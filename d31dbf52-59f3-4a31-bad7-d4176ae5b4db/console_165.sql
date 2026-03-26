-- DROP FUNCTION dash360.order_chain_for_order_id(int8, bpchar);

CREATE or replace FUNCTION trash.so_order_chain_for_order_id(in_order_id bigint, in_is_start_from_current character)
    RETURNS TABLE
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
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- #variable_conflict use_column
-- PD: 20240812 https://dashfinancial.atlassian.net/browse/DS-8735 made changes to order by "TransctTime", exec_id
-- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
-- 20250210 AK https://dashfinancial.atlassian.net/browse/DS-9519 indroduced l_min_date_id for conditional orders
-- 20250507 MB https://dashfinancial.atlassian.net/browse/DS-9912 Decommission of data_marts.d_sub_strategy
-- 20250512 AK https://dashfinancial.atlassian.net/browse/DS-9942 modified order by step
-- 20251107 OK https://dashfinancial.atlassian.net/browse/DS-10680 uncommented case when block for "OrigClOrdID"
-- 20251201 PD https://dashfinancial.atlassian.net/browse/DS-10806 changed the logic for the last l_generate_synthetic
-- 20251217 PD https://dashfinancial.atlassian.net/browse/DS-10870 generating exec_type for synthetics depending on trans_type
-- 20251217 PD https://dashfinancial.atlassian.net/browse/DS-10871 commented piece of code that generates synthetics for exec_type = 'Y' (OrigRejectReplace)
declare
    l_date_id            int;
    l_start_order_id     bigint;
    l_min_create_date_id int4;
    l_min_date_id        int;
    l_generate_synthetic bool;
    l_row_count          int;
    l_load_id            int;
    l_step_id            int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' STARTED===', 0,
                           'O')
    into l_step_id;
    --    raise notice 'start - %', clock_timestamp();
    if in_is_start_from_current <> 'Y' then
        -- Looking for min order from client_order and conditional_order
        with recursive
            min_hist_o (order_id, create_date_id, orig_order_id) --min order_id for client_order
                as
                (select order_id::bigint, create_date_id, orig_order_id
                 from dwh.client_order
                 where order_id = in_order_id
                 union all
                 select co_rec.order_id, co_rec.create_date_id, co_rec.orig_order_id
                 from dwh.client_order co_rec
                          inner join min_hist_o
                                     on min_hist_o.orig_order_id = co_rec.order_id)
                ,
            min_hist_co (order_id, /*create_date_id, */orig_order_id) -- min order for conditional_order
                as
                (select order_id::bigint, /*create_date_id, */orig_order_id
                 from dwh.conditional_order
                 where order_id = in_order_id
                 union all
                 select co_rec.order_id, /*co_rec.create_date_id, */co_rec.orig_order_id
                 from dwh.conditional_order co_rec
                          inner join min_hist_co
                                     on min_hist_co.orig_order_id = co_rec.order_id)
        select min(order_id)
        into l_start_order_id
        from (select order_id
              from min_hist_o
              union all
              select order_id
              from min_hist_co) x;
    else
        l_start_order_id := in_order_id;
    end if;
-- raise notice 'l_start_order_id - %, %', l_start_order_id, clock_timestamp();

    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text ||
                           ' Looking for min order from client_order and conditional_order', 0,
                           'O')
    into l_step_id;

    drop table if exists t_all_hist_o;
    create temp table t_all_hist_o as
    with recursive all_hist_o (order_id, create_date_id, orig_order_id) --for client_order
                       as
                       (select order_id::bigint, create_date_id, orig_order_id, 1 as lev
                        from dwh.client_order
                        where order_id = l_start_order_id
                        union all
                        select co_rec.order_id, co_rec.create_date_id, co_rec.orig_order_id, all_hist_o.lev + 1 as lev
                        from dwh.client_order co_rec
                                 inner join all_hist_o
                                            on co_rec.orig_order_id = all_hist_o.order_id)
    select *
    from all_hist_o;
    get diagnostics l_row_count = row_count;
--    raise notice 't_all_hist_o - %', clock_timestamp();
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' calculation t_all_hist_o', l_row_count,
                           'O')
    into l_step_id;
    analyze t_all_hist_o;
    create index on t_all_hist_o (order_id, create_date_id, orig_order_id);

    drop table if exists t_all_hist_co;
    create temp table t_all_hist_co as
    with recursive all_hist_co (order_id, /*create_date_id, */orig_order_id) -- for conditional_order
                       as
                       (select order_id::bigint, /*create_date_id, */orig_order_id, 1 as lev
                        from dwh.conditional_order
                        where order_id = l_start_order_id
                        union all
                        select co_rec.order_id, /*co_rec.create_date_id, */co_rec.orig_order_id,
                               all_hist_co.lev + 1 as lev
                        from dwh.conditional_order co_rec
                                 inner join all_hist_co
                                            on co_rec.orig_order_id = all_hist_co.order_id)
    select *
    from all_hist_co;
--    raise notice 't_all_hist_co - %', clock_timestamp();
    get diagnostics l_row_count = row_count;
--    raise notice 't_all_hist_o - %', clock_timestamp();
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' calculation t_all_hist_co',
                           l_row_count,
                           'O')
    into l_step_id;
    analyze t_all_hist_co;

    drop table if exists t_cte_cross_order;
    create temp table t_cte_cross_order as
    select *
    from dwh.cross_order cor
--where cor.cross_order_id in (select order_id from all_hist_o)
    where cor.cross_order_id = any
          (string_to_array((select string_agg(order_id::text, ',') from t_all_hist_o), ',')::bigint[]);
--    raise notice 't_cte_cross_order - %', clock_timestamp();

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' calculation t_cte_cross_order',
                           l_row_count,
                           'O')
    into l_step_id;

    drop table if exists t_cte_algo_order_tca;
    create temp table t_cte_algo_order_tca as
    select *
    from eq_tca.algo_order_tca
--where order_id in (select order_id from all_hist_o)
    where order_id = any (string_to_array((select string_agg(order_id::text, ',') from t_all_hist_o), ',')::bigint[]);
--    raise notice 't_cte_algo_order_tca - %', clock_timestamp();
    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' calculation t_cte_algo_order_tca',
                           l_row_count,
                           'O')
    into l_step_id;

    drop table if exists t_cte_client_order;
    create temp table t_cte_client_order as
    select co.*, di.*, coorig.client_order_id as orig_client_order_id
    from dwh.client_order co
             inner join lateral (select display_instrument_id2
                                 from dwh.d_instrument di
                                 where di.instrument_id = co.instrument_id
                                 limit 1) di on true
             LEFT JOIN lateral (select client_order_id
                                from dwh.client_order coorig
                                where co.orig_order_id = coorig.order_id) coorig on true
--where order_id in (select order_id from all_hist_o)
    where order_id = any (string_to_array((select string_agg(order_id::text, ',') from t_all_hist_o), ',')::bigint[]);
