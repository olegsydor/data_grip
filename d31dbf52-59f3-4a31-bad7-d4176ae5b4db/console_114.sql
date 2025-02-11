-- DROP FUNCTION dash360.report_fintech_eod_traiana_broker_fills(int4, int4, _int4, _varchar, text, numeric);

CREATE OR REPLACE FUNCTION dash360.report_fintech_eod_traiana_broker_fills(in_start_date_id integer DEFAULT public.get_dateid(CURRENT_DATE), in_end_date_id integer DEFAULT public.get_dateid(CURRENT_DATE), in_account_ids integer[] DEFAULT NULL::integer[], in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], in_exec_broker text DEFAULT NULL::text, in_comm_rate numeric DEFAULT 0)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
    -- 2024-11-25 OS https://dashfinancial.atlassian.net/browse/DEVREQ-4978
    -- 2025-01-21 OS added new parameters
    -- 2025-02-07 OS added in_comm_rate
declare
    l_load_id     int;
    l_step_id     int;
    l_row_cnt     int;
    l_account_ids int4[];

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_traiana_broker_fills for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
--         into l_account_ids
        from dwh.d_account
        where a
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    return query
        select 'Trade date,Trade Ref,Order ID,Action,Executing Broker,Client,Side,Fut/Opt,Ticker,BBG,Exchange,Maturity Date,Prompt,Strike,Put/Call,Quantity,Price,Expiry,Commission';

    return query
        select --array_to_string(array [
--                                    to_char(ex.exec_time, 'YYYYMMDD'), -- as "Trade date",
                                   cl.order_id::text, -- as "Trade Ref",
--                                    cl.client_order_id, -- as "Order ID",
            ex.exec_id,
                                   ex.exec_type,
                                   case ex.exec_type
                                       when 'F' then 'New' -- New
                                       when '4' then 'Cancel' -- Cancel
                                       when '5' then 'Amend' -- Replace
                                       when 'W' then 'Amend' -- Replace
                                       end, -- as "Action",

--                                    :in_exec_broker, -- as "Executing Broker",
--                                    upper(cl.trading_firm_id), -- as "Client",
--                                    case cl.side
--                                        when '1' then 'Buy'
--                                        when '2' then 'Sell'
--                                        when '3' then 'Buymin'
--                                        when '5' then 'SellShort'
--                                        end, -- as "Side",
--                                    'Opt', -- as "Fut/Opt",
--                                    di.symbol, -- as "Ticker",
--                                    oc.opra_symbol, -- as "BBG", --OSI
-- --             cl.exchange_id -- as "Exchange",
--                                    exc.mic_code, -- as "Exchange",
--                                    to_char(oc.maturity_year, 'FM0000') || to_char(OC.maturity_month, 'FM00') ||
--                                    to_char(OC.maturity_day, 'FM00'), -- as "Maturity Date",
--                                    to_char(OC.maturity_year, 'FM0000') ||
--                                    to_char(OC.maturity_month, 'FM00'), -- as "Prompt",
                                   oc.strike_price::text, -- as "Strike",
                                   case oc.put_call when '0' then 'Put' when '1' then 'Call' end, -- as "Put/Call",
                                   CL.order_qty::text, -- as "Quantity",
                                   cl.price::text, -- as "Price",
                                   to_char(OC.maturity_year, 'FM0000') || to_char(OC.maturity_month, 'FM00') ||
                                   to_char(OC.maturity_day, 'FM00'), -- as "Expiry"
                                  case
                                      when :in_exec_broker is not distinct from 'DASH'
                                          then ftr.tcce_account_dash_commission_amount::text end, -- as "Commission
                                   to_char(:in_comm_rate, 'FM999990.0099')
                               --    ], ',', '')
        from dwh.client_order cl
                 inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 inner join dwh.execution ex on cl.order_id = ex.order_id and ex.exec_date_id >= cl.create_date_id
                 left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                 inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                 inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                 left join lateral (select ftr.tcce_account_dash_commission_amount
                                    from dwh.flat_trade_record ftr
                                    where ftr.exec_id = ex.exec_id
                                      and ex.order_id = ftr.order_id
                                      and ex.exec_date_id = ftr.date_id
                                    limit 1
            ) ftr on true

        where cl.create_date_id between :in_start_date_id and :in_end_date_id
          and case when :l_account_ids = '{}' then true else cl.account_id = any (:l_account_ids) end
          and cl.parent_order_id is null
          and cl.multileg_reporting_type in ('1', '2')
          and di.instrument_type_id = 'O'
          and ex.is_busted = 'N'
--           and ex.exec_type not in ('3', 'a', '5', 'E')
--           and ex.exec_type in ('F', '4', 'W', '5')
          and ex.exec_type in ('F', '4', '5')
          and cl.trans_type <> 'F'
--           and case when in_exec_broker is null then true else ex.exec_broker = in_exec_broker end
        order by cl.order_id, ex.exec_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_traiana_broker_fills for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end ;
$function$
;
