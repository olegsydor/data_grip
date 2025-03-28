-- DROP FUNCTION data_marts.load_yield_capture_inc(_int8, int4, int8);

CREATE OR REPLACE FUNCTION data_marts.load_yield_capture_inc(in_parent_order_ids bigint[] DEFAULT NULL::bigint[], in_date_id integer DEFAULT NULL::integer, in_load_id bigint DEFAULT NULL::bigint)
 RETURNS integer
 LANGUAGE plpgsql
 PARALLEL SAFE
 SET application_name TO 'ETL: Yield Capture incremental'
AS $function$
    -- SY: 20220104 Join to l1_snapshot has been fixed to use order create_date_id. Affects mostly  GTC. It is routing time market data so should
-- SY: 20220104 dwh.get_routing_market_data function has been introduced to improve performance of accessing to foreign partition
-- SO: 20220214 added case for subscriptions when time before 10:00 am
-- SY: 20220504 The dwh.get_dateid(co.parent_order_process_time) fucntion has been introduced https://dashfinancial.atlassian.net/browse/DS-4981
-- SO: 20220513 https://dashfinancial.atlassian.net/browse/DS-5072 Added subscribes for missed market_data
-- SO: 20220527 added using function dwh.get_transaction_time_market_data looking market_data transact_time in str section
-- MB: 20220928 removed join to data_marts.d_client and changed client_src_id with client_id_text field from dwh.client_order
-- AK: 20221208 added customer_or_firm_id field to populating
-- PD  20230124 PD https://dashfinancial.atlassian.net/browse/DS-6278 added coalesce for day_cum_qty in str insert
-- AK: 20230202 due performance degradation added adittional condition in second select of union "and ft.date_id = any (l_date_ids)". We are talking about insert into orders_to_process table statement.
-- AK: 20230203 due performance degradation added changed join type from inner join on inner join lateral in insert into orders_to_process table
-- AK: 20230313 https://dashfinancial.atlassian.net/browse/DS-6356 added perform staging.foreign_key_error_fix 	to exception handling
-- MB: 20230316 changed	orders_to_process table filling logic with the use of time_in_force field in execution
-- SY: 20230321 added analyse_statistics_quick function invocation for perfomance stability
-- VP: 20230321 https://dashfinancial.atlassian.net/browse/DS-6305 pt_basket_id is now extracted from client_order instead of flat_trade_record
-- MB: 20230421 https://dashfinancial.atlassian.net/browse/DS-6657 improved orders_to_process when in_parent_order_ids is not null and minor code refactoring
-- SY: 20230602 https://dashfinancial.atlassian.net/browse/DS-6818 wave_no logic has been reverted
-- SY: 20230606 https://dashfinancial.atlassian.net/browse/DS-6818 second iterration of wave_no has been refactored. GTC only affected
-- SY: 20230620 https://dashfinancial.atlassian.net/browse/DS-6899 Fixed issue with cancel only for street level
-- MB: 20230622 https://dashfinancial.atlassian.net/browse/DS-5618 added handling of fyc fields overflows
-- SY: 20230704 https://dashfinancial.atlassian.net/browse/DS-6975 pre_str temp table has been introduced to improve wave_no calculation for missed market data cases
-- AK: 20240315 https://dashfinancial.atlassian.net/browse/DS-8098 FYC : missed today's GTC & GTD orders during etl
-- SY: 20240419 https://dashfinancial.atlassian.net/browse/DS-8239 Join to client_order_id for GTC/GTD has been refatored to use newly added order_create_date_id field
-- 																   The https://dashfinancial.atlassian.net/browse/DS-8098 has been reverted
-- PD: 20240423 https://dashfinancial.atlassian.net/browse/DS-7040 changed the way we calculate customer_or_firm field for street orders
-- PD: 20240826 https://dashfinancial.atlassian.net/browse/DS-8345 changed the way we calculate customer_or_firm field for parent HFT orders
-- SY: 20240903 Close subscription has been added in case of empty subscriptions
-- MB: 20240925 https://dashfinancial.atlassian.net/browse/DS-8944 added orig_order_id field to FYC ETL
DECLARE
  --  row_rcd                        record;
  --  r                         record;
    row_cnt                   int;
    l_orders_to_process       int;
    l_date_ids                int[];
    l_min_order_date_id       int;
    l_batch_ids_to_process    bigint[];
    l_strategy_batch_ids_list bigint[];
    l_loop_id                 bigint;
    l_load_id                 bigint;
    l_step_id                 int;
    l_ratio                   numeric;
    l_gtc_orders              bigint[];
    l_ftr_to_process          bigint[];

begin

  if in_load_id is null
   then
  select nextval('public.load_timing_seq') into l_load_id;
   l_step_id:=1;
   else l_load_id:= in_load_id;
     select max(step)+1 into l_step_id
     from public.load_timing
     where load_timing_id = l_load_id;
  end if;


   select public.load_log(l_load_id, l_step_id, 'Yield Capture STARTED ===', 0, 'B')
   into l_step_id;

-- RAISE info 'l_load_id: % ', l_load_id;
  l_orders_to_process:=0;

if in_parent_order_ids is null
 then

  l_batch_ids_to_process:= array(select distinct load_batch_id from public.etl_subscriptions
                     where subscription_name='yield_capture' and source_table_name='execution' and not is_processed
                     --and date_id is not null
                     and date_id >=get_dateid(current_date-63)
                     --and subscribe_time >= current_date - interval '63 days'
--                     and load_batch_id <> 105541523
                     order by load_batch_id
                     --limit case when clock_timestamp()::time between '07:29'::time and  '10:30'::time then 5 else 50 end
                     limit case when clock_timestamp()::time between '07:29'::time and '9:29:59'::time then 7
                     			when clock_timestamp()::time between '09:30'::time and '9:47:59'::time then 3
                     			when clock_timestamp()::time between '9:48'::time and '9:59:59'::time then 4
                     			when clock_timestamp()::time between '10:00'::time and '10:29:59'::time then 5
								when clock_timestamp()::time between '10:30'::time and '10:55'::time then 6
                     			else 10 end
                     );
   select public.load_log(l_load_id, l_step_id, 'l_batch_ids_to_process size is '|| left(array_to_string(l_batch_ids_to_process, ','),200), cardinality(l_batch_ids_to_process), 'O')
   into l_step_id;

      l_strategy_batch_ids_list:=array(select null::int where 1=2);

   select public.load_log(l_load_id, l_step_id, 'l_strategy_batch_ids_list '|| left(array_to_string(l_strategy_batch_ids_list, ','),200) , cardinality(l_strategy_batch_ids_list), 'O')
   into l_step_id;

  l_ftr_to_process:= array(select distinct load_batch_id from public.etl_subscriptions
                     where subscription_name='yield_capture' and source_table_name in ('flat_trade_record', 'l1_snapshot') and not is_processed
                     --and date_id is not null
                     and date_id >=get_dateid(current_date-73)
                     --and subscribe_time >= current_date - interval '63 days'
                     order by 1
					 limit case
	                     when clock_timestamp()::time  between '07:29'::time and '9:59:59'::time then 20000
	                     --when clock_timestamp()::time between '10:00'::time and '10:30'::time then 25000
	                     else 50000 end
                     --limit 10
                     --limit case when clock_timestamp()::time  between '07:29'::time and  '10:30'::time then 500 else 5000 end
--                     limit 50
                     );
   select public.load_log(l_load_id, l_step_id, 'l_ftr_to_process size is '|| left(array_to_string(l_ftr_to_process, ','),200), cardinality(l_ftr_to_process), 'O')
   into l_step_id;

--  select count(1)  into row_cnt
--   from public.etl_subscriptions
--   where subscription_name='yield_capture' and source_table_name='flat_trade_record' and not is_processed
--                   --and date_id is not null
--     and date_id >=20201101;
--
--       select public.load_log(l_load_id, l_step_id, 'opened subscriptions' , row_cnt, 'O')
--   into l_step_id;


