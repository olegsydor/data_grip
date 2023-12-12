select * from dash360.report_rps_surveillance_locked_markets()

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

    /* locked markets definition */
--     insert into staging.stg_rept_locked_markets (start_date_id, transaction_id, exchange_id, instrument_id, bid_price, ask_price, bid_quantity, ask_quantity, market_transact_time)
create temp table t_stg_rept_locked_markets --on commit drop
as
select md.start_date_id,
       md.transaction_id,
       md.exchange_id,
       md.instrument_id,
       md.bid_price,
       md.ask_price,
       md.bid_quantity,
       md.ask_quantity,
       md.transaction_time as market_transact_time,
       null::int8          as base_transaction_id,
       null::timestamp     as lock_start_time,
       null::interval      as duration,
       null:: int8         as real_prev_trans_id,
       null:: int8         as real_next_trans_id,
       null::int2          as is_block,
       null:: varchar(1)   as position_in_block
from dwh.l1_snapshot md
where md.start_date_id between :l_start_date_id and :l_end_date_id -- = 20171219
  --and transaction_id between 330053587947 and 330053588788
  and md.bid_price = md.ask_price
  and exchange_id = 'NBBO'
  and md.bid_price <> 0
      --and md.transaction_id > 0 -- because we can't define market_transact_time for LP traffic
    ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  create index on t_stg_rept_locked_markets using btree (market_transact_time);
  create index on t_stg_rept_locked_markets using btree (start_date_id, exchange_id, instrument_id, ask_price, bid_price);
  create index on t_stg_rept_locked_markets using btree (transaction_id);
create index on t_stg_rept_locked_markets using btree (real_next_trans_id);
create index on t_stg_rept_locked_markets using btree (position_in_block);


  select public.load_log(l_load_id, l_step_id, 'Step 1: retrieve all market locks', l_row_cnt, 'I')
   into l_step_id;

-- Step 2: look for the next and prev transactions
update t_stg_rept_locked_markets m
set real_prev_trans_id = src.real_prev_trans_id
  , real_next_trans_id = src.real_next_trans_id
  , is_block           = src.is_block
  , position_in_block  = src.position_in_block
from (select case
                 when coalesce(m.real_prev_trans_id_calc, m.real_next_trans_id_calc) is not null then 1
                 else 0 end            as is_block
           , case
                 when m.real_prev_trans_id_calc is null and m.real_next_trans_id_calc is not null
                     then 'B'
                 when m.real_prev_trans_id_calc is not null and m.real_next_trans_id_calc is not null
                     then 'M'
                 when m.real_prev_trans_id_calc is not null and m.real_next_trans_id_calc is null
                     then 'E'
        end                            as position_in_block
           , m.real_prev_trans_id_calc as real_prev_trans_id
           , m.real_next_trans_id_calc as real_next_trans_id
           , m.start_date_id
           , m.transaction_id
           , m.exchange_id
           , m.instrument_id
           , m.market_transact_time
           , m.ask_price
           , m.bid_price
      from (select case
                       when m.market_transact_time - prev_trans_time <= interval '10 second'
                           then m.prev_trans_id end as real_prev_trans_id_calc
                 , case
                       when m.next_trans_time - m.market_transact_time <= interval '10 second'
                           then m.next_trans_id end as real_next_trans_id_calc
                 , m.*
            from (select lag(m.transaction_id) over n        prev_trans_id
                       , lag(m.market_transact_time) over n  prev_trans_time
                       , lead(m.transaction_id) over n       next_trans_id
                       , lead(m.market_transact_time) over n next_trans_time
                       , m.*
                  from t_stg_rept_locked_markets m
                  window n as ( partition by m.start_date_id, m.exchange_id, m.instrument_id, m.ask_price, m.bid_price
                          order by m.market_transact_time ROWS BETWEEN 1 PRECEDING AND CURRENT ROW )) m) m) src
