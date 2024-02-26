-- DROP FUNCTION dwh.gtc_update_daily(int4, int4);

create or replace function trash.gtc_update_daily_new(p_start_date_id integer default null::integer, p_end_date_id integer default null::integer, p_only_show bool default false)
 returns integer
 language plpgsql
 SET application_name TO 'ETL: GTC update process'
AS $function$
-- 2022-09-02 https://dashfinancial.atlassian.net/browse/DS-5561 add logic to close gtc by parent executions
-- 2023-05-01 https://dashfinancial.atlassian.net/browse/DS-3581 closing heads after closing all legs
-- 2023-05-16 https://dashfinancial.atlassian.net/browse/DS-6745 closing head after at least one of legs was closed and then closing all other legs if the head was closed
-- 2023-08-17 https://dashfinancial.atlassian.net/browse/DS-7183 PD added multileg_order_id condition
-- 2024-01-08 https://dashfinancial.atlassian.net/browse/DS-7800 OS added a condition to prevent input end_date later then today
-- 2024-01-11 https://dashfinancial.atlassian.net/browse/DS-7809 OS added logging into dwh.fact_last_load_time for zabbix monitoring
-- 2024-02-26 OS performance improvement
declare
    l_row_cnt       int;
    l_row_cnt_total int;
    l_load_id       int;
    l_step_id       int;
    l_start_date_id int4;
    l_end_date_id   int4;
