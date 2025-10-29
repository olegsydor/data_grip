/*
Support SG fields on Option Allocation Configuration
Add new columns  to table genesis2.clearing_account sg_brid

Name: sg_brid

Type: varchar

Description: SG allocation field used for populating tag in 35=J. Copy from SG_ACCOUNT value

sg_sub_account_name

Name: sg_sub_account_name

Type: varchar

DescriptionSG allocation field used for populating tag in 35=J. Copy from SG_ACCOUNT value

Add the new fields to DB procedure dash360.allocations_get_accounts_config  // (i) CA view

optional inputs

Add the new fields to DB procedure dash360.allocations_set_accounts_config // (i) CA change submit

optional inputs

Display SG fields on Option Allocation Pop-up

 Adjust  dash360.allocations_clearing_accounts_by_account_id  to return sg_brid and sg_sub_account_name
*/
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
                                  jsonb_agg(jsonb_build_object('79', ac.opt_occ_id,
                                                               '80', aie.alloc_qty,
                                                               '439', ca.clearing_account_number,
                                                               '10440', aie.occ_actionable_id,
                                                               '11712', ca.sg_brid,
                                                               '10701', ca.sg_sub_account_name,
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


select *
from genesis2.allocation_instruction_entry aie
                                    join genesis2.clearing_account ca
                                         on (ca.clearing_account_id = aie.clearing_account_id
--                                                  and ca.clearing_account_type = '1' and ca.market_type = 'O'
                                             )

                           where aie.alloc_instr_id = -99683
                             and aie.date_id = 20251023


CREATE USER MAPPING FOR osemenchenko SERVER postgresbig_data_uat OPTIONS (user 'genesis2', password 'GENESIS2');