where src.is_block is not null
  and src.start_date_id = m.start_date_id
  and src.transaction_id = m.transaction_id
  and src.exchange_id = m.exchange_id
  and src.instrument_id = m.instrument_id
;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Step 2: look for the next and prev transactions', l_row_cnt, 'U')
   into l_step_id;

 --return;
create temp table rec_cte as
with RECURSIVE hierarch_cte/*(transaction_id, real_prev_trans_id, real_next_trans_id, is_block, position_in_block)*/ as
                   (select s.transaction_id
                         , s.real_prev_trans_id
                         , s.real_next_trans_id
                         , s.is_block
                         , s.position_in_block
                         , s.transaction_id as base_transaction_id
                         , s.start_date_id
                         , s.exchange_id
                         , s.instrument_id
                         , s.market_transact_time
                    from t_stg_rept_locked_markets s
                    where 1 = 1
                      and s.position_in_block = 'B'
                    -- and s.transaction_id in (773024618742, 743041481138, 783033581377, 783033581382)
                    --limit 100
                    union all
                    select s.transaction_id
                         , s.real_prev_trans_id
                         , s.real_next_trans_id
                         , s.is_block
                         , s.position_in_block
                         , h.base_transaction_id
                         , s.start_date_id
                         , s.exchange_id
                         , s.instrument_id
                         , s.market_transact_time
                    from hierarch_cte h
                             inner join t_stg_rept_locked_markets s
                                        ON s.transaction_id = h.real_next_trans_id)
select
--             first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time) as lock_begin
--           , first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time desc) as lock_end
--           , first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time desc) -
--             first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time) as lock_duration
--           ,
m.*
from hierarch_cte m;
create index on rec_cte (start_date_id, transaction_id, exchange_id, instrument_id)
-- Step 3: Calculation of Locked Market Duration
update t_stg_rept_locked_markets m
set base_transaction_id = src.base_transaction_id
  , duration            = src.lock_duration
  , lock_start_time     = src.lock_begin
from (select base_transaction_id
           , start_date_id
           , transaction_id
           , exchange_id
           , instrument_id
           , first_value(m.market_transact_time) over w                                             as lock_begin
           , last_value(m.market_transact_time) over w                                              as lock_end
           , last_value(m.market_transact_time) over w - first_value(m.market_transact_time) over w as lock_duration
      from rec_cte m
      window w as (partition by m.base_transaction_id order by m.market_transact_time)
         --order by m.start_date_id, m.exchange_id, m.instrument_id, m.market_transact_time
     ) src
where 1 = 1 -- and src.is_block is not null
  and src.start_date_id = m.start_date_id
  and src.transaction_id = m.transaction_id
  and src.exchange_id = m.exchange_id
  and src.instrument_id = m.instrument_id

    ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Step 3: Calculation of Locked Market Duration', l_row_cnt, 'U')
   into l_step_id;

