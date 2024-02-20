create or replace view db_management.v_partition_intervals as
select table_name,
       partition_name,
       (array_agg(partition_interval))[1]::int as date_from,
       (array_agg(partition_interval))[2]::int as date_to
from (select pgi.inhparent::regclass                                                       as table_name,
             pgi.inhrelid::regclass                                                        as partition_name,
             (regexp_matches(pg_get_expr(pt.relpartbound, pt.oid, true), '\d{8}', 'g'))[1] as partition_interval
      from pg_catalog.pg_inherits pgi
               join pg_catalog.pg_class pt on pt.oid = pgi.inhrelid
      where true
        and pt.relkind = 'r'
--          and pgi.inhparent = 'dwh.flat_trade_record'::regclass
     ) x
group by table_name, partition_name;



select * from db_management.v_partition_intervals