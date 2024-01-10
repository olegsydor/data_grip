select * from dwh.fact_last_load_time;

insert into dwh.fact_last_load_time (table_name)
values ('gtc_order_status');

select latest_load_time
from dwh.fact_last_load_time
where table_name = 'gtc_order_status';

update dwh.fact_last_load_time
set latest_load_time = clock_timestamp()
where table_name = 'gtc_order_status';