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



create or replace function trash.f_get_parent_order_attr(in_parent_order_id int8, in_create_date_id int4,
                                              in_retention_date_id int4 default 20230901)
    returns table
            (
                sub_strategy_desc varchar(128),
                client_order_id   varchar(256),
                order_type_id     char,
                time_in_force_id  char,
                exch_order_id     varchar(128)
            )
    language plpgsql
    immutable
as
$$
begin
    return query select pro.sub_strategy_desc, pro.client_order_id, pro.order_type_id, pro.time_in_force_id, pro.exch_order_id
                 from dwh.client_order pro
                 where pro.order_id = in_parent_order_id
                   and pro.create_date_id = in_create_date_id
                   and create_date_id = in_create_date_id
                   and pro.parent_order_id is null
                   and pro.create_date_id >= in_retention_date_id
                 limit 1;
end;
$$;

select sub_strategy_desc, client_order_id, order_type_id, time_in_force_id, exch_order_id
                                from trash.f_get_parent_order_attr(16280080016, get_dateid('2024-07-16 09:23:54.177922'::date));

select sub_strategy_desc, client_order_id, order_type_id, time_in_force_id, exch_order_id
                                from trash.f_get_parent_order_attr(16280080016, 20240716);

select get_dateid('2024-07-16 09:23:54.177922')
select parent_order_id, parent_order_process_time from dwh.client_order where create_date_id = 20240716
and parent_order_id is not null