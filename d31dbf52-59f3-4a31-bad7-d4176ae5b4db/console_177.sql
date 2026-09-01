select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.*--data_type, parameters.ordinal_position, parameters.parameter_name
from information_schema.routines
         join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
  and parameter_name ilike any('{%account_id%, %accounts_id%}')
  and not exists (select null
                  from information_schema.routines rt
                           join information_schema.parameters pr on rt.specific_name = pr.specific_name
                  where true
                    and rt.routine_schema in ('dash360', 'dash_reporting')
                    and pr.parameter_name ilike '%trading%'
                    and rt.specific_name = routines.specific_name
                    and pr.parameter_mode = 'IN')
  and parameter_mode = 'IN'
  and routines.routine_schema in ('dash360', 'dash_reporting');


SELECT * FROM (SELECT pid, state, application_name, user, wait_event, query_start::timestamp AS query_start, age(clock_timestamp(), query_start) AS age, usename, query, state FROM pg_stat_activity WHERE true AND state IN ('active', 'idle in transaction') AND query NOT ILIKE '%pg_stat_activity%' UNION ALL SELECT NULL, NULL, NULL AS application_name, NULL, NULL, NULL AS query_start, NULL AS age, NULL, NULL, NULL) x WHERE query ILIKE '%.run_f_parent_order_process%' ORDER BY CASE WHEN coalesce(application_name, 'Sydor') ILIKE '%Sydor%' THEN 0 ELSE 1 END, query_start NULLS LAST


select * from staging.find_in_load_timing('run_f_parent_order_process', 60*10*1)
where true
order by 1 desc, 2 desc;


select x.*
from staging.sync_test_calculated_metrics x
where date_id = :p_date_id;


select * from staging.edw_blaze7_treports_edw
where coalesce(date_id, 0) = 20260809;


WITH src AS
(
	SELECT
		'BLAZE7_TREPORTS_PROD1'::TEXT													AS table_name,
		:p_date_id::numeric															AS date_id,
		count(1) 																	AS cn,
		stddev(l2.pg_ord_id) 														AS dev_pg_ord_id,
		corr(pg_ord_id::double precision, userid::double precision) 				AS corr_userid,
		sum(l2.legnumber)::bigint													AS sum_legnumber,
		sum(l2.lastprice)::numeric 													AS sum_lastprice,
		sum(l2.leavesqty)::bigint 													AS sum_leavesqty,
		sum(l2.aveprice)::numeric													AS sum_aveprice,
		sum(l2.price)::numeric														AS sum_price,
		stddev(l2.cl_ord_id) 														AS dev_cl_ord_id
	FROM
	(
	SELECT
		treports._order_id AS pg_ord_id,
		treports.legnumber::int,
		round(treports.lastprice::NUMERIC / 10000.0, 2) AS lastprice,
		treports.leavesqty::int AS leavesqty,
		round(treports.aveprice::NUMERIC / 100000000.0, 8) AS aveprice,
		round(treports.price::NUMERIC / 10000.0, 2) AS price,
		treports.userid::int::double precision AS userid,
		(('x'::TEXT||lpad(md5(treports.reportid), 32, '0'))::BIT(64))::bigint AS cl_ord_id
	FROM staging.treports_edw_prod1 AS treports
	WHERE true
    -- and to_char(treports._db_create_time, 'YYYYMMDD')::int = &p_date_id
    and treports._db_create_time >= :p_date_id::text::date
          and treports._db_create_time < (:p_date_id::text::date + interval '1 day')
	ORDER BY treports.reportid
	) l2
)

INSERT INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
           metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05,
           metric_name_06, metric_value_06, metric_name_07, metric_value_07, metric_name_08, metric_value_08)
