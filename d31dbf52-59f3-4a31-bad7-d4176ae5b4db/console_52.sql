ALTER TABLE dwh.conditional_execution RENAME COLUMN text TO exec_text;
/*
-- Then fix function
select a.nspname, *
from pg_catalog.pg_proc p
inner join pg_catalog.pg_namespace a on p.pronamespace =a."oid"
where prosrc ilike '%text%'
and  prosrc ilike '%CONDITIONAL_EXECUTION%'
--and proname not like 'tlnd%'
and a.nspname not in ('trash')
and proname not like '%bkp'
and proname not like '%tst'
and proname not in ('load_temp_conditional_execution');

select * from dwh.conditional_execution


select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.data_type, parameters.ordinal_position, *
from information_schema.routines
         left join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
and routine_name !~~* all(ARRAY['%_bkp%', '%_old%', '%_tst%', '%_test%'])
and routines.routine_schema not in ('trash', 'pg_catalog', 'information_schema')
--and routines.routine_schema in ('trash', 'dash360', 'dash_reporting')
and routine_definition ilike '%text%'
and routine_definition ilike '%CONDITIONAL_EXECUTION%';
*/

-- 'dash360.order_blotter_waves_with_conditionals' -- NO
-- 'dash360.order_chain_for_order_id' -- YES
-- 'dash360.report_iex_astral_street' -- NO
-- 'dwh.reload_historic_order_cond' -- YES
-- 'eod_reports.report_iex_astral_street' -- NO
-- 'staging.get_missed_fix_messages_by_event' -- YES
-- 'staging.load_temp_conditional_execution' -- YES
-- 'staging.tlnd_load_conditional_execution_sp' -- YES
-- 'staging.tlnd_parallel_fact' -- NO



-- DROP FUNCTION dash360.order_chain_for_order_id(int8, bpchar);

create or replace function dash360.order_chain_for_order_id(in_order_id bigint, in_is_start_from_current character)
 RETURNS TABLE(exec_id bigint, orderid bigint, clordid character varying, origclordid character varying, orderclass character, customerorderid bigint, execid bigint, refexecid bigint, instrumentid bigint, symbol character varying, instrumenttype character, maturityyear smallint, maturitymonth smallint, maturityday smallint, putcall character, strikepx numeric, oprasymbol character varying, displayinstrumentid character varying, underlyingdisplayinstrid character varying, ordercreationtime timestamp without time zone, transacttime timestamp without time zone, logtime timestamp without time zone, routedtime timestamp without time zone, ordertype character, side character, orderqty integer, price numeric, stoppx numeric, timeinforce character, expiretime timestamp without time zone, openclose character, exdestination character varying, handlinst character, execinst character varying, maxshowqty integer, maxfloorqty bigint, clearingfirmid character varying, execbroker integer, customerorfirm character, ordercapacity character, marketparticipantid character varying, islocaterequired character, locatebroker character varying, exectype character, orderstatus character, rejectreason character varying, leavesqty bigint, cumqty bigint, avgpx numeric, lastqty integer, lastpx numeric, lastmkt character varying, dayorderqty bigint, daycumqty bigint, dayavgpx numeric, accountid integer, tradeliquidityindicator character varying, multilegreportingtype character, legrefid character varying, multilegorderid bigint, fixcompid character varying, clientid character varying, text character varying, isosrorder character varying, osrorderid bigint, substrategy character varying, algostoppx numeric, algoclordid character varying, transtype character, dashclordid character varying, crossorderid bigint, occoptionaldata character varying, subsystemid character varying, transactionid bigint, totnoordersintransaction bigint, exchangeid character varying, feesensitivity smallint, onbehalfofsubid character varying, strategydecisionreasoncode smallint, internalorderid bigint, algostarttime timestamp without time zone, algoendtime timestamp without time zone, mintargetqty integer, extendedordtype character, primlistingexchange character varying, postingexchange character varying, preopenbehavior character, maxwaveqtypct bigint, sweepstyle character, discretionoffset numeric, crosstype character, aggressionlevel smallint, hiddenflag character, quoteid character varying, stepuppricetype character, stepupprice numeric, crossaccountid integer, clearingaccount character varying, subaccount character varying, requestnumber integer, liquidityproviderid character varying, internalcomponenttype character, complianceid character varying, alternativecomplianceid character varying, conditionalclientorderid character varying, isconditionalorder character varying, exch_exec_id character varying)
 LANGUAGE plpgsql
 COST 1
AS $function$
#variable_conflict use_column
declare
l_date_id int;
l_start_order_id bigint;

