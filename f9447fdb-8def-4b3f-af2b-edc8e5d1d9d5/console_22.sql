drop table if exists t_tr;
  create temp table t_tr
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
--    and TR.TRADE_RECORD_ID <= l_max_trade_id
--    and TR.TRADE_RECORD_ID <= l_max_trade_id
    and tr.order_id > 0 /* excluding Blaze originated Away trades */
    and (:in_allocation_type = 0
      or (:in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
      or (:in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
      OR (:in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
    and case  -- added DS-10061
            when :in_account_ids = '{}' then true
            when :in_account_ids is null then false
            else acc.account_id = any (:in_account_ids) end
and tr.trade_record_id = 2347383271;




    -- creating temp table for account_id with sum(allocatin_ratio) = 1 only
  drop table t_clearing_account_aa
  create temp table t_clearing_account_aa as
  with base as (select ca.account_id,
                       ca.clearing_account_id as up_clearing_account_id,
                       coalesce(aa.clearing_account_id, ca.clearing_account_id)         as clearing_account_id,
                       coalesce(aa.occ_actionable_id, ca.occ_actionable_id)             as occ_actionable_id,
                       coalesce(aa.clearing_account_number, ca.clearing_account_number) as clearing_account_number,
                       coalesce(aa.cmta, ca.cmta)                                       as cmta,
                       coalesce(aa.auto_alloc_ratio, 1)                                 as auto_alloc_ratio
                from genesis2.clearing_account ca
                         left join genesis2.clearing_account aa
                                   on ca.account_id = aa.account_id and aa.is_auto_alloc_to = 'Y'
                                       and aa.is_deleted = 'N'
                                       and aa.market_type = :in_instrument_type_id
                where true
                  and ca.is_deleted = 'N'
                  and ca.market_type = :in_instrument_type_id
                  and ca.is_default = 'Y'
                and ca.clearing_account_id = -269307)
     , check_sum_ratio as (select account_id, sum(auto_alloc_ratio) as sum_ratio
                           from base
                           group by account_id
                           having sum(auto_alloc_ratio) = 1)
  select account_id, clearing_account_id, occ_actionable_id, clearing_account_number, cmta, auto_alloc_ratio, up_clearing_account_id
  from base
           join check_sum_ratio using (account_id);

select * from t_clearing_account_aa
where clearing_account_id = -269307

drop table trade_for_allocations;
 create temp table trade_for_allocations
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
         nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
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
               array_agg(tr.trade_record_id)                                                              as trade_ids --, nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
--         ca.clearing_account_id
       from t_tr tr
                 /* SY: Just to be sure clearing account already configured */
                 join genesis2.CLEARING_ACCOUNT CA on (CA.ACCOUNT_ID = TR.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                                             CA.MARKET_TYPE = :in_instrument_type_id and
                                                             CA.IS_DEFAULT = 'Y')
                 join t_clearing_account_aa caa on ca.clearing_account_id = coalesce(caa.clearing_account_id, caa.up_clearing_account_id)
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

        where AA.ALLOC_INSTR_ID is null
          and man_clear.cn is null
        --and TR.TRADE_RECORD_ID <= l_max_trade_id
        group by TR.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, TR.OPEN_CLOSE, tr.cmta,
                 case tr.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id else null end,
                 case :in_allocation_type
                     when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                     else null end) L1;

select * from genesis2.auto_allocate_unallocated_trade(in_instrument_type_id := 'O', in_allocation_type := 0, in_date_id := 20250721)


select max(allocation_instruction_entry_id) as allocation_instruction_entry_id, count(*)
                          from genesis2.allocation_instruction_entry aie
                          where aie.alloc_instr_id in (-81584)
                          group by alloc_instr_id
                          having count(*) = 1