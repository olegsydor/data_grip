delete
from alloc_instr2trade_record
where alloc_instr_id in (select alloc_instr_id
                         from allocation_instruction ai
                         where ai.date_id = :del_date_id
                           and ai.created_by_subsystem_id = 'RPS');


delete
from allocation_instruction_entry
where alloc_instr_id in (select alloc_instr_id
                         from allocation_instruction ai
                         where ai.date_id = :del_date_id
                           and ai.created_by_subsystem_id = 'RPS');

delete
from allocation_instruction ai
where ai.date_id = :del_date_id
  and ai.created_by_subsystem_id = 'RPS';

/*
-- Current UAT version

SELECT genesis2.auto_allocate_unallocated_trade(in_instrument_type_id=>'O',in_allocation_type=>0,in_date_id=>:del_date_id);

SELECT genesis2.auto_allocate_unallocated_trade(in_instrument_type_id=>'E',in_allocation_type=>0,in_date_id=>:del_date_id)
;

-- New UAT version

SELECT trash.auto_allocate_unallocated_trade(in_instrument_type_id=>'O',in_allocation_type=>0,in_date_id=>20240301);

SELECT
 trash.auto_allocate_unallocated_trade
(
in_instrument_type_id=>'E',in_allocation_type=>0,in_date_id=>20240301
)
;
*/

