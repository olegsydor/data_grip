13735825550
ClOrdID: Ajklvtdrnt1x
200475 - 20230601
54560 - 2023128

select cl.*
from dwh.client_order cl
where cl.create_date_id = 20231228
--   and cl.create_date_id < 20230701
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
                       );



select sub_strategy_id, * from data_marts.f_yield_capture
where order_id = 13735825550;


select par.order_id
from dwh.client_order par
         join dwh.client_order str on str.parent_order_id = par.order_id and str.create_date_id >= par.create_date_id
    and par.sub_strategy_desc in ('SENSOR', 'DMA')
    and str.create_date_id >= 20230601 and
                                      str.create_date_id < 20230701;