

CREATE OR REPLACE FUNCTION public.get_dateid(period date)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
begin
	return (select to_char(period ,'YYYYMMDD')::int as date_id);
end;
$function$
;


CREATE OR REPLACE FUNCTION dwh.get_dateid(period date)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
begin
	return (select to_char(period ,'YYYYMMDD')::int as date_id);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_business_date(in_date date DEFAULT CURRENT_DATE, in_offset integer DEFAULT 0, ignore_banking_holiday boolean DEFAULT true)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
begin
return(SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday , dday+8, interval '1d')::date AS holiday_date
	    FROM (SELECT in_date + in_offset AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h on (generated.holiday_date = h.holiday_date and h.is_active)
	LEFT   JOIN public.banking_holiday_calendar bh  on (generated.holiday_date = bh.banking_holiday_date )
	WHERE  h.holiday_date IS null and (bh.banking_holiday_date is null or ignore_banking_holiday)
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date 
	LIMIT  1);
end;
$function$
;


CREATE OR REPLACE FUNCTION public.get_business_date_back(in_date date DEFAULT CURRENT_DATE, in_offset integer DEFAULT 0, ignore_banking_holiday boolean DEFAULT true)
 RETURNS date
 LANGUAGE plpgsql
AS $function$ 
begin return(
SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday-8 , dday , interval '1d')::date AS holiday_date
	    FROM (SELECT in_date - in_offset AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h on (generated.holiday_date = h.holiday_date)
	LEFT   JOIN public.banking_holiday_calendar bh  on (generated.holiday_date = bh.banking_holiday_date )
	WHERE  h.holiday_date IS null and CASE WHEN ignore_banking_holiday = FALSE THEN bh.banking_holiday_date is NULL ELSE 1=1 END 
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date desc
	LIMIT  1);
end;
$function$
;


CREATE OR REPLACE FUNCTION public.get_business_date_back_w_holiday(in_date date DEFAULT CURRENT_DATE, in_offset_back integer DEFAULT 0, ignore_banking_holiday boolean DEFAULT false)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
begin 
	return(
SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday-8 , dday-1 , interval '1d')::date AS holiday_date
	    FROM (SELECT in_date + in_offset_back AS dday) x
	    ) generated
	LEFT JOIN public.holiday_calendar h on (generated.holiday_date = h.holiday_date)
	LEFT JOIN public.banking_holiday_calendar bh  on (generated.holiday_date = bh.banking_holiday_date )
	WHERE 
		CASE WHEN ignore_banking_holiday = TRUE 
		THEN COALESCE(h.holiday_date, '2020-01-01') = COALESCE(h.holiday_date, '2020-01-01') 
		ELSE h.holiday_date IS NULL 
	END 
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date desc
	LIMIT  1);
end
$function$
;


CREATE OR REPLACE FUNCTION public.get_forward_workdate_ids_arr(in_days_cnt integer DEFAULT 1, in_date_from date DEFAULT (CURRENT_DATE - '1 day'::interval))
 RETURNS integer[]
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE COST 10
AS $function$
begin 
return(select array_agg(dt.workday) as workdays
from
 (
  SELECT public.get_dateid(generated.holiday_date) AS workday
	FROM  (
	    SELECT generate_series(dday,dday + (10 + in_days_cnt*2), interval '1d')::date AS holiday_date
	    FROM (SELECT in_date_from AS dday) x
	    ) generated
	LEFT   JOIN staging.holiday_calendar h USING (holiday_date)
	WHERE  h.holiday_date IS NULL
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date ASC
	LIMIT  in_days_cnt) dt);
end;
$function$
;


CREATE OR REPLACE FUNCTION public.get_last_workdate(in_date date DEFAULT CURRENT_DATE)
 RETURNS date
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
begin return(
SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday - 8, dday - 1, interval '1d')::date AS holiday_date
	    FROM (SELECT in_date AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h USING (holiday_date)
	WHERE  h.holiday_date IS NULL
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date DESC
	LIMIT  1);
end;
$function$
;



CREATE OR REPLACE FUNCTION public.get_last_workdate_ids_arr(in_days_cnt integer DEFAULT 1, in_date_from date DEFAULT (CURRENT_DATE - '1 day'::interval))
 RETURNS integer[]
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE COST 10
AS $function$
begin return(
select array_agg(dt.workday) as workdays
from
 (
  SELECT dwh.get_dateid(generated.holiday_date) AS workday
	FROM  (
	    SELECT generate_series(dday - (10 + in_days_cnt*2), dday, interval '1d')::date AS holiday_date
	    FROM (SELECT in_date_from AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h USING (holiday_date)
	WHERE  h.holiday_date IS NULL
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date DESC
	LIMIT  in_days_cnt
 ) dt);
end;
$function$
;



CREATE OR REPLACE FUNCTION public.get_last_workdate_ids_arr_excl_early_closing(in_days_cnt integer DEFAULT 1, in_date_from date DEFAULT (CURRENT_DATE - '1 day'::interval))
 RETURNS integer[]
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE COST 10
AS $function$
begin
return(select array_agg(dt.workday) as workdays
from
 (
  SELECT dwh.get_dateid(generated.holiday_date) AS workday
	FROM  (
	    SELECT generate_series(dday - (10 + in_days_cnt*2), dday, interval '1d')::date AS holiday_date
	    FROM (SELECT in_date_from AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h USING (holiday_date)
	LEFT   JOIN public.early_closing_day_calendar ecd on generated.holiday_date = ecd.early_closing_day_date
	WHERE  h.holiday_date is null and ecd.early_closing_day_date is null
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date DESC
	LIMIT  in_days_cnt
 ) dt);
end;
$function$
;




CREATE OR REPLACE FUNCTION public.get_last_workdate_ids_arr_new(in_days_cnt integer DEFAULT 1, in_date_from date DEFAULT (CURRENT_DATE - '1 day'::interval))
 RETURNS integer[]
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE COST 10
AS $function$
begin return(
select (array_agg(dt.workday)) as workdays
from
 (
  SELECT dwh.get_dateid(generated.holiday_date) AS workday
	FROM  (
	    SELECT generate_series(dday - (10 + in_days_cnt*2), dday, interval '1d')::date AS holiday_date
	    FROM (SELECT in_date_from AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h USING (holiday_date)
	WHERE  h.holiday_date IS NULL
	AND    extract(isodow from generated.holiday_date) < 6
	
	ORDER  BY generated.holiday_date DESC
	
 ) dt
 where workday not in(select to_char(early_closing_day_date, 'YYYYMMDD')::int early_closing_day_date_id from public.early_closing_day_calendar)
 );
end;
$function$
;



CREATE OR REPLACE FUNCTION public.get_last_workdates_arr(in_days_cnt integer DEFAULT 1, in_date_from date DEFAULT ('2018-04-24'::date - '1 day'::interval))
 RETURNS date[]
 LANGUAGE plpgsql
AS $function$
begin return(select array_agg(dt.workday) as workdays
from
 (
  SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday - 1000, dday, interval '1d')::date AS holiday_date
	    FROM (SELECT in_date_from AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h USING (holiday_date)
	WHERE  h.holiday_date IS NULL
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date DESC
	LIMIT  in_days_cnt
 ) dt);
end;
$function$
;


























