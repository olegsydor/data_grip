DROP FUNCTION trash.dash360_report_trades_v3(_varchar, _int8, varchar, int4, int4, timestamp, timestamp, bpchar,
                                             _varchar, _varchar, _varchar);

CREATE FUNCTION trash.dash360_report_trades_v3(in_start_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                               in_end_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                               in_instrument_type character DEFAULT NULL::bpchar,
                                               in_account_ids integer[] DEFAULT '{}'::integer[],
                                               in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "Trading Firm"          character varying,
                "Account"               character varying,
                "Street Cl Ord ID"      character varying,
                "Cl Ord ID"             character varying,
                "Date"                  text,
                "Time"                  text,
                "Sec Type"              text,
                "Ex Dest"               character varying,
                "Sub Strategy"          character varying,
                "Side"                  text,
                "O/C"                   text,
                "Symbol"                character varying,
                "Last Qty"              integer,
                "Last Px"               numeric,
                "Principal Amount"      numeric,
                "Last Mkt"              character varying,
                "Exchange Name"         character varying,
                "Liquidity Ind"         character varying,
                "Cust/Firm"             character varying,
                "Exec Broker"           character varying,
                "CMTA"                  character varying,
                "Client ID"             character varying,
                "OSI Symbol"            character varying,
                "Root Symbol"           character varying,
                "Expiration"            text,
                "Put/Call"              text,
                "Strike"                numeric,
                "Dash Exec ID"          character varying,
                "Exch Exec ID"          character varying,
                "Is Mleg"               text,
                "Is Cross"              character,
                "Sending Firm"          character varying,
                "Sub System"            character varying,
                "Free Text"             character varying,
                "Commission"            numeric,
                "Execution Cost"        numeric,
                "Maker/Taker Fee"       numeric,
                "Transaction Fee"       numeric,
                "Trade Processing Fee"  numeric,
                "Royalty Fee"           numeric,
                "Option Regulatory Fee" numeric,
                "OCC Fee"               numeric,
                "SEC Fee"               numeric,
                "Client Commission"     numeric,
                "Dash Liq Ind Type"     character varying,
                "OCC AID"               character varying
            )
    LANGUAGE plpgsql
AS
$function$

-- OS: 20251028 https://dashfinancial.atlassian.net/browse/DEVREQ-6992
declare
    -- If you renaming this script change the alias for value f_instrument_type_id
    f_instrument_type_id char := dash360_report_trades_v2.instrument_type_id;
    l_array_symbol       varchar[];

