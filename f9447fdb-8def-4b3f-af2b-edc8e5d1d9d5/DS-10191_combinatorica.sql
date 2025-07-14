create temp table t_tr-- on commit drop
as
select TR.ACCOUNT_ID,
       TR.INSTRUMENT_ID,
       TR.SIDE,
       TR.OPEN_CLOSE,
       tr.cmta,
       acc.opt_is_fix_custfirm_processed,
       tr.market_participant_id,
       tr.compliance_id,
       tr.alternative_compliance_id,
       TR.LAST_PX,
       TR.LAST_QTY,
       tr.trade_record_id
from genesis2.trade_record tr
         inner join genesis2.account acc on (acc.account_id = tr.account_id)
         inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
where TR.DATE_ID = :l_date_id
  and TR.IS_BUSTED = 'N'
  and case :in_instrument_type_id
          when 'E' then ACC.IS_AUTO_ALLOCATE
          else ACC.IS_OPTION_AUTO_ALLOCATE
          end = 'Y'
  and I.INSTRUMENT_TYPE_ID = :in_instrument_type_id
  and ((:in_instrument_type_id = 'O' and coalesce(ACC.OPT_REPORT_TO_MPID, 'NONE') <> 'NONE') or
       (:in_instrument_type_id = 'E' and coalesce(ACC.EQ_REPORT_TO_MPID, 'NONE') <> 'NONE'))
  and TR.TRADE_RECORD_ID <= :l_max_trade_id
  and TR.TRADE_RECORD_ID <= :l_max_trade_id
  and tr.order_id > 0 /* excluding Blaze originated Away trades */
  and (:in_allocation_type = 0
    or (:in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
    or (:in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
    OR (:in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
  and case -- added DS-10061
          when :in_account_ids = '{}' then true
          when :in_account_ids is null then false
          else acc.account_id = any (:in_account_ids) end;


create temp table trade_for_allocations --on commit drop
  as
select L1.ACCOUNT_ID,
       L1.INSTRUMENT_ID,
       L1.SIDE,
       L1.OPEN_CLOSE,
       L1.cmta,
       L1.mpid,
       eq_grp,
       L1.AVG_PX,
       L1.TOTAL_QTY,
       L1.trade_ids,
       L1.last_qtys,
       nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
--        'alloc_instr_id'
from (select TR.ACCOUNT_ID,
             TR.INSTRUMENT_ID,
             TR.SIDE,
             TR.OPEN_CLOSE,
             tr.cmta,
             case tr.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id else null end as mpid,
             case :in_allocation_type
                 when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                 else null end                                                                          as eq_grp,
             round(sum(TR.LAST_PX * TR.LAST_QTY) / sum(TR.LAST_QTY), 6)                                 as AVG_PX,
             sum(TR.LAST_QTY)                                                                           as TOTAL_QTY,
             array_agg(tr.trade_record_id order by trade_record_id)                                     as trade_ids,
             array_agg(tr.LAST_QTY order by trade_record_id)                                            as last_qtys
      from t_tr tr
               /* SY: Just to be sure clearing account already configured */
               inner join genesis2.CLEARING_ACCOUNT CA on (CA.ACCOUNT_ID = TR.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                                           CA.MARKET_TYPE = :in_instrument_type_id and
                                                           CA.IS_DEFAULT = 'Y')
          /* We need to exclude manual allocations */
               left join lateral (select A.ALLOC_INSTR_ID
                                  from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                           inner join genesis2.ALLOCATION_INSTRUCTION A
                                                      on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
                                  where AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID) AA on true
          /* We need to exclude manual clearing */
               left join lateral (select count(1) cn --coalesce(cie.new_trade_record_id, cie.trade_record_id) as trade_RECORD_ID /*, cie.clearing_instr_entry_id */
                                  from genesis2.clearing_instruction_entry cie
                                           inner join genesis2.clearing_instruction ci
                                                      on cie.clearing_instr_id = ci.clearing_instr_id and
                                                         ci.status = 'D' and ci.is_deleted = 'N'
                                           inner join genesis2.clearing_account inner_ca
                                                      on cie.clearing_account_number =
                                                         inner_ca.clearing_account_number
                                                          and cie.account_id = inner_ca.account_id
                                                          and inner_ca.is_deleted = 'N'
                                                          and inner_ca.market_type =
                                                              :in_instrument_type_id /* to avoid attempt to allocate wrong clearing accounts*/
                                                          and
                                                         nullif(cie.street_account_name, '') is not distinct from nullif(inner_ca.occ_actionable_id, '')
                                  --and inner_ca.clearing_account_name = ''
                                  where cie.date_id = :l_date_id
                                    and nullif(cie.clearing_account_number, '') is not null
                                    and nullif(cie.cmta, '') is not null
                                    and coalesce(cie.new_trade_record_id, cie.trade_record_id) = TR.TRADE_RECORD_ID
                                  group by TR.TRADE_RECORD_ID
                                  having count(1) = 1 /*We just need to be sure we have one clearing account for that manual allocation */
          ) man_clear on true

      where true
      --             and AA.ALLOC_INSTR_ID is null
--           and man_clear.cn is null
      --and TR.TRADE_RECORD_ID <= l_max_trade_id
      group by TR.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, TR.OPEN_CLOSE, tr.cmta,
               case tr.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id else null end,
               case :in_allocation_type
                   when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                   else null end) L1;


create temp table t_clearing_account_aa --on commit drop
 as
  with base as (select ca.account_id,
                       ca.clearing_account_id,
                       ca.occ_actionable_id,
                       ca.clearing_account_number,
                       coalesce(aa.cmta, ca.cmta)          as cmta,
                       coalesce(aa.auto_alloc_ratio, 1)    as auto_alloc_ratio
                from genesis2.clearing_account ca
                         left join genesis2.clearing_account aa
                                   on ca.account_id = aa.account_id and aa.is_auto_alloc_to = 'Y'
                where true
                  and ca.is_deleted = 'N'
                  and ca.market_type = 'O'
                  and ca.is_default = 'Y')
     , check_sum_ratio as (select account_id, sum(auto_alloc_ratio) as sum_ratio
                           from base
                           group by account_id
                           having sum(auto_alloc_ratio) = 1
                           )
  select account_id, clearing_account_id, occ_actionable_id, clearing_account_number, cmta, auto_alloc_ratio
  from base
           join check_sum_ratio using (account_id);


select * from t_tr;
select account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys from trade_for_allocations;


drop table if exists t_aie;
  create temp table t_aie on commit drop as
  with base as (select ai.alloc_instr_id,
                       ca.clearing_account_id,
                       ai.account_id,
                       ca.auto_alloc_ratio,
                       ai.total_qty                                          as qty,
                       ai.total_qty * auto_alloc_ratio                    as pre_sum,
                       floor(ai.total_qty * auto_alloc_ratio)             as rnd_sum,
                       sum(floor(ai.total_qty * auto_alloc_ratio)) over w as acc_rnd_sum,
                       row_number() over w                                   as rn,
                       ca.occ_actionable_id
                from genesis2.allocation_instruction ai
                         inner join t_clearing_account_aa ca on (ca.account_id = ai.account_id)
                where ai.date_id = :l_date_id
--                   and ai.dataset_id = l_load_batch_id
                  and ai.is_deleted = 'N'
                group by ai.date_id, ai.alloc_instr_id, ai.total_qty, ca.occ_actionable_id, ca.clearing_account_id,
                         ai.account_id, ca.auto_alloc_ratio, ca.clearing_account_number
                window w as ( partition by ai.alloc_instr_id, ai.account_id
                        order by ca.auto_alloc_ratio, ca.clearing_account_number desc, ca.clearing_account_id)
                )
  select alloc_instr_id,
         clearing_account_id,
         case
             when rn != (select max(rn) from base b where b.alloc_instr_id = base.alloc_instr_id) then rnd_sum
             else qty - lag(base.acc_rnd_sum)
                        over (partition by alloc_instr_id order by auto_alloc_ratio) end  as alloc_qty,
--          rn,
--          qty as alloc_qty,
         occ_actionable_id,
--          l_date_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;