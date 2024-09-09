update trash.so_fix_execution_column_text_
set new_script = $insert$

CREATE OR REPLACE FUNCTION data_marts.load_ats_cons_inc_rc(in_order_ids bigint[] DEFAULT NULL::bigint[], in_recalc_date_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
DECLARE
   l_row_cnt integer;

   l_load_id int;
   l_step_id int;

   l_orig_order_ids bigint[];
   l_load_batch_arr integer[];

   l_cur_date_id integer;
   l_gtc_min_date_id integer;
   l_etl_min_date_id integer;
   l_min_order_create_date_id integer;

   l_foreign_order_id bigint;
   l_local_order_id bigint;
   l_local_rfq_id  bigint;

   l_sql varchar;

BEGIN
  /*
    we don't need to run this AFTER the HODS processed.
  */
  select nextval('public.load_timing_seq') into l_load_id;

  l_step_id:=1;

  select public.load_log(l_load_id, l_step_id, 'load_ats_cons_inc STARTED===', 0, 'O')
   into l_step_id;


   -- Variables definition
   l_cur_date_id   := coalesce(in_recalc_date_id, to_char(current_date, 'YYYYMMDD')::integer);
   l_etl_min_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '1 day', 'YYYYMMDD')::integer;
   l_gtc_min_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '30 days', 'YYYYMMDD')::integer;


  -- Temporary table definition

     execute 'CREATE TEMP TABLE IF NOT EXISTS stg_tmp_ats_cons_details (
      dataset_id int8 NULL, -- from subscription
      auction_id int8 NULL, -- NK #1. Auction ID.
      auction_date_id int4 NULL,
      liquidity_provider_id varchar(9) NULL, -- Defined via FIX_CONNECTION and FIX_COMP_ID. Used for LPO orders.
      ofp_orig_order_id int8 NULL, -- order_id of auctions initiating OFP parent order. For multileg, mlrt of such ord = ''3'' and side = ''B''

      -- markers of orders groups
      is_ats bool NULL,
      is_cons bool NULL,
      --
      is_ofp_parent bool NULL, -- OFP originating parent orders.
      is_ofp_street bool NULL, -- OFP created crosses
      is_lpo_parent bool NULL, -- LPO responces
      is_lpo_street bool NULL, -- LPO created crosses

      -- order info
      order_id int8 NOT NULL,
      client_order_id varchar(256) NULL,
      parent_order_id int8 NULL,
      order_create_time timestamp without time zone NULL,
      order_price numeric(12,4) NULL,
      order_qty int4 NULL,
      order_type_id varchar(1) NULL,
      account_id int8 NULL,
      instrument_id int8 NULL,
      transaction_id int8 NULL,
      side varchar(1) NULL,
      multileg_reporting_type varchar(1) NULL, -- including mlrt=3 in temp.
      cross_order_id int8 NULL,
      client_id varchar(255) NULL,
      exchange_id varchar(6) NULL,
      fix_connection_id int4 NULL,
      fix_comp_id varchar(30) NULL,
      internal_component_type varchar(1) NULL,
      sub_system_id varchar(20) NULL,
      order_liquidity_provider_id varchar(9) NULL,

      -- prepare some attributes for resp quality calculation
      resp_ofp_parent_order_side varchar(1) NULL,
      resp_ofp_parent_order_price numeric(12,4) NULL,
      CONSTRAINT "_PK_tmp_ats_cons" PRIMARY KEY (order_id, auction_id)
    )';

  execute 'truncate table stg_tmp_ats_cons_details';

  execute 'truncate table staging.stg_tmp_ats_cons_details'; -- for testing purpose



