-- report_eod_alpaca_equity_retail
-- We will need to add trade_liquidity_indicator and description from the dwh.d_liquidity_indicator table

-- DROP FUNCTION dash360.report_eod_alpaca_equity_retail(int4, int4, _varchar, _int4);

CREATE OR REPLACE FUNCTION dash360.report_eod_alpaca_equity_retail(in_start_date_id integer, in_end_date_id integer, in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], in_account_ids integer[] DEFAULT '{}'::integer[])
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
-- 20240926 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4936 added Account Name
-- 20241107 KK https://dashfinancial.atlassian.net/browse/DEVREQ-5065 Update Account Name
-- 20241121 KK https://dashfinancial.atlassian.net/browse/DEVREQ-5065 Update Exec ID: exec_id > exch_exec_id
-- 20250415 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5905 added 2 new input parameters
-- 20250723 OS https://dashfinancial.atlassian.net/browse/DEVREQ-6483 added 2 output columns trade_liquidity_indicator and description
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids integer[];
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_eod_alpaca_equity_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

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

    return query
        select 'Account Name,Trade Date,Timestamp,Symbol,Buy/Sell,Quantity,Price,Rate Category,Rate,Commission,Order ID,Exec ID,Venue,Exchange Fees,Liquidity Ind,Loq Ind Description';
    return query
        select array_to_string(ARRAY [
                                   ac.account_name,
                                   to_char(tr.order_process_time, 'YYYY-MM-DD'), -- as Trade date
                                   to_char(tr.order_process_time, 'HH24:MI:SS.US'), -- as Timestamp
            -- SYMBOL
                                   di.symbol, -- as "SYMBOL",
                                   case
                                       when tr.side = '1' then 'B'
                                       when tr.side in ('2', '5', '6') then 'S' end, -- as "SIDE",
                                   tr.last_qty::text, -- as "QUANTITY",
                                   to_char(tr.last_px, 'LFM99999990D009999'), -- as "PRICE",
                                   case when tr.multileg_reporting_type = '1' then 'OUTRIGHT' else 'TIED-TO-OPTION' end,-- rate_category
                                   to_char(case
                                               when tr.trading_firm_id = 'alpaca' then (case when tr.multileg_reporting_type = '1' then 0.0005 else 0 end)
                                               else coalesce(tr.tcce_account_dash_commission_amount / tr.last_qty, 0) end,
                                           'LFM90D009999'), -- rate_category
                                   to_char(case
                                               when tr.trading_firm_id = 'alpaca' then (case when tr.multileg_reporting_type = '1' then tr.last_qty * 0.0005 else 0 end)
                                               else coalesce(tr.tcce_account_dash_commission_amount, 0) end,
                                           'FM99999990D009999'),-- PFOF = rate * last_qty
                                   tr.client_order_id::text,
                                   tr.exch_exec_id::text,
                                   exc.mic_code,
                                   to_char(coalesce(tr.tcce_maker_taker_fee_amount, 0) +
                                   coalesce(tr.tcce_trade_processing_fee_amount, 0) +
                                   coalesce(tr.tcce_transaction_fee_amount, 0), 'FM99999999990.09999999'),
                                   tr.trade_liquidity_indicator,
                                   regexp_replace(replace(li.description, ',', ' '), '( ){2,}', ' ', 'g')
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account ac on (ac.account_id = tr.account_id)
                 join dwh.d_instrument di on di.instrument_id = tr.instrument_id
                 left join dwh.d_exchange exc on exc.exchange_id = tr.exchange_id and exc.is_active
                 left join dwh.d_liquidity_indicator li
                           on tr.trade_liquidity_indicator = li.trade_liquidity_indicator and
                              li.exchange_id = tr.exchange_id and li.is_active
        where tr.date_id between in_start_date_id and in_end_date_id
          --and ac.trading_firm_id in ('alpaca','OFP0068')
--           and ac.account_name in ('APCARET')
          and tr.account_id = any(l_account_ids)
          and tr.instrument_type_id = 'E'
          and tr.is_busted = 'N'
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_eod_alpaca_equity_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;
------------
select * from dash360.report_eod_alpaca_equity_retail(20250722, 20250722, '{tradeup,EFP0009,mirae}')

557175
select tr.trading_firm_id
from dwh.flat_trade_record tr
                 join dwh.d_account ac on (ac.account_id = tr.account_id)
                 join dwh.d_instrument di on di.instrument_id = tr.instrument_id
                 left join dwh.d_exchange exc on exc.exchange_id = tr.exchange_id and exc.is_active
--  left join dwh.d_liquidity_indicator li on tr.trade_liquidity_indicator = li.trade_liquidity_indicator and li.exchange_id = tr.exchange_id and li.is_active
        where tr.date_id between :in_start_date_id and :in_end_date_id
--           and ac.trading_firm_id in ('alpaca','OFP0068')
--           and ac.account_name in ('APCARET')
--           and tr.account_id = any(:l_account_ids)
          and tr.instrument_type_id = 'E'
          and tr.is_busted = 'N'


select description, exchange_id, count(*) from dwh.d_liquidity_indicator
where true
and is_active
group by description, exchange_id
having count(*) > 1

select regexp_replace(replace(:in_text, ',', ' '), '( ){2,}', ' ', 'g')