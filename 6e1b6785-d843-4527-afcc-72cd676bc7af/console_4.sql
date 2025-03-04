CREATE TABLE IF NOT EXISTS staging.ats_cons_details
(
    dataset_id                    int8                        NULL, -- from subscription
    auction_id                    int8                        NULL, -- NK #1. Auction ID.
    auction_date_id               int4                        NULL,
    liquidity_provider_id         varchar(9)                  NULL, -- Defined via FIX_CONNECTION and FIX_COMP_ID. Used for LPO orders.
    ofp_orig_order_id             int8                        NULL, -- order_id of auctions initiating OFP parent order. For multileg, mlrt of such ord = ''3'' and side = ''B''

    -- markers of orders groups
    is_ats                        bool                        NULL,
    is_cons                       bool                        NULL,
    --
    is_ofp_parent                 bool                        NULL, -- OFP originating parent orders.
    is_ofp_street                 bool                        NULL, -- OFP created crosses
    is_lpo_parent                 bool                        NULL, -- LPO responces
    is_lpo_street                 bool                        NULL, -- LPO created crosses

    -- order info
    order_id                      int8                        NOT NULL,
    client_order_id               varchar(256)                NULL,
    parent_order_id               int8                        NULL,
    order_create_time             timestamp without time zone NULL,
    create_date_id                integer                     NOT NULL,
    order_price                   numeric(12, 4)              NULL,
    order_qty                     int8                        NULL,
    order_type_id                 varchar(1)                  NULL,
    account_id                    int8                        NULL,
    instrument_id                 int8                        NULL,
    transaction_id                int8                        NULL,
    side                          varchar(1)                  NULL,
    multileg_reporting_type       varchar(1)                  NULL, -- including mlrt=3 in temp.
    cross_order_id                int8                        NULL,
    client_id                     varchar(255)                NULL,
    exchange_id                   varchar(6)                  NULL,
    fix_connection_id             int8                        NULL,
    fix_comp_id                   varchar(30)                 NULL,
    internal_component_type       varchar(1)                  NULL,
    sub_system_id                 varchar(20)                 NULL,
    order_liquidity_provider_id   varchar(9)                  NULL,
    exch_order_id                 varchar(128)                NULL,
    exec_instruction              varchar(128)                NULL,
    strategy_decision_reason_code int2                        NULL,
    capacity_group_id             int8                        NULL,

    -- prepare some attributes for resp quality calculation
    resp_ofp_parent_order_side    varchar(1)                  NULL,
    resp_ofp_parent_order_price   numeric(12, 4)              NULL,
    is_marketable                 bpchar(1)                   NULL,
    resp_is_quality_response      bool                        NULL, -- where resp price < nbbo ask price for a buy; resp price > nbbo bid price for a sell
    resp_is_good_response         bool                        NULL, -- case when order price < resp price < nbbo ask price for a buy; order price > resp price > nbbo bid price for a sell
    resp_is_neutral_response      bool                        NULL, -- case when resp price = nbbo ask price for a buy; resp price = nbbo bid price for a sell
    resp_is_bad_response          bool                        NULL, -- case when resp price > nbbo ask price for a buy; resp price < nbbo bid price for a sell
    resp_is_great_response        bool                        NULL, -- case when resp price <= order price for a buy; resp price >= order price for a sell
    resp_price_improve_pct        numeric(12, 4)              NULL, -- ( 1 - (rsp.order_price - ((rsp.nbbo_ask_price + rsp.nbbo_bid_price)/2))::numeric / ((rsp.nbbo_ask_price - rsp.nbbo_bid_price)::numeric/2))*100 for a buy
    resp_size_impr_vs_nbbo        bool                        NULL, -- case when rsp.order_qty > rsp.nbbo_ask_quantity then true else false end for a buy
    resp_size_impr_vs_nbbo_pct    numeric(12, 4)              NULL, -- (rsp.order_qty::numeric/nullif(rsp.nbbo_ask_quantity,0)::numeric)*100 for a buy
    resp_match_qty                int4                        NULL, -- execution.match_qty when exec_type = M
    resp_avg_match_px             numeric(12, 4)              NULL, -- execution.match_px when exec_type = M

    -- Market Data
    nbbo_bid_price                numeric(12, 4)              NULL,
    nbbo_bid_quantity             int4                        NULL,
    nbbo_ask_price                numeric(12, 4)              NULL,
    nbbo_ask_quantity             int4                        NULL,

    -- Order Status
    exec_text                     varchar(512)                NULL, -- 58 tag of the last execution of order.
    filled_price                  numeric(12, 4)              NULL, -- avg_px
    filled_qty                    int4                        NULL, -- cum_qty, VOLUME, -- also need to recalculate if needed
    order_status                  varchar(1)                  NULL, -- last status
    principal_amount              numeric(16, 4)              NULL,
    first_fill_date_time          timestamp without time zone NULL,

    etl_max_ord_exec_id           int8                        NULL, -- to filter out up-to-date orders
    etl_max_ord_trade_tecord_id   int8                        NULL, -- to filter out up-to-date orders
    etl_max_md_transaction_id     int8                        NULL, -- to filter out up-to-date orders
    CONSTRAINT "tmp_PK_tmp_ats_cons" PRIMARY KEY (order_id, auction_id, auction_date_id)
);


-- DROP FUNCTION data_marts.load_ats_cons_inc(_int8, int4);

CREATE OR REPLACE FUNCTION data_marts.so_load_ats_cons_inc(in_order_ids bigint[] DEFAULT NULL::bigint[], in_recalc_date_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
DECLARE
   l_row_cnt integer;

   l_load_id int;
   l_step_id int;

   l_orig_order_ids bigint[];
   l_load_batch_arr int8[];

   l_cur_date_id integer;
   l_gtc_min_date_id integer;
   l_etl_min_date_id integer;
   l_min_order_create_date_id integer;

   l_foreign_order_id bigint;
   l_local_order_id bigint;
   l_local_rfq_id  bigint;
   l_is_current_recalc boolean;

   l_sql varchar;
l_max_rfq_id int8;
BEGIN
  /*
    we don't need to run this AFTER the HODS processed.
  */

  --if in_recalc_date_id is null
  --then return -1;
  --end if;

  select nextval('public.load_timing_seq') into l_load_id;

  l_step_id:=1;

  select public.load_log(l_load_id, l_step_id, 'load_ats_cons_inc STARTED===', 0, 'O')
   into l_step_id;


   -- Variables definition
   l_cur_date_id   := coalesce(in_recalc_date_id, to_char(current_date, 'YYYYMMDD')::integer);
   l_etl_min_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '5 days', 'YYYYMMDD')::integer;
   l_gtc_min_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '180 days', 'YYYYMMDD')::integer;

   l_is_current_recalc := case when l_cur_date_id = in_recalc_date_id then true else false end;

  raise notice 'l_cur_date_id - %, l_etl_min_date_id - %, l_gtc_min_date_id - %, l_is_current_recalc - %', l_cur_date_id, l_etl_min_date_id, l_gtc_min_date_id, l_is_current_recalc;
  -- Temporary table definition
--  execute 'DROP TABLE IF EXISTS tmp_ats_cons_details;';


  truncate table staging.ats_cons_details;


---------------------------------------------------------------------------------------------------------
-- MOCK RFQ when recalc
 if in_recalc_date_id is null
 then
 --1) Step 1.1.  f_rfq_details. incremental load

  -->> calculate max rfq_id we have on PG side.
    -- 1-st execution on the next day should find all gaps if they'll be found...
     l_local_rfq_id  := ( select coalesce(max(q.rfq_id), -1) as local_rfq_id
                          from data_marts.f_rfq_details q
                          where q.auction_date_id = l_cur_date_id ) - 1000; -- why this 10000 is here if we do not have on conflict update later in insert?
     l_max_rfq_id := (select max(r.rfq_id) FROM dwh.request_for_quote r
                                           where r.auction_date_id = l_cur_date_id);

 else
     l_local_rfq_id  := -1;


 end if;
