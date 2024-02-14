select * from dash360.report_fintech_adh_workx(20240212, 20240212, '{24051}', 'E');

create or replace function dash360.report_fintech_adh_workx(in_start_date_id int4, in_end_date_id int4,
                                                            in_account_ids int4[] default '{}',
                                                            in_instrument_type_id char(1) default null)
    returns table
            (
                trfdestination       text,
                "role"               text,
                submitmpid           text,
                submitcapacity       text,
                submitgiveupmpid     text,
                submitbranchseqnum   text,
                submitclearingnumber text,
                countermpid          text,
                countercapacity      text,
                countergiveupmpid    varchar(4),
                counterbranchseqnum  text,
                counterclearingnum   text,
                includeclear         text,
                includereport        text,
                includerisk          text,
                agreement            text,
                executiondate        text,
                executiontime        text,
                side                 text,
                quantity             int4,
                symbol               varchar(10),
                tradeprice           numeric,
                pricetradedigit      text,
                ispriceoverride      text,
                settlementdays       int4,
                trademodifier2       text,
                trademodifier2time   text,
                trademodifier3       text,
                trademodifier4       text,
                trademodifier4time   text,
                istradethrough       text,
                intendedmarketflag   text,
                relatedmarketflag    text,
                isspecial            text,
                specialinstruction   text,
                stepinout            text,
                fee                  text,
                tradereferencenum    text,
                memo                 text,
                correspondentmpid    text,
                isreversal           text,
                origctrldate         text,
                origctrlnum          text,
                refdrptvenue         text
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
        select '1'                                            as trfDestination,
               'M'                                            as "role",
               'DFIN'                                         as submitMPID,
               'A'                                            as submitCapacity,
               null                                           as submitGiveupMPID,
               null                                           as submitBranchSeqNum,
               null                                           as submitClearingNumber,
               'DFIN'                                         as counterMPID,
               'A'                                            as counterCapacity,
               tf.broker_dealer_mpid                          as counterGiveUpMPID,
               null                                           as counterBranchSeqNum,
               null                                           as counterClearingNum,
               'Y'                                            as includeClear,
               'N'                                            as includeReport,
               'Y'                                            as includeRisk,
               'AGU'                                          as agreement,
               to_char(tr.trade_record_time, 'YYYY-MM-DD')    as executionDate,
               to_char(tr.trade_record_time, 'HH24:MI:SS.US') as executionTime,
               case
                   when tr.side = '1' then 'S'
                   when tr.side in ('2', '5', '6') then 'B'
                   end                                        as side,
               tr.last_qty                                    as quantity,
               hsd.symbol                                     as symbol,
               round(tr.last_px, 6)                           as tradePrice,
               null                                           as priceTradeDigit,
               null                                           as isPriceOverride,
               2                                              as settlementDays,
               null                                           as tradeModifier2,
               null                                           as tradeModifier2Time,
               null                                           as tradeModifier3,
               null                                           as tradeModifier4,
               null                                           as tradeModifier4Time,
               'N'                                            as isTradeThrough,
               null                                           as intendedMarketFlag,
               null                                           as relatedMarketFlag,
               null                                           as isSpecial,
               null                                           as specialInstruction,
               null                                           as stepInOut,
               null                                           as fee,
               null                                           as tradeReferenceNum,
               null                                           as memo,
               null                                           as correspondentMPID,
               null                                           as isReversal,
               null                                           as origCtrlDate,
               null                                           as origCtrlNum,
               null                                           as refdRptVenue
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