SELECT
	   'BLAZE7_PG'::text as source_name
       , d.table_name as table_name
       , d.date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows
       , 'dev_pg_ord_id'::varchar as metric_name_01
       , d.dev_pg_ord_id::double precision as metric_value_01
       , 'corr_userid'::varchar as metric_name_02
       , d.corr_userid::double precision as metric_value_02
       , 'sum_legnumber'::varchar as metric_name_03
       , d.sum_legnumber::double precision as metric_value_03
       , 'sum_lastprice'::varchar as metric_name_04
       , d.sum_lastprice::double precision as metric_value_04
       , 'sum_leavesqty'::varchar as metric_name_05
       , d.sum_leavesqty::double precision as metric_value_05
       , 'sum_aveprice'::varchar as metric_name_06
       , d.sum_aveprice::double precision as metric_value_06
	   , 'sum_price' ::varchar as metric_name_07
       , d.sum_price ::double precision as metric_value_07
	   , 'dev_cl_ord_id' ::varchar as metric_name_08
       , d.dev_cl_ord_id ::double precision as metric_value_08

       FROM src AS d
on conflict on constraint sync_test_calc_metrics_pkey do
        update set
            pg_db_updated_time = excluded.pg_db_updated_time
          , metric_cnt_rows    = excluded.metric_cnt_rows
          , metric_name_01     = excluded.metric_name_01
          , metric_value_01    = excluded.metric_value_01
          , metric_name_02     = excluded.metric_name_02
          , metric_value_02    = excluded.metric_value_02
          , metric_name_03     = excluded.metric_name_03
          , metric_value_03    = excluded.metric_value_03
          , metric_name_04     = excluded.metric_name_04
          , metric_value_04    = excluded.metric_value_04
          , metric_name_05     = excluded.metric_name_05
          , metric_value_05    = excluded.metric_value_05
          , metric_name_06     = excluded.metric_name_06
          , metric_value_06    = excluded.metric_value_06
          , metric_name_07     = excluded.metric_name_07
          , metric_value_07    = excluded.metric_value_07
          , metric_name_08     = excluded.metric_name_08
          , metric_value_08    = excluded.metric_value_08;


WITH src AS
(
	SELECT
		'BLAZE7_TREPORTS_PROD1'::TEXT													AS table_name,
		&p_date_id::numeric															AS date_id,
		count(1) 																	AS cn,
		stddev(l2.pg_ord_id) 														AS dev_pg_ord_id,
		corr(pg_ord_id::double precision, userid::double precision) 				AS corr_userid,
		sum(l2.legnumber)::bigint													AS sum_legnumber,
		sum(l2.lastprice)::numeric 													AS sum_lastprice,
		sum(l2.leavesqty)::bigint 													AS sum_leavesqty,
		sum(l2.aveprice)::numeric													AS sum_aveprice,
		sum(l2.price)::numeric														AS sum_price,
		stddev(l2.cl_ord_id) 														AS dev_cl_ord_id
	FROM
	(
	SELECT
		treports.pg_order_id AS pg_ord_id,--
		treports.legnumber::int,
		round(treports.lastprice::NUMERIC, 2) AS lastprice,
		treports.leavesqty::int AS leavesqty,
		round(treports.aveprice::NUMERIC, 8) AS aveprice,
		round(treports.price::NUMERIC, 2) AS price,
		treports.userid::int::double precision AS userid, --!!
		(('x'::TEXT||lpad(md5(trim(treports.exec_id)), 32, '0'))::BIT(64))::bigint AS cl_ord_id
	FROM staging.edw_blaze7_treports_edw AS treports
	WHERE COALESCE(date_id, 0) = :p_date_id
	and upper(treports.pg_entity) = 'PROD1'
	ORDER BY trim(treports.exec_id)
	) l2
)

INSERT INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
           metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05,
           metric_name_06, metric_value_06, metric_name_07, metric_value_07, metric_name_08, metric_value_08)