-- l_local_rfq_id = 290146112046642193;

   select public.load_log(l_load_id, l_step_id, 'Step 1.1. f_rfq_details. date_id = '||l_cur_date_id::varchar||', l_local_rfq_id = '||l_local_rfq_id::varchar||
                                                    ', l_max_rfq_id = '||l_max_rfq_id::text||', load_batch_id = '||l_load_id::varchar, 0 , 'O')
     into l_step_id;

  -->> take rfq_id diff to PG side
    INSERT INTO data_marts.f_rfq_details
      (
        rfq_leg_id
      , rfq_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_order_id
      , ofp_client_order_id
      , ofp_create_time
      , ofp_order_type
      , ofp_side
      , ofp_order_qty
      , ofp_order_price
      , ofp_leg_ref_id
      , ofp_account_id
      , ofp_sub_system_id
      , ofp_sub_strategy
      , ofp_internal_component_type
      , ofp_client_id
      , rfq_qty
      , rfq_multi_leg_side
      , rfq_multileg_reporting_type
      , rfq_transact_time
      , rfq_quote_type
      , rfq_min_response_qty
      , rfq_ratio_qty
      , ofp_fix_message_id
      , rfq_fix_message_id
      , ofp_instrument_id
      , rfq_instrument_id
      , ofp_transaction_id
      , rfq_transaction_id
      , ofp_fix_comp_id
      , rfq_fix_comp_id
      , ofp_fix_connection_id
      , rfq_fix_connection_id
      , is_ats_ofp_parent
      , is_consolidator_ofp_parent
      , rfq_nbbo_bid_price
      , rfq_nbbo_bid_quantity
      , rfq_nbbo_ask_price
      , rfq_nbbo_ask_quantity
      , is_maket_data_applied
      , load_batch_id)
    select
        RFQ_LEG_ID as rfq_leg_id -- UNIQUE KEY
      , RFQ_ID as rfq_id
      , AUCTION_ID as auction_id
      , auction_date_id::integer as auction_date_id
      , rfq_LIQUIDITY_PROVIDER_ID as liquidity_provider_id
      , rfq_ofp_order_id as ofp_order_id
      , CLIENT_ORDER_ID as ofp_client_order_id
--       , to_timestamp(v.create_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as ofp_create_time
         , v.create_time as ofp_create_time
      , ORDER_TYPE_id as ofp_order_type
      , SIDE as ofp_side
      , ORDER_QTY as ofp_order_qty
      , PRICE as ofp_order_price
--       , CO_CLIENT_LEG_REF_ID as ofp_leg_ref_id
      , null as ofp_leg_ref_id
      , ACCOUNT_ID as ofp_account_id
      , SUB_SYSTEM_ID as ofp_sub_system_id
      , dss.SUB_STRATEGY as ofp_sub_strategy
--       , INTERNAL_COMPONENT_TYPE as ofp_internal_component_type
         , null as ofp_internal_component_type
      , client_id_text as ofp_client_id
      , requested_qty as rfq_qty
      , requested_multi_leg_side as rfq_multi_leg_side
      , MULTILEG_REPORTING_TYPE as rfq_multileg_reporting_type
--       , to_timestamp(v.rfq_transact_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as rfq_transact_time
       , v.rfq_transact_time as rfq_transact_time
      , quote_type as rfq_quote_type
      , min_response_qty as rfq_min_response_qty
      , ratio_qty as rfq_ratio_qty
      , FIX_MESSAGE_ID as ofp_fix_message_id
      , rfq_fix_message_id as rfq_fix_message_id
      , INSTRUMENT_ID as ofp_instrument_id
      , requested_instrument_id as rfq_instrument_id
      , order_transaction_id as ofp_transaction_id
      , rfq_transaction_id as rfq_transaction_id
      , FIX_COMP_ID as ofp_fix_comp_id
      , rfq_fix_comp_id as rfq_fix_comp_id
      , FIX_CONNECTION_ID as ofp_fix_connection_id
      , rfq_fix_connection_id as rfq_fix_connection_id
      , is_ats_ofp_parent::boolean as is_ats_ofp_parent
      , is_consolidator_ofp_parent::boolean as is_consolidator_ofp_parent
      , md.bid_price as rfq_nbbo_bid_price
      , md.bid_quantity as rfq_nbbo_bid_quantity
      , md.ask_price as rfq_nbbo_ask_price
      , md.ask_quantity as rfq_nbbo_ask_quantity
      , md.is_maket_data_applied
      , l_load_id as load_batch_id
    from staging.ats_rfq_daily_v v
      left join lateral
        (
          select md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
            , case when md.transaction_id > 0 then true end as is_maket_data_applied
          from dwh.l1_snapshot md
          where md.transaction_id = v.rfq_transaction_id
            and md.instrument_id = case when md.instrument_id > 0 and v.MULTILEG_REPORTING_TYPE = '1' then v.instrument_id else md.instrument_id end --v.instrument_id
            and md.exchange_id = 'NBBO'
            and md.start_date_id between l_etl_min_date_id and l_cur_date_id
            --and md.start_date_id = v.auction_date_id::integer
          limit 1
        ) md on true
    left join data_marts.d_sub_strategy dss on dss.sub_strategy_id = v.sub_strategy_id
     where true
       and v.RFQ_ID >= l_local_rfq_id
            and v.RFQ_ID <= l_max_rfq_id
       and v.auction_date_id between l_etl_min_date_id and l_cur_date_id -- >= l_etl_min_date_id
       and not exists
      (
        select r.rfq_leg_id
        from data_marts.f_rfq_details r
        where r.auction_date_id = v.auction_date_id::integer -- unq idx used
          and r.auction_date_id >= l_etl_min_date_id
          and r.rfq_leg_id = v.rfq_leg_id
      )
  limit 1000000
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'inserted into data_marts.f_rfq_details  ', l_row_cnt , 'I')
     into l_step_id;

 --1) Step 1.2.  f_rfq_details. Missing Market Data lookup

   -- lookup into the orders array and at the end of procedure - invoke manual run for these orders
   --l_orig_order_ids := array(
   execute 'DROP TABLE IF EXISTS tmp_rfq_missed_md;';
   create temp table tmp_rfq_missed_md with (parallel_workers = 4)
--        ON COMMIT drop
       as
    select distinct q.ofp_order_id, q.auction_date_id -- parent_originator order
    from data_marts.f_rfq_details q
      join lateral
        (
          select s.transaction_id
          from dwh.l1_snapshot s
          where s.start_date_id between l_etl_min_date_id and l_cur_date_id -- partition pruning
            and s.transaction_id = q.rfq_transaction_id
            and s.exchange_id = 'NBBO'
          limit 1
        ) md ON true
    where q.auction_date_id between l_etl_min_date_id and l_cur_date_id
      --and q.is_maket_data_applied is null
      and case when (in_recalc_date_id is not null or l_local_rfq_id  = -1) -- calculation on the next day after market data is switched to Alex snapshot
                then (q.rfq_nbbo_ask_price is null or q.rfq_nbbo_bid_price is null)
                else q.is_maket_data_applied is null
          end
      and q.rfq_transaction_id is not null
      -- and limitation to not process orders older than 1 hour
    --limit 100
    --)
    ;
  GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
  execute 'analyze tmp_rfq_missed_md';

   --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_rfq_missed_md;';
   --create table trash.sdn_tmp_rfq_missed_md with (parallel_workers = 4) as
   --select * from tmp_rfq_missed_md;


  --select public.load_log(l_load_id, l_step_id, 'Step 1.2. Look for missing Market data for RFQ', cardinality(l_orig_order_ids) , 'I')
  select public.load_log(l_load_id, l_step_id, 'Step 1.2. Look for missing Market data for RFQ', l_row_cnt , 'I')
     into l_step_id;


  -- prepare Market data for RFQ into TMP
   execute 'DROP TABLE IF EXISTS tmp_rfq_missed_md_v2;';
   create temp table tmp_rfq_missed_md_v2 with (parallel_workers = 4)