l_date_ids :=   array(select distinct date_id from public.etl_subscriptions
                     where subscription_name='yield_capture' and source_table_name in ('execution', 'l1_snapshot', 'flat_trade_record') and not is_processed
                     and date_id is not null
                     and load_batch_id = any (l_batch_ids_to_process||l_strategy_batch_ids_list||l_ftr_to_process)
--                    limit case when clock_timestamp()::time < '08:00' then 2 else 15 end
                     );

   select public.load_log(l_load_id, l_step_id, 'date_ids to process '||left(array_to_string(l_date_ids,','), 200), cardinality(l_date_ids), 'O')
   into l_step_id;

--RAISE info 'l_batch_ids_to_process: % ', array_to_string(l_batch_ids_to_process,',');
--RAISE info 'l_date_ids: % ', array_to_string(l_date_ids,',');

  -- SY We need to introduce time_in_force field there
create temp table if not exists orders_to_process (order_id bigint, date_id int, event_date_id int );

execute 'truncate table orders_to_process';
analyze orders_to_process;
select public.load_log(l_load_id, l_step_id, 'truncate table orders_to_process ', 0, 'T')
   into l_step_id;
execute 'SET enable_hashjoin = false';
-- execute 'SET enable_mergejoin = false';

if (clock_timestamp()::time  between '04:00'::time and '16:30'::time)-- or (clock_timestamp()::time  between '15:30'::time and  '16:30'::time)
   then
    perform  db_management.analyse_statistics_quick();

    select public.load_log(l_load_id, l_step_id, 'statistics refreshed ', 0, 'I')
     into l_step_id;
end if;

insert into  orders_to_process
	select coalesce(co.parent_order_id, co.order_id) as order_id,
       		case when co.parent_order_id is null
            	then co.create_date_id
            	else public.get_gth_date_id_by_instrument(co.parent_order_process_time, co.instrument_id)
        	end as date_id,
        	ex.exec_date_id as event_date_id
		    from dwh.execution  ex
		    inner join dwh.client_order co on (ex.order_id = co.order_id and co.create_date_id = ex.exec_date_id)
		  	where ex.dataset_id = any (l_batch_ids_to_process)
		    and ex.exec_date_id = any (l_date_ids)
		    and order_status <> '3'
		    AND CO.MULTILEG_REPORTING_TYPE in ('1', '2')
			AND CO.TRANS_TYPE not IN('F')
			and ex.time_in_force_id not in ('1', '6')
			and ex.exec_type <>'D'
	union
	select coalesce(co.parent_order_id, co.order_id) as order_id,
--				co.date_id,
			case when co.parent_order_id is null
            	then co.create_date_id
            	else public.get_gth_date_id_by_instrument(co.parent_order_process_time, co.instrument_id)
        	end as date_id,
			ex.exec_date_id as event_date_id
		    from dwh.execution  ex
		    inner join dwh.client_order co on (ex.order_id = co.order_id and co.create_date_id = ex.order_create_date_id)
--		    join lateral(
--		    	select co.parent_order_id,
--		               co.order_id,
--		               case when co.parent_order_id is null
--		                  then co.create_date_id
--		                  else public.get_gth_date_id_by_instrument(co.parent_order_process_time, co.instrument_id)
--		               end as date_id
--		    	from dwh.gtc_order_status gos
--		      	join dwh.client_order co
--		        on gos.order_id = co.order_id
--		        and gos.create_date_id = co.create_date_id
--		        and co.multileg_reporting_type in ('1','2')
--		        and co.trans_type <> 'F'
--		        and	gos.close_date_id is null
--		        where (ex.order_id = gos.order_id)
--		        limit 1) co on true
		  	where ex.dataset_id = any (l_batch_ids_to_process)
		    and ex.exec_date_id = any (l_date_ids)
		    and ex.order_status <> '3'
			and ex.time_in_force_id in ('1', '6')
			and ex.exec_type <>'D'
			AND CO.MULTILEG_REPORTING_TYPE in ('1', '2')
			AND CO.TRANS_TYPE not IN('F')


     union
     Select load_batch_id as order_id, f.date_id, s.date_id::int as event_date_id
           from public.etl_subscriptions s
             inner join lateral (select get_dateid(order_process_time) as date_id
                                 from flat_trade_record ft
                                 where ft.order_id = s.load_batch_id
                                 and ft.date_id= s.date_id
                                 and ft.date_id = any (l_date_ids)
                                 limit 1) f on true
             where subscription_name='yield_capture' and source_table_name in ('flat_trade_record') and not is_processed
               and s.date_id is not null
               and load_batch_id = any (l_ftr_to_process)
--     union
--     select coalesce(co.parent_order_id, co.order_id) as order_id,
--       		case when co.parent_order_id is null
--            then co.create_date_id
--            else public.get_gth_date_id_by_instrument(co.parent_order_process_time, co.instrument_id)
--        	end as date_id,
--        	ex.exec_date_id as event_date_id
--		    from dwh.execution  ex
--		    inner join dwh.client_order co on (ex.order_id = co.order_id and co.create_date_id = ex.exec_date_id)
--		  	where ex.dataset_id = any (l_batch_ids_to_process)
--		    and ex.exec_date_id = dwh.get_dateid(current_date)
--		    and order_status <> '3'
--		    AND CO.MULTILEG_REPORTING_TYPE in ('1', '2')
--			AND CO.TRANS_TYPE not IN('F')
--			and ex.time_in_force_id in ('1', '6')
--			and ex.exec_type <>'D'
              ;


 GET DIAGNOSTICS row_cnt = ROW_COUNT;
 l_orders_to_process:=l_orders_to_process+row_cnt;

   select public.load_log(l_load_id, l_step_id, 'Order to process ', row_cnt, 'I')
   into l_step_id;

 execute 'SET enable_hashjoin = true';
 execute 'SET enable_mergejoin = true';
 /*===============================================================================================
  * =================== GTC logic ================================================================
  * ============================================================================================== */
-- SY 20220215
-- That is no only GTC order but some reprints via subscriptions
-- So we need return date_id and array of orders then we need to pass that date_id to recursive call.


-- SO 20220523 making gtc_orders as a separate subscription
  with dl as (delete from orders_to_process
      where date_id < dwh.get_dateid(current_date)
      --  where time_in_force_id in ('1', '6')
      RETURNING order_id, date_id, event_date_id)


  select count(public.etl_subscribe(in_load_batch_id := dl.order_id,
  									in_subscription_name := 'yield_capture'::varchar,
                                    in_source_table_name := 'gtc_order'::varchar,
                                    in_row_count := 1,
                                   -- in_date_ids := dl.date_id::text
--                                   in_date_ids :=dwh.get_dateid(current_date)::text
                                    in_date_ids => dl.event_date_id::text))
  from dl
  where not exists(select 1
                           from public.etl_subscriptions es
                           where es.subscription_name = 'yield_capture'
                             and source_table_name = 'gtc_order'
                             and is_processed = false
                             and date_id = dwh.get_dateid(current_date) --dl.date_id
      						 and dl.order_id = es.load_batch_id)
    into row_cnt;

   --l_date_ids := array(select distinct date_id from orders_to_process) ;

-- RAISE info '% orders inserted ', row_cnt;
 else
   create temp table if not exists orders_to_process (order_id bigint, date_id int, event_date_id int /*, time_in_force_id char(1)*/ );

   execute 'truncate table orders_to_process';

  execute 'SET enable_hashjoin = false';
  execute 'SET enable_mergejoin = false';
select * from dwh.d_instrument
    where instrument_id in (1, 3);


insert into orders_to_process
   select distinct ex.order_id, co.create_date_id --, co.time_in_force_id
            from dwh.execution  ex
             inner join dwh.client_order co on (ex.order_id = co.order_id and ex.order_create_date_id = co.create_date_id )
          where ex.order_id = any(:in_parent_order_ids)
            and ex.exec_date_id = :in_date_id
