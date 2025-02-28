select * from staging.ats_rfq_daily_v;
drop view staging.ats_rfq_daily_v;
create view staging.ats_rfq_daily_v
            (rfq_leg_id, rfq_id, auction_id, auction_date_id, rfq_ofp_order_id, rfq_fix_connection_id, requested_qty,
             quote_type, min_response_qty, multileg_reporting_type, rfq_transact_time, rfq_fix_message_id,
             rfq_transaction_id, requested_instrument_id, requested_multi_leg_side, ratio_qty, client_order_id,
             create_time, order_type_id, side, instrument_id, order_qty, price, fix_message_id, account_id,
             sub_system_id, fix_connection_id, fix_comp_id, client_id_text, rfq_fix_comp_id, rfq_liquidity_provider_id,
             is_ats_ofp_parent, is_consolidator_ofp_parent, sub_strategy_id, order_transaction_id)
as
SELECT rl.rfq_leg_id,
       r.rfq_id,
       r.auction_id,
--        to_char(r.transact_time, 'YYYYMMDD'::text)::integer AS auction_date_id,
       r.auction_date_id,
       r.parent_order_id                                   AS rfq_ofp_order_id,
       r.fix_connection_id                                 AS rfq_fix_connection_id,
       r.order_qty                                         AS requested_qty,
       r.quote_type,
       r.min_response_qty,
       r.multileg_reporting_type,
       r.transact_time                                     AS rfq_transact_time,
       r.fix_message_id                                    AS rfq_fix_message_id,
       r.transaction_id                                    AS rfq_transaction_id,
       rl.instrument_id                                    AS requested_instrument_id,
       rl.side                                             AS requested_multi_leg_side,
       rl.ratio_qty,
       o.client_order_id,
       o.create_time,
       o.order_type_id,
       o.side,
       o.instrument_id,
       o.order_qty,
       o.price,
       o.fix_message_id,
       o.account_id,
       dss.sub_system_id,
       o.fix_connection_id,
       fc_ord.fix_comp_id,
       o.client_id_text,
       fc_rfq.fix_comp_id                                  AS rfq_fix_comp_id,
       lpi.liquidity_provider_id                           AS rfq_liquidity_provider_id,
       CASE
           WHEN dss.sub_system_id::text !~~ '%CONS%'::text THEN true
           ELSE false
           END                                             AS is_ats_ofp_parent,
       CASE
           WHEN dss.sub_system_id::text ~~ '%CONS%'::text THEN true
           ELSE false
           END                                             AS is_consolidator_ofp_parent,
       o.sub_strategy_id,
       o.transaction_id                                    AS order_transaction_id
FROM dwh.request_for_quote r
         JOIN dwh.request_for_quote_leg rl ON r.rfq_id = rl.rfq_id
         LEFT JOIN LATERAL ( SELECT o_1.order_id,
                                    o_1.client_order_id,
                                    o_1.create_time,
                                    o_1.order_type_id,
                                    o_1.side,
                                    o_1.instrument_id,
                                    o_1.order_qty,
                                    o_1.price,
                                    o_1.fix_message_id,
                                    o_1.account_id,
                                    o_1.fix_connection_id,
                                    o_1.client_id_text,
                                    o_1.sub_system_unq_id,
                                    o_1.sub_strategy_id,
                                    o_1.transaction_id
                             FROM dwh.client_order o_1
                             WHERE r.parent_order_id = o_1.order_id
                               AND r.auction_date_id = o_1.create_date_id
                               AND (o_1.time_in_force_id <> ALL (ARRAY ['1'::bpchar, '6'::bpchar]))
                             UNION ALL
                             SELECT o_1.order_id,
                                    o_1.client_order_id,
                                    o_1.create_time,
                                    o_1.order_type_id,
                                    o_1.side,
                                    o_1.instrument_id,
                                    o_1.order_qty,
                                    o_1.price,
                                    o_1.fix_message_id,
                                    o_1.account_id,
                                    o_1.fix_connection_id,
                                    o_1.client_id_text,
                                    o_1.sub_system_unq_id,
                                    o_1.sub_strategy_id,
                                    o_1.transaction_id
                             FROM dwh.client_order o_1
                             WHERE r.parent_order_id = o_1.order_id
                               AND r.auction_date_id >= o_1.create_date_id
                               AND (o_1.time_in_force_id = ANY (ARRAY ['1'::bpchar, '6'::bpchar]))
                               AND (EXISTS (SELECT NULL::text AS text
                                            FROM dwh.gtc_order_status gos
                                            WHERE gos.order_id = o_1.order_id
                                              AND gos.create_date_id = o_1.create_date_id))) o ON true
         LEFT JOIN dwh.d_sub_system dss ON o.sub_system_unq_id = dss.sub_system_unq_id
         LEFT JOIN dwh.d_fix_connection fc_rfq ON r.fix_connection_id = fc_rfq.fix_connection_id AND fc_rfq.is_active
         LEFT JOIN dwh.d_fix_connection fc_ord ON o.fix_connection_id = fc_ord.fix_connection_id AND fc_ord.is_active
         LEFT JOIN (SELECT DISTINCT lpi_1.fixcompid           AS fix_comp_id,
                                    lpi_1.liquidityproviderid AS liquidity_provider_id
                    FROM staging.atlas_liquidity_provider_info lpi_1) lpi ON fc_rfq.fix_comp_id::text = lpi.fix_comp_id::text
