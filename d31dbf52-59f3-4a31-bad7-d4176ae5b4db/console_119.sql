explain (costs, verbose, buffers, format json)
select co.order_id,
	           co.create_date_id,
	           ex.order_status,
	           ex.exec_time,
	           case when co.time_in_force_id = '1' then di.last_trade_date else co.expire_time end as last_trade_date, -- last_trade_date from instrument for GTC or expire_time from client_order for GTD
	           to_char(current_date, 'YYYYMMDD')::int4 as last_mod_date_id,
	           co.account_id,
	           co.time_in_force_id,
	           co.client_order_id,
	           co.instrument_id,
	           co.multileg_reporting_type,
	           case when co.parent_order_id is null then true else false end as is_parent
	    from dwh.client_order co
	             join dwh.d_instrument di on di.instrument_id = co.instrument_id
	             left join lateral (select iex.exec_time,
	                                       iex.order_status
	                                from dwh.execution iex
	                                where true
	                                  and iex.order_id = co.order_id
	                                  and iex.order_status in ('2', '4', '8')
--	                                  and exec_date_id >= l_start_date_id
	                                  and exec_date_id between :l_start_date_id and :l_end_date_id
	                                order by exec_id desc
	                                limit 1) ex on true
	    where co.create_date_id between :l_start_date_id and :l_end_date_id
	      and co.time_in_force_id in ('1', '6')
	      and co.trans_type <> 'F'
	      and not exists (select null from dwh.gtc_order_status os where os.order_id = co.order_id);