--            and order_status <> '3'
--            and ex.exec_type <>'D'
            and ((order_status <> '3'and ex.exec_type <>'D')
                 or exists (select null
                            from client_order str
                            inner join execution str_ex on (str_ex.order_id= str.order_id and str_ex.order_create_date_id = str.create_date_id and str_ex.exec_date_id = :in_date_id)
                            where str_ex.order_status <> '3'
                              and str_ex.exec_type <>'D'
                              AND str.MULTILEG_REPORTING_TYPE in ('1', '2')
       						  AND str.TRANS_TYPE not IN( 'F')
       						  and str.parent_order_id = co.order_id) )
            AND CO.MULTILEG_REPORTING_TYPE in ('1', '2')
       		AND CO.PARENT_ORDER_ID IS NULL
       		AND CO.TRANS_TYPE not IN( 'F');

   GET DIAGNOSTICS row_cnt = ROW_COUNT;
   l_orders_to_process:=l_orders_to_process+row_cnt;

     select public.load_log(l_load_id, l_step_id, 'Order to process ', row_cnt, 'I')
     into l_step_id;
-- if row_cnt>0 then
--  execute 'analyze public.orders_to_process1';
-- end if;
  execute 'SET enable_hashjoin = true';
  execute 'SET enable_mergejoin = true';

     select count(1) into row_cnt from orders_to_process;

   select public.load_log(l_load_id, l_step_id, 'orders_to_process size ', row_cnt, 'I')
   into l_step_id;

   /* EMPTY arrays to let cursor  runs later */
    l_batch_ids_to_process:=array(select null::int where 1=2);
      l_strategy_batch_ids_list:=array(select null::int where 1=2);
      l_ftr_to_process:=array(select null::int where 1=2);
      l_date_ids := array[in_date_id];


 end if;

 select min(date_id) into l_min_order_date_id
 from orders_to_process;

   select public.load_log(l_load_id, l_step_id, 'date_ids to process '||left(array_to_string(l_date_ids,','), 200), cardinality(l_date_ids), 'O')
   into l_step_id;

  --l_min_order_date_id:= array(select min(date_id)  from public.orders_to_process1);

-- select public.load_log(l_load_id, l_step_id, 'Parent_order min(date_id)='||left(array_to_string(l_min_order_date_id,','), 200), 0, 'I')
--   into l_step_id;
  select public.load_log(l_load_id, l_step_id, 'Parent_order min(date_id)='||l_min_order_date_id::varchar, 0 , 'I')
   into l_step_id;

 --end loop;


  if     l_orders_to_process>0 or cardinality(l_strategy_batch_ids_list)>0
   then
     select ROUND(count(case when date_id = dwh.get_dateid (current_date) then 1 else null end)::numeric/nullif(count(1),0)*100,2) into l_ratio
     from orders_to_process;

  select public.load_log(l_load_id, l_step_id, 'CURRENT_DATE ratio is '||l_ratio, row_cnt, 'I')
   into l_step_id;

-->>
 --> fix of double calculation
 if in_parent_order_ids is not null
 then
   -- drop temporary tables if they exists
   drop table if exists par;
   drop table if exists str;
   drop table if exists str_enriched;
   drop table if exists str_final;
 end if;
--<<

--   RAISE info '% Before first ', clock_timestamp();
 create temp table if not exists par
--  on commit drop
 as
 with p as materialized (select distinct order_id from orders_to_process)
 select co.order_id, co.client_order_id, co.parent_order_id, co.orig_order_id, co.ORDER_TYPE_ID, co.side, co.order_qty, co.price, coalesce(co.transaction_id, transaction_fix.first_transaction) as transaction_id,
                   /*nullif(co.client_id,0) as client_id,*/ co.account_id, nullif(co.sub_strategy_id, -1) as sub_strategy_id, co.instrument_id, co.strtg_decision_reason_code, co.exchange_unq_id,
                   co.process_time as process_time,


                   co.TIME_IN_FORCE_id, co.MULTILEG_REPORTING_TYPE, co.cross_order_id, co.create_date_id, co.trading_firm_unq_id, co.fix_message_id,
                   co.ROUTING_TABLE_ID,
                   i.instrument_type_id,
				  co.client_id_text as client_id_text,
				  cf.customer_or_firm_id,
				  co.pt_basket_id,
				  co.sub_system_unq_id
             from p
              inner join dwh.client_order co on (p.order_id = co.order_id)
              left join lateral (select min(transaction_id) as first_transaction
                                   from dwh.client_order f
                                   where f.parent_order_id = p.order_id
                                      and f.create_date_id = any(:l_date_ids)
                                    limit 1
                                     ) transaction_fix on (1=1)
        inner join dwh.d_instrument i on (co.instrument_id = i.instrument_id)
		left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id::varchar)
        where CO.create_date_id >= :l_min_order_date_id
          AND CO.MULTILEG_REPORTING_TYPE in ( '1', '2')
            AND CO.PARENT_ORDER_ID IS NULL
            AND CO.TRANS_TYPE not IN( 'F') ;

   GET DIAGNOSTICS row_cnt = ROW_COUNT;


  select public.load_log(l_load_id, l_step_id, 'Insert into par ', row_cnt, 'I')
   into l_step_id;


   create temp table if not exists pre_str
--   on commit drop
  as
  select str.order_id, str.client_order_id, str.parent_order_id, str.orig_order_id, str.ORDER_TYPE_ID, str.side, str.order_qty, str.price, str.transaction_id,
         str.account_id, str.sub_strategy_id, str.instrument_id, str.strtg_decision_reason_code, str.exchange_unq_id, str.exchange_id,
         str.process_time,   str.cross_order_id, str.fix_message_id, str.ROUTING_TABLE_ID, str.create_date_id, str.client_id_text as client_id_text,
         par.TIME_IN_FORCE_id, par.MULTILEG_REPORTING_TYPE, par.trading_firm_unq_id, par.sub_strategy_id as parent_sub_strategy_id, par.pt_basket_id,
         coalesce(str.eq_order_capacity, str.customer_or_firm_id) as customer_or_firm_id, min(str.create_time) over (partition by str.parent_order_id, str.transaction_id)  as transaction_time
   from par
    inner join lateral (select * from dwh.client_order str
		                 where str.parent_order_id = par.order_id
		    			   and str.create_date_id >= :l_min_order_date_id
		                   and str.TRANS_TYPE not IN( 'F')
		                limit 1000000) str on true ;

 GET DIAGNOSTICS row_cnt = ROW_COUNT;


  select public.load_log(l_load_id, l_step_id, 'Insert into pre_str ', row_cnt, 'I')
   into l_step_id;

analyze pre_str;
--    create temp table if not exists str
--  on commit drop
--
--
--  as select str.order_id, str.client_order_id, str.parent_order_id, str.ORDER_TYPE_ID, str.side, str.order_qty, str.price, str.transaction_id,
--                   /*nullif(str.client_id,0) as client_id,*/ str.account_id, nullif(str.sub_strategy_id, -1) as sub_strategy_id, str.instrument_id, str.strtg_decision_reason_code, str.exchange_unq_id, str.exchange_id,
--                   str.process_time

--                  as process_time,
--                   par.TIME_IN_FORCE_id, par.MULTILEG_REPORTING_TYPE, str.cross_order_id, par.trading_firm_unq_id,
----      dense_rank() over (partition by par.order_id order by m.transaction_time, str.transaction_id) as wave_no,
----        dense_rank() over (partition by par.order_id order by dwh.get_transaction_time_market_data(in_transaction_id := str.transaction_id, in_date_id := dwh.get_dateid(str.process_time)), str.process_time) as wave_no,
--        dense_rank() over (partition by par.order_id
--                           order by dwh.get_transaction_time_market_data(in_transaction_id := str.transaction_id, in_date_id := dwh.get_dateid(str.process_time)),
--                                    str.transaction_id
--                            ROWS  BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING ) as wave_no,
--                str.fix_message_id,
--              str.ROUTING_TABLE_ID,
--              par.sub_strategy_id as parent_sub_strategy_id,
--              i.instrument_type_id,
--              str.create_date_id,
--              str.client_id_text as client_id_text,
--              cf.customer_or_firm_id,
--			  par.pt_basket_id
--              from par
--                inner join dwh.client_order str on (str.parent_order_id = par.order_id)
--        inner join dwh.d_instrument i on (str.instrument_id = i.instrument_id)
--		left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = str.customer_or_firm_id::varchar)
--       where str.create_date_id >= l_min_order_date_id
--                and str.TRANS_TYPE not IN( 'F');


