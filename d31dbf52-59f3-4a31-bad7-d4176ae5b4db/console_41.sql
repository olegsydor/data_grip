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

SELECT exec_time, routed_time, status_date_id, transaction_id, order_id, client_order_id, multileg_reporting_type, tif_name, order_type_name, order_price, day_order_qty, day_cum_qty, day_avg_px, side, client_id, account_name, is_marketable, cross_order_id, sec_type_id, display_instrument_id, last_trade_date, sub_strategy, num_exch, nbbo_bid_price, nbbo_bid_quantity, nbbo_ask_price, nbbo_ask_quantity, parent_order_id, wave_no, first_wave_nbbo_bid_px, last_wave_nbbo_bid_px, first_wave_nbbo_ask_px, last_wave_nbbo_ask_px, first_wave_nbbo_bid_qty, last_wave_nbbo_bid_qty, first_wave_nbbo_ask_qty, last_wave_nbbo_ask_qty, "?column?"
FROM trash.so_fyc_perf_new
except
SELECT exec_time, routed_time, status_date_id, transaction_id, order_id, client_order_id, multileg_reporting_type, tif_name, order_type_name, order_price, day_order_qty, day_cum_qty, day_avg_px, side, client_id, account_name, is_marketable, cross_order_id, sec_type_id, display_instrument_id, last_trade_date, sub_strategy, num_exch, nbbo_bid_price, nbbo_bid_quantity, nbbo_ask_price, nbbo_ask_quantity, parent_order_id, wave_no, first_wave_nbbo_bid_px, last_wave_nbbo_bid_px, first_wave_nbbo_ask_px, last_wave_nbbo_ask_px, first_wave_nbbo_bid_qty, last_wave_nbbo_bid_qty, first_wave_nbbo_ask_qty, last_wave_nbbo_ask_qty, "?column?"
FROM trash.so_fyc_perf
except
SELECT exec_time, routed_time, status_date_id, transaction_id, order_id, client_order_id, multileg_reporting_type, tif_name, order_type_name, order_price, day_order_qty, day_cum_qty, day_avg_px, side, client_id, account_name, is_marketable, cross_order_id, sec_type_id, display_instrument_id, last_trade_date, sub_strategy, num_exch, nbbo_bid_price, nbbo_bid_quantity, nbbo_ask_price, nbbo_ask_quantity, parent_order_id, wave_no, first_wave_nbbo_bid_px, last_wave_nbbo_bid_px, first_wave_nbbo_ask_px, last_wave_nbbo_ask_px, first_wave_nbbo_bid_qty, last_wave_nbbo_bid_qty, first_wave_nbbo_ask_qty, last_wave_nbbo_ask_qty, "?column?"
FROM trash.so_fyc_perf_new



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
                 join lateral ( select first_value(fyc.wave_no) over w                 as wave_no_first,
                                       last_value(fyc.wave_no) over w                  as wave_no_last,

                                       first_value(fyc.multileg_reporting_type) over w as multileg_reporting_type_first,
                                       last_value(fyc.multileg_reporting_type) over w  as multileg_reporting_type_last,

                                       first_value(fyc.transaction_id) over w          as transaction_id_first,
                                       last_value(fyc.transaction_id) over w           as transaction_id_last,

                                       first_value(fyc.status_date_id) over w          as status_date_id_first,
                                       last_value(fyc.status_date_id) over w           as status_date_id_last,

                                       first_value(fyc.instrument_id) over w           as instrument_id_first,
                                       last_value(fyc.instrument_id) over w            as instrument_id_last

                                from data_marts.f_yield_capture fyc
                                where fyc.parent_order_id = po.order_id
                                  and fyc.parent_order_id is not null
                                  and fyc.status_date_id >= :start_status_date_id
                                window w as (partition by parent_order_id order by wave_no)
                                order by wave_no desc
                                limit 1
            ) mx on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = transaction_id_first
                                      and ls.exchange_id = 'NBBO'
                                      and ls.start_date_id = status_date_id_first--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) min_wave on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
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
select *,
       (dwh.get_routing_market_data(in_transaction_id := fyc.transaction_id,
                                                                         in_exchange_id := 'NBBO',
                                                                         in_multileg_reporting_type := fyc.multileg_reporting_type,
                                                                         in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                                 in_order_id := fyc.parent_order_id,
                                                                                 in_multileg_reporting_type := fyc.multileg_reporting_type),
                                                                         in_date_id := fyc.status_date_id)).*
