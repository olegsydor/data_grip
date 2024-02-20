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


select to_regclass('dwh.flat_trade_record')
select 'dwh.flat_trade_record'::regclass



select *
--              (regexp_matches(pg_get_expr(pt.relpartbound, pt.oid, true), '\d{8}', 'g'))[1] as partition_interval
      from pg_catalog.pg_class pt
      where true
        and pt.relkind = 'r'
and relname ilike 'flat_trade%';

select *
from  pg_partition_tree('flat_trade_record'::regclass) pin
left join pg_catalog.pg_class pt on pt.relname = pin
where parentrelid is not null;


select par.relname, chl.relname, pg_get_expr(chl.relpartbound, chl.oid, true)
from pg_inherits inh
    join pg_class par on inh.inhparent = par.oid
    join pg_class chl on inh.inhrelid = chl.oid
where par.relname='flat_trade_record';