select min(child)::int
from (select right(child.relname, 8) as child
      from pg_inherits
               join pg_class parent on pg_inherits.inhparent = parent.oid
               join pg_class child on pg_inherits.inhrelid = child.oid
               join pg_namespace nmsp_parent on nmsp_parent.oid = parent.relnamespace
      where parent.relname like 'fix_message_json'
        and nmsp_parent.nspname = 'fix_capture'
        and length(child.relname) > 6) l;


select child
from (select right(child.relname, 8) as child
      from pg_inherits
               join pg_class parent on pg_inherits.inhparent = parent.oid
               join pg_class child on pg_inherits.inhrelid = child.oid
               join pg_namespace nmsp_parent on nmsp_parent.oid = parent.relnamespace
      where parent.relname like 'fix_message_json'
        and nmsp_parent.nspname = 'fix_capture'
        and length(child.relname) > 6
      order by 1) l
order by 1
limit 1 offset 1;


select tr.table_name
from db_management.table_retention tr
where tr.schema_name = 'consolidator'
  and tr.table_name != 'consolidator_message'
  and is_active
union all
select 'consolidator_message'