begin
	if in_is_start_from_current <> 'Y' then
	-- Looking for min order from client_order and conditional_order
	with recursive min_hist_o (order_id, create_date_id, orig_order_id) --min order_id for client_order
	as
	(
		select order_id::bigint, create_date_id, orig_order_id
		from dwh.client_order
		where order_id = in_order_id
		union all
		select co_rec.order_id, co_rec.create_date_id, co_rec.orig_order_id
		from dwh.client_order co_rec
		inner join min_hist_o
		on min_hist_o.orig_order_id = co_rec.order_id
	)
	,
	min_hist_co (order_id, /*create_date_id, */orig_order_id) -- min order for conditional_order
	as
	(
		select order_id::bigint, /*create_date_id, */orig_order_id
		from dwh.conditional_order
		where order_id = in_order_id
		union all
		select co_rec.order_id, /*co_rec.create_date_id, */co_rec.orig_order_id
		from dwh.conditional_order co_rec
		inner join min_hist_co
		on min_hist_co.orig_order_id = co_rec.order_id
	)
	select min(order_id) into l_start_order_id
	from
	(
		select order_id from min_hist_o
		union all
		select order_id from min_hist_co
	) x;
	else
		l_start_order_id := in_order_id;
	end if;

RETURN QUERY

with recursive all_hist_o (order_id, create_date_id, orig_order_id) --for client_order
as
(
select order_id::bigint, create_date_id, orig_order_id, 1 as lev
from dwh.client_order
where order_id = l_start_order_id
union all
select co_rec.order_id, co_rec.create_date_id, co_rec.orig_order_id, all_hist_o.lev + 1 as lev
from dwh.client_order co_rec
inner join all_hist_o
on co_rec.orig_order_id = all_hist_o.order_id
)
,
all_hist_co (order_id, /*create_date_id, */orig_order_id) -- for conditional_order
as
(
select order_id::bigint, /*create_date_id, */orig_order_id, 1 as lev
from dwh.conditional_order
where order_id = l_start_order_id
union all
select co_rec.order_id, /*co_rec.create_date_id, */co_rec.orig_order_id, all_hist_co.lev + 1 as lev
from dwh.conditional_order co_rec
inner join all_hist_co
on co_rec.orig_order_id = all_hist_co.order_id
)
,
cte_cross_order as
(select * from dwh.cross_order cor
--where cor.cross_order_id in (select order_id from all_hist_o)
where cor.cross_order_id = any(string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[])
)
,
cte_algo_order_tca as
(select * from eq_tca.algo_order_tca
--where order_id in (select order_id from all_hist_o)
where order_id = any(string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[])
)
,
cte_client_order as materialized
(select * from dwh.client_order
--where order_id in (select order_id from all_hist_o)
where order_id = any(string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[])
)
SELECT
  	EX.EXEC_ID,
    CO.ORDER_ID "OrderID",
    case when EX.EXEC_TYPE in ('Y','y')
    	   then (SELECT FM.fix_message->>'11'
			     FROM fix_capture.fix_message_json FM
			     WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
			     )
			else CO.CLIENT_ORDER_ID
	end as "ClOrdID",
    case when EX.EXEC_TYPE in ('Y','y')
    	   then (SELECT FM.fix_message->>'41'
			     FROM fix_capture.fix_message_json FM
			     WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
			     )
		 when EX.EXEC_TYPE = 'D' then null
		 else COORIG.CLIENT_ORDER_ID
	end as "OrigClOrdID", -- case when EX.EXEC_TYPE = 'D' then null else COORIG.CLIENT_ORDER_ID end as "OrigClOrdID"
    CO.ORDER_CLASS "OrderClass",
    CO.PARENT_ORDER_ID "CustomerOrderID",
    EX.EXEC_ID "ExecID",
    EX.REF_EXEC_ID "RefExecID",
    CO.INSTRUMENT_ID "InstrumentID",
    HSD.SYMBOL "Symbol", --10
    HSD.InstrumentType "InstrumentType",
    HSD.MaturityYear "MaturityYear",
    HSD.MaturityMonth "MaturityMonth",
    HSD.MaturityDay "MaturityDay",
    HSD.PutCall "PutCall",
    HSD.StrikePx "StrikePx",
    HSD.OPRASymbol "OPRASymbol",
    HSD.DisplayInstrumentID "DisplayInstrumentID",
    HSD.UnderlyingDisplayInstrID "UnderlyingDisplayInstrID",
    CO.CREATE_TIME "OrderCreationTime", --20
    EX.EXEC_TIME "TransactTime",
    (SELECT FM.pg_db_create_time
    FROM fix_capture.fix_message_json FM
    WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
    ) "LogTime", --22
    CO.PROCESS_TIME "RoutedTime",
    CO.ORDER_TYPE_ID "OrderType", --24
    CO.SIDE "Side",
    CO.ORDER_QTY::int "OrderQty",
    CO.PRICE "Price",
    CO.STOP_PRICE "StopPx",
    CO.TIME_IN_FORCE_ID "TimeInForce", --29
    CO.EXPIRE_TIME "ExpireTime",
    CO.OPEN_CLOSE "OpenClose", --31
    CO.EX_DESTINATION "ExDestination",
    CO.HANDL_INST "HandlInst", --33
    CO.EXEC_INSTRUCTION "ExecInst",
    CO.MAX_SHOW_QTY::int "MaxShowQty",
    CO.MAX_FLOOR "MaxFloorQty",
    CASE
      WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CO.CLEARING_FIRM_ID
      ELSE CO.CLEARING_FIRM_ID
    END "ClearingFirmID", -- 37
