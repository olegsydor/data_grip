DROP FUNCTION trash.dash360_report_trades_v3;
select *
from trash.dash360_report_trades_v3(20251028, 20251028, 'E', '{63384}')
CREATE FUNCTION trash.dash360_report_trades_v3(in_date_begin_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                               in_date_end_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                               in_instrument_type character DEFAULT NULL::bpchar,
                                               in_account_ids integer[] DEFAULT '{}'::integer[],
                                               in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "Trading Firm"          varchar, -- 1
                "Account"               varchar(30),
                "Street Cl Ord ID"      varchar(256),
                "Cl Ord ID"             varchar(256),
                "Date"                  text, -- 5
                "Time"                  text,
                "Sec Type"              text,
                "Ex Dest"               varchar,
                "Sub Strategy"          varchar(128),
                "Fee Sensitivity"       int2, -- 10
                "Status"                varchar,
                "Side"                  text,
                "O/C"                   text,
                "Symbol"                varchar(100),
                "Last Qty"              int4, -- 15
                "Leaves Qty"            int4,
                "Last Px"               numeric(16, 8),
                "Last Mkt"              varchar(5),
                "Exchange Name"         varchar(256),
                "MIC Code"              varchar(4), -- 20
                "Bid Qty"               text,
                "Bid Px"                text,
                "Ask Px"                text,
                "Ask Qty"               int4,
                "Exec Bid Qty"          int4, -- 25
                "Exec Bid Px"           text,
                "Exec Ask Px"           text,
                "Exec Ask Qty"          int4,
                "Liquidity Ind"         varchar(256),
                "Liq Ind Description"   varchar(256), -- 30
                "Cust/Firm"             varchar(255),
                "Exec Broker"           varchar(32),
                "CMTA"                  varchar(3),
                "Client ID"             varchar(255),
                "Expiration"            text, -- 35
                "Root Symbol"           varchar(10),
                "Put/Call"              text,
                "Strike"                numeric(12, 4),
                "OSI Symbol"            varchar(30),
                "DB Exec ID"            int8, -- 40
                "Dash Exec ID"          varchar,
                "Exch Exec ID"          varchar(128),
                "Is Mleg"               text,
                "Is Cross"              bpchar(1),
                "Sending Firm"          varchar(30),  -- 45
                "Sub System"            varchar(20),
                "Free Text"             varchar(512),
                "Principal Amount"      numeric(16, 4),
                "Commission"            numeric(20, 8),
                "Exchange Fees"         text, -- 50
                "Exchange Fees/Unit"    text,
                "Execution Cost"        numeric(20, 8),
                "Execution Cost/Unit"   text,
                "Maker/Taker Fee"       numeric(20, 8),
                "Maker/Taker Fee/Unit"  text, -- 55
                "Transaction Fee"       text,
                "Trade Processing Fee"  text,
                "Royalty Fee"           text,
                "Option Regulatory Fee" text,
                "OCC Fee"               text, -- 60
                "SEC Fee"               text,
                "CAT Fee"               text,
                "Equity Clearing Fee"   text,
                "Contra Broker"         varchar(256),
                "Client Commission"     numeric, -- 65
                "Dash Liq Ind Type"     varchar(256),
                "OCC AID"               varchar
            )
    LANGUAGE plpgsql
AS
$function$

