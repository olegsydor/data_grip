select * from dwh.d_account
where account_name = 'ROPP_ONEL'

select tr.date_id,
                            tr.trade_record_time::date                                  as trade_record_time,
                            tr.instrument_type_id,
                            sum(tr.last_qty)                                            as sum_last_qty,
                            sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
                            tr.open_close,
                            --tr.order_id,
                            tr.instrument_id,
                            tr.account_id,
                            tr.side,
                            tr.cmta,
                            at.alloc_qty                                                as alloc_qty,
                            at.alloc_instr_id                                           as alloc_instr_id,
                            at.clearing_account_id                                      as clearing_account_id,
                            sum(coalesce(tr.tcce_maker_taker_fee_amount, 0.0))          as tcce_maker_taker_fee_amount,
                            sum(coalesce(tr.tcce_account_dash_commission_amount, 0.0))  as tcce_account_dash_commission_amount, --
                            sum(coalesce(tr.tcce_transaction_fee_amount, 0.0))          as tcce_transaction_fee_amount,
                            sum(coalesce(tr.tcce_trade_processing_fee_amount, 0.0))     as tcce_trade_processing_fee_amount,
                            sum(coalesce(tr.tcce_royalty_fee_amount, 0.0))              as tcce_royalty_fee_amount,
                            sum(tr.principal_amount)                                    as principal_amount,
                            sum(coalesce(tr.tcce_account_execution_cost, 0.0))          as tcce_account_execution_cost,
                            sum(coalesce(tr.client_commission_rate,0.0) * tr.last_qty) 	as client_commission_rate_sum
                     from dwh.flat_trade_record tr
                              join dwh.d_account acc on (acc.account_id = tr.account_id and acc.is_active)
                              join lateral (select alloc_qty, alloc_instr_id, clearing_account_id
                                                 from dwh.allocation2trade_record atr
                                                 where atr.trade_record_id = tr.trade_record_id
                                                   and atr.date_id = tr.date_id
                                                   and atr.is_active
                                                 limit 1) at on true
                     where tr.date_id between :in_start_date_id and :in_end_date_id
                       and is_busted = 'N'
                       --and tr.order_id > 0
                       and case when coalesce(:in_account_ids, '{}') = '{}' then true else acc.account_id = any (:in_account_ids) end
                       and case when coalesce(:in_trading_firm_ids, '{}') = '{}' then true else acc.trading_firm_id = any (:in_trading_firm_ids) end
                       and case
                               when :in_instrument_type is null then true
                               else tr.instrument_type_id = :in_instrument_type end
                     group by tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, tr.cmta,
                              at.alloc_qty, tr.trade_record_time::date,
                              tr.instrument_type_id, at.alloc_instr_id, at.clearing_account_id