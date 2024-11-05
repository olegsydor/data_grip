
select tc.constraint_name, tc.constraint_schema,
'ALTER TABLE '||tc.constraint_schema||'.'||tc.table_name||' DROP CONSTRAINT '||tc.constraint_name||';' as execute_it
--        string_agg(c.column_name, ', ')
from information_schema.table_constraints as tc
         join information_schema.constraint_column_usage as ccu
              using (constraint_schema, constraint_name)
         join information_schema.columns c
              on c.table_schema = tc.constraint_schema and tc.table_name = c.table_name and
                 ccu.column_name = c.column_name
where tc.table_name ilike 'trade_record_%'
  and c.column_name = 'date_id'
group by tc.constraint_name, tc.constraint_schema, tc.table_name;


