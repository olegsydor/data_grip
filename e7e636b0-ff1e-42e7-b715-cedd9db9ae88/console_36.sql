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
    and TR.TRADE_RECORD_ID <= :l_max_trade_id

    and tr.order_id > 0 /* excluding Blaze originated Away trades */
    and (:in_allocation_type = 0
      or (:in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
      or (:in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
      OR (:in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
    and case  -- added DS-10061
            when :in_account_ids = '{}' then true
            when :in_account_ids is null then false
            else acc.account_id = any (:in_account_ids) end;




  drop table if exists trade_for_allocations;
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
       from t_tr tr
                 /* SY: Just to be sure clearing account already configured */
                 inner join genesis2.CLEARING_ACCOUNT CA on (CA.ACCOUNT_ID = TR.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                                             CA.MARKET_TYPE = :in_instrument_type_id and
                                                             CA.IS_DEFAULT = 'Y')
--                 inner join t_clearing_account_aa caa on caa.clearing_account_id = ca.clearing_account_id
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

    	GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;


    	select public.load_log(l_load_id, l_step_id, 'create temp table trade_for_allocations', l_cnt_rows, 'I')
		into l_step_id;

        create index on trade_for_allocations (alloc_instr_id);

    	select public.load_log(l_load_id, l_step_id, 'create index on table trade_for_allocations', 0, 'I')
		into l_step_id;

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

  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION', l_cnt_rows, 'I')
  into l_step_id;
  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job (removed default_ratio feature)
  -------------- DS-10191 Support multiple CMTA in auto-allocation and Options Allocation Configuration

    -- creating temp table for account_id with sum(allocatin_ratio) = 1 only
  create temp table t_clearing_account_aa  as
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
                  and ca.is_default = 'Y')
     , check_sum_ratio as (select account_id, sum(auto_alloc_ratio) as sum_ratio
                           from base
                           group by account_id
                           having sum(auto_alloc_ratio) = 1)
  select account_id, clearing_account_id, occ_actionable_id, clearing_account_number, cmta, auto_alloc_ratio
  from base
           join check_sum_ratio using (account_id);

create index on t_clearing_account_aa (account_id);

  select public.load_log(l_load_id, l_step_id, 'created temp table account created', l_cnt_rows, 'I')
  into l_step_id;

-- 2. insert into allocation_instruction_entry
  /*
  drop table if exists t_aie;
  create temp table t_aie on commit drop as
  with base as (select ai.alloc_instr_id,
                       max(clearing_account_id)                              as clearing_account_id,
                       ai.total_qty                                          as qty,
                       ca.occ_actionable_id
                from genesis2.allocation_instruction ai
                         inner join genesis2.clearing_account ca
                                    on (ca.account_id = ai.account_id and ca.is_deleted = 'N' and
                                        ca.market_type = in_instrument_type_id and ca.is_default = 'Y')
                where ai.date_id = l_date_id
                  and ai.dataset_id = l_load_batch_id
                  and ai.is_deleted = 'N'
                group by ai.alloc_instr_id, ai.total_qty, ca.occ_actionable_id
                )
  select alloc_instr_id,
         clearing_account_id,
         qty as alloc_qty,
         occ_actionable_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;
  */
execute 'SET enable_hashjoin = false';
	execute 'SET enable_mergejoin = false';
    drop table if exists t_aie;

create temp table base as
    select ai.alloc_instr_id,
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
                        order by ca.auto_alloc_ratio, ca.clearing_account_number desc, ca.clearing_account_id);
  create temp table t_aie as
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
                );
create index on base (alloc_instr_id, auto_alloc_ratio)
    create temp table t_aie as
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
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true
    ;


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
  from t_aie
where alloc_qty > 0;


  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION_ENTRY', l_cnt_rows, 'I')
  into l_step_id;


  insert into genesis2.alloc_instr2trade_record(TRADE_RECORD_ID, ALLOC_INSTR_ID, DATE_ID, dataset_id,
                                                allocation_instruction_entry_id)
  with base as (select unnest(trade_ids) as id,
                       ALLOC_INSTR_ID
--                       l_date_id as date_id,
--                       l_load_batch_id as batch_id
                from trade_for_allocations)
  select tr.id, tr.ALLOC_INSTR_ID, :l_date_id, :l_load_batch_id, aie.allocation_instruction_entry_id
  from base tr
           left join lateral ( select max(allocation_instruction_entry_id) as allocation_instruction_entry_id
                          from genesis2.allocation_instruction_entry aie
                          where aie.alloc_instr_id = tr.alloc_instr_id
                            and aie.date_id = :l_date_id
                          group by alloc_instr_id
                          having count(*) = 1 -- SO: to prevent adding multiple alloc_instr_entry_id
               ) aie on true
           where exists ( select null
                          from genesis2.allocation_instruction_entry aie
                          where aie.alloc_instr_id = tr.alloc_instr_id
                            and aie.date_id = :l_date_id
                          limit 1
               );


  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job
  -- End of the insertion into genesis2.allocation_instruction_entry


       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
       select public.load_log(l_load_id, l_step_id, 'insert into ALLOC_INSTR2TRADE_RECORD', l_cnt_rows, 'I')
	   into l_step_id;


	  /* ===================================================================================================================== */
	  /* Logic for Manual cleared trades */
	  /* ===================================================================================================================== */
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
                                left join lateral (select A.ALLOC_INSTR_ID
                                                   from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                                            inner join genesis2.ALLOCATION_INSTRUCTION A
                                                                       on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
                                                   where AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID
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
                         and (:in_allocation_type = 0
                           or (:in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
                           or (:in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
                           OR (:in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
                         and case -- added DS-10061
                                 when coalesce(:in_account_ids, '{}') = '{}' then true
                                 else acc.account_id = any (:in_account_ids) end
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
  select ALLOC_INSTR_ID, CLEARING_ACCOUNT_ID, TOTAL_QTY, :l_date_id, ca.occ_actionable_id
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
  where dataset_id = :l_load_batch_id
    and ai.date_id = :l_date_id
    and coalesce(ai.CREATED_BY_SUBSYSTEM_ID, 'RPS') <> 'RPS'
    and not exists (select null
                    from ALLOC_INSTR2TRADE_RECORD in_ai
                    where in_ai.trade_record_id = coalesce(cie.new_trade_record_id, cie.trade_record_id)
--                      and in_ai.alloc_instr_id = ai.alloc_instr_id
                      and in_ai.date_id = ai.date_id);

  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
  select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared insert into ALLOC_INSTR2TRADE_RECORD', l_cnt_rows, 'I')
  into l_step_id;

  update genesis2.ALLOCATION_INSTRUCTION
  set CREATED_BY_SUBSYSTEM_ID = 'RPS'
  where dataset_id = :l_load_batch_id
    and date_id = :l_date_id
    and coalesce(CREATED_BY_SUBSYSTEM_ID, 'RPS') <> 'RPS';

 		       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
		       select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared CREATED_BY_SUBSYSTEM_ID restored', l_cnt_rows, 'I')
			   into l_step_id;


/* We need that part because GET DIAGNOSTIC still doesn't work with partitioned tables */
  select count(1)
  from genesis2.alloc_instr2trade_record aitr
  where date_id = :l_date_id
    and dataset_id = :l_load_batch_id
  into l_cnt_rows;

select * from  genesis2.etl_subscribe(in_load_batch_id => :l_load_batch_id,
                                 in_row_cnt => 869664,
                                 in_subscription_name => 'allocation_to_big_data',
                                 in_source_table_name => 'genesis2.allocation_instruction',
                                 in_date_id => :l_date_id);

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
