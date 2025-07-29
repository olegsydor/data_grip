        select array_agg(account_id)
--        into l_account_ids
        from genesis2.account ac
        where true
          and ac.is_deleted = 'N'
          and ac.is_intraday_auto_allocate = 'Y'
          and ac.opt_report_to_mpid = 'MLCB';
--          and ac.account_id != all(in_removed_account_ids)


-- {262707,257077,257078}

        select *
        from dash360.bofa_allocation_report_wrapper(in_start_date_id => 20250716, in_end_date_id => 20250716,
                                                    in_is_eod => case when 'No' = 'Yes' then true else false end,
                                                    in_run_intraday_option_auto_allocation => case when 'Yes' = 'Yes' then true else false end,
                                                    in_exec_broker => '019');

select max(TRADE_RECORD_ID)  from TRADE_RECORD where is_busted='N' and date_id = :l_date_id
  into l_max_trade_id ; -- 2347374821


  drop table if exists t_tr;
  create temp table t_tr --on commit drop
  as
  select TR.ACCOUNT_ID,
         TR.INSTRUMENT_ID,
         TR.SIDE,
         TR.OPEN_CLOSE,

         acc.opt_is_fix_custfirm_processed,
         tr.market_participant_id,
         tr.compliance_id,
         tr.alternative_compliance_id,
         TR.LAST_PX,
         TR.LAST_QTY,
         tr.trade_record_id,
                  tr.cmta,
         tr.street_account_name,
         tr.clearing_account_number
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
    and case  -- added DS-10061
            when :in_account_ids = '{}' then true
            when :in_account_ids is null then false
            else acc.account_id = any (:in_account_ids) end
  and tr.trade_record_id in (2347378809)


select clearing_account_id, cmta, occ_actionable_id, clearing_account_number, is_default, *
from genesis2.clearing_account
where account_id = 257078
and is_deleted = 'N';
-269219


 create temp table t_clearing_account_aa on commit drop as
  with base as (select ca.account_id,
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
                  and ca.account_id = 257078
                  and ca.is_default = 'Y')
     , check_sum_ratio as (select account_id, sum(auto_alloc_ratio) as sum_ratio
                           from base
                           group by account_id
                           having sum(auto_alloc_ratio) = 1)
  select account_id, clearing_account_id, occ_actionable_id, clearing_account_number, cmta, auto_alloc_ratio
  from base
           join check_sum_ratio using (account_id);

select * from t_tr;

select * from allocation_instruction
where alloc_instr_id in (-81103, -81099);


select * from allocation_instruction_entry
where alloc_instr_id in (-81103, -81099);


    select * from genesis2.alloc_instr2trade_record
        where alloc_instr2trade_record.alloc_instr_id in (-81103, -81099);

            trade_record_id = 2347377318

  drop table if exists trade_for_allocations;
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
         --nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
  0 as alloc_instr_id
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
--         and TR.TRADE_RECORD_ID <= :l_max_trade_id
        group by TR.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, TR.OPEN_CLOSE, tr.cmta,
                 case tr.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id else null end,
                 case :in_allocation_type
                     when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                     else null end) L1;

    	select * from trade_for_allocations;

        create index on trade_for_allocations (alloc_instr_id);

ai = -80939, -80940


  insert into genesis2.ALLOCATION_INSTRUCTION(alloc_instr_id, DATE_ID, CREATE_TIME, ACCOUNT_ID, INSTRUMENT_ID, SIDE,
                                              OPEN_CLOSE, AVG_PX, TOTAL_QTY, CREATED_BY_SUBSYSTEM_ID, dataset_id)
  select tr.alloc_instr_id,
         :l_date_id,
         clock_timestamp(),
         TR.ACCOUNT_ID,
         TR.INSTRUMENT_ID,
         TR.SIDE,
         TR.OPEN_CLOSE,
         tr.AVG_PX,
         tr.TOTAL_QTY,
         'RPS',
         :l_load_batch_id
  from trade_for_allocations TR;

    -- creating temp table for account_id with sum(allocatin_ratio) = 1 only
  create temp table t_clearing_account_aa --on commit drop
        as
  with base as (select ca.account_id,
                       coalesce(aa.clearing_account_id, ca.clearing_account_id)         as clearing_account_id,
                       coalesce(aa.occ_actionable_id, ca.occ_actionable_id)             as occ_actionable_id,
                       coalesce(aa.clearing_account_number, ca.clearing_account_number) as clearing_account_number,
                       coalesce(aa.cmta, ca.cmta)                                       as cmta,
                       coalesce(aa.auto_alloc_ratio, 1)                                 as auto_alloc_ratio
--                 , aa.*
                from genesis2.clearing_account ca
                         left join genesis2.clearing_account aa
                                   on ca.account_id = aa.account_id and aa.is_auto_alloc_to = 'Y'
                                       and aa.is_deleted = 'N'
                                       and aa.market_type = 'O'
                where true
                  and ca.is_deleted = 'N'
                  and ca.market_type = 'O'
                  and ca.is_default = 'Y')
     , check_sum_ratio as (select account_id, sum(auto_alloc_ratio) as sum_ratio
                           from base
                           group by account_id
                           having sum(auto_alloc_ratio) = 1)
  select account_id, clearing_account_id, occ_actionable_id, clearing_account_number, cmta, auto_alloc_ratio
  from base
           join check_sum_ratio using (account_id);

