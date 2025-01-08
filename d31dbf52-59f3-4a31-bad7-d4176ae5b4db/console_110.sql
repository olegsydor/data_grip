
CREATE FUNCTION trash.so_get_settle_date_by_instrument_type(trade_date date, instrument_type character varying)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
declare
    v_settle_date date;
    v_offset      int;
begin

--Securities and Settlement Periods
--Security type Settlement Date (Prior to 09/05/17) Settlement Date (Beginning on 09/05/17)
--Stocks 3 Market days after trade date 2 Market days after trade date
--Exchange Traded Funds (ETFs) 3 Market days after trade date 2 Market days after trade date
--Mutual Funds 1 Market days after trade date 1 Market days after trade date
--Options 1 Market days after trade date 1 Market days after trade date
-- 2024-03-06 SO https://dashfinancial.atlassian.net/browse/DS-8041 Change into T+1 since 2024-05-28

if trade_date = '2025-01-08' then
    return '2025-01-09';
end if;

v_offset := case
                    when instrument_type = 'E' and trade_date <= '2024-05-27'::date then 1 --T+1
                    else 0 end; -- T+1

    select date_range.period
    into v_settle_date
    from (select (generate_series(trade_date + 1, trade_date + 10, '1 day'::interval))::date as period) date_range
    where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
      and date_range.period not in (select holiday_date from public.holiday_calendar h)
      and extract(dow from date_range.period) not in (0, 6)
    order by 1
    limit 1 offset v_offset;
-- raise notice '%, %, %', trade_date, v_offset, v_settle_date;
    RETURN v_settle_date;
END;
$function$
;
select * from public.get_settle_date_by_instrument_type(trade_date := '2025-01-08', instrument_type := 'E')
union all
select * from public.get_settle_date_by_instrument_type(trade_date := '2025-01-08', instrument_type := 'O')
union all
select * from public.get_settle_date_by_instrument_type(trade_date := '2025-01-07', instrument_type := 'E')
union all
select * from public.get_settle_date_by_instrument_type(trade_date := '2025-01-07', instrument_type := 'O');