--        ON COMMIT drop
       as
  select s.auction_date_id, s.rfq_leg_id, s.rfq_id
    , s.bid_price, s.bid_quantity, s.ask_price, s.ask_quantity
    , s.is_maket_data_applied
  from
    (
          with src as materialized
            (
              select a.ofp_order_id, a.auction_date_id
              from tmp_rfq_missed_md a
              limit 100000000
            )
          select q.auction_date_id, q.rfq_leg_id, q.rfq_id
            , md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
            , case when md.transaction_id > 0 then true end as is_maket_data_applied
          from src a --unnest(l_orig_order_ids) a
            --join data_marts.f_rfq_details q
            --  on q.ofp_order_id = a.a
            inner join lateral
              (
                select q.auction_date_id, q.rfq_leg_id, q.rfq_id
                  , q.rfq_transaction_id, q.rfq_instrument_id, q.rfq_multileg_reporting_type
                from data_marts.f_rfq_details q
                where q.ofp_order_id = a.ofp_order_id --a.a
                  and q.auction_date_id between l_etl_min_date_id and l_cur_date_id
                  and q.auction_date_id = a.auction_date_id
                  --and q.is_maket_data_applied is null
                  and q.rfq_transaction_id is not null
                limit 10000000 -- rfq_leg_ids per one ofp_order_id. can be tens on thousands. Up to million.
              ) q on true
            inner join lateral
              (
                select md.transaction_id
                  , md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
                from dwh.l1_snapshot md
                where md.transaction_id = q.rfq_transaction_id
                  and md.instrument_id = case when md.instrument_id > 0 and q.rfq_multileg_reporting_type = '1' then q.rfq_instrument_id else md.instrument_id end -- use instruments for single legs only
                  and md.exchange_id = 'NBBO'
                  and md.start_date_id = q.auction_date_id
                  and md.start_date_id between l_etl_min_date_id and l_cur_date_id
                limit 1  -- one NBBO for one transaction
              ) md on true
  ) s
  ;
  GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
  execute 'analyze tmp_rfq_missed_md_v2';

  select public.load_log(l_load_id, l_step_id, 'Step 1.2.1 prepare Market data for RFQ into TMP', l_row_cnt , 'I')
     into l_step_id;

   --1) Step 1.3.  f_rfq_details. Manual run. Missing Market Data update.
    -- in this peculiar case we don't need merge. Simple Update will be enough.

 --if cardinality(l_orig_order_ids) > 0 -- and in_manual_run
 if (select count(1) from tmp_rfq_missed_md) > 0 --and 1<>1-- and in_manual_run

  then
    update data_marts.f_rfq_details trg
      set rfq_nbbo_bid_price    = s.bid_price
        , rfq_nbbo_bid_quantity = s.bid_quantity
        , rfq_nbbo_ask_price    = s.ask_price
        , rfq_nbbo_ask_quantity = s.ask_quantity
        , is_maket_data_applied = true
    from tmp_rfq_missed_md_v2 s
    where trg.auction_date_id between l_etl_min_date_id and l_cur_date_id --20211119 and 20211122 --
      --and trg.is_maket_data_applied is null
      and trg.auction_date_id = s.auction_date_id
      and trg.rfq_leg_id = s.rfq_leg_id
      and trg.rfq_id = s.rfq_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Step 1.2.2 Maket Data updated in data_marts.f_rfq_details  ', l_row_cnt , 'U')
     into l_step_id;

  end if;




 -->> recalculate information for some date
 if in_recalc_date_id is not null  -- try to REcalculate the datamart for the pointed date

  then

  -- gather missed auctions on GTC orders
