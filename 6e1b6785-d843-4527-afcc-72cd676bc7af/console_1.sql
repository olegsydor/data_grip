-- DROP FUNCTION genesis2.load_trade_record_inc(numeric, int8, bpchar);

CREATE OR REPLACE FUNCTION genesis2.load_trade_record_inc(in_dataset_id int8 DEFAULT NULL::numeric, in_orig_trade_record_id bigint DEFAULT NULL::bigint, in_trade_record_reason character DEFAULT NULL::character(1))
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL_FAST: TRADE_RECORD incremental'
AS $function$
-- OS: 20240429 https://dashfinancial.atlassian.net/browse/DS-8134 init

DECLARE
--    l_max_exec_id bigint;
   l_arch_max_exec_id int;
   l_ret	int;
   some_var     varchar;
   l_step_id	int;
   l_load_id	int;
--    l_foreign_max_exec_id bigint; -- max exiscting id
   l_arch_foreign_max_exec_id bigint;
   l_status_message varchar;
   l_scr record;
   l_busted_jsn jsonb;
   l_cnt int;
   l_date_id int;
   l_away_load_batch int;
   l_max_dataset_id         int8; -- dataset_id that is present in the table
   l_foreign_max_dataset_id int8; -- max dataset_id we should load

BEGIN
   l_date_id:=to_char(current_date ,'YYYYMMDD')::int ;

   if in_dataset_id is null
 then
	select nextval('load_timing_seq') into l_load_id;
	l_step_id:=1;
	--l_foreign_max_exec_id:=0;

	l_status_message:='Trade_Record_inc STARTED===';
	select public.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
	into l_step_id;

--    l_status_message:='l_max_exec_id';
-- 	select COALESCE(max(exec_id),0)
-- 	into l_max_exec_id from genesis2.trade_record;

-- 	select load_log(l_load_id, l_step_id, 'l_max_exec_id = '||l_max_exec_id, 0 , 'S')
-- 	into l_step_id;

--	RAISE INFO 'MAX exec_id is    %', l_max_exec_id;


	l_status_message:='l_foreign_max_exec_id = ';
--  SELECT COALESCE(max(exec_id),0) FROM staging.psql_execution where OPERATION$ <> 'D' into l_foreign_max_exec_id;
-- 	SELECT COALESCE(max(exec_id),0) FROM dwh.execution where exec_id>=l_max_exec_id into l_foreign_max_exec_id;
	select coalesce(last_id, 0) from genesis2.fact_last_load_id where value_name = 'trade_record' into l_max_dataset_id;
	select coalesce(max(dataset_id), 0) from dwh.execution ex where ex.exec_date_id = l_date_id into l_foreign_max_dataset_id;

    select load_log(l_load_id, l_step_id, 'l_max_dataset_id = ' || l_max_dataset_id, 0, 'S')
    into l_step_id;

    select load_log(l_load_id, l_step_id, 'l_foreign_max_dataset_id = ' || l_foreign_max_dataset_id, 0, 'S')
    into l_step_id;
-- DISASTER
-- In case of CDC not return data then just uncomment next line
--l_foreign_max_exec_id:=999999999999;


-- SO removed
/*	perform public.oracle_close_connections();
	perform pg_sleep(3);

	select load_log(l_load_id, l_step_id, 'Oracle connection closed', 0, 'S')
	into l_step_id;
*/

-- SO removed
/* select dimension_etl(true) into some_var;

   l_status_message:='dimension_etl';
	select genesis2.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
	into l_step_id;
perform public.oracle_close_connections();

--	select load_trade_facts_etl() into some_var;
--
--   l_status_message:='load_trade_facts_etl';
--	select genesis2.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
--	into l_step_id;
*/

    for l_scr in (select load_batch_id, subscription_id
                  from public.etl_subscriptions
                  where subscription_name = 'missed_fix_trade'
                    and source_table_name = 'orcl_execution'
                    and not is_processed)
        loop
            l_status_message := 'FIX TRADE GAP processing: ' || l_scr.load_batch_id;

            select public.load_log(l_load_id, l_step_id, l_status_message, 1, 'O')
            into l_step_id;

            perform genesis2.load_trade_record_inc(l_scr.load_batch_id);

            update public.etl_subscriptions
            set is_processed = true,
                process_time = clock_timestamp()
            where subscription_id = l_scr.subscription_id;

        end loop;

