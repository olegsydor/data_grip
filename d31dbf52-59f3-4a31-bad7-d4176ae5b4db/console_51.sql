select co.order_id, co.create_date_id, co.instrument_id, co.multileg_reporting_type  from dwh.gtc_order_status gos
join dwh.client_order co
using (create_date_id, order_id)
where gos.instrument_id is null
and gos.create_date_id between 20210201 and 20210701
and co.create_date_id between 20210201 and 20210701