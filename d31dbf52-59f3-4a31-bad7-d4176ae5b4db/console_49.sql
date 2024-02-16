select *
from dash360.report_fintech_adh_workx(20240212, 20240212, '{24051}', 'E');
alter function dash360.report_fintech_adh_workx rename to report_fintech_adh_workx_tbl
create or replace function dash360.report_fintech_adh_workx(in_start_date_id int4, in_end_date_id int4,
                                                 in_account_ids int4[] default '{}',
                                                 in_instrument_type_id char(1) default null)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_fintech_adh_workx for ' || in_start_date_id::text || ' - ' ||
                           in_end_date_id::text || ' STARTED===', 0, 'O')
    into l_step_id;
    return query
        select 'trfDestination,role,submitMPID,submitCapacity,submitGiveupMPID,submitBranchSeqNum,submitClearingNumber,counterMPID,counterCapacity,counterGiveUpMPID,counterBranchSeqNum,counterClearingNum,includeClear,includeReport,includeRisk,agreement,executionDate,executionTime,side,quantity,symbol,tradePrice,priceTradeDigit,isPriceOverride,settlementDays,tradeModifier2,tradeModifier2Time,tradeModifier3,tradeModifier4,tradeModifier4Time,isTradeThrough,intendedMarketFlag,relatedMarketFlag,isSpecial,specialInstruction,stepInOut,fee,tradeReferenceNum,memo,correspondentMPID,isReversal,origCtrlDate,origCtrlNum,refdRptVenue';

    return query
        select array_to_string(ARRAY [
                                   '1', -- as trfDestination,
                                   'M', -- as "role",
                                   'DFIN', -- as submitMPID,
                                   'A', -- as submitCapacity,
                                   null, -- as submitGiveupMPID,
                                   null, -- as submitBranchSeqNum,
                                   null, -- as submitClearingNumber,
                                   'DFIN', -- as counterMPID,
                                   'A', -- as counterCapacity,
                                   tf.broker_dealer_mpid, -- as counterGiveUpMPID,
                                   null, -- as counterBranchSeqNum,
                                   null, -- as counterClearingNum,
                                   'Y', -- as includeClear,
                                   'N', -- as includeReport,
                                   'Y', -- as includeRisk,
                                   'AGU', -- as agreement,
                                   to_char(tr.trade_record_time, 'YYYY-MM-DD'), -- as executionDate,
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.US'), -- as executionTime,
                                   case
                                       when tr.side = '1' then 'S'
                                       when tr.side in ('2', '5', '6') then 'B'
                                       end , -- as side,
                                   tr.last_qty::text, -- as quantity,
                                   hsd.symbol, -- as symbol,
                                   round(tr.last_px, 6)::text, -- as tradePrice,
                                   null, -- as priceTradeDigit,
                                   null, -- as isPriceOverride,
                                   '2', -- as settlementDays,
                                   null, -- as tradeModifier2,
                                   null, -- as tradeModifier2Time,
                                   null, -- as tradeModifier3,
                                   null, -- as tradeModifier4,
                                   null, -- as tradeModifier4Time,
                                   'N', -- as isTradeThrough,
                                   null, -- as intendedMarketFlag,
                                   null, -- as relatedMarketFlag,
                                   null, -- as isSpecial,
                                   null, -- as specialInstruction,
                                   null, -- as stepInOut,
                                   null, -- as fee,
                                   null, -- as tradeReferenceNum,
                                   null, -- as memo,
                                   null, -- as correspondentMPID,
                                   null, -- as isReversal,
                                   null, -- as origCtrlDate,
                                   null, -- as origCtrlNum,
                                   null -- as refdRptVenue
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account a on (a.account_id = tr.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and case when coalesce(in_account_ids, '{}') = '{}' then true else a.account_id = any (in_account_ids) end-- (24051) --MINTTRADING
          and case
                  when in_instrument_type_id is null then true
                  else tr.instrument_type_id = in_instrument_type_id end                                            --null for both E and O
          and tr.is_busted = 'N'
        order by tr.date_id, tr.trade_record_time;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_fintech_adh_workx for ' || in_start_date_id::text || ' - ' ||
                           in_end_date_id::text || ' FINISHED===', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;