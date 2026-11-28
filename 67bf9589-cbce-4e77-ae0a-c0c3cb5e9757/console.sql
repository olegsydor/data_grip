-- DROP PROCEDURE db_management.data_rolloff(varchar, varchar, int4);

CREATE OR REPLACE PROCEDURE db_management.data_rolloff(IN in_schema_name character varying, IN in_table_name character varying, IN in_date_id integer DEFAULT (to_char((date_trunc('year'::text, (CURRENT_DATE)::timestamp with time zone) - '7 years 1 day'::interval), 'YYYYMMDD'::text))::integer)
 LANGUAGE plpgsql
AS $procedure$
-- SY 20260615 https://dashfinancial.atlassian.net/browse/DS-10954 l_execution_table has been added to distinguish tail logic and non-tail

declare
	l_date_id int4;
	l_load_id int4;
	l_row_ct int;
	l_step_id int;
    l_sql varchar;
    ret_par record;
    dt_id varchar;
	join_cond varchar;
	l_client_order_table varchar;
	l_execution_table varchar;
	l_input_table varchar;
    l_env varchar;
    l_conditional_order_table varchar;

begin

	l_date_id:=in_date_id;
	select nextval('public.load_timing_seq') into l_load_id;
	l_step_id:=0;

   	select public.load_log(l_load_id, l_step_id, in_table_name||' rollof started ===', 0, 'B')
	into l_step_id;

    select upper(public.check_environment()) into l_env;

  	select public.load_log(l_load_id, l_step_id, 'ENVIRONMETN: '||l_env, 0, 'S')
	into l_step_id;

    IF l_env = 'PROD_TAIL'
     then l_client_order_table:='staging.client_order';
		  l_execution_table:='dwh.execution_tail2';
          l_conditional_order_table:='staging.conditional_order';
     else
		  l_client_order_table:='dwh.client_order';
		  l_execution_table:='dwh.execution';
		  l_conditional_order_table:='staging.conditional_order';
    end if;

   	l_input_table:=format('%I.%I', in_schema_name, in_table_name);


	select format('%I', trim(both '"' from tr.key_field)),
	       COALESCE(l_date_id,
					case
				       when upper(tp.part_schedule) in ('MONTH', 'YEAR')
				       then public.get_dateid((date_trunc( 'month', (current_date - (tr.retention_period || ' ' || tr.cleanup_schedule)::interval))+ interval '1 month - 1 day')::date)
				       else public.get_dateid((current_date - (tr.retention_period || ' ' || tr.cleanup_schedule)::interval)::date)
			       end )
	into dt_id,
	     l_date_id
	from db_management.table_retention tr
	join db_management.table_partman tp on tp.table_name = tr.table_name
	                                  and tp.schema_name = tr.schema_name
	                                  and tp.is_active
	where tr.table_name = in_table_name
	  and tr.schema_name = in_schema_name
	  and tr.is_active
	  and tr.retention_type = 'G';

	if dt_id is null then
		select public.load_log(l_load_id, l_step_id, format('cleanup of the %s is not configured ',l_input_table), 0, 'B')
		into l_step_id;
	end if;

	select public.load_log(l_load_id, l_step_id, 'max l_date_id ='||l_date_id, 0, 'B')
	into l_step_id;

	join_cond:= case when in_table_name like 'execution%' then 'order_id'
		 when in_table_name like 'l1_snapshot%' then 'transaction_id'
		 when in_table_name like 'fix_message_json%' then 'fix_message_id'
		 when in_table_name like 'historic_order_details_storage%' then '"Status_Date_id"'
		 when in_table_name like 'historic_oes_storage%' then '"OrderID"'
	end;

	join_cond:=format('%I', trim(both '"' from join_cond));


	select public.load_log(l_load_id, l_step_id, format('New table is %s','gtc_records_to_retain'), 0, 'B')
	into l_step_id;

