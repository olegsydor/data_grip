select * from db_management.table_retention;

insert into db_management.table_retention (schema_name, table_name, retention_period, cleanup_schedule, key_field, is_active, retention_type, roll_off_order)
values ('partitions', 'hft_fix_message_event__________inc', 20, 'DAY', 'date_id', true, 'T',null);

select * from db_management.table_retention where is_active and retention_type = 'T';




with arr as (
    select array_agg(to_char(dt, '%'||'YYYYMMDD'||'%')) as days from generate_series(current_date - ('1 day'::interval * 15) , current_date, interval '1 day') as dt
)
-- select array_agg(to_char(dt, 'YYYYMMDD')) from generate_series(current_date - ('1 day'::interval * 10) , current_date, interval '1 day') as dt
select distinct t.table_schema, t.table_name--, c.column_name
from information_schema.tables t
         inner join information_schema.columns c on (c.table_name = t.table_name and c.table_schema = t.table_schema)
inner join arr on true
where t.table_schema = 'partitions'
and t.table_name ilike 'hft_fix_message_event__________inc'
--  and t.table_name ilike '%20231208%'
and t.table_name !~~ all(arr.days);

