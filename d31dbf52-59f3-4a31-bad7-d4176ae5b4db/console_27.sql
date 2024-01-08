alter function dash360.report_rps_ml_supplemental rename to report_rps_ml_supplemental_old;

CREATE OR REPLACE FUNCTION dash360.report_rps_ml_supplemental(in_start_date_id integer, in_end_date_id integer)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
-- 2023-12-18 OS https://dashfinancial.atlassian.net/browse/DEVREQ-3823
-- 2024-01-08 OS https://dashfinancial.atlassian.net/browse/DEVREQ-3823 looks like we migrated the wrong script
--               dash_reporting.get_mlbcc_supplemental on genesis2 is expected to be correct one to be migrated
    declare
    l_row_cnt int4;
    l_load_id int4;
    l_step_id int4;
begin

        select nextval('public.load_timing_seq') into l_load_id;
        l_step_id := 1;

        select public.load_log(l_load_id, l_step_id,
                               'dash360.reporting_get_mlbcc_supplemental for interval ' || in_start_date_id::text ||
                               '-' ||
                               in_end_date_id::text || ' STARTED===',
                               0, 'O')
        into l_step_id;

        create temp table tmp_suppl on commit drop as
select 'TRADE' as REC_TYPE,
               3       as OUT_ORD_FLAG, --tr.*,
               to_char(tr.trade_record_time, 'MM/DD/YY') || '|' ||
               coalesce(exc.mic_code, '') || '|' ||
               coalesce(tr.side, '') || '|' ||
               coalesce(tr.open_close, '') || '|' ||
               tr.last_qty || '|' ||
               coalesce(tr.street_order_qty, tr.order_qty, 0) || '|' ||
               coalesce(to_char(tr.last_px, 'FM99999990.0099'), '') || '|' ||
               oc.opra_symbol || '|' ||
               ui.symbol || '|' ||
               to_char(tr.order_process_time, 'hh24:mi:ss') || '|' ||
               to_char(tr.trade_record_time, 'hh24:mi:ss') || '|' ||
               coalesce(acc.eq_order_capacity, '') || '|' ||
               coalesce(tr.street_order_id::varchar, tr.order_id::varchar, '') || '|' ||
               coalesce(tr.exec_id::varchar, '') || '|' || -- column 14
               'DASH' || '|' ||
               'DASH' || '|' ||
                   --coalesce(tr.sub_account,'')||'|'|| -- OCC cust Account (440)
               case tr.subsystem_id
                   when 'HFTDMA' then 'BEBS949C'
                   --else coalesce(fm.fix_message ->> '440', fm.fix_message ->> '1', '')
-- 	  else coalesce(fm.t440, fm.t1, '')
                   else coalesce(trash.get_message_tag_string(in_fix_message_id=>tr.street_order_fix_message_id,
                                                              in_tag_number=>440,
                                                              in_date_id=>to_char(tr.order_process_time, 'YYYYMMDD')::int),
                                 tr.street_account_name
                       , '')
                   end || '|' || -- OCC cust Account Column 17
               coalesce(tr.street_client_order_id, tr.secondary_order_id, tr.client_order_id) || '|' ||
               coalesce(tr.cmta, case acc.is_option_auto_allocate when 'Y' then ca.cmta end, '') || '|' || -- Column 19
               '' || '|' || --mnemonic
               '' || '|' || --MM ID
               coalesce(trash.get_message_tag_string(in_fix_message_id=>tr.street_order_fix_message_id,
                                                     in_tag_number=>7901,
                                                     in_date_id=>to_char(tr.order_process_time, 'YYYYMMDD')::int),
                        trash.get_message_tag_string(in_fix_message_id=>tr.street_order_fix_message_id,
                                                     in_tag_number=>9324,
                                                     in_date_id=>to_char(tr.order_process_time, 'YYYYMMDD')::int),
                        '') || '|' ||--preferenced LP
               case
                   when acc.trading_firm_id = 'marathon' and tr.exchange_id = 'CBOE' then 'M'
                   when acc.trading_firm_id = 'walleye' and tr.exchange_id = 'PHLX' then 'M'
                   when tr.opt_customer_firm = '0' then 'C'
                   when tr.opt_customer_firm = '1' then 'F'
                   when tr.opt_customer_firm = '2' then 'B'
                   when tr.opt_customer_firm = '3' then 'B'
                   when tr.opt_customer_firm = '4' then 'M'
                   when tr.opt_customer_firm = '5' then 'N'
                   when tr.opt_customer_firm = '7' then 'F'
                   when tr.opt_customer_firm = '8' then 'P'
                   else ''
                   end || '|' ||
               coalesce(tr.trade_liquidity_indicator, '') || '|' ||
               '' || '|' ||
               coalesce(tr.ex_destination, '') || '|' ||
               '' || '|' ||--Exchange Access Fee
               case
                   when tr.exchange_id = 'BATS' then coalesce(tr.contra_broker, '')
                   when tr.exchange_id in ('ARCA', 'AMEX') then coalesce(tr.trade_exec_broker, '')
                   else ''
                   end || '|' ||
               case
                   when tr.multileg_reporting_type = '1' then 'N'
                   else 'Y' --check if par and str are the same!!
                   end || '|' ||
               'Y' || '|' ||--BD Flag
               case
                   when acc.opt_customer_or_firm = '8' then 'Y'
                   else 'N'
                   end || '|' ||--Professional Flag
               case tr.street_order_type
                   when '1' then 'MKT'
                   when '2' then 'LMT'
                   when '3' then 'STP'
                   when '4' then 'STL'
                   when '5' then 'MOC'
                   when '7' then 'LOB'
                   when 'B' then 'LOC'
                   when 'J' then 'MIT'
                   when 'P' then 'PEG'
                   when 'O' then 'MOO'
                   when '6' then 'WOW'
                   else '' -- coalesce(tr.street_order_type,'')
                   end || '|' ||--Order Type
