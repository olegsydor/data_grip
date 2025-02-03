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
        select array_to_string(ARRAY [
                                   tf.trading_firm_name, -- Trading Firm
                                   coalesce(t_10147::text, acc.account_name), -- Account
                                   tr.street_client_order_id,-- Cl Ord ID
                                   tr.client_order_id, -- Parent Cl Ord ID
                                   to_char(tr.trade_record_time, 'MM/DD/YY'), -- Date,
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.US'), -- Time,
                                   case
                                       when tr.instrument_type_id = 'E' then 'Equity'
                                       when tr.instrument_type_id = 'O' then 'Option'
                                       end,-- Sec Type,
                                   tr.ex_destination,-- Ex Dest,
                                   tr.sub_strategy,-- Sub Strategy,
                                   tr.fee_sensitivity::text,-- Fee Sensitivity,
                                   case tr.side
                                       when '1' then 'Buy'
                                       when '2' then 'Sell'
                                       when '5' then 'Sell Short'
                                       else tr.side::text end , -- Side
                                   case tr.open_close when 'O' then 'Open' when 'C' then 'Close' else '' end, -- O/C,
                                   i.display_instrument_id, -- Symbol,
                                   tr.last_qty::text, -- Last Qty,
                                   to_char(round(tr.last_px, 4), 'FM999990.0000'), -- Last Px,
                                   lm.last_mkt_name, -- Last Mkt,
                                   real_exch.exchange_name, -- Real Exchange Name,
                                   e.exchange_name, -- Exchange Name,
                                   tr.routing_time_bid_qty::text,-- Bid Qty,
                                   to_char(tr.routing_time_bid_price, 'FM999990.0099'), -- Bid Px
                                   to_char(tr.routing_time_ask_price, 'FM999990.0099'), -- Ask Px,
                                   tr.routing_time_ask_qty::text, -- Ask Qty,
                                   tr.bid_qty::text, -- Exec Bid Qty,
                                   to_char(tr.bid_price, 'FM999990.0099'), -- Exec Bid Px,
                                   to_char(tr.ask_price, 'FM999990.0099'), -- Exec Ask Px,
                                   tr.ask_qty::text, -- Exec Ask Qty,
                                   tr.trade_liquidity_indicator,-- Liquidity Ind,
                                   li.description,-- Liq Ind Description,
                                   cf.customer_or_firm_name,-- Cust/Firm,
                                   tr.exec_broker,-- Exec Broker,
                                   tr.cmta, -- CMTA,
                                   dss.sub_system_id, -- Sub System, -- ???
                                   tr.street_mpid, -- MPID,
                                   tr.client_id,-- Client ID,
                                   case
                                       when tr.instrument_type_id = 'O'
                                           then to_char(to_date(oc.maturity_year::text || '.' ||
                                                                oc.maturity_month::text || '.' || oc.maturity_day::text,
                                                                'YYYY.MM.DD'), 'DD Mon YY')
                                       end , -- Expiration Date-- Expiration Day,
                                   i.symbol, -- Root Symbol,
                                   tr.exec_id::text,-- DB Exec ID,
                                   tr.exch_exec_id,-- Dash Exec ID,
                                   tr.secondary_exch_exec_id,-- Exch Exec ID,
                                   case
                                       when tr.multileg_reporting_type = '1' then 'N'
                                       when tr.multileg_reporting_type = '2'
                                           then 'Y' end,-- Is MLEG,
                                   tr.is_cross_order,-- Is Cross,
                                   tr.fix_comp_id,-- Sending Firm,
                                   tr.principal_amount::text, -- Principal Amount,
                                   tr.tcce_maker_taker_fee_amount::text,-- M/T Fee,
                                   to_char(round(-1, 4), 'FM999990.0000'),-- M/T Fee/Unit,
                                   to_char(round(tr.tcce_transaction_fee_amount, 4), 'FM999990.0000'),-- Transaction Fee,
                                   tr.tcce_trade_Processing_Fee_Amount::text,-- Trade Processing Fee,
                                   tr.tcce_royalty_fee_amount::text,-- Royalty Fee,
                                   tr.tcce_mss_fee_amount::text,-- MSS Fee,
                                   to_char(round(-1, 4), 'FM999990.0000'), -- MSS Fee/Unit,
                                   to_char(round(tr.tcce_option_regulatory_fee_amount, 4), 'FM999990.0000'),-- Option Reg Fee,
                                   to_char(round(tr.tcce_occ_fee_amount, 4), 'FM999990.0000'), -- OCC Fee,
                                   to_char(round(tr.tcce_sec_fee_amount, 4), 'FM999990.0000'), -- SEC Fee,
                                   to_char(round(tr.tcce_account_dash_commission_amount, 4), 'FM999990.0000'),-- Account Dash Commission,
                                   to_char(round(tr.tcce_account_execution_cost, 4), 'FM999990.0000'),-- Account Exec Cost,
                                   to_char(round(-1, 4), 'FM999990.0000'), -- Account Exec Cost/Unit,
                                   to_char(round(tr.tcce_firm_dash_commission_amount, 4), 'FM999990.0000'),-- Firm Dash Commission,
                                   to_char(round(tr.tcce_firm_execution_cost, 4), 'FM999990.0000'),-- Firm Exec Cost,
                                   to_char(round(-1, 4), 'FM999990.0000') -- Firm Exec Cost/Unit'

            -------------------------------------
--                                    tr.trade_record_id::text,
--                                    tr.orig_trade_record_id::text,
--                                    tr.trade_record_time::text,
--                                    tr.order_id::text,
--                                    tr.street_order_id::text,
--                                    i.display_instrument_id,
--                                    i.last_trade_date::text,
--                                    coalesce(e.real_exchange_id, e.exchange_id), --  as real_exchange_id,
--                                    tr.trade_record_reason,
--                                    tr.optional_data,
--                                    tr.compliance_id,
--                                    oc.put_call, -- as put_call,
--                                    oc.strike_price::text -- as strike_px
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
                 left join dwh.d_sub_system dss on dss.sub_system_id = tr.subsystem_id and dss.is_active
        where tr.date_id between in_start_date_id and in_end_date_id
          and i.symbol not in
              ('ZVZZT', 'ZWZZT', 'CBO', 'CBX', 'IBO', 'IGZ', 'ZBZX', 'ZTEST', 'ZTST', 'ZZZ', 'ZZK', 'ZVV')
          and tr.is_busted = 'N'
          and tr.account_id = any (l_account_ids)
        order by tr.trade_record_time;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_ofp0058_trades for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;

select * from dash360.report_fintech_eod_ofp0058_trades(20250128, 20250128)


select * from dwh.execution
where exec_id =  62444091583;


select to_date(:maturity_year::text||'.'||:maturity_month::text||'.'||:maturity_day::text, 'YYYY.MM.DD')