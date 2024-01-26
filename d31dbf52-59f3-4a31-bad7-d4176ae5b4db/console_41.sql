create temp table t_old as
select po.exec_time,
               po.routed_time,
               po.status_date_id,
               po.transaction_id,
               po.order_id,                                                                  -- 5
               po.client_order_id,
               po.multileg_reporting_type,
               tif.tif_name,
               ot.order_type_name,
               po.order_price,                                                               -- 10
               po.day_order_qty,
               po.day_cum_qty,
               po.day_avg_px,
               po.side,
               po.client_id,                                                                 -- 15
               acc.account_name,
               po.is_marketable,
               po.cross_order_id,
               po.instrument_type_id    as                           sec_type_id,
               i.display_instrument_id,                                                      -- 20
               i.last_trade_date,
               dss.target_strategy_name as                           sub_strategy,
               po.num_exch,
               coalesce(po.nbbo_bid_price, min_wave.bid_price)       nbbo_bid_price,
               coalesce(po.nbbo_bid_quantity, min_wave.bid_qty)::int nbbo_bid_quantity,      -- 25
               coalesce(po.nbbo_ask_price, min_wave.ask_price)       nbbo_ask_price,
               coalesce(po.nbbo_ask_quantity, min_wave.ask_qty)::int nbbo_ask_quantity,
               min_wave.parent_order_id,
               max_wave.wave_no,
               min_wave.bid_price                                    first_wave_nbbo_bid_px, -- 30
               max_wave.bid_price                                    last_wave_nbbo_bid_px,
               min_wave.ask_price                                    first_wave_nbbo_ask_px,
               max_wave.ask_price                                    last_wave_nbbo_ask_px,
               min_wave.bid_qty                                      first_wave_nbbo_bid_qty,
               max_wave.bid_qty                                      last_wave_nbbo_bid_qty, -- 35
               min_wave.ask_qty                                      first_wave_nbbo_ask_qty,
               max_wave.ask_qty                                      last_wave_nbbo_ask_qty,
               1
        from data_marts.f_yield_capture po
                 inner join d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
                 inner join d_order_type ot on ot.order_type_id = po.order_type_id
                 inner join d_instrument i on i.instrument_id = po.instrument_id
                 left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
                 inner join data_marts.d_account acc on (acc.account_id = po.account_id)
                 inner join lateral (select fyc.wave_no,
                                            fyc.parent_order_id,
                                            dwh.get_multileg_head_instrument_id(in_order_id := fyc.parent_order_id,
                                                                                in_multileg_reporting_type := fyc.multileg_reporting_type),
                                            (dwh.get_routing_market_data(in_transaction_id := fyc.transaction_id,
                                                                         in_exchange_id := 'NBBO',
                                                                         in_multileg_reporting_type := fyc.multileg_reporting_type,
                                                                         in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                                 in_order_id := fyc.parent_order_id,
                                                                                 in_multileg_reporting_type := fyc.multileg_reporting_type),
                                                                         in_date_id := fyc.status_date_id)).*
                                     from data_marts.f_yield_capture fyc
                                     where fyc.parent_order_id = po.order_id
                                       and fyc.parent_order_id is not null
                                     order by fyc.wave_no
                                     limit 1) min_wave on true
                 inner join lateral (select fyc.wave_no,
                                            fyc.parent_order_id,
                                            dwh.get_multileg_head_instrument_id(in_order_id := fyc.parent_order_id,
                                                                                in_multileg_reporting_type := fyc.multileg_reporting_type),
                                            (dwh.get_routing_market_data(in_transaction_id := fyc.transaction_id,
                                                                         in_exchange_id := 'NBBO',
                                                                         in_multileg_reporting_type := fyc.multileg_reporting_type,
                                                                         in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                                 in_order_id := fyc.parent_order_id,
                                                                                 in_multileg_reporting_type := fyc.multileg_reporting_type),
                                                                         in_date_id := fyc.status_date_id)).*
                                     from data_marts.f_yield_capture fyc
                                     where fyc.parent_order_id = po.order_id
                                       and fyc.parent_order_id is not null
                                     order by fyc.wave_no desc
                                     limit 1) max_wave on true
        where po.parent_order_id is null
          and po.status_date_id >= :start_status_date_id
          and po.status_date_id <= :end_status_date_id
          and po.multileg_reporting_type in ('1', '2')
          and po.instrument_type_id = :in_instrument_type_id
          and po.TIME_IN_FORCE_id IN ('0', '2', '3', '4')
          and po.account_id in
              (24993, 19676, 52064, 36679, 52101, 51465, 51464, 63695, 52061, 52062, 52066, 52067, 52063, 36680, 36675,
               36681, 52065, 58770, 70279, 19681, 19634);


select *
-- into trash.so_fyc_perf
from t_old
where wave_no > 5;


