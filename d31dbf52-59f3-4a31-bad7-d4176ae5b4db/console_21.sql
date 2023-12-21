select exchange_name,
       count(*)                          order_count,
       sum(order_qty)::bigint            order_qty,
       sum(is_executed)                  exec_order_count,
       sum(exec_qty)::bigint             exec_qty,
       sum(exec_qty * slippage)::numeric total_slippage,
       case
           when sum(exec_qty) = 0 then null
           else sum(exec_qty * slippage)::numeric / sum(exec_qty)::numeric
           end                           weighted_avg_slippage,
       avg(yield)                        avg_yield
from (select str.transaction_id,
             str.order_id,
             real_exch.exchange_name,
             str.side,
             str.nbbo_ask_price                                         as ask_px,
             str.nbbo_ask_quantity                                      as ask_qty,
             str.nbbo_bid_price                                         as bid_px,
             str.nbbo_bid_quantity                                      as bid_qty,
             case
                 when str.day_cum_qty > 0 and str.side <> '1'
                     then str.avg_px - (str.nbbo_ask_price + str.nbbo_bid_price) / 2
                 when str.day_cum_qty > 0 and str.side = '1'
                     then (str.nbbo_ask_price + str.nbbo_bid_price) / 2 - str.avg_px
                 else 0
                 end                                                    as slippage,
             str.order_price                                            as limit_px,
             str.is_marketable                                          as is_marketable,
             str.day_avg_px                                             as avg_px,
             str.day_order_qty                                          as order_qty,
             str.day_cum_qty                                            as exec_qty,
             case
                 when str.day_cum_qty > 0 then 1
                 else 0
                 end                                                       is_executed,
             str.yield                                                  as yield,
             coalesce(sdrc.strategy_user_data, 'Unknown')::varchar(256) as routing_reason
      from data_marts.f_yield_capture str
               inner join data_marts.f_yield_capture par on (par.order_id = str.parent_order_id and
                                                             par.status_date_id between :in_start_date_id and :in_end_date_id)
               inner join dwh.d_account acc on (acc.account_id = par.account_id)
               left join dwh.d_exchange exch on (exch.exchange_unq_id = str.exchange_unq_id
          and exch.instrument_type_id = str.instrument_type_id
          and
                                                 str.status_date_id between to_char(exch.date_start, 'YYYYMMDD')::int and to_char(coalesce(exch.date_end, current_timestamp), 'YYYYMMDD')::int)
               left join dwh.d_exchange real_exch
                         on (real_exch.exchange_id = exch.real_exchange_id and real_exch.is_active)
               left join data_marts.d_sub_strategy as dss on par.sub_strategy_id = dss.sub_strategy_id
               left join dwh.d_strategy_decision_reason_code sdrc
                         on (sdrc.strategy_decision_reason_code = str.strategy_decision_reason_code)
      -- left join data_marts.d_client dc on (par.client_id = dc.client_id)
      where str.parent_order_id is not null
        and str.status_date_id between :in_start_date_id and :in_end_date_id
        and str.strategy_decision_reason_code in (5, 10, 13, 15, 16, 17, 60, 64)
      ) streets
group by exchange_name;


select *
from dwh.client_order par
         join dwh.client_order str on str.parent_order_id = par.order_id and str.create_date_id >= par.create_date_id
         left join dwh.execution ex on ex.order_id = str.order_id and ex.exec_date_id >= str.create_date_id and ex.order_status in ('1', '2')
--          left join lateral (select *
--                             from dwh.l1_snapshot ls
--                             where ls.transaction_id = str.transaction_id
--                               and ls.exchange_id = 'NBBO'
--                               and start_date_id = str.create_date_id
--                             limit 1) l1 on true
    and str.sub_strategy_desc = 'DMA'
    and par.create_date_id = 20231219
and str.create_date_id >= 20231219
    and str.account_id in (select account_id from dwh.d_account where trading_firm_id = 'baml')



select *
from dwh.client_order par
where par.create_date_id = 20231219
  and exists (select null
              from dwh.client_order str
                       join dwh.execution ex on ex.order_id = str.order_id and ex.exec_date_id >= str.create_date_id and
                                                ex.order_status in ('1', '2')
              where str.parent_order_id = par.order_id
                and str.create_date_id >= par.create_date_id
                and str.sub_strategy_desc = 'DMA'
                and str.create_date_id >= 20231219
                and ex.exec_date_id >= 20231219
                and str.account_id in (select account_id from dwh.d_account where trading_firm_id = 'baml'))
    and par.parent_order_id is null
--          left join lateral (select *
--                             from dwh.l1_snapshot ls
--                             where ls.transaction_id = str.transaction_id
--                               and ls.exchange_id = 'NBBO'
--                               and start_date_id = str.create_date_id
--                             limit 1) l1 on true


select *
from dwh.client_order cl
--          join dwh.d_instrument di on di.instrument_id = cl.instrument_id
--          join dwh.execution ex on ex.order_id = cl.order_id and ex.exec_date_id >= cl.create_date_id and
--                                   ex.order_status in ('1', '2')
where cl.create_date_id >= :in_date_id
  and cl.sub_strategy_desc = 'DMA'
  and cl.create_date_id >= :in_date_id
--   and ex.exec_date_id >= :in_date_id
--   and cl.account_id in (select account_id from dwh.d_account where trading_firm_id = 'baml')
  and cl.exchange_id in ('ARCAML',
                         'BATSML',
                         'BATYML',
                         'EDGAML',
                         'EDGXML',
                         'EPRLML',
                         'IEXML',
                         'LTSEML',
                         'MEMXML',
                         'NQBXML',
                         'NSDQML',
                         'NSXML',
                         'NYSEML',
                         'XASEML',
                         'XCHIML',
                         'XPSXML')
--   and di.instrument_type_id = 'E'
    limit 1


case when str.Order_Type_id = '1' then 'Y'
        when str.Side  = '1' and str.Price >= exch_md.ask_price then 'Y'
        when str.Side <> '1' and str.Price <= exch_md.bid_price then 'Y'
        else 'N'
      end as Is_Marketable,

ac.trading_firm_id in ('baml')
select * from d_target_strategy
where d_target_strategy.target_strategy_desc ilike 'SENSOR%'

select * from dwh.d_exchange
where exchange_id in ('ARCAML',
'BATSML',
'BATYML',
'EDGAML',
'EDGXML',
'EPRLML',
'IEXML',
'LTSEML',
'MEMXML',
'NQBXML',
'NSDQML',
'NSXML',
'NYSEML',
'XASEML',
'XCHIML',
'XPSXML')
and instrument_type_id = 'E'

select * from d_routing_table