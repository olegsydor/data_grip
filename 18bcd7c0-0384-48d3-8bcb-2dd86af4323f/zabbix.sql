-- DROP FUNCTION inc_hft.zabbix_monitor_check_loading();

CREATE OR REPLACE FUNCTION inc_hft.zabbix_monitor_check_loading0()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
    -- 20240215 SO https://dashfinancial.atlassian.net/browse/DS-7883
    -- 20240219 SO view with interval of dates was used to check if partition has been created
    -- 20240923 SO https://dashfinancial.atlassian.net/browse/DS-8902 changing scrip after migration into incremental loading
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

begin
--	return -1;
    case
        -- check if the partition for eod loading is presence
        when current_time < '11:00'::time then if exists (select null
                                                          from inc_hft.v_partitions
                                                          where date_from <= l_date_id
                                                            and date_to > l_date_id) then
            raise notice '%: < 11:00 ok. The partition for EOD is ready', clock_timestamp();
            return 1;
        else
            l_err_message = 'Partition is absent';
        end if;

        when current_time > '17:30'::time
            then if exists (select null from inc_hft.load_finish where date_id = l_date_id) then
                raise notice '%: > 17:30 ok', clock_timestamp();
                return 1;
            else
                l_err_message = 'The processes were not finished even after 17:30';
            end if;

        when current_time > '17:02'::time
            then if (exists (select null from inc_hft.load_finish where date_id = l_date_id) or
                     (select * from inc_hft.unfinished_hft_inc(l_date_id)) > 0) then
                raise notice '%: > 17:02 ok', clock_timestamp();
                return 1;
            else
                l_err_message = 'Unable to attach partition';
            end if;
        else select sum(end_position - start_position), max(start_processing)
             into l_sum, l_last_time
             from (select filename,
                          start_processing,
                          start_position,
                          end_position,
                          is_processed,
                          row_number()
                          over (partition by filename order by is_processed, start_processing desc) as rn
                   from inc_hft.hft_incremental_files hif
                   where date_id = l_date_id
                     and start_processing is not null) ct
             where rn <= 2;
             if l_sum > 0 or
                extract(seconds from clock_timestamp()::time - l_last_time::time) < 120 then
                 raise notice '%: 11-17 % - % ok', clock_timestamp(), clock_timestamp()::time, l_last_time::time;
                 return 1;
             elsif
                 inc_hft.unfinished_hft_inc(l_date_id) = 0 then
                 raise notice '%: 11-17 inc_hft.unfinished_hft_inc(l_date_id) = 0 ok', clock_timestamp();
                 return 1;
             else
                 l_err_message = 'Looks like process was stopped';
             end if;
        end case;

    raise notice 'Error: %', l_err_message;
    return -1;
end;
$function$
;
