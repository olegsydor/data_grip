create function staging.so_sync_test(in_table text, in_date_id int)
    returns int
    language plpgsql
as
$$
begin
    if in_table = 'TORDER' then
        WITH src AS
                 (SELECT 'BLAZE7_TORDER'::TEXT                                         AS table_name,
                         in_date_id::NUMERIC                                           AS date_id,
                         count(1)                                                      AS cn,
                         stddev(l2.cl_ord_id)                                          AS dev_cl_ord_id,
                         stddev(l2.order_id)                                           AS dev_order_id,
                         corr(cl_ord_id::double precision, order_id::double precision) AS corr_order_id,
                         corr(cl_ord_id::double precision,
                              systemordertypeid::double precision)                     AS corr_systemordertypeid,
                         corr(cl_ord_id::double precision, status::double precision)   AS corr_status,
                         corr(cl_ord_id::double precision, userid::double precision)   AS corr_user_id,
                         corr(cl_ord_id::double precision,
                              exchangeconnectionid::double precision)                  AS corr_exchangeconnectionid,
                         sum(l2.legcount)::bigint                                      AS sum_legcount,
                         sum(l2.price)::numeric                                        AS sum_price,
                         sum(l2.quantity)::bigint                                      AS sum_quantity,
                         sum(l2.filled)::bigint                                        AS sum_filled,
                         sum(l2.stockfilled)::bigint                                   AS sum_stockfilled,
                         sum(l2.optionfilled)::bigint                                  AS sum_optionfilled
                  FROM (SELECT (('x'::TEXT || lpad(md5(torder.systemorderid), 32, '0'))::BIT(64))::bigint        AS cl_ord_id,
                               (('x'::TEXT || lpad(md5(torder.systemordertypeid), 32, '0'))::BIT(64))::bigint    AS systemordertypeid,
                               (('x'::TEXT || lpad(md5(torder.status), 32, '0'))::BIT(64))::bigint               AS status,
                               torder.userid,
                               (('x'::TEXT || lpad(md5(torder.exchangeconnectionid), 32, '0'))::BIT(64))::bigint AS exchangeconnectionid,
                               torder.legcount::int,
                               round(torder.price::numeric, 2)                                                   as price, --
                               torder.quantity::int,
                               torder.filled::int,
                               torder.stockfilled::int,
                               torder.optionfilled::int,
                               torder.pg_order_id                                                                AS order_id
                        FROM staging.so_edw_blaze7_torder AS torder
                        WHERE COALESCE(order_trade_date_id, 0) between in_date_id and public.get_dateid(public.get_business_date(in_date_id::text::date, 1))
                          and upper(torder.pg_entity) = 'UAT'
                        ORDER BY trim(torder.systemorderid)) l2)
        INSERT
        INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time,
                                                   metric_cnt_rows,
                                                   metric_name_01, metric_value_01, metric_name_02, metric_value_02,
                                                   metric_name_03, metric_value_03, metric_name_04, metric_value_04,
                                                   metric_name_05, metric_value_05,
                                                   metric_name_06, metric_value_06, metric_name_07, metric_value_07,
                                                   metric_name_08, metric_value_08, metric_name_09, metric_value_09,
                                                   metric_name_10, metric_value_10,
                                                   metric_name_11, metric_value_11, metric_name_12, metric_value_12,
                                                   metric_name_13, metric_value_13)
        SELECT 'BLAZE7_EDW_SO'::text                         as source_name
             , d.table_name                                  as table_name
             , d.date_id                                     as date_id
             , clock_timestamp()                             as pg_db_updated_time
             , d.cn::double precision                        as metric_cnt_rows
             , 'dev_cl_ord_id'::varchar                      as metric_name_01
             , d.dev_cl_ord_id::double precision             as metric_value_01
             , 'dev_order_id'::varchar                       as metric_name_02
             , d.dev_order_id::double precision              as metric_value_02
             , 'corr_order_id'::varchar                      as metric_name_03
             , d.corr_order_id::double precision             as metric_value_03
             , 'corr_systemordertypeid'::varchar             as metric_name_04
             , d.corr_systemordertypeid::double precision    as metric_value_04
             , 'corr_status'::varchar                        as metric_name_05
             , d.corr_status::double precision               as metric_value_05
             , 'corr_user_id'::varchar                       as metric_name_06
             , d.corr_user_id::double precision              as metric_value_06
             , 'corr_exchangeconnectionid'::varchar          as metric_name_07
             , d.corr_exchangeconnectionid::double precision as metric_value_07
             , 'sum_legcount'::varchar                       as metric_name_08
             , d.sum_legcount::double precision              as metric_value_08
             , 'sum_price'::varchar                          as metric_name_09
             , d.sum_price::double precision                 as metric_value_09
             , 'sum_quantity'::varchar                       as metric_name_10
             , d.sum_quantity::double precision              as metric_value_10
             , 'sum_filled'::varchar                         as metric_name_11
             , d.sum_filled::double precision                as metric_value_11
             , 'sum_stockfilled' ::varchar                   as metric_name_12
             , d.sum_stockfilled ::double precision          as metric_value_12
             , 'sum_optionfilled' ::varchar                  as metric_name_13
             , d.sum_optionfilled ::double precision         as metric_value_13
        FROM src AS d
        on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
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
                                                                          , metric_name_09     = excluded.metric_name_09
                                                                          , metric_value_09    = excluded.metric_value_09
                                                                          , metric_name_10     = excluded.metric_name_10
                                                                          , metric_value_10    = excluded.metric_value_10
                                                                          , metric_name_11     = excluded.metric_name_11
                                                                          , metric_value_11    = excluded.metric_value_11
                                                                          , metric_name_12     = excluded.metric_name_12
                                                                          , metric_value_12    = excluded.metric_value_12
                                                                          , metric_name_13     = excluded.metric_name_13
                                                                          , metric_value_13    = excluded.metric_value_13;
        return 1;
    end if;

    if in_table = 'TLEG' then
        WITH src AS
                 (SELECT 'BLAZE7_TLEGS'::TEXT                                            AS table_name,
                         in_date_id::NUMERIC                                             AS date_id,
                         count(1)                                                        AS cn,
                         stddev(l2.pg_ord_id)                                            AS dev_pg_ord_id,
                         corr(pg_ord_id::double precision, statuscode::double precision) AS corr_statuscode,
                         sum(l2.legcount)::bigint                                        AS sum_legcount,
                         sum(l2.price)::bigint                                           AS sum_price,
                         sum(l2.quantity)::bigint                                        AS sum_quantity,
                         sum(l2.filled)::bigint                                          AS sum_filled,
                         sum(l2.stockfilled)::bigint                                     AS sum_stockfilled,
                         sum(l2.optionfilled)::bigint                                    AS sum_optionfilled
                  FROM (SELECT tlegs.pg_order_id                                                                     AS pg_ord_id,
                               (('x'::TEXT || lpad(md5(COALESCE(tlegs.statuscode, '0')), 32, '0'))::BIT(64))::bigint AS statuscode,
                               tlegs.legcount::int,
                               round(tlegs.price::NUMERIC, 2)                                                        AS price, --
                               tlegs.quantity::int                                                                   AS quantity,
                               tlegs.filled::int                                                                     AS filled,
                               tlegs.stockfilled::int                                                                AS stockfilled,
                               tlegs.optionfilled::int                                                               AS optionfilled
                        FROM staging.so_edw_blaze7_tlegs_edw AS tlegs
                        --	WHERE COALESCE(tlegs.date_id, 0) = &p_date_id
--	WHERE COALESCE(tlegs.order_trade_date_id, 0) = &p_date_id
                        WHERE COALESCE(tlegs.order_trade_date_id, 0) between in_date_id and public.get_dateid(public.get_business_date(in_date_id::text::date, 1))
                          and upper(tlegs.pg_entity) = 'UAT'
                        ORDER BY trim(tlegs.cl_ord_id), tlegs.legrefid) l2)

        INSERT
        INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time,
                                                   metric_cnt_rows,
                                                   metric_name_01, metric_value_01, metric_name_02, metric_value_02,
                                                   metric_name_03, metric_value_03, metric_name_04, metric_value_04,
                                                   metric_name_05, metric_value_05,
                                                   metric_name_06, metric_value_06, metric_name_07, metric_value_07,
                                                   metric_name_08, metric_value_08)
        SELECT 'BLAZE7_EDW_SO'::text                 as source_name
             , d.table_name                          as table_name
             , d.date_id                             as date_id
             , clock_timestamp()                     as pg_db_updated_time
             , d.cn::double precision                as metric_cnt_rows
             , 'dev_pg_ord_id'::varchar              as metric_name_01
             , d.dev_pg_ord_id::double precision     as metric_value_01
             , 'corr_statuscode'::varchar            as metric_name_02
             , d.corr_statuscode::double precision   as metric_value_02
             , 'sum_legcount'::varchar               as metric_name_03
             , d.sum_legcount::double precision      as metric_value_03
             , 'sum_price'::varchar                  as metric_name_04
             , d.sum_price::double precision         as metric_value_04
             , 'sum_quantity'::varchar               as metric_name_05
             , d.sum_quantity::double precision      as metric_value_05
             , 'sum_filled'::varchar                 as metric_name_06
             , d.sum_filled::double precision        as metric_value_06
             , 'sum_stockfilled' ::varchar           as metric_name_07
             , d.sum_stockfilled ::double precision  as metric_value_07
             , 'sum_optionfilled' ::varchar          as metric_name_08
             , d.sum_optionfilled ::double precision as metric_value_08
        FROM src AS d
        on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
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
        return 1;
    end if;

    if in_table = 'TORDERMISC' then
        WITH src AS
                 (SELECT 'BLAZE7_TORDERMISC1'::TEXT AS table_name,
                         in_date_id::NUMERIC        AS date_id,
                         count(1)                   AS cn,
                         stddev(l2.pg_ord_id)       AS dev_pg_ord_id,
                         sum(l2.acctcomm)::NUMERIC  AS sum_acctcomm
                  FROM (SELECT tordermisc1.pg_order_id                 AS pg_ord_id,
                               round(tordermisc1.acctcomm::NUMERIC, 8) AS acctcomm
                        FROM staging.so_edw_blaze7_tordermisc1 AS tordermisc1
                        --	WHERE COALESCE(date_id, 0) = &p_date_id
--	WHERE COALESCE(order_trade_date_id, 0) = &p_date_id
                        WHERE COALESCE(order_trade_date_id, 0) between in_date_id and public.get_dateid(public.get_business_date(in_date_id::text::date, 1))
                          and upper(tordermisc1.pg_entity) = 'UAT'
                        ORDER BY pg_ord_id) l2)

        INSERT
        INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time,
                                                   metric_cnt_rows,
                                                   metric_name_01, metric_value_01, metric_name_02, metric_value_02)
        SELECT 'BLAZE7_EDW_SO'::text             as source_name
             , d.table_name                      as table_name
             , d.date_id                         as date_id
             , clock_timestamp()                 as pg_db_updated_time
             , d.cn::double precision            as metric_cnt_rows
             , 'dev_pg_ord_id'::varchar          as metric_name_01
             , d.dev_pg_ord_id::double precision as metric_value_01
             , 'sum_acctcomm'::varchar           as metric_name_02
             , d.sum_acctcomm::double precision  as metric_value_02
        FROM src AS d
        on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
                                                                          , metric_cnt_rows    = excluded.metric_cnt_rows
                                                                          , metric_name_01     = excluded.metric_name_01
                                                                          , metric_value_01    = excluded.metric_value_01
                                                                          , metric_name_02     = excluded.metric_name_02
                                                                          , metric_value_02    = excluded.metric_value_02;
        return 1;
    end if;

    if in_table = 'TPRICE' then
        WITH src AS
                 (SELECT 'BLAZE7_TPRICE'::TEXT                                                 AS table_name,
                         in_date_id::numeric                                                   AS date_id,
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

                        from staging.so_edw_blaze7_tprice as tp
                        where coalesce(date_id, 0) = in_date_id
                          and upper(tp.pg_entity) = 'UAT'
                        order by coalesce(tp.exec_id, '')) l2)
        INSERT
        INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time,
                                                   metric_cnt_rows,
                                                   metric_name_01, metric_value_01, metric_name_02, metric_value_02,
                                                   metric_name_03, metric_value_03, metric_name_04, metric_value_04,
                                                   metric_name_05, metric_value_05)
        SELECT 'BLAZE7_EDW_SO'::text                   as source_name
             , d.table_name                            as table_name
             , d.date_id                               as date_id
             , clock_timestamp()                       as pg_db_updated_time
             , d.cn::double precision                  as metric_cnt_rows
             , 'dev_pg_ord_id'::varchar                as metric_name_01
             , d.dev_pg_ord_id::double precision       as metric_value_01
             , 'corr_legnumber'::varchar               as metric_name_02
             , d.corr_legnumber::double precision      as metric_value_02
             , 'corr_status'::varchar                  as metric_name_03
             , d.corr_status::double precision         as metric_value_03
             , 'corr_exec_id'::varchar                 as metric_name_04
             , d.corr_exec_id::double precision        as metric_value_04
             , 'corr_dashsecurityid'::varchar          as metric_name_05
             , d.corr_dashsecurityid::double precision as metric_value_05
        FROM src AS d
        on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
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

        return 1;
    end if;

    if in_table = 'TREPORT' then
        WITH src AS
                 (SELECT 'BLAZE7_TREPORTS'::TEXT                                     AS table_name,
                         in_date_id::numeric                                         AS date_id,
                         count(1)                                                    AS cn,
                         stddev(l2.pg_ord_id)                                        AS dev_pg_ord_id,
                         corr(pg_ord_id::double precision, userid::double precision) AS corr_userid,
                         sum(l2.legnumber)::bigint                                   AS sum_legnumber,
                         sum(l2.lastprice)::numeric                                  AS sum_lastprice,
                         sum(l2.leavesqty)::bigint                                   AS sum_leavesqty,
                         sum(l2.aveprice)::numeric                                   AS sum_aveprice,
                         sum(l2.price)::numeric                                      AS sum_price,
                         stddev(l2.cl_ord_id)                                        AS dev_cl_ord_id
                  FROM (SELECT treports.pg_order_id                                                         AS pg_ord_id,--
                               treports.legnumber::int,
                               round(treports.lastprice::NUMERIC, 2)                                        AS lastprice,
                               treports.leavesqty::int                                                      AS leavesqty,
                               round(treports.aveprice::NUMERIC, 2)                                         AS aveprice,
                               round(treports.price::NUMERIC, 2)                                            AS price,
                               treports.userid::int::double precision                                       AS userid,   --!!
                               (('x'::TEXT || lpad(md5(trim(treports.exec_id)), 32, '0'))::BIT(64))::bigint AS cl_ord_id
                        FROM staging.so_edw_blaze7_treports_edw AS treports
                        WHERE COALESCE(date_id, 0) = in_date_id
                          and upper(treports.pg_entity) = 'UAT'
                        ORDER BY trim(treports.exec_id)) l2)

        INSERT
        INTO staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time,
                                                   metric_cnt_rows,
                                                   metric_name_01, metric_value_01, metric_name_02, metric_value_02,
                                                   metric_name_03, metric_value_03, metric_name_04, metric_value_04,
                                                   metric_name_05, metric_value_05,
                                                   metric_name_06, metric_value_06, metric_name_07, metric_value_07,
                                                   metric_name_08, metric_value_08)
        SELECT 'BLAZE7_EDW_SO'::text              as source_name
             , d.table_name                       as table_name
             , d.date_id                          as date_id
             , clock_timestamp()                  as pg_db_updated_time
             , d.cn::double precision             as metric_cnt_rows
             , 'dev_pg_ord_id'::varchar           as metric_name_01
             , d.dev_pg_ord_id::double precision  as metric_value_01
             , 'corr_userid'::varchar             as metric_name_02
             , d.corr_userid::double precision    as metric_value_02
             , 'sum_legnumber'::varchar           as metric_name_03
             , d.sum_legnumber::double precision  as metric_value_03
             , 'sum_lastprice'::varchar           as metric_name_04
             , d.sum_lastprice::double precision  as metric_value_04
             , 'sum_leavesqty'::varchar           as metric_name_05
             , d.sum_leavesqty::double precision  as metric_value_05
             , 'sum_aveprice'::varchar            as metric_name_06
             , d.sum_aveprice::double precision   as metric_value_06
             , 'sum_price' ::varchar              as metric_name_07
             , d.sum_price ::double precision     as metric_value_07
             , 'dev_cl_ord_id' ::varchar          as metric_name_08
             , d.dev_cl_ord_id ::double precision as metric_value_08

        FROM src AS d
        on conflict on constraint sync_test_calc_metrics_pkey do update set pg_db_updated_time = excluded.pg_db_updated_time
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

        return 1;
    end if;