--   l_status_message:='============FIX TRADE GAP =======';

 else l_foreign_max_dataset_id:=in_dataset_id ;
	 l_max_dataset_id := in_dataset_id - 1;
end if;


IF l_foreign_max_dataset_id > l_max_dataset_id /* 1=1*/ THEN

	insert into genesis2.trade_record (trade_record_time, db_create_time, date_id,
		    is_busted, orig_trade_record_id, trade_record_trans_type, trade_record_reason,
		    subsystem_id, user_id, account_id, client_order_id, instrument_id ,
		    side, open_close, fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator,
		    secondary_order_id, exch_exec_id, secondary_exch_exec_id, last_mkt,
		    last_qty, last_px, ex_destination, sub_strategy, street_order_id,
		    order_id, street_order_qty, order_qty, multileg_reporting_type,
		    is_largest_leg, street_max_floor, exec_broker, cmta,
		    street_time_in_force, street_order_type, opt_customer_firm, street_mpid,
		    is_cross_order, street_is_cross_order, street_cross_type, cross_is_originator,
		    street_cross_is_originator, contra_account, contra_broker, trade_exec_broker,
		    order_fix_message_id, trade_fix_message_id,  street_order_fix_message_id, client_id,
		    street_transaction_id, transaction_id, order_price, street_order_price, order_process_time ,
		    street_client_order_id, fix_comp_id, LEAVES_QTY, street_exec_inst, fee_sensitivity,
		    strategy_decision_reason_code, compliance_id, floor_broker_id, AUCTION_ID,
		    street_opt_customer_firm, clearing_account_number, sub_account,  multileg_order_id,
		    INTERNAL_COMPONENT_TYPE, street_trade_fix_message_id, pt_basket_id, pt_order_id, Street_Client_Sender_CompID,
		    street_account_name, street_exec_broker, trade_text, branch_sequence_number, frequent_trader_id, time_in_force, int_liq_source_type,
		    market_participant_id, ALTERNATIVE_COMPLIANCE_ID, street_trade_record_time, street_order_process_time,leg_ref_id, blaze_account_alias


		    )
	select TRADE_RECORD_TIME
	, now()
	, DATE_ID
	, 'N' as IS_BUSTED
	, IN_ORIG_TRADE_RECORD_ID
	, TRADE_RECORD_TRANS_TYPE
	, coalesce(in_trade_record_reason,TRADE_RECORD_REASON::char ) as TRADE_RECORD_REASON
	, COALESCE(SUB_SYSTEM_ID,'PG_DASH') as SUB_SYSTEM_ID
	, -1 as USER_ID  -- SO hotfix
	, ACCOUNT_ID
	, CLIENT_ORDER_ID
	, v.INSTRUMENT_ID
	, SIDE
	, OPEN_CLOSE
	, FIX_CONNECTION_ID
	, EXEC_ID
	, CASE WHEN exchange_id in ('C2OXFX','CBOEFX') then substring(exchange_id, 1, length(exchange_id)-2) else exchange_id end as exchange_id
	, staging.get_trade_liquidity_indicator(TRADE_LIQUIDITY_INDICATOR) as TRADE_LIQUIDITY_INDICATOR
	, SECONDARY_ORDER_ID
	, EXCH_EXEC_ID
	, SECONDARY_EXCH_EXEC_ID
	, LAST_MKT
	, LAST_QTY
	, LAST_PX
	, EX_DESTINATION
