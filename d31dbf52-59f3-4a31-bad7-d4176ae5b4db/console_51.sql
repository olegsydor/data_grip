drop table trash.so_gtc_to_upd;
create table trash.so_gtc_to_upd as
select co.order_id, co.create_date_id, co.instrument_id, co.multileg_reporting_type
from dwh.gtc_order_status gos
         join lateral (select co.order_id, co.create_date_id, co.instrument_id, co.multileg_reporting_type
                       from dwh.client_order co
                       where co.create_date_id = gos.create_date_id
                         and co.order_id = gos.order_id
                       limit 1) co on true
where gos.instrument_id is null
  and gos.create_date_id between 20220101 and 20220630
  and co.create_date_id between 20220101 and 20220630;

create index on trash.so_gtc_to_upd (create_date_id, order_id);
create index on trash.so_gtc_to_upd (client_order_id, multileg_reporting_type);


select create_date_id, count(*) from dwh.gtc_order_status
where instrument_id is null
group by create_date_id;



create or replace function trash.so_gtc_update_daily(p_start_date_id integer default null::integer, p_end_date_id integer default null::integer)
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
-- 2024-02-27 https://dashfinancial.atlassian.net/browse/DS-8029 OS added instrument_id and multileg_reporting_type into the flow and performance improvement for gtc_update
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
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' STARTED===', 0, 'O')
    into l_step_id;

    if l_end_date_id > to_char(current_date, 'YYYYMMDD')::int then
        select public.load_log(l_load_id, l_step_id,
                               'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
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
             join lateral (select to_char(iex.exec_time, 'YYYYMMDD')::int4 as close_date_id,
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
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;

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
                  on (str.order_id = gtc.order_id and str.create_date_id = gtc.create_date_id and str.create_date_id >= 20200102)
             join lateral (select to_char(iex.exec_time, 'YYYYMMDD')::int4 as close_date_id,
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
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
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
      and gtc.last_trade_date::date < l_end_date_id::text::date
      and not exists (select null from staging.gtc_base_modif bm where bm.order_id = gtc.order_id);

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' instrument/client order update', l_row_cnt, 'U')
    into l_step_id;

    -- head of multileg
    insert into staging.gtc_base_modif(order_id, close_date_id, order_status, closing_reason, client_order_id, multileg_reporting_type)
    select gtc.order_id,
--            t.close_date_id,
           gtc.order_status,
           'L',
           gtc.client_order_id,
           gtc.multileg_reporting_type,
           t.*
    from dwh.gtc_order_status gtc
--              join lateral (select gos.close_date_id
--                            from staging.gtc_base_modif gos
--                            where gos.client_order_id = gtc.client_order_id
--                              and gos.multileg_reporting_type = '2'
--                            limit 1) t on true
                 join lateral (select *
                                         from dwh.gtc_order_status g
--                                                   join dwh.client_order c
--                                                        on c.order_id = g.order_id and c.create_date_id = g.create_date_id
                                         where true
                                           and g.client_order_id = gtc.client_order_id
--                                            and c.multileg_order_id = gtc.order_id
                                           and g.multileg_reporting_type <> '3'
                                           and g.close_date_id is not null
                                         limit 1) t on true
    where true
--       and gtc.close_date_id is null
      and gtc.multileg_reporting_type = '3'
--       and not exists (select null from staging.gtc_base_modif bm where bm.order_id = gtc.order_id)
    and gtc.order_id = 14750322399;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Heads of multilegs after closed leg', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    -- legs after the head has been closed
    insert into staging.gtc_base_modif(order_id, close_date_id, order_status, closing_reason, client_order_id,
                                       multileg_reporting_type)
    select gtc.order_id,
           t.close_date_id,
           gtc.order_status,
           'H',
           gtc.client_order_id,
           gtc.multileg_reporting_type
    from dwh.gtc_order_status gtc
             join lateral (select gos.close_date_id
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
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Legs after the heads was closed', l_row_cnt, 'U')
    into l_step_id;


--     update dwh.gtc_order_status gtc
--     set close_date_id = base.close_date_id,
--         db_update_time = clock_timestamp(),
--         closing_reason = base.closing_reason,
--         order_status = base.order_status
--     from staging.gtc_base_modif base
--     where gtc.order_id = base.order_id
--     and gtc.close_date_id is null;
--     get diagnostics l_row_cnt = row_count;

-- Logging into the table dwh.fact_last_load_time
-- perform dwh.p_upd_fact_last_load_time('GTC_ORDER_STATUS');
   select public.load_log(l_load_id, l_step_id,
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Logging into GTC_ORDER_STATUS total', l_row_cnt, 'U')
    into l_step_id;
    -- End of logging into the table dwh.fact_last_load_time
    select public.load_log(l_load_id, l_step_id,
                           'gtc_modif_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' COMPLETED===',
                           l_row_cnt_total,
                           'U')
    into l_step_id;

    select count(*) into l_row_cnt_total from staging.gtc_base_modif;
    return l_row_cnt_total;
end;
$function$
;

select * from trash.so_gtc_update_daily();


select *
into trash.so_gtc_20240229_1620
from staging.gtc_base_modif;

select *
into trash.so_gtc_20240229_1620_orig
from dwh.gtc_order_status
where close_date_id is not null
  and db_update_time >= '2024-02-29 05:00'


select order_id, closing_reason, multileg_reporting_type from trash.so_gtc_20240229_1620_orig
except
select order_id, closing_reason, multileg_reporting_type from trash.so_gtc_20240229_1620;

select *
from dwh.gtc_order_status
where order_id = 14750322419;

select gos.close_date_id
from staging.gtc_base_modif gos
where gos.client_order_id = 'DAAA6397-20240229'
  and gos.multileg_reporting_type = '2';


select co.order_id,
	           co.create_date_id,
	           ex.order_status,
	           ex.exec_time,
	           case when co.time_in_force_id = '1' then di.last_trade_date else co.expire_time end as last_trade_date, -- last_trade_date from instrument for GTC or expire_time from client_order for GTD
	           to_char(current_date, 'YYYYMMDD')::int4 as last_mod_date_id,
	           case when exec_time is null and (last_trade_date::date < current_date) then public.get_dateid(public.get_gth_business_date(last_trade_date))
	               when exec_time is not null then public.get_dateid(public.get_gth_business_date(exec_time)) end as close_date_id,
	           co.account_id,
	           co.time_in_force_id,
	           co.client_order_id,
	           co.instrument_id,
	           co.multileg_reporting_type
	    from dwh.client_order co
	             join dwh.d_instrument di on di.instrument_id = co.instrument_id
	             left join lateral (select iex.exec_time,
	                                       iex.order_status
	                                from dwh.execution iex
	                                where true
	                                  and iex.order_id = co.order_id
	                                  and iex.order_status in ('2', '4', '8')
	                                  and exec_date_id >= :l_start_date_id
	                                order by exec_id desc
	                                limit 1) ex on true
	    where co.create_date_id between :l_start_date_id and :l_end_date_id
	      and co.time_in_force_id in ('1', '6')
	      and co.trans_type <> 'F'
and co.order_id = 14750322419
-- 	      and not exists (select null from dwh.gtc_order_status os where os.order_id = co.order_id);