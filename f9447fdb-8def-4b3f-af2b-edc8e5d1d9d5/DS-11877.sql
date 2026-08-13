-- DROP FUNCTION dash360.get_data_for_allocation_drop_sg(int8, int4);
-133373 -133477
-133478


select * from dash360.get_data_for_allocation_drop_sg(-133373, 20260811);
select * from dash360.get_data_for_allocation_drop_sg(-133477, 20260811);
select * from dash360.get_data_for_allocation_drop_sg(-133478, 20260811);
select ai.alloc_instr_id,
       trash.get_data_for_allocation_drop_sg(ai.alloc_instr_id, 20260811)
from genesis2.allocation_instruction ai
where date_id = 20260811

CREATE OR REPLACE FUNCTION dash360.get_data_for_allocation_drop_sg(in_alloc_instr_id bigint, in_date_id integer DEFAULT NULL::integer)
    RETURNS jsonb
    LANGUAGE plpgsql
AS
$function$
    -- 20251027 SO https://dashfinancial.atlassian.net/browse/DS-10634
    -- 20251119 SO https://dashfinancial.atlassian.net/browse/DS-10739
    -- 20251205 SO https://dashfinancial.atlassian.net/browse/DS-10739 New atrributes in the result json were added
    -- 20260217 SO https://dashfinancial.atlassian.net/browse/DS-11116 version for SG
    -- 20260223 SO https://dashfinancial.atlassian.net/browse/DS-11134 applied filter for is_busted for cancels only
    -- 20260227 SO https://dashfinancial.atlassian.net/browse/DS-11173 Add new output param
    -- 20260528 SO https://dashfinancial.atlassian.net/browse/DS-11531 Add ElliotCounterpartyCode field to the response on get_data_for_allocation_drop_sg (SG specific)
    -- 20260528 SO https://dashfinancial.atlassian.net/browse/DS-11532 get_data_for_alloc_drop_sg (SG) returns null Trade Records when Trade Record exists.
    -- 20260812 SO https://dashfinancial.atlassian.net/browse/DS-11877 Return BlazeOrderOwner in get_data_for_allocation_drop
declare
    l_return_jsonb jsonb;
    l_sg_accounts  int8[];
begin
    select array_agg(ac.account_id)
    into l_sg_accounts
    from account ac
             join staging.sg_trading_firm using (trading_firm_id)
    where ac.is_deleted = 'N';

    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'noAllocs', aie.alloc_cnt,
                                                  'allocationEntries', aie.entries,
                                                  'AllocInstrId', ai.alloc_instr_id,
                                                  'instrumentTypeId', di.instrument_type_id,
                                                  'ElliotCounterpartyCode',
                                                  dash360.get_elliot(in_account_id := ai.account_id),
                                                  'BlazeOrderOwner', case
                                                                         when ccr.subsystem_id = 'OMS_EDW'
                                                                             then oms.blaze_order_owner
                                                                         else fmj.order_owner
                                                      end
                               )
    from genesis2.allocation_instruction ai
             join genesis2.instrument di on di.instrument_id = ai.instrument_id
             left join lateral (select sum(l1.rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)            as rate,
                                       sum(amount)                                                         as amount,
                                       (array_agg(tr.trade_record_id order by tr.trade_record_id))[1]      as trade_record_id,
                                       (array_agg(tr.subsystem_id order by tr.trade_record_id))[1]         as subsystem_id,
                                       (array_agg(tr.trade_fix_message_id order by tr.trade_record_id))[1] as order_fix_message_id
                                from genesis2.alloc_instr2trade_record alt
                                         inner join genesis2.trade_record tr
                                                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                         left join lateral (select tl.rate,
                                                                   tl.amount,
                                                                   row_number()
                                                                   over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                            from genesis2.trade_level_book_record tl
                                                                     inner join genesis2.book_record_creator cr
                                                                                on tl.book_record_creator_id = cr.book_record_creator_id
                                                            where tl.date_id = in_date_id
                                                              AND tl.book_record_type_id = 'CCRU'
                                                              and tl.trade_record_id = alt.trade_record_id) l1
                                                   on true
                                where alt.alloc_instr_id = ai.alloc_instr_id
                                  and alt.date_id = ai.date_id
                                  and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end
                                  and (l1.rn = 1 or l1.rn is null)
        ) ccr on true
             left join lateral (select blaze_order_owner
                                from staging.trade_record_blaze7 bl
                                where bl.date_id = ai.date_id
                                  and bl.trade_record_id = ccr.trade_record_id
                                  and blaze_order_owner is not null
                                limit 1) oms
                       on true and ccr.subsystem_id = 'OMS_EDW' -- and ai.account_id = any (l_sg_accounts)
             left join lateral (select fmj.fix_message ->> '10582' as order_owner
                                from staging.fix_message_json fmj
                                where fmj.fix_message_id = ccr.order_fix_message_id
                                  and fmj.date_id = ai.date_id
                                limit 1) fmj
                       on true and not (ccr.subsystem_id = 'OMS_EDW' /*and ai.account_id = any (l_sg_accounts)*/)

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_firm,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'EquityBRID', ca.sg_equity_brid,
                                                               'OptionBRID', ca.sg_opt_brid,
                                                               'subAccount', ca.sg_sub_account_name,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'salesTrader', ca.sg_sales_trader,
                                                               'sgMintAccount', ca.sg_mint_account,
                                                               'AllocEntryCCRURate', ccr.rate,
                                                               'AllocEntryCCRUTotalAmount',
                                                               ccr.amount * 1.0 * aie.alloc_qty / total_qty
                                            ))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.sg_allocation_configuration ca
                                              on (ca.sg_alloc_config_id = aie.sg_alloc_config_id)
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id = ai.alloc_instr_id
                             and aie.date_id = ai.date_id
                           limit 1) aie on true
             left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
             left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = in_alloc_instr_id
      and case when in_date_id is null then true else ai.date_id = in_date_id end;
    return l_return_jsonb;
end ;
$function$
;


 select subsystem_id
 from genesis2.trade_record
 where date_id = 20260811;




select sum(l1.rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)            as rate,
                                       sum(amount)                                                         as amount,
                                       (array_agg(tr.trade_record_id order by tr.trade_record_id))[1]      as trade_record_id,
                                       (array_agg(tr.subsystem_id order by tr.trade_record_id))[1]         as subsystem_id,
                                       (array_agg(tr.order_fix_message_id order by tr.trade_record_id))[1] as order_fix_message_id
                                from genesis2.alloc_instr2trade_record alt
                                         inner join genesis2.trade_record tr
                                                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                         left join lateral (select tl.rate,
                                                                   tl.amount,
                                                                   row_number()
                                                                   over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                            from genesis2.trade_level_book_record tl
                                                                     inner join genesis2.book_record_creator cr
                                                                                on tl.book_record_creator_id = cr.book_record_creator_id
                                                            where tl.date_id = 20260811
                                                              AND tl.book_record_type_id = 'CCRU'
                                                              and tl.trade_record_id = alt.trade_record_id) l1
                                                   on true
                                where alt.alloc_instr_id = -133373
                                  and alt.date_id = 20260811;