-- 	, SUB_STRATEGY
    , target_strategy_name	-- SO hotfix
	, STREET_ORDER_ID
	, ORDER_ID
	, STREET_ORDER_QTY
	, ORDER_QTY

	, MULTILEG_REPORTING_TYPE
	, 'Y' as IS_LARGEST_LEG -- SO hotfix
	, STREET_MAX_FLOOR
	, EXEC_BROKER
	, left(CMTA,3)
	, STREET_TIME_IN_FORCE
	, STREET_ORDER_TYPE
	, OPT_CUSTOMER_FIRM
	, STREET_MPID
	, IS_CROSS_ORDER
	, STREET_IS_CROSS_ORDER
	, STREET_CROSS_TYPE
	, CROSS_IS_ORIGINATOR
	, STREET_CROSS_IS_ORIGINATOR
	, CONTRA_ACCOUNT
	, CONTRA_BROKER
	, TRADE_EXEC_BROKER
	, order_fix_message_id
	, trade_fix_message_id
	, street_order_fix_message_id
	, client_id
	, street_transaction_id
	, transaction_id
	, order_price
	, street_order_price
	, order_process_time
	, street_client_order_id
	, fix_comp_id
    , LEAVES_QTY
    , street_exec_inst
    , fee_sensitivity
    , strategy_decision_reason_code
    , compliance_id
    , floor_broker_id
    , AUCTION_ID
    , STR_OPT_CUSTOMER_FIRM
	, clearing_account
    , left(sub_account,30) as sub_account
    ,  multileg_order_id
    , INTERNAL_COMPONENT_TYPE
    , str_trade_fix_message_id
    , pt_basket_id
    , pt_order_id
    , str_cls_comp_ID
    , coalesce(street_account_name, genesis2.f_get_street_account_name(street_order_fix_message_id, date_id::int, exchange_id , multileg_reporting_type::smallint, street_is_cross_order::char))
    , case i.instrument_type_id
        when 'O' then dwh.get_street_exec_broker(v.street_order_fix_message_id, v.date_id::int, v.exchange_id, v.street_client_order_id, v.multileg_reporting_type::smallint, v.street_is_cross_order::char)
        else null
      end as street_exec_broker
    , trade_text
    , branch_seq_num
    , left (frequent_trader_id,6) as frequent_trader_id
    , time_in_force
    , is_ats_or_cons
    , mpid
    , ALTERNATIVE_COMPLIANCE_ID
    , street_trade_record_time
    , street_order_process_time
    , co_client_leg_ref_id as leg_ref_id
    --, v.blaze_account_alias
	, case when v.is_cross_order='Y'
             then  public.get_message_tag_string_cross_multileg(v.order_fix_message_id, 10445, v.date_id::int,v.client_order_id, NULL, v.co_client_leg_ref_id, v.is_cross_order::boolean)
             else v.blaze_account_alias
      end
from genesis2.trade_record_v_historical v
	left join dwh.d_instrument i on v.instrument_id =i.instrument_id
--	where exec_id between l_max_exec_id+1 and l_max_exec_id+100001;
	where dataset_id between l_max_dataset_id+1 and l_foreign_max_dataset_id /*-50*/;

    insert into genesis2.fact_last_load_id (value_name, last_id)
    values ('trade_record', l_foreign_max_dataset_id)
    on conflict (value_name) do update
        set last_id = excluded.last_id;

select load_log(l_load_id, l_step_id, 'trade_record l_foreign_max_dataset_id='||l_foreign_max_dataset_id, 0, 'I')
into l_step_id;


ELSE
  select load_log(l_load_id, l_step_id,'Nothing to insert ', 0, 'E')
        into l_step_id;
    RAISE notice 'Nothing to insert';

