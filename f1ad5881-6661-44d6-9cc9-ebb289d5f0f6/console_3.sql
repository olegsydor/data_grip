/*
DROP TABLE dwh.gtc_order_status;
CREATE TABLE dwh.gtc_order_status (
	order_id int8 NOT NULL,
	create_date_id int4 NOT NULL,
	order_status bpchar(1) NULL,
	exec_time timestamp(6) NULL,
	last_trade_date timestamp(0) NULL,
	last_mod_date_id int4 NULL,
	is_parent bool NULL,
	close_date_id int4 NULL,
	account_id int4 NULL,
	time_in_force_id bpchar(1) DEFAULT '1'::bpchar NULL,
	db_create_time timestamp DEFAULT clock_timestamp() NULL,
	db_update_time timestamp NULL,
	closing_reason bpchar(1) NULL,
	client_order_id varchar(256) NULL
)
PARTITION BY RANGE (close_date_id);
CREATE INDEX gtc_order_status_order_id_idx ON ONLY dwh.gtc_order_status USING btree (order_id);
*/

alter table dwh.gtc_order_status add column if not exists instrument_id int8;
alter table dwh.gtc_order_status add column if not exists multileg_reporting_type bpchar(1);

create index if not exists gtc_order_status_client_order_id_idx ON dwh.gtc_order_status USING btree (client_order_id);

update dwh.gtc_order_status gtc
set instrument_id           = cl.instrument_id,
    multileg_reporting_type = cl.multileg_reporting_type
from dwh.client_order cl
where cl.order_id = gtc.order_id
  and cl.create_date_id = gtc.create_date_id
  and gtc.instrument_id is null;


CREATE OR REPLACE FUNCTION dwh.gtc_insert_daily(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL: GTC insert process'
AS $function$
-- PD: 20230906 changed the way we define close_date_id https://dashfinancial.atlassian.net/browse/DS-7223
-- SO: 20240214 added client_order_id into the flow https://dashfinancial.atlassian.net/browse/DS-7954
-- SO: 20240227 added instrument_id and multileg_reporting_type into the flow https://dashfinancial.atlassian.net/browse/DS-8029
declare
    l_row_cnt       int;
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
                           'dwh.gtc_insert_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' STARTED===', 0, 'I')
    into l_step_id;

    insert into dwh.gtc_order_status (order_id, create_date_id, order_status, exec_time, last_trade_date,
                                      last_mod_date_id, close_date_id, account_id, time_in_force_id, client_order_id,
                                      instrument_id, multileg_reporting_type)
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
	                                  and exec_date_id >= l_start_date_id
	                                order by exec_id desc
	                                limit 1) ex on true
	    where co.create_date_id between l_start_date_id and l_end_date_id
	      and co.time_in_force_id in ('1', '6')
	      and co.trans_type <> 'F'
	      and not exists (select null from dwh.gtc_order_status os where os.order_id = co.order_id);

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_insert_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' COMPLETED===', coalesce(l_row_cnt, 0),
                           'I')
    into l_step_id;

    return l_row_cnt;
end;
$function$
;


---------
drop table if exists base_modif
select * from trash.so_gtc_update_daily();

select * from base_modif;


CREATE OR REPLACE FUNCTION trash.so_gtc_update_daily(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer)
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

    -- Aggregating data
    -- street flow
    create temp table base_modif /*on commit drop*/ as
    select co.order_id,
           iex.close_date_id as close_date_id,
           iex.order_status  as order_status,
           'E'               as closing_reason
    from dwh.gtc_order_status co
             join lateral (select to_char(iex.exec_time, 'YYYYMMDD')::int4 as close_date_id,
                                  iex.order_status
                           from dwh.execution iex
                           where true
                             and iex.order_id = co.order_id
                             and iex.order_status in ('2', '4', '8')
                             and exec_date_id between l_start_date_id and l_end_date_id
                           order by exec_id desc
                           limit 1) iex on true
    where co.close_date_id is null;

