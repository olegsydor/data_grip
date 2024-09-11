update trash.so_fix_execution_column_text_
set new_script = $insert$

CREATE OR REPLACE PROCEDURE staging.tlnd_load_execution_sp(IN in_l_seq bigint, IN in_step integer, IN in_table_name character varying)
 LANGUAGE plpgsql
AS $procedure$
-- 20240327 MB: https://dashfinancial.atlassian.net/browse/DS-7717 Added fields reject_code, order_create_date_id
-- 20240911 OS: https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
DECLARE
 	date_id_crs refcursor; --for select distinct exec_date_id from staging.tlnd_temp_execution  where rtrim(operation)='I';
	l_sql_block text;
	l_sql_block_rejected text;
	l_sql text;
	l_date_id int;
	l_in_l_seq bigint;
	l_in_date_id_list text;
	l_step_id int;
	l_in_table_name text;
	e1_step int;
	date_id_crs_up refcursor;-- for select distinct exec_date_id from staging.tlnd_temp_execution where rtrim(operation)='UN';
	l_exec_analyze text;
	interval_rez int;
	neighbourhood int;
	last_partition_name text;
	l_sql_block2 text;
	l_row_count int;
	l_max_pg_exec_id bigint;
	l_max_ora_exec_id bigint;
	l_run_condition int;
	l_max_time_stamp timestamp;
	l_max_exec_time timestamp;
	l_partition_name text;
 begin
	--l_step_id :=0;
	l_in_l_seq:= in_l_seq;
	l_step_id:= in_step;



	--==============================================================
	--============ Cheking if table not exists then exit============
	--==============================================================

	l_in_table_name:= 'tlnd_execution_'||in_l_seq::varchar;

	SELECT count(1)
	into l_run_condition
	from information_schema.tables
    	where table_schema = 'staging'
			and table_name =l_in_table_name
	;

	select public.load_log(l_in_l_seq, l_step_id, 'l_run_condition ='||l_run_condition::varchar, 0, 'O')
	into l_step_id;

	if l_run_condition = 0

		then

			return;

	end if;

	--================================================================

	select public.load_log(l_in_l_seq,l_step_id,'staging.tlnd_load_execution STARTED >>>>>>>>'::text,0 ,'S'::text)
	into l_step_id
			;


	l_sql:= 'select string_agg(exec_date_id::varchar,'','')
				from(select distinct exec_date_id
						from staging.tlnd_execution_'||in_l_seq::varchar||'
							where operation =''UN''
					)t';

	EXECUTE l_sql
	into l_in_date_id_list;


	select public.load_log(l_in_l_seq,l_step_id,'l_in_date_id_list = '|| coalesce(l_in_date_id_list::varchar,'null'),0 ,'O'::text)
	into l_step_id
			;


	l_in_table_name:= in_table_name;

	l_sql_block := 'INSERT INTO  &p_partition_name
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													exec_text, is_parent_level, time_in_force_id, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, time_in_force, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id
				 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt > 1
			on conflict (exec_id,exec_date_id) do update
   set /*exec_date_id = coalesce(public.f_insert_etl_reject(''load_temp_execution''::varchar,''execution_202101_exec_id_exec_date_id_idx'',''(exec_date_id= ''||EXCLUDED.exec_date_id||'',exec_id= ''||EXCLUDED.exec_id||'',exec_time = ''||EXCLUDED.exec_time||'')''::varchar),
   EXCLUDED.exec_date_id),*/
		secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
		secondary_order_id= EXCLUDED.secondary_order_id,
		trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
		avg_px= EXCLUDED.avg_px,
		bust_qty= EXCLUDED.bust_qty,
		contra_account_capacity= EXCLUDED.contra_account_capacity,
		contra_broker= EXCLUDED.contra_broker,
		cum_qty= EXCLUDED.cum_qty,
		exch_exec_id= EXCLUDED.exch_exec_id,
		exec_time= EXCLUDED.exec_time,
		exec_type= EXCLUDED.exec_type,
		fix_message_id= EXCLUDED.fix_message_id,
		account_id= EXCLUDED.account_id,
		is_busted= EXCLUDED.is_busted,
		last_mkt= EXCLUDED.last_mkt,
		last_px= EXCLUDED.last_px,
		last_qty= EXCLUDED.last_qty,
		leaves_qty= EXCLUDED.leaves_qty,
		order_id= EXCLUDED.order_id,
		order_status= EXCLUDED.order_status,
		exec_text=EXCLUDED.text_ ,
		is_parent_level = EXCLUDED.is_parent_level,
		time_in_force_id = EXCLUDED.time_in_force_id,
		exec_broker=EXCLUDED.exec_broker,
		dataset_id = EXCLUDED.dataset_id,
		auction_id = EXCLUDED.auction_id,
		match_qty = EXCLUDED.match_qty,
		match_px = EXCLUDED.match_px,
		internal_component_type = EXCLUDED.internal_component_type,
		exchange_id = EXCLUDED.exchange_id,
		contra_trader = EXCLUDED.contra_trader,
		ref_exec_id = EXCLUDED.ref_exec_id,
		reject_code = EXCLUDED.reject_code,
		order_create_date_id = EXCLUDED.order_create_date_id;';