from trash.so_fyc_perf fyc
where multileg_reporting_type <> '1';

------------------------------------------------------------------------------------------------------------------------
drop table if exists t_report;
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
               po.nbbo_bid_price,
               po.nbbo_bid_quantity,      -- 25
               po.nbbo_ask_price,
               po.nbbo_ask_quantity,
               mx.*
        from data_marts.f_yield_capture po
                 inner join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
                 inner join dwh.d_order_type ot on ot.order_type_id = po.order_type_id
                 inner join dwh.d_instrument i on i.instrument_id = po.instrument_id
                 left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
                 inner join data_marts.d_account acc on (acc.account_id = po.account_id)
                 join lateral ( select --first_value(fyc.wave_no) over w                 as wave_no_first,
                                       last_value(fyc.wave_no) over w                  as wave_no_last,

                                       first_value(fyc.multileg_reporting_type) over w as multileg_reporting_type_first,
                                       last_value(fyc.multileg_reporting_type) over w  as multileg_reporting_type_last,

                                       first_value(fyc.transaction_id) over w          as transaction_id_first,
                                       last_value(fyc.transaction_id) over w           as transaction_id_last,

                                       first_value(fyc.status_date_id) over w          as status_date_id_first,
                                       last_value(fyc.status_date_id) over w           as status_date_id_last,

                                       first_value(fyc.instrument_id) over w           as instrument_id_first,
                                       last_value(fyc.instrument_id) over w            as instrument_id_last

                                from data_marts.f_yield_capture fyc
                                where fyc.parent_order_id = po.order_id
                                  and fyc.parent_order_id is not null
                                  and fyc.status_date_id >= :start_status_date_id
                                window w as (partition by parent_order_id order by wave_no)
                                order by wave_no desc
                                limit 1
            ) mx on true
        where po.parent_order_id is null
          and po.status_date_id >= :start_status_date_id
          and po.status_date_id <= :end_status_date_id
          and po.multileg_reporting_type in ('1', '2')
          and po.instrument_type_id = :in_instrument_type_id
          and po.TIME_IN_FORCE_id IN ('0', '2', '3', '4')
          and po.account_id in
              (24993, 19676, 52064, 36679, 52101, 51465, 51464, 63695, 52061, 52062, 52066, 52067, 52063, 36680, 36675,
               36681, 52065, 58770, 70279, 19681, 19634);

select po.exec_time,
       po.routed_time,
       po.status_date_id,
       po.transaction_id,
       po.order_id,                                                                                 -- 5
       po.client_order_id,
       po.multileg_reporting_type,
       po.tif_name,
       po.order_type_name,
       po.order_price,                                                                              -- 10
       po.day_order_qty,
       po.day_cum_qty,
       po.day_avg_px,
       po.side,
       po.client_id,                                                                                -- 15
       po.account_name,
       po.is_marketable,
       po.cross_order_id,
       po.sec_type_id,
       po.display_instrument_id,                                                                    -- 20
       po.last_trade_date,
       po.sub_strategy,
       po.num_exch,
       coalesce(po.nbbo_bid_price, case
                                       when po.multileg_reporting_type_first = '1' then min_wave.bid_price
                                       else min_wave_2.bid_price end)       nbbo_bid_price,
       coalesce(po.nbbo_bid_quantity, case
                                          when po.multileg_reporting_type_first = '1' then min_wave.bid_qty
                                          else min_wave_2.bid_qty end)::int nbbo_bid_quantity,      -- 25
       coalesce(po.nbbo_ask_price, case
                                       when po.multileg_reporting_type_first = '1' then min_wave.ask_price
                                       else min_wave_2.ask_price end)       nbbo_ask_price,
       coalesce(po.nbbo_ask_quantity, case
                                          when po.multileg_reporting_type_first = '1' then min_wave.ask_qty
                                          else min_wave_2.ask_qty end)::int nbbo_ask_quantity,
       po.order_id     as                                                   parent_order_id_of_street,
       po.wave_no_last as                                                   wave_no,
       case
           when po.multileg_reporting_type_first = '1' then min_wave.bid_price
           else min_wave_2.bid_price end                                    first_wave_nbbo_bid_px, -- 30
       case
           when po.multileg_reporting_type_last = '1' then max_wave.bid_price
           else max_wave_2.bid_price end                                    last_wave_nbbo_bid_px,
       case
           when po.multileg_reporting_type_first = '1' then min_wave.ask_price
           else min_wave_2.ask_price end                                    first_wave_nbbo_ask_px,
       case
           when po.multileg_reporting_type_last = '1' then max_wave.ask_price
           else max_wave_2.ask_price end                                    last_wave_nbbo_ask_px,
       case
           when po.multileg_reporting_type_first = '1' then min_wave.bid_qty
           else min_wave_2.bid_qty end                                      first_wave_nbbo_bid_qty,
       case
           when po.multileg_reporting_type_last = '1' then max_wave.bid_qty
           else max_wave_2.bid_qty end                                      last_wave_nbbo_bid_qty, -- 35
       case
           when po.multileg_reporting_type_first = '1' then min_wave.ask_qty
           else min_wave_2.ask_qty end                                      first_wave_nbbo_ask_qty,
       case
           when po.multileg_reporting_type_last = '1' then max_wave.ask_qty
           else max_wave_2.ask_qty end                                      last_wave_nbbo_ask_qty
