select min(create_date_id)
from dwh.gtc_order_status;


select min(create_date_id)
from trash.old_gtc_order_status;

CREATE TABLE trash.old_gtc_order_status
(
    order_id                int8                          NOT NULL,
    create_date_id          int4                          NOT NULL,
    order_status            bpchar(1)                     NULL,
    exec_time               timestamp(6)                  NULL,
    last_trade_date         timestamp(0)                  NULL, -- It is last_trade_date from instrument for time_in_force_id = 1 or expire_time from client_order for time_in_force_id = 6
    last_mod_date_id        int4                          NULL,
    is_parent               bool                          NULL, -- if this attr is true the order has been closed because of closing its parent order
    close_date_id           int4                          NULL,
    account_id              int4                          NULL, -- account_id from dwh.d_account
    time_in_force_id        bpchar(1) DEFAULT '1'::bpchar NULL, -- time_in_force_id - 1 for GTC, 6 - for GTD
    db_create_time          timestamp DEFAULT clock_timestamp() NULL,
    db_update_time          timestamp                     NULL,
    closing_reason          bpchar(1)                     NULL, -- 'the order was closed because of¶E - by the execution flow ('2', '4', '8')¶P - by the parent flow (closed street because its parent was closed)¶I - instrument or client order expire time¶L - the one of closed leg has closed the head¶H - the head closed before has closed all non closed legs¶
    client_order_id         varchar(256)                  NULL,
    instrument_id           int8                          NULL,
    multileg_reporting_type bpchar(1)                     NULL
);
CREATE INDEX old_gtc_order_status_client_order_id_idx ON trash.old_gtc_order_status USING btree (client_order_id);
CREATE INDEX old_gtc_order_status_order_id_idx ON trash.old_gtc_order_status USING btree (order_id);
CREATE INDEX old_gtc_order_status_close_date_id_idx ON trash.old_gtc_order_status USING btree (close_date_id);



CREATE OR REPLACE FUNCTION trash.old_gtc_insert_daily(p_start_date_id integer DEFAULT NULL::integer,
                                                      p_end_date_id integer DEFAULT NULL::integer)
    RETURNS integer
    LANGUAGE plpgsql
    SET application_name TO 'ETL: GTC insert process'
AS
$function$
    -- PD: 20230906 changed the way we define close_date_id https://dashfinancial.atlassian.net/browse/DS-7223
-- SO: 20240214 added client_order_id into the flow https://dashfinancial.atlassian.net/browse/DS-7954
-- SO: 20240227 added instrument_id and multileg_reporting_type into the flow https://dashfinancial.atlassian.net/browse/DS-8029
-- SO: 20240301 remove counting of close_date_id from insert function
-- SO: 20240615 DS-8470 limited execution by the interval between l_start_date_id and l_end_date_id instead of exec_date_id >= l_start_date_id
-- SO: 20240615 DS-8855 Added calculation of is_parent
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
                           'old_gtc_insert_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' STARTED===', 0, 'B')
    into l_step_id;

    insert into trash.old_gtc_order_status (order_id, create_date_id, order_status, exec_time, last_trade_date,
                                            last_mod_date_id, account_id, time_in_force_id, client_order_id,
                                            instrument_id, multileg_reporting_type, is_parent)
    select co.order_id,
           co.create_date_id,
           ex.order_status,
           ex.exec_time,
           case
               when co.time_in_force_id = '1' then di.last_trade_date
               else co.expire_time end                                   as last_trade_date, -- last_trade_date from instrument for GTC or expire_time from client_order for GTD
           to_char(current_date, 'YYYYMMDD')::int4                       as last_mod_date_id,
           co.account_id,
           co.time_in_force_id,
           co.client_order_id,
           co.instrument_id,
           co.multileg_reporting_type,
           case when co.parent_order_id is null then true else false end as is_parent
    from dwh.client_order co
             join dwh.d_instrument di on di.instrument_id = co.instrument_id
             left join lateral (select iex.exec_time,
                                       iex.order_status
                                from dwh.execution iex
                                where true
                                  and iex.order_id = co.order_id
                                  and iex.order_status in ('2', '4', '8')
--	                                  and exec_date_id >= l_start_date_id
                                  and exec_date_id between l_start_date_id and l_end_date_id
                                order by exec_id desc
                                limit 1) ex on true
    where co.create_date_id between l_start_date_id and l_end_date_id
      and co.time_in_force_id in ('1', '6')
      and co.trans_type <> 'F'
      and not exists (select null from trash.old_gtc_order_status os where os.order_id = co.order_id);

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_insert_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' FINISHED===', coalesce(l_row_cnt, 0),
                           'E')
    into l_step_id;

    return l_row_cnt;
