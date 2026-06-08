-- https://dashfinancial.atlassian.net/browse/DEVREQ-8392
select
    to_char(cl.create_time, 'dd-mm-yy') as date,
to_char(cl.create_time, 'yyyy-mm-dd"D"hh24:mi:ss.us') as "NewAckTime",
to_char(case when ex.exec_type = '4' then cl.order_cancel_time else ex.exec_time end, 'yyyy-mm-dd"D"hh24:mi:ss.us') as "EndTime", -- ??
par.client_order_id as "ParentOrderID",
cl.parent_order_id as "BrokerRootOrderID",
cl.parent_order_id as "BrokerAlgoOrderID",
i.instrument_type_id as "SecurityType",
target_strategy_name as "Algo",
oc.opra_symbol as "Symbol",
oc.strike_price as "Strike",
oc.put_call as "CallOrPut",
to_char(OC.MATURITY_DAY, 'FM00') ||'-'|| to_char(OC.MATURITY_MONTH, 'FM00') ||'-'|| to_char(OC.MATURITY_YEAR MaturityYear, 'FM0000') as "Expiration",

case when cl.side = '1' then 'Buy' when cl.side in ('2', '5', '6') then 'Sell' end as "Side",
case when cl.side = '1' then 'Buy' when cl.side in ('2', '5', '6') then 'Sell' end as "LegSide",
cl.ratio_qty as "LegRatio",

 from dwh.client_order cl
     left join lateral (select * from dwh.client_order par where par.order_id = cl.parent_order_id limit 1) par on true and cl.parent_order_id is not null
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
             left join lateral (select po.sub_strategy_desc
                                from dwh.client_order po
                                where po.order_id = cl.parent_order_id
                                  and po.create_date_id <= cl.create_date_id
                                limit 1) po on true
             left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
left join dwh.d_target_strategy dts on (dts.target_strategy_id = cl.sub_strategy_id)
             left join lateral (select *
                                from dwh.d_exchange exc
                                where exc.exchange_id = cl.exchange_id
                                  and exc.is_active
                                limit 1) exc on true
             left join lateral(select * from dwh.execution ex where ex.order_id = cl.order_id and exec_date_id >= cl.create_date_id and ex.exec_type not in ('a', 'A', 'S', '0') order by exec_id desc limit 1) ex on true
    where true
--       and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.create_date_id between :in_start_date_id and :in_end_date_id
      and cl.trans_type <> 'F'
