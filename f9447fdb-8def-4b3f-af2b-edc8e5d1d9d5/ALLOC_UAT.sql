SELECT alin.alloc_instr_id,
    ftr.trade_record_id,
       alin.side,
       ae.alloc_qty,
       alin.avg_px,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                           AS ftr_cmta,
       ca.cmta                            AS ca_cmta,
       alin.date_id,
       os.min_tick_increment,
       acc.opt_penny_commission,
       acc.opt_nickel_commission,
       os.root_symbol,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       oc.strike_price,
       alin.open_close,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
-- select alin.instrument_id, *
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select tr.trade_record_id,
                                    tr.cmta,
                                    tr.opt_customer_firm --, coalesce(tr.street_account_name,'') street_account_name
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id and
                                                    aitr.date_id = tr.date_id and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
                             where aitr.alloc_instr_id = alin.alloc_instr_id
                               and aitr.date_id = alin.date_id
                             limit 1) ftr on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                  ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
WHERE alin.date_id between :in_start_date_id and :in_end_date_id;



select tr.trade_record_id,
       tr.cmta,
       tr.opt_customer_firm --, coalesce(tr.street_account_name,'') street_account_name
from genesis2.alloc_instr2trade_record aitr
         inner join genesis2.trade_record tr
                    on aitr.trade_record_id = tr.trade_record_id and
                       aitr.date_id = tr.date_id and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
where aitr.alloc_instr_id = -51641
  and aitr.date_id = :in_end_date_id

select trade_record_id , orig_trade_record_id , is_busted ,
trade_record_reason , secondary_order_id , secondary_exch_exec_id , last_qty , last_px , * from genesis2.trade_record tr
where tr.date_id = 20241129
and tr.trade_record_id in (
2346592823
,2346592824
,2346592826
)
or tr.orig_trade_record_id in (
2346592823
,2346592824
,2346592826
);

select * from genesis2.option_contract
where instrument_id = 180072313;


INSERT INTO genesis2.option_contract
(instrument_id, option_series_id, maturity_year, maturity_month, maturity_day, put_call, strike_price, opra_symbol, create_time, is_deleted, delete_time)
VALUES(180072313, 70, 2025, 3, 21, '1', 160.0000, 'AAPL  250321P00160000', '2024-01-31 21:18:35.898', 'N', NULL);


select trade_record_id,
       orig_trade_record_id,
       is_busted,
       trade_record_reason,
       secondary_order_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       *
from genesis2.trade_record tr
where tr.date_id = 20241129
  and tr.secondary_exch_exec_id = 'S09GVAB00000001'
  and tr.secondary_order_id = 'BKAA0009-20241129'
order by trade_record_id asc;


select trade_record_id,
       orig_trade_record_id,
       is_busted,
       trade_record_reason,
       secondary_order_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       *
from genesis2.trade_record tr
where tr.date_id = 20241129
  and tr.secondary_exch_exec_id = 'S09GVAB00000001'
  and tr.secondary_order_id = 'BKAA0009-20241129'
order by tr.trade_record_id asc;


SELECT alin.alloc_instr_id,
       ftr.trade_record_ids,
       alin.side,
       ae.alloc_qty,
       alin.avg_px,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                           AS ftr_cmta,
       ca.cmta                            AS ca_cmta,
       alin.date_id,
       os.min_tick_increment,
       acc.opt_penny_commission,
       acc.opt_nickel_commission,
       os.root_symbol,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       oc.strike_price,
       alin.open_close,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
-- select alin.instrument_id, *
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select
                                 aitr.alloc_instr_id, aitr.date_id,
                                 array_agg(tr.trade_record_id) as trade_record_ids,
                                    min(tr.cmta) as cmta,
                                    min(tr.opt_customer_firm) as opt_customer_firm--, coalesce(tr.street_account_name,'') street_account_name
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id and
                                                    aitr.date_id = tr.date_id
--                                                         and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
                             where true
                                 and aitr.alloc_instr_id = alin.alloc_instr_id
                               and aitr.date_id = alin.date_id
--                               and aitr.trade_record_id in (2346592826, 2346592949,2346592950,2346593040,2346593041,2346593042,2346593043,2346593044)
                             group by aitr.alloc_instr_id, aitr.date_id
                             limit 1) ftr on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                  ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
WHERE alin.date_id between :in_start_date_id and :in_end_date_id;



select aitr.trade_record_id, *
from genesis2.allocation_instruction_entry ae
         join genesis2.allocation_instruction alin on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
         join genesis2.alloc_instr2trade_record aitr on aitr.alloc_instr_id = alin.alloc_instr_id
         join genesis2.trade_record tr on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
         join genesis2.clearing_account ca
              on (ca.clearing_account_id = ae.clearing_account_id
                  and ca.clearing_account_type = '1' and ca.market_type = 'O')
         join genesis2.account acc
              on (acc.account_id = ca.account_id and acc.is_deleted <> 'Y' and acc.opt_report_to_mpid = 'MLCB' and
                  acc.trading_firm_id <> 'cantor')
         join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
         join genesis2.option_series os on os.option_series_id = oc.option_series_id
         join genesis2.instrument i on i.instrument_id = alin.instrument_id
where alin.date_id between :in_start_date_id and :in_end_date_id
order by aitr.trade_record_id;