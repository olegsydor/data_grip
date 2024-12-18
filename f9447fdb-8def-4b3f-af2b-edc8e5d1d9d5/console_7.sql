-- accounts
select distinct tr.account_id, ac.trading_firm_id
from genesis2.trade_record tr
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         join genesis2.account ac on tr.account_id = ac.account_id
where tr.date_id = :in_date_id
  and di.instrument_type_id = 'O';



create temp table t_trade_record_monitor as
select tr.trade_record_id,
       tr.last_qty,
       case when to_char(di.last_trade_date, 'YYYYMMDD')::int4 = :in_date_id then true else false end as expiring_today,
       case
           when al.alloc_instr_id is not null then 'allocated'
           else 'unallocated' end as is_alloc,
       case
           when un.alloc_instr_id is not null then 'unable'
           end                    as is_unable
from genesis2.trade_record tr
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         join genesis2.account ac on tr.account_id = ac.account_id
         left join genesis2.alloc_instr2trade_record atr
                   on atr.trade_record_id = tr.trade_record_id and atr.date_id = tr.date_id
         left join lateral (select atr.alloc_instr_id
                            from genesis2.allocation_instruction ai
                            where ai.alloc_instr_id = atr.alloc_instr_id
                              and ai.is_deleted = 'N'
                            limit 1) al on true
         left join lateral ( select bar.alloc_instr_id
                             from dash360.bofa_allocation_report bar
                             where bar.alloc_instr_id = atr.alloc_instr_id
                               and bar.date_id = atr.date_id
                               and bar.to_report <> 'report'
                             limit 1) un on true
where true
  and tr.is_busted <> 'Y'
  and tr.date_id = :in_date_id
  and di.instrument_type_id = 'O'
;

select * from t_trade_record_monitor1
      where true
and tr.trade_record_id in (2346622522,2346622521,2346622513,2346622559,2346622562,2346622569);

-- allocated
select *
from genesis2.trade_record tr
         join genesis2.alloc_instr2trade_record atr
              on atr.trade_record_id = tr.trade_record_id and atr.date_id = tr.date_id
         join genesis2.allocation_instruction ai on ai.alloc_instr_id = atr.alloc_instr_id
where true
  and tr.date_id = 20241217
  and tr.is_busted <> 'Y'
  and is_deleted = 'N'


-- unallocated
select * from genesis2.trade_record tr
    where true
        and date_id = 20241217
        and trade_record_reason is null
      and is_busted <> 'Y'
        and not exists(select null from genesis2.alloc_instr2trade_record atr where atr.trade_record_id = tr.trade_record_id and atr.date_id = tr.date_id)





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

select atr.trade_record_id, * from dash360.bofa_allocation_report bar
         join genesis2.alloc_instr2trade_record atr
              on atr.alloc_instr_id = bar.alloc_instr_id and atr.date_id = bar.date_id
where bar.date_id = 20241212
and bar.to_report <> 'report'

select atr.alloc_instr_id, *
from genesis2.alloc_instr2trade_record atr
         join genesis2.allocation_instruction ai on ai.alloc_instr_id = atr.alloc_instr_id
where atr.trade_record_id in (2346622522, 2346622521, 2346622513, 2346622559, 2346622562, 2346622569)
--   and atr.date_id = tr.date_id
  and ai.is_deleted = 'N'
