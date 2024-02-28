drop table trash.so_gtc_to_upd;
create table trash.so_gtc_to_upd as
select co.order_id, co.create_date_id, co.instrument_id, co.multileg_reporting_type
from dwh.gtc_order_status gos
         join lateral (select co.order_id, co.create_date_id, co.instrument_id, co.multileg_reporting_type
                       from dwh.client_order co
                       where co.create_date_id = gos.create_date_id
                         and co.order_id = gos.order_id
                       limit 1) co on true
where gos.instrument_id is null
  and gos.create_date_id between 20220101 and 20220630
  and co.create_date_id between 20220101 and 20220630;

create index on trash.so_gtc_to_upd (create_date_id, order_id);


select create_date_id, count(*) from dwh.gtc_order_status
where instrument_id is null
group by create_date_id
