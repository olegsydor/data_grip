do $$

declare
	l_step_id  	int4;
	l_load_id  	int4;
	l_row_cnt	int4;
	l_instrument_id_arr  int[];
in_date_begin int:=20250701;
in_date_end int:=20250930;
in_account_ids int[]:='{50081}';
in_custom_configuration_algo boolean:=false;
in_sub_strategy text[]:= '{"SENSOR"}';
in_trading_firm_ids text[] := '{}'::text[];
in_client_ids text[] :='{}'::text[];
in_symbols character varying[] :='{}'::character varying[];
begin
	--  Created  by  PD  on  2022/05/25  to  test
	select  nextval('public.load_timing_seq')  into  l_load_id;
	l_step_id:=1;

	select  public.load_log(l_load_id,  l_step_id,  'report_equity_tca  STARTED  ====',  0,  'O')
	into  l_step_id;

	case  when  cardinality(in_symbols)  =  0
		then  l_instrument_id_arr  :=  '{}';
		else  l_instrument_id_arr  :=  (select  array_agg(instrument_id)
								          from  dwh.d_instrument  di
								          where  di.symbol  =  any(in_symbols));
	end  case;
drop table if exists tmp_fyc;
      create  temp  table  if  not  exists  tmp_fyc
      on  commit  drop
      as
      select  yc.order_id,
		yc.client_order_id,
		yc.status_date_id  as  date_id,
		yc.multileg_reporting_type,
		yc.instrument_type_id,
		yc.account_id,
		a.account_name,
		yc.client_id,
		yc.instrument_id,
		yc.routed_time  as  parent_routed_time,
		yc.order_end_time,
		yc.side,
		yc.buy_or_sell,
		(case  when  yc.buy_or_sell  =  'B'  then  1  else  -1  end)::int  as  side_multiplier,
		case  when  yc.day_order_qty  <  yc.order_qty  then  yc.day_order_qty  else  yc.order_qty  end  as  parent_order_qty,
		yc.day_cum_qty  as  parent_exec_qty,
		sum(yc.day_cum_qty)  over  (partition  by  true)  as  total_parent_exec_qty,
		yc.avg_px  as  parent_avg_price,
		yc.avg_px  *  yc.day_cum_qty  as  principal_amount,
		yc.nbbo_bid_price  as  parent_nbbo_bid_price,
		yc.nbbo_ask_price  as  parent_nbbo_ask_price,
		yc.nbbo_bid_quantity  as  parent_nbbo_bid_qty,
		yc.nbbo_ask_quantity  as  parent_nbbo_ask_qty,
		case  when  yc.side  =  '1'  then  10000  *  (yc.order_price  -  yc.nbbo_ask_price)  /  coalesce(yc.nbbo_ask_price,  0,  null)  else  null  end  as  buy_limit_vs_ask_bps,
		case  when  yc.side  <>  '1'  then  10000  *  (yc.order_price  -  yc.nbbo_bid_price)  /  coalesce(yc.nbbo_bid_price,  0,  null)  else  null  end  as  sell_limit_vs_bid_bps,
		yc.is_marketable  as  parent_is_marketable,
		yc.order_price  as  parent_limit_price,
		(yc.nbbo_ask_price  +  yc.nbbo_bid_price)  /  2  routing_time_mid_price,
		yc.nbbo_ask_price  -  yc.nbbo_bid_price  routing_time_spread,
		yc.trading_firm_unq_id  ,
		yc.sub_strategy_id,
		yc.routing_table_id,
		yc.order_fix_message_id,
		yc.day_order_qty  ,
		yc.order_qty
      from  data_marts.f_yield_capture  yc
	join  dwh.d_account  a  on  a.account_id  =  yc.account_id  and  a.is_active
	left  join  dwh.d_target_strategy  dts  on  dts.target_strategy_id  =  yc.sub_strategy_id
	where  yc.parent_order_id  is  null
	    and  yc.status_date_id  between  in_date_begin  and  in_date_end
	    and  yc.instrument_type_id  =  'E'
	    and  yc.multileg_reporting_type  =  '1'
	    and  case  when  coalesce(in_account_ids,  '{}')  <>  '{}'  then  yc.account_id  =  any(in_account_ids)  else  true  end
	    and  case  when  coalesce(in_trading_firm_ids,  '{}')  <>  '{}'  then  a.trading_firm_id  =  any(in_trading_firm_ids)  else  true  end
	    and  case  when  coalesce(in_client_ids,  '{}')  <>  '{}'  then  yc.client_id  =  any(in_client_ids)  else  true  end
	    and  case  when  in_sub_strategy  <>  '{}'  then  dts.target_strategy_name  =  any(in_sub_strategy)  else  true  end
	    and  case  when  l_instrument_id_arr  <>  '{}'  then  yc.instrument_id  =  any(l_instrument_id_arr)  else  true  end;


		get  diagnostics  l_row_cnt  =  row_count;

	  analyze  tmp_fyc;
	select  public.load_log(l_load_id,  l_step_id,  'create  temp  table  if  not  exists  tmp_fyc',  l_row_cnt,  'I')
	into  l_step_id;
