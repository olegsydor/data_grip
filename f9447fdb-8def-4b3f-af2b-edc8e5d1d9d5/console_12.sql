-- DROP FUNCTION staging.fix_ptm_missed_r(int4);
create table if not exists staging.processed_ptm_missed_r
(
    trade_record_id int8 not null,
    db_create_time  timestamp default clock_timestamp()
);


CREATE OR REPLACE FUNCTION staging.fix_ptm_missed_r(in_date_id integer DEFAULT get_dateid(CURRENT_DATE))
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
    -- 20250327 OS: logging of processed ptm with missed R status into the table staging.processed_ptm_missed_r
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'fix_ptm_missed_r for ' || in_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;
    with base as (select tr.is_billed, tr.trade_record_id, tr.orig_trade_record_id, tr.exec_id
                  from genesis2.trade_record tr
                  where date_id = in_date_id
                    and tr.is_billed = 'N'
                    and tr.orig_trade_record_id is not null
                    and exists(select null
                               from genesis2.trade_record tri
                               where tri.date_id = in_date_id
                                 and tri.exec_id = tr.exec_id
                                 and tri.is_billed = 'R'
                                 and tri.trade_record_id < tr.trade_record_id))
       , upd as (update genesis2.trade_record tr
        set is_billed = 'R'
        from base
        where tr.trade_record_id = base.trade_record_id
            and tr.date_id = in_date_id
            and tr.is_billed <> 'R'
        returning tr.trade_record_id)
    insert
    into staging.processed_ptm_missed_r (trade_record_id)
    select upd.trade_record_id
    from upd;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'fix_ptm_missed_r for ' || in_date_id::text || ' COMPLETED ====', l_row_cnt, 'E')
    into l_step_id;
    return l_row_cnt;
end;

$function$
;
select * from staging.fix_ptm_missed_r2(20250326);

select * from staging.processed_ptm_missed_r
COMMENT ON FUNCTION staging.fix_ptm_missed_r(int4) IS 'The script fix the issue when trade_records exist with missed status R';