end;
$$;

select * from staging.so_sync_test('TORDER', 20260807, 'PROD1');
select * from staging.so_sync_test('TORDERMISC', 20260807, 'PROD1');
select * from staging.so_sync_test('TLEG', 20260807, 'PROD1');
select * from staging.so_sync_test('TREPORT', 20260807, 'PROD1');
select * from staging.so_sync_test('TPRICE', 20260807, 'PROD1');

select table_name, date_id, metric_cnt_rows, metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05, metric_name_06, metric_value_06, metric_name_07, metric_value_07, metric_name_08, metric_value_08, metric_name_09, metric_value_09, metric_name_10, metric_value_10, metric_name_11, metric_value_11, metric_name_12, metric_value_12, metric_name_13, metric_value_13, metric_name_14, metric_value_14, metric_name_15, metric_value_15, metric_name_16, metric_value_16, metric_name_17, metric_value_17, metric_name_18, metric_value_18, metric_name_19, metric_value_19, metric_name_20, metric_value_20, metric_name_21, metric_value_21, metric_name_22, metric_value_22, metric_name_23, metric_value_23, metric_name_24, metric_value_24, metric_name_25, metric_value_25, metric_name_26, metric_value_26, metric_name_27, metric_value_27, metric_name_28, metric_value_28, metric_name_29, metric_value_29, metric_name_30, metric_value_30, metric_name_31, metric_value_31, metric_name_32, metric_value_32, metric_name_33, metric_value_33, metric_name_34, metric_value_34, metric_name_35, metric_value_35, metric_name_36, metric_value_36, metric_name_37, metric_value_37, metric_name_38, metric_value_38, metric_name_39, metric_value_39, metric_name_40, metric_value_40, metric_name_41, metric_value_41, metric_name_42, metric_value_42, metric_name_43, metric_value_43, metric_name_44, metric_value_44, metric_name_45, metric_value_45, metric_name_46, metric_value_46, metric_name_47, metric_value_47, metric_name_48, metric_value_48, metric_name_49, metric_value_49, metric_name_50, metric_value_50
from staging.sync_test_calculated_metrics
where source_name = 'BLAZE7_EDW_SO'
and date_id = 20260817
-- and table_name = 'BLAZE7_TREPORTS'
except
-- union all
select table_name, date_id, metric_cnt_rows, metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05, metric_name_06, metric_value_06, metric_name_07, metric_value_07, metric_name_08, metric_value_08, metric_name_09, metric_value_09, metric_name_10, metric_value_10, metric_name_11, metric_value_11, metric_name_12, metric_value_12, metric_name_13, metric_value_13, metric_name_14, metric_value_14, metric_name_15, metric_value_15, metric_name_16, metric_value_16, metric_name_17, metric_value_17, metric_name_18, metric_value_18, metric_name_19, metric_value_19, metric_name_20, metric_value_20, metric_name_21, metric_value_21, metric_name_22, metric_value_22, metric_name_23, metric_value_23, metric_name_24, metric_value_24, metric_name_25, metric_value_25, metric_name_26, metric_value_26, metric_name_27, metric_value_27, metric_name_28, metric_value_28, metric_name_29, metric_value_29, metric_name_30, metric_value_30, metric_name_31, metric_value_31, metric_name_32, metric_value_32, metric_name_33, metric_value_33, metric_name_34, metric_value_34, metric_name_35, metric_value_35, metric_name_36, metric_value_36, metric_name_37, metric_value_37, metric_name_38, metric_value_38, metric_name_39, metric_value_39, metric_name_40, metric_value_40, metric_name_41, metric_value_41, metric_name_42, metric_value_42, metric_name_43, metric_value_43, metric_name_44, metric_value_44, metric_name_45, metric_value_45, metric_name_46, metric_value_46, metric_name_47, metric_value_47, metric_name_48, metric_value_48, metric_name_49, metric_value_49, metric_name_50, metric_value_50 from staging.sync_test_calculated_metrics
where source_name = 'BLAZE7_EDW_UAT'
and date_id = 20260811
-- and table_name = 'BLAZE7_TREPORTS'



