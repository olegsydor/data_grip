-- DROP FUNCTION dash360.get_data_for_allocation_drop_v2(int8, int4);

--CREATE OR REPLACE FUNCTION dash360.get_data_for_allocation_drop_v2(in_alloc_instr_id bigint, in_date_id integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
    -- 20260312 SO https://dashfinancial.atlassian.net/browse/DS-11249
declare
    l_return_jsonb jsonb;
begin
    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'side', ai.side,
                                                  'symbol', di.symbol,
                                                  'secType',
                                                  case when di.instrument_type_id = 'O' then 'OPT' else 'CS' end,
                                                  'putOrCall',
                                                  case when di.instrument_type_id = 'O' then oc.put_call end,
                                                  'strikePx',
                                                  case when di.instrument_type_id = 'O' then oc.strike_price end,
                                                  'maturityDay', case
                                                                     when di.instrument_type_id = 'O'
                                                                         then to_char(oc.maturity_day, 'FM00') end,
                                                  'maturityMonthYear', case
                                                                           when di.instrument_type_id = 'O' then
                                                                               to_char(oc.maturity_year, 'FM0000') ||
                                                                               to_char(oc.maturity_month, 'FM00') end,
                                                  'totalQty', ai.total_qty,
                                                  'avgPx', ai.avg_px,
                                                  'noExecs', aitr.trade_cnt,
                                                  'trades', aitr.trades,
                                                  'noAllocs', aie.alloc_cnt,
                                                  'allocationEntries', aie.entries,
                                                  'CCRURate', ccr.rate,
                                                  'CCRUTotalAmount', ccr.amount,
                                                  'AllocInstrId', ai.alloc_instr_id,
                                                  'instrumentTypeId', di.instrument_type_id
                               )
    from genesis2.allocation_instruction ai
             join genesis2.instrument di on di.instrument_id = ai.instrument_id
             left join lateral (select sum(l1.rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as rate,
                                       sum(amount)                                              as amount
                                from genesis2.alloc_instr2trade_record alt
                                         inner join genesis2.trade_record tr
                                                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                         left join lateral (select tl.rate,
                                                                   tl.amount,
                                                                   row_number()
                                                                   over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                            from genesis2.trade_level_book_record tl
                                                                     inner join genesis2.book_record_creator cr
                                                                                on tl.book_record_creator_id = cr.book_record_creator_id
                                                            where tl.date_id = in_date_id
                                                              AND tl.book_record_type_id = 'CCRU'
                                                              and tl.trade_record_id = alt.trade_record_id) l1
                                                   on true
                                where alt.alloc_instr_id = ai.alloc_instr_id
--                                  and tr.is_busted = 'N'
                                  and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end
                                  and (l1.rn = 1 or l1.rn is null)
        ) ccr on true

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'AllocEntryCCRURate', ccr.rate,
                                                               'AllocEntryCCRUTotalAmount',
                                                               ccr.amount * 1.0 * aie.alloc_qty / total_qty
                                            ))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.clearing_account ca
                                              on (ca.clearing_account_id = aie.clearing_account_id
                                                  )
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id = ai.alloc_instr_id
                             and aie.date_id = ai.date_id
                           limit 1) aie on true
             join lateral (select count(*) as trade_cnt,
                                  jsonb_agg(jsonb_build_object('dashExecId', tr.exch_exec_id,
                                                               'secondaryExchExecId', tr.secondary_exch_exec_id,
                                                               'lastQty', tr.last_qty,
                                                               'legRefId', tr.leg_ref_id,
                                                               'chainExecId', fmj.chain_exec_id)
                                  )        as trades
                           from genesis2.alloc_instr2trade_record aitr
                                    join genesis2.trade_record tr
                                         on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                                    join lateral (select fix_message ->> '10710' as chain_exec_id
                                                  from staging.fix_message_json fmj
                                                  where fmj.date_id = aitr.date_id
                                                    and fmj.fix_message_id = tr.trade_fix_message_id
                                                  limit 1) fmj on true
                           where aitr.alloc_instr_id = ai.alloc_instr_id
                             and aitr.date_id = ai.date_id
--                             and is_busted = 'N'
                           limit 1) aitr on true

             left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
             left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = in_alloc_instr_id
      and case when in_date_id is null then true else ai.date_id = in_date_id end;
    return l_return_jsonb;
end ;
$function$
;

select jtr.*
from genesis2.clearing_instruction_entry cie
         join genesis2.trade_record tr on tr.trade_record_id = cie.trade_record_id
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         left join lateral (select sum(l1.rate * itr.last_qty) / nullif(sum(itr.last_qty), 0) as rate,
                                   sum(l1.amount)                                              as amount
                            from genesis2.trade_record itr
                                     left join lateral (select tl.rate,
                                                               tl.amount,
                                                               row_number()
                                                               over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                        from genesis2.trade_level_book_record tl
                                                                 inner join genesis2.book_record_creator cr
                                                                            on tl.book_record_creator_id = cr.book_record_creator_id
                                                        where tl.date_id = :in_date_id
                                                          AND tl.book_record_type_id = 'CCRU'
                                                          and tl.trade_record_id = itr.trade_record_id) l1
                                               on true
                            where itr.trade_record_id = cie.new_trade_record_id
                              and itr.date_id = cie.date_id
--                                   and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end
                              and (l1.rn = 1 or l1.rn is null)
    ) ccr on true

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'AllocEntryCCRURate', ccr.rate,
                                                               'AllocEntryCCRUTotalAmount',
                                                               ccr.amount * 1.0 * aie.alloc_qty / total_qty
                                            ))
                                           as entries
                           from genesis2.clearing_instruction_entry ie
                           where ie.new_trade_record_id = aie.new_trade_record_id
                             and ie.date_id = ai.date_id
                           limit 1) aie on true

             join lateral (select count(*) as trade_cnt,
                                  jsonb_agg(jsonb_build_object('dashExecId', tr.exch_exec_id,
                                                               'secondaryExchExecId', tr.secondary_exch_exec_id,
                                                               'lastQty', tr.last_qty,
                                                               'legRefId', tr.leg_ref_id,
                                                               'chainExecId', fmj.chain_exec_id)
                                  )        as trades
                           from genesis2.trade_record jtr
                                    join lateral (select fix_message ->> '10710' as chain_exec_id
                                                  from staging.fix_message_json fmj
                                                  where fmj.date_id = jtr.date_id
                                                    and fmj.fix_message_id = tr.trade_fix_message_id
                                                  limit 1) fmj on true
                           where jtr.trade_record_id = cie.trade_record_id
                             and jtr.date_id = cie.date_id
--                             and is_busted = 'N'
                           limit 1) jtr on true

         left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
         left join genesis2.option_series os on oc.option_series_id = os.option_series_id
where true
  and cie.trade_record_id = :in_trade_record_id
  and case when :in_date_id is null then true else cie.date_id = :in_date_id end;