--    raise notice 't_cte_client_order - %', clock_timestamp();

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' calculation t_cte_client_order',
                           l_row_count,
                           'O')
    into l_step_id;

    select min(create_date_id)
    into l_min_create_date_id
    from t_cte_client_order;

    drop table if exists t_cte_conditional_order;
    create temp table t_cte_conditional_order as
    select *
    from dwh.conditional_order
    where order_id = any (string_to_array((select string_agg(order_id::text, ',') from t_all_hist_co), ',')::bigint[]);

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' calculation t_cte_conditional_order',
                           l_row_count,
                           'O')
    into l_step_id;

    select min(date_id)
    into l_min_date_id
    from t_cte_conditional_order;

    if exists
        (select null
         from t_all_hist_o co
                  join lateral (select *
                                from dwh.client_order co2
                                where CO2.orig_ORDER_ID = co.ORDER_ID
                                  and CO2.orig_ORDER_ID is not null
--                                   and co2.create_date_id <= co.create_date_id
                                limit 1
             ) co2 on true
                  join dwh.execution e on co.order_id = e.order_id and e.exec_date_id >= co.create_date_id
--                                               and order_status in ('4', '8', '2', '3', 'C', 'B')
         where true --co.order_id in (select order_id from t_all_hist_o)
           and e.exec_time < co2.process_time
           and e.exec_type = 'F') then
        l_generate_synthetic = false;
    else
        l_generate_synthetic = true;
    end if;

    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' l_generate_synthetic', l_row_count,
                           'O')
    into l_step_id;

    drop table if exists pre_return;
    create temp table pre_return as
    select *
    from (select DISTINCT ON (ex.order_id, co.trans_type) null::bigint                                                              EXEC_ID,
                                                          CO.ORDER_ID                                                            as "OrderID",
                                                          CO.CLIENT_ORDER_ID::varchar                                            as "ClOrdID",
--	       null::varchar as "OrigClOrdID",
                                                          case when e.EXEC_TYPE = 'D' then null else CO.ORIG_CLIENT_ORDER_ID end as "OrigClOrdID",
                                                          CO.ORDER_CLASS::char                                                   as "OrderClass",
                                                          null::bigint                                                           as "CustomerOrderID",
                                                          null::bigint                                                           as "ExecID",
                                                          null::bigint                                                           as "RefExecID",
                                                          null::bigint                                                           as "InstrumentID",
                                                          null::varchar                                                          as "Symbol",                     --10
                                                          null::char                                                             as "InstrumentType",
                                                          null::smallint                                                         as "MaturityYear",
                                                          null::smallint                                                         as "MaturityMonth",
                                                          null::smallint                                                         as "MaturityDay",
                                                          null::char                                                             as "PutCall",
                                                          null::numeric                                                          as "StrikePx",
                                                          null::varchar                                                          as "OPRASymbol",
                                                          CO.display_instrument_id2::varchar                                     as "DisplayInstrumentID",
                                                          null::varchar                                                          as "UnderlyingDisplayInstrID",
                                                          null::timestamp                                                        as "OrderCreationTime",          --20
                                                          CO2.PROCESS_TIME::timestamp                                            as "TransactTime",
                                                          null::timestamp                                                        as "LogTime",                    --22
                                                          CO.PROCESS_TIME::timestamp                                             as "RoutedTime",
                                                          CO.ORDER_TYPE_ID::char                                                 as "OrderType",                  --24
                                                          CO.SIDE::char                                                          as "Side",
                                                          CO.ORDER_QTY::int                                                      as "OrderQty",
                                                          CO.PRICE::numeric                                                      as "Price",
                                                          null::numeric                                                          as "StopPx",
                                                          CO.TIME_IN_FORCE_ID::char                                              as "TimeInForce",                --29
                                                          null::timestamp                                                        as "ExpireTime",
                                                          null::char                                                             as "OpenClose",                  --31
                                                          CO.EX_DESTINATION::varchar                                             as "ExDestination",
                                                          null::char                                                             as "HandlInst",                  --33
                                                          null::varchar                                                          as "ExecInst",
                                                          null::int                                                              as "MaxShowQty",
                                                          null::bigint                                                           as "MaxFloorQty",
                                                          null::varchar                                                          as "ClearingFirmID",             -- 37
                                                          null::int                                                              as "ExecBroker",
                                                          --we store value in CLIENT_ORDER for all cases
                                                          null::char                                                             as "CustomerOrFirm",             --39
                                                          null::char                                                             as "OrderCapacity",--40
                                                          -- in order to display MPID used for routing, not sent by client
                                                          null::varchar                                                          as "MarketParticipantID",        --41
                                                          null::char                                                             as "IsLocateRequired",
                                                          null::varchar                                                          as "LocateBroker",
                                                          case
                                                              when co2.trans_type = 'G' then 'a'
                                                              when co2.trans_type = 'F' then 'b'
                                                              else co2.trans_type
                                                              end                                                                as "ExecType",                   --44
                                                          case
                                                              when co2.trans_type = 'G' then 'a'
                                                              when co2.trans_type = 'F' then 'b'
                                                              else co2.trans_type
                                                              end                                                                as "OrderStatus",                --45
                                                          -- reject reason should be selected for rejects and Cancels only
                                                          null::varchar                                                          as "RejectReason",
                                                          coalesce(e.leaves_qty, 0)                                              as "LeavesQty",                  --47
                                                          coalesce(e.cum_qty, 0::bigint)                                         as "CumQty",                     --48
                                                          coalesce(e.avg_px, 0.0)                                                as "AvgPx",                      --49
                                                          0::int                                                                 as "LastQty",                    --50
                                                          0.0                                                                    as "LastPx",                     --51
                                                          --in order to provide correct displaying of Arca ortions
                                                          null::varchar                                                          as "LastMkt",                    --52
                                                          null::bigint                                                           as "DayOrderQty",                --53
                                                          null::bigint                                                           as "DayCumQty",                  --54
                                                          null::numeric                                                          as "DayAvgPx",
                                                          null::int                                                              as "AccountID",                  --56
                                                          null::varchar                                                          as "TradeLiquidityIndicator",    --57
                                                          null::char                                                             as "MultilegReportingType",      --58
                                                          --    COL.CLIENT_LEG_REF_ID "LegRefID", --59
                                                          --    COL.MULTILEG_ORDER_ID "MultilegOrderID", --60
                                                          null ::varchar                                                         as "LegRefID",                   --59
                                                          null::bigint                                                           as "MultilegOrderID",            --60
                                                          FC.FIX_COMP_ID::varchar                                                as "FixCompID",                  --sending firm
                                                          CO.CLIENT_ID_TEXT::varchar                                             as "ClientID",                   --62
                                                          'SYNTHETIC ORIGINAL PENDING EXECUTION'::varchar                        as "Text",                       --63
                                                          null::varchar                                                          as "IsOSROrder",                 --64
                                                          null::bigint                                                           as "OSROrderID",                 --65
                                                          CO.SUB_STRATEGY_DESC::varchar                                          as "SubStrategy",                --66
                                                          null::numeric                                                          as "AlgoStopPx",
                                                          null::varchar                                                          as "AlgoClOrdID",                --68
                                                          null::char                                                             as "TransType",                  --69
                                                          null::varchar                                                          as "DashClOrdID",
                                                          null::bigint                                                           as "CrossOrderID",
                                                          null::varchar                                                          as "OCCOptionalData",
                                                          null::varchar                                                          as "SubSystemID",
                                                          null::bigint                                                           as "TransactionID",
                                                          null::bigint                                                           as "TotNoOrdersInTransaction",   --75
                                                          null::varchar                                                          as "ExchangeID",                 --76
                                                          null::smallint                                                         as "FeeSensitivity",             --77
                                                          null::varchar                                                          as "OnBehalfOfSubID",            --78
                                                          null::smallint                                                         as "StrategyDecisionReasonCode", --79
                                                          null::bigint                                                           as "InternalOrderID",            --80
                                                          null::timestamp                                                        as "AlgoStartTime",              --81
                                                          null::timestamp                                                        as "AlgoEndTime",                --82
                                                          null::int                                                              as "MinTargetQty",               --83
                                                          null::char                                                             as "ExtendedOrdType",            --84
                                                          null::varchar                                                          as "PrimListingExchange",        --85
                                                          null::varchar                                                          as "PostingExchange",            --86
                                                          null::char                                                             as "PreOpenBehavior",            --87
                                                          null::bigint                                                           as "MaxWaveQtyPct",              --88
                                                          null::char                                                             as "SweepStyle",                 --89
                                                          null::numeric                                                          as "DiscretionOffset",           --90
                                                          null::char                                                             as "CrossType",                  --91
                                                          null::smallint                                                         as "AggressionLevel",            --92
                                                          null::char                                                             as "HiddenFlag",                 --93
                                                          null::varchar                                                          as "QuoteID",
                                                          null::char                                                             as "StepUpPriceType",            --95
                                                          null::numeric                                                          as "StepUpPrice",
                                                          null::int                                                              as "CrossAccountID",
                                                          null::varchar                                                          as "ClearingAccount",            --98
                                                          null::varchar                                                          as "SubAccount",
                                                          null::int                                                              as "RequestNumber",              --100
                                                          null::varchar                                                          as "LiquidityProviderID",
                                                          null::char                                                             as "InternalComponentType",      --102
                                                          null::varchar                                                          as "ComplianceID",
                                                          null::varchar                                                          as "AlternativeComplianceID",
                                                          null::varchar                                                          as "ConditionalClientOrderID",
                                                          'N'::varchar                                                           as "IsConditionalOrder",         --106
                                                          co.client_order_id::varchar                                            as exch_exec_id
          from t_cte_client_order co
                   join lateral (select *
                                 from dwh.client_order co2
                                 where co.ORDER_ID = CO2.orig_ORDER_ID
                                 limit 1
              ) co2 on true
                   left join lateral (select *
                                      from dwh.execution e
                                      where co.order_id = e.order_id
                                      order by exec_time desc
                                      limit 1 ) e on true
                   JOIN dwh.d_fix_connection FC ON FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID
                   JOIN dwh.EXECUTION EX ON (EX.ORDER_ID = CO.ORDER_ID and ex.exec_date_id >= co.create_date_id and
                                             ex.exec_date_id >= l_min_create_date_id)
          where l_generate_synthetic
          union all
          SELECT EX.EXEC_ID,
                 CO.ORDER_ID                                                                      "OrderID",
                 case
                     when EX.EXEC_TYPE in ('Y', 'y')
                         then fmj.tag_11
                     else CO.CLIENT_ORDER_ID
                     end                                                                       as "ClOrdID",
                 case
                     when EX.EXEC_TYPE in ('Y', 'y')
                         then fmj.tag_41
                     when EX.EXEC_TYPE = 'D' then null
                     else CO.ORIG_CLIENT_ORDER_ID
                     end                                                                       as "OrigClOrdID",                -- case when EX.EXEC_TYPE = 'D' then null else COORIG.CLIENT_ORDER_ID end as "OrigClOrdID"
                 CO.ORDER_CLASS                                                                   "OrderClass",
                 CO.PARENT_ORDER_ID                                                               "CustomerOrderID",
                 EX.EXEC_ID                                                                       "ExecID",
                 EX.REF_EXEC_ID                                                                   "RefExecID",
                 CO.INSTRUMENT_ID                                                                 "InstrumentID",
                 HSD.SYMBOL                                                                       "Symbol",                     --10
                 HSD.InstrumentType                                                               "InstrumentType",
                 HSD.MaturityYear                                                                 "MaturityYear",
                 HSD.MaturityMonth                                                                "MaturityMonth",
                 HSD.MaturityDay                                                                  "MaturityDay",
                 HSD.PutCall                                                                      "PutCall",
                 HSD.StrikePx                                                                     "StrikePx",
                 HSD.OPRASymbol                                                                   "OPRASymbol",
                 HSD.DisplayInstrumentID                                                          "DisplayInstrumentID",
                 HSD.UnderlyingDisplayInstrID                                                     "UnderlyingDisplayInstrID",
                 CO.CREATE_TIME                                                                   "OrderCreationTime",          --20
                 EX.EXEC_TIME                                                                     "TransactTime",
                 fmj.pg_db_create_time                                                            "LogTime",                    --22
                 CO.PROCESS_TIME                                                                  "RoutedTime",
                 CO.ORDER_TYPE_ID                                                                 "OrderType",                  --24
                 CO.SIDE                                                                          "Side",
                 CO.ORDER_QTY::int                                                                "OrderQty",
                 CO.PRICE                                                                         "Price",
                 CO.STOP_PRICE                                                                    "StopPx",
                 CO.TIME_IN_FORCE_ID                                                              "TimeInForce",                --29
                 CO.EXPIRE_TIME                                                                   "ExpireTime",
                 CO.OPEN_CLOSE                                                                    "OpenClose",                  --31
                 CO.EX_DESTINATION                                                                "ExDestination",
                 CO.HANDL_INST                                                                    "HandlInst",                  --33
                 CO.EXEC_INSTRUCTION                                                              "ExecInst",
                 CO.MAX_SHOW_QTY::int                                                             "MaxShowQty",
                 CO.MAX_FLOOR                                                                     "MaxFloorQty",
                 CASE
                     WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
                         then CO.CLEARING_FIRM_ID
                     ELSE CO.CLEARING_FIRM_ID
                     END                                                                          "ClearingFirmID",             -- 37
                 --    ACC.OPT_IS_FIX_EXECBROK_PROCESSED,
                 CASE
                     WHEN HSD.InstrumentType = 'E' THEN NULL
                     WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
                         then coalesce(CO.OPT_EXEC_BROKER_ID, OPX.OPT_EXEC_BROKER_ID)
                     WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED <> 'Y'
                         then OPX.OPT_EXEC_BROKER_ID
                     ELSE CO.OPT_EXEC_BROKER_ID
                     END                                                                          "ExecBroker",
                 --we store value in CLIENT_ORDER for all cases
                 case
                     when CO.PARENT_ORDER_ID is null then co.customer_or_firm_id
                     else NULL end                                                                "CustomerOrFirm",             --39
                 CO.EQ_ORDER_CAPACITY                                                             "OrderCapacity",--40
                 -- in order to display MPID used for routing, not sent by client
                 case when HSD.InstrumentType = 'E' then ACC.EQ_MPID else null end                "MarketParticipantID",        --41
                 CO.LOCATE_REQ                                                                    "IsLocateRequired",
                 CO.LOCATE_BROKER                                                                 "LocateBroker",
                 EX.EXEC_TYPE                                                                     "ExecType",                   --44
                 EX.ORDER_STATUS                                                                  "OrderStatus",                --45
                 -- reject reason should be selected for rejects and Cancels only
                 case when EX.EXEC_TYPE = '8' then EX.exec_text else null end                     "RejectReason",
                 EX.LEAVES_QTY                                                                    "LeavesQty",                  --47
                 (ex_less.sum_last_qty)::bigint                                                as "CumQty",                     --48
                 case
                     when ex_less.sum_last_qty != 0 then
                         ex_less.sum_last_qty_last_px / case
                                                            when ex_less.sum_last_qty = 0 then 1
                                                            else ex_less.sum_last_qty end end  as "AvgPx",                      --49
                 EX.LAST_QTY::int                                                                 "LastQty",                    --50
                 EX.LAST_PX                                                                       "LastPx",                     --51
                 --in order to provide correct displaying of Arca ortions
                 CASE
                     WHEN EX.EXEC_TYPE NOT IN ('F', 'G', 'D')
                         THEN NULL
                     WHEN CO.PARENT_ORDER_ID IS NULL
                         THEN EX.LAST_MKT
                     ELSE CO.EX_DESTINATION
                     END                                                                          "LastMkt",                    --52
                 (CO.ORDER_QTY - EX.CUM_QTY + coalesce(eq.sum_last_qty, 0))::bigint            as "DayOrderQty",                --53
                 coalesce(eq.sum_last_qty, 0)::bigint                                          as "DayCumQty",                  --54
                 round(coalesce(eq.sum_last_qty_last_px / case
                                                              when eq.sum_last_qty = 0 then 1
                                                              else eq.sum_last_qty end, 0), 4) as "DayAvgPx",
                 CO.ACCOUNT_ID::int                                                               "AccountID",                  --56
                 EX.TRADE_LIQUIDITY_INDICATOR                                                     "TradeLiquidityIndicator",    --57
                 CO.MULTILEG_REPORTING_TYPE                                                       "MultilegReportingType",      --58
                 --    COL.CLIENT_LEG_REF_ID "LegRefID", --59
                 --    COL.MULTILEG_ORDER_ID "MultilegOrderID", --60
                 CO.co_client_leg_ref_id                                                          "LegRefID",                   --59
                 CO.MULTILEG_ORDER_ID                                                             "MultilegOrderID",            --60
                 FC.FIX_COMP_ID                                                                   "FixCompID",                  --sending firm
                 CO.CLIENT_ID_TEXT                                                                "ClientID",                   --62
                 EX.exec_text                                                                     "Text",                       --63
                 CASE
                     WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
                         THEN 'Y'::varchar
                     ELSE 'N'::varchar
                     END                                                                          "IsOSROrder",                 --64
                 coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID)                       "OSROrderID",                 --65
                 CO.SUB_STRATEGY_DESC                                                             "SubStrategy",                --66
                 CO.ALGO_STOP_PX                                                                  "AlgoStopPx",
                 CO.ALGO_CLIENT_ORDER_ID                                                          "AlgoClOrdID",                --68
                 CO.TRANS_TYPE                                                                    "TransType",                  --69
                 CO.DASH_CLIENT_ORDER_ID                                                          "DashClOrdID",
                 CO.CROSS_ORDER_ID                                                                "CrossOrderID",
                 CO.OCC_OPTIONAL_DATA                                                             "OCCOptionalData",
                 CO.SUB_STRATEGY_DESC                                                             "SubSystemID",
                 CO.TRANSACTION_ID                                                                "TransactionID",
                 CO.TOT_NO_ORDERS_IN_TRANSACTION                                                  "TotNoOrdersInTransaction",   --75
                 CO.EXCHANGE_ID                                                                   "ExchangeID",                 --76
                 CO.FEE_SENSITIVITY                                                               "FeeSensitivity",             --77
                 CO.ON_BEHALF_OF_SUB_ID                                                           "OnBehalfOfSubID",            --78
                 CO.strtg_decision_reason_code                                                    "StrategyDecisionReasonCode", --79
                 CO.INTERNAL_ORDER_ID                                                             "InternalOrderID",            --80
                 CO.ALGO_START_TIME                                                               "AlgoStartTime",              --81
                 CO.ALGO_END_TIME                                                                 "AlgoEndTime",                --82
                 al.MIN_TARGET_QTY::int                                                           "MinTargetQty",               --83
                 CO.extended_ord_type                                                             "ExtendedOrdType",            --84
                 CO.PRIM_LISTING_EXCHANGE                                                         "PrimListingExchange",        --85
                 CO.POSTING_EXCHANGE                                                              "PostingExchange",            --86
                 CO.PRE_OPEN_BEHAVIOR                                                             "PreOpenBehavior",            --87
                 CO.MAX_WAVE_QTY_PCT                                                              "MaxWaveQtyPct",              --88
                 CO.SWEEP_STYLE                                                                   "SweepStyle",                 --89
                 CO.DISCRETION_OFFSET                                                             "DiscretionOffset",           --90
                 CRO.CROSS_TYPE                                                                   "CrossType",                  --91
                 CO.AGGRESSION_LEVEL                                                              "AggressionLevel",            --92
                 CO.HIDDEN_FLAG                                                                   "HiddenFlag",                 --93
                 CO.QUOTE_ID                                                                      "QuoteID",
                 CO.STEP_UP_PRICE_TYPE                                                            "StepUpPriceType",            --95
                 CO.STEP_UP_PRICE                                                                 "StepUpPrice",
                 CO.CROSS_ACCOUNT_ID::int4                                                        "CrossAccountID",
                 CO.CLEARING_ACCOUNT                                                              "ClearingAccount",            --98
                 CO.SUB_ACCOUNT                                                                   "SubAccount",
                 CO.REQUEST_NUMBER                                                                "RequestNumber",              --100
                 CO.LIQUIDITY_PROVIDER_ID                                                         "LiquidityProviderID",
                 CO.INTERNAL_COMPONENT_TYPE                                                       "InternalComponentType",      --102
                 CO.COMPLIANCE_ID                                                                 "ComplianceID",
                 CO.ALTERNATIVE_COMPLIANCE_ID                                                     "AlternativeComplianceID",
                 CO.CONDITIONAL_CLIENT_ORDER_ID::varchar                                          "ConditionalClientOrderID",
                 'N'::varchar                                                                     "IsConditionalOrder",         --106
                 EX.exch_exec_id                                                               as "ExchExecID"
          FROM t_cte_client_order CO
                   JOIN dwh.EXECUTION EX ON (EX.ORDER_ID = CO.ORDER_ID and ex.exec_date_id >= co.create_date_id and
                                             ex.exec_date_id >= l_min_create_date_id) -- remove this hardcode!!!

                   join lateral (SELECT I.INSTRUMENT_ID         InstrumentID,
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
                                 WHERE I.INSTRUMENT_ID = CO.INSTRUMENT_ID
                                   and I.INSTRUMENT_TYPE_ID IN ('E', 'O', 'M')
                                 limit 1
              --AND I.is_active
              ) HSD ON true
                   JOIN dwh.d_FIX_CONNECTION FC ON (FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID)
                   JOIN dwh.d_ACCOUNT ACC ON (CO.ACCOUNT_ID = ACC.ACCOUNT_ID)
              --          LEFT JOIN lateral(select OPT_EXEC_BROKER_ID from d_OPT_EXEC_BROKER OPX where OPX.ACCOUNT_ID = ACC.ACCOUNT_ID AND OPX.is_active AND OPX.IS_DEFAULT = 'Y' limit 1) opx on true