-- Creating a new partition

		drop table if exists gtc_records_to_retain;

		l_sql:=format('CREATE TEMP TABLE gtc_records_to_retain (LIKE %s);', l_input_table);

		raise notice'%', l_sql;

		execute l_sql;

		select load_log(l_load_id, l_step_id, 'gtc_records_to_retain CREATED', 0, 'O')
		into l_step_id;



	select public.load_log(l_load_id, l_step_id, 'Inserting gtc data into temp table ', 0, 'I')
	into l_step_id;

	if in_table_name like 'fix_message_json%'
		then
          drop table if exists fix_msg_to_retain;
	          l_sql:=format('create temp table fix_msg_to_retain on commit drop as
	    		select  in_tb.fix_message_id , in_tb.date_id
	               from %s in_tb
						join %s co on co.%s = in_tb.%s and co.create_date_id <= %s
				 where in_tb.date_id <= %s
					union
				select  in_tb.fix_message_id , in_tb.date_id
                   from %s in_tb
						join %s e on e.%s = in_tb.%s and e.exec_date_id <= %s
				 where in_tb.date_id <= %s',
				 l_input_table,
				 l_client_order_table,
				 join_cond,
				 join_cond,
				 l_date_id,
				 l_date_id,
				 l_input_table,
				 l_execution_table,
				 join_cond,
				 join_cond,
				 l_date_id,
				 l_date_id);

			execute l_sql;
		get diagnostics l_row_ct = ROW_COUNT;

	select public.load_log(l_load_id, l_step_id, 'create temp table fix_msg_to_retain', l_row_ct, 'I')
	into l_step_id;

	    	analyze fix_msg_to_retain;

	select public.load_log(l_load_id, l_step_id, 'fix_msg_to_retain Analyzed', 0, 'A')
	  into l_step_id;

	l_sql:=format('insert into gtc_records_to_retain
				select f.*
	                  from %s f
	                   inner join fix_msg_to_retain t on t.fix_message_id = f.fix_message_id and t.date_id = f.date_id
	                 where  f.%s <= %s',
				 l_input_table,
				 dt_id,
				 l_date_id);

    elsif in_table_name like 'l1_snapshot%' then
        drop table if exists l1_snapshot_to_retain;
        l_sql := format('create temp table l1_snapshot_to_retain on commit drop as
        select  in_tb.transaction_id, in_tb.start_date_id
           from %s_tail2 in_tb
                join %s co on co.%s = in_tb.%s and co.create_date_id <= %s
         where in_tb.start_date_id <= %s
            union
        select  in_tb.transaction_id , in_tb.start_date_id
           from %s_tail2 in_tb
                join %s cnd on cnd.%s = in_tb.%s and cnd.date_id <= %s
         where in_tb.start_date_id <= %s',
                        l_input_table,
                        l_client_order_table,
                        join_cond,
                        join_cond,
                        l_date_id,
                        l_date_id,
                        l_input_table,
                        l_conditional_order_table,
                        join_cond,
                        join_cond,
                        l_date_id,
                        l_date_id);

        execute l_sql;
        get diagnostics l_row_ct = ROW_COUNT;


        select public.load_log(l_load_id, l_step_id, 'create temp table l1_snapshot_to_retain', l_row_ct, 'I')
        into l_step_id;

        analyze l1_snapshot_to_retain;

        select public.load_log(l_load_id, l_step_id, 'l1_snapshot_to_retain Analyzed', 0, 'A')
        into l_step_id;

        l_sql := format('insert into gtc_records_to_retain
        select f.*
              from %s_tail2 f
               inner join l1_snapshot_to_retain t on t.transaction_id = f.transaction_id and t.start_date_id = f.start_date_id
             where  f.%s <= %s',
                        l_input_table,
                        dt_id,
                        l_date_id);

		else

		l_sql:=format('
				insert into gtc_records_to_retain
					select distinct in_tb.* from %s in_tb
					join %s co on co.%s = in_tb.%s and co.create_date_id <= %s
						where in_tb.%s <= %s',
						l_input_table,
						l_client_order_table,
						join_cond,
						join_cond,
						l_date_id,
						dt_id,
						l_date_id);
	end if;

		execute l_sql;
		get diagnostics l_row_ct = ROW_COUNT;
		raise notice'%', l_sql;

	select public.load_log(l_load_id, l_step_id, 'Data Load into temp table done', l_row_ct, 'I')
	into l_step_id;