---------------------------------------------------------------------------------------------------------
 if in_recalc_date_id is null  -- for test purpose
 then
 --1) Step 1.1.  f_rfq_details. incremental load

  -->> calculate max rfq_id we have on PG side.
    -- 1-st execution on the next day should find all gaps if they'll be found...
     l_local_rfq_id   := (select coalesce(max(q.rfq_id), -1) as local_rfq_id
                          from data_marts.f_rfq_details q
                          where q.auction_date_id = l_cur_date_id);

    select public.load_log(l_load_id, l_step_id, 'Step 1.1. f_rfq_details. date_id = '||l_cur_date_id::varchar||', l_local_rfq_id = '||l_local_rfq_id::varchar||', load_batch_id = '||l_load_id::varchar, 0 , 'O')
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
      , to_timestamp(v.create_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as ofp_create_time
      , ORDER_TYPE as ofp_order_type
      , SIDE as ofp_side
      , ORDER_QTY as ofp_order_qty
      , PRICE as ofp_order_price
      , CO_CLIENT_LEG_REF_ID as ofp_leg_ref_id
      , ACCOUNT_ID as ofp_account_id
      , SUB_SYSTEM_ID as ofp_sub_system_id
      , SUB_STRATEGY as ofp_sub_strategy
      , INTERNAL_COMPONENT_TYPE as ofp_internal_component_type
      , CLIENT_ID as ofp_client_id
      , requested_qty as rfq_qty
      , requested_multi_leg_side as rfq_multi_leg_side
      , MULTILEG_REPORTING_TYPE as rfq_multileg_reporting_type
      , to_timestamp(v.rfq_transact_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as rfq_transact_time
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
            and md.instrument_id = case when md.instrument_id > 0 then v.instrument_id else md.instrument_id end --v.instrument_id
            and md.exchange_id = 'NBBO'
            and md.start_date_id between l_etl_min_date_id and l_cur_date_id
            --and md.start_date_id = v.auction_date_id::integer
          limit 1
        ) md on true
     where 1=1
       and v.RFQ_ID >= l_local_rfq_id
       and v.auction_date_id::integer >= l_etl_min_date_id
       and not exists
      (
        select r.rfq_leg_id
        from data_marts.f_rfq_details r
        where r.auction_date_id = v.auction_date_id::integer -- unq idx used
          and r.auction_date_id >= l_etl_min_date_id
          and r.rfq_leg_id = v.rfq_leg_id
      )
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'inserted into data_marts.f_rfq_details  ', l_row_cnt , 'I')
     into l_step_id;

 --1) Step 1.2.  f_rfq_details. Missing Market Data lookup

   -- lookup into the orders array and at the end of procedure - invoke manual run for these orders
   l_orig_order_ids := array(
    select distinct q.ofp_order_id -- parent_originator order
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
      and q.is_maket_data_applied is null
      and q.rfq_transaction_id is not null
      -- and limitation to not process orders older than 1 hour
    )
    ;

  select public.load_log(l_load_id, l_step_id, 'Step 1.2. Look for missing Market data for RFQ', cardinality(l_orig_order_ids) , 'I')
     into l_step_id;

   --1) Step 1.3.  f_rfq_details. Manual run. Missing Market Data update.
    -- in this peculiar case we don't need merge. Simple Update will be enough.

 if cardinality(l_orig_order_ids) > 0 -- and in_manual_run

  then
    update data_marts.f_rfq_details trg
      set rfq_nbbo_bid_price    = s.bid_price
        , rfq_nbbo_bid_quantity = s.bid_quantity
        , rfq_nbbo_ask_price    = s.ask_price
        , rfq_nbbo_ask_quantity = s.ask_quantity
        , is_maket_data_applied = true
    from
      (
          select q.auction_date_id, q.rfq_leg_id, q.rfq_id
            , md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
            , case when md.transaction_id > 0 then true end as is_maket_data_applied
          from data_marts.f_rfq_details q
            join dwh.l1_snapshot md
              on md.transaction_id = q.rfq_transaction_id
              and md.instrument_id = case when md.instrument_id > 0 then v.instrument_id else md.instrument_id end --v.instrument_id
              and md.exchange_id = 'NBBO'
              and md.start_date_id between l_etl_min_date_id and l_cur_date_id
          where q.auction_date_id between l_etl_min_date_id and l_cur_date_id
            and q.ofp_order_id = any (l_orig_order_ids)
            and md.start_date_id = q.auction_date_id
          limit 1
      ) s
    where trg.auction_date_id between l_etl_min_date_id and l_cur_date_id
      and trg.is_maket_data_applied is null
      and trg.auction_date_id = s.auction_date_id
      and trg.rfq_leg_id = s.rfq_leg_id
      and trg.rfq_id = s.rfq_id
    ;

  end if;



 else -- for test purpose, if in_recalc_date_id is not null  - try to calculate the datamart

 -- Step 2 Increment definition and calculations into the Temp table
 -- Step 2.1.  ATS + CONS subscriptions load

  l_load_batch_arr := array (select distinct load_batch_id
                             from public.etl_subscriptions
                             where 1=1
                               and subscription_name in ( 'ats_details' )
                               and source_table_name ='client_order2auction'
                               and not is_processed
                               and subscribe_time < now() - interval '15 seconds'
                               and subscribe_time > to_timestamp(l_cur_date_id::varchar, 'YYYYMMDD')
                             order by load_batch_id
                             limit 1
                            );

  select public.load_log(l_load_id, l_step_id, left('2.1. ATS_CONS_details load_batch_id array loaded: '||array_to_string(l_load_batch_arr,','), 200), cardinality(l_load_batch_arr), 'I')
   into l_step_id;