SELECT
	   'BLAZE7_EDW_PROD1'::text as source_name
       , d.table_name as table_name
       , d.date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows
       , 'dev_pg_ord_id'::varchar as metric_name_01
       , d.dev_pg_ord_id::double precision as metric_value_01
       , 'corr_userid'::varchar as metric_name_02
       , d.corr_userid::double precision as metric_value_02
       , 'sum_legnumber'::varchar as metric_name_03
       , d.sum_legnumber::double precision as metric_value_03
       , 'sum_lastprice'::varchar as metric_name_04
       , d.sum_lastprice::double precision as metric_value_04
       , 'sum_leavesqty'::varchar as metric_name_05
       , d.sum_leavesqty::double precision as metric_value_05
       , 'sum_aveprice'::varchar as metric_name_06
       , d.sum_aveprice::double precision as metric_value_06
	   , 'sum_price' ::varchar as metric_name_07
       , d.sum_price ::double precision as metric_value_07
	   , 'dev_cl_ord_id' ::varchar as metric_name_08
       , d.dev_cl_ord_id ::double precision as metric_value_08

       FROM src AS d
on conflict on constraint sync_test_calc_metrics_pkey do
        update set
            pg_db_updated_time = excluded.pg_db_updated_time
          , metric_cnt_rows    = excluded.metric_cnt_rows
          , metric_name_01     = excluded.metric_name_01
          , metric_value_01    = excluded.metric_value_01
          , metric_name_02     = excluded.metric_name_02
          , metric_value_02    = excluded.metric_value_02
          , metric_name_03     = excluded.metric_name_03
          , metric_value_03    = excluded.metric_value_03
          , metric_name_04     = excluded.metric_name_04
          , metric_value_04    = excluded.metric_value_04
          , metric_name_05     = excluded.metric_name_05
          , metric_value_05    = excluded.metric_value_05
          , metric_name_06     = excluded.metric_name_06
          , metric_value_06    = excluded.metric_value_06
          , metric_name_07     = excluded.metric_name_07
          , metric_value_07    = excluded.metric_value_07
          , metric_name_08     = excluded.metric_name_08
          , metric_value_08    = excluded.metric_value_08



select *
from dwh.flat_trade_record
where date_id = to_char(now()::date, 'YYYYMMDD')::int
	and trade_record_id in
		(select orig_trade_record_id
         from dwh.flat_trade_record
         where date_id = to_char(now()::date, 'YYYYMMDD')::int -1
         and is_busted='N'
         and orig_trade_record_id is not null)
and is_busted='N'


-- active processes
select * from (
 select pid, state, application_name, user, wait_event, query_start::timestamp as query_start, age(clock_timestamp(), query_start) as age, usename, query, state
	from pg_stat_activity
	where true
	and state in ('active', 'idle in transaction')
	and query not ilike '%pg_stat_activity%'
--	and query not ilike '%vacuum%'
--	and query not ilike '%replicat%'
--	and query ilike '%data_marts.run_f_parent_order_process%'
	union all
	select null, null, null as application_name, null, null, null as query_start, null as age, null, null, null) x
	order by case when coalesce(application_name, 'Sydor') ilike '%Sydor%' then 0 else 1 end,  query_start nulls last;



select * from dwh.flat_trade_record
    where exch_exec_id = '7210679533941' -- 5327423362
and date_id = 20260812;

select * from staging.trade_level_book_record
where trade_record_id = 5327423362
and date_id = 20260812;

select * from staging.dash_trade_record_daily_mira
where trade_record_id = 5327423362
and date_id >= 20260811;



--create temp table tmp_tca as
select * from staging.find_in_load_timing('dash360.report_obo_generic', 60*24*5)--localtimestamp - interval '500 minute', localtimestamp);
where true
--and load_timing_id in (302680907, 302680907, 302703950)
order by 1 desc, 2 desc;


-- DROP FUNCTION trash.so_report_rps_s3_sg(int4, int4, _int4, bpchar, _varchar, bool, bool);