end;
$function$
;


-- DROP FUNCTION dwh.gtc_update_daily(int4, int4);

CREATE OR REPLACE FUNCTION trash.old_gtc_update_daily(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- 2022-09-02 https://dashfinancial.atlassian.net/browse/DS-5561 add logic to close gtc by parent executions
-- 2023-05-01 https://dashfinancial.atlassian.net/browse/DS-3581 closing heads after closing all legs
-- 2023-05-16 https://dashfinancial.atlassian.net/browse/DS-6745 closing head after at least one of legs was closed and then closing all other legs if the head was closed
-- 2023-08-17 https://dashfinancial.atlassian.net/browse/DS-7183 PD added multileg_order_id condition
-- 2024-01-08 https://dashfinancial.atlassian.net/browse/DS-7800 OS added a condition to prevent input end_date later then today
-- 2024-01-11 https://dashfinancial.atlassian.net/browse/DS-7809 OS added logging into dwh.fact_last_load_time for zabbix monitoring
-- 2024-02-27 https://dashfinancial.atlassian.net/browse/DS-8029 OS added instrument_id and multileg_reporting_type into the flow and performance improvement for gtc_update
-- 2024-06-15 https://dashfinancial.atlassian.net/browse/DS-8470 OS replace gtc.order_status with t.order_status in parts of Leg and heads of multileg
-- 2024-08-23 https://dashfinancial.atlassian.net/browse/DS-8793 OS\SY fix close_date_id regarding to the time of execution
-- 2024-11-18 https://dashfinancial.atlassian.net/browse/DS-9069 OS\SY fix close_date_id regarding to the time of execution
declare
    l_row_cnt       int;
    l_row_cnt_total int;
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
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' STARTED===', 0, 'B')
    into l_step_id;

    if l_end_date_id > to_char(current_date, 'YYYYMMDD')::int then
        select public.load_log(l_load_id, l_step_id,
                               'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                               ' Stopped as the end_date is further than today', -1, 'E')
        into l_step_id;
        return -1;
    end if;

    -- Aggregating data
    -- street/execution flow
    drop table if exists trash.old_gtc_base_modif;
    create table trash.old_gtc_base_modif as
    select gtc.order_id,
           iex.close_date_id           as close_date_id,
           iex.order_status            as order_status,
           'E'                         as closing_reason,
           gtc.client_order_id         as client_order_id,
           gtc.multileg_reporting_type as multileg_reporting_type
    from trash.old_gtc_order_status gtc
             join lateral (select
                                  --to_char(iex.exec_time, 'YYYYMMDD')::int4 as close_date_id,
                                  public.get_gth_date_id_by_instrument(iex.exec_time, gtc.instrument_id) as close_date_id,
                                  iex.order_status
                           from dwh.execution iex
                           where true
                             and iex.order_id = gtc.order_id
                             and iex.order_status in ('2', '4', '8')
                             and exec_date_id between l_start_date_id and l_end_date_id
                           order by exec_id desc
                           limit 1) iex on true
    where gtc.close_date_id is null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;
    analyze trash.old_gtc_base_modif;

    create index on trash.old_gtc_base_modif (order_id);
    create index on trash.old_gtc_base_modif (client_order_id, multileg_reporting_type);

    -- parent flow
    insert into trash.old_gtc_base_modif (order_id, close_date_id, order_status, closing_reason, client_order_id,
                                        multileg_reporting_type)
    select gtc.order_id,
           iex_par.close_date_id as close_date_id,
           iex_par.order_status  as order_status,
           'P'                   as closing_reason,
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from trash.old_gtc_order_status gtc
             join dwh.client_order str
                  on (str.order_id = gtc.order_id and str.create_date_id = gtc.create_date_id and
                      str.create_date_id >= 20200102)
             join lateral (select
                                  -- to_char(iex.exec_time, 'YYYYMMDD')::int4 as close_date_id,
                                  public.get_gth_date_id_by_instrument(iex.exec_time, gtc.instrument_id) as close_date_id,
                                  iex.order_status
                           from dwh.execution iex
                           where true
                             and iex.order_id = str.parent_order_id
                             and iex.order_status in ('2', '4', '8')
                             and exec_date_id between l_start_date_id and l_end_date_id
                           order by exec_id desc
                           limit 1) iex_par on true
    where gtc.close_date_id is null
      and str.parent_order_id is not null
      and not exists (select null from trash.old_gtc_base_modif bm where bm.order_id = gtc.order_id);

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' parent flow update', l_row_cnt, 'U')
    into l_step_id;

    -- instrument flow
    insert into trash.old_gtc_base_modif (order_id, close_date_id, order_status, closing_reason, client_order_id,
                                        multileg_reporting_type)
    select gtc.order_id,
           to_char(last_trade_date, 'YYYYMMDD')::int4,
           gtc.order_status,
           'I',
           client_order_id,
           multileg_reporting_type
    from trash.old_gtc_order_status gtc
    where gtc.close_date_id is null
      and case
              when (gtc.time_in_force_id = '6'
                  and last_trade_date::date = current_date -- to avoid true for this condition in other day (reprints or the next day)
--                  and clock_timestamp()::time > '17:00'::time
                  and public.get_gth_date_id_by_instrument_type(clock_timestamp()::timestamp, 'O') > public.get_dateid(current_date)
                    )
                  then gtc.last_trade_date::date <= l_end_date_id::text::date
              else
                  gtc.last_trade_date::date < l_end_date_id::text::date end
      and not exists (select null from trash.old_gtc_base_modif bm where bm.order_id = gtc.order_id);

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' instrument/client order update', l_row_cnt, 'U')
    into l_step_id;

    -- head of multileg
    insert into trash.old_gtc_base_modif(order_id, close_date_id, order_status, closing_reason, client_order_id,
                                       multileg_reporting_type)
    select gtc.order_id,
           t.close_date_id,
           t.order_status,
           'L',
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from trash.old_gtc_order_status gtc
             join lateral (select gos.close_date_id, order_status
                           from trash.old_gtc_base_modif gos
                           where gos.client_order_id = gtc.client_order_id
                             and gos.multileg_reporting_type = '2'
                           limit 1) t on true
    where true
      and gtc.close_date_id is null
      and gtc.multileg_reporting_type = '3'
      and not exists (select null from trash.old_gtc_base_modif bm where bm.order_id = gtc.order_id)
