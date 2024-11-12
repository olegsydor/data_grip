 select pid, state, application_name, user, wait_event, query_start::timestamp as query_start, age(clock_timestamp(), query_start) as age, usename, query, state
	from pg_stat_activity
	where true
	and state in ('active', 'idle in transaction')
	and query not ilike '%pg_stat_activity%'
--	and query not ilike '%vacuum%'
	and query not ilike '%replicat%'
	and query ilike '%f_paren%'
    and extract(seconds from age(clock_timestamp(), query_start)) > 2