CREATE OR REPLACE FUNCTION trash.so_report_rps_s3_sg(in_start_date_id integer, in_end_date_id integer,
                                                     in_account_ids integer[] DEFAULT '{}'::integer[],
                                                     in_is_multi_leg character DEFAULT 'N'::bpchar,
                                                     in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                     in_exclude_blaze boolean DEFAULT true,
                                                     in_actual_exchange boolean DEFAULT false)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    --  2024-04-23  SO:  https://dashfinancial.atlassian.net/browse/DS-8251  added  in_trading_firm_ids  as  an  input  parameter
    --  SO  20240523  https://dashfinancial.atlassian.net/browse/DEVREQ-4264  add  coalesce  to  account\trading  firm  input  parameters
    --  SO  20250219  https://dashfinancial.atlassian.net/browse/DS-9608  Performance  improvement
    --  SO  20260108  https://dashfinancial.atlassian.net/browse/DEVREQ-7409  Add  a  new  parameter:  Exclude  S3  EOD  Blaze  Orders  (as  well  as  BLAZE  as  exchange_id)
    --  SO 20260601 https://dashfinancial.atlassian.net/browse/DS-11581
declare
    l_is_multileg     boolean := case when in_is_multi_leg = 'N' then false else true end;
    l_account_ids     int4[];
    l_load_id         int;
    l_row_cnt         int;
    l_step_id         int;
    l_msg             text;
    l_gtc_min_date_id int4    := to_char(to_date(in_start_date_id::text, 'YYYYMMDD') - interval '1 year', 'YYYYMMDD')::int4;
begin

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;
    l_msg := 'report_rps_s3 for ' || in_start_date_id::text || '-' || in_end_date_id::text ||
             case when l_is_multileg then '. Multilegs' else '. Single' end || '. Accounts - ' ||
             substr(l_account_ids::text, 1, 50);

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg || '  STARTED  ===', 0, 'O')
    into l_step_id;

    --  header
    drop table if exists t_report;
    create temp table t_report on commit drop as
    select 'H'                                                                                        as record_type,
           0::int8                                                                                    as order_id,
           null                                                                                       as time_id,
           'A'                                                                                        as record_id,
           0                                                                                          as record_type_id,
           'H' || '|' ||
           'V2.0.4' || '|' ||
           to_char(clock_timestamp(), 'YYYYMMDD') || 'T' || to_char(clock_timestamp(), 'HH24MISSFF3') as rec;

    -- orders
-- daily parent orders
    drop table if exists tmp_base;
    create temp table tmp_base as
-- head and legs
    select 'NO'                    as noro,
           cl.create_date_id,
           cl.parent_order_id,
           null                    as parent_client_order_id,
           cl.order_id,
           cl.process_time,
           cl.client_order_id,
           cl.instrument_id,
           cl.account_id,
           cl.trans_type,
           cl.multileg_reporting_type,
           cl.multileg_order_id,
           cl.time_in_force_id,
           case
               when l_is_multileg and cl.no_legs is null then (select no_legs
                                                               from dwh.client_order
                                                               where order_id = cl.multileg_order_id
                                                               limit 1)
               else cl.no_legs end as no_legs
    from dwh.client_order cl
    where true
--       and client_order_id = '00214105960ESNY1'
      and cl.parent_order_id is null
      and cl.create_date_id between in_start_date_id and in_end_date_id
      and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.trans_type <> 'F'
      and cl.time_in_force_id not in ('1', '6')
      and case
              when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
              else cl.multileg_reporting_type = '1' end
      and case
              when in_exclude_blaze then (cl.ex_destination IS NULL OR cl.ex_destination NOT ILIKE '%blaze%')
              else true end
      and case
              when in_exclude_blaze then (cl.exchange_id is null or cl.exchange_id not ilike '%blaze%')
              else true end;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || '  daily orders added  ===', l_row_cnt, 'O')
    into l_step_id;

    -- gtc parent orders