select * from t_clearing_account_aa
    where account_id = 257077


    drop table if exists t_aie;
  create temp table t_aie --on commit drop
         as
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
                  and ai.dataset_id = :l_load_batch_id
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
             else qty - coalesce(lag(base.acc_rnd_sum)
                        over (partition by alloc_instr_id order by auto_alloc_ratio), 0) end  as alloc_qty,
--          rn,
--          qty as alloc_qty,
         occ_actionable_id,
--         l_date_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;

select * from t_aie;

  -------------------------------------------------------------------------------------
  select public.load_log(l_load_id, l_step_id, 'created temp table', l_cnt_rows, 'I')
  into l_step_id;

  insert into genesis2.allocation_instruction_entry (alloc_instr_id, clearing_account_id, alloc_qty, date_id,
                                                     occ_actionable_id, allocation_instruction_entry_id)
  select alloc_instr_id,
         clearing_account_id,
         alloc_qty,
         :l_date_id,
         occ_actionable_id,
         allocation_instruction_entry_id
  from t_aie;


  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION_ENTRY', l_cnt_rows, 'I')
  into l_step_id;


  insert into genesis2.alloc_instr2trade_record(TRADE_RECORD_ID, ALLOC_INSTR_ID, DATE_ID, dataset_id,
                                                allocation_instruction_entry_id)
  with base as (select unnest(trade_ids) as id,
                       ALLOC_INSTR_ID
                from trade_for_allocations)
  select tr.id, tr.ALLOC_INSTR_ID, :in_date_id, :l_load_batch_id, aie.allocation_instruction_entry_id
  from base tr
           left join lateral ( select max(allocation_instruction_entry_id) as allocation_instruction_entry_id
                          from genesis2.allocation_instruction_entry aie
                          where aie.alloc_instr_id = tr.alloc_instr_id
                          group by alloc_instr_id
                          having count(*) = 1 -- SO: to prevent adding multiple alloc_instr_entry_id
               ) aie on true;


  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job
  -- End of the insertion into genesis2.allocation_instruction_entry


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


  ---
-- OCC019
  select street_account_name, clearing_account_number, * from trade_record
  where trade_record_id = 2347374975;

    with base as (select ca.account_id,
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
                and ca.account_id = 257077)
     , check_sum_ratio as (select account_id, sum(auto_alloc_ratio) as sum_ratio
                           from base
                           group by account_id
                           having sum(auto_alloc_ratio) = 1)

select * from genesis2.alloc_instr2trade_record
    where TRADE_RECORD_ID in (2347377616, 2347377627);


  with main_source as (select :l_date_id                                                                       as date_id,
                              clock_timestamp()                                                               as CREATE_TIME,
                              man_clear.ACCOUNT_ID,
                              TR.INSTRUMENT_ID,
                              TR.SIDE,
                              man_clear.OPEN_CLOSE,
                              round(sum(man_clear.LAST_PX * man_clear.LAST_QTY) / sum(man_clear.LAST_QTY), 6) as AVG_PX,
                              sum(man_clear.LAST_QTY)                                                         as TOTAL_QTY,
                              man_clear.clearing_account_id,
                              :l_load_batch_id                                                                 as load_batch_id
                       from genesis2.TRADE_RECORD TR
                                inner join genesis2.ACCOUNT ACC on (ACC.ACCOUNT_ID = TR.ACCOUNT_ID)
                           /* SY: Just to be sure clearing account already configured */
                                inner join genesis2.CLEARING_ACCOUNT CA
                                           on (CA.ACCOUNT_ID = ACC.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                               CA.MARKET_TYPE = :in_instrument_type_id and CA.IS_DEFAULT = 'Y')
                                inner join genesis2.INSTRUMENT I on (TR.INSTRUMENT_ID = I.INSTRUMENT_ID)
                           /* We need to exclude manual allocations and already autoallocated trades */
                                left join lateral (select A.ALLOC_INSTR_ID, at.trade_record_id
                                                   from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                                            inner join genesis2.ALLOCATION_INSTRUCTION A
                                                                       on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
                                                   where true
                       and AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID
                                             and AT.TRADE_RECORD_ID in (2347377616)--, 2347377627)
                                                  limit 1) AA on true
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
                                                                           inner_ca.market_type = :in_instrument_type_id
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
                       where TR.DATE_ID = :l_date_id
                         and TR.IS_BUSTED = 'N'
