select tf.trading_firm_name, acc.*
from genesis2.allocation_instruction_entry ae
         join genesis2.allocation_instruction alin
              on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
         join genesis2.clearing_account ca
              on (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                  and ca.clearing_account_type = '1' and ca.market_type = 'O')
         join genesis2.account acc ON (acc.account_id = ca.account_id and acc.is_deleted <> 'Y' and
                                       acc.opt_report_to_mpid = 'MLCB' and
                                       acc.trading_firm_id <> 'cantor')
         join genesis2.trading_firm tf on tf.trading_firm_id = acc.trading_firm_id
where ae.date_id = 20241217;


-- unallocated
select * from genesis2.trade_record tr
    where true
        and date_id = 20241217
        and trade_record_reason is null
      and is_busted <> 'Y'
        and not exists(select null from genesis2.alloc_instr2trade_record atr where atr.trade_record_id = tr.trade_record_id and atr.date_id = tr.date_id)


-- allocated
select *
from genesis2.trade_record tr
         join genesis2.alloc_instr2trade_record atr
             join allocation_instruction where is_deleted
              on atr.trade_record_id = tr.trade_record_id and atr.date_id = tr.date_id
where true
  and tr.date_id = 20241217
  and tr.is_busted <> 'Y'


-- unable to report
select *
from genesis2.trade_record tr
         join genesis2.alloc_instr2trade_record atr
              on atr.trade_record_id = tr.trade_record_id and atr.date_id = tr.date_id
         join dash360.bofa_allocation_report bar
              on bar.alloc_instr_id = atr.alloc_instr_id and bar.date_id = atr.date_id
where true
  and tr.date_id = 20241217
  and tr.is_busted <> 'Y'
  and bar.to_report <> 'report'
