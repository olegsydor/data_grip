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


-- dwh.gtc_order_status definition

-- Drop table

-- DROP TABLE dwh.gtc_order_status;
create schema dwh
CREATE TABLE dwh.gtc_order_status (
	order_id int8 NOT NULL,
	create_date_id int4 NOT NULL,
	order_status bpchar(1) NULL,
	exec_time timestamp(6) NULL,
	last_trade_date timestamp(0) NULL, -- It is last_trade_date from instrument for time_in_force_id = 1 or expire_time from client_order for time_in_force_id = 6
	last_mod_date_id int4 NULL,
	is_parent bool NULL, -- if this attr is true the order has been closed because of closing its parent order
	close_date_id int4 NULL,
	account_id int4 NULL, -- account_id from dwh.d_account
	time_in_force_id bpchar(1) DEFAULT '1'::bpchar NULL, -- time_in_force_id - 1 for GTC, 6 - for GTD
	db_create_time timestamp DEFAULT clock_timestamp() NULL,
	db_update_time timestamp NULL,
	closing_reason bpchar(1) NULL, -- 'the order was closed because of¶E - by the execution flow ('2', '4', '8')¶P - by the parent flow (closed street because its parent was closed)¶I - instrument or client order expire time¶L - the one of closed leg has closed the head¶H - the head closed before has closed all non closed legs¶
	client_order_id varchar(256) NULL,
	instrument_id int8 NULL,
	multileg_reporting_type bpchar(1) NULL
)
PARTITION BY RANGE (close_date_id);
CREATE INDEX gtc_order_status_client_order_id_idx ON ONLY dwh.gtc_order_status USING btree (client_order_id);
CREATE INDEX gtc_order_status_order_id_idx ON ONLY dwh.gtc_order_status USING btree (order_id);
