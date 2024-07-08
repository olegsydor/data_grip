drop table if exists trash.so_routing_instruction;
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

create table trash.roinformation as
select * from consolidator.routed_order_information
where date_id between 20230902 and 20230929
and accepted_or_rejected = 1;

drop table if exists trash.so_cons_preload;
create table trash.so_cons_preload
as
select *
from consolidator.consolidator_message cm
where cm.message_type in (8, 9)
  and cm.date_id between 20230902 and 20230929
and rfr_id in ('760204378479', '740245810547', '710317275002', '780105394924', '100284649835');


drop table if exists trash.so_consolidator_message;
create table trash.so_consolidator_message as
select date_id, cons_message_id, rfr_id, request_number, route_type, side, exchange, coalesce(executed_volume, 0) as executed_volume
from trash.so_cons_preload cm
         join trash.so_routing_instruction ri
              using (cons_message_id, date_id)
         left join lateral
    (
        select
             roi.accepted_or_rejected,
             roi.executed_volume,
              dense_rank()
               over (partition by cmi.date_id, cm.rfr_id, cmi.request_number, roi.side, roi.exchange order by roi.executed_volume asc nulls first) as dedup --
        from trash.so_cons_preload cmi
                 left join trash.roinformation roi
                           on cmi.cons_message_id = roi.cons_message_id and cmi.date_id = roi.date_id
        where true
          and cmi.message_type = 9                       -- Routed Order Information
          and cmi.date_id between 20230902 and 20230929
          and roi.date_id between 20230902 and 20230929
          and cmi.rfr_id = cm.rfr_id
          and cmi.request_number = cm.request_number
          and cmi.date_id = cm.date_id
          and ri.side = roi.side
          and ri.exchange = roi.exchange
--           and roi.accepted_or_rejected = 1
        limit 2
    ) cm_lat on true
where ri.date_id between 20230902 and 20230929
  and cm.message_type = 8
  and cm.date_id between 20230902 and 20230929
  and cm.rfr_id in ('760204378479', '740245810547', '710317275002', '780105394924', '100284649835')
  and cm.message ilike '%IMC%'
--     and cm.message_type = any('{6, 7}')
  and cm.date_id between 20230901 and 20230930
    and coalesce(dedup, 1) = 1
and route_type = 11
order by cm.rfr_id,cm.request_number, cm.cons_message_id

