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
                           else coalesce(EX.EXEC_TYPE, '') end end
           else case EX.ORDER_STATUS
                    when 'A' then 'Ex Pnd Open'
                    when '0' then 'Ex Open'
                    when '8' then 'Ex Rej'
                    when 'b' then 'Ex Pnd Cxl'
                    when '1' then 'Ex Partial'
                    when '2' then 'Ex Rpt Fill'
                    when '4' then 'Ex Rpt Out'
                    else coalesce(EX.ORDER_STATUS, '') end
           end                                                                   as "Action",
       'DASH'                                                                    as "Executing Broker",
       'SQRT'                                                                    as "Client",
       case
           when CL.SIDE = '1' and CL.OPEN_CLOSE = 'C' then 'BC'
           else case CL.SIDE when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SS' end
           end                                                                   as "Side",
       'Opp'                                                                     as "Fut/Opt",
       di.symbol                                                                 as "Ticker",
       OC.OPRA_SYMBOL                                                            as "BBG", --OSI
--             cl.exchange_id as "Exchange",
       exc.exchange_name                                                         as "Exchange",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') ||
       to_char(OC.MATURITY_DAY, 'FM00')                                          as "Maturity Date",
       to_char(OC.MATURITY_YEAR, 'FM0000') || to_char(OC.MATURITY_MONTH, 'FM00') as "Prompt",
       oc.strike_price                                                           as "Strike",
       oc.put_call                                                               as "Put/Call",
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