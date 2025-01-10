with cl_id as (select 'AAC4751-20240802:VERITION' as client_order_id)

select c.client_order_id
     , i.display_instrument_id2        as security
     , c.ratio_qty                     as ratio
     , y.side
     , c.price                         as client_limit
     , y.wave_no                       as wave
     , y.routed_time                   as time
     , y.order_price                   as order_px
     , y.day_avg_px                    as fill_px
     , y.order_qty                     as route_qty
     , y.day_cum_qty                   as fill_qty
     , y.real_exchange_id              as exchange
     , l.bid_price                     as bid_px
     , l.ask_price                     as ask_px
     , l.bid_quantity                  as bid_qty
     , l.ask_quantity                  as ask_qty
     , y.strategy_decision_reason_code as reason_code
     , y.instrument_type_id            as eo
from (select parent_order_id
           , side
           , wave_no
           , routed_time
           , order_price
           , day_avg_px
           , order_qty
           , day_cum_qty
           , real_exchange_id
           , strategy_decision_reason_code
           , instrument_type_id
           , instrument_id
           , transaction_id
      from data_marts.f_yield_capture
      where status_date_id = 20240802
        and multileg_reporting_type = '2'
        and parent_order_id is not null
        and wave_no is not null
        and real_exchange_id is not null) y
         inner join (select cl.order_id
                          , cl.client_order_id
                          , cl.ratio_qty
                          , cl.price
                     from dwh.client_order cl
                              inner join cl_id
                                         on cl.create_date_id = 20240802
                                             and cl.client_order_id = cl_id.client_order_id
                                             and cross_order_id is null) c
                    on y.parent_order_id = c.order_id
         left join dwh.d_instrument i
                   on y.instrument_id = i.instrument_id
         left join lateral (
    select ls.bid_price
         , ls.ask_price
         , ls.bid_quantity
         , ls.ask_quantity
    from dwh.l1_snapshot ls
    where ls.start_date_id = 20240802
      and ls.exchange_id = 'NBBO'
      and y.transaction_id = ls.transaction_id
    limit 1
    ) l
                   on true;

select *
from data_marts.f_yield_capture yc
join dwh.client_order cl on yc.parent_order_id = cl.order_id
join dwh.d_instrument di
                   on yc.instrument_id = di.instrument_id
left join lateral (
    select ls.bid_price
         , ls.ask_price
         , ls.bid_quantity
         , ls.ask_quantity
    from dwh.l1_snapshot ls
    where ls.start_date_id = 20240802
      and ls.exchange_id = 'NBBO'
      and yc.transaction_id = ls.transaction_id
    limit 1
    ) l
where
'AAC4751-20240802:VERITION';


select *--ex.*
from trash.ob_collect_root_order_tree_but_street_topo_sorted(317968166) co
         JOIN LATERAL ( SELECT e.exec_id, e.exec_date_id, e.exec_time, e.fix_message_id
                        FROM dwh.execution e
                        WHERE e.order_id = co.order_id
                          AND e.exec_date_id >= co.create_date_id
                          AND e.exec_type != 'D'
                          AND e.exec_time >= co.create_time - INTERVAL '2 seconds'
                          AND e.fix_message_id IS NOT NULL ) AS ex ON true
         LEFT JOIN LATERAL ( SELECT fmj.fix_message
                             FROM fix_capture.fix_message_json fmj
                             WHERE fmj.fix_message_id = ex.fix_message_id
                               AND fmj.date_id = ex.exec_date_id
                               and fmj.date_id >= co.create_date_id) AS fmj ON true