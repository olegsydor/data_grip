create function inc_hft.zabbix_check_loading()
    returns int4
    language plpgsql
as
$fx$
    -- 20240215 SO https://dashfinancial.atlassian.net/browse/DS-7883
/*
the script checks:
before 11 - the presence of the daily partition
11-17 running of the incremental process: non-null count of rows in progress or recent run of the process even though the count of rows was 0
17+ indicator of the finishing all processes
if ok - returns 1 else -1
 */
declare
    l_sum       int4;
    l_last_time timestamp;
    l_date_id   int4 := to_char(current_date, 'YYYYMMDD')::int4;
    l_err_message text;
    l_ret_value int4;

begin
    if current_time < '11:00'::time
        and exists (select null
                    from information_schema.tables
                    where table_schema = 'partitions'
                      and table_name = 'hft_fix_message_event_' || :l_date_id::text) then
        return 1;
    else
        l_err_message = 'Partition is absent'
    end if;

    if current_time > '17:01'::time
        and exists (select null from inc_hft.load_finish where date_id = l_date_id) or (select * from inc_hft.unfinished_hft_inc(:l_date_id)) > 0 then
        return 1;
    end if;


        if current_time > '17:30'::time
        and exists (select null from inc_hft.load_finish where date_id = l_date_id) then
        return 1;
        else l_err_message = 'The process was not finished even after 17:30';
    end if;

    if current_time < '17:00'::time then
                                               select sum(end_position - start_position), max(start_processing)
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
                                                  extract(seconds from clock_timestamp()::time - l_last_time::time) <
                                                  120 then
                                                   return 1;
                                               elsif
                                                   inc_hft.unfinished_hft_inc(l_date_id) = 0 then
                                                   return 1;
                                               else
                                                   return -1;
                                               end if;


        else raise notice '3 - %', clock_timestamp();
        end;
end;

$fx$

select extract(seconds from clock_timestamp()::time - '2024-02-15 13:40:29'::time)