create temp table tmp_acc
as select *
    from genesis2.account ac
    where true
      and ac.is_deleted <> 'Y'
      and ac.opt_report_to_mpid = 'MLCB'
      and ac.trading_firm_id <> 'cantor';

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