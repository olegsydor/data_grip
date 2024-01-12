-- DROP FUNCTION dwh.p_upd_fact_last_load_time(varchar);

CREATE OR REPLACE FUNCTION dwh.p_upd_fact_last_load_time(in_table_name character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
-- OS: 20210822 DS-2624. replaced int4 by int8 for trade_record_id and orig_trade_record_id
-- OS: 20220822 https://dashfinancial.atlassian.net/browse/DEVREQ-2155 changed counting of delay for FYC
-- PD: 20220927 https://dashfinancial.atlassian.net/browse/DS-5662 changed order by statement to improve FYC delay checking
-- SY: 20221209 DS-5978 Greatest has bee added for execution flow to avoid backward  move
-- SO: 20240111 https://dashfinancial.atlassian.net/browse/DS-7809 Added the case for GTC_ORDER_STATUS

declare
    l_curr_date_id          int;
    l_max_time_stamp        timestamp;
    l_in_table_name         varchar;
    l_curr_table_name       varchar;
    --> dwh.client_order
    l_max_order_id          bigint;
    l_max_process_time      timestamp;
    --> dwh.flat_trade_record
    l_max_trade_record_id   int8;
    l_max_trade_record_time timestamp;
    --> dwh.bloomberg_hods (yiled_capture)
    l_max_bh_order_id       bigint;
    l_max_bh_exec_time      timestamp;
    --> tca.order_tca
    l_max_tca_date_id       integer;
    l_max_last_trade_time   timestamp;
    --> dwh.execution
    l_max_exec_id           bigint;
    l_max_exec_time         timestamp;




BEGIN

    -- get date_id for 5 days ago
    select to_char(public.get_last_workdate(), 'YYYYMMDD')::int into l_curr_date_id;
    select UPPER(COALESCE(in_table_name, 'ALL'::varchar)) into l_in_table_name;

--------------------------------------------------------------------------------
l_curr_table_name := 'CLIENT_ORDER'::varchar;
IF l_in_table_name = l_curr_table_name OR l_in_table_name = 'ALL'
then
-- > dwh.client_order
-- get max ID via index on last partitions
select COALESCE(max(t.order_id),0) into l_max_order_id
from dwh.client_order t
where t.create_date_id >= l_curr_date_id;


select max(process_time) into l_max_process_time
from dwh.client_order t
where create_date_id >= l_curr_date_id
  and order_id >= l_max_order_id;

  RAISE NOTICE 'Order ID %', l_max_order_id;
  RAISE NOTICE 'Process Time %', l_max_process_time;

  l_max_time_stamp := l_max_process_time;

  insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
  select l_curr_table_name as table_name
         , l_max_time_stamp as latest_load_time
         , clock_timestamp() as pg_db_updated_time
  on conflict (table_name) do
  update set
    latest_load_time = excluded.latest_load_time,
    pg_db_updated_time = excluded.pg_db_updated_time;
END IF;

--------------------------------------------------------------------------------
l_curr_table_name := 'FLAT_TRADE_RECORD'::varchar;
IF l_in_table_name = l_curr_table_name OR l_in_table_name = 'ALL'
then
-- > dwh.flat_trade_record
-- get max ID via index on last partitions
select COALESCE(max(t.trade_record_id),0) into l_max_trade_record_id
from dwh.flat_trade_record t
where  t.date_id  >=  l_curr_date_id
    and  coalesce(t.trade_record_reason,  '-1')  not  in  ('A','P')
;


select max(t.trade_record_time) into l_max_trade_record_time
from dwh.flat_trade_record t
where t.date_id >= l_curr_date_id
  and t.trade_record_id >= l_max_trade_record_id;

  RAISE NOTICE 'flat_trade_record ID %', l_max_trade_record_id;
  RAISE NOTICE ' Time %', l_max_trade_record_time;
  --RETURN l_max_process_time;

  l_max_time_stamp := l_max_trade_record_time;


  insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
  select l_curr_table_name as table_name
         , l_max_time_stamp as latest_load_time
         , clock_timestamp() as pg_db_updated_time
  on conflict (table_name) do
  update set
    latest_load_time = excluded.latest_load_time,
    pg_db_updated_time = excluded.pg_db_updated_time;

    RAISE NOTICE ' Upsert done  %', clock_timestamp();
END IF;

--------------------------------------------------------------------------------
l_curr_table_name := 'YILED_CAPTURE'::varchar;
IF l_in_table_name = l_curr_table_name  OR l_in_table_name = 'ALL'
then
-- > dwh.bloomberg_hods - yiled_capture
-- get max ID via index on last partitions
select COALESCE(max(t.order_id),0) into l_max_bh_order_id
from data_marts.f_yield_capture t
where t.status_date_id >= public.get_dateid(current_date - 3);

--select max(t.exec_time) into l_max_bh_exec_time
--from data_marts.f_yield_capture t
--where t.order_id >= l_max_bh_order_id;

-- added by SO in order to get delay for FYC more accurate (3 rows above were commented) -- begin
with ct as (select load_batch_id, date_id
            from public.etl_subscriptions su
            where subscription_name = 'yield_capture'
              and source_table_name = 'execution'
              and is_processed
              and date_id >= l_curr_date_id
            order by subscribe_time desc
            limit 1)
select max(e.exec_time)
into l_max_bh_exec_time
from execution e
         join ct on e.exec_date_id = ct.date_id and e.dataset_id = ct.load_batch_id
where exec_date_id >= public.get_dateid(current_date - 63);
-- added by SO in order to get delay for FYC more accurate (3 rows above were commented) -- end

  RAISE NOTICE 'YILED_CAPTURE ID %', l_max_bh_order_id;
  RAISE NOTICE 'Time %', l_max_bh_exec_time;
  --RETURN l_max_process_time;

  l_max_time_stamp := l_max_bh_exec_time;


  insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
  select l_curr_table_name as table_name
         , l_max_time_stamp as latest_load_time
         , clock_timestamp() as pg_db_updated_time
  on conflict (table_name) do
  update set
    latest_load_time = excluded.latest_load_time,
        pg_db_updated_time  =  excluded.pg_db_updated_time
      where  fact_last_load_time.latest_load_time<excluded.latest_load_time;

END IF;

--------------------------------------------------------------------------------
l_curr_table_name := 'ORDER_TCA'::varchar;
IF l_in_table_name = l_curr_table_name OR l_in_table_name = 'ALL'
then
-- > tca.order_tca
/*
select max(t.date_id) into l_max_tca_date_id
from tca.order_tca t;
*/

select max(t.last_trade_time) into l_max_last_trade_time
from tca.order_tca t
where t.date_id >= l_curr_date_id; --l_max_tca_date_id;

  RAISE NOTICE 'order_tca ID %', l_max_tca_date_id;
  RAISE NOTICE 'Time %', l_max_last_trade_time;
  --RETURN l_max_process_time;

  l_max_time_stamp := l_max_last_trade_time;

  insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
  select l_curr_table_name as table_name
         , l_max_time_stamp as latest_load_time
         , clock_timestamp() as pg_db_updated_time
  on conflict (table_name) do
  update set
    latest_load_time = excluded.latest_load_time,
    pg_db_updated_time = excluded.pg_db_updated_time;

END IF;

--------------------------------------------------------------------------------
l_curr_table_name := 'EXECUTION'::varchar;
IF l_in_table_name = l_curr_table_name OR l_in_table_name = 'ALL'
then
-- > dwh.execution
-- get max ID via index on last partitions
 select COALESCE(max(exec_id),0) into l_max_exec_id
 from dwh.execution t
 where t.exec_date_id >= l_curr_date_id;


select max(exec_time) into l_max_exec_time
from dwh.execution t
where t.exec_date_id >= l_curr_date_id
and t.exec_id >= l_max_exec_id;

  --RAISE NOTICE 'execution ID %', l_max_exec_id;
  RAISE NOTICE 'Time %', l_max_exec_time;
  --RETURN l_max_process_time;

  l_max_time_stamp := l_max_exec_time;

  insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
  select l_curr_table_name as table_name
         , l_max_time_stamp as latest_load_time
         , clock_timestamp() as pg_db_updated_time
  on conflict (table_name) do
  update set
    latest_load_time = greatest(fact_last_load_time.latest_load_time, excluded.latest_load_time),
    pg_db_updated_time = excluded.pg_db_updated_time;

END IF;


--------------------------------------------------------------------------------
    l_curr_table_name := 'GTC_ORDER_STATUS'::varchar;
    IF l_in_table_name = l_curr_table_name-- OR l_in_table_name = 'ALL'
    then
        -- > dwh.gtc_order_status
        insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
        select l_curr_table_name as table_name
             , now()             as latest_load_time
             , clock_timestamp() as pg_db_updated_time
        on conflict (table_name) do update set latest_load_time   = excluded.latest_load_time,
                                               pg_db_updated_time = excluded.pg_db_updated_time;

    END IF;


END;
$function$
;



-- DROP FUNCTION dwh.gtc_update_daily(int4, int4);

CREATE OR REPLACE FUNCTION dwh.gtc_update_daily(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL: GTC update process'
AS $function$
    -- 2022-09-02 https://dashfinancial.atlassian.net/browse/DS-5561 add logic to close gtc by parent executions
-- 2023-05-01 https://dashfinancial.atlassian.net/browse/DS-3581 closing heads after closing all legs
-- 2023-05-16 https://dashfinancial.atlassian.net/browse/DS-6745 closing head after at least one of legs was closed and then closing all other legs if the head was closed
-- 2023-08-17 https://dashfinancial.atlassian.net/browse/DS-7183 PD added multileg_order_id condition
-- 2024-01-08 https://dashfinancial.atlassian.net/browse/DS-7800 OS added a condition to prevent input end_date later then today
-- 2024-01-11 https://dashfinancial.atlassian.net/browse/DS-7809 OS added logging into dwh.fact_last_load_time for zabbix monitoring
declare
    l_row_cnt       int;
    l_row_cnt_total int;
    l_load_id       int;
    l_step_id       int;
    l_start_date_id int4;
    l_end_date_id   int4;

begin
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
                                           and exec_date_id between l_start_date_id and l_end_date_id
                                         order by exec_id desc
                                         limit 1) iex on true
                  where co.close_date_id is null)
    update dwh.gtc_order_status co
    set exec_time      = base.exec_time,
        order_status   = base.order_status,
        close_date_id  = to_char(base.exec_time, 'YYYYMMDD')::int4,
        db_update_time = clock_timestamp(),
        closing_reason = 'E'
    from base
    where base.order_id = co.order_id
      and co.close_date_id is null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;

    l_row_cnt_total = l_row_cnt;
    -- parent flow
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
                                           and exec_date_id between l_start_date_id and l_end_date_id
                                         order by exec_id desc
                                         limit 1) iex_par on true
                  where co.close_date_id is null
                    and str.parent_order_id is not null)
    update dwh.gtc_order_status co
    set exec_time      = base.exec_time,
        order_status   = base.order_status,
        close_date_id  = to_char(base.exec_time, 'YYYYMMDD')::int4,
        db_update_time = clock_timestamp(),
        closing_reason = 'P'
    from base
    where base.order_id = co.order_id
      and co.close_date_id is null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' parent flow update', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    -- instrument flow
    update dwh.gtc_order_status co
    set close_date_id  = to_char(last_trade_date, 'YYYYMMDD')::int4,
        db_update_time = clock_timestamp(),
        closing_reason = 'I'
    where co.close_date_id is null
      and last_trade_date::date < l_end_date_id::text::date;

    get diagnostics l_row_cnt = row_count;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' instrument/client order update', l_row_cnt, 'U')
    into l_step_id;


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


