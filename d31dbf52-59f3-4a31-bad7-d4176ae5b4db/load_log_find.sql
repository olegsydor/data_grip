with base
         as (select distinct on (rt.routine_schema, rt.routine_name) substring(routine_definition FROM 'public\.load_log\(\s*([^,]+)') as load_log_substr,
                                                                     rt.specific_schema,
                                                                     rt.specific_name,
                                                                     routine_definition
             from information_schema.routines rt
                      left join information_schema.parameters pm on rt.specific_name = pm.specific_name
             where true
               and routine_name !~~* all (ARRAY ['%_bkp%', '%_old%', '%_tst%', '%_test%'])
               and rt.routine_schema not in ('trash', 'pg_catalog', 'information_schema')
               and routine_definition ilike $$%public.load_log%$$)
select specific_schema,
       specific_name,
       load_log_substr,
       substring(routine_definition, format('select\s+nextval\(''([^'']+)''\)\s+into\s+%s', load_log_substr)),
       routine_definition
from base;


	select nextval('public.load_timing_seq') into l_load_id;
	l_step_id:=0;


	select nextval('public.load_timing_seq') into l_load_id;


 declare
	l_row_cnt integer;
	l_row_cnt_2 integer;
	l_exec_id integer;
	l_load_id int;
	l_step_id int;
	l_batch_id int8;
begin
	select public.load_log(l_load_id, l_step_id, 'performMarketClose STARTED  ===', 0, 'O')
	into l_step_id;

	select staging.util_next_sfid() into l_batch_id;

	insert into dwh.execution (exec_id,dataset_id,exec_time,exec_date_id,exch_exec_id,order_id,order_status,exec_type,leaves_qty,cum_qty,avg_px,last_qty,last_px,account_id,is_parent_level,time_in_force_id,auction_id,is_busted)
		select
			staging.util_next_sfid() as exec_id, -- get custom seq
			l_batch_id as dataset_id,
			to_timestamp(in_date_id::text, 'YYYYMMDD') + interval '20:00:00' AS exec_time,
			in_date_id as exec_date_id,
			'NONE' as exch_exec_id,
			co.order_id as order_id,
			'3' as order_status,
			'3' as exec_type,
			e.leaves_qty as leaves_qty,
			e.cum_qty as cum_qty,
			e.avg_px as avg_px,
			0 as last_qty,
			0 as last_px,
			co.account_id as account_id,
			CASE WHEN co.order_class = 'R' THEN true ELSE false END as is_parent_level,
			co.time_in_force_id as time_in_force_id,
			(select min(coa.auction_id) from dwh.client_order2auction coa where coa.order_id = co.order_id and coa.create_date_id = in_date_id) as auction_id,
			'N'
		from dwh.client_order co
		join dwh.d_instrument di on co.instrument_id = di.instrument_id and di.instrument_type_id = in_instrument_type_id
		LEFT JOIN LATERAL (
		    SELECT e.*
		    FROM dwh.execution e
		    WHERE e.order_id = co.order_id and e.exec_date_id = in_date_id
		    ORDER BY e.exec_time DESC, e.exec_id DESC
		    LIMIT 1
		) e ON TRUE
		where co.create_date_id = in_date_id
		and co.multileg_reporting_type in ('1', '2')
		and co.order_id not in (
			select e.order_id from dwh.execution e
			where e.exec_date_id = in_date_id
			and e.order_id = co.order_id
			and e.order_status in ('4', '8', '2', '3', 'C', 'B')
--			and e.fix_message_id is null -- testing **********************************
		);

	get diagnostics l_row_cnt = row_count;

	select public.load_log(l_load_id, l_step_id, 'performMarketClose 1  ===', l_row_cnt, 'O')
	into l_step_id;


	with co as
		(select * from dwh.client_order co
			join d_instrument di on co.instrument_id = di.instrument_id and di.instrument_type_id = in_instrument_type_id
			where (co.order_id,co.create_date_id) in (
				select order_id,gos.create_date_id  from dwh.gtc_order_status gos
				where gos.create_date_id < in_date_id
				and (gos.close_date_id is null or gos.close_date_id = in_date_id)
				and gos.multileg_reporting_type in ('1', '2')
				and gos.order_id not in (
					select e.order_id from dwh.execution e
					where e.exec_date_id = in_date_id
					and e.order_id = gos.order_id
					and e.order_status in ('4', '8', '2', '3', 'C', 'B'))
			)
		)
	insert into dwh.execution (exec_id,dataset_id,exec_time,exec_date_id,exch_exec_id,order_id,order_status,exec_type,leaves_qty,cum_qty,avg_px,last_qty,last_px,account_id,is_parent_level,time_in_force_id,auction_id,is_busted)
	select
				staging.util_next_sfid() as exec_id, -- get custom seq
				l_batch_id as dataset_id,
				to_timestamp(in_date_id::text, 'YYYYMMDD') + interval '20:00:00' AS exec_time,
				in_date_id as exec_date_id,
				'NONE' as exch_exec_id,
				co.order_id as order_id,
				'3' as order_status,
				'3' as exec_type,
				e.leaves_qty as leaves_qty,
				e.cum_qty as cum_qty,
				e.avg_px as avg_px,
				0 as last_qty,
				0 as last_px,
				co.account_id as account_id,
				CASE WHEN co.order_class = 'R' THEN true ELSE false END as is_parent_level,
				co.time_in_force_id as time_in_force_id,
				(select min(coa.auction_id) from dwh.client_order2auction coa where coa.order_id = co.order_id and coa.create_date_id = in_date_id) as auction_id,
				'N'
	from co
	LEFT JOIN LATERAL (
		SELECT e.*
		FROM dwh.execution e
		WHERE e.order_id = co.order_id
		ORDER BY e.exec_time DESC, e.exec_id DESC
		LIMIT 1
	) e ON TRUE;

	get diagnostics l_row_cnt_2 = row_count;

	select public.load_log(l_load_id, l_step_id, 'performMarketClose 2  ===', l_row_cnt_2, 'O')
	into l_step_id;

	select public.load_log(l_load_id, l_step_id, 'performMarketClose END  ===', l_row_cnt + l_row_cnt_2, 'O')
	into l_step_id;

	return l_row_cnt + l_row_cnt_2;