-- SO removed
  /*
if 1=2 and current_time < '06:30'::time
 then
    l_status_message:='l_arch_max_exec_id';
	select COALESCE(max(exec_id),0)
	into l_arch_max_exec_id from genesis2.trade_record
	where date_id < 20160101;

	select load_log(l_load_id, l_step_id, 'l_arch_max_exec_id = '||l_arch_max_exec_id,0, 'S')
	into l_step_id;

	RAISE INFO 'ARCH MAX exec_id is    %', l_max_exec_id;


/*	l_status_message:='l_arch_foreign_max_exec_id = ';
	--SELECT COALESCE(max(exec_id),0) FROM staging.psql_execution into l_foreign_max_exec_id;
	SELECT  COALESCE(max(exec_id),0) into l_arch_foreign_max_exec_id
    FROM staging.trade_record_varch  ;*/
	insert into genesis2.trade_record (trade_record_time, db_create_time, date_id,
		    is_busted, orig_trade_record_id, trade_record_trans_type, trade_record_reason,
		    subsystem_id, user_id, account_id, client_order_id, instrument_id ,
		    side, open_close, fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator,
		    secondary_order_id, exch_exec_id, secondary_exch_exec_id, last_mkt,
		    last_qty, last_px, ex_destination, sub_strategy, street_order_id,
		    order_id, street_order_qty, order_qty, multileg_reporting_type,
		    is_largest_leg, street_max_floor, exec_broker, cmta,
		    street_time_in_force, street_order_type, opt_customer_firm, street_mpid,
		    is_cross_order, street_is_cross_order, street_cross_type, cross_is_originator,
		    street_cross_is_originator, contra_account, contra_broker, trade_exec_broker,
		    order_fix_message_id, trade_fix_message_id,  street_order_fix_message_id, client_id,
		    street_transaction_id, transaction_id, order_price, street_order_price, order_process_time ,
		    street_client_order_id, fix_comp_id, LEAVES_QTY, street_exec_inst, fee_sensitivity,
		    strategy_decision_reason_code, compliance_id, floor_broker_id, AUCTION_ID,
		    street_opt_customer_firm, multileg_order_id, int_liq_source_type

		    )
	select TRADE_RECORD_TIME
	, now()
	, DATE_ID
	, 'N' as IS_BUSTED
	, IN_ORIG_TRADE_RECORD_ID
	, TRADE_RECORD_TRANS_TYPE
	, TRADE_RECORD_REASON
	, SUB_SYSTEM_ID
	, USER_ID
	, ACCOUNT_ID
	, CLIENT_ORDER_ID
	, INSTRUMENT_ID
	, SIDE
	, OPEN_CLOSE
	, FIX_CONNECTION_ID
	, EXEC_ID
	, CASE WHEN exchange_id in ('C2OXFX','CBOEFX') then substring(exchange_id, 1, length(exchange_id)-2) else exchange_id end as exchange_id
	, TRADE_LIQUIDITY_INDICATOR
	, SECONDARY_ORDER_ID
	, EXCH_EXEC_ID
	, SECONDARY_EXCH_EXEC_ID
	, LAST_MKT
	, LAST_QTY
	, LAST_PX
	, EX_DESTINATION
	, SUB_STRATEGY
	, STREET_ORDER_ID
	, ORDER_ID
	, STREET_ORDER_QTY
	, ORDER_QTY

	, MULTILEG_REPORTING_TYPE
	, IS_LARGEST_LEG
	, STREET_MAX_FLOOR
	, EXEC_BROKER
	, CMTA
	, STREET_TIME_IN_FORCE
	, STREET_ORDER_TYPE
	, OPT_CUSTOMER_FIRM
	, STREET_MPID
	, IS_CROSS_ORDER
	, STREET_IS_CROSS_ORDER
	, STREET_CROSS_TYPE
	, CROSS_IS_ORIGINATOR
	, STREET_CROSS_IS_ORIGINATOR
	, CONTRA_ACCOUNT
	, CONTRA_BROKER
	, TRADE_EXEC_BROKER
	, order_fix_message_id
	, trade_fix_message_id
	, street_order_fix_message_id
	, client_id
	, street_transaction_id
	, transaction_id
	, order_price
	, street_order_price
	, order_process_time
	, street_client_order_id
	, fix_comp_id
    , LEAVES_QTY
    , street_exec_inst
    , fee_sensitivity
    , strategy_decision_reason_code
    , compliance_id
    , floor_broker_id
    , AUCTION_ID
    , STR_OPT_CUSTOMER_FIRM
    , multileg_order_id
    , is_ats_or_cons


	from staging.trade_record_varch
	/*where exec_id between l_max_exec_id+1 and l_max_exec_id+100001;*/
	where exec_id between l_arch_max_exec_id+1 and l_arch_max_exec_id+550000 /*-50*/;

	select load_log(l_load_id, l_step_id, 'trade_record arch insert', 0, 'I')
	into l_step_id;

 end if;
*/
END IF;

select load_log(l_load_id, l_step_id, 'AFTER IF', 0, 'I')
into l_step_id;
/* where exec_id > l_max_exec_id */

