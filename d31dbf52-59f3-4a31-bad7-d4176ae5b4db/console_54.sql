select x.period as equities_sd
			from
			    (SELECT date_range.period, ROW_NUMBER() OVER(ORDER BY date_range.period) as rownum
			     FROM (SELECT (generate_series (:trade_date + 1, :trade_date + 7, '1 day'::interval))::date as period) date_range
			            where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
			            and date_range.period not in (select holiday_date from public.holiday_calendar h)
			              and trim(to_char(date_range.period,'DAY')) not IN ('SUNDAY', 'SATURDAY') -- '1 -Sun 7 - Sat
			        ) x
			where x.rownum = 3; -- Equities T+3


select date_range.period
      from (select (generate_series(:trade_date + 1, :trade_date + 10, '1 day'::interval))::date as period) date_range
      where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
        and date_range.period not in (select holiday_date from public.holiday_calendar h)
      and extract(dow from date_range.period) not in (0, 6)
    offset 2 limit 1;

select extract(dow from current_date)


-- DROP FUNCTION public.get_settle_date_by_instrument_type(date, varchar);

CREATE OR REPLACE FUNCTION trash.get_settle_date_by_instrument_type(trade_date date, instrument_type character varying)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
declare
v_settle_date date;
begin


--Securities and Settlement Periods
--Security type Settlement Date (Prior to 09/05/17) Settlement Date (Beginning on 09/05/17)
--Stocks 3 Market days after trade date 2 Market days after trade date
--Exchange Traded Funds (ETFs) 3 Market days after trade date 2 Market days after trade date
--Mutual Funds 1 Market days after trade date 1 Market days after trade date
--Options 1 Market days after trade date 1 Market days after trade date

if trade_date >= '2024-05-28' then
    select date_range.period
    into v_settle_date
    from (select (generate_series(trade_date + 1, trade_date + 10, '1 day'::interval))::date as period) date_range
    where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
      and date_range.period not in (select holiday_date from public.holiday_calendar h)
      and extract(dow from date_range.period) not in (0, 6)
    offset 1 limit 1;
	else -- (instrument_type = 'E' and trade_date >= to_date('09/05/2017','mm/dd/yyyy')) then
			select x.period as equities_sd
			into v_settle_date
			from
			     (SELECT date_range.period, ROW_NUMBER() OVER(ORDER BY date_range.period) as rownum
			     FROM (SELECT (generate_series (trade_date + 1, trade_date + 7, '1 day'::interval))::date as period) date_range
			            where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
			            and date_range.period not in (select holiday_date from public.holiday_calendar h)
			              and trim(to_char(date_range.period,'DAY')) not IN ('SUNDAY', 'SATURDAY') -- '1 -Sun 7 - Sat
			        ) x
			where x.rownum = 2; -- Equities T+2
	end if;

	RETURN v_settle_date;
END; $function$
;

CREATE OR REPLACE FUNCTION trash.get_settle_date_by_instrument_type(trade_date date, instrument_type character varying)
    RETURNS date
    LANGUAGE plpgsql
AS
$function$
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
-- 2024-03-06
    v_offset := case
                    when instrument_type = 'E' and trade_date between '2017-05-09'::date and '2024-05-27'::date then 1
                    else 0 end;

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
select * from trash.get_settle_date_by_instrument_type('2024-05-27', 'E');

with base as (
select d::date, extract(dow from d), trash.get_settle_date_by_instrument_type(d::date, 'E') as new_return,
       public.get_settle_date_by_instrument_type(d::date, 'E') as old_return
from generate_series(current_date, current_date + interval '100 days', '1 day') as x(d)
)
         select * from base
                  where new_return <> old_return
select :trade_date between '2017-05-09'::date and '2024-05-27'::date

select * from get_settle_date_by_instrument_type( '2024-05-01', 'E')


select date_range.period
    from (select (generate_series(:trade_date + 1, :trade_date + 10, '1 day'::interval))::date as period) date_range
    where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
      and date_range.period not in (select holiday_date from public.holiday_calendar h)
      and extract(dow from date_range.period) not in (0, 6)
    order by 1
    limit 1 offset :v_offset;


SELECT date_range.period, ROW_NUMBER() OVER(ORDER BY date_range.period) as rownum
			     FROM (SELECT (generate_series (:trade_date + 1, :trade_date + 7, '1 day'::interval))::date as period) date_range
			            where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
			            and date_range.period not in (select holiday_date from public.holiday_calendar h)
			              and trim(to_char(date_range.period,'DAY')) not IN ('SUNDAY', 'SATURDAY') -- '1 -Sun 7 - Sat