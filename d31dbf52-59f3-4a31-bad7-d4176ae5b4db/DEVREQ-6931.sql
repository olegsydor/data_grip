-- DROP FUNCTION dash360.report_fintech_eod_strategas_allocation(int4, int4);
-- dash360.report_fintech_eod_spdradv01_allocation(in_start_date_id, in_end_date_id, in_trading_firm_ids, in_account_ids)
CREATE OR REPLACE FUNCTION dash360.report_fintech_eod_spdradv01_allocation(in_start_date_id integer, in_end_date_id integer, in_account_ids integer[] DEFAULT NULL::integer[], in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $fn$
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids int4[];
    l_min_date_id int4;
    l_is_current_date bool := false;
begin
    l_step_id := 0;
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_spdradv01_allocation for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    select coalesce(min(create_date_id), in_start_date_id)
    into l_min_date_id
    from dwh.gtc_order_status
    where close_date_id is null
      and account_id = any (l_account_ids);

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;
--
    return query
        select 'Master,Underlying Symbol,Expiration,Strike,Type,Contracts,Action,Price,Broker,Comm,T/D,S/D';
--         select 'ORDER_DATE,ROUTED_ORDER_REF,TYPE,BUY_SELL,CALL_PUT,OPEN_CLOSE,CONTRACTS,LEAVES_QTY,SYMBOL,EXPIRY,STRIKE,PRICE_TYPE,LIMIT_PRICE,STOP_PRICE,EXPIRY_TYPE,BROKER_ORDER_ID,SENDER_SUB_ID,EXPIREDATE';

    return query
        select array_to_string(ARRAY [
            '08423881', -- Master
            ui.symbol, -- Underlying Symbol,
            to_char(coalesce(di.last_trade_date, co.expire_time), 'DD-Mon-YY'), -- Expiration
            oc.strike_price::text, -- Strike
                                               case
                                       when oc.put_call = '0' then 'PUT'
                                       when oc.put_call = '1' then 'CALL'
                                       end, -- Type
                                               order_qty::text, -- Contracts
             case
     when side = '2' and open_close = 'C' then 'SCO'--'Sell to Close'
     when side = '2' and open_close = 'O' then 'SOO'--'Sell to Open'
     when side = '1' and open_close = 'C' then 'BCO'--'Buy to Close'
                                      when side = '1' and open_close = 'O' then 'BOO'--'Buy to Open'
                                 end, --  as "Action"
                                   co.price::text, -- Price
exchange_id, -- Broker
                                   to_char(round(ex.last_qty * 0.25, 4), 'FM99999990D0099'),-- Comm
            to_char(ex.trade_date, 'MM/DD/YYYY'), -- T/D
                to_char(public.get_settle_date_by_instrument_type(ex.trade_date, di.instrument_type_id), 'MM/DD/YYYY')::varchar --S/D

                                   to_char(co.create_time, 'yyyyMMdd'), -- ORDER_DATE
                                   co.client_order_id, -- ROUTED_ORDER_REF
                                   'OPTION', -- TYPE

                                   di.symbol, -- SYMBOL
                                   to_char(coalesce(di.last_trade_date, co.expire_time), 'DD-Mon-YY'), -- EXPIRY

                                   ot.order_type_short_name, -- PRICE_TYPE

                                   co.stop_price::text, -- STOP_PRICE
                                   tif.tif_short_name, -- EXPIRY_TYPE
                                   co.order_id::text, -- BROKER_ORDER_ID
                                   null, -- SENDER_SUB_ID
                                   null -- EXPIREDATE
                                   ], ',', '')
        from dwh.gtc_order_status gtc
                 join dwh.client_order co on gtc.order_id = co.order_id and gtc.create_date_id = co.create_date_id
                 join dwh.d_instrument di on co.instrument_id = di.instrument_id
                 join dwh.d_order_type ot on (co.order_type_id = ot.order_type_id)
                 left join dwh.d_option_contract oc on di.instrument_id = oc.instrument_id
left join dwh.d_option_series dos on oc.option_series_id = dos.option_series_id
                               left join dwh.d_instrument ui on ui.instrument_id = dos.underlying_instrument_id
                 left join lateral (select ex.last_qty, exec_time::date as trade_date
                                    from dwh.execution ex
                                    where gtc.order_id = ex.order_id
                                      and ex.order_status <> '3'
                                      and ex.exec_date_id >= gtc.create_date_id
                                    order by ex.exec_id desc
                                    limit 1) ex on true

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
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_strategas_allocation for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;

end;
$fn$
;