l_sql_block2 := 'INSERT INTO  &p_partition_name
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													exec_text, is_parent_level, time_in_force_id, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, time_in_force, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id
				 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt = 1
			on conflict (exec_id,exec_date_id) do nothing;';
	-- l_sql_block_rejected NO CHANGES in text_ (SO)
	l_sql_block_rejected := 'INSERT INTO staging.execution_rejected
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, time_in_force_id, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt, error_message)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, time_in_force, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt, $1
				 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
				 WHERE rtrim(operation)=''I'' and exec_date_id = $2
				 on conflict (exec_id, dataset_id) do nothing;';

	raise INFO 'SQL prepared';
	--analyze staging.tlnd_temp_execution;

	execute 'analyze staging.tlnd_execution_'||in_l_seq::varchar||';';
	raise INFO '%: analyze DONE', clock_timestamp() ;

	select public.load_log(l_in_l_seq,l_step_id,'analyzed staging.tlnd_execution_'||in_l_seq::varchar,0 ,'O'::text)
	into l_step_id
			;

	open date_id_crs for execute format('select distinct exec_date_id from staging.tlnd_execution_%s  where rtrim(operation)=''I'';',in_l_seq::varchar);
	loop
	fetch date_id_crs into l_date_id;
	exit when not found;

	begin

	select partition_table
	into l_partition_name
	from (SELECT  partition_table,
			  (regexp_matches(partition_range, '\((.*?)\)'))[1] AS partition_start,
			  (regexp_matches(partition_range, 'TO \((.*?)\)'))[1] AS partition_end
				FROM ( SELECT
						  cn.nspname ||'.'|| c.relname AS partition_table,
			      		  pg_get_expr(c.relpartbound, c.oid) AS partition_range
			      	from pg_inherits
				    join pg_class as c on (inhrelid=c.oid)
				    join pg_class as p on (inhparent=p.oid)
					join pg_namespace pn on pn.oid = p.relnamespace
					join pg_namespace cn on cn.oid = c.relnamespace
					where p.relname = 'execution' and pn.nspname = 'dwh'
					and c.relkind not in ('f')
				  ) sub
      ) l
	where l_date_id >= partition_start::int
	and l_date_id < partition_end::int;

		--l_sql := replace (l_sql_block ,'&p_month_id', l_date_id::text);
	l_sql := replace (l_sql_block ,'&p_date_id', l_date_id::text);
	l_sql := replace (l_sql ,'&p_partition_name', l_partition_name);

	raise INFO '%: executing INSERT %', clock_timestamp() , l_date_id;

	EXECUTE l_sql;

	GET diagnostics l_row_count= ROW_COUNT;

 			select public.load_log(
								l_in_l_seq,
								l_step_id,
								l_in_table_name::text||' for '||l_date_id::text,
						COALESCE( l_row_count, 0)::int ,
					'M'::text
				) into l_step_id
			;
	raise INFO '%: DONE INSERT %', clock_timestamp() , l_date_id;

	exception when others then

	execute l_sql_block_rejected
	using ''''|| left(sqlerrm,100) ||'''', l_date_id;

	PERFORM public.load_error_log('tlnd_load_execution_sp FAILED!!! (loaded data to staging.execution_rejected)', 'I', sqlerrm, l_in_l_seq);
	end;

	begin
		--l_sql := replace (l_sql_block2 ,'&p_month_id', l_date_id::text);
	l_sql := replace (l_sql_block2 ,'&p_date_id', l_date_id::text);
	l_sql := replace (l_sql ,'&p_partition_name', l_partition_name);

	raise INFO '%: executing INSERT2 %', clock_timestamp() , l_date_id;
	EXECUTE l_sql;
	raise INFO '%: executing DONE %', clock_timestamp() , l_date_id;

	GET diagnostics l_row_count= ROW_COUNT;

		select public.load_log(
							l_in_l_seq,
							l_step_id,
							l_in_table_name::text||' for '||l_date_id::text,
						COALESCE( l_row_count, 0)::int ,
						'I'::text
						) into l_step_id
					;
	exception when others then

	execute l_sql_block_rejected
	using ''''|| left(sqlerrm,100) ||'''', l_date_id;

	PERFORM public.load_error_log('tlnd_load_execution_sp FAILED!!! (loaded data to staging.execution_rejected)', 'I', sqlerrm, l_in_l_seq);
	end;

	raise INFO 'end loop %', clock_timestamp();
	end loop;

	close date_id_crs;

	raise INFO 'end cursor %', clock_timestamp();