for ret_par in     (select format('%I.%I', child_ns.nspname, child_cls.relname) as part_name
					from pg_inherits inh
					join pg_class parent_cls    on parent_cls.oid = inh.inhparent
					join pg_namespace parent_ns on parent_ns.oid = parent_cls.relnamespace
					join pg_class child_cls     on child_cls.oid = inh.inhrelid
					join pg_namespace child_ns  on child_ns.oid = child_cls.relnamespace
					cross join lateral regexp_matches(
					    pg_get_expr(child_cls.relpartbound, child_cls.oid),
					    'FROM\s*\(([^)]+)\)\s*TO\s*\(([^)]+)\)'
					) as bounds(part_bounds)
					where parent_ns.nspname = in_schema_name
					  and parent_cls.relname = in_table_name
					  and child_cls.relispartition
					  and trim(both '''' from part_bounds[1])::int <= l_date_id::int
					order by 1 desc)
	loop


		l_sql:=format('truncate table %s;', ret_par.part_name);
		execute l_sql;
		raise notice'%', l_sql;
		select public.load_log(l_load_id, l_step_id, 'truncated partition '||ret_par.part_name, 0, 'I')
		into l_step_id;
	end loop;


	select public.load_log(l_load_id, l_step_id, 'inserting gtc data into '||in_table_name, 0, 'I')
	into l_step_id;

	l_sql:=format('insert into %s
			select * from gtc_records_to_retain',
			l_input_table);

	execute l_sql;
	get diagnostics l_row_ct = ROW_COUNT;
	raise notice'%', l_sql;

	select public.load_log(l_load_id, l_step_id, 'gtc data has been inserted into '||in_table_name, l_row_ct, 'I')
	into l_step_id;

	drop table gtc_records_to_retain;

	select public.load_log(l_load_id, l_step_id, 'gtc partition has been dropped', 0, 'I')
	into l_step_id;

select public.load_log(l_load_id, l_step_id, in_table_name||' rollof finished ===', 0, 'B')
into l_step_id;

return;

	EXCEPTION when others then

	  RAISE notice 'Something went wrong: %', clock_timestamp()::text;
	  RAISE notice 'Error: %', sqlerrm;
	  perform public.load_log(l_load_id, l_step_id, sqlstate || ': ' || sqlerrm, 0, 'E');
	  raise;

end;
$procedure$
;

select format('create temp table l1_snapshot_to_retain on commit drop as
	    		select  in_tb.transaction_id, in_tb.start_date_id
	               from %s_tail2 in_tb
						join %s co on co.%s = in_tb.%s and co.create_date_id <= %s
				 where in_tb.start_date_id <= %s
					union
				select  in_tb.transaction_id , in_tb.start_date_id
                   from %s_tail2 in_tb
						join %s cnd on cnd.%s = in_tb.%s and cnd.date_id <= %s
				 where in_tb.start_date_id <= %s',
				 :l_input_table,
				 :l_client_order_table,
				 :join_cond,
				 :join_cond,
				 :l_date_id,
				 :l_date_id,
				 :l_input_table,
				 :l_conditional_order_table,
				 :join_cond,
				 :join_cond,
				 :l_date_id,
				 :l_date_id);

create temp table l1_snapshot_to_retain --on commit drop
    as
	    		select  in_tb.transaction_id, in_tb.start_date_id
	               from l1_snapshot_tail2 in_tb
						join staging.client_order co on co.transaction_id = in_tb.transaction_id and co.create_date_id <= 20200101
				 where in_tb.start_date_id <= 20200101
					union
				select  in_tb.transaction_id , in_tb.start_date_id
                   from l1_snapshot_tail2 in_tb
						join staging.conditional_order cnd on cnd.transaction_id = in_tb.transaction_id and cnd.date_id <= 20200101
				 where in_tb.start_date_id <= 20200101


select format('insert into gtc_records_to_retain
				select f.*
	                  from %s_tail2 f
	                   inner join l1_snapshot_to_retain t on t.transaction_id = f.transaction_id and t.start_date_id = f.start_date_id
	                 where  f.%s <= %s',
				 :l_input_table,
				 :dt_id,
				 :l_date_id);


select format('%I', trim(both '"' from tr.key_field)),
	       COALESCE(:l_date_id,
					case
				       when upper(tp.part_schedule) in ('MONTH', 'YEAR')
				       then public.get_dateid((date_trunc( 'month', (current_date - (tr.retention_period || ' ' || tr.cleanup_schedule)::interval))+ interval '1 month - 1 day')::date)
				       else public.get_dateid((current_date - (tr.retention_period || ' ' || tr.cleanup_schedule)::interval)::date)
			       end )
-- 	into dt_id,
-- 	     l_date_id
-- 	select *
	from db_management.table_retention tr
	join db_management.table_partman tp on tp.table_name = tr.table_name
	                                  and tp.schema_name = tr.schema_name
	                                  and tp.is_active
	where true
	    and tr.table_name = :in_table_name
	  and tr.schema_name = :in_schema_name
-- 	  and tr.is_active
	  and tr.retention_type = 'G';

insert into gtc_records_to_retain
				select f.*
	                  from l1_snapshot_tail2 f
	                   inner join l1_snapshot_to_retain t on t.transaction_id = f.transaction_id and t.start_date_id = f.start_date_id
	                 where  f.start_date_id <= 20190101