end;



DECLARE
	l_in_l_seq int;
	l_in_step int;
	l_in_table_name text;
    scr record;
    l_soft_del int;
    l_ins int;
    l_scd int;

 begin
 	l_in_step := in_step;
	l_in_l_seq := in_l_seq;
	l_in_table_name := in_table_name;

    l_soft_del:=0;
    l_ins:=0;
    l_scd:=0;


 	for scr in (select distinct on (customer_or_firm_id, client_customer_or_firm_id, trading_firm_unq_id, operation)
				operation, customer_or_firm_id, customer_or_firm_name, client_customer_or_firm_id, client_customer_or_firm_name, trading_firm_unq_id, trading_firm_id, commit_time
				FROM staging.tlnd_temp_client_customer_or_firm tccf
				left join lateral (select trading_firm_unq_id
								   from dwh.d_trading_firm dtf
								   where dtf.trading_firm_id = tccf.trading_firm_id
								   and is_active) dtf on true
				order by customer_or_firm_id, client_customer_or_firm_id, trading_firm_unq_id, operation) loop

    case scr.operation
 	   when 'D' then update dwh.d_client_customer_or_firm
 	                 set is_active = false,
 	                     date_end = scr.commit_time
 	                 where customer_or_firm_id = scr.customer_or_firm_id
						and client_customer_or_firm_id = scr.client_customer_or_firm_id
						and trading_firm_unq_id = scr.trading_firm_unq_id
 	                   	and is_active;

 	   				 l_soft_del:=l_soft_del+1;

 	   when 'I' then INSERT INTO dwh.d_client_customer_or_firm
						(customer_or_firm_id, customer_or_firm_name, client_customer_or_firm_id, client_customer_or_firm_name, trading_firm_unq_id, trading_firm_id, date_start, is_active)
					select customer_or_firm_id, customer_or_firm_name, client_customer_or_firm_id, client_customer_or_firm_name, trading_firm_unq_id, trading_firm_id, commit_time, true
				FROM staging.tlnd_temp_client_customer_or_firm tccf
				left join lateral (select trading_firm_unq_id
								   from dwh.d_trading_firm dtf
								   where dtf.trading_firm_id = tccf.trading_firm_id
								   and is_active) dtf on true
				ON CONFLICT ((CASE WHEN is_active THEN customer_or_firm_id ||'#'|| client_customer_or_firm_id ||'#'|| trading_firm_unq_id END)) DO NOTHING;

 	                 l_ins:=l_ins+1;

 	   when 'U' then
 	               update dwh.d_client_customer_or_firm
 	                 set is_active = false,
 	                     date_end = scr.commit_time
 					where customer_or_firm_id = scr.customer_or_firm_id
						and client_customer_or_firm_id = scr.client_customer_or_firm_id
						and trading_firm_unq_id = scr.trading_firm_unq_id
 	                   and is_active;
 	   else null;

 	   end CASE;

	end loop;

