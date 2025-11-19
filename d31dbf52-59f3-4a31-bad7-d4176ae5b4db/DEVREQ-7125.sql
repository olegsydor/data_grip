-- DROP FUNCTION dash360.report_fintech_eod_saxopts_execution(int4, int4);
Nen
CREATE FUNCTION dash360.report_fintech_eod_wealthsim_execution(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                rec text
            )
    LANGUAGE plpgsql
AS
$function$
-- 20251119 OS https://dashfinancial.atlassian.net/browse/DEVREQ-7125
declare
    l_load_id     int;
    l_step_id     int;
    l_account_ids int4[];
    l_row_count   int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_wealthsim_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::Text || ' STARTED ====', 0,
                           'O')
    into l_step_id;
    select array_agg(account_id)
--     into l_account_ids
    from dwh.d_account
    where trading_firm_id in ('wealthsim', 'OFP0081');

    return query
        select 'Create Date,Create Time,Exec Date,Exec Time,Symbol,OSI Symbol,Side,Open/Close,Order Qty,Last Qty,Price,Stop Price,Last Px,WS Account ID,WS OrderID';
    return query
        select array_to_string(ARRAY [
                                   to_char(cl.create_time, 'MM/DD/YYYY') , --as "Create Date",
                                   to_char(cl.create_time, 'HH24:MI:SS.US') , --as "Create Time",
                                   to_char(tr.trade_record_time, 'MM/DD/YYYY') , --as "Exec Date",
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.US') , --as "Exec Time",
                                   hsd.display_instrument_id , --as "Symbol",
                                   hsd.opra_symbol , --as "OSI Symbol",
                                   case
                                       when tr.side = '1' then 'Buy'
                                       when tr.side in ('2', '5', '6') then 'Sell'
                                       end , --as "Side",
                                   case
                                       when tr.open_close = 'O' then 'Open'
                                       when tr.open_close = 'C' then 'Close'
                                       end , --as "Open/Close",
                                   tr.order_qty::text , --as "Order Qty",
                                   tr.last_qty::text , --as "Last Qty",
                                   tr.order_price::text , --as "Price",
                                   cl.stop_price::text , --as "Stop Price",
                                   tr.last_px::text , --as "Last Px",
                                   fmj.tag_109 , --as "WS Account ID",
                                   fmj.tag_9945 --as "WS OrderID"
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account da on (da.account_id = tr.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = da.trading_firm_unq_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                 join lateral (select cl.create_time, stop_price
                               from dwh.client_order cl
                               where cl.order_id = tr.order_id
                               limit 1) cl on true
                 left join lateral (select fmj.fix_message ->> '109'  as tag_109,
                                           fmj.fix_message ->> '9945' as tag_9945
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = tr.order_fix_message_id
                                    limit 1) fmj on true
        --                  left join lateral
--             (
--             select ex.exec_text
--             from dwh.execution ex
--             where ex.order_id = tr.order_id
--               and ex.exec_date_id between in_start_date_id and in_end_date_id
--               and ex.order_status <> '3'
--             order by ex.exec_id desc
--             limit 1
--             ) lst_ex on true
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.is_busted <> 'Y'
          and tr.account_id = any (l_account_ids)
--           and tr.instrument_type_id = 'O'
          and tr.multileg_reporting_type in ('1', '2')
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_count = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_wealthsim_execution FINISHED ====', l_row_count,
                           'O')
    into l_step_id;
end;
$function$
;



/*
            replace(tf.trading_firm_name, ',', '')::varchar as "Trading Firm",
                     da.account_name                                 as "Account",
                     tr.client_order_id                              as "Cl Ord ID",
                     tr.street_client_order_id                       as "Street Cl Ord ID",


                     case
                         when tr.instrument_type_id = 'E' then 'Equity'
                         when tr.instrument_type_id = 'O' then 'Option'
                         end                                         as "Sec Type",
                     --coalesce(exd.ex_destination_desc, tr.ex_destination) as "Ex Dest",
                     case
                         when tr.ex_destination in ('ALGO', 'SMART')
                             then tr.ex_destination || (case
                                                            when tr.instrument_type_id = 'O' then ' Options'
                                                            when tr.instrument_type_id = 'E' then ' Equities'
                                                            else '' end)
                         else exd.ex_destination_desc
                         end::varchar                                as "Ex Dest",
                     tr.sub_strategy                                 as "Sub Strategy",





                     tr.principal_amount                             as "Principal Amount",
                     tr.last_mkt                                     as "Last Mkt",
                     ex.exchange_name                                as "Exchange Name",
                     tr.trade_liquidity_indicator                    as "Liquidity Ind",
                     cf.customer_or_firm_name                        as "Cust/Firm",
                     tr.exec_broker                                  as "Exec Broker",
                     tr.cmta                                         as "CMTA",
                     tr.client_id                                    as "Client ID",

                     coalesce(hsd.underlying_symbol, hsd.symbol)     as "Root Symbol",
                     to_char(hsd.maturity_date, 'MM/DD/YYYY')        as "Expiration",
                     case
                         when hsd.put_call = '0' then 'Put'
                         when hsd.put_call = '1' then 'Call'
                         else ''
                         end                                         as "Put/Call", -- Changed insted of clear put_call
                     hsd.strike_px                                   as "Strike",
                     hsd.contract_multiplier                         as "Contract Multiplier",
                     'USD'::varchar                                  as "Currency",
                     tr.exec_id                                      as "Dash Exec ID",
                     tr.exch_exec_id                                 as "Exch Exec ID",
                     case
                         when tr.multileg_reporting_type = '1'
                             then 'N'
                         else 'Y' end                                as "Is Mleg",
                     tr.is_cross_order                               as "Is Cross",
                     tr.fix_comp_id                                  as "Sending Firm",
                     tr.subsystem_id                                 as "Sub System",
--        tr.trade_text                                   as "Free Text from trade_record", -- took text from trade_record
                     lst_ex.exec_text                                as "Free Text",
                     tr.tcce_account_dash_commission_amount          as "Commission",
                     tr.tcce_account_execution_cost                  as "Execution Cost",
                     tr.tcce_maker_taker_fee_amount                  as "Maker/Taker Fee",
                     tr.tcce_transaction_fee_amount                  as "Transaction Fee",
                     tr.tcce_trade_processing_fee_amount             as "Trade Processing Fee",
                     tr.tcce_royalty_fee_amount                      as "Royalty Fee",
                     tr.tcce_option_regulatory_fee_amount            as "Option Regulatory Fee",
                     tr.tcce_occ_fee_amount                          as "OCC Fee",
                     tr.tcce_sec_fee_amount                          as "SEC Fee"
        */

       select * from dwh.flat_trade_record where account_id = any('{76169,76172}')