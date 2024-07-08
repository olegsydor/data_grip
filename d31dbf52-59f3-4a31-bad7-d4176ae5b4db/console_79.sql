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



drop table if exists trash.so_cons_preload;
create table trash.so_cons_preload
as
select *
from consolidator.consolidator_message cm
where cm.message_type in (8, 9)
  and cm.date_id between 20230902 and 20230929
and rfr_id in ('760204378479', '740245810547', '710317275002', '780105394924');


drop table if exists trash.so_consolidator_message;
create table trash.so_consolidator_message as
select
--     ri.date_id
--      , ri.route_type
--      , ri.side
--      , ri.exchange
--      , ri.cons_message_id
--      , ri.cancel_chaser
--      , cm.rfr_id
--      , cm.request_number
*
from trash.so_cons_preload cm
         join trash.so_routing_instruction ri
              using (cons_message_id, date_id)
where ri.date_id between 20230902 and 20230929
  and cm.message_type = 8
  and cm.date_id between 20230902 and 20230929
  and cm.rfr_id in ('760204378479', '740245810547', '710317275002', '780105394924')
  and cm.message ilike '%IMC%'
--     and cm.message_type = any('{6, 7}')
  and message_type = 8--in (8, 9)
  and cm.date_id between 20230901 and 20230930
order by request_number;

select * from trash.so_consolidator_message
where rfr_id = '760204378479'
and route_type = 11

select * from trash.so_cons_preload cm
where cons_message_id in (2355615969,
2355615969,
2355618021,
2355631344
)