WHERE r.auction_date_id >= to_char(now() - '4 days'::interval, 'YYYYMMDD'::text)::integer
  AND r.transact_time <= (now() - '00:05:00'::interval);



select * from public.load_timing
where true
     and table_name ilike '%load_ats_cons_inc%'
and log_date::date = '2025-02-24'
and load_timing_id = 6854956;


select *--coalesce(max(q.rfq_id), -1) as local_rfq_id
                          from data_marts.f_rfq_details q
                          where q.auction_date_id = :l_cur_date_id



select rfq_id from staging.ats_rfq_daily_v
where auction_date_id = 20250220
order by 1 desc limit 1;


SELECT max(r.rfq_id)
FROM dwh.request_for_quote r
where r.auction_date_id <= 20250221;



sELECT rl.rfq_leg_id,
       r.rfq_id,
       r.auction_id,
       to_char(r.transact_time, 'YYYYMMDD'::text)::integer AS auction_date_id,
       r.parent_order_id                                   AS rfq_ofp_order_id,
       r.fix_connection_id                                 AS rfq_fix_connection_id,
       r.order_qty                                         AS requested_qty,
       r.quote_type,
       r.min_response_qty,
       r.multileg_reporting_type,
       r.transact_time                                     AS rfq_transact_time,
       r.fix_message_id                                    AS rfq_fix_message_id,
       r.transaction_id                                    AS rfq_transaction_id,
       rl.instrument_id                                    AS requested_instrument_id,
       rl.side                                             AS requested_multi_leg_side,
       rl.ratio_qty,
       o.client_order_id,
       o.create_time,
       o.order_type_id,
       o.side,
       o.instrument_id,
       o.order_qty,
       o.price,
       o.fix_message_id,
       o.account_id,
       dss.sub_system_id,
       o.fix_connection_id,
       fc_ord.fix_comp_id,
       o.client_id_text,
       fc_rfq.fix_comp_id                                  AS rfq_fix_comp_id,
       lpi.liquidity_provider_id                           AS rfq_liquidity_provider_id,
       CASE
           WHEN dss.sub_system_id::text !~~ '%CONS%'::text THEN true
           ELSE false
           END                                             AS is_ats_ofp_parent,
       CASE
           WHEN dss.sub_system_id::text ~~ '%CONS%'::text THEN true
           ELSE false
           END                                             AS is_consolidator_ofp_parent,
       o.sub_strategy_id,
       o.transaction_id
