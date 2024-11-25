/*select distinct side from dwh.client_order
where create_date_id >= 20241101

create temp table t_os as
select --cl.account_id,
       to_char(ex.exec_time, 'YYYYMMDD')::int4                                   as "Trade date",
       cl.order_id                                                               as "Trade Ref",
       cl.client_order_id                                                        as "Order ID",
       case
           when CL.PARENT_ORDER_ID is null then
               case EX.ORDER_STATUS
                   when 'A' then 'Pnd Open'
                   when 'b' then 'Pnd Cxl'
                   when 'S' then 'Pnd Rep'
                   when '1' then 'Partial'
                   when '2' then 'Filled'
                   else
                       case EX.EXEC_TYPE
                           when '4' then 'Canceled'
                           when 'W' then 'Replaced'
                           else EX.EXEC_TYPE end end
           else case EX.ORDER_STATUS
                    when 'A' then 'Pending New'
                    when '0' then 'New'
                    when '8' then 'Rejected'
                    when 'b' then 'Pending Cancel'
                    when '1' then 'Partial Fill'
                    when '2' then 'Filled'
                    when '3' then 'Done For Day'
                    when '4' then 'Ex Rpt Out'
                    else coalesce(EX.ORDER_STATUS, '') end
           end                                                                   as "Action",
       'DASH'                                                                    as "Executing Broker",
       'SQRT'                                                                    as "Client",
       case cl.side
           when '1' then 'Buy'
           when '2' then 'Sell'
           when '3' then 'Buymin'
           when '5' then 'SellShort'
           end                                                                   as "Side",
       'Opt'                                                                     as "Fut/Opt",
       di.symbol                                                                 as "Ticker",
       OC.OPRA_SYMBOL                                                            as "BBG", --OSI
--             cl.exchange_id as "Exchange",
       exc.mic_code                                                              as "Exchange",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') ||
       to_char(OC.MATURITY_DAY, 'FM00')                                          as "Maturity Date",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') as "Prompt",
       oc.strike_price                                                           as "Strike",
       case oc.put_call when '0' then 'Put' when '1' then 'Call' end             as "Put/Call",
       CL.ORDER_QTY                                                              as "Quantity",
       cl.price                                                                  as "Price",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') ||
       to_char(OC.MATURITY_DAY, 'FM00')                                          as "Expiry"
from dwh.client_order cl
         inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id
         inner join dwh.execution ex on cl.order_id = ex.order_id and ex.exec_date_id >= cl.create_date_id
         left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
         inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
         inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
         inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id

where CL.CREATE_date_id between :in_start_date_id and :in_end_date_id
--             and AC.TRADING_FIRM_ID = in_firm
  and case when :l_account_ids = '{}' then true else cl.account_id = any ('{70621}') end
  --and CL.PARENT_ORDER_ID is null -- all orders
  and CL.MULTILEG_REPORTING_TYPE in ('1', '2')
  and di.instrument_type_id = 'O'
  and EX.IS_BUSTED = 'N'
  and EX.EXEC_TYPE not in ('3', 'a', '5', 'E')
  and CL.TRANS_TYPE <> 'F'
  and ((CL.PARENT_ORDER_ID is null and EX.EXEC_TYPE <> '0') or CL.PARENT_ORDER_ID is not null)
order by cl.order_id, ex.exec_id
-- and ex.order_id = 13454466648
;

select "Action", count(*)
from t_os
-- where "OrderType" = 'Street'
group by  "Action";
*/

select cl.client_order_id,
       cl.order_id,
       cl.account_id,
       to_char(ex.exec_time, 'YYYYMMDD')::int4                                   as "Trade date",
       cl.order_id                                                               as "Trade Ref",
       cl.client_order_id                                                        as "Order ID",
       case
           when CL.PARENT_ORDER_ID is null then
               case EX.ORDER_STATUS
                   when 'A' then 'Pnd Open'
                   when 'b' then 'Pnd Cxl'
                   when 'S' then 'Pnd Rep'
                   when '1' then 'Partial'
                   when '2' then 'Filled'
                   else
                       case EX.EXEC_TYPE
                           when '4' then 'Canceled'
                           when 'W' then 'Replaced'
                           else EX.EXEC_TYPE end end
           end                                                                   as "Action_old",

       case
           when CL.PARENT_ORDER_ID is null then
