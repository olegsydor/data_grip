/*
select * from dash360.report_fintech_eod_alpaca_options_retail(in_start_date_id := 20240601, in_end_date_id := 20240909);

create or replace function dash360.report_fintech_eod_alpaca_options_retail(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_alpaca_options_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;


    return query
        select 'Trade Date,Timestamp,Symbol,Buy/Sell,Quantity,Price,Rate Category,Rate,PFOF,Order ID,Exec ID';
    return query
        select array_to_string(ARRAY [
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
                                   tr.exec_id::text
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
        where tr.date_id between in_start_date_id and in_end_date_id
--   and ac.trading_firm_id = 'OFT0068'
          and ac.account_name = '0007BYV'
          and tr.instrument_type_id = 'O'
          and tr.is_busted = 'N'
--         order by ac.account_name, di.symbol, tr.side
;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_alpaca_options_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;

*/
create or replace function dash360.report_eod_alpaca_equity_retail(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_eod_alpaca_equity_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;


    return query
        select 'Trade Date,Timestamp,Symbol,Buy/Sell,Quantity,Price,Rate Category,Rate,PFOF,Order ID,Exec ID';
    return query
        select array_to_string(ARRAY [
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
                                   to_char(case when tr.multileg_reporting_type = '1' then 0.0005 else 0 end,
                                           'LFM90D0099'), -- rate_category
                                   to_char(case
                                               when tr.multileg_reporting_type = '1' then tr.last_qty * 0.0005
                                               else 0 end, 'FM99999990D009999'),-- PFOF = rate * last_qty
                                   tr.client_order_id::text,
                                   tr.exec_id::text
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account ac on (ac.account_id = tr.account_id)
                 join dwh.d_instrument di on di.instrument_id = tr.instrument_id
                 left join dwh.d_option_contract oc on (oc.instrument_id = tr.instrument_id)
                 left join dwh.d_option_series dos on oc.option_series_id = dos.option_series_id
                 left join dwh.d_instrument ui on ui.instrument_id = dos.underlying_instrument_id
        where tr.date_id between in_start_date_id and in_end_date_id
          --   and ac.trading_firm_id = 'OFT0068'
          and ac.trading_firm_id = 'mirae'
          and tr.instrument_type_id = 'E'
          and tr.is_busted = 'N'
        order by ac.account_name, di.symbol, tr.side;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_eod_alpaca_equity_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;

select * from dash360.report_eod_alpaca_equity_retail(in_start_date_id := 20240901, in_end_date_id := 20240909);