from t_report po
         left join lateral (select ls.ask_price,
                                   ls.bid_price,
                                   ls.ask_quantity as ask_qty,
                                   ls.bid_quantity as bid_qty
                            from dwh.l1_snapshot ls
                            where ls.transaction_id = transaction_id_first
                              and ls.exchange_id = 'NBBO'
                              and ls.start_date_id = status_date_id_first--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                              and po.multileg_reporting_type_first = '1'
                            limit 1
    ) min_wave on true
         left join lateral (select ls.ask_price,
                                   ls.bid_price,
                                   ls.ask_quantity as ask_qty,
                                   ls.bid_quantity as bid_qty
                            from dwh.l1_snapshot ls
                            where ls.transaction_id = transaction_id_last
                              and ls.exchange_id = 'NBBO'
                              and ls.start_date_id = status_date_id_last--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                              and po.multileg_reporting_type_first = '1'
                            limit 1
    ) max_wave on true
         left join lateral (select ask_price,
                                   bid_price,
                                   ask_qty,
                                   bid_qty
                            from dwh.get_routing_market_data(in_transaction_id := transaction_id_first,
                                                             in_exchange_id := 'NBBO',
                                                             in_multileg_reporting_type := '2',
                                                             in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                     in_order_id := po.order_id,
                                                                     in_multileg_reporting_type := '2'),
                                                             in_date_id := status_date_id_first)
                            where po.multileg_reporting_type_first = '2'
                            limit 1) min_wave_2 on true
         left join lateral (select ask_price,
                                   bid_price,
                                   ask_qty,
                                   bid_qty
                            from dwh.get_routing_market_data(in_transaction_id := transaction_id_last,
                                                             in_exchange_id := 'NBBO',
                                                             in_multileg_reporting_type := '2',
                                                             in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                     in_order_id := po.order_id,
                                                                     in_multileg_reporting_type := '2'),
                                                             in_date_id := status_date_id_last)
                            where po.multileg_reporting_type_last = '2'
                            limit 1) max_wave_2 on true;



select po.*
from data_marts.f_yield_capture po
         inner join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
         inner join dwh.d_order_type ot on ot.order_type_id = po.order_type_id
         inner join dwh.d_instrument i on i.instrument_id = po.instrument_id
         left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
         inner join data_marts.d_account acc on (acc.account_id = po.account_id)
         join lateral ( select first_value(fyc.wave_no) over w                 as wave_no_first,
                               last_value(fyc.wave_no) over w                  as wave_no_last,

                               first_value(fyc.multileg_reporting_type) over w as multileg_reporting_type_first,
                               last_value(fyc.multileg_reporting_type) over w  as multileg_reporting_type_last,

                               first_value(fyc.transaction_id) over w          as transaction_id_first,
                               last_value(fyc.transaction_id) over w           as transaction_id_last,

                               first_value(fyc.status_date_id) over w          as status_date_id_first,
                               last_value(fyc.status_date_id) over w           as status_date_id_last,

                               first_value(fyc.instrument_id) over w           as instrument_id_first,
                               last_value(fyc.instrument_id) over w            as instrument_id_last

                        from data_marts.f_yield_capture fyc
                        where fyc.parent_order_id = po.order_id
                          and fyc.parent_order_id is not null
                          and fyc.status_date_id >= :start_status_date_id
                        window w as (partition by parent_order_id order by wave_no)
                        order by wave_no desc
                        limit 1
    ) mx on true
         left join lateral (select ls.ask_price,
                                   ls.bid_price,
                                   ls.ask_quantity as ask_qty,
                                   ls.bid_quantity as bid_qty
                            from dwh.l1_snapshot ls
                            where ls.transaction_id = transaction_id_first
                              and ls.exchange_id = 'NBBO'
                              and ls.start_date_id = status_date_id_first--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                              and mx.multileg_reporting_type_first = '1'
                            limit 1
    ) min_wave on true
         left join lateral (select ls.ask_price,
                                   ls.bid_price,
                                   ls.ask_quantity as ask_qty,
                                   ls.bid_quantity as bid_qty
                            from dwh.l1_snapshot ls
                            where ls.transaction_id = transaction_id_last
                              and ls.exchange_id = 'NBBO'
                              and ls.start_date_id = status_date_id_last--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                              and mx.multileg_reporting_type_first = '1'
                            limit 1
    ) max_wave on true
