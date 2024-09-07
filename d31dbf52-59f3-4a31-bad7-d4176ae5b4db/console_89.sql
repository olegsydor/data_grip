update trash.so_fix_execution_column_text_
set new_script = $insert$

CREATE OR REPLACE FUNCTION dash360.report_fintech_adh_order_row(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE), in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE), in_instrument_type character DEFAULT NULL::bpchar, in_account_ids integer[] DEFAULT '{}'::integer[], in_row_type text DEFAULT NULL::text)
 RETURNS TABLE("row" text)
 LANGUAGE plpgsql
AS $function$
-- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
declare
begin
    return query
        select 'Row Type,Trading Firm,Account,Cl Ord ID,Orig Cl Ord ID,Order Status,Ord Type,Create Date,Create Time,Routed Time,Event Date,Event Time,Sec Type,Ex Dest,Sub Strategy,Side,O/C,Symbol,Order Qty,Price,Ex Qty,Avg Px,Lvs Qty,Exchange Name,Cust/Firm,CMTA,Client ID,OSI Symbol,Root Symbol,Expiration,Put/Call,Strike,Is Mleg,Is Cross,TIF,Max Floor,Held Status,Alternative Compliance ID,Compliance ID,Handling Instructions,Execution Instructions,Leg ID,Free Text';

    return query
        select "Row Type" || ',' ||
               "Trading Firm" || ',' ||
               "Account" || ',' ||
               "Cl Ord ID" || ',' ||
               coalesce("Orig Cl Ord ID", '') || ',' ||
               "Order Status" || ',' ||
               "Ord Type" || ',' ||
               "Create Date" || ',' ||
               "Create Time" || ',' ||
               "Routed Time" || ',' ||
               "Event Date" || ',' ||
               "Event Time" || ',' ||
               "Sec Type" || ',' ||
               "Ex Dest" || ',' || --!! can be null
               coalesce("Sub Strategy", '') || ',' ||
               "Side" || ',' ||
               "O/C" || ',' ||
               "Symbol" || ',' ||
               "Order Qty"::text || ',' ||
               coalesce("Price"::text, '') || ',' ||
               "Ex Qty"::text || ',' ||
               coalesce("Avg Px"::text, '') || ',' ||
               coalesce("Lvs Qty"::text, '') || ',' ||
               coalesce("Exchange Name", '') || ',' ||
               coalesce("Cust/Firm", '') || ',' ||
               coalesce("CMTA", '') || ',' ||
               coalesce("Client ID", '') || ',' ||
               coalesce("OSI Symbol", '') || ',' ||
               coalesce("Root Symbol", '') || ',' ||
               coalesce("Expiration", '') || ',' ||
               coalesce("Put/Call", '') || ',' ||
               coalesce("Strike"::text, '') || ',' ||
               "Is Mleg" || ',' ||
               "Is Cross" || ',' ||
               coalesce("TIF", '') || ',' ||
               coalesce("Max Floor"::text, '') || ',' ||
               "Held Status" || ',' ||
               coalesce("Alternative Compliance ID", '') || ',' ||
               coalesce("Compliance ID", '') || ',' ||
               coalesce("Handling Instructions", '') || ',' ||
               coalesce("Execution Instructions", '') || ',' ||
               coalesce("Leg ID", '') || ',' ||
               coalesce("Free Text", '') as "row"
        FROM (select case when yc.parent_order_id is null then 'Parent' else 'Child' end as "Row Type",
                     tf.trading_firm_name                                                as "Trading Firm",
                     a.account_name                                                      as "Account",
                     yc.client_order_id                                                  as "Cl Ord ID",
                     orig.client_order_id                                                as "Orig Cl Ord ID",
                     lst_ex.order_status_description                                     as "Order Status",
                     ot.order_type_name                                                  as "Ord Type",
                     to_char(co.create_time, 'MM/DD/YYYY')                               as "Create Date",
                     to_char(co.create_time, 'HH:MI:SS AM')                              as "Create Time",
                     to_char(yc.routed_time, 'HH:MI:SS AM')                              as "Routed Time", --'HH24:MI:SS.MS'
                     to_char(yc.routed_time, 'MM/DD/YYYY')                               as "Event Date",
                     to_char(yc.exec_time, 'HH:MI:SS AM')                                as "Event Time",
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
                     lst_ex.exec_text                                                    as "Free Text"
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
                  select os.order_status_description, ex.exec_text, ex.fix_message_id
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
                        when coalesce(in_account_ids, '{}') = '{}' then true
                        else yc.account_id = any (in_account_ids) end
                and yc.multileg_reporting_type in ('1', '2')
              order by co.create_date_id, co.order_id) x;

end ;
$function$
;
    $insert$
where true
  and routine_schema = 'dash360'
  and routine_name = 'report_fintech_adh_order_row'
  and new_script is null;