--	         LEFT JOIN t_cte_client_order COORIG ON (CO.ORIG_ORDER_ID = COORIG.ORDER_ID)
                   left join dwh.d_opt_exec_broker opx
                             on opx.opt_exec_broker_id = co.opt_exec_broker_id and opx.is_active
                   LEFT JOIN dwh.CLIENT_ORDER_LEG COL ON (CO.ORDER_ID = COL.ORDER_ID)
                   LEFT JOIN t_cte_cross_order CRO ON CO.CROSS_ORDER_ID = CRO.CROSS_ORDER_ID
                   left join t_cte_algo_order_tca al on al.order_id = co.order_id
                   left join lateral (SELECT FM.fix_message ->> '11' as tag_11,
                                             FM.fix_message ->> '41' as tag_41,
                                             FM.pg_db_create_time
                                      FROM fix_capture.fix_message_json FM
                                      WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
                                        and fm.date_id = ex.exec_date_id
                                        and fm.date_id >= l_min_create_date_id
                                      limit 1) fmj on true
                   left join lateral (SELECT SUM(EQ.LAST_QTY)              as sum_last_qty,
                                             SUM(EQ.LAST_QTY * EQ.LAST_PX) as sum_last_qty_last_px
                                      FROM dwh.EXECUTION EQ
                                      WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
                                        AND EQ.IS_BUSTED <> 'Y'
                                        AND EQ.ORDER_ID = CO.ORDER_ID
                                        AND to_char(EX.EXEC_TIME, 'YYYYMMDD') = to_char(EQ.EXEC_TIME, 'YYYYMMDD')
                                        and EQ.exec_date_id >= l_min_create_date_id
                                      group by eq.order_id
                                      limit 1) eq on true

                   left join lateral (SELECT SUM(EQ.LAST_QTY)              as sum_last_qty,
                                             SUM(EQ.LAST_QTY * EQ.LAST_PX) as sum_last_qty_last_px
                                      FROM dwh.EXECUTION EQ
                                      WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
                                        AND EQ.IS_BUSTED <> 'Y'
                                        AND EQ.ORDER_ID = CO.ORDER_ID
                                        AND EQ.EXEC_ID <= EX.EXEC_ID
                                        and eq.exec_date_id >= l_min_create_date_id
                                      group by eq.order_id
                                      limit 1) ex_less on true

          WHERE 1 = 1
            --and EX.ORDER_STATUS <> '3'
            --AND CO.MULTILEG_REPORTING_TYPE IN ('1','2')
            AND co.order_id in (select order_id from t_all_hist_o)
            AND co.create_date_id in (select create_date_id from t_all_hist_o)

          -- raise notice 'client_order_out - %', clock_timestamp()

          union all

          SELECT EX.EXEC_ID,                                                                                   --1
                 CO.ORDER_ID                                                       "OrderID",                  --2
                 case
                     when EX.EXEC_TYPE in ('Y', 'y')
                         then fmj.tag_11
                     else CO.CLIENT_ORDER_ID
                     end         as                                                "ClOrdID",
                 case
                     when EX.EXEC_TYPE in ('Y', 'y')
                         then fmj.tag_41
                     when EX.EXEC_TYPE = 'D' then null
                     else COORIG.CLIENT_ORDER_ID
                     end         as                                                "OrigClOrdID",              --case when EX.EXEC_TYPE = 'D' then null else COORIG.CLIENT_ORDER_ID end as "OrigClOrdID"
                 CO.ORDER_CLASS                                                    "OrderClass",
                 CO.PARENT_ORDER_ID                                                "CustomerOrderID",
                 EX.EXEC_ID                                                        "ExecID",
                 EX.REF_EXEC_ID                                                    "RefExecID",                --8
                 CO.INSTRUMENT_ID                                                  "InstrumentID",             --9
                 HSD.SYMBOL                                                        "Symbol",                   --10
                 HSD.InstrumentType                                                "InstrumentType",
                 HSD.MaturityYear                                                  "MaturityYear",
                 HSD.MaturityMonth                                                 "MaturityMonth",
                 HSD.MaturityDay                                                   "MaturityDay",
                 HSD.PutCall                                                       "PutCall",                  --15
                 HSD.StrikePx                                                      "StrikePx",
                 HSD.OPRASymbol                                                    "OPRASymbol",
                 HSD.DisplayInstrumentID                                           "DisplayInstrumentID",
                 HSD.UnderlyingDisplayInstrID                                      "UnderlyingDisplayInstrID",
                 CO.CREATE_TIME                                                    "OrderCreationTime",        --20
                 EX.EXEC_TIME                                                      "TransactTime",             --21
                 fmj.pg_db_create_time                                             "LogTime",                  --22
                 CO.PROCESS_TIME                                                   "RoutedTime",               --23
                 CO.ORDER_TYPE_ID                                                  "OrderType",
                 CO.SIDE                                                           "Side",                     --25
                 CO.ORDER_QTY::int                                                 "OrderQty",
                 CO.PRICE                                                          "Price",
                 null                                                              "StopPx",
                 CO.TIME_IN_FORCE_ID                                               "TimeInForce",
                 CO.EXPIRE_TIME                                                    "ExpireTime",               --30
                 CO.OPEN_CLOSE                                                     "OpenClose",
                 CO.EX_DESTINATION                                                 "ExDestination",
                 CO.HANDL_INST                                                     "HandlInst",
                 CO.EXEC_INSTRUCTION                                               "ExecInst",
                 CO.MAX_SHOW_QTY::int                                              "MaxShowQty",               --35
                 CO.MAX_FLOOR                                                      "MaxFloorQty",
                 null                                                              "ClearingFirmID",
                 null                                                              "ExecBroker",
                 null                                                              "CustomerOrFirm",           --39
                 CO.EQ_ORDER_CAPACITY                                              "OrderCapacity",            --40
                 -- in order to display MPID used for routing, not sent by client
                 case when HSD.InstrumentType = 'E' then ACC.EQ_MPID else null end "MarketParticipantID",      --41
                 CO.LOCATE_REQ                                                     "IsLocateRequired",
                 CO.LOCATE_BROKER                                                  "LocateBroker",
                 EX.EXEC_TYPE                                                      "ExecType",
                 EX.ORDER_STATUS                                                   "OrderStatus",              --45
                 -- reject reason should be selected for rejects and Cancels only
                 case when EX.EXEC_TYPE = '8' then EX.exec_text else null end      "RejectReason",             --46
                 EX.LEAVES_QTY                                                     "LeavesQty",                --47
                 --EX.CUM_QTY "CumQty",
                 ex_less.sum_last_qty::bigint                                      "CumQty",                   --48
                 --EX.AVG_PX "AvgPx",

                 CASE
                     WHEN ex_less.sum_last_qty = 0
                         THEN NULL
                     ELSE ex_less.sum_last_qty_last_px /
                          case when ex_less.sum_last_qty = 0 then 1 else ex_less.sum_last_qty end
                     END                                                           "AvgPx",                    --49
                 --
                 EX.LAST_QTY::int                                                  "LastQty",                  --50
                 EX.LAST_PX                                                        "LastPx",                   --51
                 --in order to provide correct displaying of Arca ortions
                 CASE
                     WHEN EX.EXEC_TYPE NOT IN ('F', 'G', 'D')
                         THEN NULL
                     WHEN CO.PARENT_ORDER_ID IS NULL
                         THEN EX.LAST_MKT
                     ELSE CO.EX_DESTINATION
                     END                                                           "LastMkt",                  --52
                 CO.ORDER_QTY - EX.CUM_QTY +
                 coalesce(eq.sum_last_qty, 0)::bigint                              "DayOrderQty",              --53
                 coalesce(eq.sum_last_qty, 0)::bigint                              "DayCumQty",                --54
                 ROUND(coalesce(eq.sum_last_qty_last_px /
                                case when eq.sum_last_qty = 0 then 1 else eq.sum_last_qty end, 0),
                       4)                                                          "DayAvgPx",                 --55
                 CO.ACCOUNT_ID::int                                                "AccountID",
                 null::varchar                                                     "TradeLiquidityIndicator",
                 '1'                                                               "MultilegReportingType",
                 null                                                              "LegRefID",
                 null                                                              "MultilegOrderID",          --60
                 FC.FIX_COMP_ID                                                    "FixCompID",                --sending firm
                 CO.CLIENT_ID_TEXT                                                 "ClientID",                 --62
                 EX.exec_text                                                      "Text",                     --63
                 CASE
                     WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
                         THEN 'Y'
                     ELSE 'N'
                     END                                                           "IsOSROrder",               --64
                 coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID)        "OSROrderID",               --65
                 --    CO.SUB_STRATEGY "SubStrategy",  --66
                 dts.target_strategy_name                                          "SubStrategy",              --66
                 null                                                              "AlgoStopPx",
                 CO.ALGO_CLIENT_ORDER_ID                                           "AlgoClOrdID",
                 CO.TRANS_TYPE                                                     "TransType",
                 null                                                              "DashClOrdID",              --70
                 null                                                              "CrossOrderID",
                 CO.OCC_OPTIONAL_DATA                                              "OCCOptionalData",
                 null                                                              "SubSystemID",
                 CO.TRANSACTION_ID                                                 "TransactionID",
                 null                                                              "TotNoOrdersInTransaction", --75
                 CO.EXCHANGE_ID                                                    "ExchangeID",
                 null                                                              "FeeSensitivity",
                 null                                                              "OnBehalfOfSubID",
                 CO.strtg_decision_reason_code                                     "StrategyDecisionReasonCode",
                 null                                                              "InternalOrderID",          --80
                 CO.ALGO_START_TIME                                                "AlgoStartTime",
                 CO.ALGO_END_TIME                                                  "AlgoEndTime",
                 CO.MIN_TARGET_QTY::int                                            "MinTargetQty",
                 null                                                              "ExtendedOrdType",
                 null                                                              "PrimListingExchange",      --85
                 null                                                              "PostingExchange",
                 null                                                              "PreOpenBehavior",
                 null                                                              "MaxWaveQtyPct",
                 null                                                              "SweepStyle",
                 CO.DISCRETION_OFFSET                                              "DiscretionOffset",         --90
                 null                                                              "CrossType",
                 null                                                              "AggressionLevel",
                 null                                                              "HiddenFlag",
                 null                                                              "QuoteID",
                 null                                                              "StepUpPriceType",          --95
                 null                                                              "StepUpPrice",
                 null                                                              "CrossAccountID",
                 null                                                              "ClearingAccount",
                 CO.CO_SUB_ACCOUNT                                                 "SubAccount",
                 null                                                              "RequestNumber",            --100
                 CO.LIQUIDITY_PROVIDER_ID                                          "LiquidityProviderID",
                 CO.INTERNAL_COMPONENT_TYPE                                        "InternalComponentType",
                 null                                                              "ComplianceID",
                 null                                                              "AlternativeComplianceID",
                 null                                                              "ConditionalClientOrderID", --105
                 'Y'                                                               "IsConditionalOrder",
                 ex.exch_exec_id as                                                "ExchExecID"
          FROM t_all_hist_co coo
                   JOIN dwh.CONDITIONAL_ORDER CO ON CO.ORDER_ID = coo.order_id
                   join dwh.CONDITIONAL_EXECUTION EX on ex.order_id = coo.order_id
                   left join dwh.d_target_strategy dts on (dts.target_strategy_id = co.sub_strategy_id)
                   JOIN lateral
              (
              SELECT I.INSTRUMENT_ID         InstrumentID,
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
              FROM dwh.d_INSTRUMENT I
                       LEFT JOIN dwh.d_OPTION_CONTRACT OC on (I.INSTRUMENT_ID = OC.INSTRUMENT_ID)
                       LEFT JOIN dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
                       LEFT JOIN dwh.d_INSTRUMENT U ON (OS.UNDERLYING_INSTRUMENT_ID = U.INSTRUMENT_ID)
              WHERE I.INSTRUMENT_ID = CO.INSTRUMENT_ID
                and I.INSTRUMENT_TYPE_ID IN ('E', 'O', 'M')
              --AND I.is_active
              ) HSD ON true
                   JOIN dwh.d_fix_connection FC ON FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID
                   JOIN dwh.d_account ACC ON CO.ACCOUNT_ID = ACC.ACCOUNT_ID
                   LEFT JOIN dwh.CLIENT_ORDER COORIG ON CO.ORIG_ORDER_ID = COORIG.ORDER_ID
                   left join lateral (SELECT FM.fix_message ->> '11' as tag_11,
                                             FM.fix_message ->> '41' as tag_41,
                                             FM.pg_db_create_time
                                      FROM fix_capture.fix_message_json FM
                                      WHERE EX.FIX_MESSAGE_ID = FM.FIX_MESSAGE_ID
                                        and fm.date_id = ex.date_id
                                        and fm.date_id >= l_min_date_id
                                      limit 1) fmj on true
                   left join lateral (SELECT SUM(EQ.LAST_QTY)              as sum_last_qty,
                                             SUM(EQ.LAST_QTY * EQ.LAST_PX) as sum_last_qty_last_px
                                      FROM dwh.CONDITIONAL_EXECUTION EQ
                                      WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
                                        AND EQ.IS_BUSTED <> 'Y'
                                        AND EQ.ORDER_ID = CO.ORDER_ID
                                        AND EQ.EXEC_ID <= EX.EXEC_ID
                                        and eq.date_id >= l_min_date_id
                                      group by eq.order_id
                                      limit 1) ex_less on true
                   left join lateral (SELECT SUM(EQ.LAST_QTY)              as sum_last_qty,
                                             SUM(EQ.LAST_QTY * EQ.LAST_PX) as sum_last_qty_last_px
                                      FROM dwh.CONDITIONAL_EXECUTION EQ
                                      WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
                                        AND EQ.IS_BUSTED <> 'Y'
                                        AND EQ.ORDER_ID = CO.ORDER_ID
                                        AND to_char(EX.EXEC_TIME, 'YYYYMMDD') = to_char(EQ.EXEC_TIME, 'YYYYMMDD')
                                        and EQ.date_id >= l_min_date_id
                                      group by eq.order_id
                                      limit 1) eq on true
          WHERE 1 = 1
            --and EX.ORDER_STATUS <> '3'
            AND co.order_id in (select order_id from t_all_hist_co)
            and co.date_id >= l_min_date_id
            and ex.date_id >= l_min_date_id) main
    order by "TransactTime", exec_id,
             CASE "ExecType"
                 WHEN 'A' THEN 1
                 WHEN 'S' THEN 2
                 WHEN 's' THEN 3
                 WHEN 'a' THEN 4
                 WHEN 'b' THEN 5
                 ELSE 6
                 END;

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' calculation pre_return', l_row_count,
                           'O')
    into l_step_id;

    select case count(*)
               when 0 then true
               else false
               end
    into l_generate_synthetic
    from pre_return
    where exectype = 'A';

    return query
        select *
        from (select distinct on ("OrderID", "ExecType", exec_id) *
              from (select DISTINCT ON (ex.order_id, co.trans_type)-- generate exec_type  'A'
                                                                   null::bigint                                                            as EXEC_ID,
                                                                   CO.ORDER_ID                                                             as "OrderID",
                                                                   CO.CLIENT_ORDER_ID::varchar                                             as "ClOrdID",
--	       null::varchar as "OrigClOrdID",
                                                                   case when EX.EXEC_TYPE = 'D' then null else CO.ORIG_CLIENT_ORDER_ID end as "OrigClOrdID",
                                                                   CO.ORDER_CLASS::char                                                    as "OrderClass",
                                                                   null::bigint                                                            as "CustomerOrderID",
                                                                   null::bigint                                                            as "ExecID",
                                                                   null::bigint                                                            as "RefExecID",
                                                                   null::bigint                                                            as "InstrumentID",
                                                                   null::varchar                                                           as "Symbol",                     --10
                                                                   null::char                                                              as "InstrumentType",
                                                                   null::smallint                                                          as "MaturityYear",
                                                                   null::smallint                                                          as "MaturityMonth",
                                                                   null::smallint                                                          as "MaturityDay",
                                                                   null::char                                                              as "PutCall",
                                                                   null::numeric                                                           as "StrikePx",
                                                                   null::varchar                                                           as "OPRASymbol",
                                                                   CO.display_instrument_id2::varchar                                      as "DisplayInstrumentID",
                                                                   null::varchar                                                           as "UnderlyingDisplayInstrID",
                                                                   null::timestamp                                                         as "OrderCreationTime",          --20
                                                                   CO.PROCESS_TIME::timestamp                                              as "TransactTime",
                                                                   null::timestamp                                                         as "LogTime",                    --22
                                                                   CO.PROCESS_TIME::timestamp                                              as "RoutedTime",
                                                                   CO.ORDER_TYPE_ID::char                                                  as "OrderType",                  --24
                                                                   CO.SIDE::char                                                           as "Side",
                                                                   CO.ORDER_QTY::int                                                       as "OrderQty",
                                                                   CO.PRICE::numeric                                                       as "Price",
                                                                   null::numeric                                                           as "StopPx",
                                                                   CO.TIME_IN_FORCE_ID::char                                               as "TimeInForce",                --29
                                                                   null::timestamp                                                         as "ExpireTime",
                                                                   null::char                                                              as "OpenClose",                  --31
                                                                   CO.EX_DESTINATION::varchar                                              as "ExDestination",
                                                                   null::char                                                              as "HandlInst",                  --33
                                                                   null::varchar                                                           as "ExecInst",
                                                                   null::int                                                               as "MaxShowQty",
                                                                   null::bigint                                                            as "MaxFloorQty",
                                                                   null::varchar                                                           as "ClearingFirmID",             -- 37
                                                                   null::int                                                               as "ExecBroker",
                                                                   --we store value in CLIENT_ORDER for all cases
                                                                   null::char                                                              as "CustomerOrFirm",             --39
                                                                   null::char                                                              as "OrderCapacity",--40
                                                                   -- in order to display MPID used for routing, not sent by client
                                                                   null::varchar                                                           as "MarketParticipantID",        --41
                                                                   null::char                                                              as "IsLocateRequired",
                                                                   null::varchar                                                           as "LocateBroker",
                                                                   (case co.trans_type
                                                                        when 'D' then 'A'
                                                                        when 'G' then 'S'
                                                                        when 'F' then 's'
                                                                       end)::bpchar                                                        as "ExecType",                   --44
                                                                   (case co.trans_type
                                                                        when 'D' then 'A'
                                                                        when 'G' then 'S'
                                                                        when 'F' then 's'
                                                                       end)::bpchar                                                        as "OrderStatus",                --45
                                                                   -- reject reason should be selected for rejects and Cancels only
                                                                   null                                                                    as "RejectReason",
                                                                   co.order_qty                                                            as "LeavesQty",                  --47
                                                                   0::bigint                                                               as "CumQty",                     --48
                                                                   0.0                                                                     as "AvgPx",                      --49
                                                                   0::int                                                                  as "LastQty",                    --50
                                                                   0.0                                                                     as "LastPx",                     --51
                                                                   --in order to provide correct displaying of Arca ortions
                                                                   null                                                                    as "LastMkt",                    --52
                                                                   null::bigint                                                            as "DayOrderQty",                --53
                                                                   null::bigint                                                            as "DayCumQty",                  --54
                                                                   null::numeric                                                           as "DayAvgPx",
                                                                   null::int                                                               as "AccountID",                  --56
                                                                   null::varchar                                                           as "TradeLiquidityIndicator",    --57
                                                                   null::char                                                              as "MultilegReportingType",      --58
                                                                   --    COL.CLIENT_LEG_REF_ID "LegRefID", --59
                                                                   --    COL.MULTILEG_ORDER_ID "MultilegOrderID", --60
                                                                   null::varchar                                                           as "LegRefID",                   --59
                                                                   null::bigint                                                            as "MultilegOrderID",            --60
                                                                   FC.FIX_COMP_ID::varchar                                                 as "FixCompID",                  --sending firm
                                                                   CO.CLIENT_ID_TEXT::varchar                                              as "ClientID",                   --62
                                                                   'SYNTHETIC PENDING NEW EXECUTION'                                       as "Text",                       --63
                                                                   null::varchar                                                           as "IsOSROrder",                 --64
                                                                   null::bigint                                                            as "OSROrderID",                 --65
                                                                   CO.SUB_STRATEGY_DESC::varchar                                           as "SubStrategy",                --66
                                                                   null::numeric                                                           as "AlgoStopPx",
                                                                   null::varchar                                                           as "AlgoClOrdID",                --68
                                                                   null::char                                                              as "TransType",                  --69
                                                                   null::varchar                                                           as "DashClOrdID",
                                                                   null::bigint                                                            as "CrossOrderID",
                                                                   null::varchar                                                           as "OCCOptionalData",
                                                                   null::varchar                                                           as "SubSystemID",
                                                                   null::bigint                                                            as "TransactionID",
                                                                   null::bigint                                                            as "TotNoOrdersInTransaction",   --75
                                                                   null::varchar                                                           as "ExchangeID",                 --76
                                                                   null::smallint                                                          as "FeeSensitivity",             --77
                                                                   null::varchar                                                           as "OnBehalfOfSubID",            --78
                                                                   null::smallint                                                          as "StrategyDecisionReasonCode", --79
                                                                   null::bigint                                                            as "InternalOrderID",            --80
                                                                   null::timestamp                                                         as "AlgoStartTime",              --81
                                                                   null::timestamp                                                         as "AlgoEndTime",                --82
                                                                   null::int                                                               as "MinTargetQty",               --83
                                                                   null::char                                                              as "ExtendedOrdType",            --84
                                                                   null::varchar                                                           as "PrimListingExchange",        --85
                                                                   null::varchar                                                           as "PostingExchange",            --86
                                                                   null::char                                                              as "PreOpenBehavior",            --87
                                                                   null::bigint                                                            as "MaxWaveQtyPct",              --88
                                                                   null::char                                                              as "SweepStyle",                 --89
                                                                   null::numeric                                                           as "DiscretionOffset",           --90
                                                                   null::char                                                              as "CrossType",                  --91
                                                                   null::smallint                                                          as "AggressionLevel",            --92
                                                                   null::char                                                              as "HiddenFlag",                 --93
                                                                   null::varchar                                                           as "QuoteID",
                                                                   null::char                                                              as "StepUpPriceType",            --95
                                                                   null::numeric                                                           as "StepUpPrice",
                                                                   null::int                                                               as "CrossAccountID",
                                                                   null::varchar                                                           as "ClearingAccount",            --98
                                                                   null::varchar                                                           as "SubAccount",
                                                                   null::int                                                               as "RequestNumber",              --100
                                                                   null::varchar                                                           as "LiquidityProviderID",
                                                                   null::char                                                              as "InternalComponentType",      --102
                                                                   null::varchar                                                           as "ComplianceID",
                                                                   null::varchar                                                           as "AlternativeComplianceID",
                                                                   null::varchar                                                           as "ConditionalClientOrderID",
                                                                   'N'::varchar                                                            as "IsConditionalOrder",         --106
                                                                   'NONE'::varchar                                                         as exch_exec_id
                    from t_cte_client_order co
                             JOIN dwh.d_fix_connection FC ON FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID
                             JOIN dwh.EXECUTION EX
                                  ON (EX.ORDER_ID = CO.ORDER_ID and ex.exec_date_id >= co.create_date_id and
                                      ex.exec_date_id >= l_min_create_date_id)
                    where not exists (select 1
                                      from dwh.EXECUTION ex
                                      where ex.ORDER_ID = co.ORDER_ID
                                        and ex.exec_date_id >= co.create_date_id
                                        and ex.exec_date_id >= l_min_create_date_id
                                        and ex.exec_type = (case co.trans_type
                                                                when 'D' then 'A'
                                                                when 'G' then 'S'
                                                                when 'F' then 's'
                                          end))
                      and l_generate_synthetic
                    --and co.trans_type <> 'F'
                    union all
                    select *
                    from pre_return) cte) abc
        order by "TransactTime", exec_id,
                 CASE "ExecType"
                     WHEN 'A' THEN 1
                     WHEN 'S' THEN 2
                     WHEN 's' THEN 3
                     WHEN 'a' THEN 4
                     WHEN 'b' THEN 5
                     ELSE 6
                     END;
    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'order_chain_for_order_id ' || in_order_id::text || ' COMPLETED======', l_row_count,
                           'O')
    into l_step_id;
