
INSERT INTO staging.sync_test_tables_dict (table_name,source_1_name,source_1_query,source_2_name,source_2_query,last_processed_date_id,is_active,entity_type,interval_query,pre_query,post_query) VALUES
	 ('HODS','DWH','with dwh_src as
     (
      SELECT ''HODS''::text                                                           AS table_name,
             &p_date_id::numeric                                                      AS big_data_date_id,
             count(1)                                                                 AS cn
      FROM (
            SELECT 1 as no_column
            FROM staging.historic_order_details_storage_big_data
            ) l1
     )
     insert into staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows, metric_name_01, metric_value_01)
     select ''DWH'' as source_name
       , d.table_name as table_name
       , d.big_data_date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows
     from dwh_src as d
      on conflict on constraint sync_test_calc_metrics_pkey do
        update set
            pg_db_updated_time = excluded.pg_db_updated_time
          , metric_cnt_rows    = excluded.metric_cnt_rows',
          'STAGING','with st_src as
     (
      SELECT ''HODS''::text                                                            AS table_name,
			 &p_date_id::numeric                                                                 AS staging_date_id,
             count(1)                                                                            AS cn
      FROM (
            SELECT 1 AS no_column
            FROM staging.historic_order_details_storage_dmp
            ) l1
     )
     insert into staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows, metric_name_01, metric_value_01)
     select ''STAGING'' as source_name
       , d.table_name as table_name
       , d.staging_date_id as date_id
       , clock_timestamp() as pg_db_updated_time
       , d.cn::double precision as metric_cnt_rows

     from st_src as d
      on conflict on constraint sync_test_calc_metrics_pkey do
        update set
            pg_db_updated_time = excluded.pg_db_updated_time
          , metric_cnt_rows    = excluded.metric_cnt_rows',
20180410,false,'DIMENSION',NULL,NULL,NULL);


-- run sync test
select staging.sync_test_metrics_calc(in_date_id := :p_date_id, in_table_name := 'HODS');

-- check sync test
select x.*
from staging.sync_test_calculated_metrics x
where date_id = :p_date_id
  and table_name = 'HODS';

with dwh_src as
         (SELECT 'HODS'::text        AS table_name,
                 :p_date_id::numeric AS big_data_date_id,
                 count(1)            AS cn
          FROM (SELECT 1 as no_column
                FROM staging.historic_order_details_storage_big_data
                where "Status_Date_id" = :p_date_id) l1)
insert
into staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows)
select 'DWH'                  as source_name
     , d.table_name           as table_name
     , d.big_data_date_id     as date_id
     , clock_timestamp()      as pg_db_updated_time
     , d.cn::double precision as metric_cnt_rows
from dwh_src as d
on conflict
    on constraint sync_test_calc_metrics_pkey
    do update set pg_db_updated_time = excluded.pg_db_updated_time
                , metric_cnt_rows    = excluded.metric_cnt_rows;


with st_src as
         (SELECT 'HODS'::text        AS table_name,
                 :p_date_id::numeric AS staging_date_id,
                 count(1)            AS cn
          FROM (SELECT 1 AS no_column
                FROM staging.historic_order_details_storage_dmp
                where "Status_Date_id" = :p_date_id) l1)
insert
into staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows)
select 'STAGING'              as source_name
     , d.table_name           as table_name
     , d.staging_date_id      as date_id
     , clock_timestamp()      as pg_db_updated_time
     , d.cn::double precision as metric_cnt_rows
from st_src as d
on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
                                                                  , metric_cnt_rows    = excluded.metric_cnt_rows