-- head and legs
    drop table if exists tmp_base_gtc;
    create temp table tmp_base_gtc as
    select 'NO'                    as noro,
           cl.create_date_id,
           cl.parent_order_id,
           null                    as parent_client_order_id,
           cl.order_id,
           cl.process_time,
           cl.client_order_id,
           cl.instrument_id,
           cl.account_id,
           cl.trans_type,
           cl.multileg_reporting_type,
           cl.multileg_order_id,
           cl.time_in_force_id,
           case
               when l_is_multileg and cl.no_legs is null then (select no_legs
                                                               from dwh.client_order
                                                               where order_id = cl.multileg_order_id
                                                               limit 1)
               else cl.no_legs end as no_legs
    from dwh.client_order cl
             join dwh.gtc_order_status gtc using (create_date_id, order_id)
    where true
--         and order_id = 416550869289618526
--      and cl.client_order_id = '00214649864ESNY1'
      and cl.parent_order_id is null
      and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and case when l_account_ids = '{}' then true else gtc.account_id = any (l_account_ids) end
      and cl.trans_type <> 'F'
      and gtc.create_date_id > l_gtc_min_date_id
      and cl.time_in_force_id in ('1', '6')
      and cl.create_date_id <= in_start_date_id
      and (gtc.close_date_id is null or gtc.close_date_id >= in_end_date_id)
      and case
              when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
              else cl.multileg_reporting_type = '1' end
      and case
              when in_exclude_blaze then (cl.ex_destination IS NULL OR cl.ex_destination NOT ILIKE '%blaze%')
              else true end
      and case
              when in_exclude_blaze then (cl.exchange_id is null or cl.exchange_id not ilike '%blaze%')
              else true end;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || '  gtc orders added  ===', l_row_cnt, 'O')
    into l_step_id;

    insert into tmp_base
    select *
    from tmp_base_gtc;

    analyse tmp_base;
    create index on tmp_base (order_id, create_date_id);

-- streets of legs
    drop table if exists tmp_base_str;
    create temp table tmp_base_str as
    select 'RO',
           cl.create_date_id,
           cl.parent_order_id,
           tmp.client_order_id as parent_client_order_id,
           cl.order_id,
           cl.process_time,
           cl.client_order_id,
           cl.instrument_id,
           cl.account_id,
           cl.trans_type,
           cl.multileg_reporting_type,
           tmp.multileg_order_id,
           cl.time_in_force_id,
           tmp.no_legs
    from dwh.client_order cl
             join tmp_base tmp on tmp.order_id = cl.parent_order_id
    where true
      and cl.parent_order_id is not null
      and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.create_date_id >= tmp.create_date_id
      and cl.create_date_id > l_gtc_min_date_id
      and case
              when l_is_multileg then cl.multileg_reporting_type in ('2')
              else cl.multileg_reporting_type = '1' end
      and case
              when in_exclude_blaze then (cl.ex_destination IS NULL OR cl.ex_destination NOT ILIKE '%blaze%')
              else true end
      and case
              when in_exclude_blaze then (cl.exchange_id is null or cl.exchange_id not ilike '%blaze%')
              else true end;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || '  street orders added  ===', l_row_cnt, 'O')
    into l_step_id;

    insert into tmp_base
    select *
    from tmp_base_str;

    create index on tmp_base (order_id, create_date_id);

    /*
     4) On the NO record, we only require the ORDER_DATETIME, the net LIMIT_PRICE, number of legs in a CLIENT_TEXT field, and the Route Destination in a CLIENT_TEXT field.
    On the NO record, we will disregard security type, symbol, order action, order type, order volume and the many conditions and modifiers.
     */

