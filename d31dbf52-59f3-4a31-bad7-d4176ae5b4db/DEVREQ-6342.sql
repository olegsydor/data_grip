DROP FUNCTION dash360.report_fintech_eod_zuercher_execution;

CREATE FUNCTION dash360.report_fintech_eod_zuercher_execution(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                              in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE))
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2025-07-17 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-6342 based on report_fintech_adh_execution_xls
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_id  int4[];
    l_min_exec_id int8;
    l_max_exec_id int8;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_zuercher_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===',
                           0, 'O')
    into l_step_id;
    select array_agg(account_id)
     into l_account_id
    from dwh.d_account
    where d_account.trading_firm_id = 'zuercher';

    return query
        select 'Trading Firm,Account,Street Cl Ord ID,Cl Ord ID,Date,Time,Sec Type,Ex Dest,Sub Strategy,Side,O/C,Symbol,Last Qty,Last Px,Principal Amount,Last Mkt,Exchange Name,Liquidity Ind,Cust/Firm,Exec Broker,CMTA,Client ID,OSI Symbol,Root Symbol,Expiration,Put/Call,Strike,Dash Exec ID,Exch Exec ID,Is Mleg,Is Cross,Sending Firm,Sub System,Free ,Commission,Execution Cost,Maker/Taker Fee,Transaction Fee,Trade Processing Fee,Royalty Fee,Option Regulatory Fee,OCC Fee,SEC Fee,Client Commission,Dash Liq Ind Type,Trade Currency';

    return query
        select array_to_string(ARRAY [
                                   replace(tf.trading_firm_name, ',', '')::varchar , -- as "Trading Firm",
                                   da.account_name , -- as "Account",
                                   tr.street_client_order_id , -- as "Street Cl Ord ID",
                                   tr.client_order_id , -- as "Cl Ord ID",
                                   to_char(tr.trade_record_time, 'MM/DD/YYYY') , -- as "Date",
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.US') , -- as "Time",
                                   case
                                       when tr.instrument_type_id = 'E' then 'Equity'
                                       when tr.instrument_type_id = 'O' then 'Option'
                                       end , -- as "Sec Type",
            --coalesce(exd.ex_destination_desc, tr.ex_destination) , -- as "Ex Dest",
                                   case
                                       when tr.ex_destination in ('ALGO', 'SMART')
                                           then tr.ex_destination || (case
                                                                          when tr.instrument_type_id = 'O'
                                                                              then ' Options'
                                                                          when tr.instrument_type_id = 'E'
                                                                              then ' Equities'
                                                                          else '' end)
                                       else exd.ex_destination_desc
                                       end::varchar , -- as "Ex Dest",
                                   tr.sub_strategy , -- as "Sub Strategy",
                                   case
                                       when tr.side = '1' then 'Buy'
                                       when tr.side = '2' then 'Sell'
                                       when tr.side in ('5', '6') then 'Sell Short'
                                       else ''
                                       end , -- as "Side",
                                   case
                                       when tr.open_close = 'O' then 'Open'
                                       when tr.open_close = 'C' then 'Close'
                                       else '' end , -- as "O/C",
                                   hsd.display_instrument_id , -- as "Symbol",
                                   tr.last_qty::text , -- as "Last Qty",
                                   to_char(tr.last_px, 'FM999990.009999') , -- as "Last Px",
                                   to_char(tr.principal_amount, 'FM999990.0099') , -- as "Principal Amount",
                                   coalesce(dlm.last_mkt_name, tr.last_mkt) , -- as "Last Mkt",
                                   ex.exchange_name , -- as "Exchange Name",
                                   tr.trade_liquidity_indicator , -- as "Liquidity Ind",
                                   cf.customer_or_firm_name , -- as "Cust/Firm",
                                   tr.exec_broker , -- as "Exec Broker",
                                   tr.cmta , -- as "CMTA",
                                   tr.client_id , -- as "Client ID",
                                   hsd.opra_symbol , -- as "OSI Symbol",
                                   coalesce(hsd.underlying_symbol, hsd.symbol) , -- as "Root Symbol",
                                   to_char(hsd.maturity_date, 'MM/DD/YYYY') , -- as "Expiration",
                                   case
                                       when hsd.put_call = '0' then 'Put'
                                       when hsd.put_call = '1' then 'Call'
                                       else ''
                                       end , -- as "Put/Call",
                                   to_char(hsd.strike_px, 'FM999990.0099') , -- as "Strike",
                                   tr.exec_id::varchar , -- as "Dash Exec ID",
                                   tr.exch_exec_id , -- as "Exch Exec ID",
                                   case
                                       when tr.multileg_reporting_type = '1'
                                           then 'N'
                                       else 'Y' end , -- as "Is Mleg",
                                   tr.is_cross_order , -- as "Is Cross",
                                   tr.fix_comp_id , -- as "Sending Firm",
                                   tr.subsystem_id , -- as "Sub System",
                                   lst_ex.exec_text , -- as "Free Text",
                                   to_char(tr.tcce_account_dash_commission_amount, 'FM990.00999999') , -- as "Commission",
                                   to_char(tr.tcce_account_execution_cost, 'FM99990.00999999') , -- as "Execution Cost",
                                   to_char(tr.tcce_maker_taker_fee_amount, 'FM99990.00999999') , -- as "Maker/Taker Fee",
                                   to_char(tr.tcce_transaction_fee_amount, 'FM99990.00999999') , -- as "Transaction Fee",
                                   to_char(tr.tcce_trade_processing_fee_amount, 'FM99990.00999999') , -- as "Trade Processing Fee",
                                   to_char(tr.tcce_royalty_fee_amount, 'FM99990.00999999') , -- as "Royalty Fee",
                                   to_char(tr.tcce_option_regulatory_fee_amount, 'FM99990.00999999') , -- as "Option Regulatory Fee",
                                   to_char(tr.tcce_occ_fee_amount, 'FM99990.00999999') , -- as "OCC Fee",
                                   to_char(tr.tcce_sec_fee_amount, 'FM99990.00999999') , -- as "SEC Fee",
                                   to_char(tr.client_commission_rate * tr.last_qty, 'FM999990.00999999') , -- as "Client Commission",
                                   dlit.liquidity_indicator_type , -- as "Dash Liq Ind Type",
                                   'USD' -- as "Trade Currency"
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account da on (da.account_id = tr.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = da.trading_firm_unq_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                 left join dwh.d_customer_or_firm cf
                           on (cf.customer_or_firm_id = tr.opt_customer_firm and cf.is_active)
                 left join dwh.d_exchange ex on (ex.exchange_id = tr.exchange_id and ex.is_active)
                 left join dwh.d_ex_destination exd on (exd.ex_destination_code = tr.ex_destination and
                                                        coalesce(exd.exchange_id, '') =
                                                        coalesce(tr.exchange_id, '') and
                                                        exd.instrument_type_id = tr.instrument_type_id and
                                                        exd.is_active)
                 left join lateral
            (
            select ex.exec_text
            from dwh.execution ex
            where ex.order_id = tr.order_id
              and ex.exec_date_id between in_start_date_id and in_end_date_id
              and ex.order_status <> '3'
            order by ex.exec_id desc
            limit 1
            ) lst_ex on true
                 left join lateral (select dlit.liquidity_indicator_type
                                    from dwh.d_liquidity_indicator dli
                                             inner join dwh.d_liquidity_indicator_type dlit
                                                        on dlit.liquidity_indicator_type_id = dli.liquidity_indicator_type_id
                                    where dli.trade_liquidity_indicator = tr.trade_liquidity_indicator
                                      and dli.exchange_id = tr.exchange_id
                                      and dli.is_active ) dlit on true
                 left join dwh.d_last_market dlm on dlm.last_mkt = tr.last_mkt and dlm.is_active
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.is_busted <> 'Y'
          and da.account_name not in (select * from fintech_dwh.users_fbw_tb)
--           and case when in_instrument_type is null then true else tr.instrument_type_id = in_instrument_type end
          and tr.account_id = any (l_account_id)
          and tr.multileg_reporting_type in ('1', '2')
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_zuercher_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===',
                           l_row_cnt, 'C')
    into l_step_id;
end;
$function$
;

