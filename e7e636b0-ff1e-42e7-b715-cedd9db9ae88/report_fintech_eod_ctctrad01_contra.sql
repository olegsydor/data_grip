select * from dash360.report_fintech_eod_ctctrad01_contra(in_start_date_id := 20240814, in_end_date_id := 20240815);

drop function if exists dash360.report_fintech_eod_ctctrad01_contra;
create function dash360.report_fintech_eod_ctctrad01_contra(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
    -- OS 20240815 https://dashfinancial.atlassian.net/browse/DEVREQ-4693
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_ctctrad01_contra for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select 'TradeDate,TradeTime,TradingFirmID,Account,ClientOrderID,ExchExecID,InstrumentType,OSISymbol,Symbol,Expiry,Strike,PutOrCall,Side,LastQty,LastPx,SORExchangeID,ExchangeCode,ContraCapacity,ContraOCC,ContraCMTA,ContraFirm';

    return query
        select array_to_string(ARRAY [
                                   to_char(tr.trade_record_time, 'MM/DD/YYYY'), -- as "TradeDate",
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.US'), -- as "TradeTime",
                                   a.trading_firm_id, -- as "TradingFirmID",
                                   a.account_name, -- as "Account",
                                   tr.client_order_id, -- as "ClientOrderID",
                                   tr.exch_exec_id, -- as "ExchExecID",
                                   case
                                       when i.instrument_type_id = 'E' then 'Equity'
                                       when i.instrument_type_id = 'O' then 'Option'
                                       end, -- as "InstrumentType",
                                   coalesce(oc.opra_symbol, i.symbol), -- as "OSISymbol",
                                   i.symbol, -- as "Symbol",
                                   to_char(to_date(
                                                   ((oc.maturity_year * 10000 + oc.maturity_month * 100 + oc.maturity_day)::varchar)::varchar,
                                                   'YYYYMMDD'), 'MM/DD/YYYY'), -- as "Expiry",
                                   oc.strike_price::text, -- as "Strike",
                                   (case when oc.put_call = '1' then 'C' else 'P' end), -- as "PutOrCall",
                                   case
                                       when tr.side = '1' then 'Buy'
                                       when tr.side in ('2', '5', '6') then 'Sell'
                                       end, -- as "Side",
                                   tr.last_qty::text, -- as "LastQty",
                                   tr.last_px::text, -- as "LastPx",
                                   tr.exchange_id, -- as "SORExchangeID",
                                   case when rest.is_restricted then null else otd.mic_code end, -- as "ExchangeCode",
                                   case when rest.is_restricted then null else otd.contra_account_type end, -- as "ContraCapacity",
                                   case
                                       when rest.is_restricted then null
                                       else otd.contra_clearing_member_number end, -- as "ContraOCC",
                                   case
                                       when rest.is_restricted then null
                                       else otd.contra_gup_clearing_firm end, -- as "ContraCMTA",
                                   case when rest.is_restricted then null else otd.contra_exec_broker end -- as "ContraFirm"
                                   ], ',', '')
        from genesis2.genesis2.trade_record tr
                 join genesis2.genesis2.account a on (a.account_id = tr.account_id)
                 join genesis2.genesis2.trading_firm tf on (tf.trading_firm_id = a.trading_firm_id)
                 join genesis2.genesis2.instrument i on (i.instrument_id = tr.instrument_id)
                 left join genesis2.genesis2.option_contract oc on (oc.instrument_id = i.instrument_id)
                 left join occ_data.occ_trade_data_matching otdm
                           on (otdm.date_id between in_start_date_id and in_end_date_id and
                               otdm.date_id = tr.date_id and otdm.trade_record_id = tr.trade_record_id)
                 left join occ_data.occ_trade_data otd on (otd.date_id between in_start_date_id and in_end_date_id and
                                                           otd.date_id = otdm.date_id and otd.trade_id = otdm.trade_id)
                 left join lateral (
            select true as is_restricted
            from occ_data.contra_occ_trade_data_matching cotdm
            where cotdm.date_id between in_start_date_id and in_end_date_id
              and cotdm.date_id = otdm.date_id
              and cotdm.rpt_id = otdm.rpt_id
              and cotdm.trade_id = otdm.trade_id
            limit 1
            ) rest on true
        where tr.date_id between in_start_date_id and in_end_date_id
          and a.trading_firm_id in ('dashctc', 'ctctrad01', 'ctctrad03')
          and tr.is_busted = 'N'
        order by tr.trade_record_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_ctctrad01_contra for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$fx$;