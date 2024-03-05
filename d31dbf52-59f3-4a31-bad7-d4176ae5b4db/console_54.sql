select x.period as equities_sd
			from
			    (SELECT date_range.period, ROW_NUMBER() OVER(ORDER BY date_range.period) as rownum
			     FROM (SELECT (generate_series (:trade_date + 1, :trade_date + 7, '1 day'::interval))::date as period) date_range
			            where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
			            and date_range.period not in (select holiday_date from public.holiday_calendar h)
			              and trim(to_char(date_range.period,'DAY')) not IN ('SUNDAY', 'SATURDAY') -- '1 -Sun 7 - Sat
			        ) x
			where x.rownum = 3; -- Equities T+3


SELECT date_range.period
      FROM (SELECT (generate_series(:trade_date + 1, :trade_date + 10, '1 day'::interval))::date as period) date_range
      where date_range.period not in (select banking_holiday_date from public.banking_holiday_calendar b)
        and date_range.period not in (select holiday_date from public.holiday_calendar h)
        and trim(to_char(date_range.period, 'DAY')) not in ('SUNDAY', 'SATURDAY') -- '1 -Sun 7 - Sat
      and extract(day frin )
    offset 0 limit 1