--    ACC.OPT_IS_FIX_EXECBROK_PROCESSED,
    CASE
      WHEN HSD.InstrumentType = 'E'	THEN NULL
      WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y' then coalesce(CO.OPT_EXEC_BROKER_ID, OPX.OPT_EXEC_BROKER_ID)
      WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED <> 'Y' then OPX.OPT_EXEC_BROKER_ID
      ELSE CO.OPT_EXEC_BROKER_ID
    END "ExecBroker",
    --we store value in CLIENT_ORDER for all cases
    case when CO.PARENT_ORDER_ID is null then co.customer_or_firm_id else NULL end "CustomerOrFirm", --39
    CO.EQ_ORDER_CAPACITY "OrderCapacity",--40
    -- in order to display MPID used for routing, not sent by client
    case when HSD.InstrumentType = 'E' then ACC.EQ_MPID else null end "MarketParticipantID", --41
    CO.LOCATE_REQ "IsLocateRequired",
    CO.LOCATE_BROKER "LocateBroker",
    EX.EXEC_TYPE "ExecType", --44
    EX.ORDER_STATUS "OrderStatus", --45
    -- reject reason should be selected for rejects and Cancels only
    case when EX.EXEC_TYPE = '8' then EX.text_ else null end "RejectReason",
    EX.LEAVES_QTY "LeavesQty", --47
    (
    SELECT SUM(EO.LAST_QTY)
    FROM EXECUTION EO
    WHERE EO.ORDER_ID = EX.ORDER_ID
    AND EO.EXEC_TYPE IN ('F', 'G', 'D')
    AND EO.IS_BUSTED <> 'Y'
    AND EO.EXEC_ID   <= EX.EXEC_ID
    )::bigint "CumQty", --48
    (
    SELECT
      CASE
        WHEN SUM(EA.LAST_QTY) = 0
        THEN NULL
        ELSE SUM(EA.LAST_QTY*EA.LAST_PX)/(case when SUM(EA.LAST_QTY) = 0 then 1 else SUM(EA.LAST_QTY) end)
      END
    FROM EXECUTION EA
    WHERE EA.ORDER_ID = EX.ORDER_ID
    AND EA.EXEC_TYPE IN ('F', 'G', 'D')
    AND EA.IS_BUSTED <> 'Y'
    AND EA.EXEC_ID   <= EX.EXEC_ID
    ) "AvgPx", --49
    --
    EX.LAST_QTY::int "LastQty", --50
    EX.LAST_PX "LastPx", --51
    --in order to provide correct displaying of Arca ortions
    CASE
      WHEN EX.EXEC_TYPE NOT IN ('F', 'G', 'D')
      THEN NULL
      WHEN CO.PARENT_ORDER_ID IS NULL
      THEN EX.LAST_MKT
      ELSE CO.EX_DESTINATION
    END "LastMkt", --52
    CO.ORDER_QTY - EX.CUM_QTY +