--        and ACC.IS_AUTO_ALLOCATE = 'Y'
                         and case :in_instrument_type_id
                                 when 'E' then ACC.IS_AUTO_ALLOCATE
                                 else ACC.IS_OPTION_AUTO_ALLOCATE
                                 end = 'Y'
                         and I.INSTRUMENT_TYPE_ID = :in_instrument_type_id
                         and tr.order_id > 0 /* excluding Blaze originated Away trades */
                         and ((:in_instrument_type_id = 'O' and coalesce(ACC.OPT_REPORT_TO_MPID, 'NONE') <> 'NONE') or
                              (:in_instrument_type_id = 'E' and coalesce(ACC.EQ_REPORT_TO_MPID, 'NONE') <> 'NONE'))
                         and AA.ALLOC_INSTR_ID is null
                         and TR.TRADE_RECORD_ID <= :l_max_trade_id
                         and TR.TRADE_RECORD_ID in (2347377616, 2347377627)
                         and (:in_allocation_type = 0
                           or (:in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
                           or (:in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
                           OR (:in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
--                          and case -- added DS-10061
--                                  when coalesce(:in_account_ids, '{}') = '{}' then true
--                                  else acc.account_id = any (:in_account_ids) end
                       group by man_clear.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, man_clear.OPEN_CLOSE,
                                man_clear.clearing_account_id)

--        ins_all_in as ( insert into genesis2.ALLOCATION_INSTRUCTION (DATE_ID, CREATE_TIME, ACCOUNT_ID, INSTRUMENT_ID,
--                                                                     SIDE, OPEN_CLOSE, AVG_PX, TOTAL_QTY,
--                                                                     CREATED_BY_SUBSYSTEM_ID, dataset_id)
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

  select coalesce(cie.new_trade_record_id, cie.trade_record_id), aie.ALLOC_INSTR_ID, :l_date_id, :l_load_batch_id, aie.allocation_instruction_entry_id
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
  where true
--     and dataset_id = l_load_batch_id
--     and ai.date_id = l_date_id
  and   ai.alloc_instr_id in (-81112, -81113)



        select *
--             coalesce(cie.new_trade_record_id, cie.trade_record_id),
--                aie.ALLOC_INSTR_ID,
--                :l_date_id,
--                :l_load_batch_id,
--                aie.allocation_instruction_entry_id,
--                ai.CREATED_BY_SUBSYSTEM_ID
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
                                and
                               nullif(cie.street_account_name, '') is not distinct from nullif(ca.occ_actionable_id, '')
                                and nullif(cie.cmta, '') is not null
                 inner join genesis2.clearing_instruction ci
                            on cie.clearing_instr_id = ci.clearing_instr_id and ci.status = 'D' and
                               ci.date_id = cie.date_id
                 inner join genesis2.trade_record tr
                            on (coalesce(cie.new_trade_record_id, cie.trade_record_id) = tr.trade_record_id
                                and cie.date_id = tr.date_id
                                and tr.is_busted = 'N'
                                and ai.side = tr.side
                                and ai.instrument_id = tr.instrument_id
                                and ai.open_close = tr.open_close)
        where dataset_id = :l_load_batch_id
          and ai.date_id = :l_date_id
    and coalesce(ai.CREATED_BY_SUBSYSTEM_ID, 'RPS') <> 'RPS'
--           and not exists (select null
--                           from ALLOC_INSTR2TRADE_RECORD in_ai
--                           where in_ai.trade_record_id = coalesce(cie.new_trade_record_id, cie.trade_record_id)
--                             and in_ai.alloc_instr_id = ai.alloc_instr_id
--                             and in_ai.date_id = ai.date_id);



select last_qty, * from genesis2.alloc_instr2trade_record aitr
         join genesis2.trade_record tr using (trade_record_id, date_id)
where alloc_instr_id in (-81583);

select * from genesis2.allocation_instruction_entry
where alloc_instr_id in (-81583);

select * from genesis2.allocation_instruction
where alloc_instr_id = -81583;


select ai.alloc_instr_id, aie.*, aitr.*
from genesis2.allocation_instruction ai
         join lateral (
    select array_agg(trade_record_id) as trade_id,
           array_agg(last_qty) as trade_qty
    from genesis2.alloc_instr2trade_record aitr
             join genesis2.trade_record tr using (trade_record_id, date_id)
    where aitr.alloc_instr_id = ai.alloc_instr_id
      and aitr.date_id = ai.date_id
      and aitr.allocation_instruction_entry_id is null
      and tr.is_busted = 'N'
    limit 1) aitr on true
         join lateral (select array_agg(aie.allocation_instruction_entry_id) as alloc_id,
                              array_agg(alloc_qty)                           as alloc_qty
                       from genesis2.allocation_instruction_entry aie
                       where aie.date_id = ai.date_id
                         and aie.alloc_instr_id = ai.alloc_instr_id
                       limit 1) aie on true
         join instrument i on ai.instrument_id = i.instrument_id and i.instrument_type_id = 'O'
where true
--     and ai.date_id = 20250718
  and ai.created_by_subsystem_id = 'RPS'
  and ai.is_deleted = 'N'
and ai.alloc_instr_id = -81413;


-- DROP FUNCTION dash360.bofa_allocation_report(int4, int4, text, bool, _int4);

CREATE OR REPLACE FUNCTION dash360.bofa_allocation_report(in_start_date_id integer, in_end_date_id integer, in_exec_broker text, in_is_eod boolean DEFAULT false, in_removed_account_ids integer[] DEFAULT '{62939,263022,62810,62887,62923,63787,67949}'::integer[])
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
    -- 20241224 SO https://dashfinancial.atlassian.net/browse/DS-9237
    -- The main function based on dash360.report_rps_ml_options_cmta for aggregating data intraday only (if in_is_eod = false)
    -- and both intraday and EOD (if in_is_eod = true) and saving data into the dash_reporting.bofa_allocation_report for intraday
    -- and dash_reporting.bofa_trade_record for EOD
    -- 20250116 SO https://dashfinancial.atlassian.net/browse/DS-9313 add subscriptions
    -- 20250214 SO https://dashfinancial.atlassian.net/browse/DS-9590 add in_removed_account_ids - list of accounts ignored during intraday
    -- 20250218 SO https://dashfinancial.atlassian.net/browse/D360-15295 removed condition order_id > 0 in the EOD part (about 290 row)
    -- 20250403 SO https://dashfinancial.atlassian.net/browse/D360-15560 account_id 62939 was added to the list of account_ids excluded from the intradey process.
    --          account_id 263022 is for UAT flow and added in all scripts for compatibility
    -- 20250722 SO https://dashfinancial.atlassian.net/browse/DS-10237 saving the reported data into the table to avoid missing report
declare
    l_load_id                 int;
    l_step_id                 int;
    l_alloc_instr_id_reported int4[];
    l_alloc_instr_id          int4[];
    l_row_cnt                 int4;
    l_row_cnt_eod             int4;
    l_msg_text                text;
    l_start_row               int4;

begin
    l_msg_text := 'bofa_allocation_report ' ||
                  case when in_is_eod then 'EOD ' else 'intraday ' end ||
                  in_start_date_id::text || '-' || in_end_date_id::text ||
                  ' for ' || case when in_exec_broker is null then 'all exec brokers' else in_exec_broker end || ':';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data STARTED ====', 0, 'O')
    into l_step_id;

    -- PART 1. Collecting intraday data
    -- get the list of all alloc_instr_id_reported in the chain of the reported records;
    select array_agg(alloc_instr_id)
    into l_alloc_instr_id_reported
    from dash_reporting.bofa_allocation_report
    where date_id between in_start_date_id and in_end_date_id
      and to_report = 'R';


    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instructions collected',
                           coalesce(array_length(l_alloc_instr_id_reported, 1), 0), 'O')
    into l_step_id;

-- insert into the table
    with base_ins as (
        insert into dash_reporting.bofa_allocation_report
            (alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty, opt_is_fix_clfirm_processed,
             ftr_cmta, ca_cmta, opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm,
             occ_actionable_id, dataset, instrument_id, opt_penny_commission, opt_nickel_commission, root_symbol,
             min_tick_increment, put_call, maturity_year, maturity_month, maturity_day, strike_price, to_report)
            select alin.alloc_instr_id,
                   alin.side,
                   alin.avg_px,
                   alin.date_id,
                   alin.open_close,
                   ae.alloc_qty,
                   acc.opt_is_fix_clfirm_processed,
                   ftr.cmta,                 -- ftr_cmta,
                   ca.cmta,                  -- ca_cmta,
                   acc.opt_is_fix_custfirm_processed,
                   ftr.opt_customer_firm,
                   acc.opt_customer_or_firm,
                   ae.occ_actionable_id,     -- occ_actionable_id,
                   l_load_id,                -- dataset,
                   alin.instrument_id,
                   acc.opt_penny_commission, -- numeric(12, 4)
                   acc.opt_nickel_commission,-- numeric(12, 4)
                   os.root_symbol,
                   os.min_tick_increment,
                   oc.put_call,
                   oc.maturity_year,
                   oc.maturity_month,
                   oc.maturity_day,
                   oc.strike_price,
                   case
                       when ar.date_id is not null then 'C' --'skip - current alloc_instr_id'
                       when or_ai.alloc_instr_ids && l_alloc_instr_id_reported
                           then 'U' -- 'unable to report - alloc_instr_id has been reported before'
                       else 'R' end as to_report
            from genesis2.allocation_instruction_entry ae
                     join genesis2.allocation_instruction alin
                          on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
                     left join lateral (select alloc_instr_ids
                                        from staging.get_all_alloc_instr_id_for_orig(alin.alloc_instr_id,
                                                                                     alin.date_id) as x(alloc_instr_ids)
                                        limit 1) or_ai on true
                     inner join lateral (select tr.cmta,
                                                tr.opt_customer_firm
                                         from genesis2.alloc_instr2trade_record aitr
                                                  inner join genesis2.trade_record tr
                                                             on aitr.trade_record_id = tr.trade_record_id
                                                                 and aitr.date_id = tr.date_id
                                                                 and tr.is_busted = 'N'
                                                                 and tr.exec_broker = in_exec_broker
                                                                 and tr.exec_broker is not null
                                         where aitr.alloc_instr_id = alin.alloc_instr_id
                                           and aitr.date_id = alin.date_id
                                         limit 1
                ) ftr on true
                     join genesis2.clearing_account ca
                          on (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                              and ca.clearing_account_type = '1' and ca.market_type = 'O')
                     join genesis2.account acc ON (acc.account_id = ca.account_id and acc.is_deleted <> 'Y'
                and acc.opt_report_to_mpid = 'MLCB'
                and acc.trading_firm_id <> 'cantor'
                and case when in_is_eod then true else acc.account_id != all (in_removed_account_ids) end
                )
                     join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
                     join genesis2.option_series os on os.option_series_id = oc.option_series_id
                     join genesis2.instrument i on i.instrument_id = alin.instrument_id
                     left join lateral (select ar.date_id
                                        from dash_reporting.bofa_allocation_report ar
                                        where ar.alloc_instr_id = ae.alloc_instr_id
                                          and to_report = 'R'
                                        limit 1) ar on true
            where alin.date_id between in_start_date_id and in_end_date_id
              and not exists (select null
                              from dash_reporting.bofa_allocation_report ar
                              where ar.alloc_instr_id = ae.alloc_instr_id
                                and ar.side = alin.side
                                and ar.date_id = alin.date_id)
            returning alloc_instr_id)
    select array_agg(distinct alloc_instr_id)
    into l_alloc_instr_id
    from base_ins;

    select array_length(l_alloc_instr_id, 1) into l_row_cnt;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instructions added',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

    -- Subscription (for ONLY THESE trade_record_id with  R in alloc_instr_id)
    perform genesis2.etl_subscribe(in_load_batch_id => l_load_id,
                                   in_row_cnt=>coalesce(l_row_cnt, 0),
                                   in_subscription_name => 'trade_record',
                                   in_source_table_name => 'bofa_allocation_report',
                                   in_date_id => in_start_date_id);

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' subscriptions sent', coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

    --  PART 2. Printing the report for intraday

    insert into staging.bofa_allocation_report_history(report_row, dataset, report_part)
        select array_to_string(ARRAY [
                                   'DAS' , ----Branch
                                   CASE
                                       WHEN gen.side = '1' THEN 'B'
                                       WHEN gen.side in ('2', '5', '6') THEN 'S'
                                       ELSE 'S'
                                       END , ----Action
                                   '' , ----Symbol
                                   '?' , ----Destination
                                   gen.alloc_qty::text , ----Quantity
                                   to_char(gen.avg_px, 'FM99990D009999') , --
                                   CASE
                                       WHEN gen.opt_is_fix_clfirm_processed = 'Y' THEN lpad(ftr_cmta, 5, '0')
                                       WHEN gen.opt_is_fix_clfirm_processed = 'N' THEN lpad(ca_cmta, 5, '0')
                                       END, --
                                   SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 5, 2) || '/' ||
                                   SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 7, 2) || '/' ||
                                   SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 3, 2) || '/' ||
                                   '00/00' , --
                                   'DASH' , ----Execution Venue
--		street_account_name ||','||--Client Identifier
                                   gen.occ_actionable_id , ----Client Identifier
                                   to_char(row_number() OVER (), 'FM0000') , --
                                   to_char(((CASE coalesce(gen.min_tick_increment, 0.01)
                                                 WHEN 0.01 THEN gen.opt_penny_commission
                                                 WHEN 0.05 THEN gen.opt_nickel_commission END) * gen.alloc_qty),
                                           'FM99990D0') , ----13
                                   '' , ----Liquidity
                                   'S' , ----Single/Basket
                                   '' , ----Pass Through Fees
                                   gen.root_symbol, ----Symbol
                                   CASE
                                       WHEN gen.put_call = '0' THEN 'P'
                                       WHEN gen.put_call = '1' THEN 'C'
                                       END , ----Put/Call
                                   gen.maturity_year::text , --
                                   to_char(gen.maturity_month, 'FM00') , --
                                   to_char(gen.MATURITY_DAY, 'FM00') , --
                                   to_char(gen.strike_price, 'FM999990D0099') , ----Strike
                                   gen.open_close , --
                                   CASE (CASE gen.opt_is_fix_custfirm_processed
                                             WHEN 'Y' THEN coalesce(gen.opt_customer_firm, gen.opt_customer_or_firm)
                                             ELSE gen.opt_customer_or_firm END)
                                       WHEN '0' THEN 'C'
                                       WHEN '1' THEN 'F'
                                       WHEN '2' THEN 'F'
                                       WHEN '3' THEN 'C'
                                       WHEN '4' THEN 'M'
                                       WHEN '5' THEN 'M'
                                       WHEN '7' THEN 'F'
                                       WHEN '8' THEN 'C'
                                       END,
                                   null,
                                   null
                                   ], ',', ''),
                   l_load_id, 'A'
        from dash_reporting.bofa_allocation_report gen
        where dataset = l_load_id
          and to_report = 'R';
    get diagnostics l_start_row = row_count;
    return query
        select report_row as ret_row
        from staging.bofa_allocation_report_history
        where dataset = l_load_id
          and report_part = 'A';

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' intraday reporting completed',
                           coalesce(l_start_row, 0), 'O')
    into l_step_id;


    -- PART 3. Printing the report for EOD
    if in_is_eod then
        -- list of reported alloc_instr_id
        l_alloc_instr_id_reported := '{}'::int4[];
        select array_agg(ba.alloc_instr_id)
        into l_alloc_instr_id_reported
        from dash_reporting.bofa_allocation_report ba
        where ba.date_id between in_start_date_id and in_end_date_id
          and ba.to_report in ('R');

        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD instructions calculated',
                               coalesce(array_length(l_alloc_instr_id_reported, 1), 0), 'O')
        into l_step_id;

        -- list of trade records from reported alloc_instr_id
        drop table if exists t_trade_record_reported;
        create temp table t_trade_record_reported as
        select tr.trade_record_id, tr.date_id, aitr.alloc_instr_id
        from genesis2.trade_record tr
                 join genesis2.alloc_instr2trade_record aitr
                      on tr.trade_record_id = aitr.trade_record_id and aitr.date_id = tr.date_id
        where aitr.alloc_instr_id = any (l_alloc_instr_id_reported);
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD trade_records calculated', l_row_cnt, 'O')
        into l_step_id;

        drop table if exists t_trade_record_to_exclude;
        create temp table t_trade_record_to_exclude as
        select aitr.trade_record_id, aitr.date_id, aitr.alloc_instr_id
        from genesis2.alloc_instr2trade_record aitr
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = aitr.alloc_instr_id and ai.date_id = aitr.date_id
                 join genesis2.trade_record tr
                      on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
        where aitr.date_id between in_start_date_id and in_end_date_id
          and ai.is_deleted = 'N'
          and tr.exec_broker = in_exec_broker;
        get diagnostics l_row_cnt = row_count;
        create index on t_trade_record_to_exclude (trade_record_id);
        analyze t_trade_record_to_exclude;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD excluded trade_records calculated', l_row_cnt,
                               'O')
        into l_step_id;
        -- find all valid trade_records: all except the records from the prev

        drop table if exists t_trade_record_to_report;
        create temp table t_trade_record_to_report as
        SELECT ftr.date_id           AS date_id,
               ftr.trade_record_id,
               l_load_id             as dataset,
               CASE
                   WHEN acc.opt_is_fix_clfirm_processed = 'Y' THEN ftr.cmta
                   ELSE NULL END     AS cmta,
               ftr.open_close,
               ftr.order_id          AS order_id,
               ftr.instrument_id,
               ftr.account_id,
               ftr.side,
               ftr.last_qty          AS last_qty,
               ftr.last_px           AS last_px,
               ftr.opt_customer_firm as opt_customer_firm,
               0                     AS is_cleared,
               acc.opt_is_fix_clfirm_processed,
               acc.opt_customer_or_firm,
               acc.opt_nickel_commission,
               acc.opt_penny_commission,
               acc.opt_is_fix_custfirm_processed,
               case
                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_reported trr
                                                                     where trr.trade_record_id = ftr.trade_record_id)
                       then 'U'
                   when ftr.orig_trade_record_id is null then 'R'
                   when exists (select null
                                from t_trade_record_reported rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'U'
                   else 'R' end      as to_report,
               case

                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_to_exclude tre
                                                                     where tre.trade_record_id = ftr.trade_record_id)
                       then 'D'
                   when ftr.orig_trade_record_id is null then null
                   when exists (select null
                                from t_trade_record_to_exclude rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'D' end  as to_del
        FROM genesis2.trade_record ftr
                 join genesis2.instrument gi on gi.instrument_id = ftr.instrument_id
                 JOIN genesis2.account acc ON (acc.account_id = ftr.account_id)
                 left join t_trade_record_to_exclude tex
                           on tex.trade_record_id = ftr.trade_record_id and tex.date_id = ftr.date_id
        WHERE ftr.date_id between in_start_date_id and in_end_date_id
          AND is_busted = 'N'
--          AND ftr.order_id > 0
          and gi.instrument_type_id = 'O'
          and ftr.exec_broker = in_exec_broker
          and tex.trade_record_id is null
          and acc.is_deleted <> 'Y'
          AND acc.opt_report_to_mpid = 'MLCB'
          AND acc.trading_firm_id <> 'cantor'
        --           and not exists (select null
--                           from t_trade_record_to_exclude rp
--                           where rp.trade_record_id = any
--                                 (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
        ;
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD temp table t_trade_record_to_report created',
                               l_row_cnt, 'O')
        into l_step_id;

        insert into dash_reporting.bofa_trade_record (date_id, trade_record_id, dataset, to_report)
        select date_id, trade_record_id, dataset, to_report
        from t_trade_record_to_report
        where to_del is null;
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD inserted into into bofa_trade_record',
                               l_row_cnt, 'O')
        into l_step_id;
        -- Subscription
        perform genesis2.etl_subscribe(in_load_batch_id => l_load_id,
                                       in_row_cnt=>coalesce(l_row_cnt, 0),
                                       in_subscription_name => 'trade_record',
                                       in_source_table_name => 'bofa_trade_record',
                                       in_date_id => in_start_date_id);

        drop table if exists t_ftr;
        create temp table t_ftr as
        SELECT rtr.date_id,
               rtr.cmta,
               rtr.open_close,
               rtr.order_id,
               rtr.instrument_id,
               rtr.side,
               sum(rtr.last_qty)                                                AS day_cum_qty,
               CASE sum(rtr.last_qty)
                   WHEN 0 THEN NULL
                   ELSE sum(rtr.last_qty * rtr.last_px) / sum(rtr.last_qty) END AS avg_px,
               max(rtr.opt_customer_firm)                                       AS customer_or_firm_id,
               rtr.opt_is_fix_clfirm_processed,
               rtr.opt_customer_or_firm,
               rtr.opt_nickel_commission,
               rtr.opt_penny_commission,
               rtr.opt_is_fix_custfirm_processed
/*,
       max(street_account_name) as street_account_name*/
        FROM t_trade_record_to_report rtr
        where date_id between in_start_date_id and in_end_date_id
          and to_report = 'R'
          and to_del is null
        group by rtr.date_id, rtr.cmta, rtr.open_close, rtr.order_id, rtr.instrument_id, rtr.side,
                 rtr.opt_is_fix_clfirm_processed, rtr.opt_customer_or_firm,
                 rtr.opt_nickel_commission, rtr.opt_penny_commission,
                 rtr.opt_is_fix_custfirm_processed;
        get diagnostics l_row_cnt_eod = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD reporting table for trade_record created',
                               l_row_cnt_eod,
                               'O')
        into l_step_id;

        insert into staging.bofa_allocation_report_history(report_row, dataset, report_part)

            SELECT array_to_string(ARRAY [
                                       'DAS' , ----Branch
                                       CASE
                                           WHEN ftr.SIDE = '1' THEN 'B'
                                           WHEN ftr.SIDE in ('2', '5', '6') THEN 'S'
                                           ELSE 'S' END , ----Action
                                       '' , ----Symbol
                                       '?' , ----Destination
                                       ftr.day_cum_qty::text , ----Quantity
                                       to_char(ftr.avg_px, 'FM99990D009999') , ----Avg. Price
                                       COALESCE(lpad(ftr.cmta, 5, '0'), '') , -- -- CMTA
                                       SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 5, 2) || '/' ||
                                       SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 7, 2) || '/' ||
                                       SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 3, 2) || '/' ||
                                       '00/00' , --
                                       'DASH' , ----Execution Venue
