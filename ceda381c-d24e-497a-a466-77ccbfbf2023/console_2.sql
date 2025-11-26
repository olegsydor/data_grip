select * from dq.get_unmatched_orders(20251126,20251126,true);

dq.load_internal_dc_client_order_matching();

select * from (
 select pid, state, application_name, user, wait_event, query_start::timestamp as query_start, age(clock_timestamp(), query_start) as age, usename, query, state
	from pg_stat_activity
	where true
	and state in ('active', 'idle in transaction')
	and query not ilike '%pg_stat_activity%'
--	and query not ilike '%vacuum%'
--	and query not ilike '%replicat%'
--	and query ilike '%load_algorithmic_order_analytic%'
	union all
	select null, null, null as application_name, null, null, null as query_start, null as age, null, null, null) x
	order by case when coalesce(application_name, 'Sydor') ilike '%Sydor%' then 0 else 1 end,  query_start nulls last;


select * from dq.get_unmatched_orders(20251126,20251126,false);