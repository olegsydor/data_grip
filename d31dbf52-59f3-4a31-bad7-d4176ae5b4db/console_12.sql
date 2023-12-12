-- drop function external_data.report_surveillance_locked_markets(int4, int4, boolean);

drop function dash360.report_surveillance_locked_markets(int4, int4, boolean)
select * from dash360.report_surveillance_locked_markets(in_start_date_id := 20231018, in_end_date_id := 20231019);

create or replace function dash360.report_surveillance_locked_markets(in_start_date_id int4 default null,
                                                                 in_end_date_id int4 default null)
    returns table
            (
                return_row text
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
DECLARE
    l_row_cnt       integer;
    l_end_date_id   int4 := coalesce(in_end_date_id, to_char(date_trunc('week', current_date) - '1 days'::interval, 'YYYYMMDD')::int4);
    l_start_date_id int4 := coalesce(in_start_date_id, to_char(date_trunc('week', current_date) - '7 days'::interval, 'YYYYMMDD')::int4);
    l_gtc_date_id   integer;
    l_load_id       integer;
    l_step_id       integer;

begin

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

   select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_locked_markets_report_csv STARTED===', 0, 'O')
   into l_step_id;

  l_gtc_date_id := to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD') - interval '1 year'), 'YYYYMMDD')::integer;

  RAISE info 'l_start_date_id = % , l_end_date_id = % ', l_start_date_id, l_end_date_id;

  select public.load_log(l_load_id, l_step_id, 'l_start_date_id = '|| l_start_date_id::varchar ||' , l_end_date_id = '||l_end_date_id::varchar, 0, 'I')
   into l_step_id;

    /* locked markets definition */
--     insert into staging.stg_rept_locked_markets (start_date_id, transaction_id, exchange_id, instrument_id, bid_price, ask_price, bid_quantity, ask_quantity, market_transact_time)
    create temp table t_stg_rept_locked_markets on commit drop as
    select md.start_date_id, md.transaction_id, md.exchange_id, md.instrument_id, md.bid_price, md.ask_price, md.bid_quantity, md.ask_quantity, md.transaction_time as market_transact_time,
           null::int8 as base_transaction_id,
           null::timestamp as lock_start_time,
	null::interval as duration,
	null:: int8 as real_prev_trans_id,
	null:: int8 as real_next_trans_id,
	null::int2 as is_block,
	null:: varchar(1) as position_in_block
    from dwh.l1_snapshot md
    where md.start_date_id between l_start_date_id and l_end_date_id -- = 20171219
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

  select public.load_log(l_load_id, l_step_id, 'Step 1: retrieve all market locks', l_row_cnt, 'I')
   into l_step_id;

-- Step 2: look for the next and prev transactions
    update t_stg_rept_locked_markets m
      set real_prev_trans_id = src.real_prev_trans_id
        , real_next_trans_id = src.real_next_trans_id
        , is_block           = src.is_block
        , position_in_block  = src.position_in_block
    from
      (
        select case when coalesce(m.real_prev_trans_id_calc, m.real_next_trans_id_calc) is not null then 1 else 0 end as is_block
          , case when m.real_prev_trans_id_calc is null and m.real_next_trans_id_calc is not null
                  then 'B'
                 when m.real_prev_trans_id_calc is not null and m.real_next_trans_id_calc is not null
                  then 'M'
                 when m.real_prev_trans_id_calc is not null and m.real_next_trans_id_calc is null
                  then 'E'
            end as position_in_block
          , m.real_prev_trans_id_calc as real_prev_trans_id
          , m.real_next_trans_id_calc as real_next_trans_id
          , m.start_date_id
          , m.transaction_id
          , m.exchange_id
          , m.instrument_id
          , m.market_transact_time, m.ask_price, m.bid_price
        from
          (
            select case when m.market_transact_time - prev_trans_time <= interval '10 second' then m.prev_trans_id end as real_prev_trans_id_calc
              , case when m.next_trans_time - m.market_transact_time <= interval '10 second' then m.next_trans_id end as real_next_trans_id_calc
              , m.*
            from
              (
                select
                    lag(m.transaction_id) over (partition by m.start_date_id, m.exchange_id, m.instrument_id, m.ask_price, m.bid_price
                          order by m.market_transact_time ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) prev_trans_id
                  , lag(m.market_transact_time) over (partition by m.start_date_id, m.exchange_id, m.instrument_id, m.ask_price, m.bid_price
                          order by m.market_transact_time ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) prev_trans_time
                  , lead(m.transaction_id) over (partition by m.start_date_id, m.exchange_id, m.instrument_id, m.ask_price, m.bid_price
                          order by m.market_transact_time ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) next_trans_id
                  , lead(m.market_transact_time) over (partition by m.start_date_id, m.exchange_id, m.instrument_id, m.ask_price, m.bid_price
                          order by m.market_transact_time ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) next_trans_time
                  , m.*
                from t_stg_rept_locked_markets m
              ) m
          ) m

      ) src
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
    -- Step 3: Calculation of Locked Market Duration
    update t_stg_rept_locked_markets m
      set base_transaction_id = src.base_transaction_id
        , duration            = src.lock_duration
        , lock_start_time     = src.lock_begin
    from
      (
        with RECURSIVE hierarch_cte/*(transaction_id, real_prev_trans_id, real_next_trans_id, is_block, position_in_block)*/ as
          (
            select s.transaction_id, s.real_prev_trans_id, s.real_next_trans_id, s.is_block, s.position_in_block, s.transaction_id as base_transaction_id
              , s.start_date_id, s.exchange_id, s.instrument_id, s.market_transact_time
            from t_stg_rept_locked_markets s
            where 1=1 and s.position_in_block = 'B'
             -- and s.transaction_id in (773024618742, 743041481138, 783033581377, 783033581382)
            --limit 100
            union all
            select s.transaction_id, s.real_prev_trans_id, s.real_next_trans_id, s.is_block, s.position_in_block, h.base_transaction_id
              , s.start_date_id, s.exchange_id, s.instrument_id, s.market_transact_time
            from hierarch_cte h
            inner join t_stg_rept_locked_markets s
              ON s.transaction_id = h.real_next_trans_id
          )
        select first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time) as lock_begin
          , first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time desc) as lock_end
          , first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time desc) -
            first_value(m.market_transact_time) over (partition by m.base_transaction_id order by m.market_transact_time) as lock_duration
          , m.*
        from hierarch_cte m
        --order by m.start_date_id, m.exchange_id, m.instrument_id, m.market_transact_time
      ) src
    where 1=1 -- and src.is_block is not null
      and src.start_date_id = m.start_date_id
      and src.transaction_id = m.transaction_id
      and src.exchange_id = m.exchange_id
      and src.instrument_id = m.instrument_id
    ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Step 3: Calculation of Locked Market Duration', l_row_cnt, 'U')
   into l_step_id;


  /* orders definition */

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
                from t_stg_rept_locked_markets m
                  left join lateral
                    (
                      select y.status_date_id, y.DAY_LEAVES_QTY, y.Day_Cum_Qty
                        , y.routed_time, y.order_end_time
                        , y.order_price, y.side, y.order_qty, y.avg_px
                        , y.order_id, y.parent_order_id, y.client_order_id, y.exchange_unq_id, y.account_id, y.instrument_type_id, y.time_in_force_id
                        , y.order_type_id
                      from data_marts.f_yield_capture y
                      where y.status_date_id  between l_start_date_id and l_end_date_id -- = 20171219
                        and y.status_date_id = m.start_date_id
                        and y.parent_order_id is not null -- street level
                        and y.multileg_reporting_type in ('1', '2')
                        and y.instrument_id = m.instrument_id
                        -- our orders
                        -- should be alive when lock happend
                        and y.routed_time <= m.market_transact_time
                        and y.order_end_time >= m.market_transact_time
                        -- should be with price that equal (or better then ?) to NBBO
                        and ( (case when y.side in ('1', '3') then m.ask_price end) <= y.order_price -- buy order is marketable
                             or
                              (case when y.side not in ('1', '3') then m.bid_price end) >= y.order_price -- sell order is marketable
                            )
                    ) y ON true
                where 1=1
                  and m.transaction_id > 0
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
            and po.create_date_id >= l_gtc_date_id
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
          where md.start_date_id between l_start_date_id and l_end_date_id -- = 20171219
            and md.transaction_id = o.transaction_id
            and md.instrument_id = o.instrument_id
            and md.exchange_id = x.real_exchange_id --x.exchange_id
        ) md ON true
      left join lateral
        (
          select ex.order_status
          from dwh.EXECUTION ex
          where EX.ORDER_ID = o.order_id
            and ex.exec_date_id >= l_start_date_id -- Здесь не between, а больше старт дэй
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




------------------------------------------------------------------------------------
select * from dash360.surveillance_crossed_markets_report(20231012, 20231019, 5);
select * from dash360.surveillance_crossed_markets_report(20231012, 20231019);
CREATE FUNCTION dash360.surveillance_crossed_markets_report(in_start_date_id int4 default null,
                                                                 in_end_date_id int4 default null, in_limit integer DEFAULT null)
 RETURNS TABLE(return_row text)
 LANGUAGE plpgsql
AS $function$
DECLARE

	l_row_cnt       integer;

    l_end_date_id   int4 := coalesce(in_end_date_id, to_char(date_trunc('week', current_date) - '1 days'::interval, 'YYYYMMDD')::int4);
    l_start_date_id int4 := coalesce(in_start_date_id, to_char(date_trunc('week', current_date) - '7 days'::interval, 'YYYYMMDD')::int4);

   l_load_id        integer;
   l_step_id        integer;

begin

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

   select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_crossed_markets_report_csv STARTED===', 0, 'O')
   into l_step_id;


  RAISE info 'l_start_date_id = % , l_end_date_id = % ', l_start_date_id, l_end_date_id;

  select public.load_log(l_load_id, l_step_id, 'l_start_date_id = '|| l_start_date_id::varchar ||' , l_end_date_id = '||l_end_date_id::varchar, 0, 'I')
   into l_step_id;


   execute 'DROP TABLE IF EXISTS tmp_crossed_markets_report;';
   create temp table tmp_crossed_markets_report with (parallel_workers = 4) ON COMMIT drop as
   select '"'|| coalesce("Child Order Cross (Y/N)"::text, ''::text )
      ||'","'|| coalesce("Trading Firm"::text, ''::text )
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
        select s.is_mkt_cross_street::varchar as "Child Order Cross (Y/N)"
          , tf.trading_firm_name as "Trading Firm"
          , acc.account_name as "Account"
          , cof.customer_or_firm_name as "Capacity"
          , os.order_status_description as "Ord Status"
          , to_char(ex.exec_time, 'YYYY-MM-DD')::varchar as "Event Date"
          , to_char(s.process_time, 'YYYY-MM-DD HH24:MI:SS.US')::varchar as "Routed Time"
          , to_char(ex.exec_time, 'YYYY-MM-DD HH24:MI:SS.MS')::varchar as "Event Time"
          , s.client_order_id as "Cl Ord ID"
          , s.parent_client_order_id as "Parent Cl Ord Id"
          , (case s.side
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
          , s.display_instrument_id as "Symbol"
          , s.street_price as "Price"
          , ft.AVG_PX as "Avg px"
          , s.order_qty as "Ord Qty"
          , ot.order_type_name as "Order Type" -- order type стрита (если нужно, можно заменить на парентовый)
          --, x.exchange_id as "ex_destination"  -- (пока покажем exchange_id стрита)
          , x.real_exchange_id as "ex_destination"
          , tif.tif_short_name as "TIF"
          , md.exchange_id as "mkt_data_exchange"
          , s.bid_price as "nbbo_bid_px"
          , s.bid_quantity as "nbbo_bid_size"
          , s.ask_price as "nbbo_ask_px"
          , s.ask_quantity as "nbbo_ask_size"
          , md.bid_quantity as "bid_size"
          , md.bid_price as "bid_px"
          , md.ask_quantity as "ask_size"
          , md.ask_price as "ask_px" -- it looks like эти поля тоже касаются того эксчейнджа, на котором захостился стритовый ордер
          --, s.transaction_id, s.instrument_id, s.md_instrument_id
        from
          (
            select o.order_id, o.client_order_id, o.parent_order_id, o.transaction_id
              , o.create_time, o.process_time, o.order_cancel_time, o.side
              , o.price as street_price, o.order_qty
              , o.account_id, o.customer_or_firm_id, o.order_type_id, o.exchange_unq_id, o.time_in_force_id
              , o.instrument_id
                --, i.instrument_type_id, i.activ_symbol, i.display_instrument_id
                , o.instrument_type_id, o.activ_symbol, o.display_instrument_id
              --, o.*
                --, m.bid_price, m.ask_price, m.bid_quantity, m.ask_quantity, m.instrument_id as md_instrument_id
                , o.bid_price, o.ask_price, o.bid_quantity, o.ask_quantity, o.md_instrument_id
              , ( case when o.side in ('1', '3')
                  then case when o.price > o.ask_price then 'Y' else 'N' end -- buy street order crossed market
                  else case when o.price < o.bid_price then 'Y' else 'N' end -- sell street order crossed market
                  end) as is_mkt_cross_street
              --, p.*
              , o.parent_price, o.parent_client_order_id, o.parent_customer_or_firm_id
            from
              --dwh.client_order o
              --left join dwh.d_instrument i ON o.instrument_id = i.instrument_id
              --left join dwh.l1_snapshot m
              --  ON m.transaction_id = o.transaction_id
              --  and m.start_date_id = o.create_date_id
              --  and m.start_date_id between l_start_date_id and l_end_date_id
              --  and m.exchange_id = 'NBBO'
              -- lookup the parent level of prices and NBBO
              (
                --options
                select o.*
                from
                  (
                    select o.order_id, o.client_order_id, o.parent_order_id, o.transaction_id
                      , o.create_time, o.process_time, o.order_cancel_time, o.side
                      , o.price, o.order_qty
                      , o.account_id, o.customer_or_firm_id, o.order_type_id, o.exchange_unq_id, o.time_in_force_id
                      , o.instrument_id
                      , i.instrument_type_id, i.activ_symbol, i.display_instrument_id
                      , m.bid_price, m.ask_price, m.bid_quantity, m.ask_quantity, m.instrument_id as md_instrument_id
                      , p.*
                    from dwh.client_order o
                      inner join dwh.d_instrument i
                        ON o.instrument_id = i.instrument_id
                      inner join dwh.l1_snapshot m
                        ON m.transaction_id = o.transaction_id
                        and m.start_date_id = o.create_date_id
                        and m.start_date_id between l_start_date_id and l_end_date_id
                        and m.exchange_id = 'NBBO'
                        and case when m.instrument_id = -1 then true else m.instrument_id = o.instrument_id end
                      inner join lateral -- to lkp of : parent_customer_or_firm_id, parent_price
                        (
                          select p.price as parent_price, p.client_order_id as parent_client_order_id, p.customer_or_firm_id as parent_customer_or_firm_id
                            --, m.bid_price as parent_bid_price
                            --, m.ask_price as parent_ask_price
                          from dwh.client_order p
                            --left join dwh.l1_snapshot m
                            --  ON m.transaction_id = p.transaction_id
                            --  and m.start_date_id = p.create_date_id
                            --  and m.exchange_id = 'NBBO'
                          where p.order_id = o.parent_order_id
                            and p.parent_order_id is null
                            and p.create_date_id between l_start_date_id and l_end_date_id
                            and p.order_type_id = '2' -- ха, у Лимит стритовых ордеров могут быть Маркет паренты?!!!
                            and p.price is not null -- таки выбираем те стриты, у кот паренты имеют прайс(лимиты, стоп-лимиты)
                          limit 1
                        ) p on true
                      join dwh.d_exchange x
                        ON o.exchange_unq_id = x.exchange_unq_id
                    where 1=1 and i.instrument_type_id = 'O'
                      and o.create_date_id between l_start_date_id and l_end_date_id
                      and o.parent_order_id is not null
                      and o.order_type_id = '2' -- limit orders
                      and o.trans_type <> 'F' -- 35 tag, exclude cancell requests
                      and o.MULTILEG_REPORTING_TYPE IN ('1') -- 1) exclude complex orders ,'2'
                      and o.price > 0 -- workaround to exclude negative prices
                      and ( case when o.side in ('1', '3')
                          then case when o.price > m.ask_price then 'Y' else 'N' end -- buy street order crossed market
                          else case when o.price < m.bid_price then 'Y' else 'N' end -- sell street order crossed market
                          end ) = 'Y'
                      and ( coalesce(m.ask_price, 1) > 0 and coalesce(m.bid_price, 1) > 0) -- workaround: exclude the negative metadata
                      --and o.exchange_unq_id not in (select e.exchange_unq_id from dwh.d_exchange e where e.exchange_id = 'BDARK') -- 2) BDARK don't look on prices
                       and x.real_exchange_id <> 'BDARK'
                      and COALESCE(o.exec_instruction, 'N') not in ('L', 'M', 'O', 'P', 'R') -- 3) exclude Pegged orders via ExecInstructions. Peggeds are related to peculiar Exchanges
                    limit case when in_limit is not null then in_limit end
                  ) o

                union all

                --equities
                select o.*
                from
                  (
                    select o.order_id, o.client_order_id, o.parent_order_id, o.transaction_id
                      , o.create_time, o.process_time, o.order_cancel_time, o.side
                      , o.price, o.order_qty
                      , o.account_id, o.customer_or_firm_id, o.order_type_id, o.exchange_unq_id, o.time_in_force_id
                      , o.instrument_id
                      , i.instrument_type_id, i.activ_symbol, i.display_instrument_id
                      , m.bid_price, m.ask_price, m.bid_quantity, m.ask_quantity, m.instrument_id as md_instrument_id
                      , p.*
                    from dwh.client_order o
                      inner join dwh.d_instrument i
                        ON o.instrument_id = i.instrument_id
                      inner join dwh.l1_snapshot m
                        ON m.transaction_id = o.transaction_id
                        and m.start_date_id = o.create_date_id
                        and m.start_date_id between l_start_date_id and l_end_date_id
                        and m.exchange_id = 'NBBO'
                        and case when m.instrument_id = -1 then true else m.instrument_id = o.instrument_id end
                      inner join lateral -- to lkp of : parent_customer_or_firm_id, parent_price
                        (
                          select p.price as parent_price, p.client_order_id as parent_client_order_id, p.customer_or_firm_id as parent_customer_or_firm_id
                            --, m.bid_price as parent_bid_price
                            --, m.ask_price as parent_ask_price
                          from dwh.client_order p
                            --left join dwh.l1_snapshot m
                            --  ON m.transaction_id = p.transaction_id
                            --  and m.start_date_id = p.create_date_id
                            --  and m.exchange_id = 'NBBO'
                          where p.order_id = o.parent_order_id
                            and p.parent_order_id is null
                            and p.create_date_id between l_start_date_id and l_end_date_id
                            and p.order_type_id = '2' -- ха, у Лимит стритовых ордеров могут быть Маркет паренты?!!!
                            and p.price is not null -- таки выбираем те стриты, у кот паренты имеют прайс(лимиты, стоп-лимиты)
                          limit 1
                        ) p on true
                      join dwh.d_exchange x
                        ON o.exchange_unq_id = x.exchange_unq_id
                    where 1=1 and i.instrument_type_id = 'E'
                      and o.create_date_id between l_start_date_id and l_end_date_id
                      and o.parent_order_id is not null
                      and o.order_type_id = '2' -- limit orders
                      and o.trans_type <> 'F' -- 35 tag, exclude cancell requests
                      and o.MULTILEG_REPORTING_TYPE IN ('1') -- 1) exclude complex orders ,'2'
                      and o.price > 0 -- workaround to exclude negative prices
                      and ( case when o.side in ('1', '3')
                          then case when o.price > m.ask_price then 'Y' else 'N' end -- buy street order crossed market
                          else case when o.price < m.bid_price then 'Y' else 'N' end -- sell street order crossed market
                          end ) = 'Y'
                      and ( coalesce(m.ask_price, 1) > 0 and coalesce(m.bid_price, 1) > 0) -- workaround: exclude the negative metadata
                      --and o.exchange_unq_id not in (select e.exchange_unq_id from dwh.d_exchange e where e.exchange_id = 'BDARK') -- 2) BDARK don't look on prices
                       and x.real_exchange_id <> 'BDARK'
                      and COALESCE(o.exec_instruction, 'N') not in ('L', 'M', 'O', 'P', 'R') -- 3) exclude Pegged orders via ExecInstructions. Peggeds are related to peculiar Exchanges
                      and not exists -- 3) additional cases for Pegged
                        (
                          select 1 --(j.fix_message ->> '9140')::varchar as displ_instr
                          from fix_capture.fix_message_json j
                          where o.exec_instruction = 'N'
                            --and o.exchange_unq_id in (select x.exchange_unq_id from dwh.d_exchange x where x.exchange_id in ('NSDQE', 'NQBX', 'XPSX'))
                             and x.real_exchange_id in ('NSDQE', 'NQBX', 'XPSX')
                            and j.date_id between l_start_date_id and l_end_date_id
                            and j.fix_message_id = o.fix_message_id
                            and j.fix_message ->> '9140' = 'M'
                        )
                    limit case when in_limit is not null then in_limit end
                  ) o
              ) o
            where 1=1
          ) s
          left join dwh.d_account acc
            ON s.account_id = acc.account_id
          left join dwh.d_trading_firm tf
            ON acc.trading_firm_unq_id = tf.trading_firm_unq_id
          left join dwh.d_customer_or_firm cof
            ON s.parent_customer_or_firm_id = cof.customer_or_firm_id
          left join lateral
            (
              select ex.order_status, ex.exec_time
              from dwh.EXECUTION ex
              where EX.ORDER_ID = s.order_id
                and ex.exec_date_id >= l_start_date_id -- Здесь не between, а больше старт дэй
                and EX.ORDER_STATUS <> '3' -- don't show done for day
              order by ex.exec_id desc
              limit 1
            ) ex ON true
          left join dwh.d_order_status os
            ON ex.order_status = os.order_status
            and os.is_active = true
          left join dwh.d_instrument_type it
            ON it.instrument_type_id = s.instrument_type_id
          left join lateral
            ( select ft.street_order_id
                , sum(last_qty) as CUM_QTY
                , SUM (ft.LAST_QTY * ft.LAST_PX) / NULLIF(SUM (ft.LAST_QTY),0) as AVG_PX
                , min(ft.leaves_qty) as leaves_qty
              from  flat_trade_record ft
              where ft.date_id between l_start_date_id and l_end_date_id
                and ft.street_order_id = s.order_id
                and ft.is_busted='N'
              group by ft.street_order_id
            ) ft ON true
          left join dwh.d_order_type ot
            ON ot.order_type_id = s.order_type_id
          left join dwh.d_exchange x
            ON x.exchange_unq_id = s.exchange_unq_id
          left join dwh.d_time_in_force tif
            ON tif.tif_id = s.time_in_force_id
          left join lateral
            (
              select md.bid_price, md.ask_price, md.bid_quantity, md.ask_quantity, md.transaction_id, md.exchange_id
              from dwh.l1_snapshot md
              where md.start_date_id between l_start_date_id and l_end_date_id
                and md.transaction_id = s.transaction_id
                --and md.instrument_id = s.instrument_id -- может ли одна транзакция содержать в себе разные инструменты? - yes
                and md.exchange_id = x.real_exchange_id --x.exchange_id
              limit 1
            ) md ON true
      ) src
    ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Retrieve all crossed markets', l_row_cnt, 'I')
   into l_step_id;

  -- let's try via direct query, wo temp tables
   RETURN QUERY

    select '"Child Order Cross (Y/N)","Trading Firm","Account",Capacity,Ord Status,Event Date,Routed Time,Event Time,Cl Ord ID,Parent Cl Ord Id,Side,Security Type,Symbol,Price,Avg px,Ord Qty,Order Type,ex_destination,TIF,mkt_data_exchange,nbbo_bid_px,nbbo_bid_size,nbbo_ask_px,nbbo_ask_size,bid_size,bid_px,ask_size,ask_px'::text as rec
    union all
    select rec
    from tmp_crossed_markets_report
    ;

   select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_crossed_markets_report_csv FINISHED SUCCESSFULLY===', 0, 'O')
   into l_step_id;