end;
$function$
;

drop table t_os;
create temp table t_os as
select *, '2' as scr
from trash.so_order_chain_for_order_id(438097887071425807, 'N');
insert into t_os
select *, '1'
from dash360.order_chain_for_order_id(438097887071425807, 'N');

select exec_id,
       orderid,
       clordid,
       origclordid,
       orderclass,
       customerorderid,
       execid,
       refexecid,
       instrumentid,
       symbol,
       instrumenttype,
       maturityyear,
       maturitymonth,
       maturityday,
       putcall,
       strikepx,
       oprasymbol,
       displayinstrumentid,
       underlyingdisplayinstrid,
       ordercreationtime,
       transacttime,
       logtime,
       routedtime,
       ordertype,
       side,
       orderqty,
       price,
       stoppx,
       timeinforce,
       expiretime,
       openclose,
       exdestination,
       handlinst,
       execinst,
       maxshowqty,
       maxfloorqty,
       clearingfirmid,
       execbroker,
       customerorfirm,
       ordercapacity,
       marketparticipantid,
       islocaterequired,
       locatebroker,
       exectype,
       orderstatus,
       rejectreason,
       leavesqty,
       cumqty,
       avgpx,
       lastqty,
       lastpx,
       lastmkt,
       dayorderqty,
       daycumqty,
       dayavgpx,
       accountid,
       tradeliquidityindicator,
       multilegreportingtype,
       legrefid,
       multilegorderid,
       fixcompid,
       clientid,
       text,
       isosrorder,
       osrorderid,
       substrategy,
       algostoppx,
       algoclordid,
       transtype,
       dashclordid,
       crossorderid,
       occoptionaldata,
       subsystemid,
       transactionid,
       totnoordersintransaction,
       exchangeid,
       feesensitivity,
       onbehalfofsubid,
       strategydecisionreasoncode,
       internalorderid,
       algostarttime,
       algoendtime,
       mintargetqty,
       extendedordtype,
       primlistingexchange,
       postingexchange,
       preopenbehavior,
       maxwaveqtypct,
       sweepstyle,
       discretionoffset,
       crosstype,
       aggressionlevel,
       hiddenflag,
       quoteid,
       stepuppricetype,
       stepupprice,
       crossaccountid,
       clearingaccount,
       subaccount,
       requestnumber,
       liquidityproviderid,
       internalcomponenttype,
       complianceid,
       alternativecomplianceid,
       conditionalclientorderid,
       isconditionalorder,
       exch_exec_id
