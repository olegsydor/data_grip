-- 1
    select count(*)
--         cm.date_id
--       , cm.rfr_id  -- key first part
--       , cm.request_number -- key second part - need to aggregate for message_type: AuctionTrade (11)
--       , case cm.message_type
--           when 6 then '(6) RequestForRoutingInstructionsOpt'
--           when 7 then '(7) RequestForRoutingInstructionsComplex'
--           end as message_type_text
--       , cm.message
--       , cm.cons_message_id
    from consolidator.consolidator_message cm
    where cm.date_id between 20230902 and 20230929
    and cm.message ilike '%IMC%'
    and cm.message_type = any('{6, 7}');
 -- 29,809,190

-- 2

create table trash.so_routing_instruction as
select ri.date_id,
       ri.route_type,
       ri.side,
       ri.exchange,
       ri.cross_exchange,
       ri.coa_indicator,
       ri.account,
       ri.cons_message_id,
       ri.cancel_chaser
from consolidator.routing_instruction_message ri
where ri.date_id between 20230902 and 20230929
  and ri.route_type in (10, 11, 3);

create table trash.so_cons_pre
as
select *
from consolidator.consolidator_message cm
where cm.message_type in (8, 9)
  and cm.date_id between 20230902 and 20230929;

create index on trash.so_cons_pre (cons_message_id);
create index on trash.so_cons_pre (rfr_id, request_number);
create index on trash.so_cons_pre (date_id);


create table trash.so_consolidator_message as
select ri.date_id
     , ri.route_type
     , ri.side
     , ri.exchange
     , ri.cons_message_id
     , ri.cancel_chaser
     , cm.rfr_id
     , cm.request_number
from trash.so_routing_instruction ri
         join trash.so_cons_pre cm
              on cm.cons_message_id = ri.cons_message_id and cm.message_type = 8
                  and cm.date_id between 20230902 and 20230929
where ri.date_id between 20230902 and 20230929;


create table trash.roinformation as
select * from consolidator.routed_order_information
where date_id between 20230902 and 20230929
and accepted_or_rejected = 1;

create index on trash.roinformation (cons_message_id, date_id);

create table trash.so_main as
-- explain
select cm_base.date_id
     , cm_base.route_type
     , case cm_base.route_type
           when 10 then '94 (Route Type - 10 - Post then Cross)' -- (Post then Cross) // Post order as part of Post then Cross
           when 11 then '96 (Route Type - 11 - Flash)' -- (Flash) // Flash order
           when 3 then '97 (Route Type - 3 - DMA route to Post to the book + cancel_chaser = Y)' -- (DMA route to Post to the book) // DMA to Post order... with Cancel Chaser
           when 12 then '98 (Route Type - 12 - Post as COA)' -- (Post as COA) // Post as COA order
    end                 as reason_code
     , cm_base.exchange
     , cm_base.side           --, ri.volume, ri.price, ri.cross_volume, ri.account, ri.cross_exchange, ri.cancel_chaser, ri.coa_indicator,
     , cm_base.rfr_id
     , cm_base.request_number
     , cm_base.cancel_chaser
     --, cm_9.* --
     , cm_lat.date_id   as routed_date_id
     , cm_lat.side      as routed_side
     , cm_lat.mechanism as route_mechanism
     , cm_lat.exchange  as routed_exchange
     , cm_lat.volume    as routed_volume
     , cm_lat.accepted_or_rejected
     , cm_lat.executed_volume --, cm_9.message
--, row_number() over (partition by cm_8.route_type, cm_9.exchange order by random()) rn_random
from trash.so_consolidator_message cm_base
         inner join lateral
    (
        select roi.date_id
             , roi.side
             , roi.mechanism
             , roi.exchange
             , roi.volume
             , roi.accepted_or_rejected
             , roi.executed_volume
             , cm.message
             , cm.rfr_id
             , cm.request_number--, cm_9.date_id
             , row_number()
               over (partition by cm.date_id, cm.rfr_id, cm.request_number, roi.side, roi.exchange order by roi.executed_volume asc nulls first) as dedup --
        from trash.so_cons_pre cm
                 left join trash.roinformation roi
                           on cm.cons_message_id = roi.cons_message_id and cm.date_id = roi.date_id
        where true
          and cm.message_type = 9                       -- Routed Order Information
          and cm.date_id between 20230902 and 20230929  -- 20230101 and 20230930 -- = 20231108 --
          and roi.date_id between 20230902 and 20230929 -- 20230101 and 20230930 -- = 20231108 --
          and cm_base.rfr_id = cm.rfr_id
          and cm_base.request_number = cm.request_number
          and cm_base.date_id = cm.date_id
          and cm_base.side = roi.side                   -- get rid off roi side which is for another RouteType
          and cm_base.exchange = roi.exchange           -- important, as it can be in several exchanges for different RouteTypes for one side, so having just a side is not enough.
          and roi.accepted_or_rejected = 1
        --and roi.executed_volume > 0 -- !!! WTF!!!???
        limit 10
    ) cm_lat on true and cm_lat.dedup = 1
where cm_base.date_id between 20230902 and 20230929 -- 20230101 and 20230930 -- = 20231108 --
  and ((cm_base.route_type = 10) --(Post then Cross) -- var SA_RR_PC_POST_ORDER = 94 // Post order as part of Post then cross
        or
    (cm_base.route_type = 11) --(Flash)           -- var SA_RR_FLASH_ORDER = 96    // Flash order
        or
    (cm_base.route_type = 3 and cm_base.cancel_chaser = 'Y') --(DMA route to Post to the book) -- var SA_RR_DMA2POST_ORDER_CXL = 97 // DMA to Post order with Cancel Chaser
--         or
--     (cm_base.route_type = 12) --(Post as COA)     -- var SA_RR_POST_COA_ORDER = 98 // Post as COA order
    )
