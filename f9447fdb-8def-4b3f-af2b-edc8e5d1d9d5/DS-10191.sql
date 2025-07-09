-- DS-10191
alter table genesis2.clearing_account add column if not exists is_auto_alloc_to bpchar null;
alter table genesis2.clearing_account rename column default_alloc_ratio to auto_alloc_ratio;


-- function set
-- function get

-- DROP FUNCTION dash360.allocations_set_account_config(int8, text, bpchar, bpchar, int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_set_account_config(in_account_id bigint, in_clearing_accounts text, in_is_auto_allocate character DEFAULT NULL::character(1), in_instrumnt_type_id character DEFAULT 'O'::bpchar, in_user_id integer DEFAULT NULL::integer, in_is_intraday_auto_allocate character DEFAULT NULL::bpchar)
 RETURNS integer
 LANGUAGE plpgsql
 COST 1
AS $function$
    -- MG: 20210413 add support to is_option_auto_allocate field
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208 is_visible_for_manual_allocation  and user_id fields have been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable


declare
    l_clearing_account_type smallint;
    l_row_cnt               int;
    l_clearing_accounts jsonb;

begin
    l_clearing_accounts := in_clearing_accounts::jsonb;
    if in_instrumnt_type_id = 'E' and in_is_auto_allocate is not null
    then
-- set is_autoallocate value
        update account acc
        set is_auto_allocate = in_is_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
          and acc.is_auto_allocate <> in_is_auto_allocate;
    end if;

    if in_instrumnt_type_id = 'O' and in_is_auto_allocate is not null
    then
-- set is_option_auto_allocate value
        update account acc
        set is_option_auto_allocate = in_is_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
          and acc.is_option_auto_allocate <> in_is_auto_allocate;
    end if;

    if in_is_intraday_auto_allocate is not null then
        update account acc
        set is_intraday_auto_allocate = in_is_intraday_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
--           and acc.is_option_auto_allocate <> in_is_auto_allocate
        ;
    end if;


-- close all current configuration for the account if any

    update genesis2.clearing_account
    set is_deleted  = 'Y',
        delete_time = clock_timestamp(),
        user_id     = in_user_id
    where account_id = in_account_id
      and market_type = in_instrumnt_type_id
      and is_deleted = 'N';

    -- get  clearing_account_type

--  select case sum(case instrument_type_id when in_instrumnt_type_id then 1 else 0 end)
--          when 1 then count(1)
--          else 2 -- Temporary solution. For some reason account_id could be missed in account2instrument_type
--          end  as  clearing_account_type
--  into l_clearing_account_type
--  from staging.account2instrument_type ait
--  where account_id = in_account_id
--    and instrument_type_id  in ('E', 'O');

    -- Temporary logc SY:20201215 as per chat with Tim Miller
    l_clearing_account_type := 1;


    insert into genesis2.clearing_account (account_id, clearing_account_type, clearing_account_number, is_default,
                                           market_type, is_deleted, cmta, clearing_account_name, occ_actionable_id,
                                           user_id, is_visible_for_manual_allocation, auto_alloc_ratio, is_auto_alloc_to)
    select in_account_id,
           l_clearing_account_type::varchar,
           sj ->> 'ca_number'             as clearing_account_number,
           sj ->> 'def'                   as is_default,
           in_instrumnt_type_id           as market_type,
           --clock_timestamp() as  create_time,
           'N'                            as is_deleted,
           sj ->> 'ca_number'             as cmta,
           coalesce(sj ->> 'ca_name', '') as clearing_account_name,
           sj ->> 'oaid'                  as occ_actionable_id,
           in_user_id,
           (sj ->> 'visible')::bool       as is_visible_for_manual_allocation,
           coalesce((sj -> 'alloc_ratio')::numeric, 1),
           sj ->> 'auto_alloc_to'
    from (select value as sj
          from jsonb_array_elements(l_clearing_accounts)) l1;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    return l_row_cnt;

end;
$function$
;


-- DROP FUNCTION dash360.allocations_get_accounts_config(bpchar, _int8);

CREATE OR REPLACE FUNCTION dash360.allocations_get_accounts_config(in_market_type character DEFAULT 'O'::character(1), in_account_ids bigint[] DEFAULT '{}'::bigint[])
 RETURNS TABLE(account_id bigint, is_auto_allocate character, clearing_accounts jsonb, is_intraday_auto_allocate character)
 LANGUAGE plpgsql
 COST 1
AS $function$

    -- MG: 20210413 -- add is_option_auto_allocate field to output
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208   The is_visible_for_manual_allocation field has been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable
-- OS: 20250626 without ticket added new input parameter in_account_ids (back-end will call this procedure per account instead of cache)
begin
    return query
        select acc.account_id::bigint,
               (case
                    when in_market_type = 'E' then acc.is_auto_allocate
                    when in_market_type = 'O' then acc.is_option_auto_allocate
                    else acc.is_auto_allocate
                   end) as is_auto_allocate,
               jsonb_agg(jsonb_object(array ['ca_number', 'def' , 'ca_name', 'oaid', 'visible', 'alloc_ratio', 'auto_alloc_to'],
                                      array [ca.clearing_account_number, ca.is_default , ca.clearing_account_name, ca.occ_actionable_id, ca.is_visible_for_manual_allocation::text, ca.auto_alloc_ratio::text, ca.is_auto_alloc_to ])),
               acc.is_intraday_auto_allocate
        from genesis2.account acc
                 inner join genesis2.clearing_account ca
                            on acc.account_id = ca.account_id
                                and ca.is_deleted = 'N'
                                and ca.market_type = in_market_type
        where acc.is_deleted = 'N'
        and case when coalesce(in_account_ids, '{}') = '{}' then true else acc.account_id = any(in_account_ids) end
        group by acc.account_id,
                 (case
                      when in_market_type = 'E' then acc.is_auto_allocate
                      when in_market_type = 'O' then acc.is_option_auto_allocate
                      else acc.is_auto_allocate
                     end)
--limit 10
    ;

end;
$function$
;


-- DROP FUNCTION dash360.allocations_clearing_accounts_by_account_id(int8, bpchar);
CREATE OR REPLACE FUNCTION dash360.allocations_clearing_accounts_by_account_id(in_account_id bigint, in_market_type character)
 RETURNS TABLE(clearing_account_id integer, clearing_account_number character varying, clearing_account_name character varying, is_default character, clearing_account_type character, market_type character, cmta character varying, occ_actionable_id character varying, account_id integer, is_visible_for_manual_allocation boolean, auto_alloc_ratio numeric, is_auto_alloc_to bpchar)
 LANGUAGE plpgsql
 COST 1
AS $function$
    -- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208
-- SO: 20250610 https://dashfinancial.atlassian.net/browse/D360-15839
begin

    return query
        select ca.clearing_account_id::integer,
               ca.clearing_account_number,
               ca.clearing_account_name,
               ca.is_default::character,
               ca.clearing_account_type::character,
               ca.market_type::character,
               ca.cmta,
               ca.occ_actionable_id,
               ca.account_id,
               ca.is_visible_for_manual_allocation,
               ca.auto_alloc_ratio,
               ca.is_auto_alloc_to
        from genesis2.clearing_account ca
        where ca.account_id = in_account_id
          and ca.market_type = in_market_type
          and ca.is_deleted = 'N'
        order by ca.is_default desc, ca.clearing_account_number;

end;
$function$
;



CREATE or replace FUNCTION trash.auto_allocate_unallocated_trade(in_instrument_type_id character, in_allocation_type integer,
                                                         in_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                         in_account_ids integer[] DEFAULT '{}'::integer[])
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
--  SO:  20250630 https://dashfinancial.atlassian.net/browse/DS-10060 REMOVING support multiple default CTMAs in auto-allocation job
-- SY\SO: 20250704 performance improvement (add index to temp table with trade_records)

DECLARE

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

  drop table if exists t_tr;
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
            when in_account_ids = '{}' then true
            when in_account_ids is null then false
            else acc.account_id = any (in_account_ids) end;

    	GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

    	select public.load_log(l_load_id, l_step_id, 'create temp table TR', l_cnt_rows, 'I')
		into l_step_id;

  drop table if exists trade_for_allocations;
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
                 inner join genesis2.CLEARING_ACCOUNT CA on (CA.ACCOUNT_ID = TR.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                                             CA.MARKET_TYPE = in_instrument_type_id and
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

        create index on trade_for_allocations (alloc_instr_id);

    	select public.load_log(l_load_id, l_step_id, 'create index on table trade_for_allocations', 0, 'I')
		into l_step_id;

  create temp table t_clearing_account_aa on commit drop as
  select ca.clearing_account_id
  from genesis2.clearing_account ca
          left join genesis2.clearing_account aa on ca.account_id = aa.account_id and aa.is_auto_alloc_to
      where true
      and ca.is_deleted = 'N'
      and ca.market_type = in_instrument_type_id
      and ca.is_default = 'Y';

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
  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job (removed default_ratio feature)
  -------------- DS-10191 Support multiple CMTA in auto-allocation and Options Allocation Configuration


    -- creating temp table for account_id with sum(allocatin_ratio) = 1 only
  create temp table t_clearing_account_aa on commit drop as
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

    drop table if exists t_aie;
  create temp table t_aie on commit drop as
  with base as (select ai.alloc_instr_id,
                       clearing_account_id,
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
                where ai.date_id = l_date_id
                  and ai.dataset_id = l_load_batch_id
                  and ai.is_deleted = 'N'
                group by ai.date_id, ai.alloc_instr_id, ai.total_qty, ca.occ_actionable_id, ca.clearing_account_id,
                         ai.account_id, ca.auto_alloc_ratio
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
         l_date_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;


  -------------------------------------------------------------------------------------
  select public.load_log(l_load_id, l_step_id, 'created temp table', l_cnt_rows, 'I')
  into l_step_id;

  insert into genesis2.allocation_instruction_entry (alloc_instr_id, clearing_account_id, alloc_qty, date_id,
                                                     occ_actionable_id, allocation_instruction_entry_id)
  select alloc_instr_id,
         clearing_account_id,
         alloc_qty,
         l_date_id,
         occ_actionable_id,
         allocation_instruction_entry_id
  from t_aie;


  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION_ENTRY', l_cnt_rows, 'I')
  into l_step_id;


  insert into genesis2.alloc_instr2trade_record(TRADE_RECORD_ID, ALLOC_INSTR_ID, DATE_ID, dataset_id,
                                                allocation_instruction_entry_id)
  with base as (select unnest(trade_ids) as id,
                       ALLOC_INSTR_ID,
                       in_date_id as date_id,
                       l_load_batch_id as batch_id
                from trade_for_allocations)
  select tr.id, tr.ALLOC_INSTR_ID, in_date_id, l_load_batch_id, aie.allocation_instruction_entry_id
  from base tr
           join lateral ( select allocation_instruction_entry_id
                          from genesis2.allocation_instruction_entry aie
                          where aie.alloc_instr_id = tr.alloc_instr_id
                          group by allocation_instruction_entry_id
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
end
$function$
;
