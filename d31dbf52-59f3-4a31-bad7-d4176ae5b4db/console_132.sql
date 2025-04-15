-- DROP FUNCTION dash360.report_eod_alpaca_options_retail(int4, int4);

select * from dash360.report_eod_alpaca_options_retail(in_start_date_id := 20250411, in_end_date_id := 20250414, in_account_ids := '{73818,73819,73820}');
select * from dash360.report_eod_alpaca_options_retail(in_start_date_id := 20250411, in_end_date_id := 20250414, in_trading_firm_ids := '{"rqd","OFP0072"}');


         except
select * from dash360.report_eod_alpaca_options_retail2(in_start_date_id := 20250411, in_end_date_id := 20250414);


        select tf.*
        from dwh.d_account ac
        join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
        where account_id in (73818,73819,73820)

CREATE FUNCTION dash360.report_eod_alpaca_options_retail(in_start_date_id integer, in_end_date_id integer, in_trading_firm_ids varchar[] default '{}'::varchar[], in_account_ids int4[] default '{}'::int4[])
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
-- 20240926 OS https://dashfinancial.atlassian.net/browse/DEVREQ-4936 added Account Name
-- 20241107 KK https://dashfinancial.atlassian.net/browse/DEVREQ-5065 Update Account Name
-- 20241121 KK https://dashfinancial.atlassian.net/browse/DEVREQ-5065 Update Exec ID: exec_id > exch_exec_id
-- 20250415 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5905 added 2 new input parameters
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
    l_account_ids     integer[];
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_alpaca_options_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        select array_agg(account_id)
--         into l_account_ids
        from dwh.d_account
        where account_name in ('OFPAPCA');
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    return query
        select 'Account Name,Trade Date,Timestamp,Symbol,Buy/Sell,Quantity,Price,Rate Category,Rate,PFOF,Order ID,Exec ID,Venue,Exchange Fees';
    return query
        select array_to_string(ARRAY [
                                   ac.account_name,
                                   to_char(tr.order_process_time, 'YYYY-MM-DD'), -- as Trade date
                                   to_char(tr.order_process_time, 'HH24:MI:SS.US'), -- as Timestamp
            -- SYMBOL
                                   di.symbol || '-' || -- as "SYMBOL",
                                   ui.symbol || '-' || -- underlying_symbol
                                   to_char(oc.maturity_year, 'FM0000') || -- as "EXPYEAR",
                                   to_char(oc.maturity_month, 'FM00') || -- as "EXPMONTH",
                                   to_char(oc.maturity_day, 'FM00') || '-' || -- as "EXPDAY",
                                   to_char(oc.strike_price, 'FM99999990D00099') || '-' || -- as "STRIKEPRICE",
                                   case
                                       when oc.put_call = '0' then 'P'
                                       when oc.put_call = '1' then 'C' end, -- as "PUTCALL",
            --
                                   case
                                       when tr.side = '1' then 'B'
                                       when tr.side in ('2', '5', '6') then 'S' end, -- as "SIDE",
                                   tr.last_qty::text, -- as "QUANTITY",
                                   to_char(tr.last_px, 'LFM99999990D009999'), -- as "PRICE",
                                   rc.rate_category,-- rate_category
                                   to_char(case when rc.rate_category = 'INDEX_OPTION' then 0 else 0.51 end,
                                           'LFM90D099'), -- rate_category
                                   to_char(case
                                               when rc.rate_category = 'INDEX_OPTION' then 0
                                               else tr.last_qty * 0.51 end, 'FM99999990D009999'),-- PFOF = rate * last_qty
                                   tr.client_order_id::text,
                                   tr.exch_exec_id::text,
                                   exc.mic_code,
                                   to_char(coalesce(tr.tcce_maker_taker_fee_amount, 0) +
                                   coalesce(tr.tcce_trade_processing_fee_amount, 0) +
                                   coalesce(tr.tcce_transaction_fee_amount, 0), 'FM99999999990.09999999')
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account ac on (ac.account_id = tr.account_id)
                 join dwh.d_instrument di on di.instrument_id = tr.instrument_id
                 left join dwh.d_option_contract oc on (oc.instrument_id = tr.instrument_id)
                 left join dwh.d_option_series dos on oc.option_series_id = dos.option_series_id
                 left join dwh.d_instrument ui on ui.instrument_id = dos.underlying_instrument_id
                 left join lateral (select case
                                               when di.symbol in
                                                    ('VIX', 'VIXW', 'SPX', 'SPXW', 'SPXPM', 'OEX', 'XEO', 'RUT', 'RUTW',
                                                     'DJX', 'XSP', 'MXEF', 'NDX', 'NDXP', 'NANOS', 'SPIKE', 'MXACW',
                                                     'MXUSA', 'MXWLD') then 'INDEX_OPTION'
                                               else 'EQUITY_OPTION' end as rate_category) rc on true
        left join dwh.d_exchange exc on exc.exchange_id = tr.exchange_id and exc.is_active
        where tr.date_id between in_start_date_id and in_end_date_id
--           and ac.trading_firm_id in ('alpaca','OFP0068')
          and tr.account_id = any(l_account_ids)
          and tr.instrument_type_id = 'O'
          and tr.is_busted = 'N'
        order by tr.date_id, tr.trade_record_id
;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_alpaca_options_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;
