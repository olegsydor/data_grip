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


------------------------------------

select co.create_time,
       'APC4' as "Client Short Name",
       'APC4' as "Reporting Client MPID",

          ac.account_name,
          co.sub_strategy_desc
          --, dts.target_strategy_desc
          --, co.eq_order_capacity
          --, co.customer_or_firm_id
          , cof.customer_or_firm_name
          , co.client_order_id
          , co.order_qty
          , tr.cum_qty as executed_qty
          , case when co.multileg_reporting_type = '2' then 'Y' else 'N' end as is_mleg
          , case when co.cross_order_id is not null then 'Y' else 'N' end as is_cross
          --, co.*
        from dwh.client_order co
          left join dwh.d_account ac
            on co.account_id = ac.account_id
          --left join dwh.d_target_strategy dts
          --  on co.sub_strategy_id = dts.target_strategy_id
          left join dwh.d_instrument di
            on co.instrument_id = di.instrument_id
          left join dwh.d_customer_or_firm cof
            on co.customer_or_firm_id = cof.customer_or_firm_id
          left join lateral
            (
              select tr.order_id, sum(tr.last_qty) as cum_qty
              from dwh.flat_trade_record tr
              where tr.date_id between l_start_date_id and l_end_date_id -- 20220118 and 20220118 --
                and tr.order_id = co.order_id
                and tr.is_busted = 'N'
              group by tr.order_id
              limit 1
            ) tr on true
        where co.create_date_id between l_start_date_id and l_end_date_id -- 20220118 and 20220118 --
          and co.account_id in (select account_id from dwh.d_account ac where ac.trading_firm_id = any (l_trading_firm_ids))
          and co.trans_type <> 'F'
          and co.multileg_reporting_type in ('1','2')
          and co.parent_order_id is null -- only parent orders have target_strategy
          and di.instrument_type_id = 'O';


select to_char(co.create_time, 'DD/MM/YYYY')                                            as "Load Date",
       'APC4'                                                                           as "Client Short Name",
       'APCA'                                                                           as "Reporting Client MPID",
       di.symbol,
       ftr.side,
       ftr.last_px,
       ftr.last_qty,
       -- Contra Name,
       -- RLi
       li.trade_liquidity_indicator                                                     as "Li",
       to_char(ftr.last_px * ftr.last_qty, 'FM09999999V990')                            as "Amount",
       to_char(ftr.trade_record_time at time zone 'America/New_York', 'HH24:MI:SS.FF3') as "Exec Time EST",
       co.client_order_id                                                               as "Client Order ID",
       sub_strategy_desc                                                                as "Target Strategy Name",
       null                                                                             as "Custom Algo",
       left(fmj.fix_message ->> '9002', 6)                                              as "Urgency Code",
       ftr.exch_exec_id                                                                 as "External Exec ID"
from dwh.client_order co
         join dwh.flat_trade_record ftr on ftr.order_id = co.order_id and ftr.date_id = co.create_date_id
         join dwh.d_account ac on ac.account_id = ftr.account_id
         join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
         left join dwh.d_liquidity_indicator li on li.exchange_id = ftr.exchange_id and
                                                   li.trade_liquidity_indicator = ftr.trade_liquidity_indicator and
                                                   li.is_active

         left join fix_capture.fix_message_json fmj
                   on fmj.fix_message_id = co.fix_message_id and fmj.date_id = co.create_date_id
where co.ex_destination = 'ALGO'
  --   and ac.trading_firm_id = 'OFT0068'
  and ac.trading_firm_id = 'mirae'
  and co.create_date_id between :l_start_date_id and :l_end_date_id;


from dwh.flat_trade_record tr
         left join dwh.d_account ac
                   on tr.account_id = ac.account_id
    --left join dwh.d_target_strategy dts
    --  on co.sub_strategy_id = dts.target_strategy_id
         left join dwh.d_instrument di
                   on tr.instrument_id = di.instrument_id
         left join dwh.d_liquidity_indicator li on li.exchange_id = tr.exchange_id and
                                                   li.trade_liquidity_indicator = tr.trade_liquidity_indicator and
                                                   li.is_active
         left join dwh.sub_strategy ds
--           left join dwh.d_customer_or_firm cof
--             on tr.customer_or_firm_id = cof.customer_or_firm_id
where tr.date_id between :l_start_date_id and :l_end_date_id
  --   and ac.trading_firm_id = 'OFT0068'
  and ac.trading_firm_id = 'mirae'
  and tr.instrument_type_id = 'E'
  and tr.is_busted = 'N'

select * from dwh.execution;


 select order_id from trash.gtc_base_modif
 except
 select order_id from trash.so_gtc_missed_close
 except
 select order_id from trash.gtc_base_modif;
select * from dwh.gtc_order_status;

update dwh.gtc_order_status gtc
set close_date_id  = base.close_date_id,
    db_update_time = clock_timestamp(),
    closing_reason = base.closing_reason,
    order_status   = base.order_status
from trash.gtc_base_modif base
where gtc.order_id = base.order_id
  and gtc.close_date_id is null;

select * from dwh.gtc_order_status