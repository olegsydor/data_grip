select * from dwh.execution
where exec_date_id = 20240910;

select * from dwh.gtc_order_status;
select * from dwh.gtc_restate_daily(20240911, 20240911);

create or replace function dwh.gtc_restate_daily(p_start_date_id integer default null::integer,
                                                 p_end_date_id integer default null::integer)
    returns integer
    language plpgsql
AS
$function$
-- 2024-09-11 SO https://dashfinancial.atlassian.net/browse/DS-8855 reusing of last_mod_date_is as date of the last restate of order (exec_status = 'D' in execution)
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
                           'dwh.gtc_restate_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
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
    drop table if exists staging.gtc_restate_modif;
    create table staging.gtc_restate_modif as
    select gtc.order_id,
           gtc.create_date_id,
           iex.close_date_id as last_mod_date_id,
           'R'               as order_status
    from dwh.gtc_order_status gtc
             join lateral (select public.get_gth_date_id_by_instrument(iex.exec_time,
                                                                       gtc.instrument_id) as close_date_id
                           from dwh.execution iex
                           where true
                             and iex.order_id = gtc.order_id
                             and iex.exec_type = '0'
                             and exec_date_id between l_start_date_id and l_end_date_id
                           order by exec_id desc
                           limit 1) iex on true
    where gtc.close_date_id is null;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_restate_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' execution flow update', l_row_cnt, 'U')
    into l_step_id;

    update dwh.gtc_order_status gtc
    set last_mod_date_id = base.last_mod_date_id,
        db_update_time   = clock_timestamp() --??
    from staging.gtc_restate_modif base
    where gtc.order_id = base.order_id
      and gtc.create_date_id = base.create_date_id
      and gtc.close_date_id is null
      and gtc.last_mod_date_id < base.last_mod_date_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dwh.gtc_restate_daily for ' || l_start_date_id::text || ' - ' || l_end_date_id::text ||
                           ' FINISHED===', l_row_cnt, 'E')
    into l_step_id;

    return l_row_cnt;
end;
$function$
;



INSERT INTO staging.sync_test_tables_dict (table_name,source_1_name,source_1_query,source_2_name,source_2_query,last_processed_date_id,is_active,entity_type,interval_query,pre_query,post_query,offset_days_cnt) VALUES
	 ('BLAZE7_TPRICE','BLAZE7_PG',$$WITH src AS
(
SELECT 'BLAZE7_TPRICE'::TEXT                                             AS table_name,
       &p_date_id::numeric                                                   AS date_id,
       count(1)                                                              AS cn,
       stddev(l2.pg_order_id)                                                AS dev_pg_ord_id,
       corr(pg_order_id::double precision, legnumber::double precision)      AS corr_legnumber,
       corr(pg_order_id::double precision, status::double precision)         AS corr_status,
       corr(pg_order_id::double precision, exec_id::double precision)        AS corr_exec_id,
       corr(pg_order_id::double precision, dashsecurityid::double precision) AS corr_dashsecurityid
FROM (select tp.reportid,
          tp."_order_id" as pg_order_id,--
             tp.legnumber::int,
             (('x'::text || lpad(md5(tp.status), 32, '0'))::bit(64))::bigint         as status,
             (('x'::text || lpad(md5(tp.reportid), 32, '0'))::bit(64))::bigint        as exec_id,
             (('x'::text || lpad(md5(tp.dashsecurityid), 32, '0'))::bit(64))::bigint as dashsecurityid
      from staging.tprices_edw_ts as tp
      where to_char("_db_create_time", 'YYYYMMDD')::int = &p_date_id
      order by tp.reportid
      ) l2
)

INSERT INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
           metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05)
SELECT
	   'BLAZE7_PG'::text as source_name
       , d.table_name as table_name
       , d.date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows
       , 'dev_pg_ord_id'::varchar as metric_name_01
       , d.dev_pg_ord_id::double precision as metric_value_01
       , 'corr_legnumber'::varchar as metric_name_02
       , d.corr_legnumber::double precision as metric_value_02
       , 'corr_status'::varchar as metric_name_03
       , d.corr_status::double precision as metric_value_03
       , 'corr_exec_id'::varchar as metric_name_04
       , d.corr_exec_id::double precision as metric_value_04
       , 'corr_dashsecurityid'::varchar as metric_name_05
       , d.corr_dashsecurityid::double precision as metric_value_05

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
          , metric_value_05    = excluded.metric_value_05;$$,'BLAZE7_EDW_UAT',$$WITH src AS
