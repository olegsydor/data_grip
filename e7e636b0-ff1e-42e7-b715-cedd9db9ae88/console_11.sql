-- select L1.ACCOUNT_ID,
--        L1.INSTRUMENT_ID,
--        L1.SIDE,
--        L1.OPEN_CLOSE,
--        L1.cmta,
--        L1.mpid,
--        eq_grp,
--        L1.AVG_PX,
--        L1.TOTAL_QTY,
--        L1.trade_ids,
--        nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
-- from (
select TR.ACCOUNT_ID,
       TR.INSTRUMENT_ID,
       TR.SIDE,
       TR.OPEN_CLOSE,
       tr.cmta,
       case acc.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id end as mpid,
       case :in_allocation_type
           when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id) end      as eq_grp,
       round(sum(TR.LAST_PX * TR.LAST_QTY) / sum(TR.LAST_QTY), 6)                        as AVG_PX,
       sum(TR.LAST_QTY)                                                                  as TOTAL_QTY,
       array_agg(tr.trade_record_id)                                                     as trade_ids --, nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
       ,nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
from genesis2.TRADE_RECORD TR
         inner join genesis2.ACCOUNT ACC on (ACC.ACCOUNT_ID = TR.ACCOUNT_ID)
         inner join genesis2.INSTRUMENT I on (TR.INSTRUMENT_ID = I.INSTRUMENT_ID)
    /* SY: Just to be sure clearing account already configured */
         inner join lateral (select ca.* from genesis2.CLEARING_ACCOUNT CA where CA.ACCOUNT_ID = ACC.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                                     CA.MARKET_TYPE = :in_instrument_type_id and CA.IS_DEFAULT = 'Y' limit 1) ca on true
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
                                                on cie.clearing_account_number = inner_ca.clearing_account_number
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

where TR.DATE_ID = :l_date_id
  and TR.IS_BUSTED = 'N'
  and case :in_instrument_type_id
          when 'E' then ACC.IS_AUTO_ALLOCATE
          else ACC.IS_OPTION_AUTO_ALLOCATE
          end = 'Y'
  and I.INSTRUMENT_TYPE_ID = :in_instrument_type_id
  and case
          when :in_instrument_type_id = 'O' then coalesce(ACC.OPT_REPORT_TO_MPID, 'NONE') <> 'NONE'
          when :in_instrument_type_id = 'E' then coalesce(ACC.EQ_REPORT_TO_MPID, 'NONE') <> 'NONE' end
  and AA.ALLOC_INSTR_ID is null
  and man_clear.cn is null
  --        and at.TRADE_RECORD_ID is null
  and TR.TRADE_RECORD_ID <= :l_max_trade_id
  and tr.order_id > 0 /* excluding Blaze originated Away trades */
  and case :in_allocation_type
          when 0 then true
          when 1 then ACC.IS_SPECIFIC_ALLOCATED = 'N'
          when 2 then ACC.IS_SPECIFIC_ALLOCATED = 'Y'
          when 3 then ACC.IS_SPECIFIC_ALLOCATED = 'T'
    end
group by TR.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, TR.OPEN_CLOSE, tr.cmta,
         case acc.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id end,
         case :in_allocation_type when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id) end
--       ) L1;
-- 3475252272
--
-- select max(TRADE_RECORD_ID)
-- from genesis2.TRADE_RECORD where is_busted='N' and date_id = 20240328