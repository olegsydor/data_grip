drop table if exists training.check_big_operation;
create table training.check_big_operation
(
    big_operation_id int8      not null
        constraint big_operation_id_pk primary key,
    operation_number int4      not null,
    operation_text   text,
    db_create_time   timestamp not null default clock_timestamp(),
    db_update_time   timestamp
);

select * from training.f_big_operation_processing()

create or replace function training.f_big_operation_processing()
    returns int4
    language plpgsql
as
$fn$
declare
    l_row_ins int4;
    l_row_del int4 := 0;
begin
    -- insert/update part

    create temp table t_ins on commit drop as
    select distinct round(random() * 150000000) as id,
                    round(random() * 10000)     as num,
                    md5(random()::text)         as txt
    from generate_series(1, 10000) s(i);

    insert into training.check_big_operation (big_operation_id, operation_number, operation_text)
    select distinct on (id) id,
                            num,
                            txt
    from t_ins
    on conflict (big_operation_id) do update
        set operation_number = excluded.operation_number,
            operation_text   = excluded.operation_text,
            db_update_time   = clock_timestamp();

    get diagnostics l_row_ins = row_count;

    -- delete part
    delete
    from training.check_big_operation
    where big_operation_id in (select round(random() * 150000000) as id
                               from generate_series(1, 10000) s(i));

    get diagnostics l_row_del = row_count;

    return l_row_ins - l_row_del;
end;
$fn$;

select count(*) from training.check_big_operation
