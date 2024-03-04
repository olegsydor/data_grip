-- DROP FUNCTION dash360.order_chain_for_order_id(int8, bpchar);

create function trash.so_order_chain_for_order_id(in_order_id bigint, in_is_start_from_current character)
    returns table
            (
                exec_id                    bigint,
                orderid                    bigint,
                clordid                    character varying,
                origclordid                character varying,
                orderclass                 character,
                customerorderid            bigint,
                execid                     bigint,
                refexecid                  bigint,
                instrumentid               bigint,
                symbol                     character varying,
                instrumenttype             character,
                maturityyear               smallint,
                maturitymonth              smallint,
                maturityday                smallint,
                putcall                    character,
                strikepx                   numeric,
                oprasymbol                 character varying,
                displayinstrumentid        character varying,
                underlyingdisplayinstrid   character varying,
                ordercreationtime          timestamp without time zone,
                transacttime               timestamp without time zone,
                logtime                    timestamp without time zone,
                routedtime                 timestamp without time zone,
                ordertype                  character,
                side                       character,
                orderqty                   integer,
                price                      numeric,
                stoppx                     numeric,
                timeinforce                character,
                expiretime                 timestamp without time zone,
                openclose                  character,
                exdestination              character varying,
                handlinst                  character,
                execinst                   character varying,
                maxshowqty                 integer,
                maxfloorqty                bigint,
                clearingfirmid             character varying,
                execbroker                 integer,
                customerorfirm             character,
                ordercapacity              character,
                marketparticipantid        character varying,
                islocaterequired           character,
                locatebroker               character varying,
                exectype                   character,
                orderstatus                character,
                rejectreason               character varying,
                leavesqty                  bigint,
                cumqty                     bigint,
                avgpx                      numeric,
                lastqty                    integer,
                lastpx                     numeric,
                lastmkt                    character varying,
                dayorderqty                bigint,
                daycumqty                  bigint,
                dayavgpx                   numeric,
                accountid                  integer,
                tradeliquidityindicator    character varying,
                multilegreportingtype      character,
                legrefid                   character varying,
                multilegorderid            bigint,
                fixcompid                  character varying,
                clientid                   character varying,
                text                       character varying,
                isosrorder                 character varying,
                osrorderid                 bigint,
                substrategy                character varying,
                algostoppx                 numeric,
                algoclordid                character varying,
                transtype                  character,
                dashclordid                character varying,
                crossorderid               bigint,
                occoptionaldata            character varying,
                subsystemid                character varying,
                transactionid              bigint,
                totnoordersintransaction   bigint,
                exchangeid                 character varying,
                feesensitivity             smallint,
                onbehalfofsubid            character varying,
                strategydecisionreasoncode smallint,
                internalorderid            bigint,
                algostarttime              timestamp without time zone,
                algoendtime                timestamp without time zone,
                mintargetqty               integer,
                extendedordtype            character,
                primlistingexchange        character varying,
                postingexchange            character varying,
                preopenbehavior            character,
                maxwaveqtypct              bigint,
                sweepstyle                 character,
                discretionoffset           numeric,
                crosstype                  character,
                aggressionlevel            smallint,
                hiddenflag                 character,
                quoteid                    character varying,
                stepuppricetype            character,
                stepupprice                numeric,
                crossaccountid             integer,
                clearingaccount            character varying,
                subaccount                 character varying,
                requestnumber              integer,
                liquidityproviderid        character varying,
                internalcomponenttype      character,
                complianceid               character varying,
                alternativecomplianceid    character varying,
                conditionalclientorderid   character varying,
                isconditionalorder         character varying,
                exch_exec_id               character varying
            )
    language plpgsql
    cost 1
as
$function$

declare
l_start_order_id bigint;

begin
    if ((in_is_start_from_current <> 'Y' and
         exists (select null from dwh.client_order where order_id = :in_order_id and orig_order_id is null)) or
        in_is_start_from_current = 'Y') then
        l_start_order_id = in_order_id;
    else
        -- Looking for min order from client_order and conditional_order
        with recursive min_hist_o (order_id, create_date_id, orig_order_id) --min order_id for client_order
            as
            (select order_id::bigint, create_date_id, orig_order_id
             from dwh.client_order
             where true
--                and orig_order_id is not null
               and order_id = :in_order_id
             union all
             select co_rec.order_id, co_rec.create_date_id, co_rec.orig_order_id
             from dwh.client_order co_rec
                      inner join min_hist_o
                                 on min_hist_o.orig_order_id = co_rec.order_id
                                     and co_rec.create_date_id <= min_hist_o.create_date_id)
            select * from min_hist_o
           , min_hist_co (order_id, /*create_date_id, */orig_order_id) -- min order for conditional_order
            as
            (select order_id::bigint, /*create_date_id, */orig_order_id
             from dwh.conditional_order
             where order_id = :in_order_id
             union all
             select co_rec.order_id, /*co_rec.create_date_id, */co_rec.orig_order_id
             from dwh.conditional_order co_rec
                      inner join min_hist_co
                                 on min_hist_co.orig_order_id = co_rec.order_id)
