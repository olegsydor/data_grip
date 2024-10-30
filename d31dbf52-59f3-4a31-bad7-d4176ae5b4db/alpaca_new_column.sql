-- DROP FUNCTION dash360.report_eod_alpaca_algo_route(int4, int4);

CREATE OR REPLACE FUNCTION dash360.report_eod_alpaca_algo_route(in_start_date_id integer, in_end_date_id integer)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
-- 20240926 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4936 added Account Name
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids int4[];
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_eod_alpaca_algo_route for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id in ('alpaca','OFP0068');

    return query
-- select 'Load Date,Client Short Name,Reporting Client MPID,Symbol,Side,Last Px,Last Qty,Contra Name,RLi,Li,Amount,Exec Time EST,Client Order ID,Target Strategy Name,Custom Algo,Urgency Code,External Exec ID';
        select 'Account Name,Load Date,Client Short Name,Reporting Client MPID,Symbol,Side,Last Px,Last Qty,Li,Amount,Exec Time EST,Client Order ID,Target Strategy Name,Custom Algo,Urgency Code,External Exec ID';
    return query
        select array_to_string(ARRAY [
                                   ac.account_name,
                                   to_char(co.create_time, 'DD/MM/YYYY'), -- as "Load Date",
                                   'APC4', -- as "Client Short Name",
                                   'APCA', -- as "Reporting Client MPID",
                                   di.symbol,
                                   case
                                       when ftr.side = '1' then 'Buy'
                                       when ftr.side = '2' then 'Sell'
                                       when ftr.side in ('5', '6') then 'Sell Short'
                                       end, -- as "Side"
                                   to_char(ftr.last_px, 'LFM99999990D009999'), -- "Last Px"
                                   ftr.last_qty::text, -- "Last Qty"
            -- Contra Name,
            -- RLi
                                   li.trade_liquidity_indicator, -- as "Li",
                                   to_char(ftr.last_px * ftr.last_qty, 'FM99999990D009999'), -- as "Amount",
                                   to_char(ftr.trade_record_time at time zone 'America/New_York',
                                           'HH24:MI:SS.FF3'), -- as "Exec Time EST",
                                   co.client_order_id, -- as "Client Order ID",
                                   sub_strategy_desc, -- as "Target Strategy Name",
                                   null::text, -- as "Custom Algo",
                                   left(fmj.fix_message ->> '9002', 6), -- as "Urgency Code",
                                   ftr.exch_exec_id -- as "External Exec ID"
                                   ], ',', '')
        from dwh.client_order co
                 join dwh.flat_trade_record ftr on ftr.order_id = co.order_id and ftr.date_id = co.create_date_id
                 join dwh.d_account ac on ac.account_id = ftr.account_id
                 join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
                 left join dwh.d_liquidity_indicator li on li.exchange_id = ftr.exchange_id and
                                                           li.trade_liquidity_indicator =
                                                           ftr.trade_liquidity_indicator and
                                                           li.is_active

                 left join fix_capture.fix_message_json fmj
                           on fmj.fix_message_id = co.fix_message_id and fmj.date_id = co.create_date_id
        where co.ex_destination = 'ALGO'
          and co.account_id = any (l_account_ids)
          and co.create_date_id between in_start_date_id and in_end_date_id
        order by ftr.date_id, ftr.trade_record_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_eod_alpaca_algo_route for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;
