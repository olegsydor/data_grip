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
  and cm.date_id between 20230902 and 20230929;


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
       cme.exchange_name as exchange,
       roi.volume,
       roi.accepted_or_rejected,
       roi.exchange_error_message,
       roi.executed_volume,
       roi.pg_db_create_time
from consolidator.consolidator_message cm
         left join consolidator.routed_order_information roi
                   on cm.date_id = roi.date_id and cm.cons_message_id = roi.cons_message_id
         join consolidator.cons_message_exchange cme on roi.exchange = cme.exchange_number
where true
  and cm.date_id between 20230902 and 20230929
  and roi.date_id between 20230902 and 20230929
  and cm.rfr_id = '100284649835'
  and cm.message_type = 9
  and cm.request_number = 2