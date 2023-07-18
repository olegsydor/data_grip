select
_db_create_time, _db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central' as _db_create_time,
* from blaze7.tprices_edw
where "_order_id" = 535802370555133952;


select now() at time zone 'UTC',
       now() at time zone 'US/Central',
       now() at time zone 'Est'
