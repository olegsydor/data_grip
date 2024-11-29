SELECT ftr.trade_record_id,
       ai.side,
       ae.alloc_qty,
       ai.avg_px,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                           AS ftr_cmta,
       ca.cmta                            AS ca_cmta,
       ai.date_id,
       os.min_tick_increment,
       acc.opt_penny_commission,
       acc.opt_nickel_commission,
       os.root_symbol,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       oc.strike_price,
       ai.open_close,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction ai
              ON ai.alloc_instr_id = ae.alloc_instr_id AND ai.is_deleted <> 'Y'
         inner join lateral (select tr.cmta,
                                    tr.opt_customer_firm, --, coalesce(tr.street_account_name,'') street_account_name
                                    tr.trade_record_id
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id and
                                                    aitr.date_id = tr.date_id and tr.is_busted = 'N' and
                                                    tr.exec_broker = :in_exec_broker
                             where aitr.alloc_instr_id = ai.alloc_instr_id
                               and aitr.date_id = ai.date_id
                             limit 1) ftr on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                  ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = ai.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = ai.instrument_id
WHERE ai.date_id between :in_start_date_id and :in_end_date_id;

select * from genesis2.trade_record
where trade_record.orig_trade_record_id in (3860724020,3861501867,3861528754,3861540292,3861541200,3860718656)