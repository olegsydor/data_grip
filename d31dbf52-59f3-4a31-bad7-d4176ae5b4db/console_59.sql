/*
dash360.report_fintech_adh_allocation_xls
dash360.report_fintech_adh_execution_xls
dash360.report_fintech_adh_occ_contra
dash360.report_fintech_adh_order_xls
dash360.report_gtc_recon
dash360.report_obo_compliance_xls
*/

-- DROP FUNCTION dash360.report_fintech_adh_allocation_xls(int4, int4, _int4, bpchar);

select *
from dash360.report_fintech_adh_allocation_xls(in_start_date_id := 20240418, in_end_date_id := 20240418,
                                               in_instrument_type := 'E', in_trading_firm_ids := '{"cmtgmbh", "baml"}');
select *
from dash360.report_fintech_adh_execution_xls(in_start_date_id := 20240418, in_end_date_id := 20240418,
                                              in_instrument_type := 'E', in_trading_firm_ids := '{"cmtgmbh", "baml"}');
select *
from dash360.report_fintech_adh_order_xls(in_start_date_id := 20240418, in_end_date_id := 20240418,
                                          in_instrument_type := 'E', in_trading_firm_ids := '{"cmtgmbh", "baml"}');
select *
from dash360.report_gtc_recon(in_start_date_id := 20240418, in_end_date_id := 20240419, in_instrument_type_id := 'O',
                              in_account_ids := '{2928,11203,11209}', in_trading_firm_ids := '{"dashdesk", "stifel"}');
select *
from dash360.report_obo_compliance_xls(in_date_begin_id := 20240418, in_date_end_id := 20240418,
                                       in_trading_firm_ids := '{"cmtgmbh", "baml"}');

CREATE FUNCTION dash360.report_fintech_adh_allocation_xls(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                                     in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                                     in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                     in_instrument_type character DEFAULT NULL::bpchar,
                                                                     in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "Trading Firm"         character varying,
                "Account"              character varying,
                "Date"                 text,
                "OCC AID"              character varying,
                "Clearing Account"     character varying,
                "Settlement Date"      character varying,
                "Alloc ID"             integer,
                "Allocated By"         character varying,
                "Alloc Time"           text,
                "Sec Type"             text,
                "Symbol"               character varying,
                "Side"                 text,
                "O/C"                  text,
                "Exec Qty"             bigint,
                "Avg Px"               numeric,
                "Alloc Qty"            bigint,
                "Pricipal Amount"      numeric,
                "CMTA"                 character varying,
                "OSI Symbol"           character varying,
                "Root Symbol"          character varying,
                "Expiration"           text,
                "Put/Call"             text,
                "Strike"               numeric,
                "Commission"           numeric,
                "Execution Cost"       numeric,
                "Maker/Taker Fee"      numeric,
                "Transaction Fee"      numeric,
                "Trade Processing Fee" numeric,
                "Royalty Fee"          numeric
            )
    LANGUAGE plpgsql
AS
$function$