create temp table if not exists str
--   on commit drop
  as select pre_str.order_id, pre_str.client_order_id, pre_str.parent_order_id, pre_str.orig_order_id, pre_str.ORDER_TYPE_ID, pre_str.side, pre_str.order_qty, pre_str.price, pre_str.transaction_id,
            pre_str.account_id, nullif(pre_str.sub_strategy_id, -1) as sub_strategy_id, pre_str.instrument_id, pre_str.strtg_decision_reason_code, pre_str.exchange_unq_id, pre_str.exchange_id,
            pre_str.process_time, pre_str.TIME_IN_FORCE_id, pre_str.MULTILEG_REPORTING_TYPE, pre_str.cross_order_id, pre_str.trading_firm_unq_id,
        dense_rank() over (partition by pre_str.parent_order_id
                           order by coalesce(dwh.get_transaction_time_market_data(in_transaction_id := pre_str.transaction_id, in_date_id := dwh.get_dateid(pre_str.process_time)),
                                             pre_str.transaction_time), pre_str.transaction_id )as wave_no,
              pre_str.fix_message_id,
              pre_str.ROUTING_TABLE_ID,
              pre_str.parent_sub_strategy_id,
              i.instrument_type_id,
              pre_str.create_date_id,
              pre_str.client_id_text as client_id_text,
              pre_str.customer_or_firm_id,
			  pre_str.pt_basket_id
              from pre_str
        inner join dwh.d_instrument i on (pre_str.instrument_id = i.instrument_id);
--		left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = pre_str.customer_or_firm_id::varchar);


   GET DIAGNOSTICS row_cnt = ROW_COUNT;
select * from str

  select public.load_log(l_load_id, l_step_id, 'Insert into str ', row_cnt, 'I')
   into l_step_id;

   analyse str;

     create temp table if not exists str_enriched
--   on commit drop
  as
  select *
  from (select str.* ,
		      (SELECT CASE
		            WHEN SUM (EA.LAST_QTY) = 0 THEN NULL
		            ELSE SUM (EA.LAST_QTY * EA.LAST_PX) / NULLIF(SUM (EA.LAST_QTY) ,0)
		          END
		        FROM dwh.flat_trade_record EA
		        WHERE   EA.street_ORDER_ID = str.ORDER_ID
		        AND EA.IS_BUSTED <> 'Y'
		        and date_id >= :l_min_order_date_id) as avg_px,
		        /* SY Why do we have dense_rank inside least again !?!?!!*/
        least(str.wave_no /*, dense_rank() over (partition by str.parent_order_id order by str.process_time, str.transaction_id)*/, 32766  ) as str_wave_no,
           ex.exec_date_id, EX.CUM_QTY, ex.exec_time as ex_exec_time, ex.order_status, ODCS.*,
           exch.real_exchange_id
     from str
        inner join lateral (SELECT e.exec_date_id, E.CUM_QTY, e.exec_time, e.order_status
                                 , row_number () over (partition by order_id order by exec_id desc) as rn
                   			FROM EXECUTION E
                  			WHERE     E.ORDER_ID = str.ORDER_ID
                        		--  AND e.exec_date_id = str.create_date_id
                  			      and  e.exec_date_id = any(:l_date_ids) -- SY: 20211216
                          		  AND E.ORDER_STATUS <> '3') ex on (ex.rn=1)
         inner join dwh.d_exchange exch on (str.exchange_unq_id = exch.exchange_unq_id)
        left join lateral (select
                                  sum(last_qty) as DAY_CUM_QTY,
                                  --str.order_id,
                                  ft.date_id as TRADE_DATE_ID,
                                  SUM (ft.LAST_QTY * ft.LAST_PX) / NULLIF(SUM (ft.LAST_QTY),0)  DAY_AVG_PX,
                                  max(ft.trade_record_time) as exec_time,
                                  min(ft.leaves_qty) as leaves_qty
                           from  flat_trade_record ft
                            where ft.date_id= any(:l_date_ids)
                            and str.order_id = ft.street_order_id and ft.is_busted='N'
                           -- and ft.date_id = ex.exec_date_id -- SY: 20211216
                            group by ft.date_id
                            limit 100000)  ODCS   ON (1=1 )
             )l
            where  (str_wave_no<=1000 or TRADE_DATE_ID is not null);

   GET DIAGNOSTICS row_cnt = ROW_COUNT;
select * from str_enriched

  select public.load_log(l_load_id, l_step_id, 'Insert into str_enriched ', row_cnt, 'I')
   into l_step_id;

   analyse str_enriched;

    create temp table if not exists str_final
  on commit drop
  as
    select str.order_id, str.client_order_id, str.parent_order_id, str.orig_order_id, /*ex.*/str.exec_date_id as Status_Date_Id,
      str.cross_order_id, str.MULTILEG_REPORTING_TYPE, str.TIME_IN_FORCE_id,
      /*ODCS*/str.leaves_qty as DAY_LEAVES_QTY, /* Potentially bug */
      str.ORDER_TYPE_ID, str.side, str.order_qty, str.price, str.transaction_id,
          /*str.client_id,*/ str.account_id, str.sub_strategy_id, str.instrument_type_id, str.instrument_id, str.strtg_decision_reason_code,
          greatest(coalesce(STR.ORDER_QTY - /*ex.*/str.CUM_QTY +coalesce (/*ODCS*/str.DAY_CUM_QTY, 0),0), -2147483648) as Day_Order_Qty,
          coalesce (/*ODCS*/str.DAY_CUM_QTY, 0) as Day_Cum_Qty,
         ROUND (coalesce (/*ODCS*/str.DAY_AVG_PX, 0), 4) as Day_Avg_Px,
           case when str.Order_Type_id = '1' then 'Y'
        when str.Side  = '1' and str.Price >= exch_md.ask_price then 'Y'
        when str.Side <> '1' and str.Price <= exch_md.bid_price then 'Y'
        else 'N'
      end as Is_Marketable,

      case when (STR.ORDER_QTY - /*ex.*/str.CUM_QTY +coalesce (/*ODCS*/str.DAY_CUM_QTY, 0)) > case str.side when '1' then exch_md.ask_qty else  exch_md.bid_qty end then 'O'
        when (STR.ORDER_QTY - /*ex.*/str.CUM_QTY +coalesce (/*ODCS*/str.DAY_CUM_QTY, 0)) < case str.side when '1' then exch_md.ask_qty else  exch_md.bid_qty end then 'U'
        else 'R'
      end as Order_Size_State,

      case  str.side when '1'
                     then case when least(exch_md.ask_qty, str.order_qty)=0 then 0
                        else round(/*ODCS*/str.DAY_CUM_QTY::numeric / NULLIF(least(exch_md.ask_qty, str.order_qty),0)::numeric, 4)
                      end
                     else  case when least(exch_md.bid_qty, str.order_qty)=0 then 0
                        else round(/*ODCS*/str.DAY_CUM_QTY::numeric / NULLIF(least(exch_md.bid_qty, str.order_qty),0)::numeric, 4)
                      end
            end as Yield,

            case when str.SIDE in ('1','3') then  'B'
        when str.SIDE in ('2','4','5','6') then  'S'
        else 'O'
      end as buy_or_sell,
      str.avg_px,
      /*ex.*/str.ex_exec_time,
      str.process_time,
      nbbo.bid_price,
      nbbo.bid_qty,
      nbbo.ask_price,
      nbbo.ask_qty,
      1 as exch_num,
      str.exchange_unq_id,
      str.exchange_id,
     -- exch.real_exchange_id,
      str.real_exchange_id,
      exch_md.bid_price as exch_md_bid_price,
      exch_md.bid_qty 	as exch_md_bid_qty,
      exch_md.ask_price as exch_md_ask_price,
      exch_md.ask_qty 	as exch_md_ask_qty,
      str.trading_firm_unq_id,
     -- least(str.wave_no, dense_rank() over (partition by str.parent_order_id order by str.transaction_id)  ) as wave_no,
     str.str_wave_no as wave_no,
      case when /*ex.*/str.order_status='4' then /*ex.*/str.ex_exec_time else case when /*ODCS*/str.leaves_qty > 0 then null else /*ODCS*/str.exec_time end end as order_end_time,
      str.fix_message_id,
      str.ROUTING_TABLE_ID,
      str.parent_sub_strategy_id,
      /*ODCS*/str.pt_basket_id,
      str.client_id_text,
      str.customer_or_firm_id,
      '***',
      str.transaction_id, 'NBBO'::varchar, str.multileg_reporting_type, str.instrument_id,  str.create_date_id
      from str_enriched str
       left join lateral (select   bid_qty
                                 , bid_price
                                 , ask_qty
                                 , ask_price
                             from dwh.get_routing_market_data(str.transaction_id, 'NBBO'::varchar, str.multileg_reporting_type, str.instrument_id,  str.create_date_id)
                           ) nbbo on (1=1)
       left join lateral (select  sum(bid_qty) as bid_qty
                                , sum(bid_price) as bid_price
                                , sum(ask_qty) as ask_qty
                               , sum(ask_price) as ask_price
                             from dwh.get_routing_market_data(str.transaction_id, str.real_exchange_id, str.multileg_reporting_type, str.instrument_id,  str.create_date_id)
                                  ) exch_md on (1=1);

  GET DIAGNOSTICS row_cnt = ROW_COUNT;


  select public.load_log(l_load_id, l_step_id, 'str_final', row_cnt, 'I')
   into l_step_id;

  perform data_marts.fyc_insert_validation('str_final');

