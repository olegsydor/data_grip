create schema staging;
select * from dwh.fact_last_load_time;

insert into dwh.fact_last_load_time (table_name)
values ('gtc_order_status');

select latest_load_time
from dwh.fact_last_load_time
where table_name = 'gtc_order_status';

update dwh.fact_last_load_time
set latest_load_time = clock_timestamp()
where table_name = 'gtc_order_status';


do
$$
    declare
        arr1 text[] := array['01:20', '16:20', '22:30'];
        x text;
    begin
        for x in ( ) LOOP
                raise notice '%', x;
            end loop;
    end;
$$;


create or replace function staging.gtc_last_load_monitor()
    returns int4
    language plpgsql
as
$fx$
    -- 20240110 SO https://dashfinancial.atlassian.net/browse/DS-7809
declare
    check_points  text[] := array ['01:20', '16:20', '22:20', '12:51'];
    check_point   time;
    check_ts      timestamp;
    l_last_update timestamp;
    l_delay interval := '7 minutes';
begin
    -- getting the last time where gtc_update_status has successfully finished
    select latest_load_time
    into l_last_update
    from dwh.fact_last_load_time
    where table_name = 'gtc_order_status';

    raise notice 'l_last_update - %', l_last_update;

-- counting of the last time where gtc_update_status should have been processed
    select tm::time
    into check_point
    from unnest(check_points)
             as data(tm)
    where tm::time < clock_timestamp()::time - l_delay
    order by tm desc
    limit 1;

    if check_point is null then
        select tm::time
        into check_point
        from unnest(check_points)
                 as data(tm)
        order by tm desc
        limit 1;
        check_ts = current_date - '1 day'::interval + check_point;
    else
        check_ts = current_date + check_point;
    end if;

    raise notice 'check_point - %', check_point;

    if l_last_update > check_ts then
        raise notice 'Ok';
        return 1;
    else
        raise notice 'Alarm';
        return 0;
    end if;

end;
$fx$;

select * from staging.gtc_last_load_monitor()

select clock_timestamp()