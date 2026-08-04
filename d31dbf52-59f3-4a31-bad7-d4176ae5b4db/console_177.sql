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