;


create table trash.mes_orders as
select co.*
     , main.* --t.reason_code, count(1)
from trash.so_main main
         left join lateral
    ( select str.*, ec.order_status
      from (select co.order_id, co.exchange_id, co.strtg_decision_reason_code
            from dwh.client_order co
            where co.create_date_id = main.date_id
              and co.create_date_id between 20230902 and 20230929
              and co.parent_order_id is not null -- street level
              and co.dash_rfr_id = main.rfr_id
              and co.order_qty = main.routed_volume
              and co.side = main.side
              and co.request_number = main.request_number
              --and co.exchange_id ilike t.exch_beg||'%'
              and co.trans_type <> 'F'           -- co.trans_type = 'F' --
              and co.multileg_reporting_type in ('1', '2')
              and co.strtg_decision_reason_code::varchar = left(reason_code, 2)
            limit 1) str
               --) co on true
               left join lateral
          (
          select ec.order_id, ec.order_status
          from dwh.execution ec
          where ec.exec_date_id = main.date_id
            and ec.exec_date_id between 20230902 and 20230929
            and ec.order_id = str.order_id
            and (ec.exec_type = '4' or ec.order_status = '4')
          limit 1
          ) ec on true
      where ec.order_id is not null
    ) co on true
where true
  and co.order_id is not null;

select * from d_exec_type
drop table trash.mes_orders_full;


drop table if exists trash.mes_orders;
create table trash.mes_orders as
select co.*
     , main.* --t.reason_code, count(1)
from trash.so_main main
         join lateral
    (
    select co.order_id, co.exchange_id, co.strtg_decision_reason_code, ec.exec_id_arr, cnt
    from dwh.client_order co
             left join lateral (select ec.order_id, count(*) as cnt, array_agg(exec_id order by exec_id) as exec_id_arr
                                from dwh.execution ec
                                where ec.exec_date_id = co.create_date_id
                                  and ec.exec_date_id between 20230902 and 20230929
                                  and ec.order_id = co.order_id
                                  and ec.exec_type = 'F'
                                group by ec.order_id
                                limit 1) ec on true
    where co.create_date_id = main.date_id
      and co.create_date_id between 20230902 and 20230929
      and co.parent_order_id is not null -- street level

      and co.dash_rfr_id = main.rfr_id
      and co.order_qty = main.routed_volume
      and co.side = main.side
      and co.request_number = main.request_number
      --and co.exchange_id ilike t.exch_beg||'%'
      and co.trans_type <> 'F'           -- co.trans_type = 'F' --
      and co.multileg_reporting_type in ('1', '2')
      and co.strtg_decision_reason_code::varchar = left(reason_code, 2)
      limit 1
    ) co on true
where true;

select * from trash.mes_orders
where order_id is not null
and exec_id_arr is null;

-- 2
select route_type, count(*)
from trash.mes_orders_full
--  where cnt is not null
group by route_type;

create index on trash.mes_orders_full (rfr_id, side, date_id, route_type);

create temp table t_grp as
with grp as (select rfr_id,
                    coalesce(order_id, 0)                                                         as order_id,
                    first_value(order_id)
                    over (partition by rfr_id, side, date_id, route_type order by request_number) as first_order_id_in_this_route,
                    first_value(order_id)
                    over (partition by rfr_id, side, date_id order by request_number)             as first_order_id
             from trash.mes_orders_full)
select rfr_id,
       order_id,
       first_order_id_in_this_route,
       first_order_id,
       -- aggregations
       case
           when order_id is not distinct from first_order_id_in_this_route and order_id <> 0 then 'case a'
           when order_id is not distinct from first_order_id_in_this_route and order_id = 0 then 'case b'
           when order_id is not distinct from first_order_id and order_id <> 0 then 'case c'
           when order_id is not distinct from first_order_id and order_id = 0 then 'case d'
           else 'case d'
           end as group_of
from grp
where true;

drop table t_grp_full;
create temp table t_grp_full as
with grp as (select rfr_id,
                    coalesce(order_id, 0)                                                         as order_id,
                    request_number,
                    first_value(order_id)
                    over (partition by rfr_id, side, date_id, route_type order by request_number, order_id) as first_order_id_in_this_route,
                    first_value(order_id)
                    over (partition by rfr_id, side, date_id order by request_number, order_id)             as first_order_id
             from trash.mes_orders_full)
select rfr_id,
       order_id,
       first_order_id_in_this_route,
       first_order_id,
       request_number,
       -- aggregations
       case
           when order_id is not distinct from first_order_id_in_this_route and order_id <> 0 then 'case a'
           when order_id is not distinct from first_order_id_in_this_route and order_id = 0 then 'case b'
           when order_id is distinct from first_order_id and order_id <> 0 then 'case c'
           when order_id is distinct from first_order_id and order_id = 0 then 'case d'
--            else 'case d'
           end as group_of
from grp
where true;


select * from t_grp_full
where group_of <> 'case a';

select group_of, count(*) from t_grp_full
group by group_of;

select 44+1437180+24493 --1461717
select 324211+165054+972452


select rfr_id, request_number, * from trash.mes_orders_full
    where mes_orders_full.rfr_id = '100284620356'



select min(create_time) from client_order
where dash_rfr_id is not null