select * into trash.t_stg_rept_locked_markets
         from t_stg_rept_locked_markets

  create index on trash.t_stg_rept_locked_markets using btree (market_transact_time);
  create index on trash.t_stg_rept_locked_markets using btree (start_date_id, exchange_id, instrument_id, ask_price, bid_price);
  create index on trash.t_stg_rept_locked_markets using btree (transaction_id);
  /* orders definition */
 create temp table t_yc as
                select m.start_date_id, m.transaction_id, m.instrument_id, m.bid_price, m.ask_price, m.bid_quantity, m.ask_quantity, m.market_transact_time
                  , m.duration, m.lock_start_time
                  , EXTRACT(EPOCH FROM y.order_end_time - m.market_transact_time) as timediff
                  , case when coalesce(y.DAY_LEAVES_QTY, -1) <> 0 then 'Cancelled' else 'Executed' end as order_state_v1
                  , case when y.Day_Cum_Qty < y.order_qty then 'Cancelled' else 'Executed' end as order_state_v2
                  --, y.*, y.exec_time,
                  , y.routed_time, y.order_end_time
                  , y.order_price, y.side, y.order_qty, y.avg_px
                  , y.order_id, y.parent_order_id, y.client_order_id, y.exchange_unq_id, y.account_id, y.instrument_type_id, y.time_in_force_id
                  , y.order_type_id
                  , to_date(status_date_id::varchar, 'YYYYMMDD') as status_date
                from trash.t_stg_rept_locked_markets m
                    left join data_marts.f_yield_capture y on (y.status_date_id  between :l_start_date_id and :l_end_date_id -- = 20171219
                        and y.status_date_id = m.start_date_id
                        and y.parent_order_id is not null -- street level
                        and y.multileg_reporting_type in ('1', '2')
                        and y.instrument_id = m.instrument_id
                        -- our orders
                        -- should be alive when lock happend
                        and y.routed_time <= m.market_transact_time
                        and y.order_end_time >= m.market_transact_time
                        -- should be with price that equal (or better then ?) to NBBO
--                         and ( (case when y.side in ('1', '3') then m.ask_price end) <= y.order_price -- buy order is marketable
--                              or
--                               (case when y.side not in ('1', '3') then m.bid_price end) >= y.order_price -- sell order is marketable
--                             )
                    and case when y.side in ('1', '3') then (m.ask_price <= y.order_price or m.bid_price >= y.order_price) else true end

                    )
