insert into trash.alloc_instr_parent_trade_ids (trade_record_id, alloc_instr_id)
select unnest(staging.all_orig_trade_record_id_today(aitr.trade_record_id, aitr.date_id)), aitr.alloc_instr_id
from genesis2.alloc_instr2trade_record aitr
         join genesis2.trade_record tr on tr.trade_record_id = aitr.trade_record_id
    and aitr.date_id = tr.date_id
where true
  and alloc_instr_id in (-51903, -51905, -51907, -51908, -51904)
  and aitr.date_id = :in_date_id
  and tr.orig_trade_record_id is not null;

select * from trash.get_all_parent_trade_record_ids_by_alloc_instr_id(-51911, 20241204);
select array_agg(trade_record_id) from trash.alloc_instr_parent_trade_ids

create function trash.so_allocation_report()
SELECT ftr.last_qty,
       alin.alloc_instr_id,
       alin.side,
       alin.avg_px,
       alin.date_id,
       alin.open_close,
       ae.alloc_qty,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                         AS ftr_cmta,
       ca.cmta                          AS ca_cmta,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       ae.occ_actionable_id             as occ_actionable_id,
       to_char(now(), 'YYYYMMDDHH24MI') as dataset,
       case
           when trash.get_all_parent_trade_record_ids_by_alloc_instr_id(alin.alloc_instr_id, alin.date_id) && :in_arr
               then 'skip 0'
           else 'report' end            as to_report
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select tr.cmta,
                                    tr.opt_customer_firm,
                                    tr.last_qty
                             --                                     staging.last_orig_trade_record_id_today(tr.trade_record_id,
--                                                                             tr.date_id) as first_orig_trade_record_id,
--                                     tr.trade_record_id,
--                                     tr.orig_trade_record_id
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id
                                                     and aitr.date_id = tr.date_id
                                                     and tr.is_busted = 'N'
                                                     and case
                                                             when :in_exec_broker is null then true
                                                             else tr.exec_broker = :in_exec_broker end
                                                     and tr.exec_broker is not null
                             where aitr.alloc_instr_id = alin.alloc_instr_id
                               and aitr.date_id = alin.date_id
                             limit 1
    ) ftr on true
    --          join lateral (select last_qty
--                        from genesis2.trade_record tr
--                        where tr.trade_record_id = ftr.first_orig_trade_record_id
--                        limit 1) qty on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                  AND ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
WHERE alin.date_id between :in_start_date_id and :in_end_date_id
  and not exists (select null
                  from trash.allocation_report ar
                  where ar.alloc_instr_id = ae.alloc_instr_id
                    and ar.side = alin.side
                    and ar.date_id = alin.date_id);
