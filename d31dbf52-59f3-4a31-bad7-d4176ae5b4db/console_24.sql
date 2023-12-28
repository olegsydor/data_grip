13735825550
ClOrdID: Ajklvtdrnt1x

select cl.exchange_id, par.sub_strategy_desc, cl.*
from dwh.client_order cl
join lateral (select sub_strategy_desc from dwh.client_order par where par.order_id = cl.parent_order_id and sub_strategy_desc in ('SENSOR', 'DMA') limit 1) par on true
where cl.create_date_id >= 20230601
    and cl.create_date_id < 20230701
--   and cl.sub_strategy_desc = 'SENSOR'
--   and cl.account_id in (select account_id from dwh.d_account where trading_firm_id = 'baml')
  and cl.exchange_id in
      ('ARCAML', 'BATSML', 'BATYML', 'EDGAML', 'EDGXML', 'EPRLML', 'IEXML', 'LTSEML', 'MEMXML', 'NQBXML', 'NSDQML',
       'NSXML', 'NYSEML', 'XASEML', 'XCHIML', 'XPSXML')
-- and cl.order_id = 13735825550
  and parent_order_id is not null
and par.sub_strategy_desc in ('SENSOR', 'DMA')


select sub_strategy_id, * from data_marts.f_yield_capture
where order_id = 13735825550;