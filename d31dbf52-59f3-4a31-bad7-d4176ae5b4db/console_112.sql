create temp table t_01 as
select distinct cl.account_id, da.account_name, cl.trading_firm_id, dtf.trading_firm_name--,  cl.create_time,  cl.expire_time, *
from dwh.client_order cl
join dwh.d_account da on da.account_id = cl.account_id
join dwh.d_trading_firm dtf on dtf.trading_firm_id = cl.trading_firm_id
where true
and cl.create_date_id = 20250130
and (cl.create_time::time between '03:00'::time and '09:30'::time
or cl.create_time::time between '03:00'::time and '16:00'::time)
--and (cl.expire_time is null
--or cl.expire_time > '16:00'::time

select da.account_id, da.account_name, dtf.trading_firm_id, dtf.trading_firm_name
from dwh.d_account da
         join dwh.d_trading_firm dtf on dtf.trading_firm_id = da.trading_firm_id
where da.account_id in (select distinct cl.account_id
                        from dwh.client_order cl
                        where true
                          and cl.create_date_id = 20250130
                          and (cl.create_time::time between '03:00'::time and '09:30'::time
                            or cl.create_time::time between '16:00'::time and '20:00'::time));



create function trash.so_non_working_time_account(in_date_id int4)
    returns table
            (
                date_id           int4,
                account_id        int4,
                account_name      varchar(30),
                trading_firm_id   varchar(9),
                trading_firm_name varchar(60),
                case_1            int8,
                case_2            int8,
                case_3            int8
            )
    language plpgsql
as
$fx$
declare

begin
    return query
        select in_date_id,
               cl.account_id,
               ac.account_name,
               cl.trading_firm_id,
               tf.trading_firm_name,
               sum(case when cl.create_time::time between '03:00'::time and '09:30'::time then 1 else 0 end) as case_1,
               sum(case when cl.create_time::time between '16:00'::time and '20:00'::time then 1 else 0 end) as case_2,
               sum(case
                       when cl.create_time::time > '09:30'::time and cl.create_time::time < '16:00'::time and
                            not exists (select null
                                        from dwh.execution ex
                                        where ex.exec_date_id = in_date_id
                                          and ex.exec_type in ('4', 'F', '8'))
                           then 1
                       else 0 end)                                                                           as case_3

        from dwh.client_order cl
                 join dwh.d_account ac on ac.account_id = cl.account_id
                 join dwh.d_trading_firm tf on tf.trading_firm_id = cl.trading_firm_id
        where cl.create_date_id = in_date_id
        group by cl.account_id,
                 ac.account_name,
                 cl.trading_firm_id,
                 tf.trading_firm_name,
                 in_date_id
        having (sum(case when cl.create_time::time between '03:00'::time and '09:30'::time then 1 else 0 end) > 0
            or sum(case when cl.create_time::time between '16:00'::time and '20:00'::time then 1 else 0 end) > 0
            or sum(case
                       when cl.create_time::time > '09:30'::time and cl.create_time::time < '16:00'::time and
                            not exists (select null
                                        from dwh.execution ex
                                        where ex.exec_date_id = in_date_id
                                          and ex.exec_type in ('4', 'F', '8'))
                           then 1
                       else 0 end) > 0
                   );
end;
$fx$;


insert into trash.non_working_hours_account
select *
from trash.so_non_working_time_account(20240702)
on conflict (date_id, account_id) do nothing

alter table trash.non_working_hours_account
add constraint date_id_account_id_unq unique (date_id, account_id)


select * from dwh.d_exec_type
select cl.*, da.account_name, dtf.trading_firm_name from t_01 cl
join dwh.d_account da on da.account_id = cl.account_id
join dwh.d_trading_firm dtf on dtf.trading_firm_id = cl.trading_firm_id;



select date_id, trading_firm_id, sum(case_1) as case_1, sum(case_2) as case_2, sum(case_3) as case_3
from trash.non_working_hours_account
group by date_id, trading_firm_id;

select *
from trash.non_working_hours_account;
----------------------------

select string_agg(foreign_table_schema || '.' || foreign_table_name, '%,%')
from information_schema.foreign_tables
where foreign_server_name = 'oracle_prod'
  and foreign_table_schema not in ('trash')
  and foreign_table_name ilike any
      ('{CLIENT_ORDER,CONDITIONAL_ORDER,CLIENT_ORDER_LEG,CLIENT_ORDER2AUCTION,CROSS_ORDER,CROSS_ORDER_NO,EXECUTION,CONDITIONAL_EXECUTION,FIX_MESSAGE_JSON,l1_snapshot,REQUEST_FOR_QUOTE,REQUEST_FOR_QUOTE_LEG,strategy_transaction_output,historic_order_algo_parameters}')


select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.data_type, parameters.ordinal_position, *
from information_schema.routines
         left join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
  and routines.routine_schema in ('dash360', 'dash_reporting')
  and routine_definition ilike any
      ('{%staging.client_order%,%staging.client_order2auction%,%staging.conditional_order%,%staging.conditional_execution%,%staging.cross_order%,%staging.execution%,%staging.request_for_quote%,%staging.strategy_transaction_output%}')


select *
from pg_views
where definition ilike any
      ('{%staging.client_order%,%staging.client_order2auction%,%staging.conditional_order%,%staging.conditional_execution%,%staging.cross_order%,%staging.execution%,%staging.request_for_quote%,%staging.strategy_transaction_output%}')