case
               when par.time_in_force_id = '0' then 'DAY'
               when par.time_in_force_id = '1' then 'GTC'
               when par.time_in_force_id = '2' then 'OPG'
               when par.time_in_force_id = '3' then 'IOC'
               when par.time_in_force_id = '4' then 'FOK'
               when par.time_in_force_id = '5' then 'GTX'
               when par.time_in_force_id = '6' then 'GTD'
               when par.time_in_force_id = '7' then 'At the Close'
               else ''-- as time_in_force
                   end || '|' ||
               '' || '|' --Record type
                   || coalesce(tr.exec_broker, '') || '' --exec_firm
                       as REC
from dwh.flat_trade_record as tr
inner join dwh.d_option_contract as oc on tr.instrument_id = oc.instrument_id
inner join dwh.d_option_series as os on os.option_series_id = oc.option_series_id
inner join dwh.d_instrument as ui on (os.underlying_instrument_id = ui.instrument_id)
inner join dwh.d_account as acc on acc.account_id = tr.account_id
    inner join dwh.client_order as par on par.order_id = tr.order_id
left join dwh.d_exchange as exc on exc.exchange_id = tr.exchange_id and exc.is_active
left join dwh.d_clearing_account ca on ca.account_id =tr.account_id and CA.IS_active  and CA.MARKET_TYPE = 'O' and CA.IS_DEFAULT = 'Y'
where tr.date_id between :in_start_date_id and :in_end_date_id --to_char(in_date,'YYYYMMDD')::int
and (acc.opt_report_to_mpid = 'MLCB' or acc.opt_report_to_mpid = 'EXCH')
and tr.exec_broker in ('792', '733')
--and (acc.opt_report_to_mpid = 'MLCB' or (acc.opt_report_to_mpid = 'EXCH' and tr.exec_broker in ('792', '733')))
--and (acc.opt_report_to_mpid = 'MLCB' or (acc.opt_report_to_mpid = 'EXCH' and tr.exec_broker = '792'))
and ( tr.subsystem_id ='HFTDMA' or (acc.trading_firm_id <> 'nomura' or tr.exchange_id <> 'CBOE') and acc.trading_firm_id <> 'baml')
and tr.is_busted = 'N'
and tr.order_id>0;

   get diagnostics l_row_cnt = row_count;

    return query
        select to_char(in_end_date_id::text::date, 'MM/DD/YY') || lpad(l_row_cnt::varchar, 10, ' ');

    return query
        select 'trade date|exchange|side|open/close|quantity|order quantity|executed price|OSI option symbol|underlying symbol|order time|execution time|account type|parent order ID|Message #|Client ID|Account Name|OCC cust acct|OCC client order ID|CMTA|mnemonic|market maker ID|preferenced LP|account origin|liquidity|strategy code|routed|exchange access fee|away market|spread indicator|BD flag|professional customer flag|order type|TIF|record type|exec_firm';

    return query
        select rec from tmp_suppl;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.reporting_get_mlbcc_supplemental for interval ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;