--    and gtc.order_id = 14750322399
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Heads of multilegs after closed leg', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    -- legs after the head has been closed
    insert into trash.old_gtc_base_modif(order_id, close_date_id, order_status, closing_reason, client_order_id,
                                       multileg_reporting_type)
    select gtc.order_id,
           t.close_date_id,
           t.order_status,
           'H',
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from trash.old_gtc_order_status gtc
             join lateral (select gos.close_date_id, order_status
                           from trash.old_gtc_base_modif gos
                           where gos.client_order_id = gtc.client_order_id
                             and gos.multileg_reporting_type = '3'
                           limit 1) t on true
    where true
      and gtc.close_date_id is null
      and gtc.multileg_reporting_type = '2'
      and not exists (select null from trash.old_gtc_base_modif bm where bm.order_id = gtc.order_id);

    get diagnostics l_row_cnt = row_count;

    l_row_cnt_total = l_row_cnt_total + l_row_cnt;
    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Legs after the heads was closed', l_row_cnt, 'U')
    into l_step_id;


    update trash.old_gtc_order_status gtc
    set close_date_id  = case when base.close_date_id < 20010101 then 20010101 else base.close_date_id end,
        db_update_time = clock_timestamp(),
        closing_reason = base.closing_reason,
        order_status   = base.order_status
    from trash.old_gtc_base_modif base
    where gtc.order_id = base.order_id
      and gtc.close_date_id is null;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Logging into GTC_ORDER_STATUS total', 1, 'I')
    into l_step_id;

    -- End of logging into the table dwh.fact_last_load_time
    select public.load_log(l_load_id, l_step_id,
                           'old_gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' FINISHED===', l_row_cnt, 'E')
    into l_step_id;

--    select count(*) into l_row_cnt_total from trash.old_gtc_base_modif;

    return l_row_cnt;
end;
$function$
;

do
$$
    declare
        rc record;
    begin
        for rc in (select extract(isodow from x), to_char(x, 'YYYYMMDD')::int as dt
                   from generate_series('2018-10-01'::date, '2018-10-31'::date,
                                        interval '1 day') as x -- '2019-08-09'::date
                   where extract(isodow from x) < 6)
            loop
                perform trash.old_gtc_insert_daily(rc.dt, rc.dt);
                perform trash.old_gtc_update_daily(rc.dt, rc.dt);
            end loop;
    end;
$$


select * from trash.old_gtc_base_modif

select * from dwh.execution
where order_id = 741271580
and exec_date_id >= 20180102


select *--create_date_id, count(*)
from trash.old_gtc_order_status gtc
left join lateral (select iex.exec_time,
                                       iex.order_status
                                from dwh.execution iex
                                where true
                                  and iex.order_id = gtc.order_id
                                  and iex.order_status in ('2', '4', '8')
--	                                  and exec_date_id >= l_start_date_id
                                  and exec_date_id between :l_start_date_id and :l_end_date_id
                                order by exec_id desc
                                limit 1) ex on true
where true
    and close_date_id is null
-- and create_date_id <= 20180501
and gtc.order_id = 1129878350


with base as (select gos.order_id, ex.*
              from trash.old_gtc_order_status gos
                       join lateral (select public.get_gth_date_id_by_instrument(iex.exec_time,
                                                                                 gos.instrument_id) as close_date_id,
                                            iex.order_status
                                     from dwh.execution iex
                                     where iex.order_id = gos.order_id
                                       and exec_date_id between 20180102 and 20190809
                                     order by exec_id desc
                                     limit 1) ex on true
              where gos.close_date_id is null)
update trash.old_gtc_order_status gtc
set close_date_id  = base.close_date_id,
    closing_reason = 'X'
from base
where gtc.order_id = base.order_id
  and gtc.close_date_id is null;



update trash.old_gtc_order_status gos
set close_date_id = (select public.get_gth_date_id_by_instrument(iex.exec_time, gos.instrument_id)
                     from dwh.execution iex
                     where iex.order_id = gos.order_id
                       and exec_date_id between 20180102 and 20190809
                     order by exec_id desc
                     limit 1)
where gos.close_date_id is null;


select gtc.order_id,
           iex_par.close_date_id as close_date_id,
           iex_par.order_status  as order_status,
           'P'                   as closing_reason,
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from trash.old_gtc_order_status gtc
             join dwh.client_order str
                  on (str.order_id = gtc.order_id and str.create_date_id = gtc.create_date_id and
                      str.create_date_id >= 20100102)
             join lateral (select
                                  -- to_char(iex.exec_time, 'YYYYMMDD')::int4 as close_date_id,
                                  public.get_gth_date_id_by_instrument(iex.exec_time, gtc.instrument_id) as close_date_id,
                                  iex.order_status
                           from dwh.execution iex
                           where true
                             and iex.order_id = str.parent_order_id
--                              and iex.order_status in ('2', '4', '8')
                             and exec_date_id between 20180102 and 20200809
                           order by exec_id desc
                           limit 1) iex_par on true
    where gtc.close_date_id is null
      and str.parent_order_id is not null
