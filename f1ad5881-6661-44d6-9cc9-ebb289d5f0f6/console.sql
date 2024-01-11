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


END;
$function$
;
