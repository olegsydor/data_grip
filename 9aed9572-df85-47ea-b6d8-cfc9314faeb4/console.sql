select
_db_create_time, _db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central' as _db_create_time,
* from blaze7.tprices_edw
where "_order_id" = 535802370555133952;


select
_db_create_time as "UTC",
_db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central' as _db_create_time,
_db_create_time at time zone 'US/Central' as _db_create_time
from blaze7.tprices_edw
where _db_create_time::date = '2023-07-18'
    and "_order_id" = 535822291003523072;