--		ftr.street_account_name ||','||--Client Identifier
                                       '' , ----Client Identifier
                                       to_char(row_number() OVER () + l_start_row, 'FM0000') , --
                                       to_char(((CASE coalesce(OS.MIN_TICK_INCREMENT, 0.01)
                                                     WHEN 0.01 THEN ftr.OPT_PENNY_COMMISSION
                                                     WHEN 0.05 THEN ftr.OPT_NICKEL_COMMISSION END) * ftr.day_cum_qty),
                                               'FM99990D0') , ----13
                                       '' , ----Liquidity
                                       'S' , ----Single/BASket
                                       '' , ----PASs Through Fees
                                       COALESCE(OS.ROOT_SYMBOL, '') , ----Symbol
                                       CASE WHEN OC.PUT_CALL = '0' THEN 'P' WHEN OC.PUT_CALL = '1' THEN 'C' END , ----Put/Call
                                       OC.MATURITY_YEAR::text , --
                                       to_char(OC.maturity_month, 'FM00') , --
                                       to_char(OC.MATURITY_DAY, 'FM00') , --
                                       to_char(OC.STRIKE_PRICE, 'FM999990D0099') , ----Strike
                                       ftr.open_close , --
                                       CASE (CASE ftr.OPT_IS_FIX_CUSTFIRM_PROCESSED
                                                 WHEN 'Y'
                                                     THEN coalesce(ftr.CUSTOMER_OR_FIRM_ID, ftr.OPT_CUSTOMER_OR_FIRM)
                                                 ELSE ftr.OPT_CUSTOMER_OR_FIRM END)
                                           WHEN '0' THEN 'C'
                                           WHEN '1' THEN 'F'
                                           WHEN '2' THEN 'F'
                                           WHEN '3' THEN 'C'
                                           WHEN '4' THEN 'M'
                                           WHEN '5' THEN 'M'
                                           WHEN '7' THEN 'F'
                                           WHEN '8' THEN 'C'
                                           END,
                                       null,
                                       null
                                       ], ',', ''),
                l_load_id, 'T'
            FROM t_ftr AS ftr
                     INNER JOIN genesis2.option_contract oc ON (oc.instrument_id = ftr.instrument_id)
                     INNER JOIN genesis2.option_series os ON (os.option_series_id = oc.option_series_id)
--                      INNER JOIN genesis2.instrument gi ON (gi.instrument_id = ftr.instrument_id)
        ;
    return query
        select report_row as ret_row
        from staging.bofa_allocation_report_history
        where dataset = l_load_id
          and report_part = 'T';

        get diagnostics l_row_cnt_eod = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD reporting for TR completed', l_row_cnt_eod,
                               'O')
        into l_step_id;
    end if;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' FINISHED ========', l_row_cnt + l_row_cnt_eod, 'O')
    into l_step_id;


end;
$function$
;

COMMENT ON FUNCTION dash360.bofa_allocation_report(int4, int4, text, bool, _int4) IS 'The main function based on dash360.report_rps_ml_options_cmta for aggregating data intraday only (if in_is_eod = false)
and both intraday and EOD (if in_is_eod = true) and saving data into the dash_reporting.bofa_allocation_report for intraday
and dash_reporting.bofa_trade_record for EOD';

