with tm as (select extract('hour' from clock_timestamp()) as hr)
   , grp as (select dl.date_id,
                    tm.hr               as hr,
                    sum(dl.loaded_rows) as current_hour,
                    sum(case
                            when end_processing < (fl.date_id::text::date + '1 hour'::interval * tm.hr)
                                then dl.loaded_rows
                            else 0 end) as prev_hour

             from loader.files fl
                      join loader.daily_load dl using (date_id, file_id)
                      join tm on true
             where dl.date_id >= 20260803
               and true
               and end_processing < (fl.date_id::text::date + '1 hour'::interval * (tm.hr + 1))
             group by dl.date_id, tm.hr)
select case when date_id = to_char(current_date, 'YYYYMMDD')::int then true else false end,
       date_id,
       hr,
       to_char(current_hour, 'FM9,999,999,990') as current_hour,
       to_char(prev_hour, 'FM9,999,999,990')    as prev_hour
from grp
where true
order by current_hour desc;


SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'hft_fix_message_event_20260928';


--Active processes
SELECT pid, * --procpid, age(clock_timestamp(), query_start), usename, current_query
FROM pg_stat_activity
WHERE state = 'active'
-- and application_name = 'psql'
-- and query like '%public.check_timeout%'
ORDER BY query_start desc;


select activity.pid,
       activity.usename,
       activity.query,
       blocking.pid   as blocking_id,
       blocking.query as blocking_query
from pg_stat_activity as activity
         join pg_stat_activity as blocking on blocking.pid = any (pg_blocking_pids(activity.pid));


select relid::regclass, index_relid::regclass, *
from pg_stat_progress_create_index;





select *
from (select node_name,
             sum(case when loading_status = 'E' then end_position - start_position else 0 end) as "All rows",
             sum(loaded_rows)                                                                  as "Loaded_rows",
             sum(case when loading_status = 'A' then 1 else 0 end)                             as "Unfinished processes",
             sum(case when loading_status = 'S' then 1 else 0 end)                             as "Processes in progress",
             sum(case when loading_status = 'S' then end_position - start_position else 0 end) as "Rows in progress"
      from loader.files
               left join loader.daily_load using (date_id, file_id)
      where date_id = to_char(current_date, 'YYYYMMDD')::int -- 5
        and true
      group by node_name
      union all
      select 'total',
             sum(case when loading_status = 'E' then end_position - start_position else 0 end) as finished,
             sum(loaded_rows)                                                                  as "Loaded_rows",
             sum(case when loading_status = 'A' then 1 else 0 end)                             as unfinished,
             sum(case when loading_status = 'S' then 1 else 0 end)                             as in_progress_cnt,
             sum(case when loading_status = 'S' then end_position - start_position else 0 end) as in_progress
      from loader.daily_load --using (date_id, file_id)
      where date_id = to_char(current_date, 'YYYYMMDD')::int -- 5
        and true) x
order by 1;



-------

-- DROP FUNCTION inc_hft.zabbix_monitor_check_loading();

CREATE OR REPLACE FUNCTION inc_hft.zabbix_monitor_check_loading()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
    -- 20240215 SO https://dashfinancial.atlassian.net/browse/DS-7883
    -- 20240219 SO view with interval of dates was used to check if partition has been created
/*
the script checks:
before 11 - the presence of the daily partition
11-17 running of the incremental process: non-null count of rows in progress or recent run of the process even though the count of rows was 0
17+ indicator of the finishing all processes and attaching partition
if ok - returns 1 else -1
 */
declare
    l_sum         int4;
    l_last_time   timestamp;
    l_date_id     int4 := to_char(current_date, 'YYYYMMDD')::int4;
    l_err_message text;
    l_allow bool;

begin
    select count(distinct regexp_match(file_name, '(.*)/log')) = 25
    into l_allow
    from loader.files
    where date_id = l_date_id;

    if not l_allow then
        return -1;
    end if;

    select count(*) = 1
    into l_allow
    from inc_hft.v_partitions
    where date_from <= l_date_id
      and date_to > l_date_id;
    if not l_allow then
        return -1;
    end if;

    if current_time > '17:01'::time then
        select count(*) = 1
        into l_allow
        from staging.load_finish
        where date_id = l_date_id;
        if l_allow then
            return 1;
        end if;
    end if;

end;
$function$
;


select *
       from loader.files
         join loader.daily_load using (date_id, file_id)
where date_id = to_char(current_date, 'YYYYMMDD')::int
and loading_status <> 'E'