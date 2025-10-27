select ai.date_id                                                                       as "75",
       ai.create_time                                                                   as "60",
       di.symbol                                                                        as "55",
       case when di.instrument_type_id = 'O' then 'OPT' else 'ES' end                   as "167",
       case when di.instrument_type_id = 'O' then oc.put_call end                       as "201",
       case when di.instrument_type_id = 'O' then oc.strike_price end                   as "202",
       case when di.instrument_type_id = 'O' then to_char(oc.maturity_day, 'FM00') end  as "205",
       case
           when di.instrument_type_id = 'O' then to_char(oc.maturity_year, 'FM0000') ||
                                                 to_char(oc.maturity_month, 'FM00') end as "200",
       ai.total_qty                                                                     as "53",
       ai.avg_px                                                                        as "6",
       "124",
       tr_arr as "NO_EXECS",
       *


from genesis2.allocation_instruction ai
         join lateral (select *
                       from genesis2.allocation_instruction_entry aie
                       where aie.alloc_instr_id = ai.alloc_instr_id
                         and aie.date_id = ai.date_id
                       limit 1) aie on true
         join lateral (select count(*) as "124", jsonb_agg(jsonb_build_object('17', tr.exec_id, 'secondary_exch_exec_id',
                                                           tr.secondary_exch_exec_id, 'last_qty', tr.last_qty,
                                                           'leg_ref_id', tr.leg_ref_id)
                              ) as tr_arr
                       from genesis2.alloc_instr2trade_record aitr
                                join genesis2.trade_record tr
                                     on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                       where aitr.alloc_instr_id = ai.alloc_instr_id
                         and aitr.date_id = ai.date_id
                         and aitr.allocation_instruction_entry_id = aie.allocation_instruction_entry_id
                       limit 1) aitr on true
         join genesis2.instrument di on di.instrument_id = ai.instrument_id
         join genesis2.clearing_account ca
              on (ca.clearing_account_id = aie.clearing_account_id and ca.clearing_account_type = '1' and
                  ca.market_type = 'O')
         left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
         left join genesis2.option_series os on oc.option_series_id = os.option_series_id
where ai.date_id = 20251024
  and ai.alloc_instr_id = -298599144
-- group by 1 aie.allocation_instruction_entry_id) > 1
--                 having count(distinct
