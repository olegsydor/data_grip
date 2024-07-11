--         and ri.rfr_id = '760204378479'

drop table if exists trash.so_consolidator_message;
create table trash.so_consolidator_message
as
select *
from consolidator.consolidator_message cm
where true
  and cm.date_id between 20230902 and 20230929
--   and cm.rfr_id in ('760204378479', '740245810547', '710317275002', '780105394924', '100284649835')
;
create index on trash.so_consolidator_message (cons_message_id, message_type);
create index on trash.so_consolidator_message (rfr_id);

drop table if exists trash.so_routing_instruction_message;
create table trash.so_routing_instruction_message as
select *
from consolidator.routing_instruction_message ri
where ri.date_id between 20230902 and 20230929
  and ri.route_type in (3, 10, 11)
-- and cons_message_id in (select cons_message_id from trash.so_consolidator_message)
;
drop table if exists trash.so_routed_order_information;
create table trash.so_routed_order_information as
    select * from consolidator.routed_order_information
        where date_id between 20230902 and 20230929;
create index on trash.so_routed_order_information (cons_message_id, date_id);


drop table if exists trash.so_base;
create table trash.so_base as
--explain
select ri.date_id,
       ri.route_type,
       ri.side,
       ri.exchange,
       ri.cons_message_id,
       ri.cancel_chaser,
       cm.rfr_id,
       cm.request_number,
       case ri.route_type
           when 10
               then '94 (Route Type - 10 - Post then Cross)' -- (Post then Cross) // Post order as part of Post then Cross
           when 11 then '96 (Route Type - 11 - Flash)' -- (Flash) // Flash order
           when 3
               then '97 (Route Type - 3 - DMA route to Post to the book + cancel_chaser = Y)' -- (DMA route to Post to the book) // DMA to Post order... with Cancel Chaser
           end        as reason_code,
       cm_9.date_id   as routed_date_id,
       cm_9.side      as routed_side,
       cm_9.mechanism as route_mechanism,
       cm_9.exchange  as routed_exchange,
       cm_9.volume    as routed_volume,
       cm_9.accepted_or_rejected,
       cm_9.executed_volume --, cm_9.message
from trash.so_routing_instruction_message ri
         join trash.so_consolidator_message cm
              on cm.cons_message_id = ri.cons_message_id and cm.message_type = 8
                  and cm.date_id between 20230902 and 20230929
         left join lateral
    (
    select roi.date_id
         , roi.side
         , roi.mechanism
         , roi.exchange
         , roi.volume
         , roi.accepted_or_rejected
         , roi.executed_volume
         , cmi.message
         , cmi.rfr_id
         , cmi.request_number--, cm_9.date_id
         , row_number()
           over (partition by cmi.date_id, cmi.rfr_id, cmi.request_number, roi.side, roi.exchange order by roi.executed_volume asc nulls first) as dedup --
    from trash.so_consolidator_message cmi
             left join trash.so_routed_order_information roi
                       on cmi.cons_message_id = roi.cons_message_id and cmi.date_id = roi.date_id
    where true
      and cmi.message_type = 9       -- Routed Order Information
      and cmi.date_id between 20230902 and 20230929
      and roi.date_id between 20230902 and 20230929
      and cm.rfr_id = cmi.rfr_id
      and cm.request_number = cmi.request_number
      and cm.date_id = cmi.date_id
      and ri.side = roi.side         -- get rid off roi side which is for another RouteType
      and ri.exchange = roi.exchange -- important, as it can be in several exchanges for different RouteTypes for one side, so having just a side is not enough.
--       and roi.accepted_or_rejected = 1
    limit 2
    ) cm_9 on true and cm_9.dedup = 1
where ri.date_id between 20230902 and 20230929
  and cm.message ilike '%IMC%'
