-- list of tables with specific column names

if exists (select null
from information_schema.tables t
         inner join information_schema.columns c on (c.table_name = t.table_name and c.table_schema = t.table_schema)
where t.table_schema = 'db_management'
  and t.table_name ilike 'table_retention'
and c.column_name = 'clean_order') then


do
$$
    begin
        update db_management.table_retention
        set roll_off_order = clean_order
        where clean_order is not null;
    exception
        when others then raise notice 'there is no the column clean_order';
    end;
$$;