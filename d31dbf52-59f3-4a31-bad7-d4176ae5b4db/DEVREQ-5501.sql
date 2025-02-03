create function dash360.report_fintech_eod_ofp0058_trades(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
declare
    l_account_ids int4[];
    l_load_id     int;
    l_step_id     int;
    l_row_cnt     int;
begin

    --DROP FUNCTION dash360.dash360_report_trades(character varying[], bigint[], character varying, integer, integer, timestamp without time zone, timestamp without time zone, character)
    -- 20210323 ak added new input parametr in_client_ids and filtering
    -- OS: 20211104 DS-4333 removing dynamic sql
    -- OS: 20230607 DS-6786 add mpid to the parameters list
    -- OS: 20250203 https://dashfinancial.atlassian.net/browse/DEVREQ-5501 used the old script for this custom report

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_ofp0058_trades for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id = 'OFP0058';

    return query
    select 'Trading Firm,Account,Cl Ord ID,Parent Cl Ord ID,Date,Time,Sec Type,Ex Dest,Sub Strategy,Fee Sensitivity,Side,O/C,Symbol,Last Qty,Last Px,Last Mkt,Real Exchange Name,Exchange Name,Bid Qty,Bid Px,Ask Px,Ask Qty,Exec Bid Qty,Exec Bid Px,Exec Ask Px, Exec Ask Qty,Liquidity Ind,Liq Ind Description,Cust/Firm,Exec Broker,CMTA,Sub System,MPID,Client ID,Expiration Day,Root Symbol,DB Exec ID,Dash Exec ID,Exch Exec ID,Is MLEG,Is Cross,Sending Firm,Principal Amount,M/T Fee,M/T Fee/Unit,Transaction Fee,Trade Processing Fee,Royalty Fee,MSS Fee,MSS Fee/Unit,Option Reg Fee,OCC Fee,SEC Fee,Account Dash Commission,Account Exec Cost,Account Exec Cost/Unit,Firm Dash Commission,Firm Exec Cost,Firm Exec Cost/Unit';
    return query
        select
            array_to_string(ARRAY [
               tf.trading_firm_name, -- Trading Firm
               coalesce(t_10147, acc.account_name), -- Account
                tr.street_client_order_id,-- Cl Ord ID
                tr.client_order_id, -- Parent Cl Ord ID
                -- Date,
                -- Time,
                -- Sec Type,
                -- Ex Dest,
                -- Sub Strategy,
                -- Fee Sensitivity,
                -- Side,
                -- O/C,
                -- Symbol,
                -- Last Qty,
                -- Last Px,
                -- Last Mkt,
                -- Real Exchange Name,
                -- Exchange Name,
                -- Bid Qty,
                -- Bid Px,
                -- Ask Px,
                -- Ask Qty,
                -- Exec Bid Qty,
                -- Exec Bid Px,
                -- Exec Ask Px,
                -- Exec Ask Qty,
                -- Liquidity Ind,
                -- Liq Ind Description,
                -- Cust/Firm,
                -- Exec Broker,
                -- CMTA,
                -- Sub System,
                -- MPID,
                -- Client ID,
                -- Expiration Day,
                -- Root Symbol,
                -- DB Exec ID,
                -- Dash Exec ID,
                -- Exch Exec ID,
                -- Is MLEG,
                -- Is Cross,
                -- Sending Firm,
                -- Principal Amount,
                -- M/T Fee,
                -- M/T Fee/Unit,
                -- Transaction Fee,
                -- Trade Processing Fee,
                -- Royalty Fee,
                -- MSS Fee,
                -- MSS Fee/Unit,
                -- Option Reg Fee,
                -- OCC Fee,
                -- SEC Fee,
                -- Account Dash Commission,
                -- Account Exec Cost,
                -- Account Exec Cost/Unit,
                -- Firm Dash Commission,
                -- Firm Exec Cost,
                -- Firm Exec Cost/Unit'





            tr.trade_record_id::text,
               tr.orig_trade_record_id::text,
               tr.trade_record_time::text,
               tr.exec_id::text,
               tr.order_id::text,
               tr.street_order_id::text,
               tr.client_order_id,


--                acc.account_name,

               tr.side,
               tr.open_close,
               tr.last_qty::text,
               tr.last_px::text,
               lm.last_mkt_name, --                             as last_mkt,
               tr.trade_liquidity_indicator,
               li.description, --                               as trade_liquidity_indicator_text,
               tr.ex_destination,
               tr.sub_strategy,
               cf.customer_or_firm_name,
               tr.exec_broker,
               tr.cmta,
               tr.client_id,
               tr.multileg_reporting_type,
               tr.is_cross_order,
               tr.exch_exec_id,
               tr.secondary_exch_exec_id,
               tr.fix_comp_id,
               tr.tcce_account_dash_commission_amount::text,
               tr.tcce_account_execution_cost::text,
               tr.tcce_firm_dash_commission_amount::text,
               tr.tcce_firm_execution_cost::text,
               tr.tcce_mss_fee_amount::text,
               tr.tcce_maker_taker_fee_amount::text,
               tr.tcce_occ_fee_amount::text,
               tr.tcce_option_regulatory_fee_amount::text,
               tr.tcce_royalty_fee_amount::text,
               tr.tcce_sec_fee_amount::text,
               tr.tcce_transaction_fee_amount::text,
               tr.tcce_trade_Processing_Fee_Amount::text,
               i.instrument_type_id, --                         as sec_type,
               i.symbol,
               i.display_instrument_id,
               i.last_trade_date::text,
               coalesce(e.real_exchange_id, e.exchange_id), --  as real_exchange_id,
               e.exchange_name,
               real_exch.exchange_name, --                      as real_exchange_name,
               tr.principal_amount::text,
               tr.ask_price::text, --                                 as execution_time_ask_price,
               tr.bid_price::text, --                                 as execution_time_bid_price,
               tr.ask_qty::text, --                                   as execution_time_ask_qty,
               tr.bid_qty::text, --                                   as execution_time_bid_qty,
               tr.routing_time_ask_price::text,
               tr.routing_time_bid_price::text,
               tr.routing_time_ask_qty::text,
               tr.routing_time_bid_qty::text,
               tr.trade_record_reason,
               tr.fee_sensitivity::text,
               tr.optional_data,
               oc.opra_symbol,
               tr.compliance_id,
               oc.put_call, -- as put_call,
               oc.strike_price::text                             -- as strike_px
                ], ',', '')
        from dwh.flat_trade_record tr
                 inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
                 inner join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)
                 left join dwh.d_exchange e on (tr.exchange_id = e.exchange_id and e.is_active = true)
                 left join dwh.d_exchange real_exch
                           on (real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and
                               real_exch.is_active = true)
                 inner join dwh.d_trading_firm tf on (acc.trading_firm_id = tf.trading_firm_id and tf.is_active)
                 left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 left join dwh.d_liquidity_indicator li
                           on (tr.trade_liquidity_indicator = li.trade_liquidity_indicator and
                               real_exch.exchange_id = li.exchange_id and li.is_active)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = opt_customer_firm and cf.is_active)
                 left join dwh.d_last_market lm on (lm.last_mkt = tr.last_mkt and lm.is_active)
--         left join fix_capture.fix_message_json fmj on fmj.fix_message_id = tr.order_fix_message_id and fmj.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::int4
                 left join lateral (select fix_message ->> '10147' as t_10147
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = tr.street_order_fix_message_id
                                      and fmj.date_id = to_char(tr.street_order_process_time, 'YYYYMMDD')::int4
                                    limit 1) fmj on true
        where tr.date_id between :in_start_date_id and :in_end_date_id
          and i.symbol not in
              ('ZVZZT', 'ZWZZT', 'CBO', 'CBX', 'IBO', 'IGZ', 'ZBZX', 'ZTEST', 'ZTST', 'ZZZ', 'ZZK', 'ZVV')
          and tr.is_busted = 'N'
          and tr.account_id = any (:l_account_ids)
        order by tr.trade_record_time;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_ofp0058_trades for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;