from t_os
where "?column?" = '2'
except
select exec_id,
       orderid,
       clordid,
       origclordid,
       orderclass,
       customerorderid,
       execid,
       refexecid,
       instrumentid,
       symbol,
       instrumenttype,
       maturityyear,
       maturitymonth,
       maturityday,
       putcall,
       strikepx,
       oprasymbol,
       displayinstrumentid,
       underlyingdisplayinstrid,
       ordercreationtime,
       transacttime,
       logtime,
       routedtime,
       ordertype,
       side,
       orderqty,
       price,
       stoppx,
       timeinforce,
       expiretime,
       openclose,
       exdestination,
       handlinst,
       execinst,
       maxshowqty,
       maxfloorqty,
       clearingfirmid,
       execbroker,
       customerorfirm,
       ordercapacity,
       marketparticipantid,
       islocaterequired,
       locatebroker,
       exectype,
       orderstatus,
       rejectreason,
       leavesqty,
       cumqty,
       avgpx,
       lastqty,
       lastpx,
       lastmkt,
       dayorderqty,
       daycumqty,
       dayavgpx,
       accountid,
       tradeliquidityindicator,
       multilegreportingtype,
       legrefid,
       multilegorderid,
       fixcompid,
       clientid,
       text,
       isosrorder,
       osrorderid,
       substrategy,
       algostoppx,
       algoclordid,
       transtype,
       dashclordid,
       crossorderid,
       occoptionaldata,
       subsystemid,
       transactionid,
       totnoordersintransaction,
       exchangeid,
       feesensitivity,
       onbehalfofsubid,
       strategydecisionreasoncode,
       internalorderid,
       algostarttime,
       algoendtime,
       mintargetqty,
       extendedordtype,
       primlistingexchange,
       postingexchange,
       preopenbehavior,
       maxwaveqtypct,
       sweepstyle,
       discretionoffset,
       crosstype,
       aggressionlevel,
       hiddenflag,
       quoteid,
       stepuppricetype,
       stepupprice,
       crossaccountid,
       clearingaccount,
       subaccount,
       requestnumber,
       liquidityproviderid,
       internalcomponenttype,
       complianceid,
       alternativecomplianceid,
       conditionalclientorderid,
       isconditionalorder,
       exch_exec_id
from t_os
where "?column?" = '1'



select distinct case when order_status in ('4', '8', '2', '3', 'C', 'B') then false end
into l_generate_synthetic
from order_status;