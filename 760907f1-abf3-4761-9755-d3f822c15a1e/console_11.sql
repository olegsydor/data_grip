drop table if exists training.check_big_operation;
create table training.check_big_operation
(
    big_operation_id int8      not null
        constraint big_operation_id_pk primary key,
    operation_number int4      not null,
    operation_text   text,
    db_create_time   timestamp not null default clock_timestamp(),
    db_update_time   timestamp
);
select * from training.check_big_operation
select * from training.f_big_operation_processing()

create or replace function training.f_big_operation_processing()
    returns int4
    language plpgsql
as
$fn$
declare
    l_row_ins int4;
    l_row_del int4 := 0;
begin
    -- insert/update part

    create temp table t_ins on commit drop as
    select distinct round(random() * 150000000) as id,
                    round(random() * 10000)     as num,
                    md5(random()::text)         as txt
    from generate_series(1, 100000) s(i);

    insert into training.check_big_operation (big_operation_id, operation_number, operation_text)
    select distinct on (id) id,
                            num,
                            txt
    from t_ins
    on conflict (big_operation_id) do update
        set operation_number = excluded.operation_number,
            operation_text   = excluded.operation_text,
            db_update_time   = clock_timestamp();

    get diagnostics l_row_ins = row_count;

    -- delete part
    delete
    from training.check_big_operation
    where big_operation_id in (select round(random() * 150000000) as id
                               from generate_series(1, 10000) s(i));

    get diagnostics l_row_del = row_count;

    return l_row_ins - l_row_del;
end;
$fn$;

select count(*) from training.check_big_operation;

select * from training.check_big_operation
where db_update_time is not null;
vacuum full verbose analyze training.check_big_operation;
analyze training.check_big_operation;

create view staging.v_tables_info as
SELECT current_database()                                                          AS current_database,
       s3.schemaname,
       s3.tblname,
       s3.bs * s3.tblpages::numeric                                                AS real_size,
       (s3.tblpages::double precision - s3.est_tblpages) * s3.bs::double precision AS extra_size,
       CASE
           WHEN s3.tblpages > 0 AND (s3.tblpages::double precision - s3.est_tblpages) > 0::double precision THEN
               100::double precision * (s3.tblpages::double precision - s3.est_tblpages) / s3.tblpages::double precision
           ELSE 0::double precision
           END                                                                     AS extra_pct,
       s3.fillfactor,
       CASE
           WHEN (s3.tblpages::double precision - s3.est_tblpages_ff) > 0::double precision THEN
               (s3.tblpages::double precision - s3.est_tblpages_ff) * s3.bs::double precision
           ELSE 0::double precision
           END                                                                     AS bloat_size,
       CASE
           WHEN s3.tblpages > 0 AND (s3.tblpages::double precision - s3.est_tblpages_ff) > 0::double precision THEN
               100::double precision * (s3.tblpages::double precision - s3.est_tblpages_ff) /
               s3.tblpages::double precision
           ELSE 0::double precision
           END                                                                     AS bloat_pct,
       s3.is_na,
       s3.tblpages
