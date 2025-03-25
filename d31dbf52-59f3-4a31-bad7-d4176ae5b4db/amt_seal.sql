create or replace function dash360.report_fintech_eod_seals_trade_import(in_start_date_id integer default get_dateid(current_date),
                                                                         in_end_date_id integer default get_dateid(current_date),
                                                                         in_account_ids int4[] DEFAULT NULL::integer[],
                                                                         in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[]
)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
    -- 20250325 OS https://dashfinancial.atlassian.net/browse/DS-9753
declare
    l_load_id     int8;
    l_step_id     int4;
    l_row_cnt     int4;
    l_account_ids int4[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_eod_seals_trade_import STARTED===', 0, 'O')
    into l_step_id;

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    return query
        select
            'UniqueIdentifier,Action,Exchange,InstrumentType,ExchangeMember,ClearingDate,TradeDate,TradeTime,ProductCode,Expiry,StrikePrice,OptionType,BuySell,' ||
            'Price,AbbreviatedPrice,ExchangeOrderNumber,ExchangeTradeNumber,Trader,TradeType,CounterPartyMemberMnemonic,ExchangeMemberMnemonic,TradePriceType,' ||
            'Venue,TimeCode,ComboType,Volume,OpenClose,PositionAccount,Client,ExchRef1,ExchRef2,ExchRef3,GiveupRef1,GiveupRef2,GiveupRef3,BOReference,BOAccount,' ||
            'TransferType,TransferMemberMnemonic,UTI,ClearingTimestamp,ExchRef4,ExchRef5,UPI,TRN,Aggressor,IsFlex,ExerciseStyle,TVTIC,ExecutionTimestamp,' ||
            'TradingCapacity,StrategyPrice,ComplexTradeId,Waivers,MiFIDOTCType,CommodityReduceRisk,DEAIndicator,BSShortCode,BSDecision,BSTransmitter,' ||
            'InvmtDecisionCode,InvmtDecisionType,ExecIdCode,ExecIdType,OrderType';

    return query
        select array_to_string(ARRAY [
                                   tr.trade_record_id::text, -- UniqueIdentifier
                                   'A', -- Action
                                   exc.mic_code, -- Exchange
                                   'O', -- InstrumentType
                                   null, -- ExchangeMember
                                   null, -- ClearingDate
                                   to_char(tr.trade_record_time, 'yyyyMMdd'), -- TradeDate
                                   to_char(tr.trade_record_time, 'HH24MISS'), -- TradeTime
                                   hsd.underlying_symbol, -- ProductCode
                                   to_char(hsd.maturity_date, 'yyyyMMdd'), -- Expiry
                                   staging.trailing_dot(hsd.strike_px), -- StrikePrice
            -- to_char(hsd.strike_px, 'FM999990.0099'), -- StrikePrice
                                   case hsd.put_call when 'C' then 'Call' when 'P' then 'Put' end, -- OptionType
                                   case when tr.SIDE in ('2', '5') then 'Sell' else 'Buy' end, -- BuySell
                                   staging.trailing_dot(tr.last_px), -- Price
                                   null, -- AbbreviatedPrice
                                   tr.secondary_order_id, -- ExchangeOrderNumber
                                   tr.secondary_exch_exec_id, -- ExchangeTradeNumber
                                   tr.client_id, -- Trader
                                   null, -- TradeType,
                                   null, -- CounterPartyMemberMnemonic,
                                   null, -- ExchangeMemberMnemonic,
                                   null, -- TradePriceType
                                   exc.mic_code, -- Venue
                                   null, -- TimeCode,
                                   null, -- ComboType
                                   last_qty::text, -- Volume
                                   case
                                       when tr.open_close = 'C' then 'Close'
                                       when tr.open_close = 'O' then 'Open' end, -- OpenClose
                                   null, -- PositionAccount,
                                   null, -- Client,
                                   null, -- ExchRef1,
                                   null, -- ExchRef2,
                                   null, -- ExchRef3,
                                   null, -- GiveupRef1,
                                   null, -- GiveupRef2,
                                   null, -- GiveupRef3,
                                   null, -- BOReference,
                                   null, -- BOAccount,
                                   null, -- TransferType,
                                   null, -- TransferMemberMnemonic,
                                   null, -- UTI,
                                   null, -- ClearingTimestamp,
                                   null, -- ExchRef4,
                                   null, -- ExchRef5,
                                   null, -- UPI,
                                   null, -- TRN,
                                   null, -- Aggressor,
                                   null, -- IsFlex,
                                   null, -- ExerciseStyle,
                                   null, -- TVTIC,
                                   null, -- ExecutionTimestamp,
                                   null, -- TradingCapacity,
                                   null, -- StrategyPrice,
                                   null, -- ComplexTradeId,
                                   null, -- Waivers,
                                   null, -- MiFIDOTCType,
                                   null, -- CommodityReduceRisk,
                                   null, -- DEAIndicator,
                                   null, -- BSShortCode,
                                   null, -- BSDecision,
                                   null, -- BSTransmitter,
                                   null, -- InvmtDecisionCode,
                                   null, -- InvmtDecisionType,
                                   null, -- ExecIdCode,
                                   null, -- ExecIdType,
                                   null-- OrderType
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account da on (da.account_id = tr.account_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                 left join dwh.d_exchange exc on (exc.exchange_id = tr.exchange_id and exc.is_active)
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.is_busted <> 'Y'
--           and da.account_name not in (select * from fintech_dwh.users_fbw_tb)
          and tr.account_id = any (l_account_ids)
          and tr.multileg_reporting_type in ('1', '2')
          and tr.instrument_type_id = 'O'
        order by tr.date_id, tr.trade_record_id;

    get diagnostics l_row_cnt = row_count;
    return query
        select 'EOD_OF_FILE';

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_eod_seals_trade_import COMPLETED ===',
                           l_row_cnt, 'O')
    into l_step_id;
end ;
$function$
;

select *
from dash360.report_fintech_eod_seals_trade_import(in_start_date_id := 20250324, in_end_date_id := 20250324,
                                                   in_account_ids := '{72476,72831,70621}');

select *
from dash360.report_fintech_eod_seals_trade_import(in_start_date_id := 20250324, in_end_date_id := 20250324,
                                                   in_trading_firm_ids := '{samsungs,samsungr}');


select trading_firm_id from dwh.d_account
where account_id = any('{72476,72831,70621}')

select staging.trailing_dot(1.000001)