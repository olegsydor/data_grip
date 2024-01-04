13735825550
ClOrdID: Ajklvtdrnt1x
200475 - 20230601
54560 - 2023128

           case when str.Order_Type_id = '1' then 'Y'
        when str.Side  = '1' and str.Price >= exch_md.ask_price then 'Y'
        when str.Side <> '1' and str.Price <= exch_md.bid_price then 'Y'
        else 'N'
      end as Is_Marketable,


select distinct cl.order_id
from dwh.client_order cl
where cl.create_date_id = 20231228
  and cl.exchange_id in
      ('ARCAML', 'BATSML', 'BATYML', 'EDGAML', 'EDGXML', 'EPRLML', 'IEXML', 'LTSEML', 'MEMXML', 'NQBXML', 'NSDQML',
       'NSXML', 'NYSEML', 'XASEML', 'XCHIML', 'XPSXML')
  and parent_order_id is not null
and exists (select sub_strategy_desc
                       from dwh.client_order par
                       where par.order_id = cl.parent_order_id
                         and par.sub_strategy_desc in ('SENSOR', 'DMA')
                         and par.create_date_id <= cl.create_date_id
                         and par.sub_strategy_desc in ('SENSOR', 'DMA')
                       )
 and case when cl.Order_Type_id = '1' then true
        when str.side  = '1' and str.Price >= exch_md.ask_price then 'Y'
        when str.Side <> '1' and str.Price <= exch_md.bid_price then 'Y'
        else 'N'
      end as Is_Marketable;

/*
Marketable equity DMA orders routed to BAML Softbot routes list below -I would like parent orders that were filled/partially filled.

Equity SENSOR BEST IOC orders routed to BAML Softbot routes list below - I would like any street orders that were filled/partially filled
as well as the associated parent order ID and routing table name.
*/
--select * from t_dma

select ftr.date_id,                                                                                         -- date_id
       str.process_time,                                                                                    -- execution_Time
       par.order_id,                                                                                        -- parent_order_id
       str.order_id,                                                                                        -- order_id
       ftr.order_process_time,                                                                              -- route_time
       str.exchange_id,                                                                                     -- exchange_id
       tf.trading_firm_name,                                                                                -- firm Name
       ftr.side,                                                                                            -- side
       di.symbol,                                                                                           -- symbol
       str.order_qty, -- route_qty
       str.price                       as price,     -- price
       ftr.last_px,                                                                                         -- fill_px
       ftr.last_qty                                                                                         -- fill_qty
from dwh.client_order par
         join dwh.client_order str on str.parent_order_id = par.order_id and str.create_date_id >= par.create_date_id
         left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                            from dwh.l1_snapshot ls
                            where ls.transaction_id = par.transaction_id
                              and ls.exchange_id = 'NBBO'
                              and ls.start_date_id = to_char(par.create_time, 'YYYYMMDD')::int4
                            limit 1
    ) md on true
         join lateral (select *
                       from dwh.flat_trade_record ftr
                       where ftr.order_id = par.order_id
                         and ftr.date_id >= par.create_date_id
                         and ftr.is_busted = 'N'
                       limit 1) ftr on true
         join dwh.d_account ac on ac.account_id = par.account_id
         join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_unq_id
    join dwh.d_instrument di on di.instrument_id = str.instrument_id
where str.create_date_id between 20231228 and 20231231
  and str.exchange_id in
      ('ARCAML', 'BATSML', 'BATYML', 'EDGAML', 'EDGXML', 'EPRLML', 'IEXML', 'LTSEML', 'MEMXML', 'NQBXML', 'NSDQML',
       'NSXML', 'NYSEML', 'XASEML', 'XCHIML', 'XPSXML')
  and par.sub_strategy_desc = 'DMA'
  and case
          when par.order_type_id = '1' then true
          when par.side = '1' and par.price >= md.ask_price then true
          when par.side <> '1' and par.price <= md.bid_price then true
          else false end;




select * from d_strategy_decision_reason_code
where strategy_user_data ilike '%BEST IOC%';



select * from dwh.d_time_in_force;

select * from d_target_strategy;


select dt.target_strategy_desc, fyc.is_marketable, fyc.exchange_id, fyc.* from data_marts.f_yield_capture fyc
         join dwh.d_target_strategy dt on fyc.sub_strategy_id = dt.target_strategy_id
where order_id in (14104242610,
14104289430,
14104807191,
14104808327,
14104814515,
14100988947,
14103109868,
14104056859,
14104090824,
14104126241,
14104126241,
14104144289,
14104269347,
14104273988,
14104765286,
14104767182,
14104768848,
14104775906,
14104788136,
14101116015,
14101116015,
14101349136,
14101711298
);