--     update dwh.gtc_order_status co
--     set exec_time      = base.exec_time,
--         order_status   = base.order_status,
--         close_date_id  = to_char(base.exec_time, 'YYYYMMDD')::int4,
--         db_update_time = clock_timestamp(),
--         closing_reason = 'E'
--     from base
--     where base.order_id = co.order_id
--       and co.close_date_id is null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt;

    -- parent flow
    insert into base_modif (order_id, close_date_id, order_status, closing_reason)
    select co.order_id,
           iex_par.close_date_id    as close_date_id,
           iex_par.order_status as order_status,
           'P'                  as closing_reason
    from dwh.gtc_order_status co
             join dwh.client_order str
                  on str.order_id = co.order_id and str.create_date_id = co.create_date_id
             join lateral (select to_char(iex.exec_time, 'YYYYMMDD')::int4 as close_date_id,
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

--     update dwh.gtc_order_status co
--     set exec_time      = base.exec_time,
--         order_status   = base.order_status,
--         close_date_id  = to_char(base.exec_time, 'YYYYMMDD')::int4,
--         db_update_time = clock_timestamp(),
--         closing_reason = 'P'
--     from base
--     where base.order_id = co.order_id
--       and co.close_date_id is null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' parent flow update', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    -- instrument flow
    insert into base_modif (order_id, close_date_id, order_status, closing_reason)
    select gtc.order_id, to_char(last_trade_date, 'YYYYMMDD')::int4, gtc.order_status, 'I'
    from dwh.gtc_order_status gtc
    where gtc.close_date_id is null
      and gtc.last_trade_date::date < l_end_date_id::text::date;

--     update dwh.gtc_order_status co
--     set close_date_id  = to_char(last_trade_date, 'YYYYMMDD')::int4,
--         db_update_time = clock_timestamp(),
--         closing_reason = 'I'
--     where co.close_date_id is null
--       and last_trade_date::date < l_end_date_id::text::date;
    get diagnostics l_row_cnt = row_count;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' instrument/client order update', l_row_cnt, 'U')
    into l_step_id;

    -- head of multileg
    insert into base_modif(order_id, close_date_id, order_status, closing_reason)
    select gtc.order_id,
           t.close_date_id,
           gtc.order_status,
           'L'
    from dwh.gtc_order_status gtc
             join lateral (select gos.close_date_id
                           from dwh.gtc_order_status gos
                           where gos.client_order_id = gtc.client_order_id
--                                            and c.multileg_order_id = co.order_id
                             and gos.multileg_reporting_type <> '3'
                             and gos.close_date_id is not null
                           limit 1) t on true
    where true
      and gtc.close_date_id is null
      and gtc.multileg_reporting_type = '3';

--     update dwh.gtc_order_status gos
--     set close_date_id  = base.close_date_id,
--         db_update_time = clock_timestamp(),
--         closing_reason = 'L'
--     from base
--     where gos.order_id = base.order_id
--       and gos.create_date_id = base.create_date_id
--       and gos.close_date_id is null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Heads of multilegs after closed leg', l_row_cnt, 'U')
    into l_step_id;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;

    -- legs after the head has been closed
    insert into base_modif(order_id, close_date_id, order_status, closing_reason)
    select gtc.order_id,
           t.close_date_id,
           gtc.order_status,
           'H'
    from dwh.gtc_order_status gtc
             join lateral (select gos.close_date_id
                           from dwh.gtc_order_status gos
                           where gos.client_order_id = gtc.client_order_id
                             and gos.multileg_reporting_type = '3'
                             and gos.close_date_id is not null
                           limit 1) t on true
    where true
      and gtc.close_date_id is null
      and gtc.multileg_reporting_type <> '3';

--     update dwh.gtc_order_status gos
--     set close_date_id  = base.close_date_id,
--         db_update_time = clock_timestamp(),
--         closing_reason = 'H'
--     from base
--     where gos.order_id = base.order_id
--       and gos.create_date_id = base.create_date_id
--       and gos.close_date_id is null;

    get diagnostics l_row_cnt = row_count;
    l_row_cnt_total = l_row_cnt_total + l_row_cnt;
    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_update_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' Legs after the heads was closed', l_row_cnt, 'U')
    into l_step_id;
    -- Logging into the table dwh.fact_last_load_time
--  !!! return back  perform dwh.p_upd_fact_last_load_time('GTC_ORDER_STATUS');
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


