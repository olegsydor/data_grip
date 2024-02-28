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
  and gos.create_date_id between 20240101 and 20240301
  and co.create_date_id between 20240101 and 20240301;

create index on trash.so_gtc_to_upd (create_date_id, order_id);