SELECT tordermisc1.pg_order_id                 AS pg_ord_id,
                               round(tordermisc1.acctcomm::NUMERIC, 8) AS acctcomm
                        FROM staging.so_edw_blaze7_tordermisc1 AS tordermisc1
                        --	WHERE COALESCE(date_id, 0) = &p_date_id
--	WHERE COALESCE(order_trade_date_id, 0) = &p_date_id
                        WHERE true
    and COALESCE(order_trade_date_id, 0) between :in_date_id and public.get_dateid(public.get_business_date(:in_date_id::text::date, 1))
                          and upper(tordermisc1.pg_entity) = :in_env
                        ORDER BY pg_ord_id;


select *
from trash.so_report_rps_s3_sg(in_start_date_id := 20260501, in_end_date_id := 20260501,
                               in_is_multi_leg := 'Y', in_exclude_blaze := true, in_actual_exchange := true,
                               in_trading_firm_ids := '{socgen01,LPTF286,socgenpsc}');
select *
from trash.so_report_rps_s3_sg(in_start_date_id := 20260501, in_end_date_id := 20260501,
                               in_is_multi_leg := 'N', in_exclude_blaze := true, in_actual_exchange := true,
                               in_trading_firm_ids := '{socgen01,LPTF286,socgenpsc}');