( SELECT coalesce(SUM(EQ.LAST_QTY),0)
             FROM EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME,'YYYYMMDD') = to_char(EQ.EXEC_TIME,'YYYYMMDD')
)::bigint "DayOrderQty", --53
( SELECT coalesce(SUM(EQ.LAST_QTY),0)
             FROM EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME,'YYYYMMDD') = to_char(EQ.EXEC_TIME,'YYYYMMDD')
)::bigint "DayCumQty", --54
(SELECT ROUND(coalesce(SUM(EQ.LAST_QTY*EQ.LAST_PX)/(case when SUM(EQ.LAST_QTY) = 0 then 1 else SUM(EQ.LAST_QTY) end), 0), 4)
             FROM EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME,'YYYYMMDD') = to_char(EQ.EXEC_TIME,'YYYYMMDD')
) "DayAvgPx", --55
    CO.ACCOUNT_ID::int "AccountID", --56
    EX.TRADE_LIQUIDITY_INDICATOR "TradeLiquidityIndicator", --57
    CO.MULTILEG_REPORTING_TYPE "MultilegReportingType", --58
--    COL.CLIENT_LEG_REF_ID "LegRefID", --59
--    COL.MULTILEG_ORDER_ID "MultilegOrderID", --60
    CO.co_client_leg_ref_id "LegRefID", --59
    CO.MULTILEG_ORDER_ID "MultilegOrderID", --60
    FC.FIX_COMP_ID "FixCompID", --sending firm
	CO.CLIENT_ID_TEXT "ClientID",  --62
    EX.TEXT_ "Text", --63
    CASE
      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
      THEN 'Y'::varchar
      ELSE 'N'::varchar
    END "IsOSROrder", --64
    coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) "OSROrderID", --65
    CO.SUB_STRATEGY_DESC "SubStrategy", --66
    CO.ALGO_STOP_PX "AlgoStopPx",
    CO.ALGO_CLIENT_ORDER_ID "AlgoClOrdID", --68
    CO.TRANS_TYPE "TransType", --69
    CO.DASH_CLIENT_ORDER_ID "DashClOrdID",
    CO.CROSS_ORDER_ID "CrossOrderID",
    CO.OCC_OPTIONAL_DATA "OCCOptionalData",
    CO.SUB_STRATEGY_DESC "SubSystemID",
    CO.TRANSACTION_ID "TransactionID",
    CO.TOT_NO_ORDERS_IN_TRANSACTION "TotNoOrdersInTransaction", --75
    CO.EXCHANGE_ID "ExchangeID", --76
    CO.FEE_SENSITIVITY "FeeSensitivity", --77
    CO.ON_BEHALF_OF_SUB_ID "OnBehalfOfSubID", --78
    CO.strtg_decision_reason_code "StrategyDecisionReasonCode", --79
    CO.INTERNAL_ORDER_ID "InternalOrderID", --80
    CO.ALGO_START_TIME "AlgoStartTime", --81
    CO.ALGO_END_TIME "AlgoEndTime",  --82
    al.MIN_TARGET_QTY::int "MinTargetQty", --83
    CO.extended_ord_type "ExtendedOrdType", --84
    CO.PRIM_LISTING_EXCHANGE "PrimListingExchange", --85
    CO.POSTING_EXCHANGE "PostingExchange", --86
    CO.PRE_OPEN_BEHAVIOR "PreOpenBehavior", --87
    CO.MAX_WAVE_QTY_PCT "MaxWaveQtyPct", --88
    CO.SWEEP_STYLE "SweepStyle", --89
    CO.DISCRETION_OFFSET "DiscretionOffset", --90
    CRO.CROSS_TYPE "CrossType", --91
    CO.AGGRESSION_LEVEL "AggressionLevel", --92
    CO.HIDDEN_FLAG "HiddenFlag", --93
    CO.QUOTE_ID "QuoteID",
    CO.STEP_UP_PRICE_TYPE "StepUpPriceType", --95
    CO.STEP_UP_PRICE "StepUpPrice",
    CO.CROSS_ACCOUNT_ID::int4 "CrossAccountID",
    CO.CLEARING_ACCOUNT "ClearingAccount", --98
    CO.SUB_ACCOUNT "SubAccount",
    CO.REQUEST_NUMBER "RequestNumber", --100
    CO.LIQUIDITY_PROVIDER_ID "LiquidityProviderID",
    CO.INTERNAL_COMPONENT_TYPE "InternalComponentType", --102
    CO.COMPLIANCE_ID "ComplianceID",
    CO.ALTERNATIVE_COMPLIANCE_ID "AlternativeComplianceID",
    CO.CONDITIONAL_CLIENT_ORDER_ID::varchar "ConditionalClientOrderID",
    'N'::varchar "IsConditionalOrder", --106
	EX.exch_exec_id as "ExchExecID"