--          left join lateral (select ask_price,
--                                    bid_price,
--                                    ask_qty,
--                                    bid_qty
--                             from dwh.get_routing_market_data(in_transaction_id := transaction_id_first,
--                                                              in_exchange_id := 'NBBO',
--                                                              in_multileg_reporting_type := '2',
--                                                              in_instrument_id := dwh.get_multileg_head_instrument_id(
--                                                                      in_order_id := po.order_id,
--                                                                      in_multileg_reporting_type := '2'),
--                                                              in_date_id := status_date_id_first)
--                             where mx.multileg_reporting_type_first = '2'
--                             limit 1) min_wave_2 on true
--          left join lateral (select ask_price,
--                                    bid_price,
--                                    ask_qty,
--                                    bid_qty
--                             from dwh.get_routing_market_data(in_transaction_id := transaction_id_last,
--                                                              in_exchange_id := 'NBBO',
--                                                              in_multileg_reporting_type := '2',
--                                                              in_instrument_id := dwh.get_multileg_head_instrument_id(
--                                                                      in_order_id := po.order_id,
--                                                                      in_multileg_reporting_type := '2'),
--                                                              in_date_id := status_date_id_last)
--                             where mx.multileg_reporting_type_last = '2'
--                             limit 1) max_wave_2 on true
        where po.parent_order_id is null
          and po.status_date_id >= :start_status_date_id
          and po.status_date_id <= :end_status_date_id
          and po.multileg_reporting_type in ('1', '2')
          and po.instrument_type_id = :in_instrument_type_id
          and po.TIME_IN_FORCE_id IN ('0', '2', '3', '4')
          and po.account_id in
              (24993, 19676, 52064, 36679, 52101, 51465, 51464, 63695, 52061, 52062, 52066, 52067, 52063, 36680, 36675,
               36681, 52065, 58770, 70279, 19681, 19634);



CREATE or replace FUNCTION trash.so_dash360_report_parent_order_metrics(account_ids bigint[] DEFAULT '{}'::bigint[],
                                                          instrument_type_id character varying DEFAULT NULL::character varying(1),
                                                          start_status_date_id integer DEFAULT NULL::integer,
                                                          end_status_date_id integer DEFAULT NULL::integer,
                                                          is_demo character DEFAULT 'N'::bpchar)
    RETURNS TABLE
            (
                exec_time               timestamp without time zone,
                routed_time             timestamp without time zone,
                status_date_id          integer,
                transaction_id          bigint,
                order_id                bigint,
                client_order_id         character varying,
                multileg_reporting_type character,
                tif_name                character varying,
                order_type_name         character varying,
                order_price             numeric,
                day_order_qty           integer,
                day_cum_qty             integer,
                day_avg_px              numeric,
                side                    character,
                client_id               character varying,
                account_name            character varying,
                is_marketable           character,
                cross_order_id          integer,
                sec_type_id             character,
                display_instrument_id   character varying,
                last_trade_date         timestamp without time zone,
                sub_strategy            character varying,
                num_exch                smallint,
                nbbo_bid_price          numeric,
                nbbo_bid_quantity       integer,
                nbbo_ask_price          numeric,
                nbbo_ask_quantity       integer,
                parent_order_id         bigint,
                wave_no                 smallint,
                first_wave_nbbo_bid_px  numeric,
                last_wave_nbbo_bid_px   numeric,
                first_wave_nbbo_ask_px  numeric,
                last_wave_nbbo_ask_px   numeric,
                first_wave_nbbo_bid_qty bigint,
                last_wave_nbbo_bid_qty  bigint,
                first_wave_nbbo_ask_qty bigint,
                last_wave_nbbo_ask_qty  bigint,
                rn                      integer
            )
    LANGUAGE plpgsql