drop table if exists pre_pre_fetch_equity_tca;
	create  temp  table  if  not  exists  pre_pre_fetch_equity_tca  (
		order_id  					int8  null,
		client_order_id  			varchar(256)  null,
		date_id  					int4  null,
		multileg_reporting_type  	bpchar(1)  null,
		instrument_type_id  			bpchar(1)  null,
		trading_firm_unq_id  		int4  null,
		trading_firm_name  			varchar(60)  null,
		account_id  					int8  null,
		account_name  				varchar(30)  null,
		client_id  					varchar(255)  null,
		instrument_id  				int4  null,
		symbol  						varchar(10)  null,
		parent_routed_time  			timestamp  null,
		order_end_time  				timestamp  null,
		order_cancel_time  			timestamp(3)  null,
		side  						bpchar(1)  null,
		buy_or_sell  				bpchar(1)  null,
		side_multiplier  			int4  null,
		parent_order_qty  			int4  null,
		parent_exec_qty  			int4  null,
		total_parent_exec_qty  		int8  null,
		parent_avg_price  			numeric  null,
		principal_amount  			numeric  null,
		target_strategy_id  			int4  null,
		algorithm  					varchar(128)  null,
		parent_nbbo_bid_price  		numeric(12,4)  null,
		parent_nbbo_ask_price  		numeric(12,4)  null,
		parent_nbbo_bid_qty  		int4  null,
		parent_nbbo_ask_qty  		int4  null,
		buy_limit_vs_ask_bps  		numeric  null,
		sell_limit_vs_bid_bps  		numeric  null,
		parent_is_marketable  		bpchar(1)  null,
		parent_limit_price  			numeric(12,4)  null,
		routing_table_name  			varchar(30)  null,
		order_arrival_price  		float8  null,
		order_end_price  			float8  null,
		vwap_over_life  				float8  null,
		eligible_vwap_over_life  	float8  null,
		twap_over_life  				float8  null,
		eligible_twap_over_life  	float8  null,
		volume_over_life  			float8  null,
		eligible_volume_over_life  	float8  null,
		eligible_pwp_5pc  			float8  null,
		eligible_pwp_10pc			float8  null,
		eligible_pwp_15pc  			float8  null,
		eligible_pwp_20pc  			float8  null,
		trade_count  				int4  null,
		eligible_trade_count  		int4  null,
		block_volume  				int4  null,
		eligible_qd_volume  			int4  null,
		eligible_ix_volume  			int4  null,
		avg_spread_over_life  		numeric  null,
		day_high_price  				numeric  null,
		day_low_price  				numeric  null,
		open_px  					numeric  null,
		close_px  					numeric  null,
		prev_close_px  				numeric  null,
		next_close_px  				numeric  null,
		routing_time_mid_price  		numeric  null,
		routing_time_spread  		numeric  null,
		aggression_level  			text  null,
		activ_symbol  				varchar(30)  null,
		day_order_qty  				int4  null,
		order_qty  					int4  null
	);
	select  public.load_log(l_load_id,  l_step_id,  'temp table created',  0,  'O')
	into  l_step_id;

	create temp table t_os on commit drop as
     select
		yc.order_id,
		yc.client_order_id,
		yc.date_id,
		yc.multileg_reporting_type,
		yc.instrument_type_id,
		tf.trading_firm_unq_id,
		tf.trading_firm_name,
		yc.account_id,
		yc.account_name,
		yc.client_id,
		yc.instrument_id,
		i.symbol,
		yc.parent_routed_time,
		yc.order_end_time,
		co.order_cancel_time,
		yc.side,
		yc.buy_or_sell,
		yc.side_multiplier,
		yc.parent_order_qty,
		yc.parent_exec_qty,
		yc.total_parent_exec_qty,
		yc.parent_avg_price,
		yc.principal_amount,
		ts.target_strategy_id,
		case  when  in_custom_configuration_algo
			  	then  coalesce(fix_message->>'9264',ts.target_strategy_desc)
			  	else  ts.target_strategy_desc
		end  as  algorithm,
		yc.parent_nbbo_bid_price,
		yc.parent_nbbo_ask_price,
		yc.parent_nbbo_bid_qty,
		yc.parent_nbbo_ask_qty,
		yc.buy_limit_vs_ask_bps,
		yc.sell_limit_vs_bid_bps,
		yc.parent_is_marketable,
		yc.parent_limit_price,
		rt.routing_table_name,
