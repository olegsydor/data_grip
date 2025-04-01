 create temp table if not exists t_lp_connection as
select * from staging.lp_connection;

create temp table if not exists t_cons_lp2trading_firm as
select * from staging.cons_lp2trading_firm;


select
    coalesce(rf.transact_time, ca.rfq_transact_time),
    to_char(now(), 'YYMMDDHH24MI')::bigint                                                                   as dataset_id
     , a.auction_id                                                                                             as auction_id
     , a.auction_date_id                                                                                        as auction_date_id
     , coalesce(ats_lp.liquidity_provider_id,
                cons_pl.liquidity_provider_id)                                                                  as liquidity_provider_id
     , rfq.ofp_order_id                                                                                         as ofp_orig_order_id -- on this step is only for ATS
     , case
           when coalesce(rf.transact_time, ca.rfq_transact_time) /*rfq.ofp_order_id*/ is not null
               then true end                                                                                    as is_ats
     , case when coalesce(rf.transact_time, ca.rfq_transact_time) /*rfq.ofp_order_id*/ is null then true end   as is_cons
     , case
           when cl.parent_order_id is null and
                coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is null
               then true end                                                                                    as is_ofp_parent
     , case
           when cl.parent_order_id is not null and
                coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is null
               then true end                                                                                    as is_ofp_street
     , case
           when cl.parent_order_id is null and
                coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is not null
               then true end                                                                                    as is_lpo_parent
     , case
           when cl.parent_order_id is not null and
                coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is not null
               then true end                                                                                    as is_lpo_street
     , ca.order_id                                                                                              as order_id
     , cl.client_order_id                                                                                       as client_order_id
     , cl.parent_order_id                                                                                       as parent_order_id
     , cl.create_time                                                                                           as order_create_time
     , cl.create_date_id                                                                                        as create_date_id
     , cl.price                                                                                                 as order_price
     , cl.order_qty                                                                                             as order_qty
     , cl.order_type_id                                                                                         as order_type_id
     , cl.account_id                                                                                            as account_id
     , cl.instrument_id                                                                                         as instrument_id
     , cl.transaction_id                                                                                        as transaction_id
     , cl.side                                                                                                  as side
     , cl.multileg_reporting_type                                                                               as multileg_reporting_type
     , cl.cross_order_id                                                                                        as cross_order_id
     , cl.client_id_text                                                                                        as client_id
     , cl.exchange_id                                                                                           as exchange_id
     , cl.fix_connection_id                                                                                     as fix_connection_id
     , fc.fix_comp_id                                                                                           as fix_comp_id
     , cl.internal_component_type                                                                               as internal_component_type
     , ss.sub_system_id                                                                                         as sub_system_id
     , cl.liquidity_provider_id                                                                                 as order_liquidity_provider_id
     , cl.exch_order_id                                                                                         as exch_order_id
     , cl.exec_instruction
     , cl.strtg_decision_reason_code                                                                            as strategy_decision_reason_code
     , cf.capacity_group_id
from (
         select distinct on (ca.auction_id) ca.auction_id,
                                            max(ca.create_date_id) over (partition by ca.auction_id) as auction_date_id,
                                            min(ca.create_date_id) over (partition by ca.auction_id) as min_order_create_date_id
         from dwh.client_order2auction ca
                  join dwh.client_order co
                       on ca.order_id = co.order_id
                           and co.create_date_id = :l_cur_date_id
         where ca.create_date_id = :l_cur_date_id    -- date for recalculation. It is not including old GTC orders for the current auction_date_id which is problem.
           and coalesce(co.trans_type, '-1') <> 'F' -- Cancel requests are generating new auction_date_id for old auctions.Suppressing.
           and (:l_is_current_recalc = true
             or coalesce(co.time_in_force_id, '-1') not in
                ('1', '6'))                         -- exclude GTC,GTD from recalculations based on create_date_id of orders
          and ca.auction_id = 290008021884
         union all
         select rd.auction_id
              , max(rd.auction_date_id) as auction_date_id
-- OS 20250310          , (select min(au.create_date_id) from dwh.client_order2auction au where rd.auction_id = au.auction_id) as min_order_create_date_id
              , (select au.create_date_id
                 from dwh.client_order2auction au
                 where rd.auction_id = au.auction_id
                 order by 1
                 limit 1)               as min_order_create_date_id
         from (select rd.auction_id, auction_date_id -- hope one auction is present in one auction date
               from data_marts.f_rfq_details rd
               where rd.auction_date_id = :l_cur_date_id
               and rd.auction_id = 290008021884
               group by auction_date_id, rd.auction_id) rd
                  join dwh.client_order2auction ca
                       on rd.auction_id = ca.auction_id
                           and rd.auction_date_id >
                               ca.create_date_id -- GTC, GTD, GTX filter: orders which were created prior auction date
         group by rd.auction_id) a
         join lateral
                    (
                    select ca.auction_id
                         , ca.order_id
                         , max(ca.rfq_transact_time) over (partition by ca.auction_id) as rfq_transact_time
                    from dwh.client_order2auction ca
                    where a.auction_id = ca.auction_id
                      and ca.create_date_id between a.min_order_create_date_id and a.auction_date_id
                      and ca.create_date_id >= :l_gtc_min_date_id -- GTC hardcode
                    limit 10000 -- orders limit in one auction
                    ) ca on true
         left join lateral (select transact_time
                            from dwh.request_for_quote rfq
                            where rfq.auction_id = a.auction_id
                              and rfq.auction_date_id between a.min_order_create_date_id and a.auction_date_id
                            limit 1) rf on true
         left join lateral
    (
    select rfq.auction_id
         , rfq.auction_date_id
         , rfq.ofp_order_id -- can be of mlrt 1 or 3
    from data_marts.f_rfq_details rfq
    where true
      and rfq.auction_date_id >= :l_gtc_min_date_id --a.auction_date_id --
      and rfq.auction_id = a.auction_id
    limit 1
    ) rfq on true
         join dwh.client_order cl
              on ca.order_id = cl.order_id
                  and cl.create_date_id between a.min_order_create_date_id and a.auction_date_id
                  and cl.create_date_id >= :l_gtc_min_date_id -- GTC hardcode
         left join dwh.d_account ac
                   on cl.account_id = ac.account_id
         left join dwh.d_sub_system ss
                   ON cl.sub_system_unq_id = ss.sub_system_unq_id
    -- parent lvl
         left join dwh.client_order po
                   on cl.parent_order_id = po.order_id
                       and po.create_date_id >= :l_gtc_min_date_id -- GTC hardcode
         left join dwh.d_account pac
                   on po.account_id = pac.account_id
         left join dwh.d_fix_connection fc
                   on cl.fix_connection_id = fc.fix_connection_id
         left join
     (select ats_lp.fix_connection_id, max(ats_lp.liquidity_provider_id) as liquidity_provider_id
      from t_lp_connection ats_lp
      where ats_lp.lp_connector_id = 'LPLB'
        and ats_lp.is_deleted = 'N'
      group by ats_lp.fix_connection_id) ats_lp
     on coalesce(po.fix_connection_id, cl.fix_connection_id) = ats_lp.fix_connection_id
         left join t_cons_lp2trading_firm cons_pl
                   on coalesce(pac.trading_firm_id, ac.trading_firm_id) = cons_pl.trading_firm_id
         left join dwh.d_customer_or_firm cf
                   on cl.customer_or_firm_id = cf.customer_or_firm_id
where true
  and coalesce(cl.trans_type, '-1') <> 'F'