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


select cl.*, da.account_name, dtf.trading_firm_name from t_01 cl
join dwh.d_account da on da.account_id = cl.account_id
join dwh.d_trading_firm dtf on dtf.trading_firm_id = cl.trading_firm_id;


select string_agg(foreign_table_schema||'.'||foreign_table_name,'%,%')
from information_schema.foreign_tables
where foreign_server_name = 'oracle_prod'
and foreign_table_schema not in ('trash')

