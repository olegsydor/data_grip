select exec_time -  from dwh.execution
where exec_date_id >= to_char(public.get_business_date_back(current_date, 2), 'YYYYMMDD')::int
order by exec_id desc
limit 1



-- DROP FUNCTION staging.zabbix_monitor_f_parent_order();
select * from staging.zabbix_monitor_f_parent_order();

create or replace function staging.zabbix_monitor_f_parent_order(in_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4)
    returns integer
    language plpgsql
as
$function$
    -- 20251202 SO https://dashfinancial.atlassian.net/browse/DS-10809
declare
    l_min_date              int4 := in_date_id;
    l_max_subscription_time timestamp;
    l_min_subscription_time timestamp;
    l_diff                  numeric;
    l_allow_time            int4 := 600;
begin

    select coalesce(min(subscribe_time), clock_timestamp()), coalesce(max(subscribe_time), clock_timestamp())
    into l_min_subscription_time, l_max_subscription_time
    from public.etl_subscriptions
    where source_table_name = 'execution'
      and subscription_name = 'f_parent_order'
      and not is_processed
      and date_id = l_min_date;


    select extract(epoch from l_max_subscription_time - l_min_subscription_time)::int
    into l_diff;
--     raise notice 'diff - % (%-%)', l_diff, l_min_subscription_time, l_max_subscription_time;
    --     return case
--                when l_diff is null then 0 -- Alarm. Something wrong
--                when l_diff > l_allow_time then 2 -- Alarm. Too long
--                else 1 end; --Ok
    return l_diff;
end;
$function$
;

select *
      from public.etl_subscriptions
      where source_table_name = 'execution'
        and subscription_name = 'f_parent_order'
        and date_id = 20251203
        and not is_processed
