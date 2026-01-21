select e.exec_type, co.client_order_id, os.order_status_description, et.exec_type_description, co.create_date_id, e.*
from dwh.execution e
left join dwh.client_order co on (co.create_date_id between 20260101 and 20260116 and co.order_id = e.order_id)
left join dwh.d_order_status os on (os.order_status = e.order_status)
left join dwh.d_exec_type et on (et.exec_type = e.exec_type)
where e.exec_date_id between 20260101 and 20260116
	and e.order_id in (411784692580724843, 411846449868391458)
order by e.order_id, e.exec_id;



select ex.*, ex1.*, gtc.close_date_id, *
from dwh.gtc_order_status gtc
                 join dwh.client_order cl
                      on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id --and cl.parent_order_id is null
                 join dwh.d_account ac on gtc.account_id = ac.account_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
                 inner join dwh.d_trading_firm tf on (tf.trading_firm_id = ac.trading_firm_id)
                 left join lateral (select ex.leaves_qty, exec_date_id, ex.order_status
                                     from dwh.execution ex
                                     where ex.order_id = gtc.order_id
                                       and ex.order_status in ('0', '1')
--                                        and ex.exec_type = 'y'
                                       and ex.exec_date_id >= gtc.create_date_id
                                       and ex.exec_date_id >= :in_start_date_id
                                       and ex.exec_date_id <= :in_end_date_id
                                     order by exec_id desc
                                     limit 1) ex on true
 left join lateral (select ex.leaves_qty
					from dwh.execution ex
					where gtc.order_id = ex.order_id
					  and ex.order_status <> '3'
					  and ex.exec_date_id >= gtc.create_date_id
                                       and ex.exec_date_id >= :in_start_date_id
                                       and ex.exec_date_id <= :in_end_date_id
					order by ex.exec_id desc
					limit 1) ex1 on true
where true
	and gtc.order_id in (411784692580724843, 411846449868391458)
-- and ex.exec_date_id between 20260101 and 20260116;

select * from dwh.get_cum_qty_from_orig_orders(in_order_id => 411846449868391458, in_date_id := 20260114)

select *
             FROM request_for_quote r
                         WHERE r.auction_id = 7590015056170
                           AND r.auction_date_id = 20260116;



-- DROP FUNCTION dash360.report_gtc_ofp0055_open_order(int4, int4);

CREATE OR REPLACE FUNCTION trash.report_gtc_ofp0055_open_order(in_start_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer, in_end_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer)
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
    into l_account_ids
    from dwh.d_account
    where true
      and trading_firm_id = 'OFP0055';
      --and trading_firm_id = 'ebsrbc';

    return query
        select 'ORDER_DATE,ROUTED_ORDER_REF,TYPE,BUY_SELL,CALL_PUT,OPEN_CLOSE,CONTRACTS,LEAVES_QTY,SYMBOL,EXPIRY,STRIKE,PRICE_TYPE,LIMIT_PRICE,STOP_PRICE,EXPIRY_TYPE,BROKER_ORDER_ID,SENDER_SUB_ID,EXPIREDATE';

    return query
        select array_to_string(ARRAY [
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
                                   case
                                       when co.open_close = 'O' then 'OPEN'
                                       when co.open_close = 'C' then 'CLOSE'
                                       end, -- OPEN_CLOSE
                                   order_qty::text, -- CONTRACTS
                                   ex.leaves_qty::text, -- LEAVES_QTY
                                   di.symbol, -- SYMBOL
                                   --to_char(coalesce(di.last_trade_date, co.expire_time), 'DD-Mon-YY'), -- EXPIRY
                                   to_char(to_date(((oc.maturity_year * 10000 + oc.maturity_month * 100 + oc.maturity_day)::character varying)::text, 'yyyyMMdd'), 'DD-Mon-YY'),
                                   oc.strike_price::text, -- STRIKE
                                   ot.order_type_short_name, -- PRICE_TYPE
                                   co.price::text, -- LIMIT_PRICE
                                   co.stop_price::text, -- STOP_PRICE
                                   tif.tif_short_name, -- EXPIRY_TYPE
                                   co.order_id::text, -- BROKER_ORDER_ID
                                   null, -- SENDER_SUB_ID
                                   --null -- EXPIREDATE
                                   to_char(coalesce(di.last_trade_date, co.expire_time), 'MM/dd/yyyy') -- EXPIREDATE
                                   ], ',', '')
        from dwh.gtc_order_status gtc
                 join dwh.client_order co on gtc.order_id = co.order_id and gtc.create_date_id = co.create_date_id
                 join dwh.d_instrument di on co.instrument_id = di.instrument_id
                 join dwh.d_order_type ot on (co.order_type_id = ot.order_type_id)
                 left join dwh.d_option_contract oc on di.instrument_id = oc.instrument_id

                 left join lateral (select ex.leaves_qty
                                    from dwh.execution ex
                                    where gtc.order_id = ex.order_id
                                      and ex.order_status <> '3'
                                      and ex.exec_date_id >= gtc.create_date_id
                                      and ex.exec_date_id <= in_end_date_id
                                    order by ex.exec_id desc
                                    limit 1) ex on true

                 left join dwh.d_time_in_force tif
                           on co.time_in_force_id = tif.tif_id
        where true
          and gtc.create_date_id <= in_start_date_id
          and co.parent_order_id is null
          and gtc.account_id = any (l_account_ids)
          and di.instrument_type_id = 'O'
          and (gtc.close_date_id is null
-- the code below has been added to provide the same performance in the case we use the report for CURRENT date
            or (case
                    when l_is_current_date then false
                    else gtc.close_date_id is not null and close_date_id >= in_end_date_id end))
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

