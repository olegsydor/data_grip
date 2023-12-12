create or replace function dash360.report_fintech_eod_saxopts_execution(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                rec text
            )
    language plpgsql
as
$fx$
declare
    l_load_id int;
    l_step_id int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_saxopts_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::Text || 'STARTED ====', in_start_date_id,
                           'O')
    into l_step_id;
    return query
        select 'Trading Firm, Account, Cl Ord ID, Street Cl Ord ID, Date, Time, Sec Type, Ex Dest, Sub Strategy, Side, O/C, Symbol, Last Qty, Last Px, Principal Amount, Last Mkt, Exchange Name, Liquidity Ind, Cust/Firm, Exec Broker, CMTA, Client ID, OSI Symbol, Root Symbol, Expiration, Put/Call, Strike, Contract Multiplier, Currency, Dash Exec ID, Exch Exec ID, Is Mleg, Is Cross, Sending Firm, Sub System, Free Text, Commission, Execution Cost, Maker/Taker Fee, Transaction Fee, Trade Processing Fee, Royalty Fee, Option Regulatory Fee, OCC Fee, SEC Fee';
    return query
        select "Trading Firm" || ',' ||
               "Account" || ',' ||
               "Cl Ord ID" || ',' ||
               coalesce("Street Cl Ord ID", '') || ',' ||
               "Date" || ',' ||
               "Time" || ',' ||
               "Sec Type" || ',' ||
               coalesce("Ex Dest", '') || ',' ||
               coalesce("Sub Strategy", '') || ',' ||
               "Side" || ',' ||
               "O/C" || ',' ||
               "Symbol" || ',' ||
               "Last Qty"::text || ',' ||
               "Last Px"::text || ',' ||
               coalesce("Principal Amount"::text, '') || ',' ||
               "Last Mkt" || ',' ||
               "Exchange Name" || ',' ||
               coalesce("Liquidity Ind", '') || ',' ||
               coalesce("Cust/Firm", '') || ',' ||
               "Exec Broker" || ',' ||
               coalesce("CMTA", '') || ',' ||
               coalesce("Client ID", '') || ',' ||
               coalesce("OSI Symbol", '') || ',' ||
               "Root Symbol" || ',' ||
               "Expiration" || ',' ||
               "Put/Call" || ',' ||
               "Strike"::text || ',' ||
               coalesce("Contract Multiplier"::text, '') || ',' ||
               "Currency" || ',' ||
               "Dash Exec ID"::text || ',' ||
               coalesce("Exch Exec ID", '') || ',' ||
               "Is Mleg" || ',' ||
               "Is Cross" || ',' ||
               "Sending Firm" || ',' ||
               "Sub System" || ',' ||
               coalesce("Free Text", '') || ',' ||
               coalesce("Commission"::text, '') || ',' ||
               coalesce("Execution Cost"::text, '') || ',' ||
               coalesce("Maker/Taker Fee"::text, '') || ',' ||
               coalesce("Transaction Fee"::text, '') || ',' ||
               coalesce("Trade Processing Fee"::text, '') || ',' ||
               coalesce("Royalty Fee"::text, '') || ',' ||
               coalesce("Option Regulatory Fee"::text, '') || ',' ||
               coalesce("OCC Fee"::text, '') || ',' ||
               coalesce("SEC Fee"::text, '')
        from (select replace(tf.trading_firm_name, ',', '')::varchar as "Trading Firm",
                     da.account_name                                 as "Account",
                     tr.client_order_id                              as "Cl Ord ID",
                     tr.street_client_order_id                       as "Street Cl Ord ID",
                     to_char(tr.trade_record_time, 'MM/DD/YYYY')     as "Date",
                     to_char(tr.trade_record_time, 'HH24:MI:SS.US')  as "Time",
                     case
                         when tr.instrument_type_id = 'E' then 'Equity'
                         when tr.instrument_type_id = 'O' then 'Option'
                         end                                         as "Sec Type",
                     --coalesce(exd.ex_destination_desc, tr.ex_destination) as "Ex Dest",
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
                     hsd.display_instrument_id                       as "Symbol",
                     tr.last_qty                                     as "Last Qty",
                     tr.last_px                                      as "Last Px",
                     tr.principal_amount                             as "Principal Amount",
                     tr.last_mkt                                     as "Last Mkt",
                     ex.exchange_name                                as "Exchange Name",
                     tr.trade_liquidity_indicator                    as "Liquidity Ind",
                     cf.customer_or_firm_name                        as "Cust/Firm",
                     tr.exec_broker                                  as "Exec Broker",
                     tr.cmta                                         as "CMTA",
                     tr.client_id                                    as "Client ID",
                     hsd.opra_symbol                                 as "OSI Symbol",
                     coalesce(hsd.underlying_symbol, hsd.symbol)     as "Root Symbol",
                     to_char(hsd.maturity_date, 'MM/DD/YYYY')        as "Expiration",
                     case
                         when hsd.put_call = '0' then 'Put'
                         when hsd.put_call = '1' then 'Call'
                         else ''
                         end                                         as "Put/Call", -- Changed insted of clear put_call
                     hsd.strike_px                                   as "Strike",
                     hsd.contract_multiplier                         as "Contract Multiplier",
                     'USD'::varchar                                  as "Currency",
                     tr.exec_id                                      as "Dash Exec ID",
                     tr.exch_exec_id                                 as "Exch Exec ID",
                     case
                         when tr.multileg_reporting_type = '1'
                             then 'N'
                         else 'Y' end                                as "Is Mleg",
                     tr.is_cross_order                               as "Is Cross",
                     tr.fix_comp_id                                  as "Sending Firm",
                     tr.subsystem_id                                 as "Sub System",
--        tr.trade_text                                   as "Free Text from trade_record", -- took text from trade_record
                     lst_ex.text_                                    as "Free Text",
                     tr.tcce_account_dash_commission_amount          as "Commission",
                     tr.tcce_account_execution_cost                  as "Execution Cost",
                     tr.tcce_maker_taker_fee_amount                  as "Maker/Taker Fee",
                     tr.tcce_transaction_fee_amount                  as "Transaction Fee",
                     tr.tcce_trade_processing_fee_amount             as "Trade Processing Fee",
                     tr.tcce_royalty_fee_amount                      as "Royalty Fee",
                     tr.tcce_option_regulatory_fee_amount            as "Option Regulatory Fee",
                     tr.tcce_occ_fee_amount                          as "OCC Fee",
                     tr.tcce_sec_fee_amount                          as "SEC Fee"
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
                  select ex.text_
                  from dwh.execution ex
                  where ex.order_id = tr.order_id
                    and ex.exec_date_id between in_start_date_id and in_end_date_id
                    and ex.order_status <> '3'
                  order by ex.exec_id desc
                  limit 1
                  ) lst_ex on true
              where tr.date_id between in_start_date_id and in_end_date_id
                and tr.is_busted <> 'Y'
                 and tr.trading_firm_id = 'saxopts'
                and tr.instrument_type_id = 'O'
                and tr.multileg_reporting_type in ('1', '2')
              order by tr.date_id, tr.trade_record_id) x;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_saxopts_execution FINISHED ====', in_start_date_id,
                           'O')
    into l_step_id;