-- GET DIAGNOSTICS does not work on partitioned tables since version 8.4 at lest !!!!
 --GET DIAGNOSTICS l_row_cnt = ROW_COUNT;



 /*select count(1) into l_ret
 from trade_record
 where date_id = to_number(to_char(current_date, 'YYYYMMDD'),'99999999');*/

 if in_dataset_id is null
  then
   /* replicate busted trades without recalculation.
     1. Must be inside in_exec_id is null
     2. MUST be before recalculated */


 /*update trade_record tr
 set is_busted = 'Y'
 where tr.exec_id in (select exec_id from staging.psql_execution psq where psq.is_busted='Y')
   and tr.is_busted='N';*/

 /*======================*/

 -- DISASTER
  select load_log(l_load_id, l_step_id, 'INSIDE in_dataset_id is null', 0, 'I')
into l_step_id;

  if (select count(1) from staging.psql_execution psq where psq.is_busted='Y' and OPERATION$ <> 'D')>0
   then
     select load_log(l_load_id, l_step_id, 'is_busted=Y', 0, 'I')
     into l_step_id;

	WITH upd AS (update genesis2.trade_record tr
			 set is_busted = 'Y'
			 where tr.exec_id in (select exec_id from staging.psql_execution psq where psq.is_busted='Y' and OPERATION$ <> 'D')
			   and tr.is_busted='N'
			   and date_id > 20210701
       RETURNING trade_record_id, tr.date_id)
    insert into public.etl_subscriptions (subscription_name, source_table_name, load_batch_id, date_id)
	Select 'big_data.flat_trade_record', 'TRADE_RECORD.BUSTED_TRADES', trade_record_id, date_id FROM upd;


  	GET DIAGNOSTICS l_ret = ROW_COUNT;

	select load_log(l_load_id, l_step_id, 'Update to BUSTED ', l_ret, 'U')
	into l_step_id;
	end if;


 /*        RECALCULATED TRADES */

  /* =======================================*/

--     select load_log(l_load_id, l_step_id, 'Before RECALCULATED TRADES', 0, 'I')
--     into l_step_id;
--
-- ============ We do not use billing on the Oracle side anymore
--  -- DISASTER
--  for l_scr in (select TRADE_RECORD_RECALC_ID, EXEC_ID from staging.PSQL_TRADE_RECORD_RECALC where is_processed=0) loop
--
--   with upd as (update trade_record
--			set is_busted='Y'
--			where exec_id = l_scr.exec_id
--			and is_busted='N'
--			and coalesce (trade_record_reason , 'O') <> 'P'
--		      RETURNING trade_record_id, date_id)
--        select array_to_json(array(select row(trade_record_id, date_id)  FROM upd)) into l_busted_jsn;
--
--  	GET DIAGNOSTICS l_ret = ROW_COUNT;
--
--	if l_busted_jsn is not null and jsonb_array_length(l_busted_jsn)>0
--      then
--        perform load_trade_record_inc(l_scr.exec_id, (l_busted_jsn->0->>'f1')::int, 'R');
--
--		update staging.PSQL_TRADE_RECORD_RECALC
--		set process_time = statement_timestamp(),
--		    is_processed=1
--		where TRADE_RECORD_RECALC_id = l_scr.TRADE_RECORD_RECALC_id;
--
--	    insert into genesis2.etl_subscriptions (subscription_name, source_table_name, load_batch_id, date_id )
--		Select 'big_data.flat_trade_record', 'TRADE_RECORD.BUSTED_TRADES', (tr_id->'f1')::int, (tr_id->>'f2')::int
--	   from jsonb_array_elements (l_busted_jsn) tr_id;
--	end if;
--
--end loop;

end if;

/* =============================================================================================================== */
/* ========================================= AWAY TRADE=========================================================== */
/* =============================================================================================================== */

if in_dataset_id is null
 then
	select public.load_log(l_load_id, l_step_id, 'AWAY TRADES processing started', 0, 'I')
	into l_step_id;

   l_date_id:=to_char(current_date ,'YYYYMMDD')::int ;