--	l_exec_analyze:= 'analyze partitions.execution_'||left(right(l_in_date_id_list, 8), 6);
--	execute l_exec_analyze;

	neighbourhood:= 3600; --60 min
	last_partition_name:= 'select execution_'||left(right(l_in_date_id_list, 8), 6); --extract last date from date_id_list in format YYYYMM

	select abs(date_part('epoch'::text, clock_timestamp() AT TIME ZONE 'US/Eastern'
										- (clock_timestamp()::date::timestamp AT TIME ZONE 'US/Eastern' + interval '8 hours 15 minutes') --8:15 AM current date
						)
				) into interval_rez;
	--analyze only between 7:15 and 9:15
	if (interval_rez < neighbourhood) then
		perform  dwh.analyse_statistics (in_schema_name => 'partitions', in_table_name => last_partition_name, in_max_interval => 600);
	end if;

if l_in_date_id_list is not null
 then
execute 'UPDATE dwh.execution ex
				SET
				secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
				secondary_order_id= EXCLUDED.secondary_order_id,
				trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
				avg_px= EXCLUDED.avg_px,
				bust_qty= EXCLUDED.bust_qty,
				contra_account_capacity= EXCLUDED.contra_account_capacity,
				contra_broker= EXCLUDED.contra_broker,
				cum_qty= EXCLUDED.cum_qty,
				exch_exec_id= EXCLUDED.exch_exec_id,
				exec_time= EXCLUDED.exec_time,
				exec_type= EXCLUDED.exec_type,
				exec_date_id= EXCLUDED.exec_date_id,
				fix_message_id= EXCLUDED.fix_message_id,
				account_id= EXCLUDED.account_id,
				is_busted= EXCLUDED.is_busted,
				last_mkt= EXCLUDED.last_mkt,
				last_px= EXCLUDED.last_px,
				last_qty= EXCLUDED.last_qty,
				leaves_qty= EXCLUDED.leaves_qty,
				order_id= EXCLUDED.order_id,
				order_status= EXCLUDED.order_status,
				exec_text=EXCLUDED.text_ ,
				is_parent_level = EXCLUDED.is_parent_level,
				time_in_force_id = EXCLUDED.time_in_force,
				exec_broker=EXCLUDED.exec_broker,
				dataset_id = EXCLUDED.dataset_id,
				auction_id = EXCLUDED.auction_id,
				match_qty = EXCLUDED.match_qty,
				match_px = EXCLUDED.match_px,
				internal_component_type = EXCLUDED.internal_component_type,
				exchange_id = EXCLUDED.exchange_id,
				contra_trader = EXCLUDED.contra_trader,
				ref_exec_id = EXCLUDED.ref_exec_id,
				reject_code = EXCLUDED.reject_code,
				order_create_date_id = EXCLUDED.order_create_date_id
			FROM  staging.tlnd_execution_'||in_l_seq::varchar||'  EXCLUDED
				WHERE  ex.exec_id = EXCLUDED.exec_id
				and ex.exec_date_id = EXCLUDED.exec_date_id
				and EXCLUDED.operation=''UN''
				and ex.exec_date_id in('||l_in_date_id_list||')';

	GET diagnostics l_row_count= ROW_COUNT;

	select public.load_log(
						l_in_l_seq,
						l_step_id,
						l_in_table_name::text,
						coalesce (l_row_count,0)::int,
							'U'::text)
						into l_step_id
					;