----Parent/Street  orders----
    insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
    select 'NO'                                      as record_type,
           coalesce(cl.parent_order_id, cl.order_id) as order_id,
           to_char(cl.process_time, 'HH24MISSFF3')   as time_id,
           cl.client_order_id                        as record_id,
           1                                         as record_type_id,
           array_to_string(array [
                               'O', -- [1]
                               tmp_base.noro, -- [2]
                               cl.client_order_id, -- [3]
                               cl.order_id::text, -- [4] source_order_id
                               case
                                   when tmp_base.noro = 'NO' then ''--cl.client_order_id
                                   else tmp_base.parent_order_id::text /*tmp_base.parent_client_order_id*/ end, -- [5]
                               cl.orig_order_id::text, -- [6]
                               case
                                   when not l_is_multileg
                                       then null
                                   when cl.multileg_reporting_type = '3' then cl.order_id::text
                                   --                                   when cl.multileg_reporting_type = '2' then cl.multileg_order_id::text
--                                   when cl.multileg_reporting_type = '3' then cl.order_id::text
--                                   when tmp_base.noro = 'NO' and cl.multileg_reporting_type = '2'
--                                       then cl.multileg_order_id::text
--                                   when tmp_base.noro = 'RO' and cl.multileg_reporting_type = '2'
--                                       then cl.parent_order_id::text
                                   when cl.multileg_reporting_type = '2'
                                       then tmp_base.multileg_order_id::text -- Update SOURCE_COMPLEX_ID on RO for complex order.  The RO field 7 should be the same as the NO field 7.

                                   end, -- [7]
                               case
                                   when not l_is_multileg then ac.broker_dealer_mpid
                                   else
                                       case
                                           when cl.parent_order_id is null and ac.broker_dealer_mpid = 'NONE' then ''
                                           when cl.parent_order_id is null then ac.broker_dealer_mpid
                                           else 'DFIN'
                                           end
                                   end, -- [8]
                               case
                                   when noro = 'NO' then 'DFIN'
                                   when in_actual_exchange then coalesce(exc.mic_code, exc.eq_mpid)
                                   else 'DFIN'
                                   end, -- [9]
                               null, -- [10]
                               null, -- [11]
                               case
                                   when noro = 'NO' and l_is_multileg
                                       then null
                                   else i.instrument_type_id end, -- [12]
                               case
                                   when noro = 'NO' and l_is_multileg then null
                                   when i.instrument_type_id = 'E' then i.display_instrument_id
                                   when i.instrument_type_id = 'O' then oc.opra_symbol
                                   end , -- [13]
                               null, -- [14] primary  Exchange
                               case
                                   when noro = 'NO' and l_is_multileg then null
                                   else
                                       case cl.side
                                           when '1' then 'B'
                                           when '2' then 'S'
                                           when '5' then 'SS'
                                           when '6' then 'SSE'
                                           end end, -- [15] OrderAction
                               to_char(cl.process_time, 'YYYYMMDD') || 'T' ||
                               to_char(cl.process_time, 'HH24MISSFF3'), -- [16]
                               case
                                   when noro = 'NO' and l_is_multileg then null
                                   else ot.order_type_short_name end, -- [17] order_type
                               case
                                   when noro = 'NO' and l_is_multileg then null
                                   when noro = 'NO' and not l_is_multileg then cl.order_qty::text
                                   when noro = 'RO' then case
                                                             when not l_is_multileg then cl.order_qty::text
                                                             else
                                                                 case
                                                                     when cl.multileg_reporting_type = '3' then null
                                                                     else cl.order_qty::text end
                                       end end, -- [18] order_volume
--                               case when cl.side = '1' then '-' else '' end,
                               to_char(cl.price, 'FM99990D0099'), -- [19]
                               to_char(cl.stop_price, 'FM99990D0099'), -- [20]
                               case when cl.time_in_force_id not in ('2', '7') then tif.tif_short_name end, -- [21]
                               case
                                   when not l_is_multileg then
                                       coalesce(to_char(cl.expire_time, 'YYYYMMDD'), '') || 'T' ||
                                       coalesce(to_char(cl.expire_time, 'HH24MISSFF3'), '')
                                   else
                                       case
                                           when cl.expire_time is not null then
                                               coalesce(to_char(cl.expire_time, 'YYYYMMDD'), '') || 'T' ||
                                               coalesce(to_char(cl.expire_time, 'HH24MISSFF3'), '')
                                           when cl.time_in_force_id = '6' then
                                               (select coalesce(fmj.fix_message ->> '432', '') || 'T235959000'
                                                from fix_capture.fix_message_json fmj
                                                where fix_message_id = cl.fix_message_id
                                                  and fmj.date_id = cl.create_date_id
                                                limit 1)
                                           end
                                   end, --[22]
                               '0', -- [23] PRE_MARKET_IND
                               null, -- [24]
                               '0', -- [25] POST_MARKET_IND
                               null, -- [26]
                               case
                                   when cl.parent_order_id is null
                                       then case cl.sub_strategy_desc when 'DMA' then '1' else '0' end
                                   else case po.sub_strategy_desc when 'DMA' then '1' else '0' end
                                   end, -- [27] --DIRECTED_ORDER_IND
                               case
                                   when (cl.parent_order_id is null or l_is_multileg)
                                       then case cl.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                                   else case po.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                                   end, -- [28] NON_DISPLAY_IND
                               '0', -- [29] DO_NOT_REDUCE
                               case cl.exec_instruction when 'G' then '1' else '0' end, -- [30]
                               case
                                   when cl.exec_instruction = '1' then '1'
                                   when cl.is_held = 'Y' then '1'
                                   else '0' end, -- [31] NOT_HELD_IND
                               case
                                   when ot.order_type_id in ('O', 'L') then '1'
                                   when tif.tif_id = '2' then '1'
                                   else '0' end, -- [32]
                               case
                                   when ot.order_type_id in ('5', 'B') then '1'
                                   when tif.tif_id = '7' then '1'
                                   else '0' end, -- [33]
                               '0', -- [34]
                               null, -- [35]
                               null, -- [36]
                               null, -- [37]
                               null, -- [38]
--                                case
--                                    when l_is_multileg then cl.ex_destination
--                                    end, -- [39]
                               cof.customer_or_firm_name, -- [39] Client wants to add account capacity in location 39 CLIENT_TEXT field
                               case
                                   when l_is_multileg --and cl.multileg_reporting_type = '3'
                                       then tmp_base.no_legs::text
                                   end, -- [40]
                               null, -- [41]
                               null, -- [42]
                               null, -- [43]
                               null, -- [44]
                               null, -- [45]
                               null, -- [46]
                               null, -- [47]
                               null -- [48]
                               ], '|', '')           as REC
    from dwh.client_order cl
             join tmp_base using (create_date_id, order_id)
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
             left join lateral (select po.sub_strategy_desc
                                from dwh.client_order po
                                where po.order_id = cl.parent_order_id
                                  and po.create_date_id <= cl.create_date_id
                                limit 1) po on true
             left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
             left join lateral (select exc.mic_code, exc.eq_mpid
                                from dwh.d_exchange exc
                                where exc.exchange_id = cl.exchange_id
                                  and exc.is_active
                                limit 1) exc on true
             left join dwh.d_customer_or_firm cof on cof.customer_or_firm_id = cl.customer_or_firm_id
    where true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' orders part of report created  ===', l_row_cnt, 'O')
    into l_step_id;

    drop table if exists tmp_exec;
    create temp table if not exists tmp_exec as
    select case when ex.exec_type in ('4', '8') then 2 else 3 end as tp,
           cl.parent_order_id,
           cl.order_id,
           cl.process_time,
           cl.client_order_id,
           ex.exec_type,
           cl.multileg_reporting_type,
           i.instrument_type_id,
           i.display_instrument_id,
           oc.opra_symbol,
           ex.exec_time,
           ex.exec_id,
           ex.last_qty,
           ex.last_px,
           ex.exchange_id,
           ex.secondary_exch_exec_id,
           ex.exch_exec_id
    from tmp_base as cl
             join dwh.execution ex on ex.order_id = cl.order_id
             join dwh.d_instrument i on i.instrument_id = cl.instrument_id
             left join lateral (select opra_symbol, option_series_id
                                from dwh.d_option_contract oc
                                where oc.instrument_id = i.instrument_id
                                limit 1) oc on true
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id
    where true
      and ex.exec_date_id between in_start_date_id and in_end_date_id
      and ex.exec_type in ('4', '8', 'F')
      and cl.noro = 'RO';
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' events added  ===', l_row_cnt, 'O')
    into l_step_id;


    insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
    --order  activity:  cancel
    select 'A'                                  as record_type,
           coalesce(parent_order_id, order_id)  as order_id,
           to_char(process_time, 'HH24MISSFF3') as time_id,
           client_order_id                      as record_id,
           3                                    as record_type_id,
           array_to_string(array [
                               'A' ,
                               order_id::text ,
                               case exec_type when '4' then 'C' when '8' then 'RJ' end , --EVENT
                               null , --SYSTEM_ID
--                               case multileg_reporting_type
--                                   when '3' then null
--                                   else instrument_type_id end , --
                               instrument_type_id,
                               case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol end,
                               null , --  --SYMBOL_EXCHANGE
                               to_char(exec_time, 'YYYYMMDD') || 'T' || to_char(exec_time, 'HH24MISSFF3'),
                               null , -- DESCRIPTION
                               null , -- [10]
                               null , -- [11]
                               null , -- [12]
                               null , -- [13]
                               null -- [14]
                               ], '|', '')
    from tmp_exec
    where tp = 2
