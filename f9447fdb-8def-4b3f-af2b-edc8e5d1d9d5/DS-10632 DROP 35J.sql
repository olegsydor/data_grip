
alter table genesis2.clearing_account add column if not exists sg_brid varchar;
comment on column genesis2.clearing_account.sg_brid is 'SG allocation field used for populating tag in 35=J. Copy from SG_ACCOUNT value';

alter table genesis2.clearing_account add column if not exists sg_sub_account_name varchar;
comment on column genesis2.clearing_account.sg_brid is 'SG allocation field used for populating tag in 35=J. Copy from SG_ACCOUNT value';

create or replace function dash360.get_data_for_allocations(in_alloc_instr_id int8, in_date_id int4 default null)
    returns jsonb
    language plpgsql
as
$fx$
    -- 20251027 SO https://dashfinancial.atlassian.net/browse/DS-10634
declare
    l_return_jsonb jsonb;
begin
    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'side', ai.side,
                                                  'symbol', di.symbol,
                                                  'secType',
                                                  case when di.instrument_type_id = 'O' then 'OPT' else 'ES' end,
                                                  'putOrCall',
                                                  case when di.instrument_type_id = 'O' then oc.put_call end,
                                                  'strikePx',
                                                  case when di.instrument_type_id = 'O' then oc.strike_price end,
                                                  'maturityDay',
                                                  case
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
                                                  'allocationEntries', aie.entries
                               )
    from genesis2.allocation_instruction ai
             join genesis2.instrument di on di.instrument_id = ai.instrument_id
             join lateral (select count(*)                                              as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'brid', ca.sg_brid,
                                                               'subAccount', ca.sg_sub_account_name,
                                                               'individualAllocID', aie.allocation_instruction_entry_id))
                                      as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.clearing_account ca
                                         on (ca.clearing_account_id = aie.clearing_account_id
--                                                  and ca.clearing_account_type = '1'
--                                                  and ca.market_type = di.instrument_type_id
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
                             and is_busted = 'N'
                           limit 1) aitr on true

             left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
             left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = in_alloc_instr_id
      and case when in_date_id is null then true else ai.date_id = in_date_id end;
    return l_return_jsonb;
end;
$fx$;

select alloc_instr_id, dash360.get_data_for_allocations(ai.alloc_instr_id, ai.date_id)
from genesis2.allocation_instruction ai
where date_id = 20251023;


select dash360.get_data_for_allocations(-99683, 20251023);
select dash360.get_data_for_allocations(-99683);



comment on column genesis2.clearing_account.clearing_account_type is '0: DVP,1: CMTA,2: Domicile,3: Non-allocated';


-- DROP FUNCTION dash360.allocations_get_accounts_config(bpchar, _int8);

CREATE OR REPLACE FUNCTION dash360.allocations_get_accounts_config(in_market_type character DEFAULT 'O'::character(1),
                                                                   in_account_ids bigint[] DEFAULT '{}'::bigint[])
    RETURNS TABLE
            (
                account_id                bigint,
                is_auto_allocate          character,
                clearing_accounts         jsonb,
                is_intraday_auto_allocate character

            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- MG: 20210413 -- add is_option_auto_allocate field to output
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208   The is_visible_for_manual_allocation field has been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable
-- OS: 20250626 without ticket added new input parameter in_account_ids (back-end will call this procedure per account instead of cache)
-- OS: 20251031 https://dashfinancial.atlassian.net/browse/DS-10634 added 'sg_brid', 'sg_sub_account_name'
begin
    return query
        select acc.account_id::bigint,
               (case
                    when in_market_type = 'E' then acc.is_auto_allocate
                    when in_market_type = 'O' then acc.is_option_auto_allocate
                    else acc.is_auto_allocate
                   end) as is_auto_allocate,
               jsonb_agg(jsonb_object(
                       array ['ca_number', 'def' , 'ca_name', 'oaid', 'visible', 'alloc_ratio', 'auto_alloc_to', 'sg_brid', 'sg_sub_account_name'],
                       array [ca.clearing_account_number, ca.is_default , ca.clearing_account_name, ca.occ_actionable_id, ca.is_visible_for_manual_allocation::text, ca.auto_alloc_ratio::text, ca.is_auto_alloc_to, ca.sg_brid, ca.sg_sub_account_name ])),
               acc.is_intraday_auto_allocate
        from genesis2.account acc
                 inner join genesis2.clearing_account ca
                            on acc.account_id = ca.account_id
                                and ca.is_deleted = 'N'
                                and ca.market_type = in_market_type
        where acc.is_deleted = 'N'
          and case when coalesce(in_account_ids, '{}') = '{}' then true else acc.account_id = any (in_account_ids) end
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


-- DROP FUNCTION dash360.allocations_set_account_config(int8, text, bpchar, bpchar, int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_set_account_config(in_account_id bigint, in_clearing_accounts text, in_is_auto_allocate character DEFAULT NULL::character(1), in_instrumnt_type_id character DEFAULT 'O'::bpchar, in_user_id integer DEFAULT NULL::integer, in_is_intraday_auto_allocate character DEFAULT NULL::bpchar)
 RETURNS integer
 LANGUAGE plpgsql
 COST 1
AS $function$
    -- MG: 20210413 add support to is_option_auto_allocate field
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208 is_visible_for_manual_allocation  and user_id fields have been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable
-- OS: 20251031 https://dashfinancial.atlassian.net/browse/DS-10634 added 'sg_brid', 'sg_sub_account_name'

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
                                           user_id, is_visible_for_manual_allocation, auto_alloc_ratio, is_auto_alloc_to,
                                           sg_brid, sg_sub_account_name)
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
           coalesce((sj ->> 'alloc_ratio')::numeric, 1),
           sj ->> 'auto_alloc_to',
           sj ->> 'sg_brid',
           sj ->> 'sg_sub_account_name'
    from (select value as sj
          from jsonb_array_elements(l_clearing_accounts)) l1;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    return l_row_cnt;

end;
$function$
;
