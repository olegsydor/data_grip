select pid, state, application_name, user, wait_event, query_start::timestamp as query_start, age(clock_timestamp(), query_start) as age, usename, query, state
	from pg_stat_activity
	where true
	and state in ('active', 'idle in transaction')
	and query not ilike '%pg_stat_activity%'
--	and query not ilike '%vacuum%'
	and query not ilike '%replicat%'
--	and query ilike '%f_paren%'


select * from trash.kill_long_process('DBeaver Oleh.Sydor', 30);

create or replace function trash.kill_long_process(in_process_name text, in_interval int4) -- ETL: f_parent_order_process
    returns jsonb
    language plpgsql
as
$$
declare
    l_load_id int;
    l_step_id int;
    l_pid     int4;
    l_timeout int4;
    l_ended   bool;
    l_message text;

begin

    select pid,
           extract(seconds from age(clock_timestamp(), query_start))--, state, application_name, user, wait_event, query_start::timestamp as query_start, age(clock_timestamp(), query_start) as age, usename, query, state
    into l_pid, l_timeout
    from pg_stat_activity
    where true
      and state in ('active', 'idle in transaction')
      and query not ilike '%pg_stat_activity%'
      and query not ilike '%replicat%'
      and application_name ilike in_process_name
      and extract(seconds from age(clock_timestamp(), query_start)) > in_interval;

    if l_pid is not null then
        select into l_ended pg_cancel_backend(l_pid);

        select nextval('public.load_timing_seq') into l_load_id;
        l_step_id := 1;
        l_message = in_process_name || 'was killed because it was running for ' || l_timeout::text || ' sec. ' ||
                    in_interval::text || ' was allowed.';
--         raise notice '%', l_message;

        select public.load_log(l_load_id, l_step_id, l_message, 0, 'O')
        into l_step_id;

        return json_build_object('pid', l_pid, 'process', in_process_name, 'timeout', l_timeout);
    end if;
    return '{}'::jsonb;
end ;
$$



