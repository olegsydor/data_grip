select order_id
   from data_marts.f_yield_capture fyc
    inner join dwh.d_target_strategy dts on (dts.target_strategy_id = fyc.parent_sub_strategy_id)
    join dwh.d_account a on fyc.account_id = a.account_id
   where  fyc.status_date_id between  :in_start_date_id and :in_end_date_id
      and parent_order_id is not null
      and dts.target_strategy_name in ('SENSOR')
and fyc.account_id in (select account_id
                        from dwh.d_trading_firm tf
                                 join dwh.d_account ac using (trading_firm_id)
                        where trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus', 'Cowen Prime Services')
                          and ac.is_active
                          and tf.is_active);



select tr.date_id::text,                        -- as trade_dt,
       oc.opra_symbol,                          -- as symbol,
       sum(tr.last_qty)::text,                  -- as qty,
       round(sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0),
             6)::text,                          -- as price,
       round(sum(tr.last_qty * 0.075), 6)::text -- as comm

from dwh.flat_trade_record tr
         inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
         inner join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)
         inner join dwh.d_trading_firm tf on (acc.trading_firm_id = tf.trading_firm_id and tf.is_active)
         left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
         left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
where true
  and tr.date_id between :in_start_date_id and :in_end_date_id
  and tr.instrument_type_id = 'E'
  and tr.is_busted = 'N'
  and acc.account_id in (select account_id
                         from dwh.d_trading_firm tf
                                  join dwh.d_account ac using (trading_firm_id)
                         where
                             trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus', 'Cowen Prime Services')
                           and ac.is_active
                           and tf.is_active)
  and tr.order_id in (select order_id
                      from data_marts.f_yield_capture fyc
                               inner join dwh.d_target_strategy dts
                                          on (dts.target_strategy_id = fyc.parent_sub_strategy_id)
                               join dwh.d_account a on fyc.account_id = a.account_id
                      where fyc.status_date_id between :in_start_date_id and :in_end_date_id
                        and parent_order_id is not null
                        and dts.target_strategy_name in ('SENSOR')
                        and fyc.account_id in (select account_id
                                               from dwh.d_trading_firm tf
                                                        join dwh.d_account ac using (trading_firm_id)
                                               where trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus',
                                                                           'Cowen Prime Services')
                                                 and ac.is_active
                                                 and tf.is_active))
group by tr.open_close, tr.side, tr.date_id, tr.order_id, oc.opra_symbol, tr.order_id



select order_id, order_qty, order_price
                      from data_marts.f_yield_capture fyc
                               inner join dwh.d_target_strategy dts
                                          on (dts.target_strategy_id = fyc.parent_sub_strategy_id)
                               join dwh.d_account a on fyc.account_id = a.account_id
                      where fyc.status_date_id between :in_start_date_id and :in_end_date_id
                        and parent_order_id is not null
                        and dts.target_strategy_name in ('SENSOR')
                        and fyc.account_id in (select account_id
                                               from dwh.d_trading_firm tf
                                                        join dwh.d_account ac using (trading_firm_id)
                                               where trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus',
                                                                           'Cowen Prime Services')
                                                 and ac.is_active
                                                 and tf.is_active);


select * from dwh.client_order
where order_id = 100000019928855616;


drop table trash.so_equity_trade_file;
create table trash.so_equity_trade_file as

with ord as (select distinct order_id
             from data_marts.f_yield_capture fyc
                      inner join dwh.d_target_strategy dts on (dts.target_strategy_id = fyc.parent_sub_strategy_id)
             where fyc.status_date_id between :in_start_date_id and :in_end_date_id
               and parent_order_id is not null
               and dts.target_strategy_name = 'SENSOR'
               and fyc.instrument_type_id = 'E'
               and case
                       when fyc.side in ('1', '3') and fyc.nbbo_ask_price <= fyc.order_price
                           then true -- buy order is marketable
                       when fyc.side not in ('1', '3') and fyc.nbbo_bid_price >= fyc.order_price
                           then true -- sell order is marketable
                       when coalesce(fyc.order_price, 0) = 0 then true
                       else false end
               and fyc.account_id in (select account_id
                                      from dwh.d_trading_firm tf
                                               join dwh.d_account ac using (trading_firm_id)
                                      where trading_firm_name in
                                            ('Pleasant Lake Partners', 'Stifel Nicolaus', 'Cowen Prime Services')
                                        and ac.is_active
                                        and tf.is_active))
select --cl.order_type_id,
       to_char(cl.create_time, 'MM/DD/YYYY'),
       to_char(cl.create_time, 'HH24:MI:SS.MS'),
       'Equity',
       case when cl.side in ('1', '3') then 'Buy' else 'Sell' end,
       di.symbol,
       cl.order_qty,
       cl.price
from trash.so_equity_trade_file ord
         join dwh.client_order cl on cl.order_id = ord.order_id
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id
where cl.create_date_id between :in_start_date_id and :in_end_date_id
  and parent_order_id is not null
  and di.instrument_type_id = 'E';


select distinct order_type_id
from trash.so_equity_trade_file ord
join dwh.client_order cl on cl.order_id = ord.order_id

select * from dwh.d_order_type
