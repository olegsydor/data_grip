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
         join consolidator.consolidator_message cm
              on cm.cons_message_id = ri.cons_message_id and cm.message_type = 8
                  and cm.date_id between 20230902 and 20230929
where ri.date_id between 20230902 and 20230929;


create table trash.sdn_tmp_tim_miller_consolidator_request_20231111_4_roi_10v2 as
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
    from consolidator.consolidator_message cm
             left join consolidator.routed_order_information roi
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
    limit 1
    ) cm_lat on true and cm_lat.dedup = 1
where cm_base.date_id between 20230902 and 20230929 -- 20230101 and 20230930 -- = 20231108 --
  and (
    (cm_base.route_type = 10) --(Post then Cross) -- var SA_RR_PC_POST_ORDER = 94 // Post order as part of Post then cross
        or
    (cm_base.route_type = 11) --(Flash)           -- var SA_RR_FLASH_ORDER = 96    // Flash order
        or
    (cm_base.route_type = 3 and cm_base.cancel_chaser = 'Y') --(DMA route to Post to the book) -- var SA_RR_DMA2POST_ORDER_CXL = 97 // DMA to Post order with Cancel Chaser
        or
    (cm_base.route_type = 12) --(Post as COA)     -- var SA_RR_POST_COA_ORDER = 98 // Post as COA order
    )
;