begin
    return query
        select -- just for debagging
               replace(tf.trading_firm_name, ',', '')::varchar     as "Trading Firm",
               da.account_name                                     as "Account",
               tr.street_client_order_id                           as "Street Cl Ord ID",
               tr.client_order_id                                  as "Cl Ord ID",
               to_char(tr.trade_record_time, 'MM/DD/YYYY')         as "Date",
               to_char(tr.trade_record_time, 'HH24:MI:SS.US')      as "Time",
               case
                   when tr.instrument_type_id = 'E' then 'Equity'
                   when tr.instrument_type_id = 'O' then 'Option'
                   end                                             as "Sec Type",
               case
                   when tr.ex_destination in ('ALGO', 'SMART')
                       then tr.ex_destination || (case
                                                      when tr.instrument_type_id = 'O' then ' Options'
                                                      when tr.instrument_type_id = 'E' then ' Equities'
                                                      else '' end)
                   else exd.ex_destination_desc
                   end::varchar                                    as "Ex Dest",
               tr.sub_strategy                                     as "Sub Strategy",
               tr.fee_sensitivity                                  as "Fee Sensitivity",
               os.order_status_description                         as "Status",
               case
                   when tr.side = '1' then 'Buy'
                   when tr.side = '2' then 'Sell'
                   when tr.side in ('5', '6') then 'Sell Short'
                   else ''
                   end                                             as "Side",
               case
                   when tr.open_close = 'O' then 'Open'
                   when tr.open_close = 'C' then 'Close'
                   else '' end                                     as "O/C",
               hsd.display_instrument_id                           as "Symbol",
               tr.last_qty                                         as "Last Qty",
               tr.leaves_qty                                       as "Leaves Qty",
               tr.last_px                                          as "Last Px",
               tr.last_mkt                                         as "Last Mkt",
               ex.exchange_name                                    as "Exchange Name",
               ex.mic_code                                         as "MIC Code",
               tr.routing_time_bid_qty::text                       as "Bid Qty",
               to_char(tr.routing_time_bid_price, 'FM999990.0099') as "Bid Px",
               to_char(tr.routing_time_ask_price, 'FM999990.0099') as "Ask Px",
               tr.routing_time_ask_qty                             as "Ask Qty",
               tr.bid_qty                                          as "Exec Bid Qty",
               to_char(tr.bid_price, 'FM999990.0099')              as "Exec Bid Px",
               to_char(tr.ask_price, 'FM999990.0099')              as "Exec Ask Px",
               tr.ask_qty                                          as "Exec Ask Qty",
               tr.trade_liquidity_indicator                        as "Liquidity Ind",
               dlit.description                                    as "Liq Ind Description",
               cf.customer_or_firm_name                            as "Cust/Firm",
               tr.exec_broker                                      as "Exec Broker",
               tr.cmta                                             as "CMTA",
               tr.client_id                                        as "Client ID",
               to_char(hsd.maturity_date, 'MM/DD/YYYY')            as "Expiration",
               coalesce(hsd.underlying_symbol, hsd.symbol)         as "Root Symbol",
               case
                   when hsd.put_call = '0' then 'Put'
                   when hsd.put_call = '1' then 'Call'
                   else ''
                   end                                             as "Put/Call",
               hsd.strike_px                                       as "Strike",
               hsd.opra_symbol                                     as "OSI Symbol",
               tr.exec_id as "DB Exec ID",
               tr.exec_id::varchar                                 as "Dash Exec ID",
               tr.exch_exec_id                                     as "Exch Exec ID",
               case
                   when tr.multileg_reporting_type = '1'
                       then 'N'
                   else 'Y' end                                    as "Is Mleg",
               tr.is_cross_order                                   as "Is Cross",
               tr.fix_comp_id                                      as "Sending Firm",
               tr.subsystem_id                                     as "Sub System",
               lst_ex.exec_text                                    as "Free Text",
               tr.tcce_account_dash_commission_amount              as "Commission",
               tr.tcce_account_execution_cost                      as "Execution Cost",
               tr.tcce_maker_taker_fee_amount                      as "Maker/Taker Fee",
               tr.tcce_transaction_fee_amount                      as "Transaction Fee",
               tr.tcce_trade_processing_fee_amount                 as "Trade Processing Fee",
               tr.tcce_royalty_fee_amount                          as "Royalty Fee",
               tr.tcce_option_regulatory_fee_amount                as "Option Regulatory Fee",
               tr.tcce_occ_fee_amount                              as "OCC Fee",
               tr.tcce_sec_fee_amount                              as "SEC Fee",
               tr.client_commission_rate * tr.last_qty             as "Client Commission",
               dlit.liquidity_indicator_type                       as "Dash Liq Ind Type",
               tr.street_account_name::varchar                     as "OCC AID",
               tr.principal_amount                                 as "Principal Amount",

        from dwh.flat_trade_record tr
                 join dwh.d_account da on (da.account_id = tr.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = da.trading_firm_unq_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                 left join dwh.d_customer_or_firm cf
                           on (cf.customer_or_firm_id = tr.opt_customer_firm and cf.is_active)
                 left join dwh.d_exchange ex on (ex.exchange_id = tr.exchange_id and ex.is_active)
                 left join dwh.d_ex_destination exd on (exd.ex_destination_code = tr.ex_destination and
                                                        coalesce(exd.exchange_id, '') =
                                                        coalesce(tr.exchange_id, '') and
                                                        exd.instrument_type_id = tr.instrument_type_id and
                                                        exd.is_active)
                 left join lateral
            (
            select ex.exec_text, ex.order_status
            from dwh.execution ex
            where ex.order_id = tr.order_id
              and ex.exec_date_id between in_start_date_id and in_end_date_id
              and ex.order_status <> '3'
            order by ex.exec_id desc
            limit 1
            ) lst_ex on true
                 left join lateral (select dlit.liquidity_indicator_type, dli.description
                                    from dwh.d_liquidity_indicator dli
                                             inner join dwh.d_liquidity_indicator_type dlit
                                                        on dlit.liquidity_indicator_type_id = dli.liquidity_indicator_type_id
                                    where dli.trade_liquidity_indicator = tr.trade_liquidity_indicator
                                      and dli.exchange_id = tr.exchange_id
                                      and dli.is_active ) dlit on true
                 left join dwh.d_order_status os on lst_ex.order_status = os.order_status
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
