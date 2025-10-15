create temp table t_account as
select * from genesis2.account
create index on t_account (account_id)
create index on t_account (IS_SPECIFIC_ALLOCATED)
drop table t_tr;
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
           inner join t_account acc on (acc.account_id = tr.account_id)
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
      OR (:in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T')
    )
    and case  -- added DS-10061
            when :in_account_ids = '{}' then true
            when :in_account_ids is null then false
            else acc.account_id = any (:in_account_ids) end;


select * from t_tr