--  	for row_rcd in (select dt  from unnest(l_date_ids) dt where dt >= get_dateid(current_date) )
--	loop
--		execute 'ANALYZE (VERBOSE) dm_partitions.f_yield_capture_'||row_rcd.dt||'';
--	end loop;
--
--	 select public.load_log(l_load_id, l_step_id, 'FYC partition analyse DONE',0, 'I')
--	   into l_step_id;

 if in_parent_order_ids is null
  then
	 select public.load_log(l_load_id, l_step_id, 'staging.foreign_key_error_fix started =====', 0, 'S')
	 into l_step_id;

	 select staging.foreign_key_error_fix('f_yield_capture')
	 into row_cnt;

	 select public.load_log(l_load_id, l_step_id, 'staging.foreign_key_error_fix finished =====', row_cnt, 'E')
	 into l_step_id;

 end if;

 INSERT INTO data_marts.f_yield_capture
           (order_id, client_order_id, parent_order_id, orig_order_id, status_date_id, cross_order_id, MULTILEG_REPORTING_TYPE, TIME_IN_FORCE_id, DAY_LEAVES_QTY,
            order_type_id, side, order_qty, order_price, transaction_id,
            /*client_id,*/ account_id, sub_strategy_id, instrument_type_id, instrument_id, strategy_decision_reason_code, day_order_qty,
            day_cum_qty, day_avg_px, is_marketable, order_size_state, yield, buy_or_sell, avg_px, exec_time, routed_time,
            nbbo_bid_price, nbbo_bid_quantity, nbbo_ask_price, nbbo_ask_quantity, num_exch,
            exchange_unq_id, exchange_id, real_exchange_id, exch_bid_price, exch_bid_quantity, exch_ask_price, exch_ask_quantity, trading_firm_unq_id, wave_no, order_end_time,
            order_fix_message_id,ROUTING_TABLE_ID, parent_sub_strategy_id, pt_basket_id, client_id,customer_or_firm_id)
 select order_id, client_order_id, parent_order_id, orig_order_id, Status_Date_Id,
      cross_order_id, MULTILEG_REPORTING_TYPE, TIME_IN_FORCE_id,
       DAY_LEAVES_QTY, /* Potentially bug */
      ORDER_TYPE_ID, side, order_qty, price, transaction_id,
          account_id, sub_strategy_id, instrument_type_id, instrument_id, strtg_decision_reason_code,
           Day_Order_Qty,
          Day_Cum_Qty,
          Day_Avg_Px,
          Is_Marketable,
          Order_Size_State,
          Yield,
          buy_or_sell,
      avg_px,
      ex_exec_time,
      process_time,
      bid_price,
      bid_qty,
      ask_price,
      ask_qty,
      exch_num,
      exchange_unq_id,
      exchange_id,
     -- exch.real_exchange_id,
      real_exchange_id,
      exch_md_bid_price,
      exch_md_bid_qty,
      exch_md_ask_price,
      exch_md_ask_qty,
      trading_firm_unq_id,
      wave_no,
      order_end_time,
      fix_message_id,
      ROUTING_TABLE_ID,
      parent_sub_strategy_id,
      pt_basket_id,
      client_id_text,
      customer_or_firm_id
    from str_final
    on conflict (order_id, status_date_id) do
			update
			set
				order_qty 		= EXCLUDED.order_qty,
				order_price 	= EXCLUDED.order_price,
				transaction_id 	= EXCLUDED.transaction_id,
				--client_id 		= EXCLUDED.client_id,
				account_id 		= EXCLUDED.account_id,
				sub_strategy_id = EXCLUDED.sub_strategy_id,
				instrument_type_id = EXCLUDED.instrument_type_id,
				instrument_id 	= EXCLUDED.instrument_id,
				strategy_decision_reason_code = EXCLUDED.strategy_decision_reason_code,
				day_order_qty 	= EXCLUDED.day_order_qty,
				day_cum_qty 	= EXCLUDED.day_cum_qty,
				day_avg_px 		= EXCLUDED.day_avg_px,
				is_marketable 	= EXCLUDED.is_marketable,
				order_size_state = EXCLUDED.order_size_state,
				yield			= EXCLUDED.yield,
				buy_or_sell		= EXCLUDED.buy_or_sell,
				avg_px 			= EXCLUDED.avg_px,
				exec_time 		= EXCLUDED.exec_time,
				routed_time 	= EXCLUDED.routed_time,
				nbbo_bid_price 	= EXCLUDED.nbbo_bid_price,
				nbbo_bid_quantity = EXCLUDED.nbbo_bid_quantity,
				nbbo_ask_price 	= EXCLUDED.nbbo_ask_price,
				nbbo_ask_quantity = EXCLUDED.nbbo_ask_quantity,
				num_exch 		= EXCLUDED.num_exch,
				exchange_unq_id = EXCLUDED.exchange_unq_id,
				exch_bid_price 	= EXCLUDED.exch_bid_price,
				exch_bid_quantity = EXCLUDED.exch_bid_quantity,
				exch_ask_price 	= EXCLUDED.exch_ask_price,
				exch_ask_quantity = EXCLUDED.exch_ask_quantity,
				cross_order_id		= EXCLUDED.cross_order_id,
				MULTILEG_REPORTING_TYPE	= EXCLUDED.MULTILEG_REPORTING_TYPE,
				TIME_IN_FORCE_id	= EXCLUDED.TIME_IN_FORCE_id,
				DAY_LEAVES_QTY		= EXCLUDED.DAY_LEAVES_QTY,
				trading_firm_unq_id = EXCLUDED.trading_firm_unq_id,
				order_type_id		= EXCLUDED.order_type_id,
				db_merge_time		= clock_timestamp(),
                wave_no				= EXCLUDED.wave_no,
                order_end_time		= EXCLUDED.order_end_time,
                order_fix_message_id = EXCLUDED.order_fix_message_id,
                ROUTING_TABLE_ID	= EXCLUDED.ROUTING_TABLE_ID,
				parent_sub_strategy_id = EXCLUDED.parent_sub_strategy_id,
				client_id		=EXCLUDED.client_id,
				customer_or_firm_id = EXCLUDED.customer_or_firm_id,
				orig_order_id = EXCLUDED.orig_order_id