1321583.68932526 vs 1321596.85


{
    "orderid": "OrderID",
    "systemid": "SystemID",
    "client": "Client",
    "trader": "Trader",
    "isctboverridden": "IsCTBOverridden",
    "stockquantity": "StockQuantity",
    "stockprice": "StockPrice",
    "acctcomm": "AcctComm",
    "issplitprice": "IsSplitPrice",
    "post": "Post",
    "station": "Station",
    "isspxcombo": "IsSPXCombo",
    "exttts": "ExtTTS",
    "nocoa": "NoCOA",
    "rejectorderid": "RejectOrderID",
    "ftid": "FTID",
    "execinst": "ExecInst",
    "ultransaction64": "ulTransaction64",
    "isautoqctchild": "IsAutoQCTChild",
    "autoqctorderid": "AutoQCTOrderID",
    "crossingtypeid": "CrossingTypeID",
    "stoplimit": "StopLimit",
    "catid": "CATID",
    "dashaliasid": "dashaliasid",
    "minquantity": "MinQuantity",
    "mindisplayqty": "MinDisplayQty",
    "maxdisplayqty": "MaxDisplayQty",
    "obouser": "OBOUser",
    "stockfloorbroker": "StockFloorBroker",
    "fdid": "FDID",
    "senderimid": "SenderIMID",
    "affiliateflag": "AffiliateFlag",
    "accountholdertype": "AccountHolderType",
    "brokerdealer": "BrokerDealer",
    "receivetime": "ReceiveTime",
    "resendparentid": "ResendParentID",
    "representative": "Representative",
    "cxlclordid": "CXLClOrdID",
    "goodtilldate": "GoodTillDate",
    "actionid": "ActionID",
    "sales_traders": "sales_traders",
    "fixclordid": "fixclordid",
    "optionrefprice": "optionrefprice",
    "stockrefprice": "stockrefprice",
    "workingdelta": "workingdelta",
    "intparentorderid": "intparentorderid",
    "catparentid": "CATParentID",
    "ordersource": "OrderSource",
    "oboorderrefid": "OBOOrderRefId",
    "ownercompanyid": "OwnerCompanyID",
    "systemcrossid": "SystemCrossID",
    "transaction64crossorderid": "Transaction64CrossOrderID",
    "representativeorderid": "RepresentativeOrderID",
    "catupdate": "CATUpdate",
    "hasrepresentedorder": "HasRepresentedOrder",
    "hasrepresentedorder": "CBOESessionEligibility",
    "impliedvolatility": "ImpliedVolatility",
    "cabinet": "Cabinet",
    "transaction64parentcrossorderid": "Transaction64ParentCrossOrderID",
    "calltime": "CallTime",
    "electronicorderid": "ElectronicOrderId",
    "electronicordertime": "ElectronicOrderTime",
    "clientinfo": "ClientInfo",
    "ordereventtime": "OrderEventTime",
    "_order_id": "pg_order_id",
    "_chain_id": "pg_chain_id",
    "_db_create_time": "pg_db_create_time",
    "boxqooannouncedtime": "BoxQOOAnnouncedTime",
    "ordernotes": "OrderNotes",
    "cboeequitybroker": "CboeEquityBroker",
    "order_trade_date_id": "order_trade_date_id",
    "autorouteruleid": "AutoRouteRuleId",
    "autorouterulename": "AutoRouteRuleName",
    "isautoaccepted": "IsAutoAccepted",
    "isautorouted": "IsAutoRouted",
    "numberoflinkedorders": "NumberOfLinkedOrders",
    "istiedtocombo": "IsTiedToCombo",
    "ismerged": "IsMerged",
    "mergedorderid": "MergedOrderID",
    "socgensubaccount": "SocGenSubAccount",
    "sgchainid": "SGChainID",
    "sglinkedid": "SGLinkedID",
    "principaleligible": "PrincipalEligible",
    "iscboetiedhedge": "IsCboeTiedHedge",
    "flexpricetype": "FlexPriceType",
    "userroutingtype": "UserRoutingType",
    "haslinkedorders": "HasLinkedOrders"
  }
