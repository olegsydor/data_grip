-- DROP FUNCTION dash360.report_fintech_mwace_execution(int4, int4, bpchar, _int4, _varchar);

create function dash360.report_fintech_mwace_execution(in_start_date_id integer default get_dateid(current_date),
                                                       in_end_date_id integer default get_dateid(current_date),
                                                       in_instrument_type character default null::bpchar,
                                                       in_account_ids integer[] default '{}'::integer[],
                                                       in_trading_firm_ids character varying[] default '{}'::character varying[])
    RETURNS TABLE
            (
                "Trading Firm"          character varying,
                "Account"               character varying,
                "Cl Ord ID"             character varying,
                "Date"                  text,
                "Time"                  text,
                "Sec Type"              text,
                "Ex Dest"               character varying,
                "Sub Strategy"          character varying,
                "Side"                  text,
                "O/C"                   text,
                "Symbol"                character varying,
                "Root Symbol"           character varying,
                "Expiration"            text,
                "Put/Call"              text,
                "Last Qty"              integer,
                "Last Px"               numeric,
                "Strike"                numeric,
                "Exchange Name"         character varying,
                "Cust/Firm"             character varying,
                "Exec Broker"           character varying,
                "CMTA"                  character varying,
                "Client ID"             character varying
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2024-04-18 SO: https://dashfinancial.atlassian.net/browse/DS-8251 added in_trading_firm_ids as an input parameter
    -- SO 20240523 https://dashfinancial.atlassian.net/browse/DEVREQ-4264 add coalesce to account\trading firm input parameters
    -- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
    -- 20241121 AK https://dashfinancial.atlassian.net/browse/DS-9086 added Client Commission to return query and renamed function from report_fintech_adh_execution_xls_liq_type to report_fintech_adh_execution_xls
declare
begin
    return query
        select -- just for debagging
               replace(tf.trading_firm_name, ',', '')::varchar as "Trading Firm",
               da.account_name                                 as "Account",
               tr.client_order_id                              as "Cl Ord ID",
               to_char(tr.trade_record_time, 'MM/DD/YYYY')     as "Date",
               to_char(tr.trade_record_time, 'HH24:MI:SS.US')  as "Time",
               case
                   when tr.instrument_type_id = 'E' then 'Equity'
                   when tr.instrument_type_id = 'O' then 'Option'
                   end                                         as "Sec Type",
               case
                   when tr.ex_destination in ('ALGO', 'SMART')
                       then tr.ex_destination || (case
                                                      when tr.instrument_type_id = 'O' then ' Options'
                                                      when tr.instrument_type_id = 'E' then ' Equities'
                                                      else '' end)
                   else exd.ex_destination_desc
                   end::varchar                                as "Ex Dest",
               tr.sub_strategy                                 as "Sub Strategy",
               case
                   when tr.side = '1' then 'Buy'
                   when tr.side = '2' then 'Sell'
                   when tr.side in ('5', '6') then 'Sell Short'
                   else ''
                   end                                         as "Side",
               case
                   when tr.open_close = 'O' then 'Open'
                   when tr.open_close = 'C' then 'Close'
                   else '' end                                 as "O/C",
               case
                    when "Sec Type" = 'Option' then concat("Root Symbol", ' US ',
                                                           to_char("Expiration"::date, 'MM/DD/YY'), ' ',
                                                           substring("Put/Call", 1, 1), "Strike"::float::varchar)
                    else hsd.display_instrument_id end                         as "Symbol",
               coalesce(hsd.underlying_symbol, hsd.symbol)     as "Root Symbol",
               to_char(hsd.maturity_date, 'MM/DD/YYYY')        as "Expiration",
               case
                   when hsd.put_call = '0' then 'Put'
                   when hsd.put_call = '1' then 'Call'
                   else ''
                   end                                         as "Put/Call", -- Changed insted of clear put_call
               tr.last_qty                                     as "Last Qty",
               tr.last_px                                      as "Last Px",
               hsd.strike_px                                   as "Strike",
               exc.exchange_name                               as "Exchange Name",
               cf.customer_or_firm_name                        as "Cust/Firm",
               tr.exec_broker                                  as "Exec Broker",
               tr.cmta                                         as "CMTA",
               tr.client_id                                    as "Client ID"

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
          and case when in_instrument_type is null then true else tr.instrument_type_id = in_instrument_type end
          and case
                  when coalesce(in_account_ids, '{}') = '{}' then true
                  else tr.account_id = any (in_account_ids) end
          and tr.multileg_reporting_type in ('1', '2')
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}' then da.trading_firm_id = any (in_trading_firm_ids)
                  else true end
        order by tr.date_id, tr.trade_record_id;

end;
$function$
;