--      and case when l_is_multileg then parent_order_id is null else true end
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' Events part of report added  ===', l_row_cnt, 'O')
    into l_step_id;


    insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)

    select 'T'                                 as record_type,
           coalesce(parent_order_id, order_id) as order_id,
           to_char(exec_time, 'HH24MISSFF3')   as time_id,
           client_order_id                     as record_id,
           2                                   as record_type_id,
           array_to_string(array [
                               'T' ,
                               order_id::text ,
--                                order_id::text || '_' || exec_id::text ,
                               order_id::text || '_' || coalesce(secondary_exch_exec_id, exch_exec_id, ''),
                               null ,
                               null , --
                               instrument_type_id , --
                               case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol end,
                               null , --  --SYMBOL_EXCHANGE
                               to_char(exec_time, 'YYYYMMDD') || 'T' ||
                               to_char(exec_time, 'HH24MISSFF3'), -- ACTION_DATETIME
                               last_qty::text, --
                               to_char(last_px, 'fm99990d0099') , --
                               exchange_id , --
                               null , --  --[12]
                               null , --  --[13]
                               case when l_is_multileg and multileg_reporting_type = '2' then 'COMPLEX' end , --  --[14]
                               null , -- [15]
                               null , -- [16]
                               null , -- [17]
                               null , -- [18]
                               null , -- [19]
                               null , -- [20]
                               null , -- [21]
                               null , -- [22]
                               null -- [23]
                               ], '|', '')
    from tmp_exec
    where tp = 3
    --      and case
--              when l_is_multileg then (multileg_reporting_type = '2' and parent_order_id is null)
--              else multileg_reporting_type = '1' end
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || '  Cancels  added', l_row_cnt, 'O')
    into l_step_id;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' Cancels part of report added  ===', l_row_cnt, 'O')
    into l_step_id;


    return query
        select case
                   when record_type = 'H' then rec || '|' ||
                                               in_start_date_id::text || 'T' || min_time || '|' || --Starting  Event
                                               in_end_date_id::text || 'T' || max_time || '|' || --Ending  Event
                                               'DFIN' || '|' ||
                                               (select coalesce(cat_imid, '')
                                                from dwh.d_account
                                                         join dwh.d_trading_firm using (trading_firm_id)
                                                where true
                                                  and case
                                                          when l_account_ids = '{}' then true
                                                          else account_id = any (l_account_ids) end
                                                  and cat_imid is not null
                                                limit 1) || '|' ||
                                               'dashtradedesk@iongroup.com' || '|' ||
                                               ''
                   else rec
                   end
        from (select min(time_id) over () as min_time,
                     max(time_id) over () as max_time,
                     record_type,
                     rec
              from t_report

              order by order_id, time_id, record_id, record_type_id) x;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || '  COMPLETED  ===', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;
