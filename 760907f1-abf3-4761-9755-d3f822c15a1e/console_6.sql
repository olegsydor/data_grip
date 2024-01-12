select * from staging.test_sql ()

create or replace function staging.test_sql ()
returns int4
language plpgsql
as $$
begin
    return 1;
end;
    $$