--   execute 'DROP TABLE IF EXISTS tmp_missed_gtc_auctions;';
--   create temp table tmp_missed_gtc_auctions with (parallel_workers = 4) ON COMMIT drop as
--   select rd.auction_date_id , rd.auction_id
--    from
--      (
--        select auction_date_id, rd.auction_id
--        from data_marts.f_rfq_details rd
--        where rd.auction_date_id = l_cur_date_id
--        group by auction_date_id, rd.auction_id
--      ) rd
--    where not exists
--      (
--        select s.auction_date_id --, s.auction_id
--        from data_marts.f_ats_cons_details s
--        where s.auction_date_id = l_cur_date_id
--          and s.auction_date_id = rd.auction_date_id
--          and s.auction_id = rd.auction_id
--      )
--    ;
--    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
--  select public.load_log(l_load_id, l_step_id, '2.0 ATS missing GTC auctions for ('||l_cur_date_id::text||') loaded into TMP' , l_row_cnt , 'I')
--    into l_step_id;

  -- load auctions, not orders. We need to complete CONS auctions with OFP parent orders. And need to set the ofp_orig_order_id value
    INSERT INTO staging.ats_cons_details
      ( dataset_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats
      , is_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select
        to_char(now(), 'YYMMDDHH24MI')::bigint as dataset_id
      , a.auction_id as auction_id
      , a.auction_date_id as auction_date_id
      , coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) as liquidity_provider_id
      , rfq.ofp_order_id as ofp_orig_order_id -- on this step is only for ATS
      , case when ca.rfq_transact_time /*rfq.ofp_order_id*/ is not null then true end as is_ats
      , case when ca.rfq_transact_time /*rfq.ofp_order_id*/ is null then true end as is_cons
      , case when cl.parent_order_id is null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is null then true end as is_ofp_parent
      , case when cl.parent_order_id is not null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is null then true end as is_ofp_street
      , case when cl.parent_order_id is null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is not null then true end as is_lpo_parent
      , case when cl.parent_order_id is not null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is not null then true end as is_lpo_street
      , ca.order_id as order_id
      , cl.client_order_id as client_order_id
      , cl.parent_order_id as parent_order_id
      , cl.create_time as order_create_time
      , cl.create_date_id as create_date_id
      , cl.price as order_price
      , cl.order_qty as order_qty
      , cl.order_type_id as order_type_id
      , cl.account_id as account_id
      , cl.instrument_id as instrument_id
      , cl.transaction_id as transaction_id
      , cl.side as side
      , cl.multileg_reporting_type as multileg_reporting_type
      , cl.cross_order_id as cross_order_id
      , cl.client_id_text as client_id
      , cl.exchange_id as exchange_id
      , cl.fix_connection_id as fix_connection_id
      , fc.fix_comp_id as fix_comp_id
      , cl.internal_component_type as internal_component_type
      , ss.sub_system_id as sub_system_id
      , cl.liquidity_provider_id as order_liquidity_provider_id
      , cl.exch_order_id as exch_order_id
      , cl.exec_instruction
      , cl.strtg_decision_reason_code as strategy_decision_reason_code
      , cf.capacity_group_id
    from
      (
        select ca.auction_id --, count(1) as cnt
          , max(ca.create_date_id) as auction_date_id
          --, min(ca.create_date_id) as min_order_create_date_id
          , (select min(au.create_date_id) from dwh.client_order2auction au where ca.auction_id = au.auction_id) as min_order_create_date_id
        from dwh.client_order2auction ca
          join dwh.client_order co
            on ca.order_id = co.order_id
            and co.create_date_id = l_cur_date_id
        where ca.create_date_id = l_cur_date_id -- date for recalculation. It is not including old GTC orders for the current auction_date_id which is problem.
          and coalesce(co.trans_type, '-1') <> 'F' -- Cancel requests are generating new auction_date_id for old auctions.Suppressing.
          and (l_is_current_recalc = true
              or coalesce(co.time_in_force_id, '-1') not in ('1','6')) -- exclude GTC,GTD from recalculations based on create_date_id of orders
        group by ca.auction_id
        union all
        select rd.auction_id
          , max(rd.auction_date_id) as auction_date_id
          , (select min(au.create_date_id) from dwh.client_order2auction au where rd.auction_id = au.auction_id) as min_order_create_date_id
        from
          (
            select rd.auction_id, auction_date_id -- hope one auction is present in one auction date
            from data_marts.f_rfq_details rd
            where rd.auction_date_id = l_cur_date_id
            group by auction_date_id, rd.auction_id
          ) rd
          join dwh.client_order2auction ca
            on rd.auction_id = ca.auction_id
            and rd.auction_date_id > ca.create_date_id -- GTC, GTD, GTX filter: orders which were created prior auction date
        group by rd.auction_id
      ) a
      join lateral
        (
          select ca.auction_id, ca.order_id
            , max(ca.rfq_transact_time) over (partition by ca.auction_id) as rfq_transact_time
          from dwh.client_order2auction ca
          where a.auction_id = ca.auction_id
            and ca.create_date_id between a.min_order_create_date_id and a.auction_date_id
            and ca.create_date_id >= l_gtc_min_date_id -- GTC hardcode
          limit 10000 -- orders limit in one auction
        ) ca on true
      left join lateral
        (
          select rfq.auction_id, rfq.auction_date_id
            , rfq.ofp_order_id -- can be of mlrt 1 or 3
          from data_marts.f_rfq_details rfq
          where 1=1
            and rfq.auction_date_id >= l_gtc_min_date_id --a.auction_date_id --
            and rfq.auction_id = a.auction_id
          limit 1
        ) rfq on true
      join dwh.client_order cl
        on ca.order_id = cl.order_id
        and cl.create_date_id between a.min_order_create_date_id and a.auction_date_id
        and cl.create_date_id >= l_gtc_min_date_id -- GTC hardcode
      left join dwh.d_account ac
        on cl.account_id = ac.account_id
      left join dwh.d_sub_system ss
        ON cl.sub_system_unq_id = ss.sub_system_unq_id
      -- parent lvl
      left join dwh.client_order po
        on cl.parent_order_id = po.order_id
        and po.create_date_id >= l_gtc_min_date_id -- GTC hardcode
      left join dwh.d_account pac
        on po.account_id = pac.account_id
      left join dwh.d_fix_connection fc
        on cl.fix_connection_id = fc.fix_connection_id
      left join
        (
          select ats_lp.fix_connection_id, max(ats_lp.liquidity_provider_id) as liquidity_provider_id
          from staging.lp_connection ats_lp
          where ats_lp.lp_connector_id = 'LPLB'
            and ats_lp.is_deleted = 'N'
          group by ats_lp.fix_connection_id
        ) ats_lp
        on coalesce(po.fix_connection_id, cl.fix_connection_id) = ats_lp.fix_connection_id
      left join staging.cons_lp2trading_firm cons_pl
        on coalesce(pac.trading_firm_id, ac.trading_firm_id) = cons_pl.trading_firm_id
      left join dwh.d_customer_or_firm cf
      	on cl.customer_or_firm_id = cf.customer_or_firm_id
    where 1=1
      and coalesce(cl.trans_type, '-1') <> 'F'
      --and cl.multileg_reporting_type in ('1','2')
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.1 ATS + CONS recalculation('||l_cur_date_id::text||') loaded into TMP' , l_row_cnt , 'I')
    into l_step_id;



  else -- incremental load

 -- Step 2 Increment definition and calculations into the Temp table
 -- Step 2.1.  ATS + CONS subscriptions load

  l_load_batch_arr := array (select distinct load_batch_id
                             from public.etl_subscriptions
                             where 1=1
                               and subscription_name in ( 'ats_details' )
                               and source_table_name ='dmp.client_order2auction'
                               and not is_processed
                               and subscribe_time < now() - interval '15 seconds'
                               and subscribe_time >= to_timestamp(l_etl_min_date_id::varchar, 'YYYYMMDD') -- interval '1 day'
                               and subscribe_time <  to_timestamp(l_cur_date_id::varchar, 'YYYYMMDD') + interval '1 day'
                             order by load_batch_id
                             limit 2
                            );

  select public.load_log(l_load_id, l_step_id, left('2.1. ATS_CONS_details load_batch_id array loaded: '||array_to_string(l_load_batch_arr,','), 200), cardinality(l_load_batch_arr), 'I')
   into l_step_id;