-- OS: 20251028 https://dashfinancial.atlassian.net/browse/DEVREQ-6992
declare
    l_load_id   int;
    l_step_id   int;
    l_row_count int4;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.MAREX - XFA for ' || in_date_begin_id::text || ' - ' ||
                           in_date_end_id::text ||
                           ' STARTED===', 0, 'O')
    into l_step_id;

    return query
        select replace(tf.trading_firm_name, ',', '')::varchar                          as "Trading Firm",
               da.account_name                                                          as "Account",
               tr.street_client_order_id                                                as "Street Cl Ord ID",
               tr.client_order_id                                                       as "Cl Ord ID",
               to_char(tr.trade_record_time, 'MM/DD/YYYY')                              as "Date",
               to_char(tr.trade_record_time, 'HH24:MI:SS.US')                           as "Time",
               case
                   when tr.instrument_type_id = 'E' then 'Equity'
                   when tr.instrument_type_id = 'O' then 'Option'
                   end                                                                  as "Sec Type",
               case
                   when tr.ex_destination in ('ALGO', 'SMART')
                       then tr.ex_destination || (case
                                                      when tr.instrument_type_id = 'O' then ' Options'
                                                      when tr.instrument_type_id = 'E' then ' Equities'
                                                      else '' end)
                   else exd.ex_destination_desc
                   end::varchar                                                         as "Ex Dest",
               tr.sub_strategy                                                          as "Sub Strategy",
               tr.fee_sensitivity                                                       as "Fee Sensitivity",
               os.order_status_description                                              as "Status",
               case
                   when tr.side = '1' then 'Buy'
                   when tr.side = '2' then 'Sell'
                   when tr.side in ('5', '6') then 'Sell Short'
                   else ''
                   end                                                                  as "Side",
               case
                   when tr.open_close = 'O' then 'Open'
                   when tr.open_close = 'C' then 'Close'
                   else '' end                                                          as "O/C",
               hsd.display_instrument_id                                                as "Symbol",
               tr.last_qty                                                              as "Last Qty",
               tr.leaves_qty                                                            as "Leaves Qty",
               tr.last_px                                                               as "Last Px",
               tr.last_mkt                                                              as "Last Mkt",
               ex.exchange_name                                                         as "Exchange Name",
               ex.mic_code                                                              as "MIC Code",
               tr.routing_time_bid_qty::text                                            as "Bid Qty",
               to_char(tr.routing_time_bid_price, 'FM999990.0099')                      as "Bid Px",
               to_char(tr.routing_time_ask_price, 'FM999990.0099')                      as "Ask Px",
               tr.routing_time_ask_qty                                                  as "Ask Qty",
               tr.bid_qty                                                               as "Exec Bid Qty",
               to_char(tr.bid_price, 'FM999990.0099')                                   as "Exec Bid Px",
               to_char(tr.ask_price, 'FM999990.0099')                                   as "Exec Ask Px",
               tr.ask_qty                                                               as "Exec Ask Qty",
               tr.trade_liquidity_indicator                                             as "Liquidity Ind",
               dlit.description                                                         as "Liq Ind Description",
               cf.customer_or_firm_name                                                 as "Cust/Firm",
               tr.exec_broker                                                           as "Exec Broker",
               tr.cmta                                                                  as "CMTA",
               tr.client_id                                                             as "Client ID",
               to_char(hsd.maturity_date, 'MM/DD/YYYY')                                 as "Expiration",
               coalesce(hsd.underlying_symbol, hsd.symbol)                              as "Root Symbol",
               case
                   when hsd.put_call = '0' then 'Put'
                   when hsd.put_call = '1' then 'Call'
                   else ''
                   end                                                                  as "Put/Call",
               hsd.strike_px                                                            as "Strike",
               hsd.opra_symbol                                                          as "OSI Symbol",
               tr.exec_id                                                               as "DB Exec ID",
               tr.exec_id::varchar                                                      as "Dash Exec ID",
               tr.exch_exec_id                                                          as "Exch Exec ID",
               case
                   when tr.multileg_reporting_type = '1'
                       then 'N'
                   else 'Y' end                                                         as "Is Mleg",
               tr.is_cross_order                                                        as "Is Cross",
               tr.fix_comp_id                                                           as "Sending Firm",
               tr.subsystem_id                                                          as "Sub System",
               lst_ex.exec_text                                                         as "Free Text",
               tr.principal_amount                                                      as "Principal Amount",
               tr.tcce_account_dash_commission_amount                                   as "Commission",
               to_char(round(coalesce(tr.tcce_transaction_fee_amount, 0) + coalesce(tr.tcce_maker_taker_fee_amount, 0) +
                             coalesce(tr.spread_transaction_fee_amount, 0) + coalesce(tr.tcce_royalty_fee_amount, 0) +
                             coalesce(tr.tcce_trade_processing_fee_amount, 0) + coalesce(tr.qcc_rebate_amount, 0), 4),
                       'FM999990.0000')                                                 as "Exchange Fees",
               to_char(round((coalesce(tr.tcce_transaction_fee_amount, 0) +
                              coalesce(tr.tcce_maker_taker_fee_amount, 0) +
                              coalesce(tr.spread_transaction_fee_amount, 0) + coalesce(tr.tcce_royalty_fee_amount, 0) +
                              coalesce(tr.tcce_trade_processing_fee_amount, 0) + coalesce(tr.qcc_rebate_amount, 0)) /
                             nullif(tr.last_qty, 0), 4),
                       'FM999990.0000')                                                 as "Exchange Fees/Unit",
               tr.tcce_account_execution_cost                                           as "Execution Cost",
               to_char(round(tr.tcce_account_execution_cost / nullif(tr.last_qty, 0), 4),
                       'FM999990.0000')                                                 as "Execution Cost/Unit",
               tr.tcce_maker_taker_fee_amount                                           as "Maker/Taker Fee",
               to_char(round(tr.tcce_maker_taker_fee_amount / nullif(tr.last_qty, 0), 4),
                       'FM999990.0000')                                                 as "Maker/Taker Fee/Unit",
               to_char(round(tr.tcce_transaction_fee_amount, 4), 'FM999990.0000')       as "Transaction Fee",
               to_char(round(tr.tcce_trade_Processing_Fee_Amount, 4), 'FM999990.0000')  as "Trade Processing Fee",
               to_char(round(tr.tcce_royalty_fee_amount, 4), 'FM999990.0000')           as "Royalty Fee",
               to_char(round(tr.tcce_option_regulatory_fee_amount, 4), 'FM999990.0000') as "Option Regulatory Fee",

               case
                   when tr.instrument_type_id = 'O'
                       then to_char(round(tr.tcce_occ_fee_amount, 4), 'FM999990.0000') end as "OCC Fee",
               to_char(round(tr.tcce_sec_fee_amount, 4), 'FM999990.0000')               as "SEC Fee",
               to_char(round(tr.cat_fee_amount, 4), 'FM999990.0000')                    as "CAT Fee",
               case
                   when tr.instrument_type_id = 'E'
                       then to_char(round(tr.clearing_fee_amout, 4), 'FM999990.0000') end as "Equity Clearing Fee",
               tr.contra_broker                                                         as "Contra Broker",
               tr.client_commission_rate * tr.last_qty                                  as "Client Commission",
               dlit.liquidity_indicator_type                                            as "Dash Liq Ind Type",
               tr.street_account_name::varchar                                          as "OCC AID"
        from dwh.flat_trade_record tr
                 join dwh.d_account da on (da.account_id = tr.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = da.trading_firm_unq_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                 left join dwh.d_customer_or_firm cf
                           on (cf.customer_or_firm_id = tr.opt_customer_firm and cf.is_active)
                 left join dwh.d_exchange ex on ex.exchange_id = tr.exchange_id and ex.is_active
                 left join dwh.d_ex_destination exd on exd.ex_destination_code = tr.ex_destination and
                                                       exd.exchange_id is not distinct from tr.exchange_id and
                                                       exd.instrument_type_id = tr.instrument_type_id and
                                                       exd.is_active
                 left join lateral ( select ex.exec_text, ex.order_status
                                     from dwh.execution ex
                                     where ex.order_id = tr.order_id
                                       and ex.exec_date_id between in_date_begin_id and in_date_end_id
                                       and ex.order_status <> '3'
                                     order by ex.exec_id desc
                                     limit 1 ) lst_ex on true
                 left join lateral (select dlit.liquidity_indicator_type, dli.description
                                    from dwh.d_liquidity_indicator dli
                                             inner join dwh.d_liquidity_indicator_type dlit
                                                        on dlit.liquidity_indicator_type_id = dli.liquidity_indicator_type_id
                                    where dli.trade_liquidity_indicator = tr.trade_liquidity_indicator
                                      and dli.exchange_id = tr.exchange_id
                                      and dli.is_active ) dlit on true
                 left join dwh.d_order_status os on lst_ex.order_status = os.order_status
        where tr.date_id between in_date_begin_id and in_date_end_id
          and tr.is_busted <> 'Y'
          and da.account_name not in (select * from fintech_dwh.users_fbw_tb)
          and case when in_instrument_type is null then true else tr.instrument_type_id = in_instrument_type end
          and case
                  when coalesce(in_account_ids, '{}') = '{}' then true
                  else tr.account_id = any (in_account_ids) end
          and tr.multileg_reporting_type in ('1', '2')
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'
                      then da.trading_firm_id = any (in_trading_firm_ids)
                  else true end
        order by tr.date_id, tr.trade_record_id;

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.MAREX - XFA for ' || in_date_begin_id::text || ' - ' || in_date_end_id::text ||
                           ' COMPLETED===', l_row_count, 'C')
    into l_step_id;
end;
$function$
;



select
from dash_reporting.imc_base_ext_md

