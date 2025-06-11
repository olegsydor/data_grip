alter table genesis2.clearing_account add column default_alloc_ratio numeric default 1.00;

-- DROP FUNCTION genesis2.auto_allocate_unallocated_trade(bpchar, int4, int4);
-- drop function trash.auto_allocate_unallocated_trade;
-- alter function genesis2.auto_allocate_unallocated_trade set schema trash;

drop function trash.auto_allocate_unallocated_trade
CREATE OR REPLACE FUNCTION trash.auto_allocate_unallocated_trade(in_instrument_type_id character,
                                                                    in_allocation_type integer,
                                                                    in_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                                    in_account_ids int4[] default '{}'::int4[]
)
    RETURNS integer
    LANGUAGE plpgsql
    SET application_name TO 'ETL:  AutoAllocation'
AS $function$
--in_allocation_type = 0: options
--in_allocation_type = 1: equities with ACC.IS_SPECIFIC_ALLOCATED = 'N'
--in_allocation_type = 2: equities with ACC.IS_SPECIFIC_ALLOCATED = 'Y'

--  SY:  20210223  DS-2833.  Subscription  has  been  introduced
--  SY:  20210418  DS-3342.  Migrate  to  is_option_autoallocate  for  options  and  is_autoallocate  for  Equity
--  SY:  20210610  DS-3568.  Introduced  market  Participant  id  and  coalesce(tr.compliance_id,  tr.alternative_compliance_id)  to  group  by  statement  while  bunching  trades
--  SY:  20210715  DS-3811.  The  opt_is_fix_custfirm_processed  field  has  been  added  to  the  logic  to  identify  using  of  mpid  during  bunching.
--  SY:  20230922  https://dashfinancial.atlassian.net/browse/DS-7307  street_account_name  field  has  been  added  to  the  manual  clearing  sub  query
--  SY:  20240901  https://dashfinancial.atlassian.net/browse/DS-7470  application  name  has  been  added  to  be  able  to  track  performance  via  zabbix    -- SY: 20240212 https://dashfinancial.atlassian.net/browse/DS-7931 join to clearing account has been added to be sure manual clearin uses correct attributes.
-- 	SY:  20240221   https://dashfinancial.atlassian.net/browse/DS-7931 join to clearing account has been added to be sure manual clearin uses correct attributes.
-- 																	condition on cmta is not null has been removed from that join.
--  SY:  20240221 https://dashfinancial.atlassian.net/browse/DS-8077	having count(1) has been added
--  SY:  20241114 https://dashfinancial.atlassian.net/browse/DS-9151 tr table has been introduced
--  SO:  20250602 https://dashfinancial.atlassian.net/browse/DS-10060 Added account_id list as an input parameter that is calculated in the wrapper (see https://dashfinancial.atlassian.net/browse/DS-10060)
--  SO:  20250606 https://dashfinancial.atlassian.net/browse/DS-10060 Support multiple default CTMAs in auto-allocation job

DECLARE
--  ai RECORD;
--  ai_id integer;
--  cl_acc_id integer;
    l_date_id       integer;
    l_max_trade_id  int8;
    l_cnt_rows      int;
    l_load_id       int;
    l_step_id       int;
    l_load_batch_id bigint;
begin

  select nextval('load_timing_seq') into l_load_id;
  l_step_id:=1;
  l_cnt_rows := 0;

  l_date_id = in_date_id;

select nextval('load_batch_load_batch_id_seq')  into l_load_batch_id;

select public.load_log(l_load_id, l_step_id, 'AUTOALLOCATION Started <<<', 0, 'S')
	into l_step_id;

select public.load_log(l_load_id, l_step_id, 'l_load_batch_id: '||l_load_batch_id, 0, 'S')
	into l_step_id;

 select public.load_log(l_load_id, l_step_id, 'in_instrument_type_id='||in_instrument_type_id||' in_allocation_type='||in_allocation_type||' date_id='||l_date_id, 1 , 'O')
	into l_step_id;