END;
$function$
;

select * from external_data.surveillance_trade_through_report_csv(20231019::text::date)
----------------------------------------------------------------------------
select *
from dash360.surveillance_trade_through_report_csv(in_start_date_id := 20231009, in_end_date_id := 20231015)

create function dash360.surveillance_trade_through_report_csv(in_start_date_id int4 default null,
                                                              in_end_date_id int4 default null)
    returns table
            (
                return_row text
            )
    language plpgsql
    parallel safe leakproof cost 1
as
$function$
declare

    l_row_cnt       integer;
    l_end_date_id   int4 := coalesce(in_end_date_id,
                                     to_char(date_trunc('week', current_date) - '1 days'::interval, 'YYYYMMDD')::int4);
    l_start_date_id int4 := coalesce(in_start_date_id,
                                     to_char(date_trunc('week', current_date) - '7 days'::interval, 'YYYYMMDD')::int4);
    l_load_id       integer;
    l_step_id       integer;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_trade_through_report_csv STARTED===', 0,
                           'O')
    into l_step_id;

    RAISE info 'l_start_date_id = % , l_end_date_id = % ', l_start_date_id, l_end_date_id;

    select public.load_log(l_load_id, l_step_id,
                           'l_start_date_id = ' || l_start_date_id::varchar || ' , l_end_date_id = ' ||
                           l_end_date_id::varchar, 0, 'I')
    into l_step_id;

     execute 'DROP TABLE IF EXISTS tmp_stg_rept_trade_trough_prepare_match;';

     create temp table tmp_stg_rept_trade_trough_prepare_match with (parallel_workers = 8) ON COMMIT drop as
      select o.order_id, o.instrument_id, o.price, o.order_qty, o.side, o.create_time/*, o.exchange_id, x.exchange_id*/, x.real_exchange_id as exchange_id
        , m.bid_price, m.ask_price, m.bid_quantity, m.ask_quantity, m.transaction_time, m.transaction_id, m.start_date_id
        , mc.market_center_bid_price, mc.market_center_ask_price, mc.market_center_bid_quantity, mc.market_center_ask_quantity
      from dwh.client_order o
        inner join lateral
          (
            select m.transaction_id, m.start_date_id, m.instrument_id
              , m.bid_price, m.ask_price, m.bid_quantity, m.ask_quantity, m.transaction_time
            from dwh.l1_snapshot m
            where m.transaction_id = o.transaction_id
              and m.start_date_id = o.create_date_id
              and m.start_date_id between l_start_date_id and l_end_date_id -- 20211213 and 20211219 --
              and m.exchange_id = 'NBBO' ---!!!!!!!!
              -- exclude problem with lost instruments (we aren't able to catch previous snapshots)
              and m.instrument_id = o.instrument_id
              -- exclude problem when a protected bid was priced higher than a protected offer in the NMS stock or options series
              and coalesce(m.bid_price, 0) < coalesce(m.ask_price, 1)
              -- exclude problem with incorrect market data
              and coalesce(m.bid_price, m.ask_price) is not null
              limit 1
          ) m on true
        join dwh.d_exchange x
          ON o.exchange_unq_id = x.exchange_unq_id
        inner join lateral -- inner to have information about market data on the order's exchange (Market Center)
          (
            select mc.bid_price as market_center_bid_price
              , mc.ask_price as market_center_ask_price
              , mc.bid_quantity as market_center_bid_quantity
              , mc.ask_quantity as market_center_ask_quantity
            from dwh.l1_snapshot mc
            where mc.transaction_id = m.transaction_id
              and mc.start_date_id = m.start_date_id
              and mc.start_date_id between l_start_date_id and l_end_date_id -- 20211213 and 20211219 --
              and mc.exchange_id = x.real_exchange_id --x.exchange_id
            limit 1
          ) mc ON true
        -- check that 1 second ago order's exchange hasn't had NBBO status
          -- проверяем, отображал ли маркет центр доступное NBBO за секунду до trade_through
          -- так же прайс NBBO должен быть не лучше(таким же, или хужее), чем у транзакции/ордера
          /*
            т.е. нам надо вытащить все снапшоты по нашему эксчейнджу за секундный период до транзакции/ордера
            по всем найденным транзакциям вытащить NBBO-шки
            определить, что по прайсу(bid, ask - в зависимости от сайда) наш эксчейндж имел бест прайс
            и этот бест прайс был
              1) для bid-ордера, >= прайса ордера, т.е. ордер.прайс <= бест.ask.прайс
              2) для ask-ордера, <= прайса ордера, т.е. ордер.прайс >= бест.bid.прайс
           Если для найденного TradeThrough-го ордера мы находим такой снапшот, то это не совсем TradeThrough, и мы его не выводим как TradeThrough
           Как реализовать:
           not exists
             1 sec ago TC been NBBO and had price inferior to order price
          */
      where true
        -- common orders info
        and o.parent_order_id is not null -- street level
        and o.trans_type <> 'F' -- 35 tag, exclude cancell requests
        and o.price > 0 -- workaround to exclude negative prices
        -- filter: period
        and o.create_date_id between l_start_date_id and l_end_date_id -- 20211213 and 20211219 --
        -- filter: out Peggeds, intermarket sweep order, Complex orders, and BDARK exchange
        and o.order_type_id <> 'P' -- not pegged
        and COALESCE(o.exec_instruction, 'N') not in ('L', 'M', 'O', 'P', 'R', 'f') -- exclude Pegged and ISO orders via ExecInstructions. Peggeds are related to peculiar Exchanges with their own prices and they don't look at NBBO
        and o.MULTILEG_REPORTING_TYPE IN ('1'/*, '2'*/) -- exclude complex orders (they have package price) (type = '2')
        and x.exchange_id <> 'BDARK'           -- BDARK don't look on prices
        -- filter hard marketable orders
        and ( case when o.side in ('1', '3')
                    then case when o.price > m.ask_price then 'Y' else 'N' end -- buy street order crossed market
                   else case when o.price < m.bid_price then 'Y' else 'N' end -- sell street order crossed market
              end ) = 'Y'
        and ( coalesce(m.ask_price, 1) > 0 and coalesce(m.bid_price, 1) > 0) -- workaround: exclude the negative metadata
        and o.create_time > m.transaction_time -- to ensure correct matching of MD to orders
        -- похоже, что маркет дата выбирается перед созданием ордера(и это логично, т.к. созданный ордер должен быть послан в правильный маркет-центр)
        and ( (o.side not in ('1', '3') and mc.market_center_bid_price < m.bid_price )  -- to sell order: market has worse bid price then NBBO
           OR (o.side in ('1', '3') and mc.market_center_ask_price > m.ask_price)       -- to buy order: market has worse offer price then NBBO
            ) -- we check that there is better Market center for this transaction
      ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Step 1: Preparatory/preliminary matching', l_row_cnt, 'I')
   into l_step_id;

  execute 'analyze tmp_stg_rept_trade_trough_prepare_match';

  /* Staging Table (with necessary indexes) to store all the Market Data related to found orders */
--   truncate table staging.stg_rept_trade_trough_md_fltr;

  /* Gather all the necessary Market Data for found street orders */
    create temp table t_stg_rept_trade_trough_md_fltr on commit drop as
    with pre_fltr as
      (
        select distinct t.instrument_id, t.start_date_id, t.exchange_id
        from tmp_stg_rept_trade_trough_prepare_match t --staging.stg_rept_trade_trough_prepare_match t
      )
    select
        s.l1_snapshot_id
      , s.start_date_id
      , s.transaction_id
      , s.exchange_id
      , s.instrument_id
      , s.bid_price
      , s.ask_price
      , s.bid_quantity
      , s.ask_quantity
      , s.dataset_id
      , s.transaction_time
    from dwh.l1_snapshot s
    where true
      and s.start_date_id between l_start_date_id and l_end_date_id --20180118 and 20180118 -- hardcode boundaries
      and ROW(s.instrument_id, s.start_date_id, s.exchange_id) in
        (
          select t.instrument_id, t.start_date_id, t.exchange_id
          from pre_fltr t
          union all
          select t.instrument_id, t.start_date_id, 'NBBO'::varchar as exchange_id -- also include values for NBBO
          from pre_fltr t
        )
      and s.transaction_time is not null --s.l1_snapshot_id > 0 -- Ora Prod Traffic
   ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    create index on t_stg_rept_trade_trough_md_fltr using btree (instrument_id);
    create index on t_stg_rept_trade_trough_md_fltr using btree (start_date_id, exchange_id, instrument_id, transaction_time);
    create index on t_stg_rept_trade_trough_md_fltr using btree (transaction_id);

  select public.load_log(l_load_id, l_step_id, 'Step 2: Market Data related to found orders', l_row_cnt, 'I')
   into l_step_id;

   execute 'analyze t_stg_rept_trade_trough_md_fltr';


--return;

   execute 'DROP TABLE IF EXISTS tmp_trade_trough_report;';
   create temp table tmp_trade_trough_report with (parallel_workers = 4) ON COMMIT drop as
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
      ||','|| coalesce("Sub Strategy"::text, ''::text )
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
          , to_char(ex.exec_time, 'YYYY-MM-DD')::varchar as "Event Date"
          , to_char(o.process_time, 'YYYY-MM-DD HH24:MI:SS.US')::varchar as "Routed Time"
          , to_char(ex.exec_time, 'YYYY-MM-DD HH24:MI:SS.MS')::varchar as "Event Time"
          , o.client_order_id as "Cl Ord ID"
          , po.client_order_id as "Parent Cl Ord Id" -- lookup to parent
          , ( case o.side
                when '1' then 'Buy'
                when '2' then 'Sell'
                when '3' then 'Buy minus'
                when '4' then 'Sell plus'
                when '5' then 'Sell short'
                when '6' then 'Sell short exempt'
                when '7' then 'Undisclosed'
                when '8' then 'Cross'
                when '9' then 'Cross short'
              end )::varchar  as "Side"
          , it.instrument_type_name as "Security Type"
          , i.display_instrument_id as "Symbol"
          , o.price as "Price"
          , y.avg_px as "Avg px"
          , o.order_qty as "Ord Qty"
          , ot.order_type_name as "Order Type"
          , s.exchange_id as "ex_destination" -- (пока покажем exchange_id стрита) -- парента или стрита? возможно это exchange_id стрита? в любом случае лукап из client_order, хотя если это exchange_id стрита, то можно и напрямую
          , tif.tif_short_name as "TIF"
          , po.sub_strategy as "Sub Strategy"
          , s.exchange_id as "mkt_data_exchange" -- что за эксчейндж ? ( наверное тот, на котором висит ордер )
          , s.bid_price as "nbbo_bid_px"
          , s.bid_quantity as "nbbo_bid_size"
          , s.ask_price as "nbbo_ask_px"
          , s.ask_quantity as "nbbo_ask_size"
          , s.market_center_bid_quantity as "bid_size"
          , s.market_center_bid_price as "bid_px"
          , s.market_center_ask_quantity as "ask_size"
          , s.market_center_ask_price as "ask_px"
        from tmp_stg_rept_trade_trough_prepare_match s -- staging.stg_rept_trade_trough_prepare_match s -- the source street orders matching
          inner join lateral
            (
              select *
              from dwh.client_order o -- street order
              where o.create_date_id between l_start_date_id and l_end_date_id -- hardcode boundaries
                and o.order_id = s.order_id
              limit 1
            ) o ON true
          left join lateral
            (
              select *
              from data_marts.f_yield_capture y -- street order datamart lookup
              where y.status_date_id >= l_start_date_id --and l_end_date_id -- l_start_date_id and l_end_date_id -- hardcode boundaries
                and y.parent_order_id is not null
                and y.order_id = o.order_id
              order by y.exec_time desc
              limit 1
            ) y ON true
          left join dwh.d_account acc
            ON acc.account_id = o.account_id
          left join dwh.d_trading_firm tf
            ON tf.trading_firm_unq_id = acc.trading_firm_unq_id
          inner join lateral
            (
              select po.client_order_id, po.customer_or_firm_id, s.sub_strategy
              from dwh.client_order po
                join data_marts.d_sub_strategy s
                  ON po.sub_strategy_id = s.sub_strategy_id
              where true
                and po.order_id = o.parent_order_id
                and po.create_date_id between l_start_date_id and l_end_date_id  -- hardcode boundaries
                --and s.sub_strategy in ('SENSOR', 'SMOKE', 'STRIKE', 'SWEEPNCXL')
              limit 1
            ) po ON true
          left join dwh.d_customer_or_firm cf
            ON cf.customer_or_firm_id = po.customer_or_firm_id
          left join lateral
            (
              select ex.order_status, ex.exec_time
              from dwh.EXECUTION ex
              where EX.ORDER_ID = o.order_id -- странно, НО почему-то мы смотрим стритовые экзекьюшены, нужны ли нам парентовые?
                and ex.exec_date_id >= l_start_date_id -- Здесь не between, а больше старт дэй
                and EX.ORDER_STATUS <> '3' -- don't show done for day
              order by ex.exec_id desc
              limit 1
            ) ex ON true
          left join dwh.d_order_status os
            ON os.order_status = ex.order_status
            and os.is_active = true
          left join dwh.d_instrument i
            ON i.instrument_id = o.instrument_id
          left join dwh.d_instrument_type it
            ON it.instrument_type_id = i.instrument_type_id
          left join dwh.d_order_type ot
            ON ot.order_type_id = o.order_type_id
          left join dwh.d_time_in_force tif
            ON tif.tif_id = o.time_in_force_id
            and tif.is_active = true
        where 1=1
          and not exists
            (
              select 1 -- Exclude TradeThroughs which wasn't TradeThroughs according to MD for 1 second ago period for order's exchange
              from t_stg_rept_trade_trough_md_fltr mcs -- snapshots by instrument for 1 second prior period
                join t_stg_rept_trade_trough_md_fltr mtb -- best price market data by transaction
                  ON mtb.start_date_id = mcs.start_date_id
                  and mtb.start_date_id between l_start_date_id and l_end_date_id -- hardcode dates boundaries
                  and mtb.transaction_id = mcs.transaction_id
                  --and mtb.instrument_id = mcs.instrument_id  -- improving of transaction_id join condition
                  and mtb.exchange_id = 'NBBO'
                  -- make sure that the exchange price is the best price for order side
                  and ( case when o.side in ('1', '3')
                              then case when mcs.ask_price = mtb.ask_price then 'Y' else 'N' end
                             else case when mcs.bid_price = mtb.bid_price then 'Y' else 'N' end
                        end ) = 'Y'
              where mcs.start_date_id = s.start_date_id
                and mcs.start_date_id between l_start_date_id and l_end_date_id -- hardcode dates boundaries
                and mcs.instrument_id = s.instrument_id -- the same instrument as we have for intersection of orders and market data
                and mcs.transaction_time between o.create_time - interval '1 second' and o.create_time -- 1 second prior to transaction period definition
                and mcs.exchange_id = s.exchange_id -- look for the transaction/order's exchange
                and mcs.transaction_id <> s.transaction_id -- exclude order's market_data
                and ( case when o.side in ('1', '3') -- requirements for previous exchange snapshots
                            then case when o.price <= mcs.ask_price then 'Y' else 'N' end -- bid price that was equal or inferior to the price of the trade-through transaction
                           else case when o.price >= mcs.bid_price then 'Y' else 'N' end -- ask price that was equal or inferior to the price of the trade-through transaction
                      end ) = 'Y'

            )
      ) src
  ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Retrieve all trade through report', l_row_cnt, 'I')
   into l_step_id;


  /* Form the return query with final filtrations */
   RETURN QUERY

    select '"Trading Firm","Account",Capacity,Ord Status,Event Date,Routed Time,Event Time,Cl Ord ID,Parent Cl Ord Id,Side,Security Type,Symbol,Price,Avg px,Ord Qty,Order Type,ex_destination,TIF,Sub Strategy,mkt_data_exchange,nbbo_bid_px,nbbo_bid_size,nbbo_ask_px,nbbo_ask_size,bid_size,bid_px,ask_size,ask_px'::text as rec
    union all
    select rec
    from tmp_trade_trough_report
    ;

   select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_trade_through_report_csv FINISHED SUCCESSFULLY===', 0, 'O')
   into l_step_id;

END;
$function$
;


select * from (
 select pid, state, application_name, user, wait_event, query_start::timestamp as query_start, age(clock_timestamp(), query_start) as age, usename, query
	from pg_stat_activity
	where true
	and state in ('active', 'idle in transaction')
	and query not ilike '%pg_stat_activity%'
--	and query not ilike '%vacuum%'
	and query not ilike '%replicat%'
	union all
	select null, null, null as application_name, null, null, null as query_start, null as age, null, null) x
	order by case when coalesce(application_name, 'Sydor') ilike '%Sydor%' then 0 else 1 end,  query_start nulls last;