FROM (SELECT ceil(s2.reltuples / ((s2.bs - s2.page_hdr::numeric)::double precision / s2.tpl_size)) +
             ceil(s2.toasttuples / 4::double precision) AS est_tblpages,
             ceil(s2.reltuples / (((s2.bs - s2.page_hdr::numeric) * s2.fillfactor::numeric)::double precision /
                                  (s2.tpl_size * 100::double precision))) +
             ceil(s2.toasttuples / 4::double precision) AS est_tblpages_ff,
             s2.tblpages,
             s2.fillfactor,
             s2.bs,
             s2.tblid,
             s2.schemaname,
             s2.tblname,
             s2.heappages,
             s2.toastpages,
             s2.is_na
      FROM (SELECT (4 + s.tpl_hdr_size)::double precision + s.tpl_data_size + (2 * s.ma)::double precision -
                   CASE
                       WHEN (s.tpl_hdr_size % s.ma::bigint) = 0 THEN s.ma::bigint
                       ELSE s.tpl_hdr_size % s.ma::bigint
                       END::double precision -
                   CASE
                       WHEN (ceil(s.tpl_data_size)::integer % s.ma) = 0 THEN s.ma
                       ELSE ceil(s.tpl_data_size)::integer % s.ma
                       END::double precision  AS tpl_size,
                   s.bs - s.page_hdr::numeric AS size_per_block,
                   s.heappages + s.toastpages AS tblpages,
                   s.heappages,
                   s.toastpages,
                   s.reltuples,
                   s.toasttuples,
                   s.bs,
                   s.page_hdr,
                   s.tblid,
                   s.schemaname,
                   s.tblname,
                   s.fillfactor,
                   s.is_na
            FROM (SELECT tbl.oid                                                                                AS tblid,
                         ns.nspname                                                                             AS schemaname,
                         tbl.relname                                                                            AS tblname,
                         tbl.reltuples,
                         tbl.relpages                                                                           AS heappages,
                         COALESCE(toast.relpages, 0)                                                            AS toastpages,
                         COALESCE(toast.reltuples, 0::real)                                                     AS toasttuples,
                         COALESCE("substring"(array_to_string(tbl.reloptions, ' '::text),
                                              'fillfactor=([0-9]+)'::text)::smallint::integer,
                                  100)                                                                          AS fillfactor,
                         current_setting('block_size'::text)::numeric                                           AS bs,
                         CASE
                             WHEN version() ~ 'mingw32'::text OR version() ~ '64-bit|x86_64|ppc64|ia64|amd64'::text
                                 THEN 8
                             ELSE 4
                             END                                                                                AS ma,
                         24                                                                                     AS page_hdr,
                         23 +
                         CASE
                             WHEN max(COALESCE(s_1.null_frac, 0::real)) > 0::double precision
                                 THEN (7 + count(s_1.attname)) / 8
                             ELSE 0::bigint
                             END +
                         CASE
                             WHEN bool_or(att.attname = 'oid'::name AND att.attnum < 0) THEN 4
                             ELSE 0
                             END                                                                                AS tpl_hdr_size,
                         sum((1::double precision - COALESCE(s_1.null_frac, 0::real)) *
                             COALESCE(s_1.avg_width, 0)::double precision)                                      AS tpl_data_size,
                         bool_or(att.atttypid = 'name'::regtype::oid) OR sum(
                                                                                 CASE
                                                                                     WHEN att.attnum > 0 THEN 1
                                                                                     ELSE 0
                                                                                     END) <> count(s_1.attname) AS is_na
                  FROM pg_attribute att
                           JOIN pg_class tbl ON att.attrelid = tbl.oid
                           JOIN pg_namespace ns ON ns.oid = tbl.relnamespace
                           LEFT JOIN pg_stats s_1 ON s_1.schemaname = ns.nspname AND s_1.tablename = tbl.relname AND
                                                     s_1.inherited = false AND s_1.attname = att.attname
                           LEFT JOIN pg_class toast ON tbl.reltoastrelid = toast.oid
                  WHERE NOT att.attisdropped
                    AND (tbl.relkind = ANY (ARRAY ['r'::"char", 'm'::"char"]))
                  GROUP BY tbl.oid, ns.nspname, tbl.relname, tbl.reltuples, tbl.relpages, (COALESCE(toast.relpages, 0)),
                           (COALESCE(toast.reltuples, 0::real)),
                           (COALESCE("substring"(array_to_string(tbl.reloptions, ' '::text),
                                                 'fillfactor=([0-9]+)'::text)::smallint::integer, 100)),
                           (current_setting('block_size'::text)::numeric),
                           (
                               CASE
                                   WHEN version() ~ 'mingw32'::text OR version() ~ '64-bit|x86_64|ppc64|ia64|amd64'::text
                                       THEN 8
                                   ELSE 4
                                   END)
                  ORDER BY ns.nspname, tbl.relname) s) s2) s3
WHERE NOT s3.is_na
  AND s3.tblpages > 100
ORDER BY ((s3.tblpages::double precision - s3.est_tblpages) * s3.bs::double precision) DESC,
         (
             CASE
                 WHEN s3.tblpages > 0 AND (s3.tblpages::double precision - s3.est_tblpages_ff) > 0::double precision
                     THEN 100::double precision * (s3.tblpages::double precision - s3.est_tblpages_ff) /
                          s3.tblpages::double precision
                 ELSE 0::double precision
                 END) DESC,
         (
             CASE
                 WHEN (s3.tblpages::double precision - s3.est_tblpages_ff) > 0::double precision THEN
                     (s3.tblpages::double precision - s3.est_tblpages_ff) * s3.bs::double precision
                 ELSE 0::double precision
                 END) DESC;


