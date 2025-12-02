select exec_time -  from dwh.execution
where exec_date_id >= to_char(public.get_business_date_back(current_date, 2), 'YYYYMMDD')::int
order by exec_id desc
limit 1



-- DROP FUNCTION staging.zabbix_monitor_gtc_last_load();
select * from staging.zabbix_monitor_f_parent_order()

create or replace function staging.zabbix_monitor_f_parent_order()
    returns integer
    language plpgsql
as
$function$
    -- 20251202 SO
declare
    l_min_date          int4 := to_char(public.get_business_date_back(current_date, 2), 'YYYYMMDD')::int;
    l_exec_time         timestamp;
    l_subscription_time timestamp;
    l_diff              numeric;
    l_allow_time        int4 := 600;
begin
    -- getting the last time from loaded execution
    select exec_time
    into l_exec_time
    from dwh.execution
    where exec_date_id >= l_min_date
    order by exec_id desc
    limit 1;

    select min(subscribe_time)
    into l_subscription_time
    from public.etl_subscriptions
    where source_table_name = 'execution'
      and subscription_name = 'f_parent_order'
      and not is_processed
      and date_id >= l_min_date;


    select extract(epoch from l_exec_time - l_subscription_time)::int
    into l_diff;

    return case
               when l_diff is null then 0 -- Alarm. Something wrong
               when l_diff > l_allow_time then 2 -- Alarm. Too long
               else 1 end; --Ok
end;
$function$
;