--                   left join lateral
--                     (
--                       select y.status_date_id, y.DAY_LEAVES_QTY, y.Day_Cum_Qty
--                         , y.routed_time, y.order_end_time
--                         , y.order_price, y.side, y.order_qty, y.avg_px
--                         , y.order_id, y.parent_order_id, y.client_order_id, y.exchange_unq_id, y.account_id, y.instrument_type_id, y.time_in_force_id
--                         , y.order_type_id
--                       from data_marts.f_yield_capture y
--                       where y.status_date_id  between :l_start_date_id and :l_end_date_id -- = 20171219
--                         and y.status_date_id = m.start_date_id
--                         and y.parent_order_id is not null -- street level
--                         and y.multileg_reporting_type in ('1', '2')
--                         and y.instrument_id = m.instrument_id
--                         -- our orders
--                         -- should be alive when lock happend
--                         and y.routed_time <= m.market_transact_time
--                         and y.order_end_time >= m.market_transact_time
--                         -- should be with price that equal (or better then ?) to NBBO
--                         and ( (case when y.side in ('1', '3') then m.ask_price end) <= y.order_price -- buy order is marketable
--                              or
--                               (case when y.side not in ('1', '3') then m.bid_price end) >= y.order_price -- sell order is marketable
--                             )
--                     ) y ON true
                where 1=1
                  and m.transaction_id > 0;
   RETURN QUERY

    select '"Trading Firm","Account",Capacity,Ord Status,Event Date,Routed Time,Event Time,Cl Ord ID,Parent Cl Ord Id,Side,Security Type,Symbol,Price,Avg px,Ord Qty,Order Type,ex_destination,TIF,mkt_locked_time,time_diff,mkt_lock_duration,mkt_lock_start_time,mkt_data_exchange,nbbo_bid_px,nbbo_bid_size,nbbo_ask_px,nbbo_ask_size,bid_size,bid_px,ask_size,ask_px'::text as rec
    union all
    select '"'|| coalesce("Trading Firm"::text, ''::text )
      ||'","'|| coalesce("Account"::text, ''::text )
      ||'",'|| coalesce("Capacity"::text, ''::text )
      ||','|| coalesce("Ord Status"::text, ''::text )
      ||','|| coalesce("Event Date"::text, ''::text )
      ||','|| coalesce("Routed Time"::text, ''::text )
      ||','|| coalesce("Event Time"::text, ''::text )
      ||','|| coalesce("Cl Ord ID"::text, ''::text )
      ||','|| coalesce("Parent Cl Ord Id"::text, ''::text )
      ||','|| coalesce("Side"::text, ''::text )
      ||','|| coalesce("Security Type"::text, ''::text )
      ||','|| coalesce("Symbol"::text, ''::text )
      ||','|| coalesce("Price"::text, ''::text )
      ||','|| coalesce("Avg px"::text, ''::text )
      ||','|| coalesce("Ord Qty"::text, ''::text )
      ||','|| coalesce("Order Type"::text, ''::text )
      ||','|| coalesce("ex_destination"::text, ''::text )
      ||','|| coalesce("TIF"::text, ''::text )
      ||','|| coalesce("mkt_locked_time"::text, ''::text )
      ||','|| coalesce(time_diff::text, ''::text )
      ||','|| coalesce("mkt_lock_duration"::text, ''::text )
      ||','|| coalesce("mkt_lock_start_time"::text, ''::text )
      ||','|| coalesce("mkt_data_exchange"::text, ''::text )
      ||','|| coalesce("nbbo_bid_px"::text, ''::text )
      ||','|| coalesce("nbbo_bid_size"::text, ''::text )
      ||','|| coalesce("nbbo_ask_px"::text, ''::text )
      ||','|| coalesce("nbbo_ask_size"::text, ''::text )
      ||','|| coalesce("bid_size"::text, ''::text )
      ||','|| coalesce("bid_px"::text, ''::text )
      ||','|| coalesce("ask_size"::text, ''::text )
      ||','|| coalesce("ask_px"::text, ''::text ) as rec
    from
      (

    select tf.trading_firm_name as "Trading Firm"
      , acc.account_name as "Account"
      , cf.customer_or_firm_name as "Capacity" -- CustomerOrFirm, 204 tag
      , os.order_status_description as "Ord Status" -- last exec_type ? 39 tag по последнему репорту по стриту
      , to_char(o.status_date, 'YYYY-MM-DD')::varchar as "Event Date"
      , to_char(o.routed_time, 'YYYY-MM-DD HH24:MI:SS.US')::varchar as "Routed Time"
      , to_char(o.order_end_time, 'YYYY-MM-DD HH24:MI:SS.MS')::varchar as "Event Time"
      , o.client_order_id as "Cl Ord ID"
      , po.client_order_id as "Parent Cl Ord Id" -- lookup to parent
      , (case o.side
            when '1' then 'Buy'
            when '2' then 'Sell'
            when '3' then 'Buy minus'
            when '4' then 'Sell plus'
            when '5' then 'Sell short'
            when '6' then 'Sell short exempt'
            when '7' then 'Undisclosed'
            when '8' then 'Cross'
            when '9' then 'Cross short'
          end)::varchar  as "Side"
      , it.instrument_type_name as "Security Type"
      , i.display_instrument_id as "Symbol"
      , o.order_price as "Price"
      , o.avg_px as "Avg px"
      , o.order_qty as "Ord Qty"
      , ot.order_type_name as "Order Type"
      --, x.exchange_id as "ex_destination" -- (пока покажем exchange_id стрита) -- парента или стрита? возможно это exchange_id стрита? в любом случае лукап из client_order, хотя если это exchange_id стрита, то можно и напрямую
      , x.real_exchange_id as "ex_destination"
      , tif.tif_short_name as "TIF"
      , to_char(o.market_transact_time, 'YYYY-MM-DD HH24:MI:SS.MS')::varchar as "mkt_locked_time"
      , ((o.timediff::varchar || ' seconds')::interval)::varchar as time_diff
      , to_char(COALESCE(o.duration, interval '0.001 second'), 'HH24:MI:SS.MS')::varchar as "mkt_lock_duration"
      , to_char(COALESCE(o.lock_start_time, o.market_transact_time), 'YYYY-MM-DD HH24:MI:SS.MS')::varchar as "mkt_lock_start_time"
      , md.exchange_id as "mkt_data_exchange" -- что за эксчейндж ? ( наверное тот, на котором висит ордер )
      , o.bid_price as "nbbo_bid_px"
      , o.bid_quantity as "nbbo_bid_size"
      , o.ask_price as "nbbo_ask_px"
      , o.ask_quantity as "nbbo_ask_size"
      , md.bid_quantity as "bid_size"
      , md.bid_price as "bid_px"
      , md.ask_quantity as "ask_size"
      , md.ask_price as "ask_px" -- наверное эти поля тоже касаются того эксчейнджа, на котором захостился стритовый ордер
     -- , md.transaction_id
     -- , o.transaction_id - не по всем эксчейндам ордеров есть информация в L1_snapshot, шо маемо, то маемо
     -- , o.order_id
    from
      (
        select o.*
          , row_number() over (partition by o.transaction_id order by o.timediff desc, o.order_id) as cnt_on_lock
        from
          (
            select o.*
              , row_number() over (partition by o.order_id order by o.timediff desc) as rn
            from
              (
               select * from t_yc m
                order by m.market_transact_time
              ) o
          ) o
        where o.rn = 1 -- choose the longest teek for order
          and timediff > 2 -- пока что показываем все, что выше 2-х сек после лочки
      ) o
      left join dwh.d_account acc
        ON acc.account_id = o.account_id
      left join dwh.d_trading_firm tf
        ON tf.trading_firm_unq_id = acc.trading_firm_unq_id
      left join dwh.d_instrument_type it
        ON it.instrument_type_id = o.instrument_type_id
      left join dwh.d_instrument i
        ON i.instrument_id = o.instrument_id
      left join dwh.d_order_type ot
        ON ot.order_type_id = o.order_type_id
      left join dwh.d_time_in_force tif
        ON tif.tif_id = o.time_in_force_id
        and tif.is_active = true
      inner join lateral
        (
          select po.client_order_id, po.customer_or_firm_id
          from dwh.client_order po
            join data_marts.d_sub_strategy s
              ON po.sub_strategy_id = s.sub_strategy_id
          where po.order_id = o.parent_order_id
            and s.sub_strategy in ('SENSOR', 'SMOKE', 'STRIKE', 'SWEEPNCXL')
            and po.create_date_id >= :l_gtc_date_id
          limit 1
        ) po ON true
     /* left join lateral
        (
          select str.customer_or_firm_id
          from dwh.client_order str
          where str.create_date_id between l_start_date_id and l_end_date_id -- 20171219 and 20171219
            and str.order_id = o.order_id
          limit 1
        ) str ON true */
      left join dwh.d_customer_or_firm cf
        ON cf.customer_or_firm_id = po.customer_or_firm_id
      left join dwh.d_exchange x
        ON x.exchange_unq_id = o.exchange_unq_id
      left join lateral
        (
          select md.bid_price, md.ask_price, md.bid_quantity, md.ask_quantity, md.transaction_id, md.exchange_id
          from dwh.l1_snapshot md
          where md.start_date_id between :l_start_date_id and :l_end_date_id -- = 20171219
            and md.transaction_id = o.transaction_id
            and md.instrument_id = o.instrument_id
            and md.exchange_id = x.real_exchange_id --x.exchange_id
        ) md ON true
      left join lateral
        (
          select ex.order_status
          from dwh.EXECUTION ex
          where EX.ORDER_ID = o.order_id
            and ex.exec_date_id >= :l_start_date_id -- Здесь не between, а больше старт дэй
            and EX.ORDER_STATUS <> '3' -- don't show done for day
          order by ex.exec_id desc
          limit 1
        ) ex ON true
      left join dwh.d_order_status os
        ON os.order_status = ex.order_status
        and os.is_active = true
    where o.cnt_on_lock <= 20
    order by o.market_transact_time, o.timediff desc, o.order_id

      ) src
    ;
   select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_locked_markets_report_csv FINISHED SUCCESSFULLY===', 0, 'O')
   into l_step_id;

END;
$function$
;
$function$

public.load_timing()