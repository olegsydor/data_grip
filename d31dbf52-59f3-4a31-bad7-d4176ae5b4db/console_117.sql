-- DROP FUNCTION dash360.report_fintech_eod_traiana_broker_fills_(int4, int4, _int4, _varchar, text, numeric);

CREATE OR REPLACE FUNCTION dash360.report_fintech_eod_traiana_broker_fills(in_start_date_id integer DEFAULT public.get_dateid(CURRENT_DATE), in_end_date_id integer DEFAULT public.get_dateid(CURRENT_DATE), in_account_ids integer[] DEFAULT NULL::integer[], in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], in_exec_broker text DEFAULT NULL::text, in_comm_rate numeric DEFAULT 0)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
    -- 2024-11-25 OS https://dashfinancial.atlassian.net/browse/DEVREQ-4978
    -- 2025-01-21 OS added new parameters
    -- 2025-02-07 OS added in_comm_rate
    -- 2025-02-12 OS changed logic into using flat_trade_record
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

--    return query
--        select 'Trade date,Trade Ref,Order ID,Action,Executing Broker,Client,Side,Fut/Opt,Ticker,BBG,Exchange,Maturity Date,Prompt,Strike,Put/Call,Quantity,Price,Expiry,Commission';

    return query
        select array_to_string(array [
                                   ftr.date_id::text, -- as "Trade date",
--                                    ftr.order_id::text, -- as "Trade Ref",
                                   fmj.tag_17,-- as "Trade Ref",
                                   ftr.client_order_id, -- as "Order ID",
                                   case
                                       when ftr.is_busted = 'Y' then 'Cancel'
                                       when ftr.orig_trade_record_id is not null then 'Amend'
                                       else 'New' end, --as "Action",
                                   in_exec_broker, -- as "Executing Broker",
                                   upper(ftr.trading_firm_id), -- as "Client",
                                   case ftr.side
                                       when '1' then 'Buy'
                                       when '2' then 'Sell'
                                       when '3' then 'Buymin'
                                       when '5' then 'SellShort'
                                       end, -- as "Side",
                                   'Opt', -- as "Fut/Opt",
                                   di.symbol, -- as "Ticker",
                                   oc.opra_symbol, -- as "BBG", --OSI
--             cl.exchange_id -- as "Exchange",
                                   exc.mic_code, -- as "Exchange",
                                   to_char(oc.maturity_year, 'FM0000') || to_char(OC.maturity_month, 'FM00') ||
                                   to_char(OC.maturity_day, 'FM00'), -- as "Maturity Date",
                                   to_char(OC.maturity_year, 'FM0000') ||
                                   to_char(OC.maturity_month, 'FM00'), -- as "Prompt",
                                   oc.strike_price::text, -- as "Strike",
                                   case oc.put_call when '0' then 'Put' when '1' then 'Call' end, -- as "Put/Call",
                                   ex.last_qty::text, -- as "Quantity",
                                   ex.last_px::text, -- as "Price",
                                   to_char(OC.maturity_year, 'FM0000') || to_char(OC.maturity_month, 'FM00') ||
                                   to_char(OC.maturity_day, 'FM00'), -- as "Expiry"
--                                   case
--                                       when in_exec_broker is not distinct from 'DASH'
--                                           then ftr.tcce_account_dash_commission_amount::text end -- as "Commission
                                   to_char(in_comm_rate, 'FM999990.0099')
--                                    , ex.*
                                   ], ',', '')
        from dwh.flat_trade_record ftr
                 join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
                 left join lateral (select ex.last_qty, ex.last_px
                                    from dwh.execution ex
                                    where ftr.order_id = ex.order_id
                                      and ex.exec_id = ftr.exec_id
                                      and ex.exec_date_id = ftr.date_id
                                    limit 1) ex on true
                 left join dwh.d_exchange exc on exc.exchange_id = ftr.exchange_id and exc.is_active
                 inner join dwh.d_option_contract oc on (oc.instrument_id = ftr.instrument_id)
                 inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                 left join lateral (select fmj.fix_message ->> '17' as tag_17
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = ftr.trade_fix_message_id
                              and fmj.date_id = ftr.date_id
                            limit 1) fmj on true


        where ftr.date_id between in_start_date_id and in_end_date_id
          and case when l_account_ids = '{}' then true else ftr.account_id = any (l_account_ids) end