IF cardinality(l_load_batch_arr) > 0
then
 -- Step 2.2.  ATS + CONS auctions load from source
  -- load auctions, not orders. We need to complete CONS auctions with OFP parent orders. And need to set the ofp_orig_order_id value
    INSERT INTO staging.stg_tmp_ats_cons_details
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
      , order_liquidity_provider_id)
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
      , to_timestamp(v.order_create_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as order_create_time
      , left(v.order_create_time, 8)::integer as create_date_id
      , v.order_price
      , v.order_qty
      , v.order_type_id
      , v.account_id
      , v.instrument_id
      , v.transaction_id
      , v.side
      , v.multileg_reporting_type
      , v.cross_order_id
      , v.client_id
      , v.exchange_id
      , v.fix_connection_id
      , v.fix_comp_id
      , v.internal_component_type
      , v.sub_system_id
      , v.order_liquidity_provider_id
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
    ON CONFLICT (order_id, auction_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.2 ATS + CONS loaded from source into TMP' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 2.3.  CONS lookup OFP parent orders
   -- Search for OFP parents via Consolidator OFP Streets
     -- we don't have CONS OFP parents in client_order2auction yet.
       -- in TMP we have whole auctions represented, so lookup of OFP parents will not take extra efforts.
    with cons_par as
      (
        select t.parent_order_id, t.auction_id, t.auction_date_id
        from staging.stg_tmp_ats_cons_details t
        where t.is_cons = true
          and t.is_ofp_street = true
        group by t.parent_order_id, t.auction_id, t.auction_date_id
        order by t.parent_order_id, t.auction_id
      )
    INSERT INTO staging.stg_tmp_ats_cons_details
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
      , order_liquidity_provider_id)
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
      , ofp.client_id
      , ofp.exchange_id
      , ofp.fix_connection_id
      , null as fix_comp_id
      , ofp.internal_component_type
      , ss.sub_system_id
      , ofp.liquidity_provider_id as order_liquidity_provider_id
    from cons_par p
      join dwh.client_order ofp
        ON p.parent_order_id = ofp.order_id
      left join dwh.d_sub_system ss
        ON ofp.sub_system_unq_id = ss.sub_system_unq_id
    ON CONFLICT (order_id, auction_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.3 CONS OFP parent orders loaded' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 2.4.  CONS set the ofp_orig_order_id attribte.
   -- it is needed for CONS sources. ATS already has ofp_orig_order_id initiated via RFQ on the ORA source view
     -- for multilegs it = order_id of OFP multileg parent order (mlrt=3)
    update staging.stg_tmp_ats_cons_details t
      set ofp_orig_order_id = src.ofp_orig_order_id
    from
      (
        select s.auction_id, min(s.order_id) as ofp_orig_order_id
        from staging.stg_tmp_ats_cons_details s
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

    update staging.stg_tmp_ats_cons_details trg
      set resp_ofp_parent_order_side = src.side
        , resp_ofp_parent_order_price = src.order_price
    from
      (
        select ofp.ofp_orig_order_id, ofp.auction_id, ofp.auction_date_id, ofp.instrument_id
          , ofp.order_price, ofp.side
        from staging.stg_tmp_ats_cons_details ofp
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
  -- As fon now we have prepared increment withous statuses and market data
   --
 -- Step 3.1. Lookup descrepancy on filled price, filled qty - from trades or f_yield_capture
    -- insert into the same temp table
    insert into staging.stg_tmp_ats_cons_details
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
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
       --, t.filled_qty
       --, tr.day_cum_qty
    from
      (
        select t.auction_date_id, t.order_id, coalesce(t.filled_qty, 0) as filled_qty
          , t.auction_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.order_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
        from data_marts.f_ats_cons_details t
        where t.auction_date_id = l_cur_date_id --
          --and t.pg_db_create_time > clock_timestamp() - interval '48 hour' -- 1 hour after pasting
          --and t.pg_dp_last_update_time is not null -- V.I. exclude rows revently added
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
      ) t
      left join lateral
        (
          select tr.order_id, sum(tr.last_qty) as day_cum_qty
          from dwh.flat_trade_record tr
          where tr.date_id = l_cur_date_id --  20190328 --
            and tr.date_id = t.auction_date_id
            and ( (tr.order_id = t.order_id and (is_ofp_parent = true or is_lpo_parent = true))
                or (tr.street_order_id = t.order_id and (is_ofp_street = true or is_lpo_street = true)) )
          group by tr.order_id
        ) tr on true
    where t.rn=1 and t.filled_qty <> coalesce(tr.day_cum_qty, 0)
    ON CONFLICT (order_id, auction_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.1 Lookup descrepancy on filled_price and filled qty.' , l_row_cnt , 'I')
    into l_step_id;


 -- Step 3.2. market data descrepancy - from l1_snapshot or maybe f_yield_capture
    insert into staging.stg_tmp_ats_cons_details
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
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
    --select count(1)
    from
      (
        select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.auction_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
        from data_marts.f_ats_cons_details t
        where t.auction_date_id = l_cur_date_id -- 20190408 --
          -- and t.pg_db_create_time > clock_timestamp() - interval '24 hour' -- 1 hour after pasting
          -- and t.pg_dp_last_update_time is not null -- V.I. exclude rows recently added orders
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
          and t.etl_max_md_transaction_id is null
      ) t
      join lateral
        (
          select md.transaction_id
          from dwh.l1_snapshot md
          where md.start_date_id = l_cur_date_id -- 20190408 --
            and md.start_date_id = t.auction_date_id
            and md.transaction_id = t.transaction_id
            and md.exchange_id = 'NBBO'
          limit 1
        ) md on true
    where t.rn=1
    ON CONFLICT (order_id, auction_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.2 Lookup descrepancy on Market Data.' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 3.3. order status descrepancy - from execution
    insert into staging.stg_tmp_ats_cons_details
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
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
    --select count(1)
    from
      (
        select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.auction_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
          , coalesce(t.order_status, '-1') as order_status
          , coalesce(t.etl_max_ord_exec_id, -1) as etl_max_ord_exec_id
        from data_marts.f_ats_cons_details t
        where t.auction_date_id = l_cur_date_id -- 20190408 --
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
          where ex.exec_date_id = l_cur_date_id -- 20190328 --
            and ex.exec_date_id = t.auction_date_id
            and ex.order_id = t.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
    where t.rn=1 and t.etl_max_ord_exec_id <> ex.exec_id
    ON CONFLICT (order_id, auction_id) DO NOTHING
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.3 Lookup descrepancy on Order Status.' , l_row_cnt , 'I')
    into l_step_id;


 -- Step 4. Update calculated status attributes in temp tbl

  -- define min orders create_date_id
  l_min_order_create_date_id := (select min(create_date_id) from staging.stg_tmp_ats_cons_details );

 -- Step 4.1. update orders with new status and quality information
  -- using temp table as a source of orders
    update staging.stg_tmp_ats_cons_details trg
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
          , ex.exec_text
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_price else tr_str.filled_price end --  as filled_price
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_qty else tr_str.filled_qty end -- as filled_qty
          , ex.order_status
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.principal_amount else tr_str.principal_amount end -- as principal_amount
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.first_fill_date_time else tr_str.first_fill_date_time end -- as first_fill_date_time
          , ex.exec_id
          , coalesce(tr_par.max_trade_record_id, tr_str.max_trade_record_id)
          , md.transaction_id  */
    from staging.stg_tmp_ats_cons_details as src
      -- market data
      left join lateral
        (
          select md.transaction_id, md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
          from dwh.l1_snapshot md
          where md.start_date_id = l_cur_date_id -- 20190408 --
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
          where ex.exec_date_id = l_cur_date_id -- 20190328 --
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
            and tr.date_id >= l_min_order_create_date_id -- 20190328 --
            and tr.date_id <= src.auction_date_id
            and tr.is_busted = 'N'
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
            and tr.date_id >= l_min_order_create_date_id -- 20190328 --
            and tr.date_id <= src.auction_date_id
            and tr.is_busted = 'N'
        ) tr_par ON true
    where 1=1
      and trg.order_id        = src.order_id
      and trg.auction_id      = src.auction_id
      and trg.auction_date_id = src.auction_date_id
      and trg.auction_date_id = l_cur_date_id -- 20190328 --
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
            , case when o.order_qty > 0 and o.nbbo_ask_price is not null and o.nbbo_bid_price is not null
                   then
                       case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy
                              then ( (o.order_price - ((o.nbbo_ask_price + o.nbbo_bid_price)/2))::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                            when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell
                              then ( (((o.nbbo_ask_price + o.nbbo_bid_price)/2) - o.order_price)::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                       end
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
        from staging.stg_tmp_ats_cons_details as o
          left join lateral
            (
              select sum(ex.match_qty)::integer as resp_match_qty, (sum(ex.match_qty*ex.match_px)/nullif(sum(ex.match_qty), 0))::numeric as resp_avg_match_px
              from dwh.execution ex
              where ex.order_id = o.order_id
                and ex.exec_date_id = o.auction_date_id
                and ex.exec_type = 'M'
                and ex.exec_date_id >= l_etl_min_date_id -- 20190327 --
              group by ex.order_id
            ) mth ON true
        where o.is_lpo_parent = true
      )
    update staging.stg_tmp_ats_cons_details trg
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
      , exec_text
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
    from staging.stg_tmp_ats_cons_details t
      left join dwh.d_instrument i
        ON t.instrument_id = i.instrument_id
      left join dwh.d_option_contract oc
        ON t.instrument_id = oc.instrument_id
      left join dwh.d_option_series os
        ON oc.option_series_id = os.option_series_id
      left join dwh.d_instrument ui
        ON os.underlying_instrument_id = ui.instrument_id
    where t.multileg_reporting_type in ('1','2') -- in temp we also have '3' -- multilegs
      and t.auction_date_id = l_cur_date_id -- 20190408 --
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
      , exec_text
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
      , resp_avg_match_px)
    select * from src
    ON CONFLICT(auction_date_id, auction_id, order_id)
      DO UPDATE SET
          nbbo_bid_price              = EXCLUDED.nbbo_bid_price
        , nbbo_bid_quantity           = EXCLUDED.nbbo_bid_quantity
        , nbbo_ask_price              = EXCLUDED.nbbo_ask_price
        , nbbo_ask_quantity           = EXCLUDED.nbbo_ask_quantity
        , exec_text                   = EXCLUDED.exec_text
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
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '5.1 Increment loaded into the datamart: data_marts.f_ats_cons_details.' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 5.2. Renumerate OFP parent orders occurences on auctions.
    with src as
      (
        select t.auction_date_id, t.auction_id, t.order_id, ofp_parent_auctions_no_new
        from
          (
            select distinct s.order_id, s.auction_date_id
            from --data_marts.f_ats_cons_details s
                 staging.stg_tmp_ats_cons_details s
            where s.is_ofp_parent = true
              and s.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id  --
              --and s.ofp_parent_auctions_no is null
          ) s
          left join lateral
            (
              select t.auction_date_id, t.auction_id, t.order_id
                , row_number() over (partition by t.order_id order by t.auction_id) as ofp_parent_auctions_no_new
              from data_marts.f_ats_cons_details t
              where t.is_ofp_parent = true
                and t.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id --
                and t.auction_date_id = s.auction_date_id
                and t.order_id = s.order_id
              limit 10000 -- up to 10k auctions limitation per one OFP parent order per day.
            ) t ON true
      )
    update data_marts.f_ats_cons_details trg
      set ofp_parent_auctions_no = src.ofp_parent_auctions_no_new
    from src
    where trg.auction_date_id = src.auction_date_id
      and trg.auction_date_id = l_cur_date_id --
      and trg.auction_id = src.auction_id
      and trg.order_id = src.order_id
      and coalesce(trg.ofp_parent_auctions_no, -1) <> src.ofp_parent_auctions_no_new
      and trg.is_ofp_parent = true
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

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
      and source_table_name ='client_order2auction' ;
  GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'load_batches to close subscriptions : '||left(array_to_string(l_load_batch_arr, ','),200) , l_row_cnt , 'U')
   into l_step_id;

END IF; -- there are not processed load_batch_ids

end if; -- fork between rfq and ats_cons datamart calculation based on presence of in_recalc_date_id parameter


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


    $insert$
where true
  and routine_schema = 'data_marts'
  and routine_name = 'load_ats_cons_inc_rc'
  and new_script is null;