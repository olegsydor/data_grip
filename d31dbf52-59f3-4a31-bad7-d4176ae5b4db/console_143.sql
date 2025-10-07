-- DROP PROCEDURE staging.f_moving_to_tail(text, text, text, int4, int4);

CREATE OR REPLACE PROCEDURE staging.f_moving_to_tail(in_schema_name text, in_table_name text,
                                                     in_tail_partition_name text,
                                                     in_next_date_id integer,
                                                     in_next_next_date_id integer, -- I don't like this naming (SO)
                                                     in_min_date_id integer)
    LANGUAGE plpgsql
AS
$procedure$
-- 20251003 SO https://dashfinancial.atlassian.net/browse/DS-10310
-- 20251006 SO https://dashfinancial.atlassian.net/browse/DS-10310 Fixing bugs and adjusting the script to the monthly partitioned tables
declare
    l_load_id          int;
    l_step_id          int;
    l_message_text     text;
    l_execute_sql      text;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    l_message_text := 'f_moving_to_tail for ' || in_schema_name || '.' || in_table_name || '.' || in_next_date_id::text || ';';

    select public.load_log(l_load_id, l_step_id, l_message_text || 'STARTED===', 0, 'O')
    into l_step_id;

    select format('alter table %1$s.%2$s DETACH PARTITION partitions.%2$s_%3$s', in_schema_name, in_table_name,
                  in_next_date_id)
    into l_execute_sql;

--     execute l_execute_sql;
   raise notice 'execute - %', l_execute_sql;
    select format('alter table %1$s.%2$s DETACH PARTITION partitions.%3$s', in_schema_name, in_table_name,
                  in_tail_partition_name)
    into l_execute_sql;

--     execute l_execute_sql;
   raise notice 'execute - %', l_execute_sql;

    select format('drop table partitions.%2$s_%3$s', in_schema_name, in_table_name, in_next_date_id)
    into l_execute_sql;

--     execute l_execute_sql;
   raise notice 'execute - %', l_execute_sql;

    select format(
                   'alter table  if exists %1$s.%2$s attach partition partitions.%3$s for values from (%4$s) to (%5$s)',
                   in_schema_name, in_table_name, in_tail_partition_name, in_min_date_id, in_next_next_date_id)
    into l_execute_sql;
--     execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;

    select public.load_log(l_load_id, l_step_id, l_message_text || 'COMPLETED===', 0, 'O')
    into l_step_id;
end ;
$procedure$
;
