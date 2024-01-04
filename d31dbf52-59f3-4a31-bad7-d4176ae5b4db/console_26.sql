 l_start_date_id = select coalesce(:p_start_date_id, to_char(public.get_last_workdate('2023-11-23'), 'YYYYMMDD')::int); -- 20231122
    l_end_date_id = select coalesce(:p_end_date_id, to_char(current_date, 'YYYYMMDD')::int);

    -- street flow
    with base as (select co.order_id,
                         iex.exec_time    as exec_time,
                         iex.order_status as order_status
                  from dwh.gtc_order_status co
                           join lateral (select iex.exec_time,
                                                iex.order_status
                                         from dwh.execution iex
                                         where true
                                           and iex.order_id = co.order_id
                                           and iex.order_status in ('2', '4', '8')
                                           and exec_date_id between :l_start_date_id and :l_end_date_id
                                         order by exec_id desc
                                         limit 1) iex on true
                  where co.close_date_id is null)
    select * from dwh.gtc_order_status co, base
   where co.order_id = base.order_id
      and co.close_date_id is null;

    with base as (select --par.order_id,
                         co.order_id,
                         iex_par.exec_time    as exec_time,
                         iex_par.order_status as order_status
                  from dwh.gtc_order_status co
                           join dwh.client_order str
                                on str.order_id = co.order_id and str.create_date_id = co.create_date_id
                           join lateral (select iex.exec_time,
                                                iex.order_status
                                         from dwh.execution iex
                                         where true
                                           and iex.order_id = str.parent_order_id
                                           and iex.order_status in ('2', '4', '8')
                                           and exec_date_id between :l_start_date_id and :l_end_date_id
                                         order by exec_id desc
                                         limit 1) iex_par on true
                  where co.close_date_id is null
                    and str.parent_order_id is not null)
    select * from dwh.gtc_order_status co, base

    where base.order_id = co.order_id
      and co.close_date_id is null;

    -- head of multileg
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
                                           and c.multileg_order_id = co.order_id
                                           and c.multileg_reporting_type <> '3'
                                           and g.close_date_id is not null
                                         limit 1) t on true
                  where true
                    and gtc.close_date_id is null
                    and co.multileg_reporting_type = '3')
    update dwh.gtc_order_status gos
    set close_date_id  = base.close_date_id,
        db_update_time = clock_timestamp(),
        closing_reason = 'L'
    from base
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