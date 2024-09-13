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
  and routines.routine_schema not in ('trash', 'pg_catalog', 'information_schema');

select * from trash.so_fix_execution_column_text_;

do
$$
    declare
        l_rec record;
    begin
        for l_rec in (select *
                      from trash.so_fix_execution_column_text_
                      where new_script is not null
                        and execution_order > 0
                        and not was_executed
                      order by execution_order)
            loop

                execute l_rec.new_script;
                update trash.so_fix_execution_column_text_
                set was_executed = true
                where routine_schema = l_rec.routine_schema
                  and routine_name = l_rec.routine_name;
                commit;
            end loop;
    end;
$$;