end;
$fx$;

------------------------


create or replace function trash.report_fintech_eod_saxopts_execution(in_start_date_id int4, in_end_date_id int4)
    returns table
            (

                "Trading Firm"          varchar,
                "Account"               varchar(30),
                "Cl Ord ID"             varchar(256),
                "Street Cl Ord ID"      varchar(256),
                "Date"                  text,
                "Time"                  text,
                "Sec Type"              text,
                "Ex Dest"               varchar,
                "Sub Strategy"          varchar(128),
                "Side"                  text,
                "O/C"                   text,
                "Symbol"                varchar(100),
                "Last Qty"              int4,
                "Last Px"               numeric(16, 8),
                "Principal Amount"      numeric(16, 4),
                "Last Mkt"              varchar(5),
                "Exchange Name"         varchar(256),
                "Liquidity Ind"         varchar(256),
                "Cust/Firm"             varchar(255),
                "Exec Broker"           varchar(32),
                "CMTA"                  varchar(3),
                "Client ID"             varchar(255),
                "OSI Symbol"            varchar(30),
                "Root Symbol"           varchar(10),
                "Expiration"            text,
                "Put/Call"              text,
                "Strike"                numeric(12, 4),
                "Contract Multiplier"   int4,
                "Currency"              varchar,
                "Dash Exec ID"          int8,
                "Exch Exec ID"          varchar(128),
                "Is Mleg"               text,
                "Is Cross"              bpchar(1),
                "Sending Firm"          varchar(30),
                "Sub System"            varchar(20),
                "Free Text"             varchar(512),
                "Commission"            numeric(16, 4),
                "Execution Cost"        numeric(16, 4),
                "Maker/Taker Fee"       numeric(16, 4),
                "Transaction Fee"       numeric(16, 4),
                "Trade Processing Fee"  numeric(16, 4),
                "Royalty Fee"           numeric(16, 4),
                "Option Regulatory Fee" numeric(16, 4),
                "OCC Fee"               numeric(16, 4),
                "SEC Fee"               numeric(16, 4)
            )
    language plpgsql
