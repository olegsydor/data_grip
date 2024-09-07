drop function if exists dash360.report_fintech_eod_goldman_6;

create function dash360.report_fintech_eod_goldman_6(in_start_date_id int4, in_end_date_id int4)
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
    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_goldman_6 for ' || in_start_date_id::text || '-' ||
                                                 in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;


    return query
        select 'ACCOUNT,SYMBOL,SIDE,QUANTITY,PRICE,CMTAOPENCLOSE,EXPYEAR,EXPMONTH,EXPDAY,PUTCALL,STRIKEPRICE,EXCHANGE';
    return query
        select array_to_string(ARRAY [
                                   a.account_name, -- as "ACCOUNT",
                                   di.symbol, -- as "SYMBOL",
                                   case
                                       when tr.side = '1' then 'B'
                                       when tr.side in ('2', '5', '6') then 'S' end, -- as "SIDE",
                                   tr.last_qty::text, -- as "QUANTITY",
                                   to_char(tr.last_px, 'FM99999990D009999'), -- as "PRICE",
                                   tr.open_close, -- as "CMTAOPENCLOSE",
                                   to_char(oc.maturity_year, 'FM0000'), -- as "EXPYEAR",
                                   to_char(oc.maturity_month, 'FM00'), -- as "EXPMONTH",
                                   to_char(oc.maturity_day, 'FM00'), -- as "EXPDAY",
                                   case when oc.put_call = '0' then 'P' when oc.put_call = '1' then 'C' end, -- as "PUTCALL",
                                   to_char(oc.strike_price, 'FM99999990D0099'), -- as "STRIKEPRICE",
                                   tr.exchange_id -- as "EXCHANGE"
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account a on (a.account_id = tr.account_id)
                 join dwh.d_instrument di on di.instrument_id = tr.instrument_id
                 left join dwh.d_option_contract oc on (oc.instrument_id = tr.instrument_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and a.account_name = 'OFPGS_0001'
--       	and a.account_name = '0007BYV'
          and tr.instrument_type_id = 'O'
          and tr.is_busted = 'N'
        order by a.account_name, di.symbol, tr.side;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_goldman_6 for ' || in_start_date_id::text || '-' ||
                                                 in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;

select * from dash360.report_fintech_eod_goldman_6(20240903, 20240903);

select * from dwh.d_liquidity_indicator
where exchange_id in ('ISE', 'ISEF')
and is_active
order by exchange_id, trade_liquidity_indicator::int;

update dwh.d_liquidity_indicator
set is_active = false,
    end_date  = current_date
where is_active
  and exchange_id = 'ISE'
  and trade_liquidity_indicator in ('C', 'H', 'M', 'O', 'R', 'T', 'X');


select description, is_grey, liquidity_indicator_type_id, trade_liquidity_indicator from dwh.d_liquidity_indicator
where exchange_id in ('ISEF')
and is_active
and trade_liquidity_indicator = '5'
union
select description, is_grey, liquidity_indicator_type_id, trade_liquidity_indicator from dwh.d_liquidity_indicator
where exchange_id in ('ISE')
and is_active
and trade_liquidity_indicator = '5'