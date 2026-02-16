DROP FUNCTION trash.report_fintech_adh_order_xls(int4, int4, bpchar, _int4, text, _varchar);

CREATE FUNCTION trash.report_fintech_adh_order_xls(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE),
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
                "Parent Cl Ord ID"          character varying,
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
                "Free Text"                 character varying,
                "NBBO Bid Px" numeric, --nbbo_bid_price
"NBBO Bid Qty" integer, -- nbbo_bid_quantity
"NBBO Ask Px" numeric, -- nbbo_ask_price
"NBBO Ask Qty" integer, -- nbbo_ask_quantity
"Exch Bid Px" numeric, -- exch_bid_price
"Exch Bid Qty" integer, -- exch_bid_quantity
"Exch Ask Px" numeric, -- exch_ask_price
"Exch Ask Qty" integer, -- exch_ask_quantity
"Exec Type" --exec_type_description
            )
    LANGUAGE plpgsql
--     SET enable_mergejoin TO 'false'
AS
$function$
-- 2024-04-18 SO: https://dashfinancial.atlassian.net/browse/DS-8251 added in_trading_firm_ids as an input parameter
-- SO 20240523 https://dashfinancial.atlassian.net/browse/DEVREQ-4264 add coalesce to account\trading firm input parameters
-- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
-- SY 20250228 https://dashfinancial.atlassian.net/browse/DS-9623 CTE, one lateral and two condition on date_id fields ingested into subqueries
-- MB 20250507 https://dashfinancial.atlassian.net/browse/DS-9912 Decommission of data_marts.d_sub_strategy
-- SO 20260216 https://dashfinancial.atlassian.net/browse/DEVREQ-7649 add new columns, performance tuning
declare
    l_account_ids    integer[];
begin
    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
            and case when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[] then trading_firm_id = ANY (in_trading_firm_ids) else true end
            and case when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids) else true end;
    end if;
    return query
with yc as materialized (select *
						from data_marts.f_yield_capture yc
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
          )
        select case when yc.parent_order_id is null then 'Parent' else 'Child' end as "Row Type",
               tf.trading_firm_name                                                as "Trading Firm",
               a.account_name                                                      as "Account",
               par.client_order_id                                                 as "Parent Cl Ord ID",
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
               dts.target_strategy_name                                            as "Sub Strategy",
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
               round(yc.avg_px, 6)                                                 as "Avg Px",
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
               lst_ex.exec_text                                                    as "Free Text"
        from /*data_marts.f_yield_capture*/ yc
                 join dwh.d_account a on (a.account_id = yc.account_id)
                 join dwh.client_order co on (co.create_date_id between in_start_date_id and in_end_date_id and
                                              co.create_date_id = yc.status_date_id and
                                              co.order_id = yc.order_id)
                  left join lateral  (select par.client_order_id
			                            from dwh.client_order par
			                           where par.create_date_id between in_start_date_id and in_end_date_id and
			                               par.create_date_id = yc.status_date_id and
			                               par.order_id = co.parent_order_id
			                          limit 1) par on true
                  left join lateral  (select orig.client_order_id
			                            from dwh.client_order orig
			                           where orig.create_date_id between in_start_date_id and in_end_date_id and
			                               orig.create_date_id = yc.status_date_id and
			                               orig.order_id = co.orig_order_id
			                          limit 1) orig on true
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = yc.time_in_force_id
                 left join dwh.d_order_type ot on ot.order_type_id = yc.order_type_id
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
                 left join dwh.d_target_strategy dts on (dts.target_strategy_id = yc.sub_strategy_id)
                 left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                        coalesce(exd.exchange_id, '') =
                                                        coalesce(yc.exchange_id, '') and
                                                        exd.instrument_type_id = yc.instrument_type_id and
                                                        exd.is_active)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
                 left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
                 left join lateral
                 (
                     select os.order_status_description, ex.exec_text, ex.fix_message_id, ex.exec_date_id
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
                                    and fm.date_id = co.create_date_id
                                     and fm.date_id between in_start_date_id and in_end_date_id
                                   limit 1) fm_co on true
                left join lateral (select fix_message ->> '6376' as tag_6376,
                                          fix_message ->> '376'  as tag_376,
                                          fix_message ->> '21'   as tag_21,
                                          fix_message ->> '18'   as tag_18
                                   from fix_capture.fix_message_json fm
                                   where fm.fix_message_id = lst_ex.fix_message_id
									 and fm.date_id = lst_ex.exec_date_id
                                     and fm.date_id between in_start_date_id and in_end_date_id
                                   limit 1) fm_ex on true
        where 1=1
--yc.status_date_id between in_start_date_id and in_end_date_id
--          and case
--                  when in_row_type is null then true
--                  when in_row_type = 'Parent' then yc.parent_order_id is null
--                  when in_row_type = 'Child' then yc.parent_order_id is not null end
--          and case when in_instrument_type is null then true else yc.instrument_type_id = in_instrument_type end
--          and case
--                  when l_account_ids = '{}' then true
--                  else yc.account_id = any (l_account_ids) end
--          and yc.multileg_reporting_type in ('1', '2')
          and case
	          when a.account_name = 'CSBDNOM' then yc.day_cum_qty > 0
	          else true end
--         and case when in_trading_firm_ids <> '{}' then a.trading_firm_id = any(in_trading_firm_ids) else true end
        --order by co.create_date_id, co.order_id;
        order by co.create_date_id, coalesce(co.parent_order_id, co.order_id), co.create_time;

end ;
$function$
;

select
nbbo_bid_quantity,
nbbo_ask_price,
nbbo_ask_quantity,
exch_bid_price,
exch_bid_quantity,
exch_ask_price,
exch_ask_quantity
--        , exec_type_description

from data_marts.f_yield_capture;

select * from dwh.d_exec_type