(
	SELECT 'BLAZE7_TPRICE'::TEXT                                             AS table_name,
       &p_date_id::numeric                                                   AS date_id,
       count(1)                                                              AS cn,
       stddev(l2.pg_order_id)                                                AS dev_pg_ord_id,
       corr(pg_order_id::double precision, legnumber::double precision)      AS corr_legnumber,
       corr(pg_order_id::double precision, status::double precision)         AS corr_status,
       corr(pg_order_id::double precision, exec_id::double precision)        AS corr_exec_id,
       corr(pg_order_id::double precision, dashsecurityid::double precision) AS corr_dashsecurityid
FROM (select tp.pg_order_id,--
             tp.legnumber::int,
             (('x'::text || lpad(md5(tp.status), 32, '0'))::bit(64))::bigint         as status,
             (('x'::text || lpad(md5(tp.exec_id), 32, '0'))::bit(64))::bigint        as exec_id,
             (('x'::text || lpad(md5(tp.dashsecurityid), 32, '0'))::bit(64))::bigint as dashsecurityid

      from staging.edw_blaze7_tprice as tp
      where coalesce(date_id, 0) = &p_date_id
        and upper(tp.pg_entity) = 'UAT'
      order by coalesce(tp.exec_id, '')) l2
)
INSERT INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
           metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05)
SELECT
	   'BLAZE7_EDW_UAT'::text as source_name
       , d.table_name as table_name
       , d.date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows
       , 'dev_pg_ord_id'::varchar as metric_name_01
       , d.dev_pg_ord_id::double precision as metric_value_01
       , 'corr_legnumber'::varchar as metric_name_02
       , d.corr_legnumber::double precision as metric_value_02
       , 'corr_status'::varchar as metric_name_03
       , d.corr_status::double precision as metric_value_03
       , 'corr_exec_id'::varchar as metric_name_04
       , d.corr_exec_id::double precision as metric_value_04
       , 'corr_dashsecurityid'::varchar as metric_name_05
       , d.corr_dashsecurityid::double precision as metric_value_05
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
          , metric_value_05    = excluded.metric_value_05;
$$,20240918,true,NULL,NULL,NULL,NULL,NULL);


SELECT 'BLAZE7_TPRICE'::TEXT                                                 AS table_name,
       &p_date_id::numeric                                                   AS date_id,
       count(1)                                                              AS cn,
       stddev(l2.pg_order_id)                                                AS dev_pg_ord_id,
       corr(pg_order_id::double precision, legnumber::double precision)      AS corr_legnumber,
       corr(pg_order_id::double precision, status::double precision)         AS corr_status,
       corr(pg_order_id::double precision, exec_id::double precision)        AS corr_exec_id,
       corr(pg_order_id::double precision, dashsecurityid::double precision) AS corr_dashsecurityid
FROM (select tp.pg_order_id,--
             tp.legnumber::int,
             (('x'::text || lpad(md5(tp.status), 32, '0'))::bit(64))::bigint         as status,
             (('x'::text || lpad(md5(tp.exec_id), 32, '0'))::bit(64))::bigint        as exec_id,
             (('x'::text || lpad(md5(tp.dashsecurityid), 32, '0'))::bit(64))::bigint as dashsecurityid
      from staging.edw_blaze7_tprice as tp
      where coalesce(date_id, 0) = &p_date_id
        and upper(tp.pg_entity) = 'UAT'
      order by trim(tp.exec_id)) l2 )




WITH src AS
(
	SELECT 'BLAZE7_TPRICE'::TEXT                                             AS table_name,
       &p_date_id::numeric                                                   AS date_id,
       count(1)                                                              AS cn,
       stddev(l2.pg_order_id)                                                AS dev_pg_ord_id,
       corr(pg_order_id::double precision, legnumber::double precision)      AS corr_legnumber,
       corr(pg_order_id::double precision, status::double precision)         AS corr_status,
       corr(pg_order_id::double precision, exec_id::double precision)        AS corr_exec_id,
       corr(pg_order_id::double precision, dashsecurityid::double precision) AS corr_dashsecurityid
FROM (select tp.pg_order_id,--
             tp.legnumber::int,
             (('x'::text || lpad(md5(tp.status), 32, '0'))::bit(64))::bigint         as status,
             (('x'::text || lpad(md5(tp.exec_id), 32, '0'))::bit(64))::bigint        as exec_id,
             (('x'::text || lpad(md5(tp.dashsecurityid), 32, '0'))::bit(64))::bigint as dashsecurityid

      from staging.edw_blaze7_tprice as tp
      where coalesce(date_id, 0) = &p_date_id
        and upper(tp.pg_entity) = 'UAT'
      order by coalesce(tp.exec_id, '')) l2
)
INSERT INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
           metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05,
           metric_name_06, metric_value_06, metric_name_07, metric_value_07, metric_name_08, metric_value_08)
