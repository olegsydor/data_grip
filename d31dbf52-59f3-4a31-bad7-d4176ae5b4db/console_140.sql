call staging.f_moving_to_tail('dwh5', 'fictional_table', 20290101, 20200101);

drop procedure if exists staging.f_moving_to_tail;
create or replace procedure staging.f_moving_to_tail(in_schema_name text, in_table_name text,
                                                     in_tail_partition_name text, in_next_date_id int4,
                                                     in_min_date_id int4)
    language plpgsql
as
$pc$
declare
    l_load_id          int;
    l_step_id          int;
    l_message_text     text;
    l_execute_sql      text;
    l_next_max_date_id int4;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    l_message_text := 'f_moving_to_tail for ' || in_schema_name || '.' || in_table_name || ' ';

    select public.load_log(l_load_id, l_step_id, l_message_text || 'STARTED===', 0, 'O')
    into l_step_id;

    select format('alter table %1$s.%2$s DETACH PARTITION partitions.%2$s_%3$s', in_schema_name, in_table_name,
                  in_next_date_id)
    into l_execute_sql;
--          execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;
    select format('alter table %1$s.%2$s DETACH PARTITION partitions.%3$s', in_schema_name, in_table_name,
                  in_tail_partition_name)
    into l_execute_sql;
--          execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;

    select format('drop table partitions.%2$s_%3$s', in_schema_name, in_table_name, in_next_date_id)
    into l_execute_sql;
--          execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;
    --        psql -U dwh -h pgbigdata1.dashops.net -d big_data -c "alter table ${schema_name}.${table_name} DETACH PARTITION partitions.${table_name}_$next_date_id"
--        psql -U dwh -h pgbigdata1.dashops.net -d big_data -c "alter table ${schema_name}.${table_name} DETACH PARTITION partitions.${table_name}_tail2"
--        psql -U dwh -h pgbigdata1.dashops.net -d big_data -c "drop table partitions.${table_name}_$next_date_id"
    select dwh.get_dateid(public.get_business_date(to_date(in_min_date_id::text, 'YYYYMMDD'), 1, true))
    into l_next_max_date_id;

    select format(
                   'alter table  if exists %1$s.%2$s attach partition partitions.%3$s for values from (%4$s) to (%5$s)',
                   in_schema_name, in_table_name, in_tail_partition_name, in_min_date_id, l_next_max_date_id)
    into l_execute_sql;
--          execute l_execute_sql;
    raise notice 'execute - %', l_execute_sql;

    select public.load_log(l_load_id, l_step_id, l_message_text || 'COMPLETED===', 0, 'O')
    into l_step_id;
end ;
$pc$;