begin
    return query
        with ftr as (select tr.date_id,
                            tr.trade_record_time::date                                  as trade_record_time,
                            tr.instrument_type_id,
                            sum(tr.last_qty)                                            as sum_last_qty,
                            sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
                            tr.open_close,
                            --tr.order_id,
                            tr.instrument_id,
                            tr.account_id,
                            tr.side,
                            tr.cmta,
                            at.alloc_qty                                                as alloc_qty,
                            at.alloc_instr_id                                           as alloc_instr_id,
                            at.clearing_account_id                                      as clearing_account_id,
                            sum(coalesce(tr.tcce_maker_taker_fee_amount, 0.0))          as tcce_maker_taker_fee_amount,
                            sum(coalesce(tr.tcce_account_dash_commission_amount, 0.0))  as tcce_account_dash_commission_amount, --
                            sum(coalesce(tr.tcce_transaction_fee_amount, 0.0))          as tcce_transaction_fee_amount,
                            sum(coalesce(tr.tcce_trade_processing_fee_amount, 0.0))     as tcce_trade_processing_fee_amount,
                            sum(coalesce(tr.tcce_royalty_fee_amount, 0.0))              as tcce_royalty_fee_amount,
                            sum(tr.principal_amount)                                    as principal_amount,
                            sum(coalesce(tr.tcce_account_execution_cost, 0.0))          as tcce_account_execution_cost
                     from dwh.flat_trade_record tr
                              join dwh.d_account acc on (acc.account_id = tr.account_id and acc.is_active)
                              left join lateral (select alloc_qty, alloc_instr_id, clearing_account_id
                                                 from dwh.allocation2trade_record atr
                                                 where atr.trade_record_id = tr.trade_record_id
                                                   and atr.date_id = tr.date_id
                                                   and atr.is_active
                                                 limit 1) at on true
                     where tr.date_id between in_start_date_id and in_end_date_id
                       and is_busted = 'N'
                       and tr.order_id > 0
                       and case when in_account_ids = '{}' then true else acc.account_id = any (in_account_ids) end
                       and case when in_trading_firm_ids <> '{}' then acc.trading_firm_id = any(in_trading_firm_ids) else 1=1 end
                       and case
                               when in_instrument_type is null then true
                               else tr.instrument_type_id = in_instrument_type end
                     group by tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, tr.cmta,
                              at.alloc_qty, tr.trade_record_time::date,
                              tr.instrument_type_id, at.alloc_instr_id, at.clearing_account_id)
           , base as (select tf.trading_firm_name                         as "Trading Firm",
                             ac.account_name                              as "Account",
                             to_char(ftr.trade_record_time, 'MM/DD/YYYY') as "Date",
                             to_char(public.get_settle_date_by_instrument_type(ftr.trade_record_time::date,
                                                                               ftr.instrument_type_id),
                                     'MM/DD/YYYY')::varchar               as "Settlement Date",
                             ftr.alloc_instr_id                           as "Alloc ID",
                             ftr.clearing_account_id                      as "Clearing Account ID",
                             case
                                 when ftr.instrument_type_id = 'E' then 'Equity'
                                 when ftr.instrument_type_id = 'O' then 'Option'
                                 end                                      as "Sec Type",
                             hsd.display_instrument_id                    as "Symbol",
                             case
                                 when ftr.side = '1' then 'Buy'
                                 when ftr.side = '2' then 'Sell'
                                 when ftr.side in ('5', '6') then 'Sell Short'
                                 else ''
                                 end                                      as "Side",
                             case
                                 when ftr.open_close = 'O' then 'Open'
                                 when ftr.open_close = 'C' then 'Close'
                                 else '' end                              as "O/C",
                             ftr.sum_last_qty                             as "Exec Qty",
                             round(ftr.avg_px, 4)                         as "Avg Px",
                             coalesce(ftr.alloc_qty, ftr.sum_last_qty)    as "Alloc Qty",
                             ftr.principal_amount                         as "Pricipal Amount",
                             ftr.cmta                                     as "CMTA",
                             coalesce(hsd.opra_symbol, hsd.symbol)        as "OSI Symbol",
                             hsd.underlying_symbol                        as "Root Symbol",
                             to_char(hsd.maturity_date, 'MM/DD/YYYY')     as "Expiration",
                             case
                                 when hsd.put_call = '0' then 'Put'
                                 when hsd.put_call = '1' then 'Call'
                                 else ''
                                 end                                      as "Put/Call",
                             hsd.strike_px                                as "Strike",
                             round(ftr.tcce_account_dash_commission_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                     as "Commission",
                             round(ftr.tcce_account_execution_cost / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                     as "Execution Cost",
                             round(ftr.tcce_maker_taker_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                     as "Maker/Taker Fee",
                             round(ftr.tcce_transaction_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                     as "Transaction Fee",
                             round(ftr.tcce_trade_processing_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                     as "Trade Processing Fee",
                             round(ftr.tcce_royalty_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                     as "Royalty Fee"
                      from ftr
                               join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                               join dwh.d_account ac on ac.account_id = ftr.account_id
                               join dwh.d_trading_firm tf on tf.trading_firm_unq_id = ac.trading_firm_unq_id
                               join dwh.historic_security_definition_all hsd on (hsd.instrument_id = ftr.instrument_id))
           , aie as (select *
                     from staging.allocation_instruction_entry
                     where date_id between in_start_date_id and in_end_date_id
                     order by alloc_instr_id)
        select base."Trading Firm",
               base."Account",
               base."Date",
               aie.occ_actionable_id                             as "OCC AID",
               coalesce(ca.clearing_account_number, base."CMTA") as "Clearing Account",
               base."Settlement Date",
               base."Alloc ID",
               case
                   when ai.created_by_subsystem_id = 'RPS' then 'auto'
                   else ui.user_name
                   end                                           as "Allocated By",
               to_char(ai.create_time, 'HH24:MI:SS.US')          as "Alloc Time",
               base."Sec Type",
               base."Symbol",
               base."Side",
               base."O/C",
               base."Exec Qty",
               base."Avg Px",
               base."Alloc Qty",
               base."Pricipal Amount",
               base."CMTA",
               base."OSI Symbol",
               base."Root Symbol",
               base."Expiration",
               base."Put/Call",
               base."Strike",
               base."Commission",
               base."Execution Cost",
               base."Maker/Taker Fee",
               base."Transaction Fee",
               base."Trade Processing Fee",
               base."Royalty Fee"
        from base
                 left join lateral (select *
                                    from staging.allocation_instruction ai
                                    where ai.alloc_instr_id = base."Alloc ID"
                                      and ai.date_id between in_start_date_id and in_end_date_id
                                      and ai.is_deleted = 'N'
                                    limit 1) ai on true
                 left join aie on (aie.alloc_instr_id = base."Alloc ID" and aie.clearing_account_id = base."Clearing Account ID" and aie.date_id = ai.date_id)
                 left join dwh.d_user_identifier ui on (ui.user_id = ai.created_by_user_id)
                 left join dwh.d_clearing_account ca
                           on (ca.clearing_account_id = aie.clearing_account_id)
        order by base."Date", base."Trading Firm", base."Account", base."Symbol", base."Side";


end ;
$function$
;


-- DROP FUNCTION dash360.report_fintech_adh_execution_xls(int4, int4, bpchar, _int4);

CREATE FUNCTION dash360.report_fintech_adh_execution_xls(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                                    in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
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
                "Dash Exec ID"          bigint,
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
                "SEC Fee"               numeric
            )
    LANGUAGE plpgsql
AS $function$
declare
begin
    return query
        select -- just for debagging
               replace(tf.trading_firm_name, ',', '')::varchar as "Trading Firm",
               da.account_name                                 as "Account",
               tr.street_client_order_id                       as "Street Cl Ord ID",
               tr.client_order_id                              as "Cl Ord ID",
               to_char(tr.trade_record_time, 'MM/DD/YYYY')     as "Date",
               to_char(tr.trade_record_time, 'HH24:MI:SS.US')  as "Time",
               case
                   when tr.instrument_type_id = 'E' then 'Equity'
                   when tr.instrument_type_id = 'O' then 'Option'
                   end                                         as "Sec Type",
               --coalesce(exd.ex_destination_desc, tr.ex_destination) as "Ex Dest",
               case
	               when tr.ex_destination in ('ALGO', 'SMART')
	                   then tr.ex_destination || (case when tr.instrument_type_id = 'O' then ' Options' when tr.instrument_type_id = 'E' then ' Equities' else '' end)
	               else exd.ex_destination_desc
	           end::varchar                                    as "Ex Dest",
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
          and da.account_name not in (select * from fintech_dwh.users_fbw_tb)
          and case when in_instrument_type is null then true else tr.instrument_type_id = in_instrument_type end
          and case
                  when coalesce(in_account_ids, '{}') = '{}' then true
                  else tr.account_id = any (in_account_ids) end
          and tr.multileg_reporting_type in ('1', '2')
          and case when in_trading_firm_ids <> '{}' then da.trading_firm_id = any(in_trading_firm_ids) else true end
        order by tr.date_id, tr.trade_record_id;
end;
$function$
;



-- DROP FUNCTION dash360.report_fintech_adh_order_xls(int4, int4, bpchar, _int4, text, character varying[]);

CREATE FUNCTION dash360.report_fintech_adh_order_xls(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                                in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                                in_instrument_type character DEFAULT NULL::bpchar,
                                                                in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                in_row_type text DEFAULT NULL::text,
                                                                in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "Row Type"                  text,
                "Trading Firm"              character varying,
                "Account"                   character varying,
                "Cl Ord ID"                 character varying,
                "Orig Cl Ord ID"            character varying,
                "Order Status"              character varying,
                "Ord Type"                  character varying,
                "Create Date"               text,
                "Create Time"               text,
                "Routed Time"               text,
                "Event Date"                text,
                "Event Time"                text,
                "Sec Type"                  text,
                "Ex Dest"                   character varying,
                "Sub Strategy"              character varying,
                "Side"                      text,
                "O/C"                       text,
                "Symbol"                    character varying,
                "Order Qty"                 integer,
                "Price"                     numeric,
                "Ex Qty"                    integer,
                "Avg Px"                    numeric,
                "Lvs Qty"                   integer,
                "Exchange Name"             character varying,
                "Cust/Firm"                 character varying,
                "CMTA"                      character varying,
                "Client ID"                 character varying,
                "OSI Symbol"                character varying,
                "Root Symbol"               character varying,
                "Expiration"                text,
                "Put/Call"                  character,
                "Strike"                    numeric,
                "Is Mleg"                   text,
                "Is Cross"                  text,
                "TIF"                       character varying,
                "Max Floor"                 bigint,
                "Held Status"               text,
                "Alternative Compliance ID" text,
                "Compliance ID"             text,
                "Handling Instructions"     text,
                "Execution Instructions"    text,
                "Leg ID"                    character varying,
                "Free Text"                 character varying
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_account_ids    integer[];
begin
    if in_account_ids = '{}' and in_trading_firm_ids = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
            and case when in_trading_firm_ids <> '{}'::varchar[] then trading_firm_id = ANY (in_trading_firm_ids) end
           or case when in_account_ids <> '{}'::integer[] then account_id = ANY (in_account_ids) end;
    end if;
    return query
        select case when yc.parent_order_id is null then 'Parent' else 'Child' end as "Row Type",
               tf.trading_firm_name                                                as "Trading Firm",
               a.account_name                                                      as "Account",
               yc.client_order_id                                                  as "Cl Ord ID",
               orig.client_order_id                                                as "Orig Cl Ord ID",
               lst_ex.order_status_description                                     as "Order Status",
               ot.order_type_name                                                  as "Ord Type",
               to_char(co.create_time, 'MM/DD/YYYY')                               as "Create Date",
               to_char(co.create_time, 'HH24:MI:SS.US')                            as "Create Time",
               to_char(yc.routed_time, 'HH24:MI:SS.US')                            as "Routed Time",
               to_char(yc.routed_time, 'MM/DD/YYYY')                               as "Event Date",
               to_char(yc.exec_time, 'HH24:MI:SS.US')                              as "Event Time",
               case
                   when hsd.instrument_type_id = 'E' then 'Equity'
                   when hsd.instrument_type_id = 'O' then 'Option'
                   end                                                             as "Sec Type",
               coalesce(exd.ex_destination_desc, co.ex_destination)                as "Ex Dest",
               dss.sub_strategy                                                    as "Sub Strategy",
               case
                   when yc.side = '1' then 'Buy'
                   when yc.side in ('2', '5', '6') then 'Sell'
                   else ''
                   end                                                             as "Side",
               case
                   when co.open_close = 'O' then 'Open'
                   when co.open_close = 'C' then 'Close'
                   else '' end                                                     as "O/C",
               hsd.display_instrument_id                                           as "Symbol",
               yc.order_qty                                                        as "Order Qty",
               yc.order_price                                                      as "Price",
               yc.day_cum_qty                                                      as "Ex Qty",
               yc.avg_px                                                           as "Avg Px",
               yc.day_leaves_qty                                                   as "Lvs Qty",
               ex.exchange_name                                                    as "Exchange Name",
               cf.customer_or_firm_name                                            as "Cust/Firm",
               co.clearing_firm_id                                                 as "CMTA",
               yc.client_id                                                        as "Client ID",   -- not d_client as we do not have d_client anymore
               hsd.opra_symbol                                                     as "OSI Symbol",
               hsd.underlying_symbol                                               as "Root Symbol",
               to_char(hsd.maturity_date, 'MM/DD/YYYY')                            as "Expiration",  --MM/DD/YYY?? It was not mentioned
               hsd.put_call                                                        as "Put/Call",
               hsd.strike_px                                                       as "Strike",
               case when yc.multileg_reporting_type = '1' then 'N' else 'Y' end    as "Is Mleg",
               case when yc.cross_order_id is not null then 'Y' else 'N' end       as "Is Cross",
               tif.tif_name                                                        as "TIF",
               co.max_floor                                                        as "Max Floor",
               case
                   when co.exec_instruction like '1%' then 'NH' -- Not Held
                   when co.exec_instruction like '5%' then 'H' -- Held
                   else 'NH'
                   end                                                             as "Held Status",
               coalesce(fm_ex.tag_6376, fm_co.tag_6376)                            as "Alternative Compliance ID",
               coalesce(fm_ex.tag_376, fm_co.tag_6376)                             as "Compliance ID",
               coalesce(fm_ex.tag_21, fm_co.tag_21)                                as "Handling Instructions",
               coalesce(fm_ex.tag_18, fm_co.tag_18)                                as "Execution Instructions",
               co.co_client_leg_ref_id                                             as "Leg ID",
               lst_ex.text_                                                        as "Free Text"
        from data_marts.f_yield_capture yc
                 join dwh.d_account a on (a.account_id = yc.account_id)
                 join dwh.client_order co on (co.create_date_id between in_start_date_id and in_end_date_id and
                                              co.create_date_id = yc.status_date_id and
                                              co.order_id = yc.order_id)
                 left join dwh.client_order orig
                           on (orig.create_date_id between in_start_date_id and in_end_date_id and
                               orig.create_date_id = yc.status_date_id and
                               orig.order_id = co.orig_order_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = yc.time_in_force_id
                 left join dwh.d_order_type ot on ot.order_type_id = yc.order_type_id
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
                 left join data_marts.d_sub_strategy dss on yc.sub_strategy_id = dss.sub_strategy_id
                 left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                        coalesce(exd.exchange_id, '') =
                                                        coalesce(yc.exchange_id, '') and
                                                        exd.instrument_type_id = yc.instrument_type_id and
                                                        exd.is_active)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
                 left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
                 left join lateral
                 (
                     select os.order_status_description, ex.text_, ex.fix_message_id
                     from dwh.execution ex
                     left join dwh.d_order_status os on (os.order_status = ex.order_status and os.is_active)
                     left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
                     where ex.order_id = yc.order_id
                         and ex.exec_date_id between in_start_date_id and in_end_date_id
                         and ex.exec_date_id = yc.status_date_id
                         and ex.order_status <> '3'
                     order by ex.exec_id desc
                     limit 1
                ) lst_ex on true
                left join lateral (select fix_message ->> '6376' as tag_6376,
                                          fix_message ->> '376'  as tag_376,
                                          fix_message ->> '21'   as tag_21,
                                          fix_message ->> '18'   as tag_18
                                   from fix_capture.fix_message_json fm
                                   where fm.fix_message_id = co.fix_message_id
                                     and fm.date_id between in_start_date_id and in_end_date_id
                                   limit 1) fm_co on true
                left join lateral (select fix_message ->> '6376' as tag_6376,
                                          fix_message ->> '376'  as tag_376,
                                          fix_message ->> '21'   as tag_21,
                                          fix_message ->> '18'   as tag_18
                                   from fix_capture.fix_message_json fm
                                   where fm.fix_message_id = lst_ex.fix_message_id
                                     and fm.date_id between in_start_date_id and in_end_date_id
                                   limit 1) fm_ex on true
        where yc.status_date_id between in_start_date_id and in_end_date_id
          and case
                  when in_row_type is null then true
                  when in_row_type = 'Parent' then yc.parent_order_id is null
                  when in_row_type = 'Child' then yc.parent_order_id is not null end
          and case when in_instrument_type is null then true else yc.instrument_type_id = in_instrument_type end
          and case
                  when l_account_ids = '{}' then true
                  else yc.account_id = any (l_account_ids) end
          and yc.multileg_reporting_type in ('1', '2')
--         and case when in_trading_firm_ids <> '{}' then a.trading_firm_id = any(in_trading_firm_ids) else true end
        order by co.create_date_id, co.order_id;

end ;
$function$
;


-- DROP FUNCTION dash360.report_gtc_recon(varchar, _int4, int4, int4);

CREATE FUNCTION dash360.report_gtc_recon(in_instrument_type_id character varying DEFAULT 'O'::character varying,
                                         in_account_ids integer[] DEFAULT '{}'::integer[],
                                         in_start_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                         in_end_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                         in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "CreateDate"     text,
                "ClOrdID"        character varying,
                "LegRefID"       character varying,
                "BuySell"        text,
                "Symbol"         character varying,
                "OpenQuantity"   character varying,
                "Price"          character varying,
                "ExpirationDate" text,
                "TypeCode"       text,
                "Strike"         character varying,
                "StopPx"         text,
                "Order_Quantity" integer,
                "ProductType"    character
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2024-01-18 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-3910 added start_date_id and end_date_id
declare
    l_row_cnt         integer;
    l_load_id         integer;
    l_step_id         integer;
    l_is_current_date bool := false;
    l_account_ids     integer[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_recon for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    if in_account_ids = '{}' and in_trading_firm_ids = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
            and case when in_trading_firm_ids <> '{}'::varchar[] then trading_firm_id = ANY (in_trading_firm_ids) end
           or case when in_account_ids <> '{}'::integer[] then account_id = ANY (in_account_ids) end;
    end if;

    select public.load_log(l_load_id, l_step_id, left(' account_ids = ' || in_account_ids::text, 200), 0,
                           'O')
    into l_step_id;

    return query
        select to_char(co.create_time, 'MM/DD/YYYY HH:MI:SS AM')                                     as "CreateDate",
               co.client_order_id                                                                    as "ClOrdID",
               co.co_client_leg_ref_id                                                               as "LegRefID",
               case
                   when co.side in ('1', '3')
                       then 'BUY'
                   else 'SELL'
                   end                                                                               as "BuySell",
               i.symbol                                                                              as "Symbol",
               (co.order_qty -
                coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id),
                         0))::varchar                                                                as "OpenQuantity",
               coalesce(co.price, co.stop_price)::varchar                                            as "Price",
               coalesce(to_char(i.last_trade_date, 'YYYYMMDD'),
                        to_char(co.expire_time, 'YYYYMMDD'))                                         as "ExpirationDate",
               case
                   when oc.put_call = '0' then 'P'
                   when oc.put_call = '1' then 'C'
                   end                                                                               as "TypeCode",
               oc.strike_price::varchar                                                              as "Strike",
               fmj.t99                                                                               as "StopPx",
               order_qty                                                                             as "Order_Quantity",
               case
                   when co_client_leg_ref_id is not null then 'MLEG'
                   when i.instrument_type_id = 'O' then 'OPT'
                   when i.instrument_type_id = 'E' then 'EQ'
--	        when i.instrument_type_id = 'M' then 'MLEG'
                   else i.instrument_type_id end                                                     as "ProductType"
        from dwh.gtc_order_status gos
                 join dwh.client_order co on gos.order_id = co.order_id and gos.create_date_id = co.create_date_id
                 join dwh.d_instrument i on co.instrument_id = i.instrument_id
                 left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
                 left join lateral (select fix_message ->> '99' as t99
                                    from fix_capture.fix_message_json fmj
                                    where fmj.date_id = co.create_date_id
                                      and fmj.fix_message_id = co.fix_message_id
                                    limit 1) fmj on true
        where true
          and gos.create_date_id <= in_start_date_id
          and co.parent_order_id is null
          and case when l_account_ids = '{}' then true else gos.account_id = any (l_account_ids) end
          and case when in_instrument_type_id is null then true else i.instrument_type_id = in_instrument_type_id end
          and (gos.close_date_id is null
-- the code below has been added to provide the same performance in the case we use the report for CURRENT date
            or (case
                    when l_is_current_date then false
                    else gos.close_date_id is not null and close_date_id > in_end_date_id end))
          -- end of
          and co.multileg_reporting_type <> '3';

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_recon for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED===',
                           l_row_cnt, 'O')
    into l_step_id;
END;
$function$
;



-- DROP FUNCTION dash360.report_obo_compliance_xls(int4, int4, bpchar, _int4, _int8);

CREATE OR REPLACE FUNCTION dash360.report_obo_compliance_xls(in_date_begin_id integer, in_date_end_id integer,
                                                             in_instrument_type character DEFAULT NULL::bpchar,
                                                             in_account_ids integer[] DEFAULT '{}'::integer[],
                                                             in_parent_order_ids bigint[] DEFAULT '{}'::bigint[],
                                                             in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "OrderID"                   bigint,
                "Trading Firm Name"         character varying,
                "Trading Firm IMID"         character varying,
                "Trading Firm CRD"          character varying,
                "Event Type"                character varying,
                "Event Date"                text,
                "Event Time"                text,
                "Client clOrderID"          character varying,
                "Street clOrderID"          text,
                "Event Qty"                 integer,
                "Event Price"               numeric,
                "Net Price"                 numeric,
                "Multi Leg Indicator"       text,
                "Number of legs"            integer,
                "Leg Order ID"              bigint,
                "Manual Flag"               text,
                "Free Text"                 character varying,
                "Order Status"              character varying,
                "Original Client clOrderID" character varying,
                "Original Street clOrderID" character varying,
                "OSI Symbol"                character varying,
                "Base symbol"               character varying,
                "Symbol"                    character varying,
                "Security Type"             character,
                "Underlying Symbol"         character varying,
                "P/C/S"                     text,
                "Expiration Date"           text,
                "Expiration Time"           text,
                "Side"                      text,
                "TIF"                       character varying,
                "Good Till Date"            text,
                "Good Till Time"            text,
                "Order Qty"                 integer,
                "Filled Qty"                bigint,
                "Order Type Code"           character varying,
                "Order Price"               numeric,
                "Order Creation Date"       text,
                "Order Creation Time"       text,
                "Open/Close"                character,
                "Trading Session"           character varying,
                "Is Held"                   text,
                "Is Cross"                  text,
                "Fee Sensitivity"           smallint,
                "Stop Price"                numeric,
                "Max Floor"                 bigint,
                "Capacity"                  character varying,
                "ExDestination"             character varying,
                "Leg ratio"                 bigint,
                "User"                      text,
                "Account Name"              character varying,
                "Account ID"                integer,
                "Account Holder Type"       character varying,
                "Account FDID"              character varying,
                "Account IMID"              text,
                "Account CRD"               character varying,
                "Sender type"               character varying,
                "Last Mkt"                  character varying,
                "MIC Code"                  character varying,
                "Liquidity Indicator"       character varying,
                "ExecutionID"               text,
                "CAT Reporting Firm IMID"   character varying
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
    l_date_begin_id int4;
    l_date_end_id   int4;
    l_account_ids   int4[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    l_date_begin_id := coalesce(in_date_begin_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_date_end_id := coalesce(in_date_end_id, to_char(current_date, 'YYYYMMDD')::int4);

        if in_account_ids = '{}' and in_trading_firm_ids = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
            and case when in_trading_firm_ids <> '{}'::varchar[] then trading_firm_id = ANY (in_trading_firm_ids) end
           or case when in_account_ids <> '{}'::integer[] then account_id = ANY (in_account_ids) end;
    end if;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' STARTED===', 0, 'O')
    into l_step_id;

    drop table if exists t_sor;

    -- parent level
    create temp table t_sor as
    select
        -- head
        staging.last_orig_order(in_order_id := cl.order_id) as first_order_id,
        cl.order_id                                         as parent_order_id,
        cl.order_id                                         as street_order_id,
        ''                                                  as exec_id,
        cl.create_date_id,

        -- Firm Details
        tf.trading_firm_name,
        tf.cat_imid                                         as firm_cat_imid,
        tf.cat_crd                                          as firm_cat_crd,

        -- Event Details
        'New Order'                                         as event_type,
        to_timestamp(fmj.tag_10061, 'YYYYMMDD-HH24:MI:SS')  as event_ts,
        cl.client_order_id                                  as parent_clorderid,
        null::text                                          as street_clorderid,
        cl.order_qty                                        as event_order_qty,
        cl.price                                            as event_price,
        mleg.price                                          as net_price,
        cl.multileg_reporting_type,
        mleg.no_legs,
        cl.multileg_order_id,
        '??'                                                as manual_flag,
        ex.text_,

        -- Order Detail
        os.order_status_description,
        orig.client_order_id                                as orig_client_order_id,
        cl.order_id,
        oc.opra_symbol,
        dos.root_symbol,
        di.symbol,
        di.instrument_type_id,
        ui.symbol                                           as underlying_symbol,
        case
            when di.instrument_type_id = 'E' then 'Stock'
            when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
            when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
            end                                             as pcv,
        di.last_trade_date                                  as expiration_ts,
        cl.side,
        dtif.tif_short_name                                 as tif,
        cl.expire_time                                      as good_till_ts,
        cl.order_qty,
        ex.cum_qty,
        ot.order_type_name,
        cl.price,
        cl.create_time                                      as order_creation_ts,
        cl.open_close,
        cl.exec_instruction,
        cl.cross_order_id,
        cl.fee_sensitivity,
        cl.stop_price,
        cl.max_floor,
        cof.customer_or_firm_name,
        cl.ex_destination,
        cl.ratio_qty,
        coalesce(fmj.tag_50, tag_109)                       as user_,

        -- Account Details
        ac.account_name,
        ac.account_id,
        ac.account_holder_type,
        ac.cat_fdid,
        case
            when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                then tf.cat_imid end                        as cat_imid,
        case
            when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                then ac.crd_number end                      as crd_number,
-- ac.broker_dealer_mpid,
        fc.sender_sub_id,

        -- Execution Details
        ex.last_mkt,
        exc.mic_code,
        ex.trade_liquidity_indicator
    -- CAT Details

    from dwh.client_order as cl
             left join dwh.client_order mleg
                       on (mleg.order_id = cl.orig_order_id and mleg.create_date_id >= cl.create_date_id)
             join dwh.d_account ac on cl.account_id = ac.account_id and ac.is_active
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
             left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
             left join lateral
        ( select ex.exec_id,
                 ex.order_status,
                 ex.exec_type,
                 ex.cum_qty,
                 ex.exec_time,
                 ex.last_mkt,
                 ex.trade_liquidity_indicator,
                 ex.text_,
                 ex.exchange_id
          from dwh.execution ex
          where ex.order_id = cl.order_id
            and ex.exec_date_id >= cl.create_date_id
            and ex.exec_date_id >= l_date_begin_id
          order by exec_id desc
          limit 1
        ) ex on true
             left join lateral (select orig.client_order_id
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and orig.create_date_id <= cl.create_date_id
                                limit 1) orig on true
             left join dwh.d_order_status os on ex.order_status = os.order_status
             left join dwh.d_option_series dos
                       on oc.option_series_id = dos.option_series_id
             left join dwh.d_instrument ui
                       on ui.instrument_id = dos.underlying_instrument_id
             left join dwh.d_time_in_force dtif
                       on dtif.tif_id = cl.time_in_force_id
             left join lateral (select fix_message ->> '40'    as tag_40,
                                       fix_message ->> '50'    as tag_50,
                                       fix_message ->> '109'   as tag_109,
                                       fix_message ->> '58'    as tag_58,
                                       fix_message ->> '10061' as tag_10061
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.fix_message_id
                                limit 1) fmj on true
             left join dwh.d_customer_or_firm cof
                       on cof.customer_or_firm_id = cl.customer_or_firm_id
             left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active
             left join dwh.d_fix_connection fc
                       on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
    where cl.parent_order_id is null
      and case
              when coalesce(in_parent_order_ids, '{}') = '{}' then true
              else cl.order_id = any (in_parent_order_ids) end
      and cl.create_date_id between l_date_begin_id and l_date_end_id
      and case when l_account_ids = '{}' then true else ac.account_id = any (l_account_ids) end
    and case when in_trading_firm_ids <> '{}' then ac.trading_firm_id = any(in_trading_firm_ids) else true end;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text || ' counted ', l_row_cnt, 'O')
    into l_step_id;

    -- exec level
    insert into t_sor
    (first_order_id, parent_order_id, street_order_id, exec_id, create_date_id, trading_firm_name, firm_cat_imid,
     firm_cat_crd,
     event_type, event_ts, parent_clorderid, street_clorderid, event_order_qty, event_price, net_price,
     multileg_reporting_type, no_legs, multileg_order_id, manual_flag, text_, order_status_description,
     orig_client_order_id, order_id, opra_symbol, root_symbol, symbol, instrument_type_id, underlying_symbol, pcv,
     expiration_ts, side, tif, good_till_ts, order_qty, cum_qty, order_type_name, price, order_creation_ts, open_close,
     exec_instruction, cross_order_id, fee_sensitivity, stop_price, max_floor, customer_or_firm_name, ex_destination,
     ratio_qty, user_, account_name, account_id, account_holder_type, cat_fdid, cat_imid, crd_number,
     sender_sub_id, last_mkt, mic_code, trade_liquidity_indicator)

    select
        -- head
        cl.first_order_id,
        cl.parent_order_id                                                                      as parent_order_id,
        cl.order_id                                                                             as street_order_id,
        fmj.tag_17                                                                              as exec_id,
        cl.create_date_id                                                                       as create_date_id,
        -- Firm Details
        tf.trading_firm_name,
        tf.cat_imid                                                                             as firm_cat_imid,
        tf.cat_crd                                                                              as firm_cat_crd,

        -- Event Details
        'Execution'                                                                             as event_type,
        to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS')                                       as event_ts,
        cl.parent_clorderid                                                                     as parent_clorderid,
        cl.street_clorderid                                                                     as street_clorderid,
        ex.last_qty                                                                             as event_qty,
        ex.last_px                                                                              as event_price,
        null                                                                                    as net_price,
        cl.multileg_reporting_type,
        null,
        cl.multileg_order_id,
        '??'                                                                                    as manual_flag,
        ex.text_,

        -- Order Detail
        et.exec_type_description,
        cl.orig_client_order_id                                                                 as orig_client_order_id,
        cl.order_id,
        cl.opra_symbol,
        cl.root_symbol,
        cl.symbol,
        cl.instrument_type_id,
        cl.underlying_symbol,
        cl.pcv,
        cl.expiration_ts,
        cl.side,
        cl.tif,
        cl.good_till_ts,
        cl.order_qty,
        ex.cum_qty,
        cl.order_type_name,
        cl.price,
        cl.order_creation_ts,
        cl.open_close,
        cl.exec_instruction,
        cl.cross_order_id,
        cl.fee_sensitivity,
        cl.stop_price,
        cl.max_floor,
        cl.customer_or_firm_name,
        cl.ex_destination,
        cl.ratio_qty,
        cl.user_,

        -- Account Details
        ac.account_name,
        ac.account_id,
        ac.account_holder_type,
        ac.cat_fdid,
        case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then tf.cat_imid end   as cat_imid,
        case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then ac.crd_number end as crd,
-- ac.broker_dealer_mpid,
        cl.sender_sub_id,

        -- Execution Details
        ex.last_mkt,
        exc.mic_code,
        ex.trade_liquidity_indicator
    -- CAT Details
    from t_sor cl
             left join dwh.d_account ac on cl.account_id = ac.account_id and ac.is_active
             left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
             left join lateral
        ( select ex.exec_id,
                 ex.order_status,
                 ex.exec_type,
                 ex.cum_qty,
                 ex.exec_time,
                 ex.last_mkt,
                 ex.trade_liquidity_indicator,
                 ex.text_,
                 ex.last_qty,
                 ex.last_px,
                 ex.exchange_id,
                 ex.fix_message_id
          from dwh.execution ex
          where ex.order_id = cl.order_id
            and ex.exec_date_id >= cl.create_date_id -- hardcode to fix later
            and ex.exec_date_id >= l_date_begin_id
-- and ex.exec_type not in ('a', '5', 'A', 'S')
        ) ex on true
             left join dwh.d_order_status os on ex.order_status = os.order_status
             left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active
             left join dwh.d_exec_type et on et.exec_type = ex.exec_type
             left join lateral (select fix_message ->> '17'   as tag_17,
                                       fix_message ->> '50'   as tag_50,
                                       fix_message ->> '109'  as tag_109,
                                       fix_message ->> '58'   as tag_58,
                                       fix_message ->> '5050' as tag_5050
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = ex.fix_message_id
                                limit 1) fmj on true
-- where cl.event_type = 'Order Route'
    ;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls exec level for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text || ' counted ', l_row_cnt, 'O')
    into l_step_id;

    return query
        select rep.parent_order_id,                                                     -- as parent_order_id,

               -- Firm Details
               rep.trading_firm_name,                                                   -- as "Trading Firm Name",
               rep.firm_cat_imid,                                                       -- as "Trading Firm IMID",
               rep.firm_cat_crd,                                                        --  as "Trading Firm CRD",
               -- Event Details
               case when rep.exec_id is not null then rep.order_status_description end, -- as "Event Type",
               to_char(rep.event_ts, 'MM/DD/YYYY'),                                     -- as "Event Date",
               to_char(rep.event_ts, 'HH24:MI:SS.MS'),                                  -- as "Event Time",
               rep.parent_clorderid,                                                    -- as "Client clOrderID",
               rep.street_clorderid,                                                    -- as "Street clOrderID",
               rep.event_order_qty,                                                     -- as "Event Qty",
               rep.event_price,                                                         -- as "Event Price",
               rep.net_price,                                                           -- as "Net Price",
               case
                   when rep.multileg_reporting_type <> '1' then 'Y'
                   else 'N'
                   end,                                                                 -- as "Multi Leg Indicator",
               rep.no_legs,                                                             -- as "Number of legs",
               rep.multileg_order_id,                                                   -- as "Leg Order ID",
               rep.manual_flag,                                                         -- as "Manual Flag",
               rep.text_,                                                               -- as "Free Text",

               -- Order Detail
               case
                   when rep.exec_id is null
                       then rep.order_status_description end,                           -- as "Order Status",
               case
                   when rep.event_type = 'New Order'
                       then orig_client_order_id end,                                   -- as "Original Client clOrderID",
               case
                   when rep.event_type = 'Order Route'
                       then orig_client_order_id end,                                   -- as "Original Street clOrderID",
               rep.opra_symbol,                                                         -- as "OSI Symbol",
               rep.root_symbol,                                                         -- as "Base symbol",
               rep.symbol,                                                              -- as "Symbol",
               case rep.instrument_type_id
                   when 'O' then 'Option'
                   when 'E' then 'Equity'
                   else rep.instrument_type_id end,                                     -- as "Security Type",
               rep.underlying_symbol,                                                   -- as "Underlying Symbol",
               rep.pcv,                                                                 -- as "P/C/S",
               to_char(rep.expiration_ts, 'MM/DD/YYYY'),                                -- as "Expiration Date",
               to_char(rep.expiration_ts, 'HH24:MI:SS.MS'),                             -- as "Expiration Time",
               case
                   when rep.side = '1' then 'Buy'
                   when rep.side = '2' then 'Sell'
                   when rep.side in ('5', '6') then 'Sell Short'
                   end,                                                                 -- as "Side",
               rep.tif,                                                                 -- as "TIF",
               to_char(rep.good_till_ts, 'MM/DD/YYYY'),                                 -- as "Good Till Date",
               to_char(rep.good_till_ts, 'HH24:MI:SS.MS'),                              -- as "Good Till Time",
               rep.order_qty,                                                           -- as "Order Qty",
               rep.cum_qty,                                                             -- as "Filled Qty",
               rep.order_type_name,                                                     -- as "Order Type Code",
               rep.price,                                                               -- as "Order Price",
               to_char(rep.order_creation_ts, 'DD.MM.YYYY'),                            -- as "Order Creation Date",
               to_char(rep.order_creation_ts, 'HH24:MI:SS.MS'),                         -- as "Order Creation Time",
               rep.open_close,                                                          -- as "Open/Close",
               compliance.get_eq_sor_trading_session(in_order_id := rep.order_id,
                                                     in_date_id := rep.create_date_id), -- as "Trading Session",
               case
                   when rep.exec_instruction like '1%' then 'NH'
                   when rep.exec_instruction like '5%' then 'H'
                   else 'NH'
                   end,                                                                 -- as "Is Held",
               case when rep.cross_order_id is not null then 'Y' else 'N' end,          -- as "Is Cross",
               rep.fee_sensitivity,                                                     -- as "Fee Sensitivity",
               rep.stop_price,                                                          -- as "Stop Price",
               rep.max_floor,                                                           -- as "Max Floor",
               rep.customer_or_firm_name,                                               -- as "Capacity",
               rep.ex_destination,                                                      -- as "ExDestination",
               rep.ratio_qty,                                                           -- as "Leg ratio",
               rep.user_,                                                               -- as "User",

               -- Account Details
               rep.account_name,                                                        -- as "Account Name",
               rep.account_id,                                                          -- as "Account ID",
               rep.account_holder_type,                                                 -- as "Account Holder Type",
               rep.cat_fdid,                                                            -- as "Account FDID",
               null::text,                                                              -- as "Account IMID",
               rep.crd_number,                                                          -- as "Account CRD",
               rep.sender_sub_id,                                                       -- as "Sender type",

               -- Execution Details
               rep.last_mkt,                                                            -- as "Last Mkt",
               rep.mic_code,                                                            -- as "MIC Code",
               rep.trade_liquidity_indicator,                                           -- as "Liquidity Indicator",
               rep.exec_id,                                                             -- as "ExecutionID",

               -- CAT Details
               rep.cat_imid                                                             -- as "CAT Reporting Firm IMID"
--  ], ',', '')
        from t_sor rep
        order by coalesce(rep.first_order_id, rep.parent_order_id), rep.parent_order_id, rep.street_order_id, rep.exec_id nulls first;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text || ' FINISHED=== ', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;