begin
    -- INTRO
    l_start_date_id = coalesce(p_start_date_id, to_char(public.get_last_workdate(), 'YYYYMMDD')::int);
    l_end_date_id = coalesce(p_end_date_id, to_char(current_date, 'YYYYMMDD')::int);
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' STARTED===', 0, 'O')
    into l_step_id;
    if l_end_date_id > to_char(current_date, 'YYYYMMDD')::int then
        select public.load_log(l_load_id, l_step_id,
                               'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                               ' Stopped as the end_date is further than today', -1, 'E')
        into l_step_id;
        return -1;
    end if;

    -- street/execution flow
    create temp table base_exec on commit drop as
    select co.order_id,
           iex.exec_time    as exec_time,
           iex.order_status as order_status,
           'E'              as closing_reason
    from dwh.gtc_order_status co
             join lateral (select iex.exec_time,
                                  iex.order_status
                           from dwh.execution iex
                           where true
                             and iex.order_id = co.order_id
                             and iex.order_status in ('2', '4', '8')
                             and exec_date_id between l_start_date_id and l_end_date_id
                           order by exec_id desc
                           limit 1) iex on true
    where co.close_date_id is null;

    if not p_only_show then
        update dwh.gtc_order_status co
        set exec_time      = base.exec_time,
            order_status   = base.order_status,
            close_date_id  = to_char(base.exec_time, 'YYYYMMDD')::int4,
            db_update_time = clock_timestamp(),
            closing_reason = base.closing_reason
        from base_exec base
        where base.order_id = co.order_id
          and co.close_date_id is null;
    end if;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt;

    -- parent flow
    create temp table base_parent on commit drop as
    select --par.order_id,
           co.order_id,
           iex_par.exec_time    as exec_time,
           iex_par.order_status as order_status,
           'P' as closing_reason
    from dwh.gtc_order_status co
             join dwh.client_order str
                  on str.order_id = co.order_id and str.create_date_id = co.create_date_id
             join lateral (select iex.exec_time,
                                  iex.order_status
                           from dwh.execution iex
                           where true
                             and iex.order_id = str.parent_order_id
                             and iex.order_status in ('2', '4', '8')
                             and exec_date_id between l_start_date_id and l_end_date_id
                           order by exec_id desc
                           limit 1) iex_par on true
    where co.close_date_id is null
      and str.parent_order_id is not null;

    if not p_only_show then
        update dwh.gtc_order_status co
        set exec_time      = base.exec_time,
            order_status   = base.order_status,
            close_date_id  = to_char(base.exec_time, 'YYYYMMDD')::int4,
            db_update_time = clock_timestamp(),
            closing_reason = closing_reason
        from base_parent base
        where base.order_id = co.order_id
          and co.close_date_id is null;
    end if;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' parent flow update', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    -- instrument flow
    if not p_only_show then
        update dwh.gtc_order_status co
        set close_date_id  = to_char(last_trade_date, 'YYYYMMDD')::int4,
            db_update_time = clock_timestamp(),
            closing_reason = 'I'
        where co.close_date_id is null
          and last_trade_date::date < l_end_date_id::text::date;
    else
        create temp table base_instrument on commit drop as
        select --par.order_id,
               gtc.order_id,
               gtc.exec_time    as exec_time,
               gtc.order_status as order_status,
               'I'              as closing_reason
        from dwh.gtc_order_status gtc
        where gtc.close_date_id is null
          and last_trade_date::date < l_end_date_id::text::date;
    end if;

    get diagnostics l_row_cnt = row_count;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' instrument/client order update', l_row_cnt, 'U')
    into l_step_id;

    -- head of multileg
    create temp table base_head as
    select --co.client_order_id,
           gtc.order_id,
           gtc.create_date_id,
           t.close_date_id,
           'L' as closing_reason
    from dwh.gtc_order_status gtc
             join lateral ( select multileg_reporting_type
                            from dwh.client_order co
                            where co.order_id = gtc.order_id
                              and co.create_date_id = gtc.create_date_id
                            limit 1) co on true
             join lateral (select g.close_date_id
                           from dwh.gtc_order_status g
                                    join dwh.client_order c
                                         on c.order_id = g.order_id and c.create_date_id = g.create_date_id
                           where c.client_order_id = gtc.client_order_id
                             and c.multileg_order_id = gtc.order_id
                             and c.multileg_reporting_type <> '3'
                             and g.close_date_id is not null
                           limit 1) t on true
    where true
      and gtc.close_date_id is null
      and co.multileg_reporting_type = '3'
    and exists (select null from dwh.gtc_order_status);

    update dwh.gtc_order_status gos
    set close_date_id  = base.close_date_id,
        db_update_time = clock_timestamp(),
        closing_reason = closing_reason
    from base_head base
    where gos.order_id = base.order_id
      and gos.create_date_id = base.create_date_id
      and gos.close_date_id is null;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Heads of multilegs after closed leg', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;
    -- legs after the head has been closed
    with base as (select --co.client_order_id,
                         gtc.order_id,
                         gtc.create_date_id,
                         t.close_date_id
                  from dwh.gtc_order_status gtc
                           join dwh.client_order co
                                on (co.order_id = gtc.order_id and co.create_date_id = gtc.create_date_id)
                           join lateral (select g.close_date_id
                                         from dwh.gtc_order_status g
                                                  join dwh.client_order c
                                                       on c.order_id = g.order_id and c.create_date_id = g.create_date_id
                                         where c.client_order_id = co.client_order_id
                                           and c.order_id = co.multileg_order_id
                                           and c.multileg_reporting_type = '3'
                                           and g.close_date_id is not null
                                         limit 1) t on true
                  where true
                    and gtc.close_date_id is null
                    and co.multileg_reporting_type <> '3')
    update dwh.gtc_order_status gos
    set close_date_id  = base.close_date_id,
        db_update_time = clock_timestamp(),
        closing_reason = 'H'
    from base
    where gos.order_id = base.order_id
      and gos.create_date_id = base.create_date_id
      and gos.close_date_id is null;
    get diagnostics l_row_cnt = row_count;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Legs after the heads was closed', l_row_cnt, 'U')
    into l_step_id;
    -- Logging into the table dwh.fact_last_load_time
   perform dwh.p_upd_fact_last_load_time('GTC_ORDER_STATUS');
   select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Logging into GTC_ORDER_STATUS', 1, 'U')
    into l_step_id;
    -- End of logging into the table dwh.fact_last_load_time
 select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' COMPLETED===',
                           l_row_cnt_total,
                           'U')
    into l_step_id;
    return l_row_cnt_total;
end;
$function$
;

COMMENT ON FUNCTION dwh.gtc_update_daily(int4, int4) IS 'updates all gtc orders in dwh.gtc_order_status regarding to execution have appeared between two input date_ids';