FROM dwh.EXECUTION EX
  JOIN cte_client_order CO ON (EX.ORDER_ID = CO.ORDER_ID )
  JOIN
  (
    SELECT
		I.INSTRUMENT_ID InstrumentID,
		I.SYMBOL Symbol,
		I.INSTRUMENT_TYPE_ID InstrumentType,
		U.SYMBOL UnderlyingSymbol,
		OC.MATURITY_YEAR MaturityYear,
		OC.MATURITY_MONTH MaturityMonth,
		OC.MATURITY_DAY MaturityDay,
		OC.PUT_CALL PutCall,
		OC.STRIKE_PRICE StrikePx,
		OC.OPRA_SYMBOL OPRASymbol,
		OS.CONTRACT_MULTIPLIER ContractMultiplier,
		I.INSTRUMENT_NAME InstrumentName,
		I.DISPLAY_INSTRUMENT_ID DisplayInstrumentID,
		U.DISPLAY_INSTRUMENT_ID UnderlyingDisplayInstrID
		--select *
		FROM dwh.d_INSTRUMENT I
		LEFT JOIN dwh.d_OPTION_CONTRACT OC on (I.INSTRUMENT_ID = OC.INSTRUMENT_ID)
		LEFT JOIN dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
		LEFT JOIN dwh.d_INSTRUMENT U ON (OS.UNDERLYING_INSTRUMENT_ID = U.INSTRUMENT_ID)
		WHERE I.INSTRUMENT_TYPE_ID IN ('E','O','M')
		--AND I.is_active
  ) HSD ON (HSD.INSTRUMENTID = CO.INSTRUMENT_ID)
  JOIN dwh.d_FIX_CONNECTION FC ON (FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID)
  JOIN dwh.d_ACCOUNT ACC ON (CO.ACCOUNT_ID = ACC.ACCOUNT_ID)
  LEFT JOIN d_OPT_EXEC_BROKER OPX ON (OPX.ACCOUNT_ID  = ACC.ACCOUNT_ID AND OPX.is_active AND OPX.IS_DEFAULT  = 'Y')
  LEFT JOIN cte_client_order COORIG ON (CO.ORIG_ORDER_ID = COORIG.ORDER_ID)
  LEFT JOIN dwh.CLIENT_ORDER_LEG COL ON (CO.ORDER_ID = COL.ORDER_ID)
  LEFT JOIN cte_cross_order CRO ON CO.CROSS_ORDER_ID = CRO.CROSS_ORDER_ID
  left join cte_algo_order_tca al on al.order_id = co.order_id
  WHERE 1=1
  --and EX.ORDER_STATUS <> '3'
  --AND CO.MULTILEG_REPORTING_TYPE IN ('1','2')
  AND co.order_id = any(string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[])
  AND co.create_date_id = any(string_to_array((select string_agg(create_date_id::text, ',') from all_hist_o), ',')::int[])


  union all

  SELECT
    EX.EXEC_ID, --1
    CO.ORDER_ID "OrderID", --2
    case when EX.EXEC_TYPE in ('Y','y')
    	   then (SELECT FM.fix_message->>'11'
			     FROM fix_capture.fix_message_json FM
			     WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
			     )
			else CO.CLIENT_ORDER_ID
	end as "ClOrdID",
    case when EX.EXEC_TYPE in ('Y','y')
    	   then (SELECT FM.fix_message->>'41'
			     FROM fix_capture.fix_message_json FM
			     WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
			     )
		 when EX.EXEC_TYPE = 'D' then null
		 else COORIG.CLIENT_ORDER_ID
	end as "OrigClOrdID", --case when EX.EXEC_TYPE = 'D' then null else COORIG.CLIENT_ORDER_ID end as "OrigClOrdID"
    CO.ORDER_CLASS "OrderClass",
    CO.PARENT_ORDER_ID "CustomerOrderID",
    EX.EXEC_ID "ExecID",
    EX.REF_EXEC_ID "RefExecID", --8
    CO.INSTRUMENT_ID "InstrumentID", --9
    HSD.SYMBOL "Symbol", --10
    HSD.InstrumentType "InstrumentType",
    HSD.MaturityYear "MaturityYear",
    HSD.MaturityMonth "MaturityMonth",
    HSD.MaturityDay "MaturityDay",
    HSD.PutCall "PutCall", --15
    HSD.StrikePx "StrikePx",
    HSD.OPRASymbol "OPRASymbol",
    HSD.DisplayInstrumentID "DisplayInstrumentID",
    HSD.UnderlyingDisplayInstrID "UnderlyingDisplayInstrID",
    CO.CREATE_TIME "OrderCreationTime", --20
    EX.EXEC_TIME "TransactTime", --21
    (SELECT FM.pg_db_create_time
    FROM fix_capture.fix_message_json FM
    WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
    ) "LogTime", --22
    CO.PROCESS_TIME "RoutedTime", --23
    CO.ORDER_TYPE "OrderType",
    CO.SIDE "Side", --25
    CO.ORDER_QTY::int "OrderQty",
    CO.PRICE "Price",
    null "StopPx",
    CO.TIME_IN_FORCE "TimeInForce",
    CO.EXPIRE_TIME "ExpireTime", --30
    CO.OPEN_CLOSE "OpenClose",
    CO.EX_DESTINATION "ExDestination",
    CO.HANDL_INST "HandlInst",
    CO.EXEC_INST "ExecInst",
    CO.MAX_SHOW_QTY::int "MaxShowQty", --35
    CO.MAX_FLOOR "MaxFloorQty",
    null "ClearingFirmID",
    null "ExecBroker",
    null "CustomerOrFirm", --39
    CO.EQ_ORDER_CAPACITY "OrderCapacity", --40
    -- in order to display MPID used for routing, not sent by client
    case when HSD.InstrumentType = 'E' then ACC.EQ_MPID else null end "MarketParticipantID", --41
    CO.LOCATE_REQ "IsLocateRequired",
    CO.LOCATE_BROKER "LocateBroker",
    EX.EXEC_TYPE "ExecType",
    EX.ORDER_STATUS "OrderStatus", --45
    -- reject reason should be selected for rejects and Cancels only
    case when EX.EXEC_TYPE = '8' then EX.exec_text else null end "RejectReason", --46
    EX.LEAVES_QTY "LeavesQty", --47
    --EX.CUM_QTY "CumQty",
    (
    SELECT SUM(EO.LAST_QTY)
    FROM CONDITIONAL_EXECUTION EO
    WHERE EO.ORDER_ID = EX.ORDER_ID
    AND EO.EXEC_TYPE IN ('F', 'G', 'D')
    AND EO.IS_BUSTED <> 'Y'
    AND EO.EXEC_ID   <= EX.EXEC_ID
    )::bigint "CumQty", --48
    --EX.AVG_PX "AvgPx",
    (
    SELECT
      CASE
        WHEN SUM(EA.LAST_QTY) = 0
        THEN NULL
        ELSE SUM(EA.LAST_QTY*EA.LAST_PX)/(case when SUM(EA.LAST_QTY) = 0 then 1 else SUM(EA.LAST_QTY) end)
      END
    FROM CONDITIONAL_EXECUTION EA
    WHERE EA.ORDER_ID = EX.ORDER_ID
    AND EA.EXEC_TYPE IN ('F', 'G', 'D')
    AND EA.IS_BUSTED <> 'Y'
    AND EA.EXEC_ID   <= EX.EXEC_ID
    ) "AvgPx", --49
    --
    EX.LAST_QTY::int "LastQty", --50
    EX.LAST_PX "LastPx", --51
    --in order to provide correct displaying of Arca ortions
    CASE
      WHEN EX.EXEC_TYPE NOT IN ('F', 'G', 'D')
      THEN NULL
      WHEN CO.PARENT_ORDER_ID IS NULL
      THEN EX.LAST_MKT
      ELSE CO.EX_DESTINATION
    END "LastMkt", --52
    CO.ORDER_QTY - EX.CUM_QTY +