nullif(tca.order_arrival_price,  0)::float as order_arrival_price,
		nullif(tca.order_end_price,  0)::float as order_end_price,
		nullif(tca.vwap_over_life,  0)::float as vwap_over_life,
		nullif(tca.eligible_vwap_over_life,  0)::float as eligible_vwap_over_life,
		nullif(tca.twap_over_life,  0)::float as twap_over_life,
		nullif(tca.eligible_twap_over_life,  0)::float as eligible_twap_over_life,
		nullif(tca.volume_over_life,  0)::float as volume_over_life,
		nullif(tca.eligible_volume_over_life,  0)::float as eligible_volume_over_life,
		nullif(tca.pwp_5pc,  0)::float as eligible_pwp_5pc,
		nullif(tca.pwp_10pc,  0)::float as eligible_pwp_10pc,
		nullif(tca.pwp_15pc,  0)::float as eligible_pwp_15pc,
		nullif(tca.pwp_20pc,  0)::float as eligible_pwp_20pc,
		tca.trade_count,
		tca.eligible_trade_count,
		tca.block_volume,
		COALESCE((tca.eligible_volume_over_life_by_exchange  ->>  'QD')::int,0)  as  eligible_qd_volume,
		COALESCE((tca.eligible_volume_over_life_by_exchange  ->>  'IX')::int,0)  as  eligible_ix_volume,
		tca.wtd_avg_spread_arrival  as  avg_spread_over_life,
		da.high  as  day_high_price,
		da.low  as  day_low_price,
		da.open_price  as  open_px,
		da.close_price  as  close_px,
		prev.close_price  as  prev_close_px,
		nxt.close_price  as  next_close_px,
		yc.routing_time_mid_price,
		yc.routing_time_spread,
		coalesce(case  target_strategy_desc
			when  'POV'  then  public.get_message_tag_string(yc.order_fix_message_id,  9023,  yc.date_id  )  --target_pov
			when  'VOLUME  PARTICIPATION'  then  public.get_message_tag_string(yc.order_fix_message_id,  9023,  yc.date_id  )  --target_pov
			when  'PHANTOM'  then  case  public.get_message_tag_string(yc.order_fix_message_id,  9002,  yc.date_id  )      --urgency
									when  '1'  then  'Low'
										when  '2'  then  'Medium'
										when  '3'  then  'High'
									  end
			when  'VWAP'  then  case  public.get_message_tag_string(yc.order_fix_message_id,  9002,  yc.date_id  )
								when  '1'  then  'Low'
								when  '2'  then  'Medium'
								when  '3'  then  'High'
							  end
			when  'TWAP'  then  case  public.get_message_tag_string(yc.order_fix_message_id,  9002,  yc.date_id  )
								when  '1'  then  'Low'
								when  '2'  then  'Medium'
								when  '3'  then  'High'
							  end
			when  'CLOSE'  then  public.get_message_tag_string(yc.order_fix_message_id,  9126,  yc.date_id  )  --close_aggression
			when  'SENSOR  DARK'  then  'Default  (PI  =  '  ||  public.get_message_tag_string(yc.order_fix_message_id,  9191,  yc.date_id  )::text  ||  ')'
			else  null
		end,  'Default')  as  aggression_level,
		i.activ_symbol,
		yc.day_order_qty,
		yc.order_qty
		from  tmp_fyc  yc
			join  lateral(select tf.trading_firm_unq_id,		tf.trading_firm_name from  dwh.d_trading_firm  tf  where  tf.trading_firm_unq_id  =  yc.trading_firm_unq_id limit 1 ) tf on true
			join  lateral(select symbol, activ_symbol from  dwh.d_instrument  i  where  i.instrument_id  =  yc.instrument_id  and  i.is_active limit 1 ) i on true
			left  join  lateral (select target_strategy_id, target_strategy_desc from  dwh.d_target_strategy  ts  where  ts.target_strategy_id  =  yc.sub_strategy_id  and  ts.is_active limit 1) ts on true
			left  join   dwh.d_routing_table  rt  on  rt.routing_table_id  =  yc.routing_table_id  and  rt.is_active  =  true
			left  join   eq_tca.algorithmic_order_analytic_v2  tca  on  tca.order_id  =  yc.order_id  and  tca.date_id  =  yc.date_id
			left  join  eq_tca.daily_analytic_v2  da  on  da.symbol  =  i.activ_symbol  and  da.date_id  =  yc.date_id
			left  join  lateral  (select  da.close_price  as  close_price  from  eq_tca.daily_analytic_v2  da  where  da.symbol  =  i.activ_symbol  and  da.date_id  <  yc.date_id  order  by  date_id  desc  limit  1)  prev  on  true
			left  join  lateral  (select  da.close_price  as  close_price  from  eq_tca.daily_analytic_v2  da  where  da.symbol  =  i.activ_symbol  and  da.date_id  >  yc.date_id  order  by  date_id  limit  1)  nxt  on  true
			join  dwh.client_order  co  on  co.order_id  =  yc.order_id  and  co.create_date_id  =  yc.date_id  and  co.create_date_id  between  in_date_begin  and  in_date_end
			left  join  lateral (select fix_message from fix_capture.fix_message_json  fmj  where  fmj.fix_message_id  =  co.fix_message_id  and  fmj.date_id  =  co.create_date_id limit 1 )fmj on true;


		select  public.load_log(l_load_id,  l_step_id,  'temp table t-Os created',  0,  'O')
	into  l_step_id;


    insert into pre_pre_fetch_equity_tca (order_id, client_order_id, date_id, multileg_reporting_type,
                                          instrument_type_id, trading_firm_unq_id, trading_firm_name, account_id,
                                          account_name, client_id, instrument_id, symbol, parent_routed_time,
                                          order_end_time, order_cancel_time, side, buy_or_sell, side_multiplier,
                                          parent_order_qty, parent_exec_qty, total_parent_exec_qty, parent_avg_price,
                                          principal_amount, target_strategy_id, algorithm, parent_nbbo_bid_price,
                                          parent_nbbo_ask_price, parent_nbbo_bid_qty, parent_nbbo_ask_qty,
                                          buy_limit_vs_ask_bps, sell_limit_vs_bid_bps, parent_is_marketable
        ,
                                          parent_limit_price, routing_table_name, order_arrival_price, order_end_price,
                                          vwap_over_life, eligible_vwap_over_life, twap_over_life,
                                          eligible_twap_over_life, volume_over_life, eligible_volume_over_life,
                                          eligible_pwp_5pc, eligible_pwp_10pc, eligible_pwp_15pc, eligible_pwp_20pc,
                                          trade_count, eligible_trade_count, block_volume, eligible_qd_volume,
                                          eligible_ix_volume, avg_spread_over_life, day_high_price, day_low_price,
                                          open_px, close_px, prev_close_px, next_close_px, routing_time_mid_price,
                                          routing_time_spread, aggression_level, activ_symbol, day_order_qty, order_qty
    )
	select * from t_os;

                get  diagnostics  l_row_cnt  =  row_count;
		select  public.load_log(l_load_id,  l_step_id,  'pre_pre_table  was  filled  out  ====',  l_row_cnt,  'I')
		into  l_step_id;

end;
$$