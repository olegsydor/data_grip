create or replace procedure training.each_commit(in_date_id int4)
    language plpgsql
as
$prc$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    begin
        insert into training.chk1 (ts)
        select (clock_timestamp() + '1 second'::interval * round(random() * 1000000))
        from
            generate_series(1, 100);
        commit;
    end;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg for ' || in_date_id::text || ' STARTED ===',
                           0, 'O')
    into l_step_id;
    begin
        perform 1 / 0;
        commit;

    end;
end;
$prc$;

call training.each_commit();

select * from training.chk1;

select version()