-- DROP FUNCTION staging.zabbix_monitor_gtc_last_load();

CREATE OR REPLACE FUNCTION staging.zabbix_monitor_gtc_last_load()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
    -- 20240110 SO https://dashfinancial.atlassian.net/browse/DS-7809
declare
    check_points  text[] := array ['01:20', '16:20', '22:20'];
    check_point   time;
    check_ts      timestamp;
    l_last_update timestamp;
    l_delay interval := '7 minutes';
begin
    -- getting the last time where gtc_update_status has successfully finished
    select latest_load_time
    into l_last_update
    from dwh.fact_last_load_time
    where table_name = 'GTC_ORDER_STATUS';

--    raise notice 'l_last_update - %', l_last_update;

-- counting of the last time where gtc_update_status should have been processed
    select tm::time
    into check_point
    from unnest(check_points)
             as data(tm)
    where tm::time < clock_timestamp()::time - l_delay
    order by tm desc
    limit 1;

    if check_point is null then
        select tm::time
        into check_point
        from unnest(check_points)
                 as data(tm)
        order by tm desc
        limit 1;
        check_ts = current_date - '1 day'::interval + check_point;
    else
        check_ts = current_date + check_point;
    end if;

--    raise notice 'check_point - %', check_point;

    if l_last_update > check_ts then
--        raise notice 'Ok';
        return 1;
    else
--        raise notice 'Alarm';
        return 0;
    end if;

end;
$function$
;