SELECT
	   'BLAZE7_EDW_UAT'::text as source_name
       , d.table_name as table_name
       , d.date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows
       , 'dev_pg_ord_id'::varchar as metric_name_01
       , d.dev_pg_ord_id::double precision as metric_value_01
       , 'corr_legnumber'::varchar as metric_name_02
       , d.corr_legnumber::double precision as metric_value_02
       , 'corr_status'::varchar as metric_name_03
       , d.corr_status::double precision as metric_value_03
       , 'corr_exec_id'::varchar as metric_name_04
       , d.corr_exec_id::double precision as metric_value_04
       , 'corr_dashsecurityid'::varchar as metric_name_05
       , d.corr_dashsecurityid::double precision as metric_value_05

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
          , metric_value_05    = excluded.metric_value_05;



---

WITH src AS
(
SELECT 'BLAZE7_TPRICE'::TEXT                                             AS table_name,
       &p_date_id::numeric                                                   AS date_id,
       count(1)                                                              AS cn,
       stddev(l2.pg_order_id)                                                AS dev_pg_ord_id,
       corr(pg_order_id::double precision, legnumber::double precision)      AS corr_legnumber,
       corr(pg_order_id::double precision, status::double precision)         AS corr_status,
       corr(pg_order_id::double precision, exec_id::double precision)        AS corr_exec_id,
       corr(pg_order_id::double precision, dashsecurityid::double precision) AS corr_dashsecurityid
FROM (select tp.reportid,
          tp."_order_id" as pg_order_id,--
             tp.legnumber::int,
             (('x'::text || lpad(md5(tp.status), 32, '0'))::bit(64))::bigint         as status,
             (('x'::text || lpad(md5(tp.reportid), 32, '0'))::bit(64))::bigint        as exec_id,
             (('x'::text || lpad(md5(tp.dashsecurityid), 32, '0'))::bit(64))::bigint as dashsecurityid
      from staging.tprices_edw_ts as tp
      where to_char("_db_create_time", 'YYYYMMDD')::int = &p_date_id
      order by tp.reportid
      ) l2
)

INSERT INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
           metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05,
           metric_name_06, metric_value_06, metric_name_07, metric_value_07, metric_name_08, metric_value_08)
SELECT
	   'BLAZE7_EDW_UAT'::text as source_name
       , d.table_name as table_name
       , d.date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows
       , 'dev_pg_ord_id'::varchar as metric_name_01
       , d.dev_pg_ord_id::double precision as metric_value_01
       , 'corr_legnumber'::varchar as metric_name_02
       , d.corr_legnumber::double precision as metric_value_02
       , 'corr_status'::varchar as metric_name_03
       , d.corr_status::double precision as metric_value_03
       , 'corr_exec_id'::varchar as metric_name_04
       , d.corr_exec_id::double precision as metric_value_04
       , 'corr_dashsecurityid'::varchar as metric_name_05
       , d.corr_dashsecurityid::double precision as metric_value_05

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
          , metric_value_05    = excluded.metric_value_05;



create temp table t_blaze as
select 'pg' as src,
          tp."_order_id" as pg_order_id,--
          tp.reportid
      from staging.tprices_edw as tp
where to_char("_db_create_time", 'YYYYMMDD')::int = :p_date_id
and coalesce(tp.reportid, '') = 'j5ib5dc00g00'
       order by coalesce(tp.reportid, '')

insert into t_blaze (src, pg_order_id, reportid)
select 'edw',
    tp.pg_order_id,--
       tp.exec_id
      from staging.edw_blaze7_tprice as tp
      where coalesce(date_id, 0) = :p_date_id
        and upper(tp.pg_entity) = 'UAT'
      and exec_id = 'j5ib5dc00g00'
      order by coalesce(tp.exec_id, '');


select pg_order_id, reportid from t_blaze
where src = 'pg'
except
select pg_order_id, reportid from t_blaze
where src = 'edw'

select * from staging.edw_blaze7_tprice
where coalesce(pg_order_id, 0) = 635187202275409920
and coalesce(date_id, 0) = 20240918
    select *
from staging.tprices_edw as tp
    where _order_id = 635187202275409920
    and _db_create_time::date = '2024-09-18'

BLAZE7_EDW_UAT,BLAZE7_TPRICE,20240918,2024-09-19 17:07:10.342800 +00:00,1815,dev_pg_ord_id,39810227004855136,corr_legnumber,0.2612595973003835,corr_status,0.030754932164165426,corr_exec_id,0.010645219094902429,corr_dashsecurityid,-0.22427140775261634
BLAZE7_EDW_UAT,BLAZE7_TPRICE,20240918,2024-09-19 17:06:22.033668 +00:00,1815,dev_pg_ord_id,39810227004855136,corr_legnumber,0.26125959730038584,corr_status,0.030754932164165874,corr_exec_id,0.004863824780777405,corr_dashsecurityid,-0.22427140775260818
BLAZE7_EDW_UAT	BLAZE7_TPRICE	20240918	2024-09-19 13:10:13.172 -0400	1815.0	dev_pg_ord_id	39810227004855136	corr_legnumber	0.2612595973003835	corr_status	0.030754932164165426	corr_exec_id	0.010645219094902429	corr_dashsecurityid	-0.22427140775261634