WITH table_opts AS (SELECT c_1.oid,
                           c_1.relname,
                           c_1.relfrozenxid,
                           c_1.relminmxid,
                           n.nspname,
                           array_to_string(c_1.reloptions, ''::text) AS relopts
                    FROM pg_class c_1
                             JOIN pg_namespace n ON c_1.relnamespace = n.oid
                    WHERE (c_1.relkind = ANY (ARRAY ['r'::"char", 't'::"char"]))
                      AND (n.nspname <> ALL (ARRAY ['pg_catalog'::name, 'information_schema'::name]))
                      AND n.nspname !~ '^pg_temp'::text),
     vacuum_settings AS (SELECT table_opts.oid,
                                table_opts.relname,
                                table_opts.nspname,
                                table_opts.relfrozenxid,
                                table_opts.relminmxid,
                                CASE
                                    WHEN table_opts.relopts ~~ '%autovacuum_vacuum_threshold%'::text
                                        THEN regexp_replace(table_opts.relopts,
                                                            '.*autovacuum_vacuum_threshold=([0-9.]+).*'::text,
                                                            '\1'::text)::integer
                                    ELSE current_setting('autovacuum_vacuum_threshold'::text)::integer
                                    END AS autovacuum_vacuum_threshold,
                                CASE
                                    WHEN table_opts.relopts ~~ '%autovacuum_vacuum_scale_factor%'::text
                                        THEN regexp_replace(table_opts.relopts,
                                                            '.*autovacuum_vacuum_scale_factor=([0-9.]+).*'::text,
                                                            '\1'::text)::real
                                    ELSE current_setting('autovacuum_vacuum_scale_factor'::text)::real
                                    END AS autovacuum_vacuum_scale_factor,
                                CASE
                                    WHEN table_opts.relopts ~~ '%autovacuum_analyze_threshold%'::text
                                        THEN regexp_replace(table_opts.relopts,
                                                            '.*autovacuum_analyze_threshold=([0-9.]+).*'::text,
                                                            '\1'::text)::integer
                                    ELSE current_setting('autovacuum_analyze_threshold'::text)::integer
                                    END AS autovacuum_analyze_threshold,
                                CASE
                                    WHEN table_opts.relopts ~~ '%autovacuum_analyze_scale_factor%'::text
                                        THEN regexp_replace(table_opts.relopts,
                                                            '.*autovacuum_analyze_scale_factor=([0-9.]+).*'::text,
                                                            '\1'::text)::real
                                    ELSE current_setting('autovacuum_analyze_scale_factor'::text)::real
                                    END AS autovacuum_analyze_scale_factor,
                                CASE
                                    WHEN table_opts.relopts ~~ '%autovacuum_freeze_max_age%'::text THEN LEAST(
                                            regexp_replace(table_opts.relopts,
                                                           '.*autovacuum_freeze_max_age=([0-9.]+).*'::text,
                                                           '\1'::text)::bigint,
                                            current_setting('autovacuum_freeze_max_age'::text)::bigint)
                                    ELSE current_setting('autovacuum_freeze_max_age'::text)::bigint
                                    END AS autovacuum_freeze_max_age,
                                CASE
                                    WHEN table_opts.relopts ~~ '%autovacuum_multixact_freeze_max_age%'::text THEN LEAST(
                                            regexp_replace(table_opts.relopts,
                                                           '.*autovacuum_multixact_freeze_max_age=([0-9.]+).*'::text,
                                                           '\1'::text)::bigint,
                                            current_setting('autovacuum_multixact_freeze_max_age'::text)::bigint)
                                    ELSE current_setting('autovacuum_multixact_freeze_max_age'::text)::bigint
                                    END AS autovacuum_multixact_freeze_max_age
                         FROM table_opts)
SELECT (s.schemaname::text || '.'::text) || s.relname::text AS "table",
       CASE
           WHEN (v.autovacuum_vacuum_threshold::double precision +
                 v.autovacuum_vacuum_scale_factor::numeric::double precision * c.reltuples) <
                s.n_dead_tup::double precision THEN true
           ELSE false
           END                                              AS need_vacuum,
       CASE
           WHEN (v.autovacuum_analyze_threshold::double precision +
                 v.autovacuum_analyze_scale_factor::numeric::double precision * c.reltuples) <
                s.n_mod_since_analyze::double precision THEN true
           ELSE false
           END                                              AS need_analyze,
       CASE
           WHEN age(v.relfrozenxid)::bigint > v.autovacuum_freeze_max_age OR
                mxid_age(v.relminmxid)::bigint > v.autovacuum_multixact_freeze_max_age THEN true
           ELSE false
           END                                              AS need_wraparound,
       now() - GREATEST(s.last_autovacuum, s.last_vacuum)   AS vacuum_delay,
       s.last_autovacuum,
       s.last_vacuum,
       s.autovacuum_count,
       s.vacuum_count
FROM pg_stat_user_tables s
         JOIN pg_class c ON s.relid = c.oid
         JOIN vacuum_settings v ON c.oid = v.oid
WHERE (v.autovacuum_vacuum_threshold::double precision +
       v.autovacuum_vacuum_scale_factor::numeric::double precision * c.reltuples) < s.n_dead_tup::double precision
   OR (v.autovacuum_analyze_threshold::double precision +
       v.autovacuum_analyze_scale_factor::numeric::double precision * c.reltuples) <
      s.n_mod_since_analyze::double precision
   OR age(v.relfrozenxid)::bigint > v.autovacuum_freeze_max_age
   OR mxid_age(v.relminmxid)::bigint > v.autovacuum_multixact_freeze_max_age;

select *--relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
from pg_stat_user_tables
order by n_dead_tup desc;

SELECT *
FROM pg_stat_activity;

CREATE EXTENSION pg_stat_statements;

SELECT *
FROM pg_stat_statements;


select pg_size_pretty(real_size), * from staging.v_tables_info;


select :json::jsonb #>> '{BBOSnapshot,SPHR,BidPrice}'