--   and cm.rfr_id = '100284649835'
 and (
            (ri.route_type = 10) --(Post then Cross) -- var SA_RR_PC_POST_ORDER = 94 // Post order as part of Post then cross
            or
            (ri.route_type = 11) --(Flash)           -- var SA_RR_FLASH_ORDER = 96    // Flash order
            or
            (ri.route_type = 3 and ri.cancel_chaser = 'Y') --(DMA route to Post to the book) -- var SA_RR_DMA2POST_ORDER_CXL = 97 // DMA to Post order with Cancel Chaser
--             or
--             (ri.route_type = 12) --(Post as COA)     -- var SA_RR_POST_COA_ORDER = 98 // Post as COA order
          );

select * from  trash.so_base
where rfr_id = '100284649835';

drop table if exists trash.so_main_ext;
create table trash.so_main_ext as
select co.*
     , main.* --t.reason_code, count(1)
from trash.so_base main
         left join lateral
    (
    select co.order_id, co.exchange_id, co.strtg_decision_reason_code, ec.exec_id_arr, cnt
    from dwh.client_order co
             left join lateral (select ec.order_id, count(*) as cnt, array_agg(exec_id order by exec_id) as exec_id_arr
                                from dwh.execution ec
                                where ec.exec_date_id >= co.create_date_id
                                  and ec.exec_date_id between 20230902 and 20230929
                                  and ec.order_id = co.order_id
                                  and ec.exec_type in ('A', 'O', '5', 'F')--= 'F'
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
where true
and main.rfr_id = '100284649835';

select * from trash.so_main_ext;
create index on trash.so_main_ext (rfr_id, route_type, request_number);

drop table if exists trash.so_cons_prepared;
create table trash.so_cons_prepared as
select rfr_id,
       request_number,
       route_type,
       dense_rank() over (partition by rfr_id, route_type order by request_number) as rn,
       dense_rank() over (partition by rfr_id order by request_number)             as rn_total,
       executed_volume,
       cnt,
       case coalesce(routed_exchange::varchar, exchange::varchar) -- t.cross_exchange,
           when '1' then 'AMEX'
           when '2' then 'ARCA'
           when '3' then 'BATS'
           when '4' then 'BOX'
           when '5' then 'BX'
           when '6' then 'C2'
           when '7' then 'CBOE'
           when '8' then 'EDGE'
           when '9' then 'GEMINI'
           when '10' then 'ISE'
           when '11' then 'MCRY'
           when '12' then 'MIAX'
           when '13' then 'PEARL'
           when '14' then 'NOM'
           when '15' then 'PHLX'
           when '16' then 'EMERALD'
           when '17' then 'MXOP'
           else coalesce(exchange_id, routed_exchange::varchar, exchange::varchar)
           end                                                                     as exchange_routed,
    side
from trash.so_main_ext
 where rfr_id = '100284649835'
;

select * from trash.so_cons_prepared
where rfr_id = '100284649835';

with al as (select rfr_id,
                   request_number,
                   route_type,
                   executed_volume,
                   exchange_routed,
                   cnt,
                   case
                       when rn = 1 and nullif(executed_volume, 0) is not null then 'a'
                       when rn = 1 and nullif(executed_volume, 0) is null then 'b'
                       when rn_total > 1 and nullif(executed_volume, 0) is not null then 'c'
                       when rn_total > 1 and nullif(executed_volume, 0) is null then 'd' end as routed_type
            from trash.so_cons_prepared
            where true
--             and rfr_id = '100284649835'
            and executed_volume is not null)
select
routed_type, count(*)
from al
group by routed_type;

select 1103898+7519856+389567+2474165



and rfr_id = '100284649835';

select ex.last_qty, * from dwh.client_order co
         join dwh.execution ex on ex.order_id = co.order_id and ex.exec_date_id >= co.create_date_id and ex.exec_type in ('0', 'A', '5', 'F')
where dash_rfr_id = '100287978057'
and create_date_id between 20230901 and 20230930
and parent_order_id is not null