( SELECT coalesce(SUM(EQ.LAST_QTY),0)
             FROM CONDITIONAL_EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME,'YYYYMMDD') = to_char(EQ.EXEC_TIME,'YYYYMMDD')
)::bigint "DayOrderQty", --53
( SELECT coalesce(SUM(EQ.LAST_QTY),0)
             FROM CONDITIONAL_EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME,'YYYYMMDD') = to_char(EQ.EXEC_TIME,'YYYYMMDD')
)::bigint "DayCumQty", --54
(
SELECT ROUND(coalesce(SUM(EQ.LAST_QTY*EQ.LAST_PX)/(case when SUM(EQ.LAST_QTY) = 0 then 1 else SUM(EQ.LAST_QTY) end), 0), 4)
             FROM CONDITIONAL_EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME,'YYYYMMDD') = to_char(EQ.EXEC_TIME,'YYYYMMDD')
) "DayAvgPx", --55
    CO.ACCOUNT_ID::int "AccountID",
    null "TradeLiquidityIndicator",
    '1' "MultilegReportingType",
    null "LegRefID",
    null "MultilegOrderID", --60
    FC.FIX_COMP_ID "FixCompID", --sending firm
    CO.CLIENT_ID_TEXT "ClientID", --62
    EX.exec_text "Text", --63
    CASE
      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
      THEN 'Y'
      ELSE 'N'
    END "IsOSROrder", --64
    coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) "OSROrderID", --65
    CO.SUB_STRATEGY "SubStrategy",  --66
    null "AlgoStopPx",
    CO.ALGO_CLIENT_ORDER_ID "AlgoClOrdID",
    CO.TRANS_TYPE "TransType",
    null "DashClOrdID",  --70
    null "CrossOrderID",
    CO.OCC_OPTIONAL_DATA "OCCOptionalData",
    CO.SUB_SYSTEM_ID "SubSystemID",
    CO.TRANSACTION_ID "TransactionID",
    null "TotNoOrdersInTransaction", --75
    CO.EXCHANGE_ID "ExchangeID",
    null "FeeSensitivity",
    null "OnBehalfOfSubID",
    CO.STRATEGY_DECISION_REASON_CODE "StrategyDecisionReasonCode",
    null "InternalOrderID", --80
    CO.ALGO_START_TIME "AlgoStartTime",
    CO.ALGO_END_TIME "AlgoEndTime",
    CO.MIN_TARGET_QTY::int "MinTargetQty",
    null "ExtendedOrdType",
    null "PrimListingExchange", --85
    null "PostingExchange",
    null "PreOpenBehavior",
    null "MaxWaveQtyPct",
    null "SweepStyle",
    CO.DISCRETION_OFFSET "DiscretionOffset", --90
    null "CrossType",
    null "AggressionLevel",
    null "HiddenFlag",
    null "QuoteID",
    null "StepUpPriceType", --95
    null "StepUpPrice",
    null "CrossAccountID",
    null "ClearingAccount",
    CO.CO_SUB_ACCOUNT "SubAccount",
    null "RequestNumber", --100
    CO.LIQUIDITY_PROVIDER_ID "LiquidityProviderID",
    CO.INTERNAL_COMPONENT_TYPE "InternalComponentType",
    null "ComplianceID",
    null "AlternativeComplianceID",
    null "ConditionalClientOrderID", --105
    'Y' "IsConditionalOrder",
	ex.exch_exec_id as "ExchExecID"
  FROM dwh.CONDITIONAL_EXECUTION EX
  JOIN dwh.CONDITIONAL_ORDER CO ON EX.ORDER_ID = CO.ORDER_ID
  JOIN
  (
    SELECT
		I.INSTRUMENT_ID InstrumentID,
		I.SYMBOL Symbol,
		I.INSTRUMENT_TYPE_ID InstrumentType,
		U.SYMBOL UnderlyingSymbol,
		OC.MATURITY_YEAR MaturityYear,
		OC.MATURITY_MONTH MaturityMonth,
		OC.MATURITY_DAY MaturityDay,
		OC.PUT_CALL PutCall,
		OC.STRIKE_PRICE StrikePx,
		OC.OPRA_SYMBOL OPRASymbol,
		OS.CONTRACT_MULTIPLIER ContractMultiplier,
		I.INSTRUMENT_NAME InstrumentName,
		I.DISPLAY_INSTRUMENT_ID DisplayInstrumentID,
		U.DISPLAY_INSTRUMENT_ID UnderlyingDisplayInstrID
		FROM dwh.d_INSTRUMENT I
		LEFT JOIN dwh.d_OPTION_CONTRACT OC on (I.INSTRUMENT_ID = OC.INSTRUMENT_ID)
		LEFT JOIN dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
		LEFT JOIN dwh.d_INSTRUMENT U ON (OS.UNDERLYING_INSTRUMENT_ID = U.INSTRUMENT_ID)
		WHERE I.INSTRUMENT_TYPE_ID IN ('E','O','M')
		--AND I.is_active
  ) HSD ON HSD.INSTRUMENTID = CO.INSTRUMENT_ID
  JOIN dwh.d_fix_connection FC ON FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID
  JOIN dwh.d_account ACC ON CO.ACCOUNT_ID = ACC.ACCOUNT_ID
  LEFT JOIN dwh.CLIENT_ORDER COORIG ON CO.ORIG_ORDER_ID = COORIG.ORDER_ID
  WHERE 1=1
  --and EX.ORDER_STATUS <> '3'
