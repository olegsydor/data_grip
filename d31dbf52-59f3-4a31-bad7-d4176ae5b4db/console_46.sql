
 INSERT INTO data_marts.f_yield_capture
           (order_id, client_order_id, parent_order_id, status_date_id, cross_order_id, MULTILEG_REPORTING_TYPE, TIME_IN_FORCE_id, DAY_LEAVES_QTY,
            order_type_id, side, order_qty, order_price, transaction_id,
            /*client_id,*/ account_id, sub_strategy_id, instrument_type_id, instrument_id, strategy_decision_reason_code, day_order_qty,
            day_cum_qty, day_avg_px, is_marketable, order_size_state, yield, buy_or_sell, avg_px, exec_time, routed_time,
            nbbo_bid_price, nbbo_bid_quantity, nbbo_ask_price, nbbo_ask_quantity, num_exch,
            exchange_unq_id, exchange_id, real_exchange_id, exch_bid_price, exch_bid_quantity, exch_ask_price, exch_ask_quantity, trading_firm_unq_id, wave_no, order_end_time,
            order_fix_message_id,ROUTING_TABLE_ID, parent_sub_strategy_id, pt_basket_id, client_id,customer_or_firm_id)
 select order_id, client_order_id, parent_order_id, Status_Date_Id,
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
				customer_or_firm_id = EXCLUDED.customer_or_firm_id
;

     GET DIAGNOSTICS row_cnt = ROW_COUNT;


  select public.load_log(l_load_id, l_step_id, 'Street orders', row_cnt, 'I')
   into l_step_id;


   /* ================================== PARENT LEVEL ===================================================================
    * ==================================================================================================================
   */

	create temp table if not exists fyc_insert_table_par as
  	  select par.order_id, par.client_order_id, par.parent_order_id, ex.exec_date_id as status_date_id,
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
        and date_id >= l_min_order_date_id) as avg_px,
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
      par.customer_or_firm_id
            from par
--                inner join dwh.d_instrument i on (par.instrument_id = i.instrument_id)
               -- inner join dwh.EXECUTION ex ON (EX.ORDER_ID = par.ORDER_ID)
                inner join lateral (SELECT *, row_number () over (partition by order_id order by exec_id desc) as rn
                    FROM EXECUTION E
                   WHERE     E.ORDER_ID = par.ORDER_ID
                        AND e.exec_date_id = any(l_date_ids)
                          AND E.ORDER_STATUS <> '3') ex on (ex.rn=1)

                --inner join dwh.d_exchange exch on (par.exchange_unq_id = exch.exchange_unq_id)
                left join lateral (select
                                      sum(last_qty) as DAY_CUM_QTY,
                                      --str.order_id,
                                      ft.date_id as TRADE_DATE_ID,
                                      SUM (ft.LAST_QTY * ft.LAST_PX) / NULLIF(SUM (ft.LAST_QTY),0)  DAY_AVG_PX,
                                      max(ft.trade_record_time) as exec_time,
                                      min(ft.leaves_qty) as leaves_qty
                               from  flat_trade_record ft
                                where ft.date_id= any(l_date_ids)
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
                  where ex.exec_date_id = any(l_date_ids);

   perform data_marts.fyc_insert_validation('fyc_insert_table_par');

   INSERT INTO data_marts.f_yield_capture
           (order_id, client_order_id, parent_order_id, status_date_id, cross_order_id, MULTILEG_REPORTING_TYPE, TIME_IN_FORCE_id, DAY_LEAVES_QTY,
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
	   select   order_id, client_order_id, parent_order_id, status_date_id, cross_order_id, MULTILEG_REPORTING_TYPE, TIME_IN_FORCE_id, DAY_LEAVES_QTY,
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
				customer_or_firm_id = EXCLUDED.customer_or_firm_id;


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
