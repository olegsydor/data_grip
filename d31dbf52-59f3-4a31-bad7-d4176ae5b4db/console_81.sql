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