---SCD case
	select count(1) into l_scd
 	    	from staging.tlnd_temp_client_customer_or_firm tccf
				left join lateral (select trading_firm_unq_id
								   from dwh.d_trading_firm dtf
								   where dtf.trading_firm_id = tccf.trading_firm_id
								   and is_active) dtf on true
 	    		where operation in ('U')
				and (customer_or_firm_id, client_customer_or_firm_id, trading_firm_unq_id) in
										(select customer_or_firm_id, client_customer_or_firm_id, trading_firm_unq_id
					  					 from staging.tlnd_temp_client_customer_or_firm tccf
										 left join lateral (select trading_firm_unq_id
															   from dwh.d_trading_firm dtf
															   where dtf.trading_firm_id = tccf.trading_firm_id
															   and is_active) dtf on true
				 	  					 except
				 	  					 select customer_or_firm_id, client_customer_or_firm_id, trading_firm_unq_id
				 	  					 from dwh.d_client_customer_or_firm
				 	  					 where is_active);

    if l_scd <> 0
        then
 	      INSERT INTO dwh.d_client_customer_or_firm
					(customer_or_firm_id, customer_or_firm_name, client_customer_or_firm_id, client_customer_or_firm_name, trading_firm_unq_id, trading_firm_id, date_start, is_active)
										select distinct on (customer_or_firm_id, client_customer_or_firm_id, trading_firm_unq_id)
				customer_or_firm_id, customer_or_firm_name, client_customer_or_firm_id, client_customer_or_firm_name, trading_firm_unq_id, trading_firm_id, commit_time, true
				FROM staging.tlnd_temp_client_customer_or_firm tccf
				left join lateral (select trading_firm_unq_id
								   from dwh.d_trading_firm dtf
								   where dtf.trading_firm_id = tccf.trading_firm_id
								   and is_active) dtf on true
							where operation in ('U')
		  ON CONFLICT ((CASE WHEN is_active THEN customer_or_firm_id ||'#'|| client_customer_or_firm_id ||'#'|| trading_firm_unq_id END)) DO NOTHING;

	get diagnostics l_scd = ROW_COUNT;

	end if;


	select public.load_log(l_in_l_seq, l_in_step,	l_in_table_name, l_soft_del ,'D'::text)
     into l_in_step;

	select public.load_log(l_in_l_seq, l_in_step,	l_in_table_name, l_ins ,'I'::text)
     into l_in_step;

    select public.load_log(l_in_l_seq, l_in_step,	l_in_table_name, l_scd ,'U'::text)
     into l_in_step;

	RETURN l_in_step;

 end;
