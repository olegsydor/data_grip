-- DROP FUNCTION dash360.report_fintech_adh_allocation_xls(int4, int4, _int4, bpchar, _varchar, _varchar);
select * from dash360.report_fintech_laniakea_allocation(in_start_date_id := 20250424, in_end_date_id := 20250424);

CREATE OR REPLACE FUNCTION dash360.report_fintech_laniakea_allocation(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2025-04-25 SO: https://dashfinancial.atlassian.net/browse/DS-9930
declare
    l_account_ids int4[];
    l_load_id     int;
    l_step_id     int;
    l_row_cnt     int;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_laniakea_allocation for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from genesis2.account ac
    where ac.trading_firm_id = 'laniakea';

    l_account_ids = '{24849}';

    return query
        select 'Version,ActionType,ExternalID,TransactionType,TransactionAccountNumber,TransactionAccountType,' ||
               'TransactionSideType,TransactionQuantity,TransactionPrice,TransactionDateTime,TransactionOpenClose,' ||
               'TransactionBrokerCapacity,AllocationSourceAccountNumber,AllocationSourceAccountType,ExecutionRouteType,' ||
               'ExecutionExchange,ExecutionOrderId,ExecutingBroker,InstrumentType,InstrumentIDType,' ||
               'InstrumentID,ChargeCommissionAmount';

    return query
        select array_to_string(ARRAY [
                                   '1' , -- as "Version",
                                   'CREATE' , -- as "ActionType",
                                   alt.alloc_instr_id::text, -- as "ExternalID",
                                   'ALLOCATION' , -- as "TransactionType",
                                   null::text , -- as "TransactionAccountNumber",
                                   'MARGIN' , -- as "TransactionAccountType",
                                   case
                                       when tr.side = '1' then 'BUY'
                                       when tr.side in ('2', '5', '6') then 'SELL'
                                       end , -- as "TransactionSideType",
                                   ai.total_qty::text , -- as "TransactionQuantity",
                                   round(sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0),
                                         4)::text , -- as "TransactionPrice",
                                   to_char(min(tr.street_trade_record_time)::timestamp at time zone 'UTC',
                                           'YYYY-MM-DD"T"HH24:MI:SSOF:00'), -- as "TransactionDateTime",2025-04-07T16:17:16-04:00
                                   case
                                       when di.instrument_type_id = 'E' then null
                                       when tr.open_close = 'O' then 'OPEN'
                                       when tr.open_close = 'C' then 'CLOSE'
                                       end , -- as "TransactionOpenClose",
                                   'AGENT' , -- as "TransactionBrokerCapacity",
                                   ac.account_name , -- as "AllocationSourceAccountNumber",
                                   'MARGIN' , -- as "AllocationSourceAccountType",
                                   null::text , -- as "ExecutionRouteType",
                                   null::text , -- as "ExecutionExchange",
                                   null::text , -- as "ExecutionOrderId",
                                   null::text , -- as "ExecutingBroker",
                                   case
                                       when di.instrument_type_id = 'O' then 'OPTION'
                                       when di.instrument_type_id = 'E' then 'EQUITY' end , -- as "InstrumentType",
                                   case
                                       when di.instrument_type_id = 'O' then 'OCC_SYMBOL'
                                       when di.instrument_type_id = 'E'
                                           then 'TICKER_SYMBOL' end, -- as "InstrumentIDType",
                                   case
                                       when di.instrument_type_id = 'O' then oc.opra_symbol
                                       when di.instrument_type_id = 'E' then di.symbol end, -- as "InstrumentID",
                                   case
                                       when di.instrument_type_id = 'O' then (ai.total_qty * 0.1)::text
                                       end -- as "ChargeCommissionAmount"
                                   ], ',', '')
        from genesis2.trade_record tr
                 join genesis2.account ac on (ac.account_id = tr.account_id)
                 join genesis2.instrument di on di.instrument_id = tr.instrument_id
                 join genesis2.alloc_instr2trade_record alt
                      on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                 join genesis2.allocation_instruction ai
                      on (ai.date_id between in_start_date_id and in_end_date_id and
                          ai.alloc_instr_id = alt.alloc_instr_id and
                          ai.is_deleted = 'N')
                 left join genesis2.option_contract oc on oc.instrument_id = di.instrument_id
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.account_id = any (l_account_ids)
          and tr.is_busted = 'N'
        group by alt.alloc_instr_id, tr.side, ai.total_qty, di.instrument_type_id, tr.open_close, ac.account_name,
                 oc.opra_symbol, di.symbol;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_laniakea_allocation for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;



select '1'                                                         as "Version",
       'CREATE'                                                    as "ActionType",
       alt.alloc_instr_id                                          as "ExternalID",
       'ALLOCATION'                                                as "TransactionType",
       null::text                                                  as "TransactionAccountNumber",
       'MARGIN'                                                    as "TransactionAccountType",
       case
           when tr.side = '1' then 'BOT'
           when tr.side = '2' then 'SLD'
           when tr.side in ('5', '6') then 'SLD SHORT'
           end                                                     as "TransactionSideType",
       ai.total_qty                                                as "TransactionQuantity",
       sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as "TransactionPrice",
       min(tr.street_trade_record_time)::timestamp at time zone 'UTC'   as "TransactionDateTime",
       case
           when di.instrument_type_id = 'E' then null
           when tr.open_close = 'O' then 'Open'
           when tr.open_close = 'C' then 'Close'
           end                                                     as "TransactionOpenClose",
       'AGENT'                                                     as "TransactionBrokerCapacity",
       ac.account_name                                             as "AllocationSourceAccountNumber",
       'MARGIN'                                                    as "AllocationSourceAccountType",
       null::text                                                  as "ExecutionRouteType",
       null::text                                                  as "ExecutionExchange",
       null::text                                                  as "ExecutionOrderId",
       null::text                                                  as "ExecutingBroker",
       case
           when di.instrument_type_id = 'O' then 'OPTION'
           when di.instrument_type_id = 'E' then 'EQUITY' end      as "InstrumentType",
       'OCC_SYMBOL'                                                as "InstrumentIDType",
       oc.opra_symbol                                              as "InstrumentID",
       case
           when di.instrument_type_id = 'O' then ai.total_qty * 0.1
           end                                                     as ChargeCommissionAmount
from genesis2.trade_record tr
         join genesis2.account ac on (ac.account_id = tr.account_id)
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         join genesis2.alloc_instr2trade_record alt
              on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
         join genesis2.allocation_instruction ai
              on (ai.date_id between :in_start_date_id and :in_end_date_id and
                  ai.alloc_instr_id = alt.alloc_instr_id and
                  ai.is_deleted = 'N')
         left join genesis2.option_contract oc on oc.instrument_id = di.instrument_id
where tr.date_id between :in_start_date_id and :in_end_date_id
  and tr.account_id = any (:l_account_ids)
  and tr.is_busted = 'N'
group by alt.alloc_instr_id, tr.side, ai.total_qty, di.instrument_type_id, tr.open_close, ac.account_name,
         oc.opra_symbol


select to_char(clock_timestamp()::timestamp at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS-04:00'),
       to_char(clock_timestamp()::timestamp at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS'),
       to_char(clock_timestamp()::timestamp at time zone 'UTC',  'YYYY-MM-DD"T"HH24:MI:SS-OF');