;

     GET DIAGNOSTICS row_cnt = ROW_COUNT;


  select public.load_log(l_load_id, l_step_id, 'Street orders', row_cnt, 'I')
   into l_step_id;


   /* ================================== PARENT LEVEL ===================================================================
    * ==================================================================================================================
   */

	create temp table if not exists fyc_insert_table_par as
  	  select par.order_id, par.client_order_id, par.parent_order_id, par.orig_order_id, ex.exec_date_id as status_date_id,
      par.cross_order_id, par.MULTILEG_REPORTING_TYPE, par.TIME_IN_FORCE_id,
      ODCS.leaves_qty as DAY_LEAVES_QTY, /* Potentially bug */
      par.ORDER_TYPE_ID, par.side, par.order_qty, par.price as order_price, par.transaction_id,
          /*par.client_id,*/ par.account_id, par.sub_strategy_id, par.instrument_type_id, par.instrument_id, par.strtg_decision_reason_code as strategy_decision_reason_code,
          greatest(par.ORDER_QTY - coalesce (EX.CUM_QTY,0) +coalesce (ODCS.DAY_CUM_QTY, 0), -2147483648) as Day_Order_Qty,
          coalesce (ODCS.DAY_CUM_QTY, 0) as Day_Cum_Qty,
    	  ROUND (coalesce (ODCS.DAY_AVG_PX, 0), 4) as Day_Avg_Px,
          case when par.Order_Type_id = '1' then 'Y'
        when par.Side  = '1' and par.Price >= nbbo.ask_price then 'Y'
        when par.Side <> '1' and par.Price <= nbbo.bid_price then 'Y'
        else 'N'
      end as Is_Marketable,

      case when (par.ORDER_QTY - EX.CUM_QTY +coalesce (ODCS.DAY_CUM_QTY, 0)) > case par.side when '1' then nbbo.ask_qty else  nbbo.bid_qty end then 'O'
        when (par.ORDER_QTY - EX.CUM_QTY +coalesce (ODCS.DAY_CUM_QTY, 0)) < case par.side when '1' then nbbo.ask_qty else  nbbo.bid_qty end then 'U'
        else 'R'
      end as Order_Size_State,

      case  par.side when '1'
                     then case when least(nbbo.ask_qty, par.order_qty)=0 then 0
                        else round(ODCS.DAY_CUM_QTY::numeric / NULLIF(least(nbbo.ask_qty, par.order_qty),0)::numeric, 4)
                      end
                     else  case when least(nbbo.bid_qty, par.order_qty)=0 then 0
                        else round(ODCS.DAY_CUM_QTY::numeric / NULLIF(least(nbbo.bid_qty, par.order_qty),0)::numeric, 4)
                      end
            end as Yield,

            case when par.SIDE in ('1','3') then  'B'
        when par.SIDE in ('2','4','5','6') then  'S'
        else 'O'
      end as buy_or_sell,
      (SELECT CASE
            WHEN SUM (EA.LAST_QTY) = 0 THEN NULL
            ELSE SUM (EA.LAST_QTY * EA.LAST_PX) / NULLIF(SUM (EA.LAST_QTY),0)
          END
        FROM dwh.flat_trade_record EA
        WHERE   EA.ORDER_ID = par.ORDER_ID
        AND EA.IS_BUSTED <> 'Y'
        and date_id >= :l_min_order_date_id) as avg_px,
      ex.exec_time,
      par.process_time as routed_time,
      nbbo.bid_price as nbbo_bid_price,
      nbbo.bid_qty as nbbo_bid_quantity,
      nbbo.ask_price as nbbo_ask_price,
      nbbo.ask_qty as nbbo_ask_quantity,
      --(select count(distinct exchange_unq_id) from data_marts.f_yield_capture where parent_order_id = par.order_id ) as exch_num ,
      exch_md.num_exchange as num_exch,
      par.trading_firm_unq_id,
      case when ex.order_status='4' then ex.exec_time else case when ODCS.leaves_qty > 0 then null else ODCS.exec_time end end as order_end_time,
      par.fix_message_id as order_fix_message_id,
      par.ROUTING_TABLE_ID,
      par.pt_basket_id,
      par.client_id_text as client_id,
      case when par.sub_system_unq_id = '93' then ODCS.customer_or_firm_id -- HFT parent orders
      	   else par.customer_or_firm_id end as customer_or_firm_id,

  	      par.transaction_id, 'NBBO'::varchar, par.multileg_reporting_type, par.instrument_id,   par.create_date_id

            from par
--                inner join dwh.d_instrument i on (par.instrument_id = i.instrument_id)
               -- inner join dwh.EXECUTION ex ON (EX.ORDER_ID = par.ORDER_ID)
                inner join lateral (SELECT *, row_number () over (partition by order_id order by exec_id desc) as rn
                    FROM EXECUTION E
                   WHERE     E.ORDER_ID = par.ORDER_ID
                        AND e.exec_date_id = any(:l_date_ids)
                          AND E.ORDER_STATUS <> '3') ex on (ex.rn=1)

                --inner join dwh.d_exchange exch on (par.exchange_unq_id = exch.exchange_unq_id)
                left join lateral (select
                                      sum(last_qty) as DAY_CUM_QTY,
                                      --str.order_id,
                                      ft.date_id as TRADE_DATE_ID,
                                      SUM (ft.LAST_QTY * ft.LAST_PX) / NULLIF(SUM (ft.LAST_QTY),0)  DAY_AVG_PX,
                                      max(ft.trade_record_time) as exec_time,
                                      min(ft.leaves_qty) as leaves_qty,
                                      min(ft.opt_customer_firm) as customer_or_firm_id
                               from  flat_trade_record ft
                                where ft.date_id= any(:l_date_ids)
                                and par.order_id = ft.order_id and ft.is_busted='N'
                                and ft.date_id = ex.exec_date_id
                                group by ft.date_id
                                limit 10000)  ODCS   ON (1=1 )
                left join lateral (select  bid_qty
                                         , bid_price
                                         , ask_qty
                                         , ask_price
     							 from dwh.get_routing_market_data(par.transaction_id, 'NBBO'::varchar, par.multileg_reporting_type, par.instrument_id,   par.create_date_id)
                           ) nbbo on (1=1)

                  left join lateral (select  count(distinct md.exchange_id) as num_exchange
                                 from  l1_snapshot md
                                 where par.transaction_id = md.transaction_id --and md.start_date_id = any(l_date_ids)
                                   and md.start_date_id = par.create_date_id
                                   and md.exchange_id <> 'NBBO' --and md.exchange_id = exch.real_exchange_id
                                   and ((md.ask_price > 0 and md.ask_quantity > 0) or (md.bid_price > 0 and md.bid_quantity > 0))
                                   and  (nbbo.bid_price = md.bid_price or nbbo.ask_price = md.ask_price)
                                   and case when multileg_reporting_type <> '1'  then true else par.instrument_id = md.instrument_id end
                                  limit 1) exch_md on (1=1)
                  where ex.exec_date_id = any(:l_date_ids);

select * from dwh.l1_snapshot
    where transaction_id = 7260000044260
     and exchange_id = 'NBBO'

   perform data_marts.fyc_insert_validation('fyc_insert_table_par');

   INSERT INTO data_marts.f_yield_capture
           (order_id, client_order_id, parent_order_id, orig_order_id, status_date_id, cross_order_id, MULTILEG_REPORTING_TYPE, TIME_IN_FORCE_id, DAY_LEAVES_QTY,
            order_type_id, side, order_qty, order_price, transaction_id,
            /*client_id,*/ account_id, sub_strategy_id, instrument_type_id, instrument_id, strategy_decision_reason_code, day_order_qty,
            day_cum_qty, day_avg_px, is_marketable, order_size_state, yield, buy_or_sell, avg_px, exec_time, routed_time,
            nbbo_bid_price, nbbo_bid_quantity, nbbo_ask_price, nbbo_ask_quantity, num_exch, trading_firm_unq_id, order_end_time,  order_fix_message_id/*,
            exchange_unq_id, exch_bid_price, exch_bid_quantity, exch_ask_price, exch_ask_quantity*/, ROUTING_TABLE_ID, pt_basket_id, client_id,customer_or_firm_id)


