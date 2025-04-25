-- DROP FUNCTION dash360.report_fintech_adh_allocation_xls(int4, int4, _int4, bpchar, _varchar, _varchar);

CREATE OR REPLACE FUNCTION dash360.report_fintech_laniakea_allocation(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS $function$
    -- 2025-04-25 SO: https://dashfinancial.atlassian.net/browse/DS-9930
declare
    l_account_ids int4[];
    begin



select array_agg(account_id)
into l_account_ids
from dwh.d_account ac
where ac.trading_firm_id = 'laniakea';

select '1'                                                            as "Version",
       'CREATE'                                                       as "ActionType",
       alt.alloc_instr_id                                             as "ExternalID",
       'ALLOCATION'                                                   as "TransactionType",
       null::text                                                     as "TransactionAccountNumber",
       'MARGIN'                                                       as "TransactionAccountType",
       case
           when tr.side = '1' then 'BOT'
           when tr.side = '2' then 'SLD'
           when tr.side in ('5', '6') then 'SLD SHORT'
           end                                                        as "TransactionSideType",
       sum(ai.total_qty)                                              as "TransactionQuantity",
       round(sum(tr.last_qty * tr.last_px) / sum(tr.last_qty), 4)     as "TransactionPrice",
       min(tr.street_trade_record_time::timestamp at time zone 'UTC') as "TransactionDateTime",
       case
           when di.instrument_type_id = 'E' then null
           when tr.open_close = 'O' then 'Open'
           when tr.open_close = 'C' then 'Close'
           end                                                        as "TransactionOpenClose",
       'AGENT'                                                        as "TransactionBrokerCapacity",
       ac.account_name                                                as "AllocationSourceAccountNumber",
       'MARGIN'                                                       as "AllocationSourceAccountType",
       null::text                                                     as "ExecutionRouteType",
       null::text                                                     as "ExecutionExchange",
       null::text                                                     as "ExecutionOrderId",
       null::text                                                     as "ExecutingBroker",
       case
           when di.instrument_type_id = 'O' then 'OPTION'
           when di.instrument_type_id = 'E' then 'EQUITY' end         as "InstrumentType",
       'OCC_SYMBOL'                                                   as "InstrumentIDType",
       oc.opra_symbol                                                 as "InstrumentID",
       case
           when di.instrument_type_id = 'O' then sum(ai.total_qty) * 0.1
           end                                                        as ChargeCommissionAmount
from genesis2.trade_record tr
         join genesis2.account ac on (ac.account_id = tr.account_id)
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         left join lateral (
    select alloc_instr_id, clearing_account_id
    from genesis2.alloc_instr2trade_record atr
    where atr.trade_record_id = tr.trade_record_id
      and atr.date_id = tr.date_id
    limit 1) alt on true
         left join staging.allocation_instruction ai
                   on (ai.date_id between :in_start_date_id and :in_end_date_id and
                       ai.alloc_instr_id = alt.alloc_instr_id and
                       ai.is_deleted = 'N')
    --          left join staging.allocation_instruction_entry aie
--                    on (aie.date_id between :in_start_date_id and :in_end_date_id and
--                        aie.alloc_instr_id = alt.alloc_instr_id and
--                        aie.clearing_account_id = alt.clearing_account_id)
         left join genesis2.option_contract oc on oc.instrument_id = di.instrument_id
where tr.date_id between :in_start_date_id and :in_end_date_id
  and tr.account_id = any (:l_account_ids)
  and tr.is_busted = 'N'
group by to_char(tr.trade_record_time, 'MM/dd/yyyy'), tr.side, ai.alloc_instr_id,
         ac.account_name, oc.opra_symbol, alt.alloc_instr_id, di.instrument_type_id, tr.open_close;

end ;
$function$
;



select '1'                                                       as "Version",
       'CREATE'                                                  as "ActionType",
       alt.alloc_instr_id                                        as "ExternalID",
       'ALLOCATION'                                              as "TransactionType",
       null::text                                                as "TransactionAccountNumber",
       'MARGIN'                                                  as "TransactionAccountType",
       case
           when tr.side = '1' then 'BOT'
           when tr.side = '2' then 'SLD'
           when tr.side in ('5', '6') then 'SLD SHORT'
           end                                                   as "TransactionSideType",
       ai.total_qty                                              as "TransactionQuantity",
       tr.last_qty,
       tr.last_px                                                as "TransactionPrice",
       tr.street_trade_record_time::timestamp at time zone 'UTC' as "TransactionDateTime",
       case
           when di.instrument_type_id = 'E' then null
           when tr.open_close = 'O' then 'Open'
           when tr.open_close = 'C' then 'Close'
           end                                                   as "TransactionOpenClose",
       'AGENT'                                                   as "TransactionBrokerCapacity",
       ac.account_name                                           as "AllocationSourceAccountNumber",
       'MARGIN'                                                  as "AllocationSourceAccountType",
       null::text                                                as "ExecutionRouteType",
       null::text                                                as "ExecutionExchange",
       null::text                                                as "ExecutionOrderId",
       null::text                                                as "ExecutingBroker",
       case
           when di.instrument_type_id = 'O' then 'OPTION'
           when di.instrument_type_id = 'E' then 'EQUITY' end    as "InstrumentType",
       'OCC_SYMBOL'                                              as "InstrumentIDType",
       oc.opra_symbol                                            as "InstrumentID",
       case
           when di.instrument_type_id = 'O' then ai.total_qty * 0.1
           end                                                   as ChargeCommissionAmount
from genesis2.trade_record tr
         join genesis2.account ac on (ac.account_id = tr.account_id)
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         left join lateral (
    select alloc_instr_id, clearing_account_id
    from genesis2.alloc_instr2trade_record atr
    where atr.trade_record_id = tr.trade_record_id
      and atr.date_id = tr.date_id
    limit 1) alt on true
         left join staging.allocation_instruction ai
                   on (ai.date_id between :in_start_date_id and :in_end_date_id and
                       ai.alloc_instr_id = alt.alloc_instr_id and
                       ai.is_deleted = 'N')
    --          left join staging.allocation_instruction_entry aie
--                    on (aie.date_id between :in_start_date_id and :in_end_date_id and
--                        aie.alloc_instr_id = alt.alloc_instr_id and
--                        aie.clearing_account_id = alt.clearing_account_id)
         left join genesis2.option_contract oc on oc.instrument_id = di.instrument_id
where tr.date_id between :in_start_date_id and :in_end_date_id
  and tr.account_id = any (:l_account_ids)
  and tr.is_busted = 'N'