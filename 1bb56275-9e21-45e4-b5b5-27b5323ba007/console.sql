create temp table tmp_acc
as select *
    from genesis2.account ac
    where true
      and ac.is_deleted <> 'Y'
      and ac.opt_report_to_mpid = 'MLCB'
      and ac.trading_firm_id <> 'cantor';



drop table if exists t_trade_record_to_report;
create temp table t_trade_record_to_report as
SELECT ftr.date_id AS date_id,
       ftr.trade_record_id,
       orig.*
FROM genesis2.trade_record ftr
         join genesis2.instrument gi on gi.instrument_id = ftr.instrument_id
         JOIN genesis2.account acc ON (acc.account_id = ftr.account_id)
         LEFT JOIN LATERAL (
    SELECT staging.all_orig_trade_record_id_today(
                   ftr.trade_record_id,
                   ftr.date_id
           ) AS orig_ids
    WHERE ftr.orig_trade_record_id IS NOT NULL
    OFFSET 0
    ) orig ON true
WHERE ftr.date_id between :in_start_date_id and :in_end_date_id
  and gi.instrument_type_id = 'O'
  and ftr.orig_trade_record_id is not null
  and ftr.exec_broker = '733';

select * from t_trade_record_to_report
order by array_length(orig_ids, 1) desc;


        drop table if exists t_trade_record_reported;
        create temp table t_trade_record_reported as
        select tr.trade_record_id, tr.date_id, aitr.alloc_instr_id
        from genesis2.trade_record tr
                 join genesis2.alloc_instr2trade_record aitr
                      on tr.trade_record_id = aitr.trade_record_id and aitr.date_id = tr.date_id
        where aitr.alloc_instr_id = any (:l_alloc_instr_id_reported);
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD trade_records calculated', l_row_cnt, 'O')
        into l_step_id;

        drop table if exists t_trade_record_to_exclude;
        create temp table t_trade_record_to_exclude as
        select aitr.trade_record_id, aitr.date_id, aitr.alloc_instr_id
        from genesis2.alloc_instr2trade_record aitr
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = aitr.alloc_instr_id and ai.date_id = aitr.date_id
                 join genesis2.trade_record tr
                      on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
        where aitr.date_id between :in_start_date_id and :in_end_date_id
          and ai.is_deleted = 'N'
          and tr.exec_broker = :in_exec_broker;

        create index on t_trade_record_to_exclude (trade_record_id);


        drop table if exists t_trade_record_to_report;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
        create temp table t_trade_record_to_report as
        SELECT ftr.date_id           AS date_id,
               ftr.trade_record_id,
               :l_load_id             as dataset,
               CASE
                   WHEN acc.opt_is_fix_clfirm_processed = 'Y' THEN ftr.cmta
                   ELSE NULL END     AS cmta,
               ftr.open_close,
               ftr.order_id          AS order_id,
               ftr.instrument_id,
               ftr.account_id,
               ftr.side,
               ftr.last_qty          AS last_qty,
               ftr.last_px           AS last_px,
               ftr.opt_customer_firm as opt_customer_firm,
               0                     AS is_cleared,
               acc.opt_is_fix_clfirm_processed,
               acc.opt_customer_or_firm,
               acc.opt_nickel_commission,
               acc.opt_penny_commission,
               acc.opt_is_fix_custfirm_processed,
               case
                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_reported trr
                                                                     where trr.trade_record_id = ftr.trade_record_id)
                       then 'U'
                   when ftr.orig_trade_record_id is null then 'R'
                   when exists (select null
                                from t_trade_record_reported rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'U'
                   else 'R' end      as to_report,
               case
                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_to_exclude tre
                                                                     where tre.trade_record_id = ftr.trade_record_id)
                       then 'D'
                   when ftr.orig_trade_record_id is null then null
                   when exists (select null
                                from t_trade_record_to_exclude rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'D' end  as to_del
        FROM genesis2.trade_record ftr
                 join genesis2.instrument gi on gi.instrument_id = ftr.instrument_id
                 JOIN tmp_acc acc ON (acc.account_id = ftr.account_id)
                 left join t_trade_record_to_exclude tex
                           on tex.trade_record_id = ftr.trade_record_id and tex.date_id = ftr.date_id
        WHERE ftr.date_id between :in_start_date_id and :in_end_date_id
          and ftr.is_busted = 'N'
--           and ftr.is_billed is distinct from 'R'
--          AND ftr.order_id > 0
          and gi.instrument_type_id = 'O'
          and ftr.exec_broker = :in_exec_broker
          and tex.trade_record_id is null;


        drop table if exists t_trade_record_to_report_new;
CREATE TEMP TABLE t_trade_record_to_report_new AS
SELECT
    ftr.date_id,
    ftr.trade_record_id,
    :l_load_id AS dataset,
    CASE
        WHEN acc.opt_is_fix_clfirm_processed = 'Y' THEN ftr.cmta
        ELSE NULL
    END AS cmta,
    ftr.open_close,
    ftr.order_id,
    ftr.instrument_id,
    ftr.account_id,
    ftr.side,
    ftr.last_qty,
    ftr.last_px,
    ftr.opt_customer_firm,
    0 AS is_cleared,
    acc.opt_is_fix_clfirm_processed,
    acc.opt_customer_or_firm,
    acc.opt_nickel_commission,
    acc.opt_penny_commission,
    acc.opt_is_fix_custfirm_processed,
    CASE
        WHEN ftr.orig_trade_record_id IS NULL
             AND EXISTS (
                 SELECT 1
                 FROM t_trade_record_reported trr
                 WHERE trr.trade_record_id = ftr.trade_record_id
             )
            THEN 'U'
        WHEN ftr.orig_trade_record_id IS NULL
            THEN 'R'
        WHEN EXISTS (
            SELECT 1
            FROM t_trade_record_reported rp
            WHERE rp.trade_record_id = ANY(orig.orig_ids)
        )
            THEN 'U'
        ELSE 'R'
    END AS to_report,
    CASE
        WHEN ftr.orig_trade_record_id IS NULL
             AND EXISTS (
                 SELECT 1
                 FROM t_trade_record_to_exclude tre
                 WHERE tre.trade_record_id = ftr.trade_record_id
             )
            THEN 'D'
        WHEN ftr.orig_trade_record_id IS NULL
            THEN NULL
        WHEN EXISTS (
            SELECT 1
            FROM t_trade_record_to_exclude rp
            WHERE rp.trade_record_id = ANY(orig.orig_ids)
        )
            THEN 'D'
    END AS to_del
FROM genesis2.trade_record ftr
    join tmp_acc acc on acc.account_id = ftr.account_id
JOIN genesis2.instrument gi
    ON gi.instrument_id = ftr.instrument_id
LEFT JOIN t_trade_record_to_exclude tex
    ON tex.trade_record_id = ftr.trade_record_id
   AND tex.date_id = ftr.date_id
LEFT JOIN LATERAL (
    SELECT staging.all_orig_trade_record_id_today(
        ftr.trade_record_id,
        ftr.date_id
    ) AS orig_ids
    WHERE ftr.orig_trade_record_id IS NOT NULL
    OFFSET 0
) orig ON true
WHERE ftr.date_id BETWEEN :in_start_date_id AND :in_end_date_id
  AND ftr.is_busted = 'N'
--   AND ftr.is_billed IS DISTINCT FROM 'R'
  AND gi.instrument_type_id = 'O'
  AND ftr.exec_broker = :in_exec_broker
  AND tex.trade_record_id IS NULL;


select * from t_trade_record_to_report
except
select * from t_trade_record_to_report_new