--   select par.order_id, par.client_order_id, par.parent_order_id, ex.exec_date_id as Status_Date_Id,
--      par.cross_order_id, par.MULTILEG_REPORTING_TYPE, par.TIME_IN_FORCE_id,
--      ODCS.leaves_qty as DAY_LEAVES_QTY, /* Potentially bug */
--      par.ORDER_TYPE_ID, par.side, par.order_qty, par.price, par.transaction_id,
--          /*par.client_id,*/ par.account_id, par.sub_strategy_id, par.instrument_type_id, par.instrument_id, par.strtg_decision_reason_code,
--          greatest(par.ORDER_QTY - coalesce (EX.CUM_QTY,0) +coalesce (ODCS.DAY_CUM_QTY, 0), -2147483648) as Day_Order_Qty,
--          coalesce (ODCS.DAY_CUM_QTY, 0) as Day_Cum_Qty,


--          ROUND (coalesce (ODCS.DAY_AVG_PX, 0), 4) as Day_Avg_Px,
--          case when par.Order_Type_id = '1' then 'Y'
--        when par.Side  = '1' and par.Price >= nbbo.ask_price then 'Y'
--        when par.Side <> '1' and par.Price <= nbbo.bid_price then 'Y'
--        else 'N'
--      end as Is_Marketable,
--
--      case when (par.ORDER_QTY - EX.CUM_QTY +coalesce (ODCS.DAY_CUM_QTY, 0)) > case par.side when '1' then nbbo.ask_qty else  nbbo.bid_qty end then 'O'
--        when (par.ORDER_QTY - EX.CUM_QTY +coalesce (ODCS.DAY_CUM_QTY, 0)) < case par.side when '1' then nbbo.ask_qty else  nbbo.bid_qty end then 'U'
--        else 'R'
--      end as Order_Size_State,
--
--      case  par.side when '1'
--                     then case when least(nbbo.ask_qty, par.order_qty)=0 then 0
--                        else round(ODCS.DAY_CUM_QTY::numeric / NULLIF(least(nbbo.ask_qty, par.order_qty),0)::numeric, 4)
--                      end
--                     else  case when least(nbbo.bid_qty, par.order_qty)=0 then 0
--                        else round(ODCS.DAY_CUM_QTY::numeric / NULLIF(least(nbbo.bid_qty, par.order_qty),0)::numeric, 4)
--                      end
--            end as Yield,
--
--            case when par.SIDE in ('1','3') then  'B'
--        when par.SIDE in ('2','4','5','6') then  'S'
--        else 'O'
--      end as buy_or_sell,
--      (SELECT CASE
--            WHEN SUM (EA.LAST_QTY) = 0 THEN NULL
--            ELSE SUM (EA.LAST_QTY * EA.LAST_PX) / NULLIF(SUM (EA.LAST_QTY),0)
--          END
--        FROM dwh.flat_trade_record EA
--        WHERE   EA.ORDER_ID = par.ORDER_ID
--        AND EA.IS_BUSTED <> 'Y'
--        and date_id >= l_min_order_date_id) as avg_px,
--      ex.exec_time,
--      par.process_time,
--      nbbo.bid_price,
--      nbbo.bid_qty,
--      nbbo.ask_price,
--      nbbo.ask_qty,
--      --(select count(distinct exchange_unq_id) from data_marts.f_yield_capture where parent_order_id = par.order_id ) as exch_num ,
--      exch_md.num_exchange ,
--      par.trading_firm_unq_id,
--      case when ex.order_status='4' then ex.exec_time else case when ODCS.leaves_qty > 0 then null else ODCS.exec_time end end as order_end_time,
--      par.fix_message_id,
--      par.ROUTING_TABLE_ID,
--      par.pt_basket_id,
--      par.client_id_text,
--      par.customer_or_firm_id
--            from par
----                inner join dwh.d_instrument i on (par.instrument_id = i.instrument_id)
--               -- inner join dwh.EXECUTION ex ON (EX.ORDER_ID = par.ORDER_ID)
--                inner join lateral (SELECT *, row_number () over (partition by order_id order by exec_id desc) as rn
--                    FROM EXECUTION E
--                   WHERE     E.ORDER_ID = par.ORDER_ID
--                        AND e.exec_date_id = any(l_date_ids)
--                          AND E.ORDER_STATUS <> '3') ex on (ex.rn=1)
--
--                --inner join dwh.d_exchange exch on (par.exchange_unq_id = exch.exchange_unq_id)
--                left join lateral (select
--                                      sum(last_qty) as DAY_CUM_QTY,
--                                      --str.order_id,
--                                      ft.date_id as TRADE_DATE_ID,
--                                      SUM (ft.LAST_QTY * ft.LAST_PX) / NULLIF(SUM (ft.LAST_QTY),0)  DAY_AVG_PX,
--                                      max(ft.trade_record_time) as exec_time,
--                                      min(ft.leaves_qty) as leaves_qty
--                               from  flat_trade_record ft
--                                where ft.date_id= any(l_date_ids)
--                                and par.order_id = ft.order_id and ft.is_busted='N'
--                                and ft.date_id = ex.exec_date_id
--                                group by ft.date_id
--                                limit 10000)  ODCS   ON (1=1 )
--                left join lateral (select  bid_qty
--                                         , bid_price
--                                         , ask_qty
--                                         , ask_price
--     							 from dwh.get_routing_market_data(par.transaction_id, 'NBBO'::varchar, par.multileg_reporting_type, par.instrument_id,   par.create_date_id)
--                           ) nbbo on (1=1)
--
--                  left join lateral (select  count(distinct md.exchange_id) as num_exchange
--                                 from  l1_snapshot md
--                                 where par.transaction_id = md.transaction_id --and md.start_date_id = any(l_date_ids)
--                                   and md.start_date_id = par.create_date_id
--                                   and md.exchange_id <> 'NBBO' --and md.exchange_id = exch.real_exchange_id
--                                   and ((md.ask_price > 0 and md.ask_quantity > 0) or (md.bid_price > 0 and md.bid_quantity > 0))
--                                   and  (nbbo.bid_price = md.bid_price or nbbo.ask_price = md.ask_price)
--                                   and case when multileg_reporting_type <> '1'  then true else par.instrument_id = md.instrument_id end
--                                  limit 1) exch_md on (1=1)