end if;


raise INFO 'update skiped %', clock_timestamp();
--==========================================================================================================
--======================= p_upd_fact_last_load_time part removed from ETL ==================================
--==========================================================================================================

	--PERFORM dwh.p_upd_fact_last_load_time('execution');

	l_sql:=  'select max(exec_time) from staging.tlnd_execution_'||in_l_seq::varchar ;

	execute l_sql into l_max_exec_time;

  --RAISE NOTICE 'execution ID %', l_max_exec_id;
 	RAISE NOTICE 'Time %', l_max_exec_time;
  --RETURN l_max_process_time;

  l_max_time_stamp := l_max_exec_time;

  insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
  select 'EXECUTION' as table_name
         , l_max_time_stamp as latest_load_time
         , clock_timestamp() as pg_db_updated_time
  on conflict (table_name) do
  update set
    latest_load_time = greatest(fact_last_load_time.latest_load_time, excluded.latest_load_time),
    pg_db_updated_time = excluded.pg_db_updated_time;

	select public.load_log(l_in_l_seq,l_step_id,'p_upd_fact_last_load_time finished ', 0,'F')
		into l_step_id;



	execute 'select count(distinct exec_id) from staging.tlnd_execution_'||in_l_seq::varchar /*where rtrim(operation)=''I'' and cnt > 1*/
	into l_row_count;

	raise notice ' l_row_count = %', l_row_count;


	l_sql:= 'select string_agg(exec_date_id::varchar,'','')
				from(select distinct exec_date_id
						from staging.tlnd_execution_'||in_l_seq::varchar||'
					)t';

	EXECUTE l_sql
	into l_in_date_id_list;

	perform  public.etl_subscribe(l_in_l_seq, 'yield_capture', 'execution', l_in_date_id_list::varchar,coalesce(l_row_count,0)::int ) ;

	execute	'select count(1)
	from (select public.etl_subscribe('||in_l_seq||'::bigint, ''f_parent_order''::varchar, ''execution''::varchar, exec_date_id::varchar, count(1)::int )
			from staging.tlnd_execution_'||in_l_seq::varchar||'
							where not is_parent_level
							      and is_busted <> ''Y''
							      and exec_type in (''F'', ''0'', ''W'')
	group by exec_date_id) l'
	into l_row_count;

	--execute 'drop table if exists staging.tlnd_execution_'||in_l_seq::varchar;


	select public.load_log(l_in_l_seq,l_step_id,'staging.tlnd_load_execution FINISHED >>>>>>>>'::text,0 ,'S'::text)
	into l_step_id
			;

	--RETURN l_step_id;

 end;
$procedure$
;


    $insert$
where true
  and routine_schema = 'staging'
  and routine_name = 'tlnd_load_execution_sp'
  and new_script is null;