execute 'select max(TRADE_RECORD_ID)  from TRADE_RECORD where is_busted=''N'' and date_id = '||l_date_id
  into l_max_trade_id ;

 select public.load_log(l_load_id, l_step_id, 'l_max_trade_id='||l_max_trade_id, 1 , 'S')
	into l_step_id;

  create temp table t_tr on commit drop
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
  where TR.DATE_ID = l_date_id
    and TR.IS_BUSTED = 'N'
    and case in_instrument_type_id
            when 'E' then ACC.IS_AUTO_ALLOCATE
            else ACC.IS_OPTION_AUTO_ALLOCATE
            end = 'Y'
    and I.INSTRUMENT_TYPE_ID = in_instrument_type_id
    and ((in_instrument_type_id = 'O' and coalesce(ACC.OPT_REPORT_TO_MPID, 'NONE') <> 'NONE') or
         (in_instrument_type_id = 'E' and coalesce(ACC.EQ_REPORT_TO_MPID, 'NONE') <> 'NONE'))
    and TR.TRADE_RECORD_ID <= l_max_trade_id
    and TR.TRADE_RECORD_ID <= l_max_trade_id
    and tr.order_id > 0 /* excluding Blaze originated Away trades */
    and (in_allocation_type = 0
      or (in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
      or (in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
      OR (in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
    and case  -- added DS-10061
            when coalesce(in_account_ids, '{}') = '{}' then true
            else acc.account_id = any (in_account_ids) end;

    	GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

    	select public.load_log(l_load_id, l_step_id, 'create temp table TR', l_cnt_rows, 'I')
		into l_step_id;

  create temp table trade_for_allocations on commit drop
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
               case in_allocation_type
                   when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                   else null end                                                                          as eq_grp,
               round(sum(TR.LAST_PX * TR.LAST_QTY) / sum(TR.LAST_QTY), 6)                                 as AVG_PX,
               sum(TR.LAST_QTY)                                                                           as TOTAL_QTY,
               array_agg(tr.trade_record_id)                                                              as trade_ids --, nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
        from t_tr tr
                 /* SY: Just to be sure clearing account already configured */
                 inner join lateral (select 'nothing'
                                     from genesis2.CLEARING_ACCOUNT CA
                                     where CA.ACCOUNT_ID = TR.ACCOUNT_ID
                                       and CA.IS_DELETED = 'N'
                                       and CA.MARKET_TYPE = in_instrument_type_id
                                       and CA.IS_DEFAULT = 'Y'
                                     limit 1) ca
                            on true -- added for DS-10060 - Support multiple default CTMAs in auto-allocation job
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
                                                                in_instrument_type_id /* to avoid attempt to allocate wrong clearing accounts*/
                                                            and
                                                           nullif(cie.street_account_name, '') is not distinct from nullif(inner_ca.occ_actionable_id, '')
                                    --and inner_ca.clearing_account_name = ''
                                    where cie.date_id = l_date_id
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
                 case in_allocation_type
                     when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                     else null end) L1;

    	GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

    	select public.load_log(l_load_id, l_step_id, 'create temp table trade_for_allocations', l_cnt_rows, 'I')
		into l_step_id;


  insert into genesis2.ALLOCATION_INSTRUCTION(alloc_instr_id, DATE_ID, CREATE_TIME, ACCOUNT_ID, INSTRUMENT_ID, SIDE,
                                              OPEN_CLOSE, AVG_PX, TOTAL_QTY, CREATED_BY_SUBSYSTEM_ID, dataset_id)
  select tr.alloc_instr_id,
         l_date_id,
         clock_timestamp(),
         TR.ACCOUNT_ID,
         TR.INSTRUMENT_ID,
         TR.SIDE,
         TR.OPEN_CLOSE,
         tr.AVG_PX,
         tr.TOTAL_QTY,
         'RPS',
         l_load_batch_id
  from trade_for_allocations TR;

  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION', l_cnt_rows, 'I')
  into l_step_id;


  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job
  -- 1. Check if all accounts for the current dataset have a sum of default_alloc_ratio equals 1
  if exists (select distinct on (account_id) 'smth'
             from genesis2.allocation_instruction ai
                      join lateral (select sum(ca.default_alloc_ratio) as sum_ratio
                                    from genesis2.clearing_account ca
                                    where true
                                      and ca.account_id = ai.account_id
                                      and ca.is_deleted = 'N'
                                      and ca.market_type = in_instrument_type_id
                                      and ca.is_default = 'Y'
                 ) ca on sum_ratio != 1
             where true
               and ai.date_id = l_date_id
               and ai.dataset_id = l_load_batch_id
               and ai.is_deleted = 'N') then
      raise exception 'The account with the sum of default_alloc_ratio less than 1 exists in the clearing account';
  end if;

-- 2. insert into allocation_instruction_entry
  create temp table t_aie as
  with base as (select ai.alloc_instr_id,
--                     ai.dataset_id,
                       clearing_account_id,
                       ai.account_id,
                       ca.default_alloc_ratio,
                       ai.total_qty                                          as qty,
                       ai.total_qty * default_alloc_ratio                    as pre_sum,
                       floor(ai.total_qty * default_alloc_ratio)             as rnd_sum,
                       sum(floor(ai.total_qty * default_alloc_ratio)) over w as acc_rnd_sum,
                       row_number() over w                                   as rn,
                       ca.occ_actionable_id,
                       ai.date_id
                from genesis2.allocation_instruction ai
                         inner join genesis2.clearing_account ca
                                    on (ca.account_id = ai.account_id and ca.is_deleted = 'N' and
                                        ca.market_type = in_instrument_type_id and ca.is_default = 'Y')
                where ai.date_id = l_date_id
                  and ai.dataset_id = l_load_batch_id
                  and ai.is_deleted = 'N'
                group by ai.date_id, ai.alloc_instr_id, ai.total_qty, ca.occ_actionable_id, ca.clearing_account_id,
                         ai.account_id, ca.default_alloc_ratio
                window w as ( partition by ai.alloc_instr_id, ai.account_id
                        order by ca.default_alloc_ratio, ca.clearing_account_id ))
  select alloc_instr_id,
         clearing_account_id,
         case
             when rn != (select max(rn) from base b where b.alloc_instr_id = base.alloc_instr_id) then rnd_sum
             else qty - lag(base.acc_rnd_sum)
                        over (partition by alloc_instr_id order by default_alloc_ratio) end  as alloc_qty,
         rn,
         occ_actionable_id,
         date_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;
  -------------------------------------------------------------------------------------

  insert into genesis2.allocation_instruction_entry (alloc_instr_id, clearing_account_id, alloc_qty, date_id,
                                                     occ_actionable_id, allocation_instruction_entry_id)
  select alloc_instr_id,
         clearing_account_id,
         alloc_qty,
         date_id,
         occ_actionable_id,
         allocation_instruction_entry_id
  from t_aie;

  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job
  -- End of the insertion into genesis2.allocation_instruction_entry


  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION_ENTRY', l_cnt_rows, 'I')
  into l_step_id;


  insert into genesis2.alloc_instr2trade_record(TRADE_RECORD_ID, ALLOC_INSTR_ID, DATE_ID, dataset_id, allocation_instruction_entry_id)
  with base as (select unnest(:trade_ids) as id,
                       ALLOC_INSTR_ID,
                       in_date_id,
                       l_load_batch_id
                from trade_for_allocations)
  select tr.id, tr.ALLOC_INSTR_ID, in_date_id, l_load_batch_id, aie.allocation_instruction_entry_id
  from base tr
  join lateral ( select allocation_instruction_entry_id from genesis2.allocation_instruction_entry aie where aie.alloc_instr_id = tr.alloc_instr_id limit 1) aie on true;


--   with base as (select unnest(ids) as id, txt from t_os)
-- select * from base
-- join trade_record tr on tr.trade_record_id = base.id


       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
       select public.load_log(l_load_id, l_step_id, 'insert into ALLOC_INSTR2TRADE_RECORD', l_cnt_rows, 'I')
	   into l_step_id;


	  /* ===================================================================================================================== */
	  /* Logic for Manual cleared trades */
	  /* ===================================================================================================================== */
  with main_source as (select l_date_id                                                                       as date_id,
                              clock_timestamp()                                                               as CREATE_TIME,
                              man_clear.ACCOUNT_ID,
                              TR.INSTRUMENT_ID,
                              TR.SIDE,
                              man_clear.OPEN_CLOSE,
                              round(sum(man_clear.LAST_PX * man_clear.LAST_QTY) / sum(man_clear.LAST_QTY), 6) as AVG_PX,
                              sum(man_clear.LAST_QTY)                                                         as TOTAL_QTY,
                              man_clear.clearing_account_id,
                              l_load_batch_id                                                                 as load_batch_id
                       from genesis2.TRADE_RECORD TR
                                inner join genesis2.ACCOUNT ACC on (ACC.ACCOUNT_ID = TR.ACCOUNT_ID)
                           /* SY: Just to be sure clearing account already configured */
                                inner join genesis2.CLEARING_ACCOUNT CA
                                           on (CA.ACCOUNT_ID = ACC.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                               CA.MARKET_TYPE = in_instrument_type_id and CA.IS_DEFAULT = 'Y')
                                inner join genesis2.INSTRUMENT I on (TR.INSTRUMENT_ID = I.INSTRUMENT_ID)
                           /* We need to exclude manual allocations and already autoallocated trades */
                                left join lateral (select A.ALLOC_INSTR_ID
                                                   from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                                            inner join genesis2.ALLOCATION_INSTRUCTION A
                                                                       on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
                                                   where AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID) AA on true
                           /* Manual clearing */
                                inner join lateral (select cie.last_qty,
                                                           cie.last_px,
                                                           cie.clearing_account_number,
                                                           cie.open_close,
                                                           cie.account_id,
                                                           inner_ca.clearing_account_id
                                                    from genesis2.clearing_instruction_entry cie
                                                             inner join genesis2.clearing_instruction ci
                                                                        on cie.clearing_instr_id =
                                                                           ci.clearing_instr_id and ci.status = 'D' and
                                                                           ci.is_deleted = 'N'
                                                             inner join genesis2.clearing_account inner_ca
                                                                        on cie.clearing_account_number =
                                                                           inner_ca.clearing_account_number
                                                                            and cie.account_id = inner_ca.account_id
                                                                            and inner_ca.is_deleted = 'N'
                                                                            and
                                                                           inner_ca.market_type = in_instrument_type_id
                                                                            and
                                                                           nullif(cie.street_account_name, '') is not distinct from nullif(inner_ca.occ_actionable_id, '')
                                                    --and inner_ca.clearing_account_name = ''
                                                    where cie.new_trade_record_id = TR.TRADE_RECORD_ID
                                                      and cie.date_id = tr.date_id
                                                      and nullif(cie.cmta, '') is not null
                                                      and nullif(cie.clearing_account_number, '') is not null
                                                    order by nullif(inner_ca.clearing_account_name, '') nulls first
                                                    limit 1
                           ) man_clear on true
                       where TR.DATE_ID = l_date_id
                         and TR.IS_BUSTED = 'N'
--        and ACC.IS_AUTO_ALLOCATE = 'Y'
                         and case in_instrument_type_id
                                 when 'E' then ACC.IS_AUTO_ALLOCATE
                                 else ACC.IS_OPTION_AUTO_ALLOCATE
                                 end = 'Y'
                         and I.INSTRUMENT_TYPE_ID = in_instrument_type_id
                         and tr.order_id > 0 /* excluding Blaze originated Away trades */
                         and ((in_instrument_type_id = 'O' and coalesce(ACC.OPT_REPORT_TO_MPID, 'NONE') <> 'NONE') or
                              (in_instrument_type_id = 'E' and coalesce(ACC.EQ_REPORT_TO_MPID, 'NONE') <> 'NONE'))
                         and AA.ALLOC_INSTR_ID is null
                         and TR.TRADE_RECORD_ID <= l_max_trade_id
                         and (in_allocation_type = 0
                           or (in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
                           or (in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
                           OR (in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
                         and case -- added DS-10061
                                 when coalesce(in_account_ids, '{}') = '{}' then true
                                 else acc.account_id = any (in_account_ids) end
                       group by man_clear.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, man_clear.OPEN_CLOSE,
                                man_clear.clearing_account_id),

       ins_all_in as ( insert into genesis2.ALLOCATION_INSTRUCTION (DATE_ID, CREATE_TIME, ACCOUNT_ID, INSTRUMENT_ID,
                                                                    SIDE, OPEN_CLOSE, AVG_PX, TOTAL_QTY,
                                                                    CREATED_BY_SUBSYSTEM_ID, dataset_id)
           select DATE_ID
                , CREATE_TIME
                , ACCOUNT_ID
                , INSTRUMENT_ID
                , SIDE
                , OPEN_CLOSE
                , AVG_PX
                , TOTAL_QTY
                , main_source.clearing_account_id /*we insert there not subsystem. it will be updated later. We need one more field into ALLOCATION_INSTRUCTION table */
                , load_batch_id
           from main_source
           returning ALLOC_INSTR_ID, CREATED_BY_SUBSYSTEM_ID, TOTAL_QTY, account_id)

  insert
  into genesis2.ALLOCATION_INSTRUCTION_ENTRY (ALLOC_INSTR_ID, CLEARING_ACCOUNT_ID, ALLOC_QTY, DATE_ID,
                                              occ_actionable_id)
  select ALLOC_INSTR_ID, CLEARING_ACCOUNT_ID, TOTAL_QTY, l_date_id, ca.occ_actionable_id
  from ins_all_in
           inner join genesis2.clearing_account ca on ca.clearing_account_id = ins_all_in.CREATED_BY_SUBSYSTEM_ID::int;

	       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
	       select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared insert into ALLOCATION_INSTRUCTION_ENTRY', l_cnt_rows, 'I')
		   into l_step_id;


  insert into genesis2.ALLOC_INSTR2TRADE_RECORD(TRADE_RECORD_ID, ALLOC_INSTR_ID, DATE_ID, dataset_id,allocation_instruction_entry_id)
  select coalesce(cie.new_trade_record_id, cie.trade_record_id), aie.ALLOC_INSTR_ID, l_date_id, l_load_batch_id, aie.allocation_instruction_entry_id
  from genesis2.ALLOCATION_INSTRUCTION ai
           inner join genesis2.ALLOCATION_INSTRUCTION_ENTRY aie
                      on ai.alloc_instr_id = aie.alloc_instr_id and is_deleted = 'N' and ai.date_id = aie.date_id
           inner join genesis2.clearing_account ca
                      on aie.clearing_account_id = ca.clearing_account_id and ca.is_deleted = 'N'
           inner join genesis2.clearing_instruction_entry cie
                      on cie.account_id = ca.account_id /*and cie.cmta = ca.cmta*/ and
                         cie.date_id = aie.date_id --- ?????
                          and cie.clearing_account_number = ca.clearing_account_number
                          --and cie.street_account_name = ca.occ_actionable_id
                          and nullif(cie.street_account_name, '') is not distinct from nullif(ca.occ_actionable_id, '')
                          and nullif(cie.cmta, '') is not null
           inner join genesis2.clearing_instruction ci
                      on cie.clearing_instr_id = ci.clearing_instr_id and ci.status = 'D' and ci.date_id = cie.date_id
           inner join genesis2.trade_record tr
                      on (coalesce(cie.new_trade_record_id, cie.trade_record_id) = tr.trade_record_id
                          and cie.date_id = tr.date_id
                          and tr.is_busted = 'N'
                          and ai.side = tr.side
                          and ai.instrument_id = tr.instrument_id
                          and ai.open_close = tr.open_close)
  where dataset_id = l_load_batch_id
    and ai.date_id = l_date_id
    and coalesce(ai.CREATED_BY_SUBSYSTEM_ID, 'RPS') <> 'RPS'
    and not exists (select null
                    from ALLOC_INSTR2TRADE_RECORD in_ai
                    where in_ai.trade_record_id = coalesce(cie.new_trade_record_id, cie.trade_record_id)
                      and in_ai.alloc_instr_id = ai.alloc_instr_id
                      and in_ai.date_id = ai.date_id);

  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
  select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared insert into ALLOC_INSTR2TRADE_RECORD', l_cnt_rows, 'I')
  into l_step_id;

  update genesis2.ALLOCATION_INSTRUCTION
  set CREATED_BY_SUBSYSTEM_ID = 'RPS'
  where dataset_id = l_load_batch_id
    and date_id = l_date_id
    and coalesce(CREATED_BY_SUBSYSTEM_ID, 'RPS') <> 'RPS';

 		       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
		       select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared CREATED_BY_SUBSYSTEM_ID restored', l_cnt_rows, 'I')
			   into l_step_id;


/* We need that part because GET DIAGNOSTIC still doesn't work with partitioned tables */
  select count(1)
  from genesis2.alloc_instr2trade_record aitr
  where date_id = l_date_id
    and dataset_id = l_load_batch_id
  into l_cnt_rows;

  Perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id,
                                 in_row_cnt => l_cnt_rows,
                                 in_subscription_name => 'allocation_to_big_data',
                                 in_source_table_name => 'genesis2.allocation_instruction',
                                 in_date_id => l_date_id);

select public.load_log(l_load_id, l_step_id, 'AUTOALLOCATION COMPLETED >>>', 0, 'E')
	into l_step_id;


  return l_cnt_rows;

 exception when others then
   select load_log(l_load_id, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E')
  into l_step_id;
  RAISE notice '% %', sqlstate, sqlerrm;

  select load_log(l_load_id, l_step_id, 'AUTOALLOCATION COMPLETED !!!', 0, 'E')
  into l_step_id;

  PERFORM load_error_log('AUTOALLOCATION',  'I', REPLACE(sqlerrm, ''::text, ''::text), l_load_id);
  RAISE;
end
$function$
;


alter table genesis2.account add column is_intraday_auto_allocate bpchar;
comment on column genesis2.account.is_intraday_auto_allocate is 'enables intraday auto allocation for options only and only for PTA_Accounts';


CREATE OR REPLACE FUNCTION dash360.bofa_allocation_report_wrapper(in_start_date_id integer, in_end_date_id integer,
                                                                  in_exec_broker text, in_is_eod boolean DEFAULT false,
                                                                  in_removed_account_ids integer[] DEFAULT '{62939,263022,62810,62887,62923,63787,67949}'::integer[],
                                                                  in_run_intraday_option_auto_allocation bool default true)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$fn$
declare
    l_row_cnt       int;
    l_load_id       int;
    l_step_id       int;
    l_load_batch_id bigint;
    l_account_ids   int4[];
begin
    select nextval('load_batch_load_batch_id_seq') into l_load_batch_id;

    select public.load_log(l_load_id, l_step_id, 'bofa_allocation_report_wrapper STARTED =======', 0, 'S')
    into l_step_id;

    if in_run_intraday_option_auto_allocation = 'Y' then
        -- 1. Select account_ids
        select array_agg(account_id)
        into l_account_ids
        from genesis2.account ac
        where true
          and ac.is_deleted = 'N'
          and ac.is_intraday_auto_allocate = 'Y'
          and ac.opt_report_to_mpid = 'MLCB';

        l_row_cnt = array_length(l_account_ids, 1);

        select public.load_log(l_load_id, l_step_id, 'bofa_allocation_report_wrapper account_ids calculated =======',
                               l_row_cnt, 'I')
        into l_step_id;

        -- 2. Call autoallocations
        select x
        into l_row_cnt
        from genesis2.auto_allocate_unallocated_trade(in_instrument_type_id := 'O',
                                                      in_allocation_type := 0,
                                                      in_account_ids := l_account_ids) as x;

        select public.load_log(l_load_id, l_step_id,
                               'bofa_allocation_report_wrapper account_ids auto allocation performed =======',
                               l_row_cnt,
                               'I')
        into l_step_id;
    end if;
    -- 3. Call dash360.bofa_allocation_report
    return query
        select ret_row
        from dash360.bofa_allocation_report(in_start_date_id, in_end_date_id,
                                            in_exec_broker, in_is_eod,
                                            in_removed_account_ids);
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'bofa_allocation_report_wrapper account_ids COMLETED =======',
                           l_row_cnt, 'I')
    into l_step_id;

end;

$fn$






select * from genesis2.allocation_instruction_entry
where account_nickname is not null;

/*
select 5 / 2.0
1. greater %
2. smaller cmta
3, primary key
*/

1.1 -> 2


0.33 -> 0
0.33 -> 0
0.33 -> 1


;

  create temp table t_aie as
  select ai.alloc_instr_id,
         ca.clearing_account_id,
         ai.account_id,
         ai.total_qty * ca.default_alloc_ratio as alloc_qty,
         :l_date_id                            as date_id,
         ca.occ_actionable_id
  from genesis2.allocation_instruction ai
           inner join genesis2.clearing_account ca on (ca.account_id = ai.account_id and ca.is_deleted = 'N' and
                                                       ca.market_type = :in_instrument_type_id and ca.is_default = 'Y')
  where ai.date_id = :l_date_id
    and ai.dataset_id = :l_load_batch_id
    and ai.is_deleted = 'N'
  and ai.account_id = 9908
  group by alloc_instr_id, total_qty, occ_actionable_id, ca.clearing_account_id
  order by ca.clearing_account_id, ai.alloc_instr_id;


create temp table t_aie as
with base as (select ai.alloc_instr_id,
--                     ai.dataset_id,
                     clearing_account_id,
                     ai.account_id,
                     ca.default_alloc_ratio,
                     ai.total_qty                                          as qty,
                     ai.total_qty * default_alloc_ratio                    as pre_sum,
                     floor(ai.total_qty * default_alloc_ratio)             as rnd_sum,
                     sum(floor(ai.total_qty * default_alloc_ratio)) over w as acc_rnd_sum,
                     row_number() over w                                   as rn
              from trash.so_allocation_instruction ai
                       inner join trash.so_clearing_account ca
                                  on (ca.account_id = ai.account_id and ca.is_deleted = 'N' and
                                      ca.market_type = :in_instrument_type_id and ca.is_default = 'Y')
              where ai.date_id = :l_date_id
                and ai.dataset_id = :l_load_batch_id
                and ai.is_deleted = 'N'
              and ai.account_id = 9908
              group by ai.alloc_instr_id, ai.total_qty, occ_actionable_id, ca.clearing_account_id,ai.account_id, ca.default_alloc_ratio
              window w as ( partition by ai.alloc_instr_id, ai.account_id order by ca.default_alloc_ratio, ca.clearing_account_id )
--               order by ai.alloc_instr_id, ca.default_alloc_ratio, ca.clearing_account_id
              )
select alloc_instr_id,
       clearing_account_id,
       account_id,
--        default_alloc_ratio,
--        pre_sum,
       qty,
        rnd_sum,

       case
           when rn != (select max(rn) from base b where b.alloc_instr_id = base.alloc_instr_id) then rnd_sum
           else qty - lag(base.acc_rnd_sum)
                      over (partition by alloc_instr_id order by default_alloc_ratio) end as final_qty,
       rn
from base
order by alloc_instr_id, clearing_account_id;
;


-- insert into trash.so_clearing_account
select ctid, * from trash.so_clearing_account
where account_id = 9908
and market_type = 'O'
and ctid = '(109,35)'in (select  ctid from trash.so_clearing_account
where account_id = 9908
and market_type = 'O'
order by 1 desc
    limit 1)


update trash.so_clearing_account
set clearing_account_id = 99998
where true
  and market_type = 'O'
  and ctid in (select ctid
               from trash.so_clearing_account
               where account_id = 9908
                 and market_type = 'O'
               order by 1 desc
               limit 1)

select *
 into trash.so_clearing_account
 from genesis2.clearing_account
where is_deleted = 'N'
  and is_default = 'Y';

select ai.account_id, sum(ca.default_alloc_ratio), array_agg(ca.default_alloc_ratio)
from genesis2.clearing_account ca
         join lateral (select account_id
                       from genesis2.allocation_instruction ai
                       where true
                         and ai.date_id = :l_date_id
                         and ai.dataset_id = :l_load_batch_id
                         and ai.is_deleted = 'N'
                         and ca.account_id = ai.account_id
                         and ca.is_deleted = 'N'
                         and ca.market_type = :in_instrument_type_id
                         and ca.is_default = 'Y'
                       limit 1) ai on true
group by ai.account_id;


select distinct on (account_id) *
from genesis2.allocation_instruction ai
         join lateral (select sum(ca.default_alloc_ratio) as sum_ratio
                       from genesis2.clearing_account ca
                       where true
                         and ca.account_id = ai.account_id
                         and ca.is_deleted = 'N'
                         and ca.market_type = :in_instrument_type_id
                         and ca.is_default = 'Y'
    ) ca on sum_ratio != 1
where true
  and ai.date_id = :l_date_id
--   and ai.dataset_id = :l_load_batch_id
  and ai.is_deleted = 'N'

drop table t_os
create temp table t_os (ids int[], txt text);

insert into t_os (ids, txt) values ('{1954227,1948382,1948459}'::int[], 'os'), ('{1948460,1947924,6}'::int[], 'so')

select t_os.*--, tr.*
from trade_record tr
join lateral (  select unnest(ids), txt from t_os where tr.trade_record_id = any(t_os.ids) ) t_os on true


select trade_record_id from trade_record
where trade_record_id = 1954227


with base as (select unnest(ids) as id, txt from t_os)
select * from base
join trade_record tr on tr.trade_record_id = base.id