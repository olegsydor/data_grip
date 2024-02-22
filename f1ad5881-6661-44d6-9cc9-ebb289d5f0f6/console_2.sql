/*
select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.data_type, parameters.ordinal_position, *
from information_schema.routines
         left join information_schema.parameters on routines.specific_name = parameters.specific_name
where true

and routine_name !~~* all(ARRAY['%_bkp%', '%_old%', '%_tst%', '%_test%'])
and routines.routine_schema not in ('trash', 'pg_catalog', 'information_schema')
--and routines.routine_schema in ('trash', 'dash360', 'dash_reporting')
and routine_definition ilike '%text\_%'
and routine_definition ilike '%CONDITIONAL_EXECUTION%'
*/
------------------

ALTER TABLE dwh.conditional_execution RENAME COLUMN text_ TO exec_text;


CREATE OR REPLACE FUNCTION dwh.reload_historic_order_cond(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[])
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- PD: 20240118 https://dashfinancial.atlassian.net/browse/DS-7780 added new Optwap columns


declare
 l_row_cnt int;
begin



	create temp table temp_hods
	on commit drop as
	 SELECT
	    CO.ORDER_ID as "OrderID",
	   --EX.ORA_ROWSCN as "ORA_ROWSCN",
	   CO.CLIENT_ORDER_ID as "ClOrdID",
	   COORIG.CLIENT_ORDER_ID as "OrigClOrdID",
	   CO.ORDER_CLASS as "OrderClass",
	   CO.PARENT_ORDER_ID as "CustomerOrderID",
	   EX.EXEC_ID as "ExecID",
	   EX.REF_EXEC_ID as "RefExecID",
	   CO.INSTRUMENT_ID as "InstrumentID",
	   HSD.SYMBOL as "Symbol",
	   HSD.instrument_type_id as "InstrumentType",
	   HSD.maturity_year  as "MaturityYear",
	   HSD.maturity_month  as "MaturityMonth",
	   HSD.maturity_day as "MaturityDay",
	   HSD.put_call as "PutCall",
	   HSD.strike_px as "StrikePx",
	   HSD.opra_symbol as "OPRASymbol",
	   HSD.display_instrument_id as "DisplayInstrumentID",
	   HSD.underlying_display_instrument_id as "UnderlyingDisplayInstrID",
	   CO.CREATE_TIME as "OrderCreationTime",
	   EX.EXEC_TIME as "TransactTime",
	   /* (SELECT FM.pg_db_create_time
	    FROM fix_capture.fix_message_json FM
	    WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
	    and ex.date_id = 20230307
	    ) "LogTime",*/
	   CO.PROCESS_TIME as "RoutedTime",
	   CO.order_type as "OrderType",
	   CO.SIDE as "Side",
	   CO.ORDER_QTY as "OrderQty",
	   CO.PRICE as "Price",
	   CO.time_in_force as "TimeInForce",
	   CO.EXPIRE_TIME as "ExpireTime",
	   CO.OPEN_CLOSE::char(1) as "OpenClose",
	   CO.EX_DESTINATION as "ExDestination",
	   CO.HANDL_INST::char(1) as "HandlInst",
	   --CO.EXEC_INST as "ExecInst",
	   CO.MAX_SHOW_QTY as "MaxShowQty",
	   CO.MAX_FLOOR as "MaxFloorQty",
	   CO.EQ_ORDER_CAPACITY::char(1) as "OrderCapacity",
	   case
	   	 when HSD.Instrument_Type_id = 'E'
	   	 then ACC.EQ_MPID
	   	 else null
	   end as "MarketParticipantID",
	   CO.LOCATE_REQ as "IsLocateRequired",
	   CO.LOCATE_BROKER as "LocateBroker",
	   EX.EXEC_TYPE::char(1) as "ExecType",
	   EX.ORDER_STATUS::char(1) as "OrderStatus",
	   case
	   	 when EX.EXEC_TYPE = '8'
	   	 then EX.exec_text
	   	 else null
	   end as "RejectReason",
	   EX.LEAVES_QTY as "LeavesQty",
	     --EX.CUM_QTY "CumQty",
	   coalesce(ODCS."DAY_CUM_QTY",0) as "CumQty",
	    --EX.AVG_PX "AvgPx",
	   ROUND(coalesce(ODCS."DAY_AVG_PX", 0), 4) as "AvgPx",
	    --
	   EX.LAST_QTY as "LastQty",
	   EX.LAST_PX as "LastPx",
	    --in order to provide correct displaying of Arca ortions
	    CASE
	      WHEN EX.EXEC_TYPE NOT IN ('F', 'G')
	      THEN NULL
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN EX.LAST_MKT
	      ELSE CO.EX_DESTINATION
	    END "LastMkt",
	    CASE
	        WHEN ( co.order_qty - ex.cum_qty + coalesce(odcs."DAY_CUM_QTY",0)) > 0
			    THEN co.order_qty - ex.cum_qty + coalesce(odcs."DAY_CUM_QTY",0)
	        ELSE 0
	    END "DayOrderQty",
	   coalesce(ODCS."DAY_CUM_QTY",0) as "DayCumQty",
	   ROUND(coalesce(ODCS."DAY_AVG_PX", 0), 4) as "DayAvgPx",
	   CO.ACCOUNT_ID as "AccountID",
	   FC.FIX_COMP_ID as "FixCompID", --sending firm
	   CO.client_id_text as "ClientID",
	   EX.exec_text as "Text",
	    (CASE
	      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
	      THEN 'Y'
	      ELSE 'N'
	    end)::char(1) "IsOSROrder",
		coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
	   CO.sub_strategy as "SubStrategy",
	   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
	   CO.TRANS_TYPE as "TransType",
	   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
	   co.sub_system_id  as "SubSystemID",
	   CO.TRANSACTION_ID as "TransactionID",
	   CO.EXCHANGE_ID as "ExchangeID",
	   CO.strategy_decision_reason_code as "StrategyDecisionReasonCode",
	   CO.ALGO_START_TIME as "AlgoStartTime",
	   CO.ALGO_END_TIME as "AlgoEndTime",
	   --CO.MIN_TARGET_QTY as "MinTargetQty",
	   CO.DISCRETION_OFFSET as "DiscretionOffset",
	   CO.co_sub_account as "SubAccount",
	   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
	   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",
	   'Y'::char(1) "IsConditionalOrder",
	   AC.FIX_COMP_ID "FixCompID2",
	   I.SYMBOL_SUFFIX "SymbolSfx",
	   CO.date_id "CreateDateID",
	   EX.date_id "TradeDateID",
	   EX.exec_time::date as "TradeDate",
	   CO.optwap_bin_number as "OptwapBinNumber",
	   CO.optwap_phase as "OptwapPhase",
	   CO.optwap_order_price as "OptwapOrderPrice",
	   CO.optwap_bin_duration as "OptwapBinDuration",
	   CO.optwap_bin_qty as "OptwapBinQty",
	   CO.optwap_phase_duration as "OptwapPhaseDuration"
	   from dwh.conditional_execution ex
	   join dwh.conditional_order co on ex.order_id = co.order_id and ex.date_id = co.date_id
	   join dwh.d_instrument i on i.instrument_id = co.instrument_id
	   join dwh.historic_security_definition hsd on hsd.instrument_id = co.instrument_id
	   join dwh.d_fix_connection fc on  fc.fix_connection_id = co.fix_connection_id
	   join staging.acceptor ac on ac.acceptor_id = fc.acceptor_id
	   join d_account acc on co.account_id = acc.account_id
	   left join dwh.conditional_order coorig on co.orig_order_id = coorig.order_id and coorig.date_id = co.date_id
	   left join dwh.d_order_type dot on dot.order_type_id = co.order_type
	   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force and dtif.is_active
	   left join lateral
	    (select sum(eq.last_qty) "DAY_CUM_QTY",
	      eq.order_id "order_id",
	      eq.exec_time::date "trade_date",
	     sum(eq.last_qty*eq.last_px)/nullif(sum(eq.last_qty),0) "DAY_AVG_PX"
	    from conditional_execution eq
	    where eq.exec_type in ('F', 'G')
	    and date_id = in_date_id
	    and eq.is_busted   <> 'Y'
	    and ex.order_id = eq.order_id
	    and ex.exec_time::date  = eq.exec_time::date
	    group by eq.order_id,
	      eq.exec_time::date
	    limit 1
	    ) odcs on true
	   where ex.order_status <> '3'
	   and case when in_order_ids_arr <> '{}' then ex.order_id = any(in_order_ids_arr) else true end
	   and ex.date_id = in_date_id;

	   analyze temp_hods;


	   raise  INFO  '%: temp table has been created',  clock_timestamp()::text;


	   insert into dwh.historic_order_details_storage --trash.pd_historic_order_details_storage
	   ("OrderID",
		  "ClOrdID", "OrigClOrdID", "OrderClass", "CustomerOrderID", "ExecID",
		  "RefExecID", "InstrumentID", "Symbol", "InstrumentType", "MaturityYear",
		  "MaturityMonth", "MaturityDay", "PutCall", "StrikePx", "OPRASymbol",
		  "DisplayInstrumentID", "UnderlyingDisplayInstrID", "OrderCreationTime",
		  "TransactTime", /*"LogTime",*/ "RoutedTime", "OrderType", "Side", "OrderQty",
		  "Price", "StopPx", "TimeInForce", "ExpireTime", "OpenClose", "ExDestination",
		  "AliasExDestination", "HandlInst", "MaxShowQty", "MaxFloorQty",
		  "ClearingFirmID", "ExecBroker", "CustomerOrFirm", "OrderCapacity",
		  "MarketParticipantID", "IsLocateRequired", "LocateBroker", "ExecType",
		  "OrderStatus", "RejectReason", "LeavesQty", "CumQty", "AvgPx", "LastQty",
		  "LastPx", "LastMkt", "DayOrderQty", "DayCumQty", "DayAvgPx", "AccountID",
		  "TradeLiquidityIndicator", "MultilegReportingType", "LegRefID",
		  "MultilegOrderID", "FixCompID", "ClientID", "Text",
		  "IsOSROrder", "OSROrderID", "SubStrategy", "AlgoStopPx", "AlgoClOrdID", "DashClOrdID", "OCCOptionalData", "SubSystemID",
	    "TransactionID","TotNoOrdersInTransaction","ExchangeID","CrossOrderID","AggressionLevel","HiddenFlag",
	    "AlgoStartTime","AlgoEndTime","ExtendedOrdType","PrimListingExchange","PreOpenBehavior","MaxWaveQtyPct","SweepStyle","DiscretionOffset","CrossType",
	    "QuoteID","StepUpPriceType","StepUpPrice","CrossAccountID","AuctionID",
	    "ClearingAccount", "SubAccount", "RequestNumber", "LiquidityProviderID", "InternalComponentType",
	    "ComplianceID", "AlternativeComplianceID", "ConditionalClientOrderID", "IsConditionalOrder",
	    "RoutingTableEntryID", "MaxVegaPerStrike", "PerStrikeVegaExposure", "VegaBehavior", "DeltaBehavior", "HedgeParamUnits", "MinDelta",
	    "FixCompID2","SymbolSfx","StrategyDecisionReasonCode","SessionEligibility","CreateDateID",
	    "StatusDate","Status_Date_id", "OptwapBinNumber", "OptwapPhase", "OptwapOrderPrice", "OptwapBinDuration", "OptwapBinQty", "OptwapPhaseDuration")
	   select HCOD."OrderID",
			HCOD."ClOrdID",
			HCOD."OrigClOrdID",
			HCOD."OrderClass",
			HCOD."CustomerOrderID",
			HCOD."ExecID",
			HCOD."RefExecID",
			HCOD."InstrumentID",
			HCOD."Symbol",
			HCOD."InstrumentType",
			HCOD."MaturityYear",
			HCOD."MaturityMonth",
			HCOD."MaturityDay",
			HCOD."PutCall",
			HCOD."StrikePx",
			HCOD."OPRASymbol",
			HCOD."DisplayInstrumentID",
			HCOD."UnderlyingDisplayInstrID",
			HCOD."OrderCreationTime",
			HCOD."TransactTime",
			HCOD."RoutedTime",
			HCOD."OrderType",
			HCOD."Side",
			HCOD."OrderQty",
			HCOD."Price",
			null "StopPx",
			HCOD."TimeInForce",
			HCOD."ExpireTime",
			HCOD."OpenClose",
			HCOD."ExDestination",
			HCOD."ExDestination",
			HCOD."HandlInst",
			HCOD."MaxShowQty",
			HCOD."MaxFloorQty",
			null "ClearingFirmID",
			null "ExecBroker",
			null "CustomerOrFirm",
			HCOD."OrderCapacity",
			HCOD."MarketParticipantID",
			HCOD."IsLocateRequired",
			HCOD."LocateBroker",
			HCOD."ExecType",
			HCOD."OrderStatus",
			HCOD."RejectReason",
			HCOD."LeavesQty",
			HCOD."CumQty",
			HCOD."AvgPx",
			HCOD."LastQty",
			HCOD."LastPx",
			HCOD."LastMkt",
			HCOD."DayOrderQty",
			HCOD."DayCumQty",
			HCOD."DayAvgPx",
			HCOD."AccountID",
			null "TradeLiquidityIndicator",
			null "MultilegReportingType",
			null "LegRefID",
			null "MultilegOrderID",
			HCOD."FixCompID",
			HCOD."ClientID",
			HCOD."Text",
			HCOD."IsOSROrder",
			HCOD."OSROrderID",
			HCOD."SubStrategy",
			null "AlgoStopPx",
			null "AlgoClOrdID",
			null "DashClOrdID",
			HCOD."OCCOptionalData",
			HCOD."SubSystemID",
			HCOD."TransactionID",
			null "TotNoOrdersInTransaction",
			HCOD."ExchangeID",
			null "CrossOrderID",
			null "AggressionLevel",
			null "HiddenFlag",
			HCOD."AlgoStartTime",
			HCOD."AlgoEndTime",
			null "ExtendedOrdType",
			null "PrimaryListingExchange",
			null "PreOpenBehavior",
			null "MaxWaveQtyPct",
			null "SweepStyle",
			HCOD."DiscretionOffset",
			null "CrossType",
			null "QuoteID",
			null "StepUpPriceType",
			null "StepUpPrice",
			null "CrossAccountID",
			null "AuctionID",
			null "ClearingAccount",
			null "SubAccount",
			null "RequestNumber",
			null "LiquidityProviderID",
			null "InternalComponentType",
			null "ComplianceID",
			null "AlternativeComplianceID",
			null "ConditionalClientOrderID",
			HCOD."IsConditionalOrder",
            null "RoutingTableEntryID",
            null "MaxVegaPerStrike",
            null "PerStrikeVegaExposure",
            null "VegaBehavior",
            null "DeltaBehavior",
            null "HedgeParamUnits",
            null "MinDelta",
            HCOD."FixCompID2",
            HCOD."SymbolSfx",
            HCOD."StrategyDecisionReasonCode",
			null "SessionEligibility",
			HCOD."CreateDateID",
			HCOD."TradeDate" as "StatusDate",
			in_date_id as "Status_Date_id",
			HCOD."OptwapBinNumber",
			HCOD."OptwapPhase",
			HCOD."OptwapOrderPrice",
			HCOD."OptwapBinDuration",
			HCOD."OptwapBinQty",
			HCOD."OptwapPhaseDuration"
			from temp_hods HCOD
	   	WHERE HCOD."TransType" <> 'F'
			AND HCOD."ExecID" in (
	        select max(e.exec_id) from dwh.conditional_execution e
		  	where case when in_order_ids_arr <> '{}' then e.order_id = any(in_order_ids_arr) else true end
			  and e.date_id = in_date_id
	          and e.order_status <> '3'
	          group by e.order_id)
	    /*on conflict ("OrderID","StatusDate", "Status_Date_id") do update
	    	set "OrderID"= excluded."OrderID",
			"ClOrdID"= excluded."ClOrdID",
			"OrigClOrdID"= excluded."OrigClOrdID",
			"ExecID"= excluded."ExecID",
			"RefExecID"= excluded."RefExecID",
			"Symbol"= excluded."Symbol",
			"InstrumentType"= excluded."InstrumentType",
			"MaturityYear"= excluded."MaturityYear",
			"MaturityMonth"= excluded."MaturityMonth",
			"MaturityDay"= excluded."MaturityDay",
			"PutCall"= excluded."PutCall",
			"StrikePx"= excluded."StrikePx",
			"DisplayInstrumentID"= excluded."DisplayInstrumentID",
			"TransactTime"= excluded."TransactTime",
			"OrderType"= excluded."OrderType",
			"OrderClass"= excluded."OrderClass",
			"Side"= excluded."Side",
			"OrderQty"= excluded."OrderQty",
			"Price"= excluded."Price",
			"StopPx"= excluded."StopPx",
			"TimeInForce"= excluded."TimeInForce",
			"ExpireTime"= excluded."ExpireTime",
			"HandlInst"= excluded."HandlInst",
			"OpenClose"= excluded."OpenClose",
			"ExecInst"= excluded."ExecInst",
			"MaxShowQty"= excluded."MaxShowQty",
			"MaxFloorQty"= excluded."MaxFloorQty",
			"ClearingFirmID"= excluded."ClearingFirmID",
			"ExecBroker"= excluded."ExecBroker",
			"MarketParticipantID"= excluded."MarketParticipantID",
			"CustomerOrFirm"= excluded."CustomerOrFirm",
			"OrderCapacity"= excluded."OrderCapacity",
			"IsLocateRequired"= excluded."IsLocateRequired",
			"LocateBroker"= excluded."LocateBroker",
			"ExecType"= excluded."ExecType",
			"OrderStatus"= excluded."OrderStatus",
			"RejectReason"= excluded."RejectReason",
			"LeavesQty"= excluded."LeavesQty",
			"CumQty"= excluded."CumQty",
			"AvgPx"= excluded."AvgPx",
			"LastQty"= excluded."LastQty",
			"LastPx"= excluded."LastPx",
			"LastMkt"= excluded."LastMkt",
			"DayOrderQty"= excluded."DayOrderQty",
			"DayCumQty"= excluded."DayCumQty",
			"DayAvgPx"= excluded."DayAvgPx",
			"AccountID"= excluded."AccountID",
			"MultilegReportingType"= excluded."MultilegReportingType",
			"LegRefID"= excluded."LegRefID",
			"TradeLiquidityIndicator"= excluded."TradeLiquidityIndicator",
			"CustomerOrderID"= excluded."CustomerOrderID",
			"FixCompID"= excluded."FixCompID",
			"ClientID"= excluded."ClientID",
			"Text"= excluded."Text",
			"RoutedTime"= excluded."RoutedTime",
			"ExchExecID"= excluded."ExchExecID",
			"OrderFixMsgID"= excluded."OrderFixMsgID",
			"ExecFixMsgID"= excluded."ExecFixMsgID",
			"MultilegOrderID"= excluded."MultilegOrderID",
			"InstrumentID"= excluded."InstrumentID",
			"LogTime"= excluded."LogTime",
			"RouteReason"= excluded."RouteReason",
			"IsOSROrder"= excluded."IsOSROrder",
			"OSROrderID"= excluded."OSROrderID",
			"OPRASymbol"= excluded."OPRASymbol",
			"OrderCreationTime"= excluded."OrderCreationTime",
			"SubStrategy"= excluded."SubStrategy",
			"UnderlyingDisplayInstrID"= excluded."UnderlyingDisplayInstrID",
			"AlgoClOrdID"= excluded."AlgoClOrdID",
			"AliasExDestination"= excluded."AliasExDestination",
			"AlgoStopPx"= excluded."AlgoStopPx",
			"DashClOrdID"= excluded."DashClOrdID",
			"StatusDate"= excluded."StatusDate",
			"OCCOptionalData"= excluded."OCCOptionalData",
			"ExDestination"= excluded."ExDestination",
			"SubSystemID"= excluded."SubSystemID",
			"TransactionID"= excluded."TransactionID",
			"TotNoOrdersInTransaction"= excluded."TotNoOrdersInTransaction",
			"ExchangeID"= excluded."ExchangeID",
			"FeeSensitivity"= excluded."FeeSensitivity",
			"OnBehalfOfSubID"= excluded."OnBehalfOfSubID",
			"StrategyDecisionReasonCode"= excluded."StrategyDecisionReasonCode",
			"InternalOrderID"= excluded."InternalOrderID",
			"CrossOrderID"= excluded."CrossOrderID",
			"AlgoStartTime"= excluded."AlgoStartTime",
			"AlgoEndTime"= excluded."AlgoEndTime",
			"MinTargetQty"= excluded."MinTargetQty",
			"ExtendedOrdType"= excluded."ExtendedOrdType",
			"PrimListingExchange"= excluded."PrimListingExchange",
			"PostingExchange"= excluded."PostingExchange",
			"PreOpenBehavior"= excluded."PreOpenBehavior",
			"MaxWaveQtyPct"= excluded."MaxWaveQtyPct",
			"SweepStyle"= excluded."SweepStyle",
			"DiscretionOffset"= excluded."DiscretionOffset",
			"CrossType"= excluded."CrossType",
			"AggressionLevel"= excluded."AggressionLevel",
			"HiddenFlag"= excluded."HiddenFlag",
			"AuctionID"= excluded."AuctionID",
			"QuoteID"= excluded."QuoteID",
			"StepUpPriceType"= excluded."StepUpPriceType",
			"StepUpPrice"= excluded."StepUpPrice",
			"CrossAccountID"= excluded."CrossAccountID",
			"ConditionalClientOrderID"= excluded."ConditionalClientOrderID",
			"IsConditionalOrder"= excluded."IsConditionalOrder",
			"MaxVegaPerStrike"= excluded."MaxVegaPerStrike",
			"PerStrikeVegaExposure"= excluded."PerStrikeVegaExposure",
			"VegaBehavior"= excluded."VegaBehavior",
			"DeltaBehavior"= excluded."DeltaBehavior",
			"HedgeParamUnits"= excluded."HedgeParamUnits",
			"MinDelta"= excluded."MinDelta",
			"RoutingTableEntryID"= excluded."RoutingTableEntryID",
			"SymbolSfx"= excluded."SymbolSfx",
			"FixCompID2"= excluded."FixCompID2",
			"ProductDescription"= excluded."ProductDescription",
			"SessionEligibility"= excluded."SessionEligibility",
			"CreateDateID"= excluded."CreateDateID",
			"AlternativeComplianceID"= excluded."AlternativeComplianceID",
			"ComplianceID"= excluded."ComplianceID"*/;


	   GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;

	   raise  INFO  '%:  inserted rows: %',  clock_timestamp()::text, l_row_cnt;

	   return l_row_cnt;

