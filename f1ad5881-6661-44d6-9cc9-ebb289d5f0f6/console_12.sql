-- DROP FUNCTION dwh.gtc_update_daily(int4, int4);
select * from dwh.gtc_update_daily(20241023, 20241023)
CREATE OR REPLACE FUNCTION dwh.gtc_update_daily(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer)
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
-- 2024-10-25 https://dashfinancial.atlassian.net/browse/DS-9069 OS\SY fix close_date_id regarding to the time of execution
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
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
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
    drop table if exists staging.gtc_base_modif;
    create table staging.gtc_base_modif as
    select gtc.order_id,
           iex.close_date_id           as close_date_id,
           iex.order_status            as order_status,
           'E'                         as closing_reason,
           gtc.client_order_id         as client_order_id,
           gtc.multileg_reporting_type as multileg_reporting_type
    from dwh.gtc_order_status gtc
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
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;
    analyze staging.gtc_base_modif;

    create index on staging.gtc_base_modif (order_id);
    create index on staging.gtc_base_modif (client_order_id, multileg_reporting_type);

    -- parent flow
    insert into staging.gtc_base_modif (order_id, close_date_id, order_status, closing_reason, client_order_id,
                                        multileg_reporting_type)
    select gtc.order_id,
           iex_par.close_date_id as close_date_id,
           iex_par.order_status  as order_status,
           'P'                   as closing_reason,
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from dwh.gtc_order_status gtc
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
      and not exists (select null from staging.gtc_base_modif bm where bm.order_id = gtc.order_id);

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' parent flow update', l_row_cnt, 'U')
    into l_step_id;

    -- instrument flow
    insert into staging.gtc_base_modif (order_id, close_date_id, order_status, closing_reason, client_order_id,
                                        multileg_reporting_type)
    select gtc.order_id,
           to_char(last_trade_date, 'YYYYMMDD')::int4,
           gtc.order_status,
           'I',
           client_order_id,
           multileg_reporting_type
    from dwh.gtc_order_status gtc
    where gtc.close_date_id is null
      and case
              when (gtc.time_in_force_id = '6'
                  and last_trade_date::date = current_date -- to avoid true for this condition in other day (reprints or the next day)
                  and last_trade_date::time >= '17:00'::time -- ??
                  and clock_timestamp()::time > '17:00'::time)
                  then gtc.last_trade_date::date <= l_end_date_id::text::date
              else
                  gtc.last_trade_date::date < l_end_date_id::text::date end
      and not exists (select null from staging.gtc_base_modif bm where bm.order_id = gtc.order_id);

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' instrument/client order update', l_row_cnt, 'U')
    into l_step_id;

    -- head of multileg
    insert into staging.gtc_base_modif(order_id, close_date_id, order_status, closing_reason, client_order_id,
                                       multileg_reporting_type)
    select gtc.order_id,
           t.close_date_id,
           t.order_status,
           'L',
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from dwh.gtc_order_status gtc
             join lateral (select gos.close_date_id, order_status
                           from staging.gtc_base_modif gos
                           where gos.client_order_id = gtc.client_order_id
                             and gos.multileg_reporting_type = '2'
                           limit 1) t on true
    where true
      and gtc.close_date_id is null
      and gtc.multileg_reporting_type = '3'
      and not exists (select null from staging.gtc_base_modif bm where bm.order_id = gtc.order_id)
--    and gtc.order_id = 14750322399
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Heads of multilegs after closed leg', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    -- legs after the head has been closed
    insert into staging.gtc_base_modif(order_id, close_date_id, order_status, closing_reason, client_order_id,
                                       multileg_reporting_type)
    select gtc.order_id,
           t.close_date_id,
           t.order_status,
           'H',
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from dwh.gtc_order_status gtc
             join lateral (select gos.close_date_id, order_status
                           from staging.gtc_base_modif gos
                           where gos.client_order_id = gtc.client_order_id
                             and gos.multileg_reporting_type = '3'
                           limit 1) t on true
    where true
      and gtc.close_date_id is null
      and gtc.multileg_reporting_type = '2'
      and not exists (select null from staging.gtc_base_modif bm where bm.order_id = gtc.order_id);

    get diagnostics l_row_cnt = row_count;

    l_row_cnt_total = l_row_cnt_total + l_row_cnt;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Legs after the heads was closed', l_row_cnt, 'U')
    into l_step_id;


    update dwh.gtc_order_status gtc
    set close_date_id  = case when base.close_date_id < 20010101 then 20010101 else base.close_date_id end,
        db_update_time = clock_timestamp(),
        closing_reason = base.closing_reason,
        order_status   = base.order_status
    from staging.gtc_base_modif base
    where gtc.order_id = base.order_id
      and gtc.close_date_id is null;
    get diagnostics l_row_cnt = row_count;

-- Logging into the table dwh.fact_last_load_time
    perform dwh.p_upd_fact_last_load_time('GTC_ORDER_STATUS');

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Logging into GTC_ORDER_STATUS total', 1, 'I')
    into l_step_id;

    -- End of logging into the table dwh.fact_last_load_time
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' FINISHED===', l_row_cnt, 'E')
    into l_step_id;

--    select count(*) into l_row_cnt_total from staging.gtc_base_modif;

    return l_row_cnt;
end;
$function$
;