--         select min(order_id)
--         into l_start_order_id
--         from (
        select order_id
              from min_hist_o
              union all
              select order_id
              from min_hist_co
--             ) x;
    end if;

RETURN QUERY
    with recursive
        all_hist_o (order_id, create_date_id, orig_order_id) --for client_order
            as
            (select order_id::bigint, create_date_id, orig_order_id, 1 as lev
             from dwh.client_order
             where order_id = :l_start_order_id
             union all
             select co_rec.order_id, co_rec.create_date_id, co_rec.orig_order_id, all_hist_o.lev + 1 as lev
             from dwh.client_order co_rec
                      inner join all_hist_o
                                 on co_rec.orig_order_id = all_hist_o.order_id)
            ,
        all_hist_co (order_id, /*create_date_id, */orig_order_id) -- for conditional_order
            as
            (select order_id::bigint, /*create_date_id, */orig_order_id, 1 as lev
             from dwh.conditional_order
             where order_id = :l_start_order_id
             union all
             select co_rec.order_id, /*co_rec.create_date_id, */co_rec.orig_order_id, all_hist_co.lev + 1 as lev
             from dwh.conditional_order co_rec
                      inner join all_hist_co
                                 on co_rec.orig_order_id = all_hist_co.order_id)
            ,
        cte_cross_order as
            (select *
             from dwh.cross_order cor
--where cor.cross_order_id in (select order_id from all_hist_o)
             where cor.cross_order_id = any
                   (string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[]))
            ,
        cte_algo_order_tca as
            (select *
             from eq_tca.algo_order_tca
--where order_id in (select order_id from all_hist_o)
             where order_id = any
                   (string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[]))
            ,
        cte_client_order as materialized
            (select *
             from dwh.client_order
--where order_id in (select order_id from all_hist_o)
             where order_id = any
                   (string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[]))
    select *
    from all_hist_o


    SELECT EX.EXEC_ID,
           CO.ORDER_ID                                                                           "OrderID",
           case
               when EX.EXEC_TYPE in ('Y', 'y')
                   then (SELECT FM.fix_message ->> '11'
                         FROM fix_capture.fix_message_json FM
                         WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID)
               else CO.CLIENT_ORDER_ID
               end         as                                                                    "ClOrdID",
           case
               when EX.EXEC_TYPE in ('Y', 'y')
                   then (SELECT FM.fix_message ->> '41'
                         FROM fix_capture.fix_message_json FM
                         WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID)
               when EX.EXEC_TYPE = 'D' then null
               else COORIG.CLIENT_ORDER_ID
               end         as                                                                    "OrigClOrdID",                -- case when EX.EXEC_TYPE = 'D' then null else COORIG.CLIENT_ORDER_ID end as "OrigClOrdID"
           CO.ORDER_CLASS                                                                        "OrderClass",
           CO.PARENT_ORDER_ID                                                                    "CustomerOrderID",
           EX.EXEC_ID                                                                            "ExecID",
           EX.REF_EXEC_ID                                                                        "RefExecID",
           CO.INSTRUMENT_ID                                                                      "InstrumentID",
           HSD.SYMBOL                                                                            "Symbol",                     --10
           HSD.InstrumentType                                                                    "InstrumentType",
           HSD.MaturityYear                                                                      "MaturityYear",
           HSD.MaturityMonth                                                                     "MaturityMonth",
           HSD.MaturityDay                                                                       "MaturityDay",
           HSD.PutCall                                                                           "PutCall",
           HSD.StrikePx                                                                          "StrikePx",
           HSD.OPRASymbol                                                                        "OPRASymbol",
           HSD.DisplayInstrumentID                                                               "DisplayInstrumentID",
           HSD.UnderlyingDisplayInstrID                                                          "UnderlyingDisplayInstrID",
           CO.CREATE_TIME                                                                        "OrderCreationTime",          --20
           EX.EXEC_TIME                                                                          "TransactTime",
           (SELECT FM.pg_db_create_time
            FROM fix_capture.fix_message_json FM
            WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID)                                         "LogTime",                    --22
           CO.PROCESS_TIME                                                                       "RoutedTime",
           CO.ORDER_TYPE_ID                                                                      "OrderType",                  --24
           CO.SIDE                                                                               "Side",
           CO.ORDER_QTY::int                                                                     "OrderQty",
           CO.PRICE                                                                              "Price",
           CO.STOP_PRICE                                                                         "StopPx",
           CO.TIME_IN_FORCE_ID                                                                   "TimeInForce",                --29
           CO.EXPIRE_TIME                                                                        "ExpireTime",
           CO.OPEN_CLOSE                                                                         "OpenClose",                  --31
           CO.EX_DESTINATION                                                                     "ExDestination",
           CO.HANDL_INST                                                                         "HandlInst",                  --33
           CO.EXEC_INSTRUCTION                                                                   "ExecInst",
           CO.MAX_SHOW_QTY::int                                                                  "MaxShowQty",
           CO.MAX_FLOOR                                                                          "MaxFloorQty",
           CASE
               WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CO.CLEARING_FIRM_ID
               ELSE CO.CLEARING_FIRM_ID
               END                                                                               "ClearingFirmID",             -- 37