--           and cl.parent_order_id is null
          and ftr.multileg_reporting_type in ('1', '2')
          and di.instrument_type_id = 'O'
--         and ftr.order_id = 17751341583
        order by ftr.order_id, ftr.exec_id, case when is_busted = 'N' then 1 else 2 end;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_traiana_broker_fills for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end ;
$function$
;



select --array_to_string(array [
       ftr.date_id::text,                                             -- as "Trade date",
--                                    ftr.order_id::text, -- as "Trade Ref",
       ftr.client_order_id,
       fmj.tag_17,-- as "Trade Ref",
       ftr.client_order_id,                                           -- as "Order ID",
       case
           when ftr.is_busted = 'Y' then 'Cancel'
           when ftr.orig_trade_record_id is not null then 'Amend'
           else 'New' end,                                            --as "Action",
       :in_exec_broker,                                               -- as "Executing Broker",
       upper(ftr.trading_firm_id),                                    -- as "Client",
       case ftr.side
           when '1' then 'Buy'
           when '2' then 'Sell'
           when '3' then 'Buymin'
           when '5' then 'SellShort'
           end,                                                       -- as "Side",
       'Opt',                                                         -- as "Fut/Opt",
       di.symbol,                                                     -- as "Ticker",
       oc.opra_symbol,                                                -- as "BBG", --OSI
--             cl.exchange_id -- as "Exchange",
       exc.mic_code,                                                  -- as "Exchange",
       to_char(oc.maturity_year, 'FM0000') || to_char(OC.maturity_month, 'FM00') ||
       to_char(OC.maturity_day, 'FM00'),                              -- as "Maturity Date",
       to_char(OC.maturity_year, 'FM0000') ||
       to_char(OC.maturity_month, 'FM00'),                            -- as "Prompt",
       oc.strike_price::text,                                         -- as "Strike",
       case oc.put_call when '0' then 'Put' when '1' then 'Call' end, -- as "Put/Call",
       ex.last_qty::text,                                             -- as "Quantity",
       ex.last_px::text,                                              -- as "Price",
       to_char(OC.maturity_year, 'FM0000') || to_char(OC.maturity_month, 'FM00') ||
       to_char(OC.maturity_day, 'FM00'),                              -- as "Expiry"
--                                   case
--                                       when in_exec_broker is not distinct from 'DASH'
--                                           then ftr.tcce_account_dash_commission_amount::text end -- as "Commission
       to_char(:in_comm_rate, 'FM999990.0099')
--                                    , ex.*
--                                    ], ',', '')
from dwh.flat_trade_record ftr
         join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
         left join lateral (select ex.last_qty, ex.last_px
                            from dwh.execution ex
                            where ftr.order_id = ex.order_id
                              and ex.exec_id = ftr.exec_id
                              and ex.exec_date_id = ftr.date_id
                            limit 1) ex on true
         left join dwh.d_exchange exc on exc.exchange_id = ftr.exchange_id and exc.is_active
         inner join dwh.d_option_contract oc on (oc.instrument_id = ftr.instrument_id)
         inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
         inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
         left join lateral (select fmj.fix_message ->> '17' as tag_17
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = ftr.trade_fix_message_id
                              and fmj.date_id = ftr.date_id
                            limit 1) fmj on true


where ftr.date_id between :in_start_date_id and :in_end_date_id
  and case when :l_account_ids = '{}' then true else ftr.account_id = any (:l_account_ids) end
--           and cl.parent_order_id is null
  and ftr.multileg_reporting_type in ('1', '2')
  and di.instrument_type_id = 'O';


select *
from dash360.report_fintech_eod_traiana_broker_fills(in_start_date_id := 20241101, in_end_date_id := 20241102,
                                                     in_account_ids := '{70621}', in_exec_broker := 'DASH',
                                                     in_comm_rate := 1)