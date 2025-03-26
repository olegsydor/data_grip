-- DROP FUNCTION dash360.report_gtc_recon(varchar, _int4, int4, int4, _varchar);

CREATE function dash360.report_gtc_ofp0055_open_order(in_start_date_id integer DEFAULT to_char(CURRENT_DATE, 'YYYYMMDD')::integer, in_end_date_id int4 DEFAULT to_char(CURRENT_DATE, 'YYYYMMDD')::integer)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
    -- 2025-03-26 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-5550
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
                           'dash360.report_gtc_ofp0055_open_order for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

        select array_agg(account_id)
--         into l_account_ids
        from dwh.d_account
        where true
            and trading_firm_id = 'OFP0055';

return query
    select 'ORDER_DATE,ROUTED_ORDER_REF,TYPE,BUY_SELL,CALL_PUT,OPEN_CLOSE,CONTRACTS,LEAVES_QTY,SYMBOL,EXPIRY,STRIKE,PRICE_TYPE,LIMIT_PRICE,STOP_PRICE,EXPIRY_TYPE,BROKER_ORDER_ID,SENDER_SUB_ID,EXPIREDATE';

    return query
        select
            to_char(co.create_time, 'yyyyMMdd'), -- ORDER_DATE
            co.client_order_id, -- ROUTED_ORDER_REF
            'OPTION', -- TYPE
                    case
                   when co.side in ('1', '3')
                       then 'BUY'
                   else 'SELL'
                   end, -- BUY_SELL
 case
                   when oc.put_call = '0' then 'PUT'
                   when oc.put_call = '1' then 'CALL'
                   end, -- CALL_PUT
            case when co.open_close = 'O' then 'OPEN'
                when co.open_close = 'C' then 'CLOSE'
                    end, -- OPEN_CLOSE
            order_qty, -- CONTRACTS
ex.leaves_qty, -- LEAVES_QTY
(co.order_qty -
                coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id),
                         0))::varchar                                                                as "OpenQuantity", --!!!
               i.symbol, -- SYMBOL
to_char(coalesce(i.last_trade_date, co.expire_time), 'DD-Mon-YY'), -- EXPIRY
               staging.trailing_dot(oc.strike_price), -- STRIKE
               ot.order_type_short_name





            to_char(co.create_time, 'MM/DD/YYYY HH:MI:SS AM')                                     as "CreateDate",
               co.co_client_leg_ref_id                                                               as "LegRefID",



               coalesce(co.price, co.stop_price)::varchar                                            as "Price",
               coalesce(to_char(i.last_trade_date, 'YYYYMMDD'),
                        to_char(co.expire_time, 'YYYYMMDD'))                                         as "ExpirationDate",

               oc.strike_price::varchar                                                              as "Strike",
               fmj.t99                                                                               as "StopPx",

               case
                   when co_client_leg_ref_id is not null then 'MLEG'
                   when i.instrument_type_id = 'O' then 'OPT'
                   when i.instrument_type_id = 'E' then 'EQ'
--	        when i.instrument_type_id = 'M' then 'MLEG'
                   else i.instrument_type_id end                                                     as "ProductType"
        from dwh.gtc_order_status gos
                 join dwh.client_order co on gos.order_id = co.order_id and gos.create_date_id = co.create_date_id
                 join dwh.d_instrument i on co.instrument_id = i.instrument_id
            inner join dwh.d_order_type ot on (co.order_type_id = ot.order_type_id)
                 left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
                 left join lateral (select fix_message ->> '99' as t99
                                    from fix_capture.fix_message_json fmj
                                    where fmj.date_id = co.create_date_id
                                      and fmj.fix_message_id = co.fix_message_id
                                    limit 1) fmj on true

                         join lateral (select ex.exec_id as exec_id
                               from dwh.execution ex
                               where gos.order_id = ex.order_id
                                 and ex.order_status <> '3'
                                 and ex.exec_date_id >= gos.create_date_id
                               order by ex.exec_id desc
                               limit 1) gtex on true
                 inner join lateral (select ex.avg_px, ex.last_px, ex.leaves_qty, ex.order_status
                                     from dwh.execution ex
                                     where ex.exec_id = gtex.exec_id
                                       and ex.exec_date_id >= gos.create_date_id
                                     limit 1) ex on true



        where true
          and gos.create_date_id <= in_start_date_id
          and co.parent_order_id is null
          and case when l_account_ids = '{}' then true else gos.account_id = any (l_account_ids) end
          and i.instrument_type_id = 'O'
          and (gos.close_date_id is null
-- the code below has been added to provide the same performance in the case we use the report for CURRENT date
            or (case
                    when l_is_current_date then false
                    else gos.close_date_id is not null and close_date_id > in_end_date_id end))
          -- end of
          and co.multileg_reporting_type <> '3';

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_ofp0055_open_order for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED===',
                           l_row_cnt, 'O')
    into l_step_id;
END;
$function$
;