--    ACC.OPT_IS_FIX_EXECBROK_PROCESSED,
           CASE
               WHEN HSD.InstrumentType = 'E' THEN NULL
               WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
                   then coalesce(CO.OPT_EXEC_BROKER_ID, OPX.OPT_EXEC_BROKER_ID)
               WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED <> 'Y' then OPX.OPT_EXEC_BROKER_ID
               ELSE CO.OPT_EXEC_BROKER_ID
               END                                                                               "ExecBroker",
           --we store value in CLIENT_ORDER for all cases
           case when CO.PARENT_ORDER_ID is null then co.customer_or_firm_id else NULL end        "CustomerOrFirm",             --39
           CO.EQ_ORDER_CAPACITY                                                                  "OrderCapacity",--40
           -- in order to display MPID used for routing, not sent by client
           case when HSD.InstrumentType = 'E' then ACC.EQ_MPID else null end                     "MarketParticipantID",        --41
           CO.LOCATE_REQ                                                                         "IsLocateRequired",
           CO.LOCATE_BROKER                                                                      "LocateBroker",
           EX.EXEC_TYPE                                                                          "ExecType",                   --44
           EX.ORDER_STATUS                                                                       "OrderStatus",                --45
           -- reject reason should be selected for rejects and Cancels only
           case when EX.EXEC_TYPE = '8' then EX.text_ else null end                              "RejectReason",
           EX.LEAVES_QTY                                                                         "LeavesQty",                  --47
           (SELECT SUM(EO.LAST_QTY)
            FROM EXECUTION EO
            WHERE EO.ORDER_ID = EX.ORDER_ID
              AND EO.EXEC_TYPE IN ('F', 'G', 'D')
              AND EO.IS_BUSTED <> 'Y'
              AND EO.EXEC_ID <= EX.EXEC_ID)::bigint                                              "CumQty",                     --48
           (SELECT CASE
                       WHEN SUM(EA.LAST_QTY) = 0
                           THEN NULL
                       ELSE SUM(EA.LAST_QTY * EA.LAST_PX) /
                            (case when SUM(EA.LAST_QTY) = 0 then 1 else SUM(EA.LAST_QTY) end)
                       END
            FROM EXECUTION EA
            WHERE EA.ORDER_ID = EX.ORDER_ID
              AND EA.EXEC_TYPE IN ('F', 'G', 'D')
              AND EA.IS_BUSTED <> 'Y'
              AND EA.EXEC_ID <= EX.EXEC_ID)                                                      "AvgPx",                      --49
           --
           EX.LAST_QTY::int                                                                      "LastQty",                    --50
           EX.LAST_PX                                                                            "LastPx",                     --51
           --in order to provide correct displaying of Arca ortions
           CASE
               WHEN EX.EXEC_TYPE NOT IN ('F', 'G', 'D')
                   THEN NULL
               WHEN CO.PARENT_ORDER_ID IS NULL
                   THEN EX.LAST_MKT
               ELSE CO.EX_DESTINATION
               END                                                                               "LastMkt",                    --52
           CO.ORDER_QTY - EX.CUM_QTY +
           (SELECT coalesce(SUM(EQ.LAST_QTY), 0)
            FROM EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME, 'YYYYMMDD') = to_char(EQ.EXEC_TIME, 'YYYYMMDD'))::bigint "DayOrderQty",                --53
           (SELECT coalesce(SUM(EQ.LAST_QTY), 0)
            FROM EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME, 'YYYYMMDD') = to_char(EQ.EXEC_TIME, 'YYYYMMDD'))::bigint "DayCumQty",                  --54
           (SELECT ROUND(coalesce(SUM(EQ.LAST_QTY * EQ.LAST_PX) /
                                  (case when SUM(EQ.LAST_QTY) = 0 then 1 else SUM(EQ.LAST_QTY) end), 0), 4)
            FROM EXECUTION EQ
            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
              AND EQ.IS_BUSTED <> 'Y'
              AND EQ.ORDER_ID = CO.ORDER_ID
              AND to_char(EX.EXEC_TIME, 'YYYYMMDD') = to_char(EQ.EXEC_TIME, 'YYYYMMDD'))         "DayAvgPx",                   --55
           CO.ACCOUNT_ID::int                                                                    "AccountID",                  --56
           EX.TRADE_LIQUIDITY_INDICATOR                                                          "TradeLiquidityIndicator",    --57
           CO.MULTILEG_REPORTING_TYPE                                                            "MultilegReportingType",      --58
