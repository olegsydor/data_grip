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


select ai.date_id                                                                       as "75",
       ai.create_time                                                                   as "60",
       di.symbol                                                                        as "55",
       case when di.instrument_type_id = 'O' then 'OPT' else 'ES' end                   as "167",
       case when di.instrument_type_id = 'O' then oc.put_call end                       as "201",
       case when di.instrument_type_id = 'O' then oc.strike_price end                   as "202",
       case when di.instrument_type_id = 'O' then to_char(oc.maturity_day, 'FM00') end  as "205",
       case
           when di.instrument_type_id = 'O' then to_char(oc.maturity_year, 'FM0000') ||
                                                 to_char(oc.maturity_month, 'FM00') end as "200",
       ai.total_qty                                                                     as "53",
       ai.avg_px                                                                        as "6",
       "124",
       "NO_EXECS",
       "78",
       "NO_ALLOCS"

-- select ai.alloc_instr_id, *
from genesis2.allocation_instruction ai
         join lateral (select count(*)                                                                            as "78",
                              jsonb_agg(jsonb_build_object('79', ac.opt_occ_id, '80', aie.alloc_qty, '439',
                                                           ca.clearing_account_number, '10440', aie.occ_actionable_id,
                                                           '11888', ca.sg_brid, '10701',
                                                           ca.sg_sub_account_name))                               as "NO_ALLOCS"
                       from genesis2.allocation_instruction_entry aie
                                join genesis2.clearing_account ca
                                     on (ca.clearing_account_id = aie.clearing_account_id and
                                         ca.clearing_account_type = '1' and ca.market_type = 'O')
                                join genesis2.account ac on ac.account_id = ai.account_id
                       where aie.alloc_instr_id = ai.alloc_instr_id
                         and aie.date_id = ai.date_id
                       limit 1) aie on true
         join lateral (select count(*) as "124",
                              jsonb_agg(jsonb_build_object('17', tr.exec_id, 'secondary_exch_exec_id',
                                                           tr.secondary_exch_exec_id, 'last_qty', tr.last_qty,
                                                           'leg_ref_id', tr.leg_ref_id)
                              )        as "NO_EXECS"
                       from genesis2.alloc_instr2trade_record aitr
                                join genesis2.trade_record tr
                                     on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                       where aitr.alloc_instr_id = ai.alloc_instr_id
                         and aitr.date_id = ai.date_id
--                          and aitr.allocation_instruction_entry_id = aie.allocation_instruction_entry_id
                       limit 1) aitr on true
         join genesis2.instrument di on di.instrument_id = ai.instrument_id
         left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
         left join genesis2.option_series os on oc.option_series_id = os.option_series_id
where ai.date_id = 20251024
  and ai.alloc_instr_id = -99689
-- group by 1 aie.allocation_instruction_entry_id) > 1
--                 having count(distinct

