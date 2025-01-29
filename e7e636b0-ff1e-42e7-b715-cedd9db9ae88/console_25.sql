select array_agg(trade_record_id)
from clearing_instruction_entry
where clearing_instr_id = :in_clearing_instr_id
--'{3961223943,3961223963,3961224093,3961224107,3961224110,3961224111,3961224140,3961223932,3961223933,3961223944,3961223945,3961223946,3961223961,3961223962,3961223964,3961223973,3961223974,3961223975,3961223983,3961223996,3961223997,3961224004,3961224005,3961224006,3961224021,3961224038,3961224039,3961224040,3961224056,3961224057,3961224058,3961224059,3961224070,3961224072,3961224073,3961224083,3961224094,3961224095,3961224108,3961224109,3961224125,3961224126,3961224139,3961224141,3961224142}'
select real_exch.exchange_name                                    as exchange_name,
       i.display_instrument_id2                                   as symbol,
       i.last_trade_date                                          as expiration_date,
       tr.side,
       cie.open_close,
       cie.last_px                                                as last_px,
       cie.exec_broker                                            as gup,
       cie.cmta,
       cie.opt_customer_firm,
       cie.clearing_account_number,
       cie.sub_account,
       cie.account_id,
       tr.client_id,
       sum(cie.last_qty)                                          as last_qty,  -- affected qty
       sum(cie.last_qty) + sum(coalesce(trt.last_qty, 0))::bigint as total_qty, -- total qty
       cie.electronic_report_status                               as report_status,
       cie.street_account_name,
       cie.street_exec_broker,
       cie.client_commission_rate,
       real_exch.exchange_id                                      as exchange_id,
       i.instrument_type_id,
       cie.branch_sequence_number,
       cie.trade_text,
       cie.frequent_trader_id
from clearing_instruction_entry cie
         --inner join clearing_instruction ci on ci.clearing_instr_id = cie.clearing_instr_id
         inner join trade_record tr on tr.trade_record_id = cie.trade_record_id
         left join instrument i on i.instrument_id = tr.instrument_id
         left join exchange exch on exch.exchange_id = tr.exchange_id
         left join exchange real_exch on real_exch.exchange_id = exch.real_exchange_id

         left join (select total.account_id
                         , total.instrument_id
                         , total.side
                         , total.last_px
                         , coalesce(total.open_close, '')  as    open_close
                         , coalesce(total.client_id, '')   as    client_id
                         , coalesce(total.exec_broker, '') as    exec_broker
                         , coalesce(total.cmta, '')              cmta
                         , coalesce(total.opt_customer_firm, '') opt_customer_firm
                         , sum(total.last_qty)                   last_qty
                    from trade_record total
                    where total.date_id = :l_date_id
                      and date_id = :l_date_id
                      and total.is_busted = 'N'
                      and total.trade_record_id not in (select trade_record_id
                                                        from clearing_instruction_entry
                                                        where clearing_instr_id = :in_clearing_instr_id)
                      and total.orig_trade_record_id not in (select trade_record_id
                                                             from clearing_instruction_entry
                                                             where clearing_instr_id = :in_clearing_instr_id)

                    group by total.account_id, total.instrument_id, total.side, total.last_px
                           , total.open_close
                           , total.client_id
                           , total.exec_broker
                           , total.cmta
                           , total.opt_customer_firm) trt on (trt.account_id = cie.account_id
    and trt.instrument_id = tr.instrument_id
    and trt.side = tr.side
    and trt.last_px = cie.last_px
    and trt.open_close = coalesce(cie.open_close, '')
    and trt.client_id = coalesce(tr.client_id, '')
    and trt.exec_broker = coalesce(cie.exec_broker, '')
    and trt.cmta = coalesce(cie.cmta, '')
    and trt.opt_customer_firm = coalesce(cie.opt_customer_firm, ''))

where cie.clearing_instr_id = :in_clearing_instr_id
  and tr.date_id = :l_date_id
group by cie.account_id,
         real_exch.exchange_id,
         i.instrument_id,
         i.instrument_type_id,
         i.last_trade_date,
         tr.side,
         tr.client_id,
         cie.open_close,
         cie.last_px,
         cie.exec_broker,
         cie.cmta,
         cie.opt_customer_firm,
         cie.clearing_account_number,
         cie.sub_account,
         real_exch.exchange_name,
         cie.electronic_report_status,
         cie.street_account_name,
         cie.street_exec_broker,
         cie.client_commission_rate,
         cie.branch_sequence_number,
         cie.trade_text,
         cie.frequent_trader_id;