--                  where ex.exec_date_id = any(l_date_ids)
	   select   order_id, client_order_id, parent_order_id, orig_order_id, status_date_id, cross_order_id, MULTILEG_REPORTING_TYPE, TIME_IN_FORCE_id, DAY_LEAVES_QTY,
	            order_type_id, side, order_qty, order_price, transaction_id,
	            account_id, sub_strategy_id, instrument_type_id, instrument_id, strategy_decision_reason_code, day_order_qty,
	            day_cum_qty, day_avg_px,
				is_marketable, order_size_state, yield, buy_or_sell, avg_px, exec_time, routed_time,
	            nbbo_bid_price, nbbo_bid_quantity, nbbo_ask_price, nbbo_ask_quantity, num_exch, trading_firm_unq_id, order_end_time,  order_fix_message_id,
	            ROUTING_TABLE_ID, pt_basket_id, client_id,customer_or_firm_id
	   from 	fyc_insert_table_par
	   on conflict (order_id, status_date_id) do
			update
			set
				order_qty 		= EXCLUDED.order_qty,
				order_price 	= EXCLUDED.order_price,
				transaction_id 	= EXCLUDED.transaction_id,
				--client_id 		= EXCLUDED.client_id,
				account_id 		= EXCLUDED.account_id,
				sub_strategy_id = EXCLUDED.sub_strategy_id,
				instrument_type_id = EXCLUDED.instrument_type_id,
				instrument_id 	= EXCLUDED.instrument_id,
				strategy_decision_reason_code = EXCLUDED.strategy_decision_reason_code,
				day_order_qty 	= EXCLUDED.day_order_qty,
				day_cum_qty 	= EXCLUDED.day_cum_qty,
				day_avg_px 		= EXCLUDED.day_avg_px,
				is_marketable 	= EXCLUDED.is_marketable,
				order_size_state = EXCLUDED.order_size_state,
				yield			= EXCLUDED.yield,
				buy_or_sell		= EXCLUDED.buy_or_sell,
				avg_px 			= EXCLUDED.avg_px,
				exec_time 		= EXCLUDED.exec_time,
				routed_time 	= EXCLUDED.routed_time,
				nbbo_bid_price 	= EXCLUDED.nbbo_bid_price,
				nbbo_bid_quantity = EXCLUDED.nbbo_bid_quantity,
				nbbo_ask_price 	= EXCLUDED.nbbo_ask_price,
				nbbo_ask_quantity = EXCLUDED.nbbo_ask_quantity,
				num_exch 		= EXCLUDED.num_exch,
				exchange_unq_id = EXCLUDED.exchange_unq_id,
				exch_bid_price 	= EXCLUDED.exch_bid_price,
				exch_bid_quantity = EXCLUDED.exch_bid_quantity,
				exch_ask_price 	= EXCLUDED.exch_ask_price,
				exch_ask_quantity = EXCLUDED.exch_ask_quantity,
				cross_order_id		= EXCLUDED.cross_order_id,
				MULTILEG_REPORTING_TYPE	= EXCLUDED.MULTILEG_REPORTING_TYPE,
				TIME_IN_FORCE_id	= EXCLUDED.TIME_IN_FORCE_id,
				DAY_LEAVES_QTY		= EXCLUDED.DAY_LEAVES_QTY,
				trading_firm_unq_id = EXCLUDED.trading_firm_unq_id,
				order_type_id		= EXCLUDED.order_type_id,
				db_merge_time		= clock_timestamp(),
                wave_no				= EXCLUDED.wave_no,
                order_end_time		= EXCLUDED.order_end_time,
                order_fix_message_id = EXCLUDED.order_fix_message_id,
                ROUTING_TABLE_ID	= EXCLUDED.ROUTING_TABLE_ID,
				parent_sub_strategy_id = EXCLUDED.parent_sub_strategy_id,
				client_id		=EXCLUDED.client_id,
				customer_or_firm_id = EXCLUDED.customer_or_firm_id,
				orig_order_id = EXCLUDED.orig_order_id;



     GET DIAGNOSTICS row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Parent orders', row_cnt, 'I')
   into l_step_id;
   /* ===============================================================================================================*/
   /* Mark subscription as processed*/
   /* ===============================================================================================================*/
 --        RAISE info 'l_batch_ids_to_purge size is %', cardinality(l_batch_ids_to_process);

--  select public.load_log(l_load_id, l_step_id, 'cardinality(l_batch_ids_to_process)', cardinality(l_batch_ids_to_process), 'I')
--   into l_step_id;

--  foreach l_loop_id in ARRAY l_batch_ids_to_process loop
      if cardinality(l_batch_ids_to_process)>0 and in_parent_order_ids is null
       then

--	  select public.load_log(l_load_id, l_step_id, left(array_to_string(l_batch_ids_to_process,','), 200) , cardinality(l_batch_ids_to_process), 'I')
--	   into l_step_id;

  	update public.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where --load_batch_id =l_loop_id
          load_batch_id = any (l_batch_ids_to_process)
         and subscription_name='yield_capture'
         and source_table_name='execution'
        and subscription_id in (select subscription_id from public.etl_subscriptions
        						 where load_batch_id = any (l_batch_ids_to_process)
         							and subscription_name='yield_capture'
         							and source_table_name='execution'
         							and not is_processed
         						   for update skip locked);
--       end loop;

       GET DIAGNOSTICS row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Close subscriptions yield_capture_execution ', row_cnt, 'U')
   into l_step_id;
 end if;


   if cardinality(l_strategy_batch_ids_list) >0 and in_parent_order_ids is null
    then

  update public.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where --load_batch_id =l_loop_id
         load_batch_id = any (l_strategy_batch_ids_list)
         and subscription_name='yield_capture'
         and source_table_name='strategy_in'
         and date_id = any (l_date_ids);

     GET DIAGNOSTICS row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Close subscriptions yield_capture_strategy_in ', row_cnt, 'U')
   into l_step_id;
  end if;
 --      end loop;

--foreach l_loop_id in ARRAY l_ftr_to_process loop
      if cardinality(l_ftr_to_process) >0 and in_parent_order_ids is null
       then
        update public.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where --load_batch_id =l_loop_id
         load_batch_id = any (l_ftr_to_process)
         and subscription_name='yield_capture'
         and source_table_name in ('flat_trade_record', 'l1_snapshot')
         and date_id = any (l_date_ids)
        and not is_processed ;

     GET DIAGNOSTICS row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'Close subscriptions yield_capture_flat_trade_record ', row_cnt, 'U')
   into l_step_id;

  end if;


   select public.load_log(l_load_id, l_step_id, 'subscriptions marked as processed', 0, 'U')
   into l_step_id;




--        RAISE info '% After loop. ', clock_timestamp();
   /* ===============================================================================================================*/
   /* Update fact_last_load_time*/
   /* ===============================================================================================================*/
   perform dwh.p_upd_fact_last_load_time('YILED_CAPTURE');
   select public.load_log(l_load_id, l_step_id, 'p_upd_fact_last_load_time ' , 0, 'O')
   into l_step_id;
 /* ===============================================================================================================*/
   /* Mark subscription as processed*/
   /* ===============================================================================================================*/
  execute 'truncate table  orders_to_process';

     select public.load_log(l_load_id, l_step_id, 'Yield Capture Completed ===', 0, 'E')
   into l_step_id;

   return row_cnt;

   else
   /* ===============================================================================================================*/
   /* Mark subscription as processed*/
   /* ===============================================================================================================*/


select public.load_log(l_load_id, l_step_id, 'Nothing to process', 0, 'U')
   into l_step_id;
 --       RAISE info '% After loop. ', clock_timestamp();
   /* ===============================================================================================================*/
   /* Update fact_last_load_time*/
   /* ===============================================================================================================*/

   if cardinality(l_batch_ids_to_process) >0 and in_parent_order_ids is null
   then
	update public.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where --load_batch_id =l_loop_id
          load_batch_id = any (l_batch_ids_to_process)
         and subscription_name='yield_capture'
         and source_table_name='execution'
        and subscription_id in (select subscription_id from public.etl_subscriptions
        						 where load_batch_id = any (l_batch_ids_to_process)
         							and subscription_name='yield_capture'
         							and source_table_name='execution'
         							and not is_processed
         						   for update skip locked);

       GET DIAGNOSTICS row_cnt = ROW_COUNT;

	  select public.load_log(l_load_id, l_step_id, 'Close subscriptions yield_capture_execution ', row_cnt, 'U')
	   into l_step_id;
	   end if;

   perform dwh.p_upd_fact_last_load_time('YILED_CAPTURE');
   select public.load_log(l_load_id, l_step_id, 'p_upd_fact_last_load_time ' , 0, 'O')
   into l_step_id;
   /* ===============================================================================================================*/
   /* Mark subscription as processed*/
   /* ===============================================================================================================*/
     select public.load_log(l_load_id, l_step_id, 'Yield Capture REPORT Completed ===', 0, 'E')
   into l_step_id;

   return 0;
   end if;


  exception when others then

--  if sqlstate = '23503'
--		then
--			select public.load_log(l_load_id, l_step_id, 'staging.foreign_key_error_fix started =====' , 0, 'S')
-- 			into l_step_id;
--
--			perform staging.foreign_key_error_fix('f_yield_capture');
--
--			select public.load_log(l_load_id, l_step_id, 'staging.foreign_key_error_fix finished =====' , 0, 'E')
-- 			into l_step_id;
--  end if;
 select public.load_log(l_load_id, l_step_id, left(sqlerrm,100) , 0, 'E')
 into l_step_id;
     select public.load_log(l_load_id, l_step_id, 'Yield Capture REPORT Completed with ERROR!!!', 0, 'O')
   into l_step_id;
  PERFORM public.load_error_log('Yield Capture REPORT',  'I', left(sqlerrm,100), l_load_id);

  RAISE;


end;
$function$
;
