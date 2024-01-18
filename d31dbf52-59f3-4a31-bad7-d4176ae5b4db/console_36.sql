-- DROP FUNCTION dash360.report_gtc_recon(varchar, _int4);

select *
from dash360.report_gtc_recon(
        in_account_ids => array [28517,20805],
        in_instrument_type_id => null,
        in_start_date_id => 20240111,
        in_end_date_id => 20240111
     )


CREATE FUNCTION dash360.report_gtc_recon(in_instrument_type_id character varying DEFAULT 'O'::character varying,
                                                    in_account_ids integer[] DEFAULT '{}'::integer[],
                                                    in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                    in_end_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4)
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
AS $function$
    -- 2024-01-18 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-3910 added start_date_id and end_date_id
declare
    l_row_cnt          integer;
    l_load_id          integer;
    l_step_id          integer;
 l_is_current_date bool := false;
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
           coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), to_char(co.expire_time, 'YYYYMMDD')) as "ExpirationDate",
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
      and case when coalesce(in_account_ids, '{}') = '{}' then true else gos.account_id = any(in_account_ids) end
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