select first_value(fyc.wave_no) over w                 as wave_no_first,
                   last_value(fyc.wave_no) over w                  as wave_no_last,

                   first_value(fyc.multileg_reporting_type) over w as multileg_reporting_type_first,
                   last_value(fyc.multileg_reporting_type) over w  as multileg_reporting_type_last,

                   first_value(fyc.transaction_id) over w          as transaction_id_first,
                   last_value(fyc.transaction_id) over w           as transaction_id_last,

                   first_value(fyc.status_date_id) over w          as status_date_id_first,
                   last_value(fyc.status_date_id) over w           as status_date_id_last,

                   first_value(fyc.instrument_id) over w          as instrument_id_first,
                   last_value(fyc.instrument_id) over w           as instrument_id_last

            from data_marts.f_yield_capture fyc
            where fyc.parent_order_id = 13275412562
              and fyc.parent_order_id is not null
              and fyc.status_date_id >= :start_status_date_id
            window w as (partition by parent_order_id order by wave_no)
order by wave_no desc limit 1


/*
select *
         into trash.so_fyc_perf_new
         from t_report
where order_id = 13272669099
*/

select * from trash.so_fyc_perf
where order_id = 13272669099;

        create temp table t_report as
        select po.exec_time,
               po.routed_time,
               po.status_date_id,
               po.transaction_id,
               po.order_id,                                                                  -- 5
               po.client_order_id,
               po.multileg_reporting_type,
               tif.tif_name,
               ot.order_type_name,
               po.order_price,                                                               -- 10
               po.day_order_qty,
               po.day_cum_qty,
               po.day_avg_px,
               po.side,
               po.client_id,                                                                 -- 15
               acc.account_name,
               po.is_marketable,
               po.cross_order_id,
               po.instrument_type_id    as                           sec_type_id,
               i.display_instrument_id,                                                      -- 20
               i.last_trade_date,
               dss.target_strategy_name as                           sub_strategy,
               po.num_exch,

               coalesce(po.nbbo_bid_price, min_wave.bid_price)       nbbo_bid_price,
               coalesce(po.nbbo_bid_quantity, min_wave.bid_qty)::int nbbo_bid_quantity,      -- 25
               coalesce(po.nbbo_ask_price, min_wave.ask_price)       nbbo_ask_price,
               coalesce(po.nbbo_ask_quantity, min_wave.ask_qty)::int nbbo_ask_quantity,
               po.order_id              as                           parent_order_id,        --??
               wave_no_last as wave_no,
               min_wave.bid_price                                    first_wave_nbbo_bid_px, -- 30
               max_wave.bid_price                                    last_wave_nbbo_bid_px,
               min_wave.ask_price                                    first_wave_nbbo_ask_px,
               max_wave.ask_price                                    last_wave_nbbo_ask_px,
               min_wave.bid_qty                                      first_wave_nbbo_bid_qty,
               max_wave.bid_qty                                      last_wave_nbbo_bid_qty, -- 35
               min_wave.ask_qty                                      first_wave_nbbo_ask_qty,
               max_wave.ask_qty                                      last_wave_nbbo_ask_qty,
               1
                ,
               mx.*
        from data_marts.f_yield_capture po
                 inner join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
                 inner join dwh.d_order_type ot on ot.order_type_id = po.order_type_id
                 inner join dwh.d_instrument i on i.instrument_id = po.instrument_id
                 left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
                 inner join data_marts.d_account acc on (acc.account_id = po.account_id)
                 left join lateral (
            select first_value(fyc.wave_no) over w                 as wave_no_first,
                   last_value(fyc.wave_no) over w                  as wave_no_last,

                   first_value(fyc.multileg_reporting_type) over w as multileg_reporting_type_first,
                   last_value(fyc.multileg_reporting_type) over w  as multileg_reporting_type_last,

                   first_value(fyc.transaction_id) over w          as transaction_id_first,
                   last_value(fyc.transaction_id) over w           as transaction_id_last,

                   first_value(fyc.status_date_id) over w          as status_date_id_first,
                   last_value(fyc.status_date_id) over w           as status_date_id_last,

                   first_value(fyc.instrument_id) over w          as instrument_id_first,
                   last_value(fyc.instrument_id) over w           as instrument_id_last

            from data_marts.f_yield_capture fyc
            where fyc.parent_order_id = po.order_id
              and fyc.parent_order_id is not null
              and fyc.status_date_id >= :start_status_date_id
            window w as (partition by parent_order_id order by wave_no)
            order by wave_no desc limit 1
            ) mx on true
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity as ask_qty, ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = transaction_id_first
                                  and ls.exchange_id = 'NBBO'
                                  and ls.start_date_id = status_date_id_first--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                limit 1
        ) min_wave on true
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity as ask_qty, ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = transaction_id_last
                                  and ls.exchange_id = 'NBBO'
                                  and ls.start_date_id = status_date_id_last--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                limit 1
        ) max_wave on true
        where po.parent_order_id is null
          and po.status_date_id >= :start_status_date_id
          and po.status_date_id <= :end_status_date_id
          and po.multileg_reporting_type in ('1', '2')
          and po.instrument_type_id = :in_instrument_type_id
          and po.TIME_IN_FORCE_id IN ('0', '2', '3', '4')
          and po.account_id in
              (24993, 19676, 52064, 36679, 52101, 51465, 51464, 63695, 52061, 52062, 52066, 52067, 52063, 36680, 36675,
               36681, 52065, 58770, 70279, 19681, 19634)
        and po.order_id = 13317023312
        order by po.exec_time;
