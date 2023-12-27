-- DROP FUNCTION dash_reporting.get_wfdailytrades(timestamp);
select * from dash360.report_rps_wellsfarg_trades(20231226, 20231226)
create function dash360.report_rps_wellsfarg_trades(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$function$
declare
    l_load_id int;
    l_step_id int;
    row_cnt   int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_rps_wellsfarg_trades for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;
    return query
-- Start
        select
            'Trade Date,Account,Cl Ord ID,Side,Time,Trading Symbol,Symbol Sfx,Security Type,Exec Qty,Last Px,Last Mkt,Root Symbol,Underlying Symbol,' ||
            'Is Mleg,Leg Ref ID,Ex Dest,Sub Strategy,Expiration Day,MPID,Capacity,Exec Broker,Execution ID,Liquidity Indicator,O/C,Principal Amount,' ||
            'Maker/Taker Fee,M/T Fee/Unit,Transaction Fee,Trade Processing Fee,Royalty Fee,Option Regulatory Fee,OCC Fee,SEC Fee,Dash Commission Account,' ||
            'Execution Cost Account,Exec Cost/Unit Account,Dash Commission Firm,Execution Cost Firm,Exec Cost/Unit Firm,OSI Symbol';

    --
    return query
        select array_to_string(array [
                                   to_char(tr.trade_record_time, 'MM/DD/YYYY'),
                                   ac.account_name,
                                   tr.client_order_id ,
                                   tr.side ,
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.MS') ,
                                   i.display_instrument_id ,
                                   i.symbol_suffix,
                                   case i.instrument_type_id
                                       when 'O' then 'Option'
                                       else 'Equity'
                                       end,
                                   tr.last_qty::text,
                                   tr.last_px::text ,
                                   exch.mic_code,tr.last_mkt,
                                   coalesce(os.root_symbol, i.symbol) ,
                                   coalesce(ui.symbol, i.symbol) ,
                                   case tr.multileg_reporting_type
                                       when '1' then 'N'
                                       else 'Y'
                                       end,
                                   tr.leg_ref_id::text,
                                   exd.ex_destination_code_name::text,
                                   --
                                   tr.sub_strategy::text,

                                   case
                                       when i.instrument_type_id = 'O'
                                           then
                                           concat_ws('/', to_char(oc.maturity_month, 'FM00'),
                                                     to_char(oc.maturity_day, 'FM00'),
                                                     substr(oc.maturity_year::varchar, 3))
                                       else
                                           ''
                                       end,
                                   --CL.MPID
                                   'DASH',
                                   --
                                   coalesce(cf.customer_or_firm_name, tr.opt_customer_firm),
                                   tr.exec_broker,
                                   --
                                   tr.exch_exec_id ,
                                   coalesce(tr.trade_liquidity_indicator, '') ,
                                   case tr.open_close
                                       when 'O' then 'Open'
                                       when 'C' then 'Close'
                                       else ''
                                       end,

                                   to_char(ROUND(tr.last_qty * tr.last_px * coalesce(os.contract_multiplier, 1), 4),
                                           'FM9999999990D0000'),

                                   to_char(ROUND(tr.tcce_maker_taker_fee_amount, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_maker_taker_fee_amount / tr.last_qty, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_transaction_fee_amount, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_trade_processing_fee_amount, 4), 'FM999990.0000'),
                                   --
                                   to_char(ROUND(tr.tcce_royalty_fee_amount, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_option_regulatory_fee_amount, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_occ_fee_amount, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_sec_fee_amount, 4), 'FM999990.0000'),

                                   to_char(ROUND(tr.tcce_account_dash_commission_amount, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_account_execution_cost, 4), 'FM999990.0000'),
                                   to_char(ROUND(tr.tcce_account_execution_cost / tr.last_qty, 4), 'FM999990.0000'),

                                   '',
                                   '',
                                   '',
                                   --

                                   oc.opra_symbol
                                   ], ',', '')
                   as rec
        from dwh.flat_trade_record tr
                 inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
                 inner join dwh.mv_active_account_snapshot ac on tr.account_id = ac.account_id

                 inner join dwh.d_exchange exch on exch.exchange_id = tr.exchange_id
                 left join dwh.d_ex_destination_code exd on exd.ex_destination_code = tr.ex_destination
                 left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 left join dwh.d_instrument ui on (os.underlying_instrument_id = ui.instrument_id)

            --left join OPT_EXEC_BROKER OPX ON (OPX.ACCOUNT_ID  = AC.ACCOUNT_ID AND OPX.IS_DELETED <> 'Y' AND OPX.IS_DEFAULT  = 'Y')
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = tr.opt_customer_firm)
        where tr.date_id between in_start_date_id and in_end_date_id

          and tr.is_busted = 'N'
          and ac.trading_firm_id = 'wellsfarg';
    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_rps_wellsfarg_trades for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' finished====', row_cnt, 'O')
    into l_step_id;
end;
$function$
;