AND co.order_id = any(string_to_array((select string_agg(order_id::text, ',') from all_hist_co), ',')::bigint[])
order by exec_id;


end;
$function$
;




create or replace function dwh.reload_historic_order_cond(in_date_id integer, in_order_ids_arr bigint[] default null::bigint[])
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- PD: 20240125 https://dashfinancial.atlassian.net/browse/DS-7780 added new Optwap columns
-- PD: 20240126 https://dashfinancial.atlassian.net/browse/DS-7891 changed MultilegReportingType column

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
	   EX.exec_time::date as "TradeDate"--,
--	   CO.optwap_bin_number as "OptwapBinNumber",
--	   CO.optwap_phase as "OptwapPhase",
--	   CO.optwap_order_price as "OptwapOrderPrice",
--	   CO.optwap_bin_duration as "OptwapBinDuration",
--	   CO.optwap_bin_qty as "OptwapBinQty",
--	   CO.optwap_phase_duration as "OptwapPhaseDuration"
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
	    "StatusDate","Status_Date_id"/*, "OptwapBinNumber", "OptwapPhase", "OptwapOrderPrice", "OptwapBinDuration", "OptwapBinQty", "OptwapPhaseDuration"*/)
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
			'1' as "MultilegReportingType",
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
			in_date_id as "Status_Date_id"/*,
			HCOD."OptwapBinNumber",
			HCOD."OptwapPhase",
			HCOD."OptwapOrderPrice",
			HCOD."OptwapBinDuration",
			HCOD."OptwapBinQty",
			HCOD."OptwapPhaseDuration" */
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


