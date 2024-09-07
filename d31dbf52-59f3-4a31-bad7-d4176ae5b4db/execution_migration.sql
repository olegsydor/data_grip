/*
create table trash.so_fix_execution_column_text_ as
select distinct on (routines.routine_schema, routines.routine_name) routines.routine_schema,
                                                                    routines.routine_name,
                                                                    routine_definition,
                                                                    md5(routine_definition) as md5_before,
                                                                    clock_timestamp()       as last_update_time,
                                                                    null::text              as new_script,
                                                                    null::int               as execution_order,
                                                                    false::bool             as was_executed
from information_schema.routines
         left join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
  and routine_name !~~* all (ARRAY ['%_bkp%', '%_old%', '%_tst%', '%_test%'])
  and routines.routine_schema not in ('trash', 'pg_catalog', 'information_schema')
  and routine_definition ilike '%text\_%'
  and routine_definition ilike '%execution%';

*/
-- text_ -> exec_text
with base as (select fex.*, case when md5_before = md5(rt.routine_definition) then 'ok' else 'needs to check' end as chk
              from trash.so_fix_execution_column_text_ fex
                       join lateral (select routine_definition
                                     from information_schema.routines
                                     where routines.routine_schema = fex.routine_schema
                                       and routines.routine_name = fex.routine_name
                                     limit 1) rt on true
-- where new_script is null
)
select *
from base
where chk = 'ok'
  and new_script is null
;


