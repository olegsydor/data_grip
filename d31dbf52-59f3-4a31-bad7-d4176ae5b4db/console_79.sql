drop table if exists trash.so_routed_order_information;
create table trash.so_routed_order_information as
select *
from consolidator.routed_order_information
where date_id between 20230902 and 20230929;

drop table if exists trash.so_consolidator_message;
create table trash.so_consolidator_message
as
select *
from consolidator.consolidator_message cm
where true
  and cm.date_id between 20230902 and 20230929
-- and cm.message ilike '%IMC%'
;

create index on trash.so_routed_order_information(date_id, cons_message_id);
create index on trash.so_consolidator_message(rfr_id);

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

/*
3 = DMA route to Post to the book -> 6 = DMA to Pos
10 = Post then Cross
11 = Flash -> 7 = Flash
*/

drop table if exists trash.so_report_abcd;
create table trash.so_report_abcd as
select cm.message_type,
       cm.rfr_id,
       cm.request_number,
       roi.routed_order_information_id,
       roi.date_id,
       roi.cons_message_id,
       roi.side,
       roi.routing_instructions_timestamp,
       roi.order_sent_timestamp,
       roi.order_ack_timestamp,
       roi.mechanism,
       case roi.mechanism
           when 1 then 'DMA to Remove' -- excluded
           when 2 then 'Auction'
           when 3 then 'ATS'
           when 4 then 'SOR'
           when 5 then 'Consolidator Lite'
           when 6 then 'DMA to Pos' -- 3
           when 7 then 'Flash' -- 11
           end           as route_type,
       cme.exchange_name as exchange,
       roi.volume,
       roi.accepted_or_rejected,
       roi.exchange_error_message,
       roi.executed_volume,
       roi.pg_db_create_time
--          ,
--         crw.*--route_type
from trash.so_consolidator_message cm
         left join trash.so_routed_order_information roi
                   on cm.date_id = roi.date_id and cm.cons_message_id = roi.cons_message_id
         join consolidator.cons_message_exchange cme on roi.exchange = cme.exchange_number

where true
  and cm.date_id between 20230902 and 20230929
  and roi.date_id between 20230902 and 20230929
  and cm.rfr_id = '760204378479'
  and cm.message_type = '9'
  and roi.mechanism <> 1;
