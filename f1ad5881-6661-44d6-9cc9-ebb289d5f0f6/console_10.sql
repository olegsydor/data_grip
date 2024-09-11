select * from dwh.execution
where exec_date_id = 20240910;

select * from dwh.gtc_order_status;
select * from dwh.gtc_restate_daily(20240911, 20240911);

create or replace function dwh.gtc_restate_daily(p_start_date_id integer default null::integer,
                                                 p_end_date_id integer default null::integer)
    returns integer
    language plpgsql
AS
$function$
-- 2024-09-11 SO https://dashfinancial.atlassian.net/browse/DS-8855 reusing of last_mod_date_is as date of the last restate of order (exec_status = 'D' in execution)
declare
    l_row_cnt       int;
    l_load_id       int;
    l_step_id       int;
    l_start_date_id int4;
    l_end_date_id   int4;
begin
    --	return -1;
    l_start_date_id = coalesce(p_start_date_id, to_char(public.get_last_workdate(), 'YYYYMMDD')::int);
    l_end_date_id = coalesce(p_end_date_id, to_char(current_date, 'YYYYMMDD')::int);

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_restate_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' STARTED===', 0, 'B')
    into l_step_id;

    if l_end_date_id > to_char(current_date, 'YYYYMMDD')::int then
        select public.load_log(l_load_id, l_step_id,
                               'gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                               ' Stopped as the end_date is further than today', -1, 'E')
        into l_step_id;
        return -1;
    end if;

    -- Aggregating data
-- street/execution flow
    drop table if exists staging.gtc_restate_modif;
    create table staging.gtc_restate_modif as
    select gtc.order_id,
           gtc.create_date_id,
           iex.close_date_id as last_mod_date_id,
           'R'               as order_status
    from dwh.gtc_order_status gtc
             join lateral (select public.get_gth_date_id_by_instrument(iex.exec_time,
                                                                       gtc.instrument_id) as close_date_id
                           from dwh.execution iex
                           where true
                             and iex.order_id = gtc.order_id
                             and iex.exec_type = '0'
                             and exec_date_id between l_start_date_id and l_end_date_id
                           order by exec_id desc
                           limit 1) iex on true
    where gtc.close_date_id is null;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_restate_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;

    update dwh.gtc_order_status gtc
    set last_mod_date_id = base.last_mod_date_id,
        db_update_time   = clock_timestamp() --??
    from staging.gtc_restate_modif base
    where gtc.order_id = base.order_id
      and gtc.create_date_id = base.create_date_id
      and gtc.close_date_id is null
      and gtc.last_mod_date_id < base.last_mod_date_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_restate_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' FINISHED===', l_row_cnt, 'E')
    into l_step_id;

    return l_row_cnt;
end;
$function$
;
