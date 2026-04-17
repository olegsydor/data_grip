select status_date_id,
       fpo.parent_order_id,
       fpo.last_exec_id,
       fpo.order_status,
       hods."OrderStatus",
       fpo.pg_db_update_time,
       fpo.pg_db_create_time
from data_marts.f_parent_order fpo
         join dwh.historic_order_details_storage hods on hods."OrderID" = fpo.parent_order_id
         join dwh.client_order cl on cl.order_id = fpo.parent_order_id
where status_date_id = 20260415
  and hods."Status_Date_id" = 20260415
  and fpo.status_date_id = hods."Status_Date_id"
  and fpo.order_status != hods."OrderStatus"
and cl.multileg_reporting_type != '3';

select * from data_marts.load_parent_order_inc(in_parent_order_ids := '{436936742537443562}', in_date_id := 20260415);

select * from d_order_status

drop table t_base;

create temp table t_base as
select coalesce(cl.parent_order_id, ex.order_id) as parent_order_id,
       min(ex.exec_id)                           as min_exec_id,
       max(ex.exec_id)                           as max_exec_id,
       min(coalesce(cl.parent_order_process_time, client_order.process_time))         as parent_order_process_time,
       min(ex.order_create_date_id)              as order_create_date_id,
       min(cl.create_date_id)                    as create_date_id,
       array_agg(distinct ex.dataset_id)
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
where ex.exec_date_id = 20260416
  and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
  and case when in_parent_order_ids is null then true else cl.parent_order_id = any (in_parent_order_ids) end
  and case
          when not ex.is_parent_level and cl.parent_order_id is not null then true
           when ex.is_parent_level and ex.order_status = '4' and cl.parent_order_id is null then true
          else false end
and cl.order_id = 445894764413560327
group by coalesce(cl.parent_order_id, ex.order_id);

select parent_order_process_time, * from dwh.client_order
    where client_order.order_id = 445894764413560327

select *
    --distinct unnest(array_agg)
    from t_base;


drop table if exists t_base;
create temp table t_base as
select coalesce(cl.parent_order_id, ex.order_id)                              as parent_order_id,
       min(ex.exec_id)                                                        as min_exec_id,
       max(ex.exec_id)                                                        as max_exec_id,
       min(coalesce(cl.parent_order_process_time, client_order.process_time)) as parent_order_process_time,
       min(ex.order_create_date_id)                                           as order_create_date_id,
       min(cl.create_date_id)                                                 as create_date_id
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
where ex.exec_date_id = l_date_id
  and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
  and case when in_parent_order_ids is null then true else cl.parent_order_id = any (in_parent_order_ids) end
  and case
          when not ex.is_parent_level and cl.parent_order_id is not null then true
          when ex.is_parent_level and ex.order_status = '4' and cl.parent_order_id is null then true
          else false end
group by coalesce(cl.parent_order_id, ex.order_id);



