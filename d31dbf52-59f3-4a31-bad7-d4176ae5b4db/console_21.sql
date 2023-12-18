-- DROP FUNCTION dash_reporting.reporting_get_mlbcc_supplemental(date);
select trim(regexp_replace('sto    probiliv        mozna           zabraty    ', '( ){2,}', ' ', 'g'))
sto probiliv mozna zabraty
select * from dash360.reporting_get_mlbcc_supplemental(in_date_id := 20231215);

create or replace function dash360.reporting_get_mlbcc_supplemental(in_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
declare
    l_row_cnt int4;
    l_load_id int4;
    l_step_id int4;
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.reporting_get_mlbcc_supplemental for ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    create temp table tmp_suppl on commit drop as
    select 'TRADE' as REC_TYPE,
           3       as OUT_ORD_FLAG, --tr.*,
           to_char(tr.trade_record_time, 'MM/DD/YY') || '|' ||
           coalesce(exc.mic_code, '') || '|' ||
           coalesce(tr.side, 'halepa') || '|' ||
           coalesce(tr.open_close, 'halepa') || '|' ||
           tr.last_qty || '|' ||
           coalesce(tr.street_order_qty, tr.order_qty, 0) || '|' ||
           coalesce(to_char(tr.last_px, 'FM99999990.0099'), '') || '|' ||
           oc.opra_symbol || '|' ||
           ui.symbol || '|' ||
           to_char(tr.order_process_time, 'hh24:mi:ss') || '|' ||
           to_char(tr.trade_record_time, 'hh24:mi:ss') || '|' ||
           coalesce(acc.eq_order_capacity, '') || '|' ||
           coalesce(tr.street_order_id::varchar, tr.order_id::varchar, '') || '|' ||
           coalesce(tr.trade_record_id::varchar, '') || '|' ||
           'DASH' || '|' ||
           'DASH' || '|' ||
               --coalesce(tr.sub_account,'')||'|'|| -- OCC cust Account (440)
           case
               when tr.fix_connection_id = 1352 then 'BEBS949C'
               else coalesce(fm.fix_message ->> '440', fm.fix_message ->> '1', '')
               end || '|' || -- OCC cust Account
           coalesce(tr.street_client_order_id, tr.secondary_order_id, tr.client_order_id) || '|' ||
           coalesce(tr.cmta, '') || '|' ||
           '' || '|' || --mnemonic
           '' || '|' || --MM ID
           coalesce(fm.fix_message ->> '7901', fm.fix_message ->> '9324', '') || '|' ||--preferenced LP
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
               when str.multileg_reporting_type = '1' then 'N'
               else 'Y'
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
               else coalesce(tr.street_order_type, '')
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
           '' --Record type
                   as rec
    from dwh.flat_trade_record as tr
             inner join data_marts.d_option_contract as oc on tr.instrument_id = oc.instrument_id
             inner join dwh.d_option_series as os on os.option_series_id = oc.option_series_id
             inner join data_marts.d_instrument as ui on (os.underlying_instrument_id = ui.instrument_id)
             inner join dwh.d_account as acc on acc.account_id = tr.account_id
             inner join dwh.client_order as par on par.order_id = tr.order_id
             inner join dwh.client_order as str on str.order_id = tr.order_id and str.create_date_id = tr.date_id
--
             left join fix_capture.fix_message_json as fm
                       on (tr.street_order_fix_message_id = fm.fix_message_id and fm.date_id = tr.date_id)
             left join dwh.d_exchange as exc on exc.exchange_id = tr.exchange_id and exc.is_active = True
    where tr.date_id = in_date_id --to_char(in_date,'YYYYMMDD')::int
      and (acc.opt_report_to_mpid = 'MLCB' or (acc.opt_report_to_mpid = 'EXCH' and tr.exec_broker = '792'))
      and (acc.trading_firm_id <> 'nomura' or tr.exchange_id <> 'CBOE')
      and acc.trading_firm_id <> 'baml'
      and tr.is_busted = 'N';

    get diagnostics l_row_cnt = row_count;

    return query
        select to_char(in_date_id::text::date, 'MM/DD/YY') || lpad(l_row_cnt::varchar, 10, ' ');

    return query
        select 'trade date|exchange|side|open/close|quantity|order quantity|executed price|OSI option symbol|underlying symbol|order time|execution time|account type|parent order ID|Message #|Client ID|Account Name|OCC cust acct|OCC client order ID|CMTA|mnemonic|market maker ID|preferenced LP|account origin|liquidity|strategy code|routed|exchange access fee|away market|spread indicator|BD flag|professional customer flag|order type|TIF|record type';

    return query
        select rec from tmp_suppl;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.reporting_get_mlbcc_supplemental for ' || in_date_id::text || ' FINISHED===',
                           l_row_cnt, 'O')
    into l_step_id;
end;
$function$;