AS
$fn$

declare
    in_instrument_type_id char := $2;
begin

    create temp table t_report on commit drop as
    select po.exec_time,
           po.routed_time,
           po.status_date_id,
           po.transaction_id,
           po.order_id,             -- 5
           po.client_order_id,
           po.multileg_reporting_type,
           tif.tif_name,
           ot.order_type_name,
           po.order_price,          -- 10
           po.day_order_qty,
           po.day_cum_qty,
           po.day_avg_px,
           po.side,
           po.client_id,            -- 15
           acc.account_name,
           po.is_marketable,
           po.cross_order_id,
           po.instrument_type_id    as sec_type_id,
           i.display_instrument_id, -- 20
           i.last_trade_date,
           dss.target_strategy_name as sub_strategy,
           po.num_exch,
           po.nbbo_bid_price,
           po.nbbo_bid_quantity,    -- 25
           po.nbbo_ask_price,
           po.nbbo_ask_quantity,
           mx.*
    from data_marts.f_yield_capture po
             inner join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
             inner join dwh.d_order_type ot on ot.order_type_id = po.order_type_id
             inner join dwh.d_instrument i on i.instrument_id = po.instrument_id
             left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
             inner join data_marts.d_account acc on (acc.account_id = po.account_id)
             join lateral ( select --first_value(fyc.wave_no) over w                 as wave_no_first,
                                   last_value(fyc.wave_no) over w                  as wave_no_last,

                                   first_value(fyc.multileg_reporting_type) over w as multileg_reporting_type_first,
                                   last_value(fyc.multileg_reporting_type) over w  as multileg_reporting_type_last,

                                   first_value(fyc.transaction_id) over w          as transaction_id_first,
                                   last_value(fyc.transaction_id) over w           as transaction_id_last,

                                   first_value(fyc.status_date_id) over w          as status_date_id_first,
                                   last_value(fyc.status_date_id) over w           as status_date_id_last,

                                   first_value(fyc.instrument_id) over w           as instrument_id_first,
                                   last_value(fyc.instrument_id) over w            as instrument_id_last

                            from data_marts.f_yield_capture fyc
                            where fyc.parent_order_id = po.order_id
                              and fyc.parent_order_id is not null
                              and fyc.status_date_id >= start_status_date_id
                              and fyc.status_date_id <= end_status_date_id
                            window w as (partition by fyc.parent_order_id order by fyc.wave_no)
                            order by fyc.wave_no desc
                            limit 1
        ) mx on true
    where po.parent_order_id is null
      and po.status_date_id >= start_status_date_id
      and po.status_date_id <= end_status_date_id
      and po.multileg_reporting_type in ('1', '2')
      and po.instrument_type_id = in_instrument_type_id
      and po.TIME_IN_FORCE_id IN ('0', '2', '3', '4')
      and po.account_id = any (account_ids);

    return query
        select po.exec_time,
               po.routed_time,
               po.status_date_id,
               po.transaction_id,
               po.order_id,                                                          -- 5
               po.client_order_id,
               po.multileg_reporting_type,
               po.tif_name,
               po.order_type_name,
               po.order_price,                                                       -- 10
               po.day_order_qty,
               po.day_cum_qty,
               po.day_avg_px,
               po.side,
               po.client_id,                                                         -- 15
               po.account_name,
               po.is_marketable,
               po.cross_order_id,
               po.sec_type_id,
               po.display_instrument_id,                                             -- 20
               po.last_trade_date,
               po.sub_strategy,
               po.num_exch,
               coalesce(po.nbbo_bid_price, case
                                               when po.multileg_reporting_type_first = '1' then min_wave.bid_price
                                               else min_wave_2.bid_price end),       --       nbbo_bid_price
               coalesce(po.nbbo_bid_quantity, case
                                                  when po.multileg_reporting_type_first = '1' then min_wave.bid_qty
                                                  else min_wave_2.bid_qty end)::int, -- nbbo_bid_quantity      -- 25
               coalesce(po.nbbo_ask_price, case
                                               when po.multileg_reporting_type_first = '1' then min_wave.ask_price
                                               else min_wave_2.ask_price end),       --       nbbo_ask_price
               coalesce(po.nbbo_ask_quantity, case
                                                  when po.multileg_reporting_type_first = '1' then min_wave.ask_qty
                                                  else min_wave_2.ask_qty end)::int, -- nbbo_ask_quantity
               po.order_id,                                                          -- parent_order_id
               po.wave_no_last,                                                      -- wave_no,
               case
                   when po.multileg_reporting_type_first = '1' then min_wave.bid_price
                   else min_wave_2.bid_price end,                                    -- first_wave_nbbo_bid_px -- 30
               case
                   when po.multileg_reporting_type_last = '1' then max_wave.bid_price
                   else max_wave_2.bid_price end,                                    -- last_wave_nbbo_bid_px
               case
                   when po.multileg_reporting_type_first = '1' then min_wave.ask_price
                   else min_wave_2.ask_price end,                                    -- first_wave_nbbo_ask_px,
               case
                   when po.multileg_reporting_type_last = '1' then max_wave.ask_price
                   else max_wave_2.ask_price end,                                    -- last_wave_nbbo_ask_px
               case
                   when po.multileg_reporting_type_first = '1' then min_wave.bid_qty
                   else min_wave_2.bid_qty end,                                      -- first_wave_nbbo_bid_qty,
               case
                   when po.multileg_reporting_type_last = '1' then max_wave.bid_qty
                   else max_wave_2.bid_qty end,                                      -- last_wave_nbbo_bid_qty, -- 35
               case
                   when po.multileg_reporting_type_first = '1' then min_wave.ask_qty
                   else min_wave_2.ask_qty end,                                      -- first_wave_nbbo_ask_qty,
               case
                   when po.multileg_reporting_type_last = '1' then max_wave.ask_qty
                   else max_wave_2.ask_qty end,                                      -- last_wave_nbbo_ask_qty,
               1
        from t_report po
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = transaction_id_first
                                      and ls.exchange_id = 'NBBO'
                                      and ls.start_date_id = status_date_id_first--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      and po.multileg_reporting_type_first = '1'
                                    limit 1
            ) min_wave on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = transaction_id_last
                                      and ls.exchange_id = 'NBBO'
                                      and ls.start_date_id = status_date_id_last--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      and po.multileg_reporting_type_first = '1'
                                    limit 1
            ) max_wave on true
                 left join lateral (select ask_price,
                                           bid_price,
                                           ask_qty,
                                           bid_qty
                                    from dwh.get_routing_market_data(in_transaction_id := transaction_id_first,
                                                                     in_exchange_id := 'NBBO',
                                                                     in_multileg_reporting_type := '2',
                                                                     in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                             in_order_id := po.order_id,
                                                                             in_multileg_reporting_type := '2'),
                                                                     in_date_id := status_date_id_first)
                                    where po.multileg_reporting_type_first = '2'
                                    limit 1) min_wave_2 on true
                 left join lateral (select ask_price,
                                           bid_price,
                                           ask_qty,
                                           bid_qty
                                    from dwh.get_routing_market_data(in_transaction_id := transaction_id_last,
                                                                     in_exchange_id := 'NBBO',
                                                                     in_multileg_reporting_type := '2',
                                                                     in_instrument_id := dwh.get_multileg_head_instrument_id(
                                                                             in_order_id := po.order_id,
                                                                             in_multileg_reporting_type := '2'),
                                                                     in_date_id := status_date_id_last)
                                    where po.multileg_reporting_type_last = '2'
                                    limit 1) max_wave_2 on true
        order by po.exec_time;
end;
$fn$;


select *
into trash.so_fyc_report_new
from trash.so_dash360_report_parent_order_metrics(start_status_date_id=>20231002,
                                                  end_status_date_id=>20231006,
                                                  account_ids=>array [24993,19676,52064,36679,52101,51465,51464,63695,52061,52062,52066,52067,52063,36680,36675,36681,52065,58770,70279,19681,19634],
                                                  instrument_type_id=>'O');


select *
into trash.so_fyc_report_old
from dash360.dash360_report_parent_order_metrics(start_status_date_id=>20231002,
                                                  end_status_date_id=>20231006,
                                                  account_ids=>array [24993,19676,52064,36679,52101,51465,51464,63695,52061,52062,52066,52067,52063,36680,36675,36681,52065,58770,70279,19681,19634],
                                                  instrument_type_id=>'O');