end
$function$
;


CREATE OR REPLACE PROCEDURE staging.tlnd_load_conditional_execution_sp(IN in_l_seq integer, IN in_l_step integer, IN in_l_table_name character varying)
 LANGUAGE plpgsql
AS $procedure$ declare
	date_id_curs refcursor;--cursor for execute format('select distinct date_id from staging.tlnd_conditional_execution_%s where rtrim(operation )= ''I'';',in_l_seq::varchar);
	l_sql text;
	l_date_id int;
	l_in_l_seq int;
	l_in_l_step int;
	l_in_table_name text;
	l_row_count int;
	l_run_condition int;

begin

	l_in_l_seq:= in_l_seq;
	l_in_l_step:= in_l_step;


	--==============================================================
	--============ Cheking if table not exists then exit============
	--==============================================================

	l_in_table_name:= 'tlnd_conditional_execution_'||in_l_seq::varchar;

	SELECT count(1)
	into l_run_condition
	from information_schema.tables
    	where table_schema = 'staging'
			and table_name = l_in_table_name
	;

	select public.load_log(l_in_l_seq, l_in_l_step, 'l_run_condition = '||l_run_condition::varchar, 0, 'O')
	into l_in_l_step;

	if l_run_condition = 0

		then

			return;

	end if;

	--================================================================

	l_in_table_name:=in_l_table_name;

	select public.load_log (l_in_l_seq,l_in_l_step,'tlnd_load_conditional_execution_sp STARTED >>>>>>',0,'S'::text)
			into l_in_l_step;

	l_sql:='insert into dwh.conditional_execution
			(exec_id,exch_exec_id,order_id,fix_message_id,exec_type,order_status,exec_time,leaves_qty,last_mkt,exec_text,is_busted,exchange_id,date_id,
			 last_qty,cum_qty,last_px,ref_exec_id)
		 	select exec_id,exch_exec_id,order_id,fix_message_id,exec_type,order_status,exec_time,leaves_qty,last_mkt,text_,is_busted,exchange_id,date_id,
				last_qty,cum_qty,last_px,ref_exec_id
				from staging.tlnd_conditional_execution_'||in_l_seq::varchar||'
					where rtrim(operation)=''I'' and date_id = $1
						on conflict (exec_id) do update
							set date_id = coalesce(public.f_insert_etl_reject(''load_temp_conditional_execution''::varchar,''exec_id_pkey'',''(date_id= ''||EXCLUDED.date_id||'',exec_id= ''||EXCLUDED.exec_id||'',exec_time = ''||EXCLUDED.exec_time||'')''::varchar),
								EXCLUDED.date_id);';


	open date_id_curs for execute format('select distinct date_id from staging.tlnd_conditional_execution_%s where rtrim(operation )= ''I'';',in_l_seq::varchar);
	loop
	fetch  date_id_curs into l_date_id;
	exit when not found;

		--l_sql:= replace(l_sql,'&p_date_id',l_date_id::text);
		execute l_sql
			using l_date_id;

			get diagnostics l_row_count = row_count;

		select public.load_log (l_in_l_seq,l_in_l_step,l_in_table_name,	coalesce ( l_row_count,0)::int,'I'::text)
			into l_in_l_step;

	end loop;

	close date_id_curs;

	l_sql:= 'update dwh.conditional_execution a
				set exec_id 	   = EXCLUDED.exec_id,
					exch_exec_id   = EXCLUDED.exch_exec_id,
					order_id 	   = EXCLUDED.order_id,
					fix_message_id = EXCLUDED.fix_message_id,
					exec_type 	   = EXCLUDED.exec_type,
					order_status   = EXCLUDED.order_status,
					exec_time 	   = EXCLUDED.exec_time,
					leaves_qty 	   = EXCLUDED.leaves_qty,
					last_mkt 	   = EXCLUDED.last_mkt,
					exec_text 	   = EXCLUDED.text_,
					is_busted 	   = EXCLUDED.is_busted,
					exchange_id    = EXCLUDED.exchange_id,
					date_id 	   = EXCLUDED.date_id,
					last_qty	   = EXCLUDED.last_qty,
					cum_qty 	   = EXCLUDED.cum_qty,
					last_px 	   = EXCLUDED.last_px,
					ref_exec_id	   = EXCLUDED.ref_exec_id
				from staging.tlnd_conditional_execution_'||in_l_seq::varchar||'  EXCLUDED
				where a.exec_id = EXCLUDED.exec_id
				and rtrim(operation) in(''U'',''UN'');';

		execute l_sql;

		get diagnostics l_row_count = row_count;

		select public.load_log(l_in_l_seq,l_in_l_step,l_in_table_name,coalesce (l_row_count,0)::int,'U'::text)
			into l_in_l_step;


		select public.load_log (l_in_l_seq,l_in_l_step,'tlnd_load_conditional_execution_sp FINISHED >>>>>>',0,'F'::text)
			into l_in_l_step;
end;
$procedure$
;


