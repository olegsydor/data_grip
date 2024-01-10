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

select * from unnest(:arr1)
         as 
where unnest > clock_timestamp()
order by 1

create or replace function staging.gtc_last_load_monitor()
    returns int4
    language plpgsql
as
$fx$
    -- 20240110 SO https://dashfinancial.atlassian.net/browse/DS-7809
declare
    check_points text[] := array ['01:20', '16:20', '22:20'];
    check_point  text;
    l_last_update timestamp;
begin
select latest_load_time
into l_last_update
from dwh.fact_last_load_time
where table_name = 'gtc_order_status';

    for check_point in (select unnest(check_points) order by 1 desc)
        loop
            raise notice 'check_point - %', current_date + check_point::interval;
            if clock_timestamp() > current_date + check_point::interval then
                                raise notice 'here we are - %', check_point;
                                exit
            end if;
        end loop;
    return 1;
end;
$fx$

select * from staging.gtc_last_load_monitor()