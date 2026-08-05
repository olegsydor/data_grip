select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.*--data_type, parameters.ordinal_position, parameters.parameter_name
from information_schema.routines
         join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
  and parameter_name ilike any('{%account_id%, %accounts_id%}')
  and not exists (select null
                  from information_schema.routines rt
                           join information_schema.parameters pr on rt.specific_name = pr.specific_name
                  where true
                    and rt.routine_schema in ('dash360', 'dash_reporting')
                    and pr.parameter_name ilike '%trading%'
                    and rt.specific_name = routines.specific_name
                    and pr.parameter_mode = 'IN')
  and parameter_mode = 'IN'
  and routines.routine_schema in ('dash360', 'dash_reporting');


SELECT * FROM (SELECT pid, state, application_name, user, wait_event, query_start::timestamp AS query_start, age(clock_timestamp(), query_start) AS age, usename, query, state FROM pg_stat_activity WHERE true AND state IN ('active', 'idle in transaction') AND query NOT ILIKE '%pg_stat_activity%' UNION ALL SELECT NULL, NULL, NULL AS application_name, NULL, NULL, NULL AS query_start, NULL AS age, NULL, NULL, NULL) x WHERE query ILIKE '%.run_f_parent_order_process%' ORDER BY CASE WHEN coalesce(application_name, 'Sydor') ILIKE '%Sydor%' THEN 0 ELSE 1 END, query_start NULLS LAST


select * from staging.find_in_load_timing('run_f_parent_order_process', 60*21*1)
where true
order by 1 desc, 2 desc;