end;
$function$
;


        select po.exec_time,
               po.routed_time,
               po.status_date_id,
               po.transaction_id,
               po.order_id,                                                                  -- 5
               po.client_order_id,
               po.multileg_reporting_type,
               tif.tif_name,
               ot.order_type_name,
               po.order_price,                                                               -- 10
               po.day_order_qty,
               po.day_cum_qty,
               po.day_avg_px,
               po.side,
               po.client_id,                                                                 -- 15
               acc.account_name,
               po.is_marketable,
               po.cross_order_id,
               po.instrument_type_id    as                           sec_type_id,
               i.display_instrument_id,                                                      -- 20
               i.last_trade_date,
               dss.target_strategy_name as                           sub_strategy,
               po.num_exch,
               coalesce(po.nbbo_bid_price, min_wave.bid_price)       nbbo_bid_price,
               coalesce(po.nbbo_bid_quantity, min_wave.bid_qty)::int nbbo_bid_quantity,      -- 25
               coalesce(po.nbbo_ask_price, min_wave.ask_price)       nbbo_ask_price,
               coalesce(po.nbbo_ask_quantity, min_wave.ask_qty)::int nbbo_ask_quantity,
               min_wave.parent_order_id,
               max_wave.wave_no,
               min_wave.bid_price                                    first_wave_nbbo_bid_px, -- 30
               max_wave.bid_price                                    last_wave_nbbo_bid_px,
               min_wave.ask_price                                    first_wave_nbbo_ask_px,
               max_wave.ask_price                                    last_wave_nbbo_ask_px,
               min_wave.bid_qty                                      first_wave_nbbo_bid_qty,
               max_wave.bid_qty                                      last_wave_nbbo_bid_qty, -- 35
               min_wave.ask_qty                                      first_wave_nbbo_ask_qty,
               max_wave.ask_qty                                      last_wave_nbbo_ask_qty,
               1
        from data_marts.f_yield_capture po
                 inner join d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
                 inner join d_order_type ot on ot.order_type_id = po.order_type_id
                 inner join d_instrument i on i.instrument_id = po.instrument_id
                 left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
                 inner join data_marts.d_account acc on (acc.account_id = po.account_id)
                 inner join lateral (select fyc.wave_no,
                                            fyc.parent_order_id,
                                            dwh.get_multileg_head_instrument_id(in_order_id := fyc.parent_order_id,
                                                                                in_multileg_reporting_type := fyc.multileg_reporting_type),
                                            (dwh.get_routing_market_data(in_transaction_id := fyc.transaction_id,
                                                                         in_exchange_id := 'NBBO',
                                                                         in_multileg_reporting_type := fyc.multileg_reporting_type,
                                                                         in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                                 in_order_id := fyc.parent_order_id,
                                                                                 in_multileg_reporting_type := fyc.multileg_reporting_type),
                                                                         in_date_id := fyc.status_date_id)).*
                                     from data_marts.f_yield_capture fyc
                                     where fyc.parent_order_id = po.order_id
                                       and fyc.parent_order_id is not null
                                     order by fyc.wave_no
                                     limit 1) min_wave on true
                 inner join lateral (select fyc.wave_no,
                                            fyc.parent_order_id,
                                            dwh.get_multileg_head_instrument_id(in_order_id := fyc.parent_order_id,
                                                                                in_multileg_reporting_type := fyc.multileg_reporting_type),
                                            (dwh.get_routing_market_data(in_transaction_id := fyc.transaction_id,
                                                                         in_exchange_id := 'NBBO',
                                                                         in_multileg_reporting_type := fyc.multileg_reporting_type,
                                                                         in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                                 in_order_id := fyc.parent_order_id,
                                                                                 in_multileg_reporting_type := fyc.multileg_reporting_type),
                                                                         in_date_id := fyc.status_date_id)).*
                                     from data_marts.f_yield_capture fyc
                                     where fyc.parent_order_id = po.order_id
                                       and fyc.parent_order_id is not null
                                     order by fyc.wave_no desc
                                     limit 1) max_wave on true
        where po.parent_order_id is null
and po.order_id = 13317023312
          and po.multileg_reporting_type in ('1', '2')
          and po.TIME_IN_FORCE_id IN ('0', '2', '3', '4')
        order by po.exec_time;

select *
     /*, (dwh.get_routing_market_data(in_transaction_id := fyc.transaction_id,
                                                                         in_exchange_id := 'NBBO',
                                                                         in_multileg_reporting_type := fyc.multileg_reporting_type,
                                                                         in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                                 in_order_id := fyc.parent_order_id,
                                                                                 in_multileg_reporting_type := fyc.multileg_reporting_type),
                                                                         in_date_id := fyc.status_date_id)).*
*/
       from t_report
       where wave_no > 1
where order_id = 13317023312


----------------------------------------------