--                case EX.ORDER_STATUS
--                    when 'A' then 'New'
--                    when 'b' then 'Cancel'
--                    when 'S' then 'Amend'
--                    when '1' then 'AMend'
--                    when '2' then '???'
--                    else
                       case EX.EXEC_TYPE
                           when '0' then 'New'
                           when '4' then 'Cancel'
                           when '5' then 'Amend'
                           when 'W' then 'Amend'
                           else EX.EXEC_TYPE end --end
           end                                                                   as "Action",
    EX.EXEC_TYPE,

       'DASH'                                                                    as "Executing Broker",
       'SQRT'                                                                    as "Client",
       case cl.side
           when '1' then 'Buy'
           when '2' then 'Sell'
           when '3' then 'Buymin'
           when '5' then 'SellShort'
           end                                                                   as "Side",
       'Opt'                                                                     as "Fut/Opt",
       di.symbol                                                                 as "Ticker",
       OC.OPRA_SYMBOL                                                            as "BBG", --OSI
--             cl.exchange_id as "Exchange",
       exc.mic_code                                                              as "Exchange",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') ||
       to_char(OC.MATURITY_DAY, 'FM00')                                          as "Maturity Date",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') as "Prompt",
       oc.strike_price                                                           as "Strike",
       case oc.put_call when '0' then 'Put' when '1' then 'Call' end             as "Put/Call",
       CL.ORDER_QTY                                                              as "Quantity",
       cl.price                                                                  as "Price",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') ||
       to_char(OC.MATURITY_DAY, 'FM00')                                          as "Expiry"
from dwh.client_order cl
         inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id
         inner join dwh.execution ex on cl.order_id = ex.order_id and ex.exec_date_id >= cl.create_date_id
         left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
         inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
         inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
         inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id

where CL.CREATE_date_id between :in_start_date_id and :in_end_date_id
--             and AC.TRADING_FIRM_ID = in_firm
  and case when :l_account_ids = '{}' then true else cl.account_id = any (:l_account_ids) end
--   and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
  and CL.PARENT_ORDER_ID is null
  and CL.MULTILEG_REPORTING_TYPE in ('1', '2')
  and di.instrument_type_id = 'O'
  and EX.IS_BUSTED = 'N'
--   and EX.EXEC_TYPE not in ('3', 'a', '5', 'E')
  and EX.EXEC_TYPE in ('0', '4', 'W', '5')
  and CL.TRANS_TYPE <> 'F'
--   and CL.TRANS_TYPE in ('D', 'G')
--   and ((CL.PARENT_ORDER_ID is null and EX.EXEC_TYPE <> '0') or CL.PARENT_ORDER_ID is not null)
order by cl.order_id, ex.exec_id;



create
    or replace
    function dash360.report_fintech_eod_traiana_broker_fills(in_start_date_id integer default public.get_dateid(current_date),
                                                             in_end_date_id integer default public.get_dateid(current_date),
                                                             in_account_ids int4[] default null::int4[],
                                                             in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$function$
    -- 2024-11-25 OS https://dashfinancial.atlassian.net/browse/DEVREQ-4978
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

    return query
        select 'Trade date,Trade Ref,Order ID,Action,Executing Broker,Client,Side,Fut/Opt,Ticker,BBG,Exchange,Maturity Date,Prompt,Strike,Put/Call,Quantity,Price,Expiry,Commission';

    return query
        select array_to_string(array [
                                   to_char(ex.exec_time, 'YYYYMMDD'), -- as "Trade date",
                                   cl.order_id::text, -- as "Trade Ref",
                                   cl.client_order_id, -- as "Order ID",
                                   case ex.exec_type
                                       when '0' then 'New' -- New
                                       when '4' then 'Amend' -- Cancel
                                       when '5' then 'Amend' -- Replace
                                       when 'W' then 'Amend' -- Replace
                                       end, -- as "Action",

                                   'DASH', -- as "Executing Broker",
                                   'SQRT', -- as "Client",
                                   case cl.side
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
                                   CL.order_qty::text, -- as "Quantity",
                                   cl.price::text, -- as "Price",
                                   to_char(OC.maturity_year, 'FM0000') || to_char(OC.maturity_month, 'FM00') ||
                                   to_char(OC.maturity_day, 'FM00'), -- as "Expiry"
                                   '0' -- as "Commission
                                   ], ',', '')
        from dwh.client_order cl
                 inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 inner join dwh.execution ex on cl.order_id = ex.order_id and ex.exec_date_id >= cl.create_date_id
                 left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                 inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                 inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id

        where cl.create_date_id between in_start_date_id and in_end_date_id
          and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
          and cl.parent_order_id is null
          and cl.multileg_reporting_type in ('1', '2')
          and di.instrument_type_id = 'O'
          and ex.is_busted = 'N'
--           and ex.exec_type not in ('3', 'a', '5', 'E')
          and ex.exec_type in ('0', '4', 'W', '5')
          and cl.trans_type <> 'F'
        order by cl.order_id, ex.exec_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_traiana_broker_fills for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$;


select * from dash360.report_fintech_eod_traiana_broker_fills(20241101, 20241102,'{70621}')