FROM dwh.request_for_quote r
         JOIN dwh.request_for_quote_leg rl ON r.rfq_id = rl.rfq_id
         LEFT JOIN LATERAL ( SELECT cl.order_id,
                                    cl.client_order_id,
                                    cl.create_time,
                                    cl.order_type_id,
                                    cl.side,
                                    cl.instrument_id,
                                    cl.order_qty,
                                    cl.price,
                                    cl.fix_message_id,
                                    cl.account_id,
                                    cl.fix_connection_id,
                                    cl.client_id_text,
                                    cl.sub_system_unq_id,
                                    cl.sub_strategy_id,
                                    cl.transaction_id
                             FROM dwh.client_order cl
                             WHERE r.parent_order_id = cl.order_id
                               AND r.auction_date_id = cl.create_date_id
                               AND (cl.time_in_force_id <> ALL (ARRAY ['1'::bpchar, '6'::bpchar]))
--                              UNION ALL
--                              SELECT cl.order_id,
--                                     cl.client_order_id,
--                                     cl.create_time,
--                                     cl.order_type_id,
--                                     cl.side,
--                                     cl.instrument_id,
--                                     cl.order_qty,
--                                     cl.price,
--                                     cl.fix_message_id,
--                                     cl.account_id,
--                                     cl.fix_connection_id,
--                                     cl.client_id_text,
--                                     cl.sub_system_unq_id,
--                                     cl.sub_strategy_id,
--                                     cl.transaction_id
--
--                              FROM dwh.client_order cl
--                              WHERE r.parent_order_id = cl.order_id
--                                AND r.auction_date_id >= cl.create_date_id
--                                AND (cl.time_in_force_id = ANY (ARRAY ['1'::bpchar, '6'::bpchar]))
--                                AND (EXISTS (SELECT NULL::text AS text
--                                             FROM dwh.gtc_order_status gos
--                                             WHERE gos.order_id = cl.order_id
--                                               AND gos.create_date_id = cl.create_date_id
--                                             ))
             ) o ON true
         LEFT JOIN dwh.d_sub_system dss ON o.sub_system_unq_id = dss.sub_system_unq_id
         LEFT JOIN dwh.d_fix_connection fc_rfq ON r.fix_connection_id = fc_rfq.fix_connection_id AND fc_rfq.is_active
         LEFT JOIN dwh.d_fix_connection fc_ord ON o.fix_connection_id = fc_ord.fix_connection_id AND fc_ord.is_active
         LEFT JOIN (SELECT DISTINCT lpi_1.fixcompid           AS fix_comp_id,
                                    lpi_1.liquidityproviderid AS liquidity_provider_id
                    FROM staging.atlas_liquidity_provider_info lpi_1) lpi ON fc_rfq.fix_comp_id::text = lpi.fix_comp_id::text
WHERE r.auction_date_id >= to_char(now() - '4 days'::interval, 'YYYYMMDD'::text)::integer
  AND r.transact_time <= (now() - '00:05:00'::interval)
                             and r.rfq_id between 290146112046642193 and 290517206305881034;


select v.*
          from staging.ats_cons_stats_v v
          where 1=1;



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
       and v.auction_date_id::integer between l_etl_min_date_id and l_cur_date_id -- >= l_etl_min_date_id
       and not exists
      (
        select r.rfq_leg_id
        from data_marts.f_rfq_details r
        where r.auction_date_id = v.auction_date_id::integer -- unq idx used
          and r.auction_date_id >= l_etl_min_date_id
          and r.rfq_leg_id = v.rfq_leg_id
      )
    ;


select to_char(r.transact_time, 'yyyymmdd'::text)::integer as auction_date_id_,
       r.auction_date_id
from dwh.request_for_quote r
where to_char(r.transact_time, 'yyyymmdd'::text)::integer <>       r.auction_date_id



select coalesce(max(q.rfq_id), -1) as local_rfq_id
                          from data_marts.f_rfq_details q
                          where q.auction_date_id = :l_cur_date_id


select count(*)
FROM dwh.request_for_quote
    where rfq_id between 291591063615740451 and 291591433561841795
291591063615740451, l_max_rfq_id = 291591433561841795
    ;


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
      , :l_load_id as load_batch_id
    from staging.ats_rfq_daily_v v
      left join lateral
        (
          select md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
            , case when md.transaction_id > 0 then true end as is_maket_data_applied
          from dwh.l1_snapshot md
          where md.transaction_id = v.rfq_transaction_id
            and md.instrument_id = case when md.instrument_id > 0 and v.MULTILEG_REPORTING_TYPE = '1' then v.instrument_id else md.instrument_id end --v.instrument_id
            and md.exchange_id = 'NBBO'
            and md.start_date_id between :l_etl_min_date_id and :l_cur_date_id
            --and md.start_date_id = v.auction_date_id::integer
          limit 1
        ) md on true
    left join data_marts.d_sub_strategy dss on dss.sub_strategy_id = v.sub_strategy_id
     where true
       and v.RFQ_ID >= :l_local_rfq_id
            and v.RFQ_ID <= :l_max_rfq_id
       and v.auction_date_id between :l_etl_min_date_id and :l_cur_date_id -- >= l_etl_min_date_id
       and not exists
      (
        select r.rfq_leg_id
        from data_marts.f_rfq_details r
        where r.auction_date_id = v.auction_date_id::integer -- unq idx used
          and r.auction_date_id >= :l_etl_min_date_id
          and r.rfq_leg_id = v.rfq_leg_id
      )
  limit 1000000


select *
from data_marts.f_rfq_details q
WHERE auction_date_id = 20250228;