create or replace function dash360.report_fintech_mwace_execution(in_start_date_id integer default get_dateid(current_date),
                                                                  in_end_date_id integer default get_dateid(current_date)
)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
    -- 20250319 OS https://dashfinancial.atlassian.net/browse/DS-9735
declare
    l_load_id     int8;
    l_step_id     int4;
    l_row_cnt     int4;
    l_account_ids int4[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_mwace_execution STARTED===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id = 'mwace'
      and is_active;

    return query
        select 'Trading Firm,Account,Cl Ord ID,Date,Time,Sec Type,Ex Dest,Sub Strategy,Side,O/C,Symbol,Root Symbol,Expiration,Put/Call,Last Qty,Last Px,Strike,Exchange Name,Cust/Firm,Exec Broker,CMTA,Client ID';

    return query
        select array_to_string(ARRAY [
                                   replace(tf.trading_firm_name, ',', '')::varchar, -- as "Trading Firm",
                                   da.account_name , -- as "Account",
                                   tr.client_order_id , -- as "Cl Ord ID",
                                   to_char(tr.trade_record_time, 'MM/DD/YYYY') , -- as "Date",
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.US') , -- as "Time",
                                   case
                                       when tr.instrument_type_id = 'E' then 'Equity'
                                       when tr.instrument_type_id = 'O' then 'Option'
                                       end , -- as "Sec Type",
                                   case
                                       when tr.ex_destination in ('ALGO', 'SMART')
                                           then tr.ex_destination || (case
                                                                          when tr.instrument_type_id = 'O'
                                                                              then ' Options'
                                                                          when tr.instrument_type_id = 'E'
                                                                              then ' Equities'
                                                                          else '' end)
                                       else exd.ex_destination_desc
                                       end::varchar , -- as "Ex Dest",
                                   tr.sub_strategy , -- as "Sub Strategy",
                                   case
                                       when tr.side = '1' then 'Buy'
                                       when tr.side = '2' then 'Sell'
                                       when tr.side in ('5', '6') then 'Sell Short'
                                       end , -- as "Side",
                                   case
                                       when tr.open_close = 'O' then 'Open'
                                       when tr.open_close = 'C' then 'Close'
                                       end , -- as "O/C",
                                   case
                                       when tr.instrument_type_id = 'O' then
                                           concat(coalesce(hsd.underlying_symbol, hsd.symbol),
                                                  ' US ',
                                                  to_char(hsd.maturity_date, 'MM/DD/YY'),
                                                  ' ',
                                                  case
                                                      when hsd.put_call = '0' then 'P'
                                                      when hsd.put_call = '1' then 'C'
                                                      else '' end,
                                                  hsd.strike_px::float::varchar)
                                       else hsd.display_instrument_id end , -- as "Symbol",
                                   coalesce(hsd.underlying_symbol, hsd.symbol) , -- as "Root Symbol",
                                   to_char(hsd.maturity_date, 'MM/DD/YYYY') , -- as "Expiration",
                                   case
                                       when hsd.put_call = '0' then 'Put'
                                       when hsd.put_call = '1' then 'Call'
                                       end , -- as "Put/Call", -- Changed insted of clear put_call
                                   tr.last_qty::text , -- as "Last Qty",
                                   tr.last_px::text , -- as "Last Px",
                                   hsd.strike_px::text , -- as "Strike",
                                   exc.exchange_name , -- as "Exchange Name",
                                   cf.customer_or_firm_name , -- as "Cust/Firm",
                                   tr.exec_broker , -- as "Exec Broker",
                                   tr.cmta , -- as "CMTA",
                                   tr.client_id -- as "Client ID"
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account da on (da.account_id = tr.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = da.trading_firm_unq_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                 left join dwh.d_customer_or_firm cf
                           on (cf.customer_or_firm_id = tr.opt_customer_firm and cf.is_active)
                 left join dwh.d_exchange exc on (exc.exchange_id = tr.exchange_id and exc.is_active)
                 left join dwh.d_ex_destination exd on (exd.ex_destination_code = tr.ex_destination and
                                                        coalesce(exd.exchange_id, '') =
                                                        coalesce(tr.exchange_id, '') and
                                                        exd.instrument_type_id = tr.instrument_type_id and
                                                        exd.is_active)
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.is_busted <> 'Y'
          and da.account_name not in (select * from fintech_dwh.users_fbw_tb)
--           and case when in_instrument_type is null then true else tr.instrument_type_id = in_instrument_type end
          and tr.account_id = any (l_account_ids)
          and tr.multileg_reporting_type in ('1', '2')
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_mwace_execution COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;

select *
from dash360.report_fintech_mwace_execution(20250318, 20250318);

