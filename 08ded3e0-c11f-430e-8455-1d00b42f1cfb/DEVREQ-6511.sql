select dash360.report_billing_cboe_family_exchange_data_wellsfarg(20250601, 20250630, '{DFWF}', '{DFWF}', '{BATS}');

create or replace function dash360.report_billing_cboe_family_exchange_data_wellsfarg(in_start_date_id integer,
                                                                                      in_end_date_id integer,
                                                                                      in_executing_firm_ids character varying[] default array ['DFWF'],
                                                                                      in_invoiced_to character varying[] default array ['DFWF'],
                                                                                      in_exchange_codes character varying[] default null:: character varying[])
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
-- 20240926 SO https://dashfinancial.atlassian.net/browse/DEVREQ-6511
declare
    l_load_id    int;
    l_row_cnt    int;
    l_step_id    int;
    l_start_date date := in_start_date_id::text::date;
    l_end_date   date := in_end_date_id::text::date;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_billing_cboe_family_exchange_data_wellsfarg for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    return query 
    select 'trading_firm_id,trading_firm_name,trade_day,trade_time,sending_firm,sessionid,executing_firm_id,clearing_account,client_order_id,bats_order_id,execution_id,symbol,osi_root,exercise_date,put_or_call,strike_price,side,price,"size",capacity,liquidity,access_fee,bats_subscriber_id,routing_instruction,route_strategy,contra,contra_capacity,subliquidity,fee_code,contra_fee_code,pfof_fee_code,directed_market_maker,pfof_access_fee,auction_order_type,auction_role,contra_auction_role,routing_broker,invoiced_to,breakup_credit_code,breakup_credit_dollars,qcc_rebate_code,orig_exec_id,complex_execution_id,complex_symbol_id,contra_trader,contra_broker,order_entry_date,cboe_member_id,occ_clearing_id,cmta_clearing_firm,complex_instrument_id,base_rate,breakup_credit_role,floor_trader,contra_floor_trader,type,underlying,frequent_trader_id,strategy_id,compression_trade,names_later_id,original_client_order_id,clearing_optional_data,account,total_surcharges,ors_cors';
    
    return query
        select array_to_string(ARRAY [
                                   ep.trading_firm_id,
                                   ep.trading_firm_name,
                                   to_char(ep.trade_day, 'YYYY-MM-DD'),
                                   ep.trade_time,
                                   ep.sending_firm,
                                   ep.sessionid,
                                   ep.executing_firm_id,
                                   ep.clearing_account,
                                   ep.client_order_id,
                                   ep.bats_order_id,
                                   ep.execution_id,
                                   ep.symbol,
                                   ep.osi_root,
                                   ep.exercise_date,
                                   ep.put_or_call,
                                   ep.strike_price,
                                   ep.side,
                                   to_char(ep.price, 'FM999990.0099'),
                                   ep."size"::text,
                                   ep.capacity,
                                   ep.liquidity,
                                   to_char(ep.access_fee, 'FM999990.0099'),
                                   ep.bats_subscriber_id,
                                   ep.routing_instruction,
                                   ep.route_strategy,
                                   ep.contra,
                                   ep.contra_capacity,
                                   ep.subliquidity,
                                   ep.fee_code,
                                   ep.contra_fee_code,
                                   ep.pfof_fee_code,
                                   ep.directed_market_maker,
                                   '0', -- as pfof_access_fee
                                   ep.auction_order_type,
                                   ep.auction_role,
                                   ep.contra_auction_role,
                                   ep.routing_broker,
                                   ep.invoiced_to,
                                   ep.breakup_credit_code,
                                   to_char(ep.breakup_credit_dollars, 'FM999990.0099'),
                                   ep.qcc_rebate_code,
                                   ep.orig_exec_id,
                                   ep.complex_execution_id,
                                   ep.complex_symbol_id,
                                   ep.contra_trader,
                                   ep.contra_broker,
                                   to_char(ep.order_entry_date, 'YYYY-MM-DD'),
                                   ep.cboe_member_id,
                                   ep.occ_clearing_id,
                                   ep.cmta_clearing_firm,
                                   ep.complex_instrument_id,
                                   to_char(ep.base_rate, 'FM999990.0099'),
                                   ep.breakup_credit_role,
                                   ep.floor_trader,
                                   ep.contra_floor_trader,
                                   ep."type",
                                   ep.underlying,
                                   ep.frequent_trader_id,
                                   ep.strategy_id,
                                   ep.compression_trade,
                                   ep.names_later_id,
                                   ep.original_client_order_id,
                                   ep.clearing_optional_data,
                                   ep.account,
                                   ep.total_surcharges,
                                   ep.ors_cors
                                   ], ',', '')
        from billing.exchange_data.edgx_pfof_trade_data ep
        where ep.trade_day between l_start_date and l_end_date
          and ep.executing_firm_id = any (in_executing_firm_ids)
          and ep.invoiced_to = any (in_invoiced_to)
          and case
                  when coalesce(in_exchange_codes, '{}') = '{}' then true
                  else ep.exchange_code = any (in_exchange_codes) end
        order by ep.trade_day, ep.trade_time;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_billing_cboe_family_exchange_data_wellsfarg for ' || l_start_date || '-' ||
                           l_end_date::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$