-- working version
create temp table prod_trade_for_allocations
 as
 select L1.ACCOUNT_ID, L1.INSTRUMENT_ID,  L1.SIDE,  L1.OPEN_CLOSE, L1.cmta, L1.mpid, eq_grp, L1.AVG_PX, L1.TOTAL_QTY, L1.trade_ids--, nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
  from (select TR.ACCOUNT_ID, TR.INSTRUMENT_ID,  TR.SIDE,  TR.OPEN_CLOSE, tr.cmta,
  				case acc.opt_is_fix_custfirm_processed when 'Y' then  tr.market_participant_id else null end as mpid,
               	case :in_allocation_type when  3 then  coalesce(tr.compliance_id, tr.alternative_compliance_id) else null end as eq_grp,
			  round(sum(TR.LAST_PX * TR.LAST_QTY)/sum(TR.LAST_QTY),6) as AVG_PX, sum(TR.LAST_QTY) as TOTAL_QTY,
			  array_agg(tr.trade_record_id order by tr.trade_record_id) as trade_ids --, nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
			 from TRADE_RECORD TR
			  inner join ACCOUNT ACC on (ACC.ACCOUNT_ID = TR.ACCOUNT_ID)
			  inner join INSTRUMENT I on (TR.INSTRUMENT_ID = I.INSTRUMENT_ID)
			  /* SY: Just to be sure clearing account already configured */
			  inner join CLEARING_ACCOUNT CA on (CA.ACCOUNT_ID  = ACC.ACCOUNT_ID and CA.IS_DELETED = 'N'  and CA.MARKET_TYPE = :in_instrument_type_id    and CA.IS_DEFAULT = 'Y')
			  /* We need to exclude manual allocations */
			  left join lateral (select A.ALLOC_INSTR_ID
			                      from  ALLOC_INSTR2TRADE_RECORD AT
			                      inner join ALLOCATION_INSTRUCTION A on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
			                      where AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID) AA on true
			   /* We need to exclude manual clearing */
			   left join  lateral (select count(1) cn --coalesce(cie.new_trade_record_id, cie.trade_record_id) as trade_RECORD_ID /*, cie.clearing_instr_entry_id */
			               from  clearing_instruction_entry cie
			                inner join clearing_instruction ci on cie.clearing_instr_id = ci.clearing_instr_id and ci.status='D' and ci.is_deleted ='N'
			                inner join clearing_account inner_ca 	on cie.clearing_account_number=inner_ca.clearing_account_number
			                      									and cie.account_id = inner_ca.account_id
		                                                         	and inner_ca.is_deleted ='N'
		                                                         	and inner_ca.market_type = :in_instrument_type_id /* to avoid attempt to allocate wrong clearing accounts*/
 		                                                            and  nullif(cie.street_account_name,'') is not distinct from nullif(inner_ca.occ_actionable_id,'')
 		                                                            --and inner_ca.clearing_account_name = ''
			                      where  cie.date_id = :l_date_id
			                         and nullif(cie.clearing_account_number,'') is not null
			                         and nullif(cie.cmta,'') is not null
			                         and coalesce(cie.new_trade_record_id, cie.trade_record_id) = TR.TRADE_RECORD_ID
			                         group by TR.TRADE_RECORD_ID having count(1)=1  /*We just need to be sure we have one clearing account for that manual allocation */
			               ) man_clear on true

			  where TR.DATE_ID = :l_date_id
			        and TR.IS_BUSTED = 'N'
			        and case :in_instrument_type_id
			             when 'E' then ACC.IS_AUTO_ALLOCATE
			               		  else ACC.IS_OPTION_AUTO_ALLOCATE
			             end = 'Y'
			        and I.INSTRUMENT_TYPE_ID = :in_instrument_type_id
			        and ((:in_instrument_type_id = 'O' and coalesce(ACC.OPT_REPORT_TO_MPID,'NONE') <> 'NONE') or
			             (:in_instrument_type_id = 'E' and coalesce(ACC.EQ_REPORT_TO_MPID,'NONE') <> 'NONE'))
			        and AA.ALLOC_INSTR_ID is null
			        and man_clear.cn is null
			--        and at.TRADE_RECORD_ID is null
			        and TR.TRADE_RECORD_ID <= :l_max_trade_id
			        and tr.order_id > 0 /* excluding Blaze originated Away trades */
			        and (:in_allocation_type = 0
			            or (:in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
			            or (:in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
			            OR (:in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
			  group by TR.ACCOUNT_ID, TR.INSTRUMENT_ID,  TR.SIDE,  TR.OPEN_CLOSE, tr.cmta, case acc.opt_is_fix_custfirm_processed when 'Y' then  tr.market_participant_id else null end,
			           case :in_allocation_type when  3 then  coalesce(tr.compliance_id, tr.alternative_compliance_id) else null  end ) L1 ;



-- modif version SO
 create temp table pre_trade_for_allocations
 as
       select TR.ACCOUNT_ID, TR.INSTRUMENT_ID,  TR.SIDE,  TR.OPEN_CLOSE, tr.cmta,
  				case acc.opt_is_fix_custfirm_processed when 'Y' then  tr.market_participant_id else null end as mpid,
               	case :in_allocation_type when  3 then  coalesce(tr.compliance_id, tr.alternative_compliance_id) else null end as eq_grp
                  ,TR.LAST_PX, TR.LAST_QTY, tr.trade_record_id

			 from TRADE_RECORD TR
			  inner join ACCOUNT ACC on (ACC.ACCOUNT_ID = TR.ACCOUNT_ID)
			  inner join INSTRUMENT I on (TR.INSTRUMENT_ID = I.INSTRUMENT_ID)
			  /* SY: Just to be sure clearing account already configured */
			  inner join CLEARING_ACCOUNT CA on (CA.ACCOUNT_ID  = ACC.ACCOUNT_ID and CA.IS_DELETED = 'N'  and CA.MARKET_TYPE = :in_instrument_type_id    and CA.IS_DEFAULT = 'Y')
			  /* We need to exclude manual allocations */
			  left join lateral (select A.ALLOC_INSTR_ID
			                      from  ALLOC_INSTR2TRADE_RECORD AT
			                      inner join ALLOCATION_INSTRUCTION A on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
			                      where AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID) AA on true
			  where TR.DATE_ID = :l_date_id
			        and TR.IS_BUSTED = 'N'
			        and case :in_instrument_type_id
			             when 'E' then ACC.IS_AUTO_ALLOCATE
			               		  else ACC.IS_OPTION_AUTO_ALLOCATE
			             end = 'Y'
			        and I.INSTRUMENT_TYPE_ID = :in_instrument_type_id
  and case
          when :in_instrument_type_id = 'O' then ACC.OPT_REPORT_TO_MPID is not null
          when :in_instrument_type_id = 'E' then ACC.EQ_REPORT_TO_MPID is not null end
			        and AA.ALLOC_INSTR_ID is null
-- 			        and man_clear.cn is null
			--        and at.TRADE_RECORD_ID is null
			        and TR.TRADE_RECORD_ID <= :l_max_trade_id
			        and tr.order_id > 0 /* excluding Blaze originated Away trades */
  and case :in_allocation_type
          when 0 then true
          when 1 then ACC.IS_SPECIFIC_ALLOCATED = 'N'
          when 2 then ACC.IS_SPECIFIC_ALLOCATED = 'Y'
          when 3 then ACC.IS_SPECIFIC_ALLOCATED = 'T'
    end;


create temp table tst_trade_for_allocations as
select TR.ACCOUNT_ID,
       TR.INSTRUMENT_ID,
       TR.SIDE,
       TR.OPEN_CLOSE,
       tr.cmta,
       tr.mpid,
       tr.eq_grp,
       round(sum(TR.LAST_PX * TR.LAST_QTY) / sum(TR.LAST_QTY), 6)                       as AVG_PX,
       sum(TR.LAST_QTY)                                                                 as TOTAL_QTY,
       array_agg(tr.trade_record_id order by tr.trade_record_id)                                                    as trade_ids
--        nextval('allocation_instruction_alloc_instr_id_seq'::regclass)                   as alloc_instr_id
from pre_trade_for_allocations tr
-- the row below was added in order to improve performance
         left join genesis2.clearing_instruction_entry g2c
                   on coalesce(g2c.new_trade_record_id, g2c.trade_record_id) = tr.trade_record_id and
                      g2c.date_id = :l_date_id
         left join lateral (select count(1) as cnt --coalesce(cie.new_trade_record_id, cie.trade_record_id) as trade_RECORD_ID /*, cie.clearing_instr_entry_id */
                            from genesis2.clearing_instruction_entry cie
                                     inner join clearing_instruction ci
                                                on cie.clearing_instr_id = ci.clearing_instr_id and ci.status = 'D' and
                                                   ci.is_deleted = 'N'
                                     inner join clearing_account inner_ca
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
                              and coalesce(cie.new_trade_record_id, cie.trade_record_id) =
                                  coalesce(g2c.new_trade_record_id, g2c.trade_record_id)
                            group by coalesce(cie.new_trade_record_id, cie.trade_record_id)--TR.TRADE_RECORD_ID
--                             having count(1) = 1 /*We just need to be sure we have one clearing account for that manual allocation */
                            limit 1
    ) man on true
where man.cnt is distinct from 1
group by TR.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, TR.OPEN_CLOSE, tr.cmta,
         tr.mpid, tr.eq_grp;


select * from tst_trade_for_allocations
except
select * from prod_trade_for_allocations
except
select * from tst_trade_for_allocations