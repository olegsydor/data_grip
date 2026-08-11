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
