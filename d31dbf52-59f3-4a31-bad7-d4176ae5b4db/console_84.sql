INSERT INTO staging.sync_test_tables_dict (table_name,source_1_name,source_1_query,source_2_name,source_2_query,last_processed_date_id,is_active,entity_type,interval_query,pre_query,post_query,offset_days_cnt) VALUES
	 ('BLAZE7_EXCHANGE_MAP','BLAZE7_PG',$$WITH src AS
         (SELECT 'BLAZE7_EXCHANGE_MAP'::TEXT AS table_name,
                 &p_date_id::NUMERIC         AS date_id,
                 count(1)                    AS cn,
                 stddev(l2.check_sum)        AS dev_chk_sum
          FROM (SELECT em.mic_code                         AS mic_code,
                       (('x'::TEXT || lpad(
                               md5(row (security_type, venue_exchange, business_name, ex_destination, venue_fix_code, exchange_code, is_exchange, applicable_spread_type, supports_bi, supports_cob)::text),
                               32, '0'))::BIT(64))::bigint as check_sum
                FROM staging.edw_blaze7_exchange_map AS em
                WHERE true
                ORDER BY mic_code) l2)

INSERT
INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
                                           metric_name_01, metric_value_01, metric_name_02, metric_value_02)
SELECT 'BLAZE7_PG'::text               as source_name
     , d.table_name                    as table_name
     , d.date_id                       as date_id
     , clock_timestamp()               as pg_db_updated_time
     , d.cn::double precision          as metric_cnt_rows
     , 'dev_chk_sum'::varchar          as metric_name_01
     , d.dev_chk_sum::double precision as metric_value_01
FROM src AS d
on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
                                                                  , metric_cnt_rows    = excluded.metric_cnt_rows
                                                                  , metric_name_01     = excluded.metric_name_01
                                                                  , metric_value_01    = excluded.metric_value_01$$,'BLAZE7_EDW_PROD1',$$WITH src AS
         (SELECT 'BLAZE7_EXCHANGE_MAP'::TEXT AS table_name,
                 &p_date_id::NUMERIC         AS date_id,
                 count(1)                    AS cn,
                 stddev(l2.check_sum)        AS dev_chk_sum
          FROM (SELECT em.mic_code                         AS mic_code,
                       (('x'::TEXT || lpad(
                               md5(row (security_type, venue_exchange, business_name, ex_destination, venue_fix_code, exchange_code, is_exchange, applicable_spread_type, supports_bi, supports_cob)::text),
                               32, '0'))::BIT(64))::bigint as check_sum
                FROM staging.exchange_map_prod1 AS em
                WHERE true
                ORDER BY mic_code) l2)

INSERT
INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
                                           metric_name_01, metric_value_01, metric_name_02, metric_value_02)
SELECT 'BLAZE7_EDW_PROD1'::text        as source_name
     , d.table_name                    as table_name
     , d.date_id                       as date_id
     , clock_timestamp()               as pg_db_updated_time
     , d.cn::double precision          as metric_cnt_rows
     , 'dev_chk_sum'::varchar          as metric_name_01
     , d.dev_chk_sum::double precision as metric_value_01
FROM src AS d
on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
                                                                  , metric_cnt_rows    = excluded.metric_cnt_rows
                                                                  , metric_name_01     = excluded.metric_name_01
                                                                  , metric_value_01    = excluded.metric_value_01
;$$,20240822,true,NULL,NULL,NULL,NULL,NULL);



WITH src AS
         (SELECT 'BLAZE7_EXCHANGE_MAP'::TEXT AS table_name,
                 &p_date_id::NUMERIC         AS date_id,
                 count(1)                    AS cn,
                 stddev(l2.check_sum)        AS dev_chk_sum
          FROM (SELECT em.mic_code                         AS mic_code,
                       (('x'::TEXT || lpad(
                               md5(row (security_type, venue_exchange, business_name, ex_destination, venue_fix_code, exchange_code, is_exchange, applicable_spread_type, supports_bi, supports_cob)::text),
                               32, '0'))::BIT(64))::bigint as check_sum
                FROM staging.exchange_map_prod1 AS em
                WHERE true
                ORDER BY mic_code) l2)

INSERT
INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows,
                                           metric_name_01, metric_value_01, metric_name_02, metric_value_02)
SELECT 'BLAZE7_EDW_PROD1'::text        as source_name
     , d.table_name                    as table_name
     , d.date_id                       as date_id
     , clock_timestamp()               as pg_db_updated_time
     , d.cn::double precision          as metric_cnt_rows
     , 'dev_chk_sum'::varchar          as metric_name_01
     , d.dev_chk_sum::double precision as metric_value_01
FROM src AS d
on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
                                                                  , metric_cnt_rows    = excluded.metric_cnt_rows
                                                                  , metric_name_01     = excluded.metric_name_01
                                                                  , metric_value_01    = excluded.metric_value_01
;



select gtc.close_date_id,
       public.get_gth_date_id_by_instrument(gtc.exec_time, cl.instrument_id),
       gtc.exec_time,
       gtc.order_id,
       gtc.create_date_id
from dwh.gtc_order_status gtc
         join dwh.client_order cl using (order_id, create_date_id)
where close_date_id is not null
  and public.get_gth_date_id_by_instrument(gtc.exec_time, cl.instrument_id) != gtc.close_date_id
  and closing_reason in ('E', 'P')
limit 5


select count(*)
from dwh.gtc_order_status gtc
         join lateral (select instrument_id from dwh.client_order cl where cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id limit 1) cl on true
where close_date_id is not null
  and public.get_gth_date_id_by_instrument(gtc.exec_time, cl.instrument_id) != gtc.close_date_id
  and closing_reason in ('E', 'P')