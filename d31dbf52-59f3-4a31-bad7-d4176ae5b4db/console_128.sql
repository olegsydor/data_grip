        select po.exec_time,
               po.routed_time,
               po.status_date_id,
               po.transaction_id,
               po.order_id,
               po.client_order_id,
               po.multileg_reporting_type,
               tif.tif_name,
               ot.order_type_name,
               po.order_price,
               po.day_order_qty,
               po.day_cum_qty,
               po.day_avg_px,
               po.side,
               po.client_id,
               acc.account_name,
               po.is_marketable,
               po.cross_order_id,
               po.instrument_type_id                                                                       as sec_type_id,
               i.display_instrument_id,
               i.last_trade_date,
               dss.target_strategy_name                                                                    as sub_strategy,
               po.num_exch,
               coalesce(po.nbbo_bid_price, parent_waves.first_wave_nbbo_bid_px,
                        head_md.bid_price)                                                                 as nbbo_bid_price,
               coalesce(po.nbbo_bid_quantity, parent_waves.first_wave_nbbo_bid_qty,
                        head_md.bid_qty::int4)                                                             as nbbo_bid_quantity,
               coalesce(po.nbbo_ask_price, parent_waves.first_wave_nbbo_ask_px,
                        head_md.ask_price)                                                                 as nbbo_ask_price,
               coalesce(po.nbbo_ask_quantity, parent_waves.first_wave_nbbo_ask_qty,
                        head_md.ask_qty::int4)                                                             as nbbo_ask_quantity,
               parent_waves.parent_order_id,
               parent_waves.wave_no,
               coalesce(parent_waves.first_wave_nbbo_bid_px, head_md.bid_price)                            as first_wave_nbbo_bid_px,
               coalesce(parent_waves.last_wave_nbbo_bid_px, head_md.bid_price)                             as last_wave_nbbo_bid_px,
               coalesce(parent_waves.first_wave_nbbo_ask_px, head_md.ask_price)                            as first_wave_nbbo_ask_px,
               coalesce(parent_waves.last_wave_nbbo_ask_px, head_md.ask_price)                             as last_wave_nbbo_ask_px,
               coalesce(parent_waves.first_wave_nbbo_bid_qty::int8,
                        head_md.bid_qty)                                                                   as first_wave_nbbo_bid_qty,
               coalesce(parent_waves.last_wave_nbbo_bid_qty::int8,
                        head_md.bid_qty)                                                                   as last_wave_nbbo_bid_qty,
               coalesce(parent_waves.first_wave_nbbo_ask_qty::int8,
                        head_md.ask_qty)                                                                   as first_wave_nbbo_ask_qty,
               coalesce(parent_waves.last_wave_nbbo_ask_qty::int8,
                        head_md.ask_qty)                                                                   as last_wave_nbbo_ask_qty,
               1                                                                                           as rn
        , po.order_id,
          parent_waves.first_wave_nbbo_bid_px, head_md.bid_price
        from data_marts.f_yield_capture po
                 inner join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
                 inner join dwh.d_order_type ot on ot.order_type_id = po.order_type_id
                 inner join dwh.d_instrument i on i.instrument_id = po.instrument_id
                 left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
                 inner join dwh.d_account acc on (acc.account_id = po.account_id)
                 inner join lateral (select str.parent_order_id,
                                            last_value(str.wave_no) over w            as wave_no,
                                            first_value(str.nbbo_bid_price) over w    as first_wave_nbbo_bid_px,
                                            last_value(str.nbbo_bid_price) over w     as last_wave_nbbo_bid_px,
                                            first_value(str.nbbo_ask_price) over w    as first_wave_nbbo_ask_px,
                                            last_value(str.nbbo_ask_price) over w     as last_wave_nbbo_ask_px,
                                            first_value(str.nbbo_bid_quantity) over w as first_wave_nbbo_bid_qty,
                                            last_value(str.nbbo_bid_quantity) over w  as last_wave_nbbo_bid_qty,
                                            first_value(str.nbbo_ask_quantity) over w as first_wave_nbbo_ask_qty,
                                            last_value(str.nbbo_ask_quantity) over w  as last_wave_nbbo_ask_qty
                                     from data_marts.f_yield_capture str
                                     where str.parent_order_id = po.order_id
                                       and str.status_date_id >= :start_status_date_id
                                       and str.status_date_id <= :end_status_date_id
                                       and str.parent_order_id is not null
                                       and str.status_date_id = po.status_date_id
                                     window w as (partition by str.parent_order_id order by str.wave_no)
                                     order by str.wave_no desc
                                     limit 1
            ) parent_waves on true
                 left join lateral (select *
                                    from dwh.get_routing_market_data(in_transaction_id := po.transaction_id,
                                                                     in_exchange_id := 'NBBO',
                                                                     in_multileg_reporting_type := '3',
                                                                     in_instrument_id := 3,
                                                                     in_date_id := po.status_date_id)
                                    where po.multileg_reporting_type = '2'
                                      and num_nonnulls(parent_waves.first_wave_nbbo_bid_px,
                                                       parent_waves.first_wave_nbbo_ask_px,
                                                       parent_waves.first_wave_nbbo_bid_qty,
                                                       parent_waves.first_wave_nbbo_ask_qty) = 0
                                    limit 1
            ) head_md on true
        where po.parent_order_id is null
          and po.status_date_id >= :start_status_date_id
          and po.status_date_id <= :end_status_date_id
          and po.multileg_reporting_type in ('1', '2')
          and po.instrument_type_id = :in_instrument_type_id
          and po.time_in_force_id in ('0', '2', '3', '4')
          and po.account_id = any (:l_account_ids)
        and po.order_id in (18561901909,18561901910)
        ;


select *
from dash360.report_compliance_order_blotter_reg(
	in_start_date_id := 20250102,
	in_end_date_id := 20250102,
	in_instrument_type => 'O',
	in_account_ids := '{71361}'
);



select *
from dash360.dash360_report_parent_order_metrics(account_ids := '{71361}', instrument_type_id := 'O',
                                                 start_status_date_id := 20250102,
                                                 end_status_date_id := 20250102);


select * from order_ids_cte
where order_id in (18561901909,18561901910)