--    COL.CLIENT_LEG_REF_ID "LegRefID", --59
--    COL.MULTILEG_ORDER_ID "MultilegOrderID", --60
           CO.co_client_leg_ref_id                                                               "LegRefID",                   --59
           CO.MULTILEG_ORDER_ID                                                                  "MultilegOrderID",            --60
           FC.FIX_COMP_ID                                                                        "FixCompID",                  --sending firm
           CO.CLIENT_ID_TEXT                                                                     "ClientID",                   --62
           EX.TEXT_                                                                              "Text",                       --63
           CASE
               WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
                   THEN 'Y'::varchar
               ELSE 'N'::varchar
               END                                                                               "IsOSROrder",                 --64
           coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID)                            "OSROrderID",                 --65
           CO.SUB_STRATEGY_DESC                                                                  "SubStrategy",                --66
           CO.ALGO_STOP_PX                                                                       "AlgoStopPx",
           CO.ALGO_CLIENT_ORDER_ID                                                               "AlgoClOrdID",                --68
           CO.TRANS_TYPE                                                                         "TransType",                  --69
           CO.DASH_CLIENT_ORDER_ID                                                               "DashClOrdID",
           CO.CROSS_ORDER_ID                                                                     "CrossOrderID",
           CO.OCC_OPTIONAL_DATA                                                                  "OCCOptionalData",
           CO.SUB_STRATEGY_DESC                                                                  "SubSystemID",
           CO.TRANSACTION_ID                                                                     "TransactionID",
           CO.TOT_NO_ORDERS_IN_TRANSACTION                                                       "TotNoOrdersInTransaction",   --75
           CO.EXCHANGE_ID                                                                        "ExchangeID",                 --76
           CO.FEE_SENSITIVITY                                                                    "FeeSensitivity",             --77
           CO.ON_BEHALF_OF_SUB_ID                                                                "OnBehalfOfSubID",            --78
           CO.strtg_decision_reason_code                                                         "StrategyDecisionReasonCode", --79
           CO.INTERNAL_ORDER_ID                                                                  "InternalOrderID",            --80
           CO.ALGO_START_TIME                                                                    "AlgoStartTime",              --81
           CO.ALGO_END_TIME                                                                      "AlgoEndTime",                --82
           al.MIN_TARGET_QTY::int                                                                "MinTargetQty",               --83
           CO.extended_ord_type                                                                  "ExtendedOrdType",            --84
           CO.PRIM_LISTING_EXCHANGE                                                              "PrimListingExchange",        --85
           CO.POSTING_EXCHANGE                                                                   "PostingExchange",            --86
           CO.PRE_OPEN_BEHAVIOR                                                                  "PreOpenBehavior",            --87
           CO.MAX_WAVE_QTY_PCT                                                                   "MaxWaveQtyPct",              --88
           CO.SWEEP_STYLE                                                                        "SweepStyle",                 --89
           CO.DISCRETION_OFFSET                                                                  "DiscretionOffset",           --90
           CRO.CROSS_TYPE                                                                        "CrossType",                  --91
           CO.AGGRESSION_LEVEL                                                                   "AggressionLevel",            --92
           CO.HIDDEN_FLAG                                                                        "HiddenFlag",                 --93
           CO.QUOTE_ID                                                                           "QuoteID",
           CO.STEP_UP_PRICE_TYPE                                                                 "StepUpPriceType",            --95
           CO.STEP_UP_PRICE                                                                      "StepUpPrice",
           CO.CROSS_ACCOUNT_ID::int4                                                             "CrossAccountID",
           CO.CLEARING_ACCOUNT                                                                   "ClearingAccount",            --98
           CO.SUB_ACCOUNT                                                                        "SubAccount",
           CO.REQUEST_NUMBER                                                                     "RequestNumber",              --100
           CO.LIQUIDITY_PROVIDER_ID                                                              "LiquidityProviderID",
           CO.INTERNAL_COMPONENT_TYPE                                                            "InternalComponentType",      --102
           CO.COMPLIANCE_ID                                                                      "ComplianceID",
           CO.ALTERNATIVE_COMPLIANCE_ID                                                          "AlternativeComplianceID",
           CO.CONDITIONAL_CLIENT_ORDER_ID::varchar                                               "ConditionalClientOrderID",
           'N'::varchar                                                                          "IsConditionalOrder",         --106
           EX.exch_exec_id as                                                                    "ExchExecID"
    FROM dwh.EXECUTION EX
             JOIN cte_client_order CO ON (EX.ORDER_ID = CO.ORDER_ID)
             JOIN
         (SELECT I.INSTRUMENT_ID         InstrumentID,
                 I.SYMBOL                Symbol,
                 I.INSTRUMENT_TYPE_ID    InstrumentType,
                 U.SYMBOL                UnderlyingSymbol,
                 OC.MATURITY_YEAR        MaturityYear,
                 OC.MATURITY_MONTH       MaturityMonth,
                 OC.MATURITY_DAY         MaturityDay,
                 OC.PUT_CALL             PutCall,
                 OC.STRIKE_PRICE         StrikePx,
                 OC.OPRA_SYMBOL          OPRASymbol,
                 OS.CONTRACT_MULTIPLIER  ContractMultiplier,
                 I.INSTRUMENT_NAME       InstrumentName,
                 I.DISPLAY_INSTRUMENT_ID DisplayInstrumentID,
                 U.DISPLAY_INSTRUMENT_ID UnderlyingDisplayInstrID
          --select *
          FROM dwh.d_INSTRUMENT I
                   LEFT JOIN dwh.d_OPTION_CONTRACT OC on (I.INSTRUMENT_ID = OC.INSTRUMENT_ID)
                   LEFT JOIN dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
                   LEFT JOIN dwh.d_INSTRUMENT U ON (OS.UNDERLYING_INSTRUMENT_ID = U.INSTRUMENT_ID)
          WHERE I.INSTRUMENT_TYPE_ID IN ('E', 'O', 'M')
             --AND I.is_active
         ) HSD ON (HSD.INSTRUMENTID = CO.INSTRUMENT_ID)
             JOIN dwh.d_FIX_CONNECTION FC ON (FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID)
             JOIN dwh.d_ACCOUNT ACC ON (CO.ACCOUNT_ID = ACC.ACCOUNT_ID)
             LEFT JOIN d_OPT_EXEC_BROKER OPX
                       ON (OPX.ACCOUNT_ID = ACC.ACCOUNT_ID AND OPX.is_active AND OPX.IS_DEFAULT = 'Y')
             LEFT JOIN cte_client_order COORIG ON (CO.ORIG_ORDER_ID = COORIG.ORDER_ID)
             LEFT JOIN dwh.CLIENT_ORDER_LEG COL ON (CO.ORDER_ID = COL.ORDER_ID)
             LEFT JOIN cte_cross_order CRO ON CO.CROSS_ORDER_ID = CRO.CROSS_ORDER_ID
             left join cte_algo_order_tca al on al.order_id = co.order_id
    WHERE 1 = 1
      --and EX.ORDER_STATUS <> '3'
      --AND CO.MULTILEG_REPORTING_TYPE IN ('1','2')
      AND co.order_id = any (string_to_array((select string_agg(order_id::text, ',') from all_hist_o), ',')::bigint[])
      AND co.create_date_id = any
          (string_to_array((select string_agg(create_date_id::text, ',') from all_hist_o), ',')::int[])


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
--    CO.SUB_STRATEGY "SubStrategy",  --66
    dss.SUB_STRATEGY "SubStrategy",  --66
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
  left join data_marts.d_sub_strategy dss on dss.sub_strategy_id = co.sub_strategy_id
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