as
$fx$
declare
    l_load_id int;
    l_step_id int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_saxopts_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::Text || 'STARTED ====', in_start_date_id,
                           'O')
    into l_step_id;
    return query
        select replace(tf.trading_firm_name, ',', '')::varchar as "Trading Firm",
               da.account_name                                 as "Account",
               tr.client_order_id                              as "Cl Ord ID",
               tr.street_client_order_id                       as "Street Cl Ord ID",
               to_char(tr.trade_record_time, 'MM/DD/YYYY')     as "Date",
               to_char(tr.trade_record_time, 'HH24:MI:SS.US')  as "Time",
               case
                   when tr.instrument_type_id = 'E' then 'Equity'
                   when tr.instrument_type_id = 'O' then 'Option'
                   end                                         as "Sec Type",
               --coalesce(exd.ex_destination_desc, tr.ex_destination) as "Ex Dest",
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
               hsd.display_instrument_id                       as "Symbol",
               tr.last_qty                                     as "Last Qty",
               tr.last_px                                      as "Last Px",
               tr.principal_amount                             as "Principal Amount",
               tr.last_mkt                                     as "Last Mkt",
               ex.exchange_name                                as "Exchange Name",
               tr.trade_liquidity_indicator                    as "Liquidity Ind",
               cf.customer_or_firm_name                        as "Cust/Firm",
               tr.exec_broker                                  as "Exec Broker",
               tr.cmta                                         as "CMTA",
               tr.client_id                                    as "Client ID",
               hsd.opra_symbol                                 as "OSI Symbol",
               coalesce(hsd.underlying_symbol, hsd.symbol)     as "Root Symbol",
               to_char(hsd.maturity_date, 'MM/DD/YYYY')        as "Expiration",
               case
                   when hsd.put_call = '0' then 'Put'
                   when hsd.put_call = '1' then 'Call'
                   else ''
                   end                                         as "Put/Call", -- Changed insted of clear put_call
               hsd.strike_px                                   as "Strike",
               hsd.contract_multiplier                         as "Contract Multiplier",
               'USD'::varchar                                  as "Currency",
               tr.exec_id                                      as "Dash Exec ID",
               tr.exch_exec_id                                 as "Exch Exec ID",
               case
                   when tr.multileg_reporting_type = '1'
                       then 'N'
                   else 'Y' end                                as "Is Mleg",
               tr.is_cross_order                               as "Is Cross",
               tr.fix_comp_id                                  as "Sending Firm",
               tr.subsystem_id                                 as "Sub System",
--        tr.trade_text                                   as "Free Text from trade_record", -- took text from trade_record
               lst_ex.text_                                    as "Free Text",
               tr.tcce_account_dash_commission_amount          as "Commission",
               tr.tcce_account_execution_cost                  as "Execution Cost",
               tr.tcce_maker_taker_fee_amount                  as "Maker/Taker Fee",
               tr.tcce_transaction_fee_amount                  as "Transaction Fee",
               tr.tcce_trade_processing_fee_amount             as "Trade Processing Fee",
               tr.tcce_royalty_fee_amount                      as "Royalty Fee",
               tr.tcce_option_regulatory_fee_amount            as "Option Regulatory Fee",
               tr.tcce_occ_fee_amount                          as "OCC Fee",
               tr.tcce_sec_fee_amount                          as "SEC Fee"
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
            select ex.text_
            from dwh.execution ex
            where ex.order_id = tr.order_id
              and ex.exec_date_id between in_start_date_id and in_end_date_id
              and ex.order_status <> '3'
            order by ex.exec_id desc
            limit 1
            ) lst_ex on true
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.is_busted <> 'Y'
          and tr.trading_firm_id = 'saxopts'
          and tr.instrument_type_id = 'O'
          and tr.multileg_reporting_type in ('1', '2')
        order by tr.date_id, tr.trade_record_id;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_saxopts_execution FINISHED ====', in_start_date_id,
                           'O')
    into l_step_id;

end;
$fx$;

select *
from dash.report_fintech_eod_saxopts_execution(in_start_date_id := 20230807, in_end_date_id := 20230807)
where rec is null