/* We take into account last but one completed Missed trade job
 * Missed job has delay 12 minutes to be sure we are not ahead Oracle traffic
 * We can't use last completed ID bacuse aftre completion we have matching process. It update all load_batchIds to -1 to avoid picking up trade too early
 * */

  select max(load_batch_id)
	  into l_away_load_batch
	from genesis2.etl_load_batch
	where file_name ='Load_Missed_Trades_MSSQL'
	and process_end_date_time < now()
	and status ='C';

  INSERT INTO genesis2.trade_record
	(trade_record_time
			,date_id
			,is_busted
			,orig_trade_record_id
			,trade_record_trans_type
			,trade_record_reason
			,subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id
			,load_batch_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias )

select trade_record_time
			,date_id
			,is_busted
			,orig_trade_record_id
			,trade_record_trans_type
			,'A' as trade_record_reason
--			,subsystem_id
			,case when (generation>0  or (is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ))
			            and subsystem_id = 'LPEDW'
				  then 'LPEDW_DUPE'
			 else subsystem_id
			 end as subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,e.exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,e.last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,nullif(left(cmta,3), '') as cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,nullif(street_client_order_id,'') as street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id::varchar
			,l_load_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias
	from staging.trade_record_missed_lp trml
	join dwh.d_exchange e on  e.exchange_id=trml.exchange_id
					and e.is_active
					and e.exchange_id=e.real_exchange_id
    where trade_record_id is null
    and instrument_id is not null
--    and subsystem_id not in ('OMS_EDW')
    and (  (subsystem_id not in ('OMS_EDW') and  generation = 0 and not is_sor_routed )/* ordinar case non sor routed trades */
		    or (subsystem_id not in ('OMS_EDW') and  generation = 0 and is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* routed to sor with company name changes*/
		    or (subsystem_id not in ('OMS_EDW') and  generation>0 and is_company_name_changed =1 and not is_sor_routed and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* non-routed to SOR company name chaned in firther generation*/
		    or (subsystem_id not in ('OMS_EDW') and generation>0 and is_company_name_changed =1 and is_sor_routed and mx_gen>generation and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' )
		    or (subsystem_id in ('OMS_EDW') and generation=0 and secondary_exch_exec_id = 'Manual Report' and not is_sor_routed and trml.instrument_type_id not in ('E') )
		)
    and date_id = l_date_id
    and trml.load_batch_id <> -1
    and trml.load_batch_id < l_away_load_batch
    and last_qty<=order_qty
    and trml.is_busted ='N'
    --and not trml.is_flex_order
    ;

	update staging.trade_record_missed_lp trml
	set trade_record_id = tr.trade_record_id ,
		mapping_logic = 20
	from genesis2.trade_record tr
	where tr.date_id = l_date_id
	 and tr.load_batch_id = l_load_id
	 and tr.subsystem_id in ('LPEDW', 'LPEDW_DUPE', 'OMS_EDW')
	 and trml.trade_record_id is null
	 and trml.date_id =tr.date_id
	 and trml.exec_id = tr.exec_id
	 and trml.load_batch_id <> -1
	 and trml.load_batch_id < l_away_load_batch;


   	GET DIAGNOSTICS l_cnt = ROW_COUNT;


--	select count(1)
--   	from genesis2.trade_record trml
--    where date_id = l_date_id
--    and load_batch_id=l_load_id
--    into l_cnt;

	select public.load_log(l_load_id, l_step_id, 'AWAY TRADES INSERT INSERTED load_batch_id='||l_load_id, l_cnt, 'I')
	into l_step_id;
end if;


/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   AWAY TRADES ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/

select load_log(l_load_id, l_step_id, 'Trade_Record_inc COMPLETED ===', 0, 'O')
into l_step_id;

 l_ret:=1;

 return l_ret;

 exception when others then
   select public.load_log(l_load_id, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E')
  into l_step_id;
  RAISE notice '% %', sqlstate, sqlerrm;

  select public.load_log(l_load_id, l_step_id, 'Trade_Record_inc COMPLETED ===', 0, 'O')
  into l_step_id;

  PERFORM public.load_error_log('trade_record',  'I', REPLACE(sqlerrm, ''::text, ''::text), l_load_id);
  RAISE;



END;
$function$
;