create or replace function staging.get_missed_fix_messages_by_event(in_date_id integer default public.get_dateid(get_business_date()))
 RETURNS TABLE(table_name text, order_id bigint, exec_id bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
#variable_conflict use_column
begin
return query
with eos_ss as (select sub_system_unq_id from
				dwh.d_sub_system dss
				where  dss.sub_system_id like 'EOS%' or dss.sub_system_id like 'HFT%'
				)
select 'client_order', order_id, null::bigint as exec_id
from dwh.client_order co
where not exists (select null from eos_ss where eos_ss.sub_system_unq_id = co.sub_system_unq_id)
  and not  sub_system_unq_id = 0 --== this is to exclude Trade Desk's manual ones
  and create_date_id =in_date_id
  and fix_message_id is null
union all
select 'conditional_order', order_id, null::bigint as exec_id
from dwh.conditional_order co
where --to_char(create_time, 'YYYYMMDD')::int =in_date_id
	date_id = in_date_id
  and fix_message_id is null
union all
select 'execution', e.order_id, e.exec_id
from dwh.execution e
join lateral (select order_id from dwh.client_order co
				where co.order_id = e.order_id
				and not co.ex_destination = 'LIQPT'
				and co.create_date_id = e.exec_date_id
				limit 1
			) coe on true
where exec_date_id =in_date_id
  and (e.text_ not like 'SYNTH%' or e.text_ like 'SYNTHETIC CANCEL%' or e.text_ like 'SYNTHETIC REPLACE%')
  and e.fix_message_id is null
union all
select 'execution', e.order_id, e.exec_id
from dwh.execution e
join lateral (select 1
              from dwh.gtc_order_status gos
                inner join lateral (select 1 from dwh.client_order co where  gos.order_id = co.order_id and gos.create_date_id = co.create_date_id and not co.ex_destination = 'LIQPT' limit 1) c on true
				where gos.order_id = e.order_id
				limit 1
			) gte on true
where exec_date_id =in_date_id
and (e.text_ not like 'SYNTH%' or e.text_ like 'SYNTHETIC CANCEL%' or e.text_ like 'SYNTHETIC REPLACE%')
and fix_message_id is null
union all
select 'conditional_execution', e.order_id, e.exec_id
from dwh.conditional_execution e
join lateral (select order_id
			  from dwh.conditional_order co
				where co.order_id = e.order_id
				and not co.ex_destination = 'LIQPT'
				--and co.create_time::date = e.exec_time::date
				and co.date_id = e.date_id
				limit 1
			) coe on true
where to_char(exec_time, 'YYYYMMDD')::int =in_date_id
and (e.exec_text not like 'SYNTH%' or e.exec_text like 'SYNTHETIC CANCEL%' or e.exec_text like 'SYNTHETIC REPLACE%')
and e.fix_message_id is null;
end;
$function$
;

-- DROP PROCEDURE staging.tlnd_load_conditional_execution_sp(int4, int4, varchar);

create or replace procedure staging.tlnd_load_conditional_execution_sp(in in_l_seq integer, in in_l_step integer, in in_l_table_name character varying)
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
