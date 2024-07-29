call trash.get_consolidator_eod_pg_7(in_date_id := 20240716);
call trash.get_consolidator_eod_pg_8(in_date_id := 20240716);

select * from trash.t_base_gtc;
select * from trash.t_base;


    drop table if exists t_opt_exec_broker;
    create temp table t_opt_exec_broker as
    select * from dwh.d_opt_exec_broker opx where opx.is_default = 'Y' and opx.is_active;
    create index on t_opt_exec_broker (account_id);
    analyze t_opt_exec_broker;


select tbs.order_id, tbs.opt_exec_broker, opx.opt_exec_broker
from trash.t_base tbs
             left join t_opt_exec_broker opx on opx.account_id = tbs.account_id-- and opx.is_default = 'Y' and opx.is_active)


select
		CL.OPT_EXEC_BROKER_id, account_id, *
	  from CLIENT_ORDER CL
      where CL.MULTILEG_REPORTING_TYPE in ('1','2')
      and cl.order_id = 16290488887;


select * from dwh.d_opt_exec_broker
where account_id = 68488;

select * from t_opt_exec_broker;

select * from dwh.gtc_order_status
    where order_id = 16280266243

select * from dwh.client_order cl
where cl.order_id in (16280266243, 16219389154, 16280481389)

create temp table t_so_gtc as
select distinct on (e.order_id) e.order_id, co.date_id
from dwh.execution e
         join lateral (select get_dateid(co.parent_order_process_time) as date_id
                       from dwh.client_order co
                       where e.order_id = co.order_id
                         and co.parent_order_id is not null
                         and co.parent_order_process_time < '2024-07-16'::timestamp
                       limit 1) co on true
where true
--and e.order_id = 16174742575
  and e.exec_date_id = 20240716
  and e.exec_type not in ('E', 'S', 'D', 'y')
  and not e.is_parent_level


select order_id, create_date_id, parent_order_id, parent_order_process_time, * from dwh.client_order
where order_id in (16174742575, 16156679190)

create temp table t_so as
select distinct on (e.order_id) e.order_id, co.parent_order_process_time
from dwh.execution e
         join dwh.client_order co
              on e.order_id = co.order_id
                  and co.parent_order_id is not null
                  and co.parent_order_process_time < '2024-07-16'::timestamp
                  and e.exec_date_id = 20240716
                  and e.exec_type not in ('E', 'S', 'D', 'y')
                  and not e.is_parent_level;


create temp table t_so as
select e.order_id, min(co.parent_order_process_time)
from dwh.execution e
         join dwh.client_order co
              on e.order_id = co.order_id
                  and co.parent_order_id is not null
                  and co.parent_order_process_time < '2024-07-16'::timestamp
                  and e.exec_date_id = 20240716
                  and e.exec_type not in ('E', 'S', 'D', 'y')
                  and not e.is_parent_level
group by e.order_id;

