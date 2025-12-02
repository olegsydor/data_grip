-- DROP PROCEDURE staging.f_moving_to_tail(text, text, text, int4, int4, int4);

CREATE OR REPLACE PROCEDURE staging.f_moving_to_tail(IN in_schema_name text, IN in_table_name text,
                                                     in in_tail_partition_schema text,
                                                     IN in_tail_partition_name text, IN in_next_date_id integer,
                                                     IN in_next_next_date_id integer, IN in_min_date_id integer)
    LANGUAGE plpgsql
AS
$procedure$
    -- 20251003 SO https://dashfinancial.atlassian.net/browse/DS-10310
-- 20251006 SO https://dashfinancial.atlassian.net/browse/DS-10310 Fixing bugs and adjusting the script to the monthly partitioned tables
declare
    l_load_id      int;
    l_step_id      int;
    l_message_text text;
    l_execute_sql  text;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    l_message_text :=
            'f_moving_to_tail for ' || in_schema_name || '.' || in_table_name || '_' || in_next_date_id::text || ' ';

    select public.load_log(l_load_id, l_step_id, l_message_text || 'STARTED===', 0, 'O')
    into l_step_id;

    select format('alter table %1$s.%2$s DETACH PARTITION %4$s.%2$s_%3$s', in_schema_name, in_table_name,
                  in_next_date_id, in_tail_partition_schema)
    into l_execute_sql;

    execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;
    select format('alter table %1$s.%2$s DETACH PARTITION %4$s.%3$s', in_schema_name, in_table_name,
                  in_tail_partition_name, in_tail_partition_schema)
    into l_execute_sql;

    execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;

    select format('drop table %4$s.%2$s_%3$s', in_schema_name, in_table_name, in_next_date_id, in_tail_partition_schema)
    into l_execute_sql;

--     execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;

    select format(
                   'alter table  if exists %1$s.%2$s attach partition %6$s.%3$s for values from (%4$s) to (%5$s)',
                   in_schema_name, in_table_name, in_tail_partition_name, in_min_date_id, in_next_next_date_id,
                   in_tail_partition_schema)
    into l_execute_sql;
    execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;

    select public.load_log(l_load_id, l_step_id, l_message_text || 'COMPLETED===', 0, 'O')
    into l_step_id;
end ;
$procedure$
;


call staging.f_moving_to_tail(in_schema_name := 'market_data', in_table_name := 'trade',
                              in_tail_partition_schema := 'md_partition',
                              in_tail_partition_name := 'trade_stb', in_next_date_id := 20250829,
                              in_next_next_date_id := 20250829,
                              in_min_date_id := 20250401);


select child
from (select right(child.relname, 8) as child
      from pg_inherits
               join pg_class parent on pg_inherits.inhparent = parent.oid
               join pg_class child on pg_inherits.inhrelid = child.oid
               join pg_namespace nmsp_parent on nmsp_parent.oid = parent.relnamespace
      where parent.relname like 'trade'
        and nmsp_parent.nspname = 'market_data'
        and length(child.relname) > 6
      order by 1
      )  x
order by 1
limit 1 offset 1


select '{"OPT_IS_FIX_CLFIRM_PROCESSED": "N","OPT_CLEARING_FIRM": "","OPT_IS_FIX_CUSTFIRM_PROCESSED": "N","OPT_CUST_OR_FIRM": "0","CLIENT_CUST_OR_FIRM": "","OPT_IS_FIX_EXECBROK_PROCESSED": "N","OPT_EXEC_BROKER": "019","OPT_OCC_ID": "","SG_SUB_ACCOUNT": "","SG_MINT_ACCOUNT": "","SG_SALES_TRADER_ID": "","OPT_EXEC_BROKER_BY_DASH_BROKER": ""}'::jsonb



select * from public.get_business_date_back(current_date, 4)
union all
select * from public.get_business_date_back(current_date, 3)
union all
select * from public.get_business_date_back(current_date, 2)
union all
select * from public.get_business_date_back(current_date, 1);

SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday-8 , dday , interval '1d')::date AS holiday_date
	    FROM (SELECT current_date - :in_offset AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h on (generated.holiday_date = h.holiday_date)
	LEFT   JOIN public.banking_holiday_calendar bh  on (generated.holiday_date = bh.banking_holiday_date )
	WHERE  h.holiday_date IS null and CASE WHEN :ignore_banking_holiday = FALSE THEN bh.banking_holiday_date is NULL ELSE 1=1 END
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date desc