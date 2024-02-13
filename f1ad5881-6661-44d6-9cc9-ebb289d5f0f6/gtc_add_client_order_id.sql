alter table dwh.gtc_order_status add column if not exists client_order_id varchar(256) null;

-- DROP FUNCTION dwh.gtc_insert_daily(int4, int4);

CREATE OR REPLACE FUNCTION dwh.gtc_insert_daily(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL: GTC insert process'
AS $function$
-- PD: 20230906 changed the way we define close_date_id https://dashfinancial.atlassian.net/browse/DS-7223
-- SO: 20240212 added client_order_id into the flow https://dashfinancial.atlassian.net/browse/DS-7954
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

    insert into dwh.gtc_order_status (order_id, create_date_id, order_status, exec_time, last_trade_date, last_mod_date_id, close_date_id, account_id, time_in_force_id, client_order_id)
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
	           co.client_order_id
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
COMMENT ON FUNCTION dwh.gtc_insert_daily(int4, int4) IS 'Inserts all gtc orders have appeared at input date_id - related to create_date_id from client_order';

update dwh.gtc_order_status gtc
set client_order_id = cl.client_order_id
from dwh.client_order cl
where gtc.order_id = cl.order_id
  and gtc.create_date_id = cl.create_date_id
  and gtc.client_order_id is null
--   and gtc.close_date_id is not null
;