IF cardinality(l_load_batch_arr) > 0
then
 -- Step 2.2.  ATS + CONS auctions load from source
  -- load auctions, not orders. We need to complete CONS auctions with OFP parent orders. And need to set the ofp_orig_order_id value
    INSERT INTO staging.ats_cons_details
      ( dataset_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats
      , is_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select s.dataset_id
      , v.auction_id
      , v.auction_date_id
      , v.liquidity_provider_id
      , v.ofp_orig_order_id
      , v.is_ats::boolean
      , v.is_cons::boolean
      , v.is_ofp_parent::boolean
      , v.is_ofp_street::boolean
      , v.is_lpo_parent::boolean
      , v.is_lpo_street::boolean
      , v.order_id
      , v.client_order_id
      , v.parent_order_id
--       , to_timestamp(v.order_create_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as order_create_time
         , v.order_create_time as order_create_time
      , TO_CHAR(v.order_create_time, 'YYYYMMDD')::integer as create_date_id
      , v.order_price
      , v.order_qty
      , v.order_type_id
      , v.account_id
      , v.instrument_id
      , v.transaction_id
      , v.side
      , v.multileg_reporting_type
      , v.cross_order_id
      , v.client_id_text
      , v.exchange_id
      , v.fix_connection_id
      , v.fix_comp_id
      , v.internal_component_type
      , v.sub_system_id
      , v.order_liquidity_provider_id
      , v.exch_order_id
      , v.exec_instruction
      , v.strategy_decision_reason_code
      , v.capacity_group_id
    from
      (
        select  s.auction_id
          , max(s.dataset_id) as dataset_id
        from dwh.client_order2auction s
        where s.dataset_id = any (l_load_batch_arr)   --- (ARRAY[126018501, 126018487, 126018477, 126018466, 126018454, 126018440, 126018428, 126018416, 126018405]) --
        group by s.auction_id
      ) s
      join lateral
        (
          select v.*
          from staging.ats_cons_stats_v v
          where 1=1
             and v.auction_id = s.auction_id
          limit 10000 -- up to ten thousand requests, responses and streets in one auction. It's the huge enough value
        ) v ON true
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.2 ATS + CONS loaded from source into TMP' , l_row_cnt , 'I')
    into l_step_id;

end if; --<< empty  l_load_batch_arr

 end if; --<< full date load or increment


 if (select count(1) from staging.ats_cons_details limit 1) > 0
   then

 -- Step 2.3.  CONS lookup OFP parent orders
   -- Search for OFP parents via Consolidator OFP Streets
     -- we don't have CONS OFP parents in client_order2auction yet.
       -- in TMP we have whole auctions represented, so lookup of OFP parents will not take extra efforts.
    with cons_par as
      (
        select t.parent_order_id, t.auction_id, t.auction_date_id
        from staging.ats_cons_details t
        where t.is_cons = true
          and t.is_ofp_street = true
        group by t.parent_order_id, t.auction_id, t.auction_date_id
        order by t.parent_order_id, t.auction_id
      )
    INSERT INTO staging.ats_cons_details
      ( dataset_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats
      , is_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select null as dataset_id
      , p.auction_id
      , p.auction_date_id
      , null as liquidity_provider_id
      , null as ofp_orig_order_id
      , null as is_ats
      , true as is_cons
      , true as is_ofp_parent
      , null as is_ofp_street
      , null as is_lpo_parent
      , null as is_lpo_street
      , ofp.order_id
      , ofp.client_order_id
      , ofp.parent_order_id
      , ofp.create_time as order_create_time
      , ofp.create_date_id
      , ofp.price as order_price
      , ofp.order_qty
      , ofp.order_type_id
      , ofp.account_id
      , ofp.instrument_id
      , ofp.transaction_id
      , ofp.side
      , ofp.multileg_reporting_type
      , ofp.cross_order_id
      , ofp.client_id_text
      , ofp.exchange_id
      , ofp.fix_connection_id
      , null as fix_comp_id
      , ofp.internal_component_type
      , ss.sub_system_id
      , ofp.liquidity_provider_id as order_liquidity_provider_id
      , ofp.exch_order_id
      , ofp.exec_instruction
      , ofp.strtg_decision_reason_code
      , cf.capacity_group_id
    from cons_par p
      join dwh.client_order ofp
        ON p.parent_order_id = ofp.order_id
      left join dwh.d_sub_system ss
        ON ofp.sub_system_unq_id = ss.sub_system_unq_id
      left join dwh.d_customer_or_firm cf
      	on ofp.customer_or_firm_id = cf.customer_or_firm_id
    ON CONFLICT (auction_id, order_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.3 CONS OFP parent orders loaded' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 2.4.  CONS set the ofp_orig_order_id attribte.
   -- it is needed for CONS sources. ATS already has ofp_orig_order_id initiated via RFQ on the ORA source view
     -- for multilegs it = order_id of OFP multileg parent order (mlrt=3)
    update staging.ats_cons_details t
      set ofp_orig_order_id = src.ofp_orig_order_id
    from
      (
        select s.auction_id, min(s.order_id) as ofp_orig_order_id
        from staging.ats_cons_details s
        where s.is_ofp_parent = true
          and s.is_cons = true
          and s.multileg_reporting_type in ('1','3')
        group by s.auction_id
      ) src
    where t.ofp_orig_order_id is null -- only when is not set
      and t.auction_id = src.auction_id
      and t.is_cons = true -- for whole auction
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.4 CONS ofp_orig_order_id updated. Increment almost prepared.' , l_row_cnt , 'U')
    into l_step_id;

 -- Step 2.5. Set Price and Side of OFP parent order for LPO responses

    update staging.ats_cons_details trg
      set resp_ofp_parent_order_side = src.side
        , resp_ofp_parent_order_price = src.order_price
    from
      (
        select ofp.ofp_orig_order_id, ofp.auction_id, ofp.auction_date_id, ofp.instrument_id
          , ofp.order_price, ofp.side
        from staging.ats_cons_details ofp
        where is_ofp_parent = true
      ) src
    where trg.ofp_orig_order_id = src.ofp_orig_order_id
      and trg.auction_id = src.auction_id
      and trg.auction_date_id = src.auction_date_id
      and trg.instrument_id = src.instrument_id -- fix for miltilegs
      and trg.is_lpo_parent = true
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.5 Price and Side of OFP parent is set for LPO responses. Increment prepared.' , l_row_cnt , 'U')
    into l_step_id;

 -- Step 3. Extend dataset for statuses and market data recalculation
  -- As for now we have prepared increment withous statuses and market data
   --
 -- Step 3.1. Lookup descrepancy on filled price, filled qty - from trades or f_yield_capture
    -- insert into the same temp table
    insert into staging.ats_cons_details
      (
        order_id
      , auction_id
      , auction_date_id
      , create_date_id
      , transaction_id
      , instrument_id
      , ofp_orig_order_id
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , is_ats
      , is_cons
      , liquidity_provider_id
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.liquidity_provider_id
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
      , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
       --, t.filled_qty
       --, tr.day_cum_qty
    from
      (
        select t.auction_date_id, t.order_id, coalesce(t.filled_qty, 0) as filled_qty
          , t.auction_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.order_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.liquidity_provider_id
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
          , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
        from data_marts.f_ats_cons_details t
        where t.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id --
          --and t.pg_db_create_time > clock_timestamp() - interval '48 hour' -- 1 hour after pasting
          --and t.pg_dp_last_update_time is not null -- V.I. exclude rows revently added
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
      ) t
      left join lateral
        (
          select tr.order_id, sum(tr.last_qty) as day_cum_qty
          from dwh.flat_trade_record tr
          where tr.date_id between l_etl_min_date_id and l_cur_date_id -- -->= l_cur_date_id --  20190328 --
            and tr.date_id = t.auction_date_id
            and ( (tr.order_id = t.order_id and (is_ofp_parent = true or is_lpo_parent = true))
                or (tr.street_order_id = t.order_id and (is_ofp_street = true or is_lpo_street = true)) )
            and tr.is_busted = 'N'
          group by tr.order_id
        ) tr on true
    where t.rn=1 and t.filled_qty <> coalesce(tr.day_cum_qty, 0)
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.1 Lookup descrepancy on filled_price and filled qty.' , l_row_cnt , 'I')
    into l_step_id;


 -- Step 3.2. market data descrepancy - from l1_snapshot or maybe f_yield_capture
    insert into staging.ats_cons_details
      (
        order_id
      , auction_id
      , auction_date_id
      , create_date_id
      , transaction_id
      , instrument_id
      , ofp_orig_order_id
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , is_ats
      , is_cons
      , liquidity_provider_id
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.liquidity_provider_id
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
      , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
    --select count(1)
    from
      (
        select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.auction_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.liquidity_provider_id
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
          , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
        from data_marts.f_ats_cons_details t
        where t.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190408 --
          -- and t.pg_db_create_time > clock_timestamp() - interval '24 hour' -- 1 hour after pasting
          -- and t.pg_dp_last_update_time is not null -- V.I. exclude rows recently added orders
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
          and t.etl_max_md_transaction_id is null
      ) t
      join lateral
        (
          select md.transaction_id
          from dwh.l1_snapshot md
          where md.start_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190408 --
            and md.start_date_id = t.auction_date_id
            and md.transaction_id = t.transaction_id
            and md.exchange_id = 'NBBO'
          limit 1
        ) md on true
    where t.rn=1
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.2 Lookup descrepancy on Market Data.' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 3.3. order status descrepancy - from execution
    insert into staging.ats_cons_details
      (
        order_id
      , auction_id
      , auction_date_id
      , create_date_id
      , transaction_id
      , instrument_id
      , ofp_orig_order_id
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , is_ats
      , is_cons
      , liquidity_provider_id
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.liquidity_provider_id
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
      , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
    --select count(1)
    from
      (
        select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.auction_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.liquidity_provider_id
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
          , coalesce(t.order_status, '-1') as order_status
          , coalesce(t.etl_max_ord_exec_id, -1) as etl_max_ord_exec_id
          , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
        from data_marts.f_ats_cons_details t
        where t.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190408 --
          -- and t.pg_db_create_time > clock_timestamp() - interval '24 hour' -- 1 hour after pasting
          -- and t.pg_dp_last_update_time is not null -- V.I. exclude rows recently added orders
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
          and coalesce(t.order_status, '-1') not in ('2','4')
      ) t
      join lateral
        (
          select ex.exec_text
            , ex.order_status
            , ex.exec_id
          from dwh.execution ex
          where ex.exec_date_id between l_etl_min_date_id and l_cur_date_id -->= l_cur_date_id -- 20190328 --
            and ex.exec_date_id = t.auction_date_id
            and ex.order_id = t.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
    where t.rn=1 and t.etl_max_ord_exec_id <> ex.exec_id
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.3 Lookup descrepancy on Order Status.' , l_row_cnt , 'I')
    into l_step_id;


 -- Step 4. Update calculated status attributes in temp tbl

  -- define min orders create_date_id
  l_min_order_create_date_id := (select min(create_date_id) from staging.ats_cons_details );

 -- Step 4.1. update orders with new status and quality information
  -- using temp table as a source of orders
    update staging.ats_cons_details trg
      set nbbo_bid_price       = md.bid_price
        , nbbo_bid_quantity    = md.bid_quantity
        , nbbo_ask_price       = md.ask_price
        , nbbo_ask_quantity    = md.ask_quantity
        , exec_text            = ex.exec_text
        , filled_price         = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_price else tr_str.filled_price end --  as filled_price
        , filled_qty           = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_qty else tr_str.filled_qty end -- as filled_qty
        , order_status         = ex.order_status
        , principal_amount     = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.principal_amount else tr_str.principal_amount end -- as principal_amount
        , first_fill_date_time = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.first_fill_date_time else tr_str.first_fill_date_time end -- as first_fill_date_time
        , etl_max_ord_exec_id  = ex.exec_id
        , etl_max_ord_trade_tecord_id = coalesce(tr_par.max_trade_record_id, tr_str.max_trade_record_id)
        , etl_max_md_transaction_id = md.transaction_id
        , is_marketable        = case when src.order_type_id = '1' then 'Y'
                                      when src.side in ('1','3') and src.order_price >= md.ask_price then 'Y'
                                      when src.side not in ('1','3') and src.order_price <= md.bid_price then 'Y'
                                      else 'N' end --as is_marketable
        --, pg_dp_last_update_time = clock_timestamp()
   /*   select
            md.bid_price
          , md.bid_quantity
          , md.ask_price
          , md.ask_quantity
          , ex.exec_text  -- just in case somebody wants to uncomment it (SO)
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_price else tr_str.filled_price end --  as filled_price
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_qty else tr_str.filled_qty end -- as filled_qty
          , ex.order_status
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.principal_amount else tr_str.principal_amount end -- as principal_amount
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.first_fill_date_time else tr_str.first_fill_date_time end -- as first_fill_date_time
          , ex.exec_id
          , coalesce(tr_par.max_trade_record_id, tr_str.max_trade_record_id)
          , md.transaction_id  */
    from staging.ats_cons_details as src
      -- market data
      left join lateral
        (
          select md.transaction_id, md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
          from dwh.l1_snapshot md
          where md.start_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190408 --
            and md.start_date_id = src.auction_date_id
            and md.transaction_id = src.transaction_id -- lookup key
            and md.instrument_id = case when md.instrument_id > 0 then src.instrument_id else md.instrument_id end
            and md.exchange_id = 'NBBO'
          limit 1
        ) md on true
      -- the last execution
      left join lateral
        (
          select ex.exec_text
            , ex.order_status
            , ex.exec_id
          from dwh.execution ex
          where ex.exec_date_id between l_etl_min_date_id and l_cur_date_id -->= l_cur_date_id -- 20190328 --
            and ex.exec_date_id = src.auction_date_id
            and ex.order_id = src.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      -- trades for street orders
      left join lateral
        (
          select sum(tr.last_qty) as filled_qty
            , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as filled_price
            , sum(tr.principal_amount) as principal_amount
            , min(tr.trade_record_time) as first_fill_date_time
            , max(tr.trade_record_id) as max_trade_record_id
          from dwh.flat_trade_record tr
          where 1=1
            and ( src.is_lpo_street = true or src.is_ofp_street = true ) -- street level
            and src.order_id = tr.street_order_id
            and tr.date_id between l_min_order_create_date_id and l_cur_date_id-- 20190328 --
            --and tr.date_id = src.auction_date_id
            and tr.is_busted = 'N'
          group by tr.street_order_id
          limit 1
        ) tr_str ON true
      -- trades for parent orders
      left join lateral
        (
          select sum(tr.last_qty) as filled_qty
            , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as filled_price
            , sum(tr.principal_amount) as principal_amount
            , min(tr.trade_record_time) as first_fill_date_time
            , max(tr.trade_record_id) as max_trade_record_id
          from dwh.flat_trade_record tr
          where 1=1 -- try to calculate for both ATS and CONS (maybe CONS will be calculated on the street executions)
            and ( src.is_ofp_parent = true or src.is_lpo_parent = true ) -- try to calc responses also
            and src.order_id = tr.order_id -- parent level
            and tr.date_id between l_min_order_create_date_id and l_cur_date_id -->= l_min_order_create_date_id -- 20190328 --
            --and tr.date_id <= src.auction_date_id
            and tr.is_busted = 'N'
          group by tr.order_id
          limit 1
        ) tr_par ON true
    where 1=1
      and trg.order_id        = src.order_id
      and trg.auction_id      = src.auction_id
      and trg.auction_date_id = src.auction_date_id
      and trg.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190328 --
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '4.1 Market Data and Status updated in tmp.' , l_row_cnt , 'U')
    into l_step_id;

  -- Step 4.2. Recalculation of LPO parent orders(responses) quality
   -- блин, опять же это лучше сделать в темповой таблице, но тогда и статус апдейтать лучше в темповую таблицу
    -- лан, берем из темповой таблицы список ордеров, считаем
    with qlty as
      (
        select o.order_id, o.auction_id, o.auction_date_id
               -- is_quality_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.order_price < o.nbbo_ask_price then true else false end
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.order_price > o.nbbo_bid_price then true else false end
                           end -- end of sell response side
               end as resp_is_quality_response
               -- is_good_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.resp_ofp_parent_order_price is not null -- not market originator's order type
                                         then case when o.resp_ofp_parent_order_price < o.order_price and o.order_price < o.nbbo_ask_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price < o.nbbo_ask_price then true else false end
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.resp_ofp_parent_order_price is not null -- not market originator's order type
                                         then case when o.resp_ofp_parent_order_price > o.order_price and o.order_price > o.nbbo_bid_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price > o.nbbo_bid_price then true else false end
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
               end as resp_is_good_response
               -- is_neutral_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.order_price = o.nbbo_ask_price then true else false end
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.order_price = o.nbbo_bid_price then true else false end
                           end -- end of sell response side
               end as resp_is_neutral_response
               -- is_bad_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.order_price > o.nbbo_ask_price then true else false end
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.order_price < o.nbbo_bid_price then true else false end
                           end -- end of sell response side
               end as resp_is_bad_response
               -- is_great_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.resp_ofp_parent_order_price is not null -- not "market" originator's order type
                                         then case when o.order_price <= o.resp_ofp_parent_order_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price < o.nbbo_ask_price then true else false end -- ? left resp better then NBBO for "market order"??
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.resp_ofp_parent_order_price is not null -- not market originator's order type
                                         then case when o.order_price >= o.resp_ofp_parent_order_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price > o.nbbo_bid_price then true else false end -- ? left resp better then NBBO for "market order"??
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
               end as resp_is_great_response
            -- responce, price improvement %. For ofp buy when resp price = nbb then -100%, when resp price = nbo then 100%, when resp price = mid nbbo then 0%
            /*, case when o.order_qty > 0 and o.nbbo_ask_price is not null and o.nbbo_bid_price is not null
                   then
                       case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy
                              then ( (o.order_price - ((o.nbbo_ask_price + o.nbbo_bid_price)/2))::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                            when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell
                              then ( (((o.nbbo_ask_price + o.nbbo_bid_price)/2) - o.order_price)::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                       end
              end as resp_price_improve_pct*/
            -- responce, price improvement %. For ofp buy when resp price = nbb then 100%, when resp price = nbo then -100%, when resp price = mid nbbo then 0%
             -- should I return to "minus is good"?
             -- For ofp sell when resp price = nbo then 100%, when resp price = nbb then -100%, when resp price = mid nbbo then 0%
            -- if we buy, then good resp sell price should be lesser than midpoint
             -- if we sell, then good resp buy price should be greater than midpoint
            , case
                when
                  round(case when o.order_qty > 0 and o.nbbo_ask_price is not null and o.nbbo_bid_price is not null
                     then
                       case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy, resp sell
                              then ( (((o.nbbo_ask_price + o.nbbo_bid_price)/2) - o.order_price)::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                            when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell, resp buy
                              then ( (o.order_price - ((o.nbbo_ask_price + o.nbbo_bid_price)/2))::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                       end
                    end::numeric, 4)*-1.0 between -100000 and 100000
                then
                  round(case when o.order_qty > 0 and o.nbbo_ask_price is not null and o.nbbo_bid_price is not null
                     then
                       case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy, resp sell
                              then ( (((o.nbbo_ask_price + o.nbbo_bid_price)/2) - o.order_price)::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                            when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell, resp buy
                              then ( (o.order_price - ((o.nbbo_ask_price + o.nbbo_bid_price)/2))::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                       end
                    end::numeric, 4)*-1.0
                else
                  round(case when o.order_qty > 0 and o.nbbo_ask_price is not null and o.nbbo_bid_price is not null
                     then
                       case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy, resp sell
                              then ( (((o.nbbo_ask_price + o.nbbo_bid_price)/2) - o.order_price)::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                            when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell, resp buy
                              then ( (o.order_price - ((o.nbbo_ask_price + o.nbbo_bid_price)/2))::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                       end
                    end::numeric, 4)*-1.0 / 1000
               end as resp_price_improve_pct
            -- size improvement vs nbbo count
            , case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy
                     then case when o.order_qty > o.nbbo_ask_quantity then true else false end
                   when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell
                     then case when o.order_qty > o.nbbo_bid_quantity then true else false end
              end as resp_size_impr_vs_nbbo
            -- size improvement vs nbbo %
            , case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy
                     then (o.order_qty::numeric/nullif(o.nbbo_ask_quantity,0)::numeric)*100
                   when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell
                     then (o.order_qty::numeric/nullif(o.nbbo_bid_quantity,0)::numeric)*100
              end::numeric as resp_size_impr_vs_nbbo_pct
            -- match_qty. Based on executions. exec_type = 'M'
            , mth.resp_match_qty as resp_match_qty
            -- match_px. Based on executions. exec_type = 'M'
            , mth.resp_avg_match_px as resp_avg_match_px
        from staging.ats_cons_details as o
          left join lateral
            (
              select sum(ex.match_qty)::integer as resp_match_qty, (sum(ex.match_qty*ex.match_px)/nullif(sum(ex.match_qty), 0))::numeric as resp_avg_match_px
              from dwh.execution ex
              where ex.order_id = o.order_id
                and ex.exec_date_id = o.auction_date_id
                and ex.exec_type = 'M'
                and ex.exec_date_id between l_etl_min_date_id and l_cur_date_id -->= l_etl_min_date_id -- 20190327 --
              group by ex.order_id
            ) mth ON true
        where o.is_lpo_parent = true
      )
    update staging.ats_cons_details trg
      set resp_is_quality_response   = src.resp_is_quality_response
        , resp_is_good_response      = src.resp_is_good_response
        , resp_is_neutral_response   = src.resp_is_neutral_response
        , resp_is_bad_response       = src.resp_is_bad_response
        , resp_is_great_response     = src.resp_is_great_response
        , resp_price_improve_pct     = src.resp_price_improve_pct
        , resp_size_impr_vs_nbbo     = src.resp_size_impr_vs_nbbo
        , resp_size_impr_vs_nbbo_pct = src.resp_size_impr_vs_nbbo_pct
        , resp_match_qty             = src.resp_match_qty
        , resp_avg_match_px          = src.resp_avg_match_px
    from qlty as src
    where 1=1
      and trg.order_id        = src.order_id
      and trg.auction_id      = src.auction_id
      and trg.auction_date_id = src.auction_date_id
      and trg.auction_date_id = l_cur_date_id -- 20190328 --
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '4.2 Responses Quality updated in tmp.' , l_row_cnt , 'U')
    into l_step_id;


 -- Step 5. Add the increment + recalc into the datamart.
 -- Step 5.1. Merge the increment into the datamart. (update status, MD, quality if orders are existing)
  with src as
   (
    select
        auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , case when is_ats = true then 'A' when is_cons = true then 'C' end as is_ats_or_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , null::integer as ofp_parent_auctions_no
      , t.order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , t.instrument_id
      , i.instrument_type_id
      , i.display_instrument_id as display_instrument_id
      , ui.symbol as underlying_symbol
      , os.root_symbol as root_symbol
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , resp_ofp_parent_order_side
      , resp_ofp_parent_order_price
      -- other ETLs entities
      , nbbo_bid_price
      , nbbo_bid_quantity
      , nbbo_ask_price
      , nbbo_ask_quantity
      , exec_text as text_
      , filled_price
      , filled_qty
      , order_status
      , principal_amount
      , first_fill_date_time
      , etl_max_ord_exec_id
      , etl_max_ord_trade_tecord_id
      , etl_max_md_transaction_id
      , is_marketable
      , resp_is_quality_response
      , resp_is_good_response
      , resp_is_neutral_response
      , resp_is_bad_response
      , resp_is_great_response
      , resp_price_improve_pct
      , resp_size_impr_vs_nbbo
      , resp_size_impr_vs_nbbo_pct
      , resp_match_qty
      , resp_avg_match_px
      , t.exch_order_id
      , t.exec_instruction
      , t.strategy_decision_reason_code
      , t.capacity_group_id
    from staging.ats_cons_details t
      left join dwh.d_instrument i
        ON t.instrument_id = i.instrument_id
      left join dwh.d_option_contract oc
        ON t.instrument_id = oc.instrument_id
      left join dwh.d_option_series os
        ON oc.option_series_id = os.option_series_id
      left join dwh.d_instrument ui
        ON os.underlying_instrument_id = ui.instrument_id
    where t.multileg_reporting_type in ('1','2') -- in temp we also have '3' -- multilegs
      and t.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190408 --
     -- order by ofp_orig_order_id, auction_id, order_id
   )
   --select count(1) from src
    INSERT INTO data_marts.f_ats_cons_details
      ( auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats_or_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , ofp_parent_auctions_no
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , instrument_type_id
      , display_instrument_id
      , underlying_symbol
      , root_symbol
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , resp_ofp_parent_order_side
      , resp_ofp_parent_order_price
      -- other ETLs entities
      , nbbo_bid_price
      , nbbo_bid_quantity
      , nbbo_ask_price
      , nbbo_ask_quantity
      , text_
      , filled_price
      , filled_qty
      , order_status
      , principal_amount
      , first_fill_date_time
      , etl_max_ord_exec_id
      , etl_max_ord_trade_tecord_id
      , etl_max_md_transaction_id
      , is_marketable
      , resp_is_quality_response
      , resp_is_good_response
      , resp_is_neutral_response
      , resp_is_bad_response
      , resp_is_great_response
      , resp_price_improve_pct
      , resp_size_impr_vs_nbbo
      , resp_size_impr_vs_nbbo_pct
      , resp_match_qty
      , resp_avg_match_px
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select * from src
    ON CONFLICT(auction_date_id, auction_id, order_id)
      DO UPDATE SET
          nbbo_bid_price              = EXCLUDED.nbbo_bid_price
        , nbbo_bid_quantity           = EXCLUDED.nbbo_bid_quantity
        , nbbo_ask_price              = EXCLUDED.nbbo_ask_price
        , nbbo_ask_quantity           = EXCLUDED.nbbo_ask_quantity
        , text_                   = EXCLUDED.text_
        , filled_price                = EXCLUDED.filled_price
        , filled_qty                  = EXCLUDED.filled_qty
        , order_status                = EXCLUDED.order_status
        , principal_amount            = EXCLUDED.principal_amount
        , first_fill_date_time        = EXCLUDED.first_fill_date_time
        , etl_max_ord_exec_id         = EXCLUDED.etl_max_ord_exec_id
        , etl_max_ord_trade_tecord_id = EXCLUDED.etl_max_ord_trade_tecord_id
        , etl_max_md_transaction_id   = EXCLUDED.etl_max_md_transaction_id
        , is_marketable               = EXCLUDED.is_marketable
        , resp_is_quality_response    = EXCLUDED.resp_is_quality_response
        , resp_is_good_response       = EXCLUDED.resp_is_good_response
        , resp_is_neutral_response    = EXCLUDED.resp_is_neutral_response
        , resp_is_bad_response        = EXCLUDED.resp_is_bad_response
        , resp_is_great_response      = EXCLUDED.resp_is_great_response
        , resp_price_improve_pct      = EXCLUDED.resp_price_improve_pct
        , resp_size_impr_vs_nbbo      = EXCLUDED.resp_size_impr_vs_nbbo
        , resp_size_impr_vs_nbbo_pct  = EXCLUDED.resp_size_impr_vs_nbbo_pct
        , resp_match_qty              = EXCLUDED.resp_match_qty
        , resp_avg_match_px           = EXCLUDED.resp_avg_match_px
        , pg_dp_last_update_time      = clock_timestamp()
        , liquidity_provider_id       = EXCLUDED.liquidity_provider_id
        , ofp_orig_order_id           = EXCLUDED.ofp_orig_order_id
        , is_ats_or_cons              = EXCLUDED.is_ats_or_cons
        , is_ofp_parent               = EXCLUDED.is_ofp_parent
        , is_ofp_street               = EXCLUDED.is_ofp_street
        , is_lpo_parent               = EXCLUDED.is_lpo_parent
        , is_lpo_street               = EXCLUDED.is_lpo_street
        , exch_order_id               = EXCLUDED.exch_order_id
        , exec_instruction               = EXCLUDED.exec_instruction
        , strategy_decision_reason_code  = EXCLUDED.strategy_decision_reason_code
        , capacity_group_id				 = EXCLUDED.capacity_group_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '5.1 Increment loaded into the datamart: data_marts.f_ats_cons_details.' , l_row_cnt , 'I')
    into l_step_id;


    with source as materialized
    --select * count(1) from
      (
        select s.order_id, s.auction_date_id, s.is_ats_or_cons, ts.auction_id, ts.ofp_parent_auctions_no_new
        from
          (
            select s.order_id, s.auction_date_id, s.is_ats_or_cons, count(1)
            from data_marts.f_ats_cons_details s
                 --tmp_ats_cons_details s
            where s.is_ofp_parent = true
              and s.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190328 -- processing auction_date_id  --
              and s.ofp_parent_auctions_no is null -->> column is not present in temp
            group by s.order_id, s.auction_date_id, s.is_ats_or_cons -- distinct
            limit 50000000
          ) s
          inner join lateral
            (
              select t.auction_date_id, t.order_id, t.auction_id
                , row_number() over (partition by t.auction_date_id, t.order_id order by t.auction_id) as ofp_parent_auctions_no_new
              from data_marts.f_ats_cons_details t
              where t.is_ofp_parent = true
                and t.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id -- 20190328 -- processing auction_date_id --
                and t.auction_date_id = s.auction_date_id
                and t.is_ats_or_cons = s.is_ats_or_cons
                and t.order_id = s.order_id
              limit 50000 -- up to 10k auctions limitation per one OFP parent order per day.
            ) ts ON true
      ) -- s
    , upd as
      (
        update data_marts.f_ats_cons_details trg
          set ofp_parent_auctions_no = src.ofp_parent_auctions_no_new
        from source src
        where trg.auction_date_id = src.auction_date_id
          and trg.auction_date_id between l_etl_min_date_id and l_cur_date_id --= l_cur_date_id --
          and trg.auction_id = src.auction_id
          and trg.order_id = src.order_id
          and trg.is_ats_or_cons = src.is_ats_or_cons
          --and coalesce(trg.ofp_parent_auctions_no, -1) <> src.ofp_parent_auctions_no_new
          and trg.is_ofp_parent = true
        returning trg.auction_id
      )
    select count(1) into l_row_cnt
    from upd
    ;
    --GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '5.2 Numeration of "ofp_parent_auctions_no" field completed.' , l_row_cnt , 'U')
    into l_step_id;

 -- Step 6. Recalculation of all auctions analytics and stats for OFP parent orders.
  -- analytics will only be present in the "ats_cons_stats" datamart. here. in the next steps.

 -- Step 7. Close processed subsctiptions
   update public.etl_subscriptions
    set is_processed = true,
        process_time = clock_timestamp()
    where load_batch_id = ANY(l_load_batch_arr) --subs_cursor.load_batch_id
      and not is_processed
      and subscription_name in ( 'ats_details' )
      and source_table_name ='dmp.client_order2auction' ;
  GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'load_batches to close subscriptions : '||coalesce(left(array_to_string(l_load_batch_arr, ','),200)::varchar,' '::varchar) , l_row_cnt , 'U')
   into l_step_id;

END IF; -- there is no data to process




---------------------------------------------------------------------------------------------------------
  select public.load_log(l_load_id, l_step_id, 'load_ats_cons_inc COMPLETE ========= ' , 0, 'O')
   into l_step_id;
  RETURN 1;

exception when others then
  select public.load_log(l_load_id, l_step_id, sqlerrm , 0, 'E')
  into l_step_id;
   PERFORM public.load_error_log('load_ats_cons_inc',  'I', sqlerrm, l_load_id);

  RAISE;

END;
$function$
;


SELECT * FROM data_marts.so_load_ats_cons_inc();

SELECT *
FROM dwh.request_for_quote AS rfq
WHERE auction_date_id = 20250228;

select *
from data_marts.f_rfq_details q
WHERE auction_date_id = 20250228;

select * from staging.ats_cons_details;

select * from tmp_rfq_missed_md;
select * from tmp_rfq_missed_md_v2;


select q.liquidity_provider_id,
       q.auction_id,
       q.rfq_transact_time,
       q.rfq_quote_type,
       q.rfq_min_response_qty * coalesce(q.rfq_ratio_qty, 1)                    as MIN_RESPONSE_QTY,
       --q.ofp_order_qty*coalesce(q.rfq_ratio_qty,1) as ORDER_QTY,
       q.rfq_qty::bigint                                                        as ORDER_QTY, -- https://dashfinancial.atlassian.net/browse/DS-5177
       q.rfq_fix_message_id, /* OFP/RFQ ???*/
       q.rfq_multileg_reporting_type,
       --q.ofp_side,
       case when q.ofp_side = 'B' then q.rfq_multi_leg_side else q.ofp_side end as ofp_side,  -- changed to be able to display legs sides
       q.rfq_instrument_id,
       i.display_instrument_id2                                                 as display_instrument_id,
       i.instrument_type_id,
       q.rfq_transaction_id,
       q.ofp_account_id,
       q.rfq_leg_id
, q.auction_date_id
,q.ofp_order_id
from data_marts.f_rfq_details q
         left join dwh.d_instrument i on (q.rfq_instrument_id = i.instrument_id)
where true
and      q.auction_id = :in_auction_id
  and q.auction_date_id = :l_auction_date_id
  and case when l_ofp_orig_order_id is null then true else q.ofp_order_id = l_ofp_orig_order_id end;


select * from dash360.ats_quotes_requests(in_auction_id := 290007787166, in_order_id := 16868013621)

select distinct ofp_orig_order_id, auction_date_id, ats.auction_id, ats.order_id
--     into l_ofp_orig_order_id, l_auction_date_id
    from data_marts.f_ats_cons_details ats
     where true
    and ats.order_id = :in_order_id
    and ats.auction_id = :in_auction_id
    and auction_date_id >= l_order_date_id;
         Executing procedure:("dash360.ats_quotes_requests"). Parameters: "@in_auction_id=7790001973844; @in_order_id=292739327434480262; "