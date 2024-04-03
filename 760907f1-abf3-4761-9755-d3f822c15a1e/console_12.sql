CREATE or replace FUNCTION dash360.order_blotter_get_order_details(in_order_id bigint)
    RETURNS TABLE
            (
                account_id              integer,
                trading_firm_id         character varying,
                auction_id              bigint,
                order_id                bigint,
                client_order_id         character varying,
                multileg_reporting_type character varying,
                cross_order_id          bigint,
                side                    character varying,
                create_time             timestamp without time zone,
                process_time            timestamp without time zone,
                order_qty               bigint,
                price                   numeric,
                sub_strategy            character varying,
                display_instrument_id   character varying,
                instrument_type_id      character varying,
                instrument_id           bigint,
                last_trade_date         timestamp without time zone,
                customer_or_firm_id     character varying,
                opt_clearing_firm_id    character varying,
                opt_exec_broker         character varying,
                time_in_force_id        character varying,
                open_close              character varying,
                client_id               character varying,
                ratio_qty               bigint,
                no_legs                 integer,
                co_client_leg_ref_id    character varying,
                fix_message_id          bigint,
                order_type              character varying,
                ex_destination          character varying,
                exchange_id             character varying,
                extended_ord_type       character varying,
                sweep_style             character varying,
                aggression_level        smallint,
                order_status            character varying,
                exec_qty                bigint,
                avg_px                  numeric,
                leaves_qty              bigint,
                activ_symbol            character varying,
                trade_date_id           integer,
                latest_street_exec_time timestamp without time zone,
                order_class             character,
                fix_comp_id             character varying,
                is_cons_order           boolean,
                rfr_id                  bigint,
                internal_order_id       bigint
            )
    LANGUAGE plpgsql
AS
$$
    -- SY: 20211208 latest_street_exec_time based on latest parent execution or street execution reports time https://dashfinancial.atlassian.net/browse/DS-4577
-- PD: 20220107 commented grouping by date_id in trd join
-- VP: 20220824 https://dashfinancial.atlassian.net/browse/DS-5511 Add new columns(order_class, fix_comp_id) to responce of dash360.order_blotter_get_order_details
-- MB: 20220929 removed join to data_marts.d_client and changed client_src_id with client_id_text field from dwh.client_order
-- PD: 20221116 added rfr_id to output
-- PD: 20230103 https://dashfinancial.atlassian.net/browse/DS-6132 Changed the logic for rfr_id output
-- PD: 20230119 https://dashfinancial.atlassian.net/browse/DS-6260 added left(dclp.lp_priority,1), because the old logic didn't work
-- PD: 20230908 https://dashfinancial.atlassian.net/browse/DS-6227 added new fields is_cons_order to the output
-- SO: 20240402 https://dashfinancial.atlassian.net/browse/DS-7719 renaming text_ into exec_text
DECLARE
    select_stmt      text;
    sql_params       text;
    row_cnt          integer;
    l_create_date_id integer;
    l_load_id        integer;
    l_step_id        integer;

begin
    --select nextval('public.load_timing_seq') into l_load_id;
    --l_step_id:=1;

    --select public.load_log(l_load_id, l_step_id, 'dash360.order_blotter_get_order_details STARTED===', 0, 'O')
    --into l_step_id;

    l_create_date_id :=
            coalesce((select o.create_date_id from dwh.client_order o where o.order_id = in_order_id limit 1)::integer,
                     21010101);

    RAISE info 'l_create_date_id = % ', l_create_date_id;

    --select public.load_log(l_load_id, l_step_id, 'l_create_date_id = '|| l_create_date_id::varchar, 0, 'O')
    -- into l_step_id;


    -- form the query
    RETURN QUERY
        select co.account_id
             , tf.trading_firm_id
             , auc.auction_id
             , co.order_id
             , co.client_order_id
             , co.multileg_reporting_type::varchar
             , co.cross_order_id
             , co.side::varchar
             , co.create_time
             , co.process_time
             , co.order_qty::bigint
             , co.price
             , case when co.sub_strategy_desc = 'SENSORDRK' then 'SENSORDARK' else co.sub_strategy_desc end sub_strategy
             , i.display_instrument_id2                                                                     display_instrument_id
             , i.instrument_type_id::varchar
             , co.instrument_id
             , i.last_trade_date
             , co.customer_or_firm_id::varchar
             , co.clearing_firm_id                   AS                                                     opt_clearing_firm_id
             --, clo.opt_exec_broker --co.opt_exec_broker_id -- !!!! should be 792 ???
             , eb.opt_exec_broker
             , co.time_in_force_id::varchar
             , co.open_close::varchar
             , co.client_id_text                     as                                                     client_id
             , co.ratio_qty
             , co.no_legs
             , co.co_client_leg_ref_id
             , co.fix_message_id
             , co.order_type_id::varchar             as                                                     order_type --
             , co.ex_destination
             , co.exchange_id
             , co.extended_ord_type::varchar
             , co.sweep_style::varchar
             , co.aggression_level
             , ex.order_status::varchar
             , trd.exec_qty::bigint
             , trd.avg_px
             , ex.leaves_qty
             , i.activ_symbol
             , trd.date_id
             --, str.latest_street_exec_time
             , greatest(str.exec_time, ex.exec_time) as                                                     latest_street_exec_time
             , co.order_class
             , fc.fix_comp_id
             , case
                   when (co.ex_destination = 'ALGO' and co.sub_strategy_id = 78 and i.instrument_type_id in ('M', 'O'))
                       or (co.liquidity_provider_id is not null and fc.fix_comp_id = 'IMCCONS')
                       then true
                   else false
            end                                      as                                                     is_cons_order
             , case
                   when co.ex_destination = 'ALGO' and co.sub_strategy_id = 78 and i.instrument_type_id in ('M', 'O')
                       then co.internal_order_id
                   when left(dclp.lp_priority, 1) = '1' and fc.fix_comp_id = 'IMCCONS'
                       then (select imc.internal_order_id
                             from fix_capture.fix_message_json fmj
                                      join dwh.client_order imc on imc.client_order_id = fmj.fix_message ->> '5059'
                                      join dwh.d_fix_connection dfc on fmj.fix_message ->> '5060' = dfc.fix_comp_id and
                                                                       dfc.fix_connection_id = imc.fix_connection_id
                             where fmj.date_id = co.create_date_id
                               and fmj.fix_message_id = co.fix_message_id
                             limit 1)
                   when left(dclp.lp_priority, 1) = '2' and fc.fix_comp_id = 'IMCCONS'
                       then (select (fix_message ->> '10231'::text)::bigint
                             from dwh.flat_trade_record ftr
                                      join fix_capture.fix_message_json fmj
                                           on ftr.trade_fix_message_id = fmj.fix_message_id and
                                              ftr.date_id = fmj.date_id
                             where ftr.date_id >= co.create_date_id
                               and ftr.order_id = co.order_id
                             limit 1)
            end                                      as                                                     rfr_id
             , co.internal_order_id
        --,  co.*
        from dwh.client_order co
                 left join dwh.d_account ac on co.account_id = ac.account_id
                 left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
                 left join dwh.d_opt_exec_broker eb on co.opt_exec_broker_id = eb.opt_exec_broker_id
                 left join lateral
            ( select oa.auction_id -- как вариант, еще сгруппировать все аукционы ордера
              from dwh.client_order2auction oa
              where oa.create_date_id >= l_create_date_id
                and oa.order_id = co.order_id
              order by oa.rfq_transact_time
              limit 1 -- parent OFP orders can participate in thousands of auctions
            ) auc on true
                 left join dwh.d_instrument i on co.instrument_id = i.instrument_id
                 left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id
                 left join lateral
            ( select ex.exec_text
                   , ex.order_status
                   , ex.exec_id
                   , ex.leaves_qty
                   , ex.exec_time
              from dwh.execution ex
              where ex.exec_date_id >= l_create_date_id -- l_order_create_date_id --
                and ex.exec_date_id >= co.create_date_id
                and ex.order_id = co.order_id
              order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
              limit 1
            ) ex on true
                 left join lateral
            ( select max(tr.date_id)                                                                   as date_id
                   , sum(tr.last_qty)                                                                  as exec_qty
                   , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4)                        as avg_px
                   , sum(tr.principal_amount)                                                          as principal_amount
                   , min(tr.trade_record_time)                                                         as first_fill_date_time
                   , max(tr.trade_record_id)                                                           as max_trade_record_id
                   , max(tr.transact_time)                                                             as latest_street_exec_time
                   , case when co.parent_order_id is null then tr.order_id else tr.street_order_id end as order_id
              from dwh.flat_trade_record tr
              where 1 = 1                                         -- try to calculate for both parent and street level orders
                and tr.order_id = case
                                      when co.parent_order_id is null then co.order_id
                                      else co.parent_order_id end -- trade filter by parent level for both levels of orders
                and co.order_id = case
                                      when co.parent_order_id is null then tr.order_id
                                      else tr.street_order_id end -- trade filter for street level !!!
                and tr.date_id >= l_create_date_id
                and tr.is_busted = 'N'
              group by /*tr.date_id,*/ case when co.parent_order_id is null then tr.order_id else tr.street_order_id end
            --limit 1
            ) trd ON true
                 left join lateral
            ( select max(ex.exec_time) as exec_time
              from dwh.client_order str
                       inner join dwh.execution ex on str.order_id = ex.order_id and ex.exec_date_id >= l_create_date_id
              where 1 = 1
                and co.order_id = str.parent_order_id
                and str.create_date_id >= l_create_date_id
            ) str on true
                 left join consolidator.d_cons_lp_priority dclp on dclp.liquidity_provider_id = co.liquidity_provider_id
        where co.create_date_id = l_create_date_id
          -- and co.multileg_reporting_type in ('1','2') -- PD commented on 03/09/21 because of SD request
          and co.order_id = in_order_id
        limit 10000;
    --GET DIAGNOSTICS row_cnt = ROW_COUNT;

    --select public.load_log(l_load_id, l_step_id, 'orders returned cnt', row_cnt, 'O')
    --into l_step_id;

    --select public.load_log(l_load_id, l_step_id, 'dash360.order_blotter_get_order_details COMPLETE===', 0, 'O')
    --into l_step_id;

END;
$$;


-- select * from dash360.order_chain_for_order_id(in_order_id := 1, in_is_start_from_current := 'Y');
CREATE or replace FUNCTION dash360.order_chain_for_order_id(in_order_id bigint, in_is_start_from_current character)
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
$$
-- #variable_conflict use_column
declare
l_date_id int;
l_start_order_id bigint;
    l_min_create_date_id int4;

begin
--    raise notice 'start - %', clock_timestamp();
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
	select min(order_id)
	into l_start_order_id
	from
	(
		select order_id from min_hist_o
		union all
		select order_id from min_hist_co
	) x;
	else
		l_start_order_id := in_order_id;
	end if;
-- raise notice 'l_start_order_id - %, %', l_start_order_id, clock_timestamp();


    create temp table t_all_hist_o on commit drop as
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
--    raise notice 't_all_hist_o - %', clock_timestamp();

    create temp table t_all_hist_co on commit drop as
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

    create temp table t_cte_cross_order on commit drop as
    select *
    from dwh.cross_order cor
--where cor.cross_order_id in (select order_id from all_hist_o)
    where cor.cross_order_id = any
          (string_to_array((select string_agg(order_id::text, ',') from t_all_hist_o), ',')::bigint[]);
--    raise notice 't_cte_cross_order - %', clock_timestamp();

    create temp table t_cte_algo_order_tca on commit drop as
    select *
    from eq_tca.algo_order_tca
--where order_id in (select order_id from all_hist_o)
    where order_id = any (string_to_array((select string_agg(order_id::text, ',') from t_all_hist_o), ',')::bigint[]);
--    raise notice 't_cte_algo_order_tca - %', clock_timestamp();

    create temp table t_cte_client_order on commit drop as
    select *
    from dwh.client_order
--where order_id in (select order_id from all_hist_o)
    where order_id = any (string_to_array((select string_agg(order_id::text, ',') from t_all_hist_o), ',')::bigint[]);
--    raise notice 't_cte_client_order - %', clock_timestamp();

    select coalesce(min(create_date_id), 20200101)
    into l_min_create_date_id
    from t_cte_client_order;

    return query
SELECT EX.EXEC_ID,
       CO.ORDER_ID                                                                                               "OrderID",
       case
           when EX.EXEC_TYPE in ('Y', 'y')
               then fmj.tag_11
           else CO.CLIENT_ORDER_ID
           end                                                                                                as "ClOrdID",
       case
           when EX.EXEC_TYPE in ('Y', 'y')
               then fmj.tag_41
           when EX.EXEC_TYPE = 'D' then null
           else COORIG.CLIENT_ORDER_ID
           end                                                                                                as "OrigClOrdID",                -- case when EX.EXEC_TYPE = 'D' then null else COORIG.CLIENT_ORDER_ID end as "OrigClOrdID"
       CO.ORDER_CLASS                                                                                            "OrderClass",
       CO.PARENT_ORDER_ID                                                                                        "CustomerOrderID",
       EX.EXEC_ID                                                                                                "ExecID",
       EX.REF_EXEC_ID                                                                                            "RefExecID",
       CO.INSTRUMENT_ID                                                                                          "InstrumentID",
       HSD.SYMBOL                                                                                                "Symbol",                     --10
       HSD.InstrumentType                                                                                        "InstrumentType",
       HSD.MaturityYear                                                                                          "MaturityYear",
       HSD.MaturityMonth                                                                                         "MaturityMonth",
       HSD.MaturityDay                                                                                           "MaturityDay",
       HSD.PutCall                                                                                               "PutCall",
       HSD.StrikePx                                                                                              "StrikePx",
       HSD.OPRASymbol                                                                                            "OPRASymbol",
       HSD.DisplayInstrumentID                                                                                   "DisplayInstrumentID",
       HSD.UnderlyingDisplayInstrID                                                                              "UnderlyingDisplayInstrID",
       CO.CREATE_TIME                                                                                            "OrderCreationTime",          --20
       EX.EXEC_TIME                                                                                              "TransactTime",
       fmj.pg_db_create_time                                                                                     "LogTime",                    --22
       CO.PROCESS_TIME                                                                                           "RoutedTime",
       CO.ORDER_TYPE_ID                                                                                          "OrderType",                  --24
       CO.SIDE                                                                                                   "Side",
       CO.ORDER_QTY::int                                                                                         "OrderQty",
       CO.PRICE                                                                                                  "Price",
       CO.STOP_PRICE                                                                                             "StopPx",
       CO.TIME_IN_FORCE_ID                                                                                       "TimeInForce",                --29
       CO.EXPIRE_TIME                                                                                            "ExpireTime",
       CO.OPEN_CLOSE                                                                                             "OpenClose",                  --31
       CO.EX_DESTINATION                                                                                         "ExDestination",
       CO.HANDL_INST                                                                                             "HandlInst",                  --33
       CO.EXEC_INSTRUCTION                                                                                       "ExecInst",
       CO.MAX_SHOW_QTY::int                                                                                      "MaxShowQty",
       CO.MAX_FLOOR                                                                                              "MaxFloorQty",
       CASE
           WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CO.CLEARING_FIRM_ID
           ELSE CO.CLEARING_FIRM_ID
           END                                                                                                   "ClearingFirmID",             -- 37
--    ACC.OPT_IS_FIX_EXECBROK_PROCESSED,
       CASE
           WHEN HSD.InstrumentType = 'E' THEN NULL
           WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
               then coalesce(CO.OPT_EXEC_BROKER_ID, OPX.OPT_EXEC_BROKER_ID)
           WHEN CO.PARENT_ORDER_ID IS null and ACC.OPT_IS_FIX_EXECBROK_PROCESSED <> 'Y' then OPX.OPT_EXEC_BROKER_ID
           ELSE CO.OPT_EXEC_BROKER_ID
           END                                                                                                   "ExecBroker",
       --we store value in CLIENT_ORDER for all cases
       case
           when CO.PARENT_ORDER_ID is null then co.customer_or_firm_id
           else NULL end                                                                                         "CustomerOrFirm",             --39
       CO.EQ_ORDER_CAPACITY                                                                                      "OrderCapacity",--40
       -- in order to display MPID used for routing, not sent by client
       case when HSD.InstrumentType = 'E' then ACC.EQ_MPID else null end                                         "MarketParticipantID",        --41
       CO.LOCATE_REQ                                                                                             "IsLocateRequired",
       CO.LOCATE_BROKER                                                                                          "LocateBroker",
       EX.EXEC_TYPE                                                                                              "ExecType",                   --44
       EX.ORDER_STATUS                                                                                           "OrderStatus",                --45
       -- reject reason should be selected for rejects and Cancels only
       case when EX.EXEC_TYPE = '8' then EX.exec_text else null end                                                  "RejectReason",
       EX.LEAVES_QTY                                                                                             "LeavesQty",                  --47
       (ex_less.sum_last_qty)::bigint                                                                         as "CumQty",                     --48
       case
           when ex_less.sum_last_qty != 0 then
               ex_less.sum_last_qty_last_px / case
                                                  when ex_less.sum_last_qty = 0 then 1
                                                  else ex_less.sum_last_qty end end as "AvgPx", --49
       EX.LAST_QTY::int                                                                "LastQty", --50
       EX.LAST_PX                                                                                                "LastPx",                     --51
       --in order to provide correct displaying of Arca ortions
       CASE
           WHEN EX.EXEC_TYPE NOT IN ('F', 'G', 'D')
               THEN NULL
           WHEN CO.PARENT_ORDER_ID IS NULL
               THEN EX.LAST_MKT
           ELSE CO.EX_DESTINATION
           END                                                                                                   "LastMkt",                    --52
       (CO.ORDER_QTY - EX.CUM_QTY + coalesce(eq.sum_last_qty, 0))::bigint                                     as "DayOrderQty",                --53
       coalesce(eq.sum_last_qty, 0)::bigint                                                                   as "DayCumQty",                  --54
       round(coalesce(eq.sum_last_qty_last_px / case
                                     when eq.sum_last_qty = 0 then 1
                                     else eq.sum_last_qty end, 0), 4)                                         as "DayAvgPx",
       CO.ACCOUNT_ID::int                                                                                        "AccountID",                  --56
       EX.TRADE_LIQUIDITY_INDICATOR                                                                              "TradeLiquidityIndicator",    --57
       CO.MULTILEG_REPORTING_TYPE                                                                                "MultilegReportingType",      --58
--    COL.CLIENT_LEG_REF_ID "LegRefID", --59
--    COL.MULTILEG_ORDER_ID "MultilegOrderID", --60
       CO.co_client_leg_ref_id                                                                                   "LegRefID",                   --59
       CO.MULTILEG_ORDER_ID                                                                                      "MultilegOrderID",            --60
       FC.FIX_COMP_ID                                                                                            "FixCompID",                  --sending firm
       CO.CLIENT_ID_TEXT                                                                                         "ClientID",                   --62
       EX.exec_text                                                                                                  "Text",                       --63
       CASE
           WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
               THEN 'Y'::varchar
           ELSE 'N'::varchar
           END                                                                                                   "IsOSROrder",                 --64
       coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID)                                                "OSROrderID",                 --65
       CO.SUB_STRATEGY_DESC                                                                                      "SubStrategy",                --66
       CO.ALGO_STOP_PX                                                                                           "AlgoStopPx",
       CO.ALGO_CLIENT_ORDER_ID                                                                                   "AlgoClOrdID",                --68
       CO.TRANS_TYPE                                                                                             "TransType",                  --69
       CO.DASH_CLIENT_ORDER_ID                                                                                   "DashClOrdID",
       CO.CROSS_ORDER_ID                                                                                         "CrossOrderID",
       CO.OCC_OPTIONAL_DATA                                                                                      "OCCOptionalData",
       CO.SUB_STRATEGY_DESC                                                                                      "SubSystemID",
       CO.TRANSACTION_ID                                                                                         "TransactionID",
       CO.TOT_NO_ORDERS_IN_TRANSACTION                                                                           "TotNoOrdersInTransaction",   --75
       CO.EXCHANGE_ID                                                                                            "ExchangeID",                 --76
       CO.FEE_SENSITIVITY                                                                                        "FeeSensitivity",             --77
       CO.ON_BEHALF_OF_SUB_ID                                                                                    "OnBehalfOfSubID",            --78
       CO.strtg_decision_reason_code                                                                             "StrategyDecisionReasonCode", --79
       CO.INTERNAL_ORDER_ID                                                                                      "InternalOrderID",            --80
       CO.ALGO_START_TIME                                                                                        "AlgoStartTime",              --81
       CO.ALGO_END_TIME                                                                                          "AlgoEndTime",                --82
       al.MIN_TARGET_QTY::int                                                                                    "MinTargetQty",               --83
       CO.extended_ord_type                                                                                      "ExtendedOrdType",            --84
       CO.PRIM_LISTING_EXCHANGE                                                                                  "PrimListingExchange",        --85
       CO.POSTING_EXCHANGE                                                                                       "PostingExchange",            --86
       CO.PRE_OPEN_BEHAVIOR                                                                                      "PreOpenBehavior",            --87
       CO.MAX_WAVE_QTY_PCT                                                                                       "MaxWaveQtyPct",              --88
       CO.SWEEP_STYLE                                                                                            "SweepStyle",                 --89
       CO.DISCRETION_OFFSET                                                                                      "DiscretionOffset",           --90
       CRO.CROSS_TYPE                                                                                            "CrossType",                  --91
       CO.AGGRESSION_LEVEL                                                                                       "AggressionLevel",            --92
       CO.HIDDEN_FLAG                                                                                            "HiddenFlag",                 --93
       CO.QUOTE_ID                                                                                               "QuoteID",
       CO.STEP_UP_PRICE_TYPE                                                                                     "StepUpPriceType",            --95
       CO.STEP_UP_PRICE                                                                                          "StepUpPrice",
       CO.CROSS_ACCOUNT_ID::int4                                                                                 "CrossAccountID",
       CO.CLEARING_ACCOUNT                                                                                       "ClearingAccount",            --98
       CO.SUB_ACCOUNT                                                                                            "SubAccount",
       CO.REQUEST_NUMBER                                                                                         "RequestNumber",              --100
       CO.LIQUIDITY_PROVIDER_ID                                                                                  "LiquidityProviderID",
       CO.INTERNAL_COMPONENT_TYPE                                                                                "InternalComponentType",      --102
       CO.COMPLIANCE_ID                                                                                          "ComplianceID",
       CO.ALTERNATIVE_COMPLIANCE_ID                                                                              "AlternativeComplianceID",
       CO.CONDITIONAL_CLIENT_ORDER_ID::varchar                                                                   "ConditionalClientOrderID",
       'N'::varchar                                                                                              "IsConditionalOrder",         --106
       EX.exch_exec_id                                                                                        as "ExchExecID"
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
         LEFT JOIN t_cte_client_order COORIG ON (CO.ORIG_ORDER_ID = COORIG.ORDER_ID)
    left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = co.opt_exec_broker_id and opx.is_active
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

  SELECT
    EX.EXEC_ID, --1
    CO.ORDER_ID "OrderID", --2
    case when EX.EXEC_TYPE in ('Y','y')
    	   then fmj.tag_11
			else CO.CLIENT_ORDER_ID
	end as "ClOrdID",
    case when EX.EXEC_TYPE in ('Y','y')
    	   then fmj.tag_41
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
    fmj.pg_db_create_time "LogTime", --22
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
    ex_less.sum_last_qty::bigint "CumQty", --48
    --EX.AVG_PX "AvgPx",

      CASE
        WHEN ex_less.sum_last_qty = 0
        THEN NULL
        ELSE ex_less.sum_last_qty_last_px/case when ex_less.sum_last_qty = 0 then 1 else ex_less.sum_last_qty end
      END "AvgPx", --49
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
coalesce(eq.sum_last_qty, 0)::bigint "DayOrderQty", --53
coalesce(eq.sum_last_qty, 0)::bigint "DayCumQty", --54
ROUND(coalesce(eq.sum_last_qty_last_px/case when eq.sum_last_qty = 0 then 1 else eq.sum_last_qty end, 0), 4) "DayAvgPx", --55
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
  FROM t_all_hist_co coo
  JOIN dwh.CONDITIONAL_ORDER CO ON CO.ORDER_ID = coo.order_id
      join dwh.CONDITIONAL_EXECUTION EX on ex.order_id = coo.order_id
  left join data_marts.d_sub_strategy dss on dss.sub_strategy_id = co.sub_strategy_id
  JOIN lateral
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
		WHERE I.INSTRUMENT_ID = CO.INSTRUMENT_ID and I.INSTRUMENT_TYPE_ID IN ('E','O','M')
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
                            and fm.date_id >= l_min_create_date_id
                            limit 1) fmj on true
           left join lateral (SELECT SUM(EQ.LAST_QTY)              as sum_last_qty,
                                   SUM(EQ.LAST_QTY * EQ.LAST_PX) as sum_last_qty_last_px
                            FROM dwh.CONDITIONAL_EXECUTION EQ
                            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
                              AND EQ.IS_BUSTED <> 'Y'
                              AND EQ.ORDER_ID = CO.ORDER_ID
                              AND EQ.EXEC_ID <= EX.EXEC_ID
                            and eq.date_id >= l_min_create_date_id
                            group by eq.order_id
                            limit 1) ex_less on true
           left join lateral (SELECT SUM(EQ.LAST_QTY)              as sum_last_qty,
                                   SUM(EQ.LAST_QTY * EQ.LAST_PX) as sum_last_qty_last_px
                            FROM dwh.CONDITIONAL_EXECUTION EQ
                            WHERE EQ.EXEC_TYPE IN ('F', 'G', 'D')
                              AND EQ.IS_BUSTED <> 'Y'
                              AND EQ.ORDER_ID = CO.ORDER_ID
                              AND to_char(EX.EXEC_TIME, 'YYYYMMDD') = to_char(EQ.EXEC_TIME, 'YYYYMMDD')
                            and EQ.date_id >= l_min_create_date_id
                            group by eq.order_id
                            limit 1) eq on true
  WHERE 1=1
  --and EX.ORDER_STATUS <> '3'
AND co.order_id in (select order_id from t_all_hist_co)
order by exec_id;

--raise notice 'finish - %', clock_timestamp();
end;
$$;

-- select * from dash360.report_compliance_parent_orders();
CREATE or replace FUNCTION dash360.report_compliance_parent_orders(trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                        account_ids bigint[] DEFAULT '{}'::bigint[],
                                                        start_date_id integer DEFAULT NULL::integer,
                                                        end_date_id integer DEFAULT NULL::integer,
                                                        p_client_id character varying DEFAULT NULL::character varying,
                                                        p_mode character DEFAULT 'A'::character(1))
    RETURNS TABLE
            (
                trading_firm_name     character varying,
                account_name          character varying,
                routed_time           timestamp without time zone,
                event_time            timestamp without time zone,
                order_status          character varying,
                client_order_id       character varying,
                free_text             character varying,
                orig_client_order_id  character varying,
                ex_destination        character varying,
                instrument_type_id    character,
                symbol                character varying,
                customer_or_firm_name character varying,
                display_instrument_id character varying,
                last_trade_date       timestamp without time zone,
                side                  character,
                order_qty             integer,
                exec_qty              bigint,
                avg_px                numeric,
                price                 numeric,
                leaves_qty            bigint,
                exchange_id           character varying,
                sub_strategy          character varying,
                time_in_force         character varying,
                order_type            character varying,
                clearing_firm_id      character varying,
                max_floor             bigint,
                open_close            character,
                client_id             character varying,
                root_symbol           character varying,
                is_mleg               character,
                is_cross              character,
                max_show_qty          integer,
                market_participant_id character varying,
                create_time           timestamp without time zone,
                event_type            character varying,
                opt_exec_broker       character varying,
                exec_instruction      character varying,
                expire_time           timestamp without time zone,
                fee_sensitivity       integer,
                handle_inst           character varying,
                leg_id                character varying,
                locate_broker         character varying,
                occ_optional_data     character varying,
                order_capacty         character varying,
                osi_symbol            character varying,
                internal_order_id     bigint,
                stop_price            numeric
            )
    LANGUAGE plpgsql
    COST 1
    SET enable_material TO 'false'
    SET random_page_cost TO '1'
AS
$_$
DECLARE
    select_stmt text;
    sql_params  text;
begin

raise info '%: %',clock_timestamp(), 'Started';

   select  ' '
          ||case when trading_firm_ids<>'{}' then ' and  tf.trading_firm_id=any($3)' else '' end
          ||case when account_ids<>'{}' then ' and acc.account_id=any($4)' else '' end
          ||case when p_client_id is not null then ' and upper(co.client_id_text) = upper($5) ' else '' end
   into sql_params;

raise info '%: %',clock_timestamp(), 'SQL PARAM DONE';

select_stmt='select
  tf.trading_firm_name,
  acc.account_name,
  co.process_time as routed_time,
  ex.exec_time as event_time,
  ex.order_status,
  co.client_order_id,
  ex.exec_text as free_text,
  oco.client_order_id as orig_client_order_id,
  edc.ex_destination_code_name as ex_destination,
  i.instrument_type_id,
  i.symbol,
  cf.customer_or_firm_name,
  i.display_instrument_id,
  i.last_trade_date,
  co.side,
  co.order_qty,
  --ex.cum_qty as exec_qty::int8,
  --ex.avg_px,
  (case when ex.cum_qty = 0 then null else ex.cum_qty end)::int8 as exec_qty,
  (case when ex.avg_px = 0 then null else ex.avg_px end)::numeric as avg_px,
  co.price,
  ex.leaves_qty::int8,
  co.exchange_id,
  co.sub_strategy_desc as sub_strategy,
  tif.tif_name time_in_force,
  ot.order_type_name as order_type,
  fc.fix_comp_id clearing_firm_id,
  co.max_floor,
  co.open_close,
  co.client_id_text,
  oss.root_symbol as root_symbol,
  (case when co.multileg_reporting_type = ''1'' then ''N'' else ''Y'' end)::character as is_mleg,
  (case when co.cross_order_id is null then ''N'' else ''Y'' end)::character as is_cross,
  co.max_show_qty,
  co.market_participant_id,
  co.create_time,
  ex.exec_type as event_type,
  --co.opt_exec_broker_id,
  null::varchar as opt_exec_broker,
  co.exec_instruction,
  co.expire_time,
  co.fee_sensitivity::integer,
  co.handl_inst::varchar,
  co.co_client_leg_ref_id as leg_id,
  null::varchar as locate_broker,
  co.occ_optional_data,
  ocp.order_capacity_name as order_capacity,
  oct.opra_symbol as osi_symbol,
  co.internal_order_id,
  co.stop_price
from client_order co
left join d_ex_destination_code edc on edc.is_acitive = true and edc.ex_destination_code = co.ex_destination
inner join d_account acc on acc.account_id = co.account_id and acc.is_active
left join d_fix_connection fc ON fc.fix_connection_id = co.fix_connection_id
inner join d_trading_firm tf on tf.trading_firm_id = acc.trading_firm_id and tf.is_active
inner join d_instrument i on i.instrument_id = co.instrument_id /*and i.is_active*/
left join d_option_contract oct on oct.instrument_id = i.instrument_id /*and oct.is_active */
left join d_option_series oss on oss.option_series_id = oct.option_series_id
left join d_customer_or_firm cf on cf.customer_or_firm_id = co.customer_or_firm_id and cf.is_active
left join d_time_in_force tif on tif.tif_id = co.time_in_force_id and tif.is_active
left join d_order_type ot on ot.order_type_id = co.order_type_id
left join client_order oco on oco.order_id = co.orig_order_id
left join d_order_capacity ocp on ocp.order_capacity_id = co.eq_order_capacity
left join
        ( select tr.order_id
            , sum(tr.last_qty) as exec_qty
            , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as avg_px
          from dwh.flat_trade_record tr
          where tr.date_id between $1 and $2
            and tr.is_busted = ''N''
            and tr.account_id > 0
          group by tr.order_id
        ) trd on trd.order_id = co.order_id
left join lateral
        ( select ex.exec_text
            , et.exec_type_description as exec_type
            , os.order_status_description as order_status
            , ex.exec_id
            , ex.leaves_qty
            , ex.cum_qty
            , ex.avg_px
            , ex.exec_time
          from dwh.execution ex
          left join d_exec_type et on et.exec_type = ex.exec_type
          left join d_order_status os on os.order_status = ex.order_status
          where ex.exec_date_id between $1 and $2
            and ex.order_id = co.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
left join lateral
        ( select ex.exec_time
          from dwh.execution ex
          where ex.exec_date_id between $1 and $2
            and ex.order_id = co.order_id
          order by ex.exec_time asc, ex.exec_id asc -- first execution definition
          limit 1
        ) fex on true
where
  co.create_date_id between $1 and $2
  and co.parent_order_id is null
  and co.multileg_reporting_type in (''1'', ''2'')
  '||sql_params||' order by 1,3,2 ';

raise info '%: %',clock_timestamp(), select_stmt;

RETURN QUERY
execute select_stmt using start_date_id, end_date_id, trading_firm_ids, account_ids, p_client_id;

end;
$_$;

-- select * from dash_reporting.get_parent_orders_trade_activity();
CREATE or replace FUNCTION dash_reporting.get_parent_orders_trade_activity(p_accounts bigint[] DEFAULT '{}'::bigint[],
                                                                p_exchanges character varying[] DEFAULT '{}'::character varying[],
                                                                in_start_date_id integer DEFAULT NULL::integer,
                                                                in_end_date_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                client_order_id           character varying,
                exch_order_id             character varying,
                order_id                  bigint,
                side                      character,
                order_qty                 integer,
                price                     numeric,
                time_in_force             character varying,
                instrument_name           character varying,
                last_trade_date           timestamp without time zone,
                account_name              character varying,
                sub_system_id             character varying,
                multileg_reporting_type   character,
                exec_id                   bigint,
                ref_exec_id               bigint,
                exch_exec_id              character varying,
                "Exec_Time_Orig"          timestamp without time zone,
                exec_time                 text,
                "Exec_Type"               character varying,
                "Order_Status"            character varying,
                leaves_qty                bigint,
                cum_qty                   bigint,
                avg_px                    numeric,
                last_qty                  bigint,
                last_px                   numeric,
                bust_qty                  bigint,
                last_mkt                  character varying,
                last_mkt_name             character varying,
                text_                     character varying,
                trade_liquidity_indicator character varying,
                is_busted                 character,
                exec_broker               character varying,
                exchange_id               character varying,
                exchange_name             character varying
            )
    LANGUAGE plpgsql
    PARALLEL SAFE
AS
$$
begin

RETURN QUERY
	Select
	co.client_order_id --1
	, co.exch_order_id
	, ex.order_id
	, co.side
	, co.order_qty
	, co.price
	, tif.tif_short_name
	, inst.instrument_name
	, inst.last_trade_date
	, acc.account_name --10
	, dss.sub_system_id
	, co.multileg_reporting_type
	, ex.exec_id
	, ex.ref_exec_id
	, ex.exch_exec_id
	, ex.exec_time
	, to_char(ex.exec_time, 'HH:MI:SS.MS')
	, et.exec_type_description
	, os.order_status_description
	, ex.leaves_qty --20
	, ex.cum_qty
	, ex.avg_px
	, ex.last_qty
	, ex.last_px
	, ex.bust_qty
	, ex.last_mkt
	, lm.last_mkt_name
	, ex.exec_text as text_
	, ex.trade_liquidity_indicator
	, ex.is_busted --30
	, ex.exec_broker
	, ex.exchange_id
	, e.exchange_name
	From dwh.execution ex
	INNER JOIN dwh.client_order co ON ex.order_id = co.order_id
	INNER JOIN dwh.d_account acc ON co.account_id = acc.account_id
	INNER JOIN dwh.d_instrument inst ON co.instrument_id = inst.instrument_id
	LEFT JOIN dwh.d_sub_system dss on co.sub_system_unq_id = dss.sub_system_unq_id
	LEFT JOIN dwh.d_time_in_force tif ON co.time_in_force_id = tif.tif_id
	LEFT JOIN dwh.d_order_status os ON os.order_status = ex.order_status
	LEFT JOIN dwh.d_last_market lm ON lm.last_mkt = ex.last_mkt AND lm.is_active = true
	LEFT JOIN dwh.d_exchange e ON e.exchange_id = ex.exchange_id AND e.is_active = true
	LEFT JOIN dwh.d_exec_type et ON et.exec_type = ex.exec_type
	Where ex.exec_type In ('F','H')
	AND (p_accounts IS NULL OR co.account_id = any(p_accounts))
	AND (p_exchanges IS null OR ex.exchange_id = any(p_exchanges))
	And ex.exec_date_id  >= in_start_date_id
	And ex.exec_date_id < in_end_date_id
	And co.parent_order_id is null;
end;
$$;

-- select * from dash_reporting.get_street_orders_trade_activity();
CREATE or replace FUNCTION dash_reporting.get_street_orders_trade_activity(p_accounts bigint[] DEFAULT '{}'::bigint[],
                                                                p_exchanges character varying[] DEFAULT '{}'::character varying[],
                                                                in_start_date_id integer DEFAULT NULL::integer,
                                                                in_end_date_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                parent_client_order_id    character varying,
                client_order_id           character varying,
                exch_order_id             character varying,
                order_id                  bigint,
                side                      character,
                order_qty                 integer,
                price                     numeric,
                time_in_force             character varying,
                instrument_name           character varying,
                last_trade_date           timestamp without time zone,
                account_name              character varying,
                sub_system_id             character varying,
                multileg_reporting_type   character,
                exec_id                   bigint,
                ref_exec_id               bigint,
                exch_exec_id              character varying,
                "Exec_Time_Orig"          timestamp without time zone,
                exec_time                 text,
                "Exec_Type"               character varying,
                "Order_Status"            character varying,
                leaves_qty                bigint,
                cum_qty                   bigint,
                avg_px                    numeric,
                last_qty                  bigint,
                last_px                   numeric,
                bust_qty                  bigint,
                last_mkt                  character varying,
                last_mkt_name             character varying,
                text_                     character varying,
                trade_liquidity_indicator character varying,
                is_busted                 character,
                exec_broker               character varying,
                exchange_id               character varying,
                exchange_name             character varying
            )
    LANGUAGE plpgsql
    PARALLEL SAFE
AS
$$
begin
    RETURN QUERY
	Select
	po.client_order_id --1
	, co.client_order_id
	, co.exch_order_id
	, ex.order_id
	, co.side
	, co.order_qty
	, co.price
	, tif.tif_short_name
	, inst.instrument_name
	, inst.last_trade_date --10
	, acc.account_name
	, dss.sub_system_id
	, co.multileg_reporting_type
	, ex.exec_id
	, ex.ref_exec_id
	, ex.exch_exec_id
	, ex.exec_time
	, to_char(ex.exec_time, 'HH:MI:SS.MS')
	, et.exec_type_description
	, os.order_status_description --20
	, ex.leaves_qty
	, ex.cum_qty
	, ex.avg_px
	, ex.last_qty
	, ex.last_px
	, ex.bust_qty
	, ex.last_mkt
	, lm.last_mkt_name
	, ex.exec_text as text_
	, ex.trade_liquidity_indicator --30
	, ex.is_busted
	, ex.exec_broker
	, ex.exchange_id
	, e.exchange_name
	From dwh.execution ex
	INNER JOIN dwh.client_order co ON co.order_id = ex.order_id
	INNER JOIN dwh.client_order po ON po.order_id = co.parent_order_id
	INNER JOIN dwh.d_account acc ON co.account_id = acc.account_id
	INNER JOIN dwh.d_instrument inst ON co.instrument_id = inst.instrument_id
	LEFT JOIN dwh.d_sub_system dss on co.sub_system_unq_id = dss.sub_system_unq_id
	LEFT JOIN dwh.d_time_in_force tif ON co.time_in_force_id = tif.tif_id
	LEFT JOIN dwh.d_order_status os ON os.order_status = ex.order_status
	LEFT JOIN dwh.d_last_market lm ON lm.last_mkt = ex.last_mkt AND lm.is_active = true
	LEFT JOIN dwh.d_exchange e ON e.exchange_id = ex.exchange_id AND e.is_active = true
	LEFT JOIN dwh.d_exec_type et ON et.exec_type = ex.exec_type
	Where ex.exec_type In ('F','H')
	AND (p_accounts IS NULL OR co.account_id = ANY(p_accounts))
	AND (p_exchanges IS NULL OR ex.exchange_id = ANY(p_exchanges))
	AND ex.exec_date_id  >= in_start_date_id
	AND ex.exec_date_id < in_end_date_id
	AND co.parent_order_id IS NOT NULL;
end;
$$;



-- select * from data_marts.load_ats_cons_inc();
CREATE or replace FUNCTION data_marts.load_ats_cons_inc(in_order_ids bigint[] DEFAULT NULL::bigint[], in_recalc_date_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
   l_row_cnt integer;

   l_load_id int;
   l_step_id int;

   l_orig_order_ids bigint[];
   l_load_batch_arr integer[];

   l_cur_date_id integer;
   l_gtc_min_date_id integer;
   l_etl_min_date_id integer;
   l_min_order_create_date_id integer;

   l_foreign_order_id bigint;
   l_local_order_id bigint;
   l_local_rfq_id  bigint;

   l_sql varchar;

BEGIN
  /*
    we don't need to run this AFTER the HODS processed.
  */

  --if in_recalc_date_id is null
  --then return -1;
  --end if;

  select nextval('public.load_timing_seq') into l_load_id;

  l_step_id:=1;

  select public.load_log(l_load_id, l_step_id, 'load_ats_cons_inc STARTED===', 0, 'O')
   into l_step_id;


   -- Variables definition
   l_cur_date_id   := coalesce(in_recalc_date_id, to_char(current_date, 'YYYYMMDD')::integer);
   l_etl_min_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '1 day', 'YYYYMMDD')::integer;
   l_gtc_min_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '30 days', 'YYYYMMDD')::integer;


  -- Temporary table definition
--  execute 'DROP TABLE IF EXISTS tmp_ats_cons_details;';

     execute 'CREATE TEMP TABLE IF NOT EXISTS tmp_ats_cons_details (
      dataset_id int8 NULL, -- from subscription
      auction_id int8 NULL, -- NK #1. Auction ID.
      auction_date_id int4 NULL,
      liquidity_provider_id varchar(9) NULL, -- Defined via FIX_CONNECTION and FIX_COMP_ID. Used for LPO orders.
      ofp_orig_order_id int8 NULL, -- order_id of auctions initiating OFP parent order. For multileg, mlrt of such ord = ''3'' and side = ''B''

      -- markers of orders groups
      is_ats bool NULL,
      is_cons bool NULL,
      --
      is_ofp_parent bool NULL, -- OFP originating parent orders.
      is_ofp_street bool NULL, -- OFP created crosses
      is_lpo_parent bool NULL, -- LPO responces
      is_lpo_street bool NULL, -- LPO created crosses

      -- order info
      order_id int8 NOT NULL,
      client_order_id varchar(256) NULL,
      parent_order_id int8 NULL,
      order_create_time timestamp without time zone NULL,
      create_date_id integer NOT NULL,
      order_price numeric(12,4) NULL,
      order_qty int4 NULL,
      order_type_id varchar(1) NULL,
      account_id int8 NULL,
      instrument_id int8 NULL,
      transaction_id int8 NULL,
      side varchar(1) NULL,
      multileg_reporting_type varchar(1) NULL, -- including mlrt=3 in temp.
      cross_order_id int8 NULL,
      client_id varchar(255) NULL,
      exchange_id varchar(6) NULL,
      fix_connection_id int4 NULL,
      fix_comp_id varchar(30) NULL,
      internal_component_type varchar(1) NULL,
      sub_system_id varchar(20) NULL,
      order_liquidity_provider_id varchar(9) NULL,
      exch_order_id varchar(128) NULL,
      exec_instruction varchar(128) NULL,
      strategy_decision_reason_code int2 NULL,
	  capacity_group_id int4 NULL,

      -- prepare some attributes for resp quality calculation
      resp_ofp_parent_order_side varchar(1) NULL,
      resp_ofp_parent_order_price numeric(12,4) NULL,
      is_marketable bpchar(1) NULL,
      resp_is_quality_response bool NULL, -- where resp price < nbbo ask price for a buy; resp price > nbbo bid price for a sell
      resp_is_good_response bool NULL, -- case when order price < resp price < nbbo ask price for a buy; order price > resp price > nbbo bid price for a sell
      resp_is_neutral_response bool NULL, -- case when resp price = nbbo ask price for a buy; resp price = nbbo bid price for a sell
      resp_is_bad_response bool NULL, -- case when resp price > nbbo ask price for a buy; resp price < nbbo bid price for a sell
      resp_is_great_response bool NULL, -- case when resp price <= order price for a buy; resp price >= order price for a sell
      resp_price_improve_pct numeric(12,4) NULL, -- ( 1 - (rsp.order_price - ((rsp.nbbo_ask_price + rsp.nbbo_bid_price)/2))::numeric / ((rsp.nbbo_ask_price - rsp.nbbo_bid_price)::numeric/2))*100 for a buy
      resp_size_impr_vs_nbbo bool NULL, -- case when rsp.order_qty > rsp.nbbo_ask_quantity then true else false end for a buy
      resp_size_impr_vs_nbbo_pct numeric(12,4) NULL, -- (rsp.order_qty::numeric/nullif(rsp.nbbo_ask_quantity,0)::numeric)*100 for a buy
      resp_match_qty int4 NULL, -- execution.match_qty when exec_type = M
      resp_avg_match_px numeric(12,4) NULL, -- execution.match_px when exec_type = M

      -- Market Data
      nbbo_bid_price numeric(12,4) NULL,
      nbbo_bid_quantity int4 NULL,
      nbbo_ask_price numeric(12,4) NULL,
      nbbo_ask_quantity int4 NULL,

      -- Order Status
      exec_text varchar(512) NULL, -- 58 tag of the last execution of order.
      filled_price numeric(12,4) NULL, -- avg_px
      filled_qty int4 NULL,  -- cum_qty, VOLUME, -- also need to recalculate if needed
      order_status varchar(1) NULL, -- last status
      principal_amount numeric(16,4) NULL,
      first_fill_date_time timestamp without time zone NULL,

      etl_max_ord_exec_id int8 NULL, -- to filter out up-to-date orders
      etl_max_ord_trade_tecord_id int8 NULL, -- to filter out up-to-date orders
      etl_max_md_transaction_id int8 NULL,  -- to filter out up-to-date orders
      CONSTRAINT "tmp_PK_tmp_ats_cons" PRIMARY KEY (order_id, auction_id, auction_date_id)
    )';

  execute 'truncate table tmp_ats_cons_details';




---------------------------------------------------------------------------------------------------------
-- MOCK RFQ when recalc
 if in_recalc_date_id is null
 then
 --1) Step 1.1.  f_rfq_details. incremental load

  -->> calculate max rfq_id we have on PG side.
    -- 1-st execution on the next day should find all gaps if they'll be found...
     l_local_rfq_id   := (select coalesce(max(q.rfq_id), -1) as local_rfq_id
                          from data_marts.f_rfq_details q
                          where q.auction_date_id = l_cur_date_id);

    select public.load_log(l_load_id, l_step_id, 'Step 1.1. f_rfq_details. date_id = '||l_cur_date_id::varchar||', l_local_rfq_id = '||l_local_rfq_id::varchar||', load_batch_id = '||l_load_id::varchar, 0 , 'O')
     into l_step_id;

  -->> take rfq_id diff to PG side
    INSERT INTO data_marts.f_rfq_details
      (
        rfq_leg_id
      , rfq_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_order_id
      , ofp_client_order_id
      , ofp_create_time
      , ofp_order_type
      , ofp_side
      , ofp_order_qty
      , ofp_order_price
      , ofp_leg_ref_id
      , ofp_account_id
      , ofp_sub_system_id
      , ofp_sub_strategy
      , ofp_internal_component_type
      , ofp_client_id
      , rfq_qty
      , rfq_multi_leg_side
      , rfq_multileg_reporting_type
      , rfq_transact_time
      , rfq_quote_type
      , rfq_min_response_qty
      , rfq_ratio_qty
      , ofp_fix_message_id
      , rfq_fix_message_id
      , ofp_instrument_id
      , rfq_instrument_id
      , ofp_transaction_id
      , rfq_transaction_id
      , ofp_fix_comp_id
      , rfq_fix_comp_id
      , ofp_fix_connection_id
      , rfq_fix_connection_id
      , is_ats_ofp_parent
      , is_consolidator_ofp_parent
      , rfq_nbbo_bid_price
      , rfq_nbbo_bid_quantity
      , rfq_nbbo_ask_price
      , rfq_nbbo_ask_quantity
      , is_maket_data_applied
      , load_batch_id)
    select
        RFQ_LEG_ID as rfq_leg_id -- UNIQUE KEY
      , RFQ_ID as rfq_id
      , AUCTION_ID as auction_id
      , auction_date_id::integer as auction_date_id
      , rfq_LIQUIDITY_PROVIDER_ID as liquidity_provider_id
      , rfq_ofp_order_id as ofp_order_id
      , CLIENT_ORDER_ID as ofp_client_order_id
      , to_timestamp(v.create_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as ofp_create_time
      , ORDER_TYPE as ofp_order_type
      , SIDE as ofp_side
      , ORDER_QTY as ofp_order_qty
      , PRICE as ofp_order_price
      , CO_CLIENT_LEG_REF_ID as ofp_leg_ref_id
      , ACCOUNT_ID as ofp_account_id
      , SUB_SYSTEM_ID as ofp_sub_system_id
      , SUB_STRATEGY as ofp_sub_strategy
      , INTERNAL_COMPONENT_TYPE as ofp_internal_component_type
      , CLIENT_ID as ofp_client_id
      , requested_qty as rfq_qty
      , requested_multi_leg_side as rfq_multi_leg_side
      , MULTILEG_REPORTING_TYPE as rfq_multileg_reporting_type
      , to_timestamp(v.rfq_transact_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as rfq_transact_time
      , quote_type as rfq_quote_type
      , min_response_qty as rfq_min_response_qty
      , ratio_qty as rfq_ratio_qty
      , FIX_MESSAGE_ID as ofp_fix_message_id
      , rfq_fix_message_id as rfq_fix_message_id
      , INSTRUMENT_ID as ofp_instrument_id
      , requested_instrument_id as rfq_instrument_id
      , order_transaction_id as ofp_transaction_id
      , rfq_transaction_id as rfq_transaction_id
      , FIX_COMP_ID as ofp_fix_comp_id
      , rfq_fix_comp_id as rfq_fix_comp_id
      , FIX_CONNECTION_ID as ofp_fix_connection_id
      , rfq_fix_connection_id as rfq_fix_connection_id
      , is_ats_ofp_parent::boolean as is_ats_ofp_parent
      , is_consolidator_ofp_parent::boolean as is_consolidator_ofp_parent
      , md.bid_price as rfq_nbbo_bid_price
      , md.bid_quantity as rfq_nbbo_bid_quantity
      , md.ask_price as rfq_nbbo_ask_price
      , md.ask_quantity as rfq_nbbo_ask_quantity
      , md.is_maket_data_applied
      , l_load_id as load_batch_id
    from staging.ats_rfq_daily_v v
      left join lateral
        (
          select md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
            , case when md.transaction_id > 0 then true end as is_maket_data_applied
          from dwh.l1_snapshot md
          where md.transaction_id = v.rfq_transaction_id
            and md.instrument_id = case when md.instrument_id > 0 then v.instrument_id else md.instrument_id end --v.instrument_id
            and md.exchange_id = 'NBBO'
            and md.start_date_id between l_etl_min_date_id and l_cur_date_id
            --and md.start_date_id = v.auction_date_id::integer
          limit 1
        ) md on true
     where 1=1
       and v.RFQ_ID >= l_local_rfq_id
       and v.auction_date_id::integer >= l_etl_min_date_id
       and not exists
      (
        select r.rfq_leg_id
        from data_marts.f_rfq_details r
        where r.auction_date_id = v.auction_date_id::integer -- unq idx used
          and r.auction_date_id >= l_etl_min_date_id
          and r.rfq_leg_id = v.rfq_leg_id
      )
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'inserted into data_marts.f_rfq_details  ', l_row_cnt , 'I')
     into l_step_id;

 --1) Step 1.2.  f_rfq_details. Missing Market Data lookup

   -- lookup into the orders array and at the end of procedure - invoke manual run for these orders
   l_orig_order_ids := array(
    select distinct q.ofp_order_id -- parent_originator order
    from data_marts.f_rfq_details q
      join lateral
        (
          select s.transaction_id
          from dwh.l1_snapshot s
          where s.start_date_id between l_etl_min_date_id and l_cur_date_id -- partition pruning
            and s.transaction_id = q.rfq_transaction_id
            and s.exchange_id = 'NBBO'
          limit 1
        ) md ON true
    where q.auction_date_id between l_etl_min_date_id and l_cur_date_id
      and q.is_maket_data_applied is null
      and q.rfq_transaction_id is not null
      -- and limitation to not process orders older than 1 hour
    )
    ;

  select public.load_log(l_load_id, l_step_id, 'Step 1.2. Look for missing Market data for RFQ', cardinality(l_orig_order_ids) , 'I')
     into l_step_id;

   --1) Step 1.3.  f_rfq_details. Manual run. Missing Market Data update.
    -- in this peculiar case we don't need merge. Simple Update will be enough.

 if cardinality(l_orig_order_ids) > 0 -- and in_manual_run

  then
    update data_marts.f_rfq_details trg
      set rfq_nbbo_bid_price    = s.bid_price
        , rfq_nbbo_bid_quantity = s.bid_quantity
        , rfq_nbbo_ask_price    = s.ask_price
        , rfq_nbbo_ask_quantity = s.ask_quantity
        , is_maket_data_applied = true
    from
      (
          select q.auction_date_id, q.rfq_leg_id, q.rfq_id
            , md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
            , case when md.transaction_id > 0 then true end as is_maket_data_applied
          from data_marts.f_rfq_details q
            join dwh.l1_snapshot md
              on md.transaction_id = q.rfq_transaction_id
              and md.instrument_id = case when md.instrument_id > 0 then q.rfq_instrument_id else md.instrument_id end
              and md.exchange_id = 'NBBO'
              and md.start_date_id between l_etl_min_date_id and l_cur_date_id
          where q.auction_date_id between l_etl_min_date_id and l_cur_date_id
            and q.ofp_order_id = any (l_orig_order_ids)
            and md.start_date_id = q.auction_date_id
      ) s
    where trg.auction_date_id between l_etl_min_date_id and l_cur_date_id
      and trg.is_maket_data_applied is null
      and trg.auction_date_id = s.auction_date_id
      and trg.rfq_leg_id = s.rfq_leg_id
      and trg.rfq_id = s.rfq_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Step 1.2. Maket Data updated in data_marts.f_rfq_details  ', l_row_cnt , 'U')
     into l_step_id;

  end if;

 --<< MOCK RFQ when recalc
 end if;


 -->> recalculate information for some date
 if in_recalc_date_id is not null  -- try to REcalculate the datamart for the pointed date

  then

  -- load auctions, not orders. We need to complete CONS auctions with OFP parent orders. And need to set the ofp_orig_order_id value
    INSERT INTO tmp_ats_cons_details
      ( dataset_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats
      , is_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select
        to_char(now(), 'YYMMDDHH24MI')::integer as dataset_id
      , a.auction_id as auction_id
      , a.auction_date_id as auction_date_id
      , coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) as liquidity_provider_id
      , rfq.ofp_order_id as ofp_orig_order_id -- on this step is only for ATS
      , case when ca.rfq_transact_time /*rfq.ofp_order_id*/ is not null then true end as is_ats
      , case when ca.rfq_transact_time /*rfq.ofp_order_id*/ is null then true end as is_cons
      , case when cl.parent_order_id is null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is null then true end as is_ofp_parent
      , case when cl.parent_order_id is not null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is null then true end as is_ofp_street
      , case when cl.parent_order_id is null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is not null then true end as is_lpo_parent
      , case when cl.parent_order_id is not null and coalesce(ats_lp.liquidity_provider_id, cons_pl.liquidity_provider_id) is not null then true end as is_lpo_street
      , ca.order_id as order_id
      , cl.client_order_id as client_order_id
      , cl.parent_order_id as parent_order_id
      , cl.create_time as order_create_time
      , cl.create_date_id as create_date_id
      , cl.price as order_price
      , cl.order_qty as order_qty
      , cl.order_type_id as order_type_id
      , cl.account_id as account_id
      , cl.instrument_id as instrument_id
      , cl.transaction_id as transaction_id
      , cl.side as side
      , cl.multileg_reporting_type as multileg_reporting_type
      , cl.cross_order_id as cross_order_id
      , cl.client_id_text as client_id
      , cl.exchange_id as exchange_id
      , cl.fix_connection_id as fix_connection_id
      , fc.fix_comp_id as fix_comp_id
      , cl.internal_component_type as internal_component_type
      , ss.sub_system_id as sub_system_id
      , cl.liquidity_provider_id as order_liquidity_provider_id
      , cl.exch_order_id as exch_order_id
      , cl.exec_instruction
      , cl.strtg_decision_reason_code as strategy_decision_reason_code
      , cf.capacity_group_id
    from
      (
        select ca.auction_id, count(1) as cnt
          , max(ca.create_date_id) as auction_date_id
          , min(ca.create_date_id) as min_order_create_date_id
        from dwh.client_order2auction ca
        where ca.create_date_id = l_cur_date_id -- date for recalculation
        group by ca.auction_id
      ) a
      join lateral
        (
          select ca.auction_id, ca.order_id
            , max(ca.rfq_transact_time) over (partition by ca.auction_id) as rfq_transact_time
          from dwh.client_order2auction ca
          where a.auction_id = ca.auction_id
            and ca.create_date_id between min_order_create_date_id and auction_date_id
          limit 10000 -- orders limit in one auction
        ) ca on true
      left join lateral
        (
          select rfq.auction_id, rfq.auction_date_id
            , rfq.ofp_order_id -- can be of mlrt 1 or 3
          from data_marts.f_rfq_details rfq
          where 1=1
            and rfq.auction_date_id = a.auction_date_id --
            and rfq.auction_id = a.auction_id
          limit 1
        ) rfq on true
      left join dwh.client_order cl
        on ca.order_id = cl.order_id
        and cl.create_date_id between a.min_order_create_date_id and a.auction_date_id
      left join dwh.d_account ac
        on cl.account_id = ac.account_id
      left join dwh.d_sub_system ss
        ON cl.sub_system_unq_id = ss.sub_system_unq_id
      -- parent lvl
      left join dwh.client_order po
        on cl.parent_order_id = po.order_id
      left join dwh.d_account pac
        on po.account_id = pac.account_id
      left join dwh.d_fix_connection fc
        on cl.fix_connection_id = fc.fix_connection_id
      left join
        (
          select ats_lp.fix_connection_id, max(ats_lp.liquidity_provider_id) as liquidity_provider_id
          from staging.lp_connection ats_lp
          where ats_lp.lp_connector_id = 'LPLB'
            and ats_lp.is_deleted = 'N'
          group by ats_lp.fix_connection_id
        ) ats_lp
        on coalesce(po.fix_connection_id, cl.fix_connection_id) = ats_lp.fix_connection_id
      left join staging.cons_lp2trading_firm cons_pl
        on coalesce(pac.trading_firm_id, ac.trading_firm_id) = cons_pl.trading_firm_id
      left join dwh.d_customer_or_firm cf
      	on cl.customer_or_firm_id = cf.customer_or_firm_id
    where 1=1
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.1 ATS + CONS recalculation('||l_cur_date_id::text||') loaded into TMP' , l_row_cnt , 'I')
    into l_step_id;



  else -- incremental load

 -- Step 2 Increment definition and calculations into the Temp table
 -- Step 2.1.  ATS + CONS subscriptions load

  l_load_batch_arr := array (select distinct load_batch_id
                             from public.etl_subscriptions
                             where 1=1
                               and subscription_name in ( 'ats_details' )
                               and source_table_name ='client_order2auction'
                               and not is_processed
                               and subscribe_time < now() - interval '15 seconds'
                               and subscribe_time >= to_timestamp(l_cur_date_id::varchar, 'YYYYMMDD')
                               and subscribe_time <  to_timestamp(l_cur_date_id::varchar, 'YYYYMMDD') + interval '1 day'
                             order by load_batch_id
                             limit 250
                            );

  select public.load_log(l_load_id, l_step_id, left('2.1. ATS_CONS_details load_batch_id array loaded: '||array_to_string(l_load_batch_arr,','), 200), cardinality(l_load_batch_arr), 'I')
   into l_step_id;

IF cardinality(l_load_batch_arr) > 0
then
 -- Step 2.2.  ATS + CONS auctions load from source
  -- load auctions, not orders. We need to complete CONS auctions with OFP parent orders. And need to set the ofp_orig_order_id value
    INSERT INTO tmp_ats_cons_details
      ( dataset_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats
      , is_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select s.dataset_id
      , v.auction_id
      , v.auction_date_id
      , v.liquidity_provider_id
      , v.ofp_orig_order_id
      , v.is_ats::boolean
      , v.is_cons::boolean
      , v.is_ofp_parent::boolean
      , v.is_ofp_street::boolean
      , v.is_lpo_parent::boolean
      , v.is_lpo_street::boolean
      , v.order_id
      , v.client_order_id
      , v.parent_order_id
      , to_timestamp(v.order_create_time, 'YYYYMMDD HH24:MI:SS.MS')::timestamp without time zone as order_create_time
      , left(v.order_create_time, 8)::integer as create_date_id
      , v.order_price
      , v.order_qty
      , v.order_type_id
      , v.account_id
      , v.instrument_id
      , v.transaction_id
      , v.side
      , v.multileg_reporting_type
      , v.cross_order_id
      , v.client_id
      , v.exchange_id
      , v.fix_connection_id
      , v.fix_comp_id
      , v.internal_component_type
      , v.sub_system_id
      , v.order_liquidity_provider_id
      , v.exch_order_id
      , v.exec_instruction
      , v.strategy_decision_reason_code
      , v.capacity_group_id
    from
      (
        select  s.auction_id
          , max(s.dataset_id) as dataset_id
        from dwh.client_order2auction s
        where s.dataset_id = any (l_load_batch_arr)   --- (ARRAY[126018501, 126018487, 126018477, 126018466, 126018454, 126018440, 126018428, 126018416, 126018405]) --
        group by s.auction_id
      ) s
      join lateral
        (
          select v.*
          from staging.ats_cons_stats_v v
          where 1=1
             and v.auction_id = s.auction_id
          limit 10000 -- up to ten thousand requests, responses and streets in one auction. It's the huge enough value
        ) v ON true
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.2 ATS + CONS loaded from source into TMP' , l_row_cnt , 'I')
    into l_step_id;

end if; --<< empty  l_load_batch_arr

 end if; --<< full date load or increment


 if (select count(1) from tmp_ats_cons_details limit 1) > 0
   then

 -- Step 2.3.  CONS lookup OFP parent orders
   -- Search for OFP parents via Consolidator OFP Streets
     -- we don't have CONS OFP parents in client_order2auction yet.
       -- in TMP we have whole auctions represented, so lookup of OFP parents will not take extra efforts.
    with cons_par as
      (
        select t.parent_order_id, t.auction_id, t.auction_date_id
        from tmp_ats_cons_details t
        where t.is_cons = true
          and t.is_ofp_street = true
        group by t.parent_order_id, t.auction_id, t.auction_date_id
        order by t.parent_order_id, t.auction_id
      )
    INSERT INTO tmp_ats_cons_details
      ( dataset_id
      , auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats
      , is_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select null as dataset_id
      , p.auction_id
      , p.auction_date_id
      , null as liquidity_provider_id
      , null as ofp_orig_order_id
      , null as is_ats
      , true as is_cons
      , true as is_ofp_parent
      , null as is_ofp_street
      , null as is_lpo_parent
      , null as is_lpo_street
      , ofp.order_id
      , ofp.client_order_id
      , ofp.parent_order_id
      , ofp.create_time as order_create_time
      , ofp.create_date_id
      , ofp.price as order_price
      , ofp.order_qty
      , ofp.order_type_id
      , ofp.account_id
      , ofp.instrument_id
      , ofp.transaction_id
      , ofp.side
      , ofp.multileg_reporting_type
      , ofp.cross_order_id
      , ofp.client_id_text
      , ofp.exchange_id
      , ofp.fix_connection_id
      , null as fix_comp_id
      , ofp.internal_component_type
      , ss.sub_system_id
      , ofp.liquidity_provider_id as order_liquidity_provider_id
      , ofp.exch_order_id
      , ofp.exec_instruction
      , ofp.strtg_decision_reason_code
      , null as capacity_group_id --? cf.capacity_group_id
    from cons_par p
      join dwh.client_order ofp
        ON p.parent_order_id = ofp.order_id
      left join dwh.d_sub_system ss
        ON ofp.sub_system_unq_id = ss.sub_system_unq_id
      left join dwh.d_customer_or_firm cf
      	on ofp.customer_or_firm_id = cf.customer_or_firm_id
    ON CONFLICT (auction_id, order_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.3 CONS OFP parent orders loaded' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 2.4.  CONS set the ofp_orig_order_id attribte.
   -- it is needed for CONS sources. ATS already has ofp_orig_order_id initiated via RFQ on the ORA source view
     -- for multilegs it = order_id of OFP multileg parent order (mlrt=3)
    update tmp_ats_cons_details t
      set ofp_orig_order_id = src.ofp_orig_order_id
    from
      (
        select s.auction_id, min(s.order_id) as ofp_orig_order_id
        from tmp_ats_cons_details s
        where s.is_ofp_parent = true
          and s.is_cons = true
          and s.multileg_reporting_type in ('1','3')
        group by s.auction_id
      ) src
    where t.ofp_orig_order_id is null -- only when is not set
      and t.auction_id = src.auction_id
      and t.is_cons = true -- for whole auction
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.4 CONS ofp_orig_order_id updated. Increment almost prepared.' , l_row_cnt , 'U')
    into l_step_id;

 -- Step 2.5. Set Price and Side of OFP parent order for LPO responses

    update tmp_ats_cons_details trg
      set resp_ofp_parent_order_side = src.side
        , resp_ofp_parent_order_price = src.order_price
    from
      (
        select ofp.ofp_orig_order_id, ofp.auction_id, ofp.auction_date_id, ofp.instrument_id
          , ofp.order_price, ofp.side
        from tmp_ats_cons_details ofp
        where is_ofp_parent = true
      ) src
    where trg.ofp_orig_order_id = src.ofp_orig_order_id
      and trg.auction_id = src.auction_id
      and trg.auction_date_id = src.auction_date_id
      and trg.instrument_id = src.instrument_id -- fix for miltilegs
      and trg.is_lpo_parent = true
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '2.5 Price and Side of OFP parent is set for LPO responses. Increment prepared.' , l_row_cnt , 'U')
    into l_step_id;

 -- Step 3. Extend dataset for statuses and market data recalculation
  -- As for now we have prepared increment withous statuses and market data
   --
 -- Step 3.1. Lookup descrepancy on filled price, filled qty - from trades or f_yield_capture
    -- insert into the same temp table
    insert into tmp_ats_cons_details
      (
        order_id
      , auction_id
      , auction_date_id
      , create_date_id
      , transaction_id
      , instrument_id
      , ofp_orig_order_id
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , is_ats
      , is_cons
      , liquidity_provider_id
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.liquidity_provider_id
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
      , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
       --, t.filled_qty
       --, tr.day_cum_qty
    from
      (
        select t.auction_date_id, t.order_id, coalesce(t.filled_qty, 0) as filled_qty
          , t.auction_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.order_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.liquidity_provider_id
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
          , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
        from data_marts.f_ats_cons_details t
        where t.auction_date_id = l_cur_date_id --
          --and t.pg_db_create_time > clock_timestamp() - interval '48 hour' -- 1 hour after pasting
          --and t.pg_dp_last_update_time is not null -- V.I. exclude rows revently added
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
      ) t
      left join lateral
        (
          select tr.order_id, sum(tr.last_qty) as day_cum_qty
          from dwh.flat_trade_record tr
          where tr.date_id = l_cur_date_id --  20190328 --
            and tr.date_id = t.auction_date_id
            and ( (tr.order_id = t.order_id and (is_ofp_parent = true or is_lpo_parent = true))
                or (tr.street_order_id = t.order_id and (is_ofp_street = true or is_lpo_street = true)) )
          group by tr.order_id
        ) tr on true
    where t.rn=1 and t.filled_qty <> coalesce(tr.day_cum_qty, 0)
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.1 Lookup descrepancy on filled_price and filled qty.' , l_row_cnt , 'I')
    into l_step_id;


 -- Step 3.2. market data descrepancy - from l1_snapshot or maybe f_yield_capture
    insert into tmp_ats_cons_details
      (
        order_id
      , auction_id
      , auction_date_id
      , create_date_id
      , transaction_id
      , instrument_id
      , ofp_orig_order_id
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , is_ats
      , is_cons
      , liquidity_provider_id
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.liquidity_provider_id
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
      , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
    --select count(1)
    from
      (
        select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.auction_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.liquidity_provider_id
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
          , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
        from data_marts.f_ats_cons_details t
        where t.auction_date_id = l_cur_date_id -- 20190408 --
          -- and t.pg_db_create_time > clock_timestamp() - interval '24 hour' -- 1 hour after pasting
          -- and t.pg_dp_last_update_time is not null -- V.I. exclude rows recently added orders
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
          and t.etl_max_md_transaction_id is null
      ) t
      join lateral
        (
          select md.transaction_id
          from dwh.l1_snapshot md
          where md.start_date_id = l_cur_date_id -- 20190408 --
            and md.start_date_id = t.auction_date_id
            and md.transaction_id = t.transaction_id
            and md.exchange_id = 'NBBO'
          limit 1
        ) md on true
    where t.rn=1
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.2 Lookup descrepancy on Market Data.' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 3.3. order status descrepancy - from execution
    insert into tmp_ats_cons_details
      (
        order_id
      , auction_id
      , auction_date_id
      , create_date_id
      , transaction_id
      , instrument_id
      , ofp_orig_order_id
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , is_ats
      , is_cons
      , liquidity_provider_id
      , resp_ofp_parent_order_side
      , side
      , resp_ofp_parent_order_price
      , order_price
      , order_qty
      , multileg_reporting_type
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id
      )
    select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
      , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street
      , case when t.is_ats_or_cons = 'A' then true end as is_ats
      , case when t.is_ats_or_cons = 'C' then true end as is_cons
      , t.liquidity_provider_id
      , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
      , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
    --select count(1)
    from
      (
        select t.order_id, t.auction_id, t.auction_date_id, t.create_date_id, t.transaction_id, t.instrument_id
          , row_number() over (partition by t.order_id, t.auction_id order by t.auction_id) as rn
          , t.ofp_orig_order_id, t.is_ofp_parent, t.is_ofp_street, t.is_lpo_parent, t.is_lpo_street, t.is_ats_or_cons
          , t.liquidity_provider_id
          , t.resp_ofp_parent_order_side, t.side, t.resp_ofp_parent_order_price, t.order_price, t.order_qty, t.multileg_reporting_type
          , coalesce(t.order_status, '-1') as order_status
          , coalesce(t.etl_max_ord_exec_id, -1) as etl_max_ord_exec_id
          , t.exch_order_id, t.exec_instruction, t.strategy_decision_reason_code, t.capacity_group_id
        from data_marts.f_ats_cons_details t
        where t.auction_date_id = l_cur_date_id -- 20190408 --
          -- and t.pg_db_create_time > clock_timestamp() - interval '24 hour' -- 1 hour after pasting
          -- and t.pg_dp_last_update_time is not null -- V.I. exclude rows recently added orders
          and coalesce(t.pg_dp_last_update_time, clock_timestamp()) - t.pg_db_create_time <= interval '4 hour'
          and coalesce(t.order_status, '-1') not in ('2','4')
      ) t
      join lateral
        (
          select ex.exec_text
            , ex.order_status
            , ex.exec_id
          from dwh.execution ex
          where ex.exec_date_id = l_cur_date_id -- 20190328 --
            and ex.exec_date_id = t.auction_date_id
            and ex.order_id = t.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
    where t.rn=1 and t.etl_max_ord_exec_id <> ex.exec_id
    ON CONFLICT (order_id, auction_id, auction_date_id) DO NOTHING
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '3.3 Lookup descrepancy on Order Status.' , l_row_cnt , 'I')
    into l_step_id;


 -- Step 4. Update calculated status attributes in temp tbl

  -- define min orders create_date_id
  l_min_order_create_date_id := (select min(create_date_id) from tmp_ats_cons_details );

 -- Step 4.1. update orders with new status and quality information
  -- using temp table as a source of orders
    update tmp_ats_cons_details trg
      set nbbo_bid_price       = md.bid_price
        , nbbo_bid_quantity    = md.bid_quantity
        , nbbo_ask_price       = md.ask_price
        , nbbo_ask_quantity    = md.ask_quantity
        , exec_text            = ex.exec_text
        , filled_price         = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_price else tr_str.filled_price end --  as filled_price
        , filled_qty           = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_qty else tr_str.filled_qty end -- as filled_qty
        , order_status         = ex.order_status
        , principal_amount     = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.principal_amount else tr_str.principal_amount end -- as principal_amount
        , first_fill_date_time = case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.first_fill_date_time else tr_str.first_fill_date_time end -- as first_fill_date_time
        , etl_max_ord_exec_id  = ex.exec_id
        , etl_max_ord_trade_tecord_id = coalesce(tr_par.max_trade_record_id, tr_str.max_trade_record_id)
        , etl_max_md_transaction_id = md.transaction_id
        , is_marketable        = case when src.order_type_id = '1' then 'Y'
                                      when src.side in ('1','3') and src.order_price >= md.ask_price then 'Y'
                                      when src.side not in ('1','3') and src.order_price <= md.bid_price then 'Y'
                                      else 'N' end --as is_marketable
        --, pg_dp_last_update_time = clock_timestamp()
   /*   select
            md.bid_price
          , md.bid_quantity
          , md.ask_price
          , md.ask_quantity
          , ex.text_
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_price else tr_str.filled_price end --  as filled_price
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.filled_qty else tr_str.filled_qty end -- as filled_qty
          , ex.order_status
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.principal_amount else tr_str.principal_amount end -- as principal_amount
          , case when ( src.is_ofp_parent = true or src.is_lpo_parent = true ) then tr_par.first_fill_date_time else tr_str.first_fill_date_time end -- as first_fill_date_time
          , ex.exec_id
          , coalesce(tr_par.max_trade_record_id, tr_str.max_trade_record_id)
          , md.transaction_id  */
    from tmp_ats_cons_details as src
      -- market data
      left join lateral
        (
          select md.transaction_id, md.bid_price, md.bid_quantity, md.ask_price, md.ask_quantity
          from dwh.l1_snapshot md
          where md.start_date_id = l_cur_date_id -- 20190408 --
            and md.start_date_id = src.auction_date_id
            and md.transaction_id = src.transaction_id -- lookup key
            and md.instrument_id = case when md.instrument_id > 0 then src.instrument_id else md.instrument_id end
            and md.exchange_id = 'NBBO'
          limit 1
        ) md on true
      -- the last execution
      left join lateral
        (
          select ex.exec_text
            , ex.order_status
            , ex.exec_id
          from dwh.execution ex
          where ex.exec_date_id = l_cur_date_id -- 20190328 --
            and ex.exec_date_id = src.auction_date_id
            and ex.order_id = src.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      -- trades for street orders
      left join lateral
        (
          select sum(tr.last_qty) as filled_qty
            , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as filled_price
            , sum(tr.principal_amount) as principal_amount
            , min(tr.trade_record_time) as first_fill_date_time
            , max(tr.trade_record_id) as max_trade_record_id
          from dwh.flat_trade_record tr
          where 1=1
            and ( src.is_lpo_street = true or src.is_ofp_street = true ) -- street level
            and src.order_id = tr.street_order_id
            and tr.date_id >= l_min_order_create_date_id -- 20190328 --
            and tr.date_id <= src.auction_date_id
            and tr.is_busted = 'N'
          group by tr.street_order_id
          limit 1
        ) tr_str ON true
      -- trades for parent orders
      left join lateral
        (
          select sum(tr.last_qty) as filled_qty
            , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as filled_price
            , sum(tr.principal_amount) as principal_amount
            , min(tr.trade_record_time) as first_fill_date_time
            , max(tr.trade_record_id) as max_trade_record_id
          from dwh.flat_trade_record tr
          where 1=1 -- try to calculate for both ATS and CONS (maybe CONS will be calculated on the street executions)
            and ( src.is_ofp_parent = true or src.is_lpo_parent = true ) -- try to calc responses also
            and src.order_id = tr.order_id -- parent level
            and tr.date_id >= l_min_order_create_date_id -- 20190328 --
            and tr.date_id <= src.auction_date_id
            and tr.is_busted = 'N'
          group by tr.order_id
          limit 1
        ) tr_par ON true
    where 1=1
      and trg.order_id        = src.order_id
      and trg.auction_id      = src.auction_id
      and trg.auction_date_id = src.auction_date_id
      and trg.auction_date_id = l_cur_date_id -- 20190328 --
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '4.1 Market Data and Status updated in tmp.' , l_row_cnt , 'U')
    into l_step_id;

  -- Step 4.2. Recalculation of LPO parent orders(responses) quality
   -- блин, опять же это лучше сделать в темповой таблице, но тогда и статус апдейтать лучше в темповую таблицу
    -- лан, берем из темповой таблицы список ордеров, считаем
    with qlty as
      (
        select o.order_id, o.auction_id, o.auction_date_id
               -- is_quality_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.order_price < o.nbbo_ask_price then true else false end
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.order_price > o.nbbo_bid_price then true else false end
                           end -- end of sell response side
               end as resp_is_quality_response
               -- is_good_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.resp_ofp_parent_order_price is not null -- not market originator's order type
                                         then case when o.resp_ofp_parent_order_price < o.order_price and o.order_price < o.nbbo_ask_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price < o.nbbo_ask_price then true else false end
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.resp_ofp_parent_order_price is not null -- not market originator's order type
                                         then case when o.resp_ofp_parent_order_price > o.order_price and o.order_price > o.nbbo_bid_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price > o.nbbo_bid_price then true else false end
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
               end as resp_is_good_response
               -- is_neutral_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.order_price = o.nbbo_ask_price then true else false end
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.order_price = o.nbbo_bid_price then true else false end
                           end -- end of sell response side
               end as resp_is_neutral_response
               -- is_bad_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.order_price > o.nbbo_ask_price then true else false end
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.order_price < o.nbbo_bid_price then true else false end
                           end -- end of sell response side
               end as resp_is_bad_response
               -- is_great_response
             , case when o.resp_ofp_parent_order_side in ('1','3') -- parent buy order
                      then case
                             when o.side not in ('1','3')   -- responce side is opposite, i.g. sell
                             then case when o.resp_ofp_parent_order_price is not null -- not "market" originator's order type
                                         then case when o.order_price <= o.resp_ofp_parent_order_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price < o.nbbo_ask_price then true else false end -- ? left resp better then NBBO for "market order"??
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
                    when o.resp_ofp_parent_order_side not in ('1','3') -- parent sell order
                      then case
                             when o.side in ('1','3')   -- responce side is opposite, i.g. buy
                             then case when o.resp_ofp_parent_order_price is not null -- not market originator's order type
                                         then case when o.order_price >= o.resp_ofp_parent_order_price then true else false end
                                       else -- when originator's order type is "market"
                                         case when o.order_price > o.nbbo_bid_price then true else false end -- ? left resp better then NBBO for "market order"??
                                  end -- responce - sell order for buy originator
                           end -- end of sell response side
               end as resp_is_great_response
            -- responce, price improvement %. For ofp buy when resp price = nbb then -100%, when resp price = nbo then 100%, when resp price = mid nbbo then 0%
            , case when o.order_qty > 0 and o.nbbo_ask_price is not null and o.nbbo_bid_price is not null
                   then
                       case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy
                              then ( (o.order_price - ((o.nbbo_ask_price + o.nbbo_bid_price)/2))::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                            when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell
                              then ( (((o.nbbo_ask_price + o.nbbo_bid_price)/2) - o.order_price)::numeric / (nullif((o.nbbo_ask_price - o.nbbo_bid_price), 0)::numeric/2))*100
                       end
              end as resp_price_improve_pct
            -- size improvement vs nbbo count
            , case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy
                     then case when o.order_qty > o.nbbo_ask_quantity then true else false end
                   when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell
                     then case when o.order_qty > o.nbbo_bid_quantity then true else false end
              end as resp_size_impr_vs_nbbo
            -- size improvement vs nbbo %
            , case when o.resp_ofp_parent_order_side in ('1','3') and o.side not in ('1','3') -- ofp buy
                     then (o.order_qty::numeric/nullif(o.nbbo_ask_quantity,0)::numeric)*100
                   when o.resp_ofp_parent_order_side not in ('1','3') and o.side in ('1','3') -- ofp sell
                     then (o.order_qty::numeric/nullif(o.nbbo_bid_quantity,0)::numeric)*100
              end::numeric as resp_size_impr_vs_nbbo_pct
            -- match_qty. Based on executions. exec_type = 'M'
            , mth.resp_match_qty as resp_match_qty
            -- match_px. Based on executions. exec_type = 'M'
            , mth.resp_avg_match_px as resp_avg_match_px
        from tmp_ats_cons_details as o
          left join lateral
            (
              select sum(ex.match_qty)::integer as resp_match_qty, (sum(ex.match_qty*ex.match_px)/nullif(sum(ex.match_qty), 0))::numeric as resp_avg_match_px
              from dwh.execution ex
              where ex.order_id = o.order_id
                and ex.exec_date_id = o.auction_date_id
                and ex.exec_type = 'M'
                and ex.exec_date_id >= l_etl_min_date_id -- 20190327 --
              group by ex.order_id
            ) mth ON true
        where o.is_lpo_parent = true
      )
    update tmp_ats_cons_details trg
      set resp_is_quality_response   = src.resp_is_quality_response
        , resp_is_good_response      = src.resp_is_good_response
        , resp_is_neutral_response   = src.resp_is_neutral_response
        , resp_is_bad_response       = src.resp_is_bad_response
        , resp_is_great_response     = src.resp_is_great_response
        , resp_price_improve_pct     = src.resp_price_improve_pct
        , resp_size_impr_vs_nbbo     = src.resp_size_impr_vs_nbbo
        , resp_size_impr_vs_nbbo_pct = src.resp_size_impr_vs_nbbo_pct
        , resp_match_qty             = src.resp_match_qty
        , resp_avg_match_px          = src.resp_avg_match_px
    from qlty as src
    where 1=1
      and trg.order_id        = src.order_id
      and trg.auction_id      = src.auction_id
      and trg.auction_date_id = src.auction_date_id
      and trg.auction_date_id = l_cur_date_id -- 20190328 --
    ;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '4.2 Responses Quality updated in tmp.' , l_row_cnt , 'U')
    into l_step_id;


 -- Step 5. Add the increment + recalc into the datamart.
 -- Step 5.1. Merge the increment into the datamart. (update status, MD, quality if orders are existing)
  with src as
   (
    select
        auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , case when is_ats = true then 'A' when is_cons = true then 'C' end as is_ats_or_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , null::integer as ofp_parent_auctions_no
      , t.order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , t.instrument_id
      , i.instrument_type_id
      , i.display_instrument_id as display_instrument_id
      , ui.symbol as underlying_symbol
      , os.root_symbol as root_symbol
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , resp_ofp_parent_order_side
      , resp_ofp_parent_order_price
      -- other ETLs entities
      , nbbo_bid_price
      , nbbo_bid_quantity
      , nbbo_ask_price
      , nbbo_ask_quantity
      , exec_text
      , filled_price
      , filled_qty
      , order_status
      , principal_amount
      , first_fill_date_time
      , etl_max_ord_exec_id
      , etl_max_ord_trade_tecord_id
      , etl_max_md_transaction_id
      , is_marketable
      , resp_is_quality_response
      , resp_is_good_response
      , resp_is_neutral_response
      , resp_is_bad_response
      , resp_is_great_response
      , resp_price_improve_pct
      , resp_size_impr_vs_nbbo
      , resp_size_impr_vs_nbbo_pct
      , resp_match_qty
      , resp_avg_match_px
      , t.exch_order_id
      , t.exec_instruction
      , t.strategy_decision_reason_code
      , t.capacity_group_id
    from tmp_ats_cons_details t
      left join dwh.d_instrument i
        ON t.instrument_id = i.instrument_id
      left join dwh.d_option_contract oc
        ON t.instrument_id = oc.instrument_id
      left join dwh.d_option_series os
        ON oc.option_series_id = os.option_series_id
      left join dwh.d_instrument ui
        ON os.underlying_instrument_id = ui.instrument_id
    where t.multileg_reporting_type in ('1','2') -- in temp we also have '3' -- multilegs
      and t.auction_date_id = l_cur_date_id -- 20190408 --
     -- order by ofp_orig_order_id, auction_id, order_id
   )
   --select count(1) from src
    INSERT INTO data_marts.f_ats_cons_details
      ( auction_id
      , auction_date_id
      , liquidity_provider_id
      , ofp_orig_order_id
      , is_ats_or_cons
      , is_ofp_parent
      , is_ofp_street
      , is_lpo_parent
      , is_lpo_street
      , ofp_parent_auctions_no
      , order_id
      , client_order_id
      , parent_order_id
      , order_create_time
      , create_date_id
      , order_price
      , order_qty
      , order_type_id
      , account_id
      , instrument_id
      , instrument_type_id
      , display_instrument_id
      , underlying_symbol
      , root_symbol
      , transaction_id
      , side
      , multileg_reporting_type
      , cross_order_id
      , client_id
      , exchange_id
      , fix_connection_id
      , fix_comp_id
      , internal_component_type
      , sub_system_id
      , order_liquidity_provider_id
      , resp_ofp_parent_order_side
      , resp_ofp_parent_order_price
      -- other ETLs entities
      , nbbo_bid_price
      , nbbo_bid_quantity
      , nbbo_ask_price
      , nbbo_ask_quantity
      , exec_text
      , filled_price
      , filled_qty
      , order_status
      , principal_amount
      , first_fill_date_time
      , etl_max_ord_exec_id
      , etl_max_ord_trade_tecord_id
      , etl_max_md_transaction_id
      , is_marketable
      , resp_is_quality_response
      , resp_is_good_response
      , resp_is_neutral_response
      , resp_is_bad_response
      , resp_is_great_response
      , resp_price_improve_pct
      , resp_size_impr_vs_nbbo
      , resp_size_impr_vs_nbbo_pct
      , resp_match_qty
      , resp_avg_match_px
      , exch_order_id
      , exec_instruction
      , strategy_decision_reason_code
      , capacity_group_id)
    select * from src
    ON CONFLICT(auction_date_id, auction_id, order_id)
      DO UPDATE SET
          nbbo_bid_price              = EXCLUDED.nbbo_bid_price
        , nbbo_bid_quantity           = EXCLUDED.nbbo_bid_quantity
        , nbbo_ask_price              = EXCLUDED.nbbo_ask_price
        , nbbo_ask_quantity           = EXCLUDED.nbbo_ask_quantity
        , exec_text                   = EXCLUDED.exec_text
        , filled_price                = EXCLUDED.filled_price
        , filled_qty                  = EXCLUDED.filled_qty
        , order_status                = EXCLUDED.order_status
        , principal_amount            = EXCLUDED.principal_amount
        , first_fill_date_time        = EXCLUDED.first_fill_date_time
        , etl_max_ord_exec_id         = EXCLUDED.etl_max_ord_exec_id
        , etl_max_ord_trade_tecord_id = EXCLUDED.etl_max_ord_trade_tecord_id
        , etl_max_md_transaction_id   = EXCLUDED.etl_max_md_transaction_id
        , is_marketable               = EXCLUDED.is_marketable
        , resp_is_quality_response    = EXCLUDED.resp_is_quality_response
        , resp_is_good_response       = EXCLUDED.resp_is_good_response
        , resp_is_neutral_response    = EXCLUDED.resp_is_neutral_response
        , resp_is_bad_response        = EXCLUDED.resp_is_bad_response
        , resp_is_great_response      = EXCLUDED.resp_is_great_response
        , resp_price_improve_pct      = EXCLUDED.resp_price_improve_pct
        , resp_size_impr_vs_nbbo      = EXCLUDED.resp_size_impr_vs_nbbo
        , resp_size_impr_vs_nbbo_pct  = EXCLUDED.resp_size_impr_vs_nbbo_pct
        , resp_match_qty              = EXCLUDED.resp_match_qty
        , resp_avg_match_px           = EXCLUDED.resp_avg_match_px
        , pg_dp_last_update_time      = clock_timestamp()
        , liquidity_provider_id       = EXCLUDED.liquidity_provider_id
        , ofp_orig_order_id           = EXCLUDED.ofp_orig_order_id
        , is_ats_or_cons              = EXCLUDED.is_ats_or_cons
        , is_ofp_parent               = EXCLUDED.is_ofp_parent
        , is_ofp_street               = EXCLUDED.is_ofp_street
        , is_lpo_parent               = EXCLUDED.is_lpo_parent
        , is_lpo_street               = EXCLUDED.is_lpo_street
        , exch_order_id               = EXCLUDED.exch_order_id
        , exec_instruction               = EXCLUDED.exec_instruction
        , strategy_decision_reason_code  = EXCLUDED.strategy_decision_reason_code
        , capacity_group_id				 = EXCLUDED.capacity_group_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '5.1 Increment loaded into the datamart: data_marts.f_ats_cons_details.' , l_row_cnt , 'I')
    into l_step_id;

 -- Step 5.2. Renumerate OFP parent orders occurences on auctions.
/*    with src as
      (
        select t.auction_date_id, t.auction_id, t.order_id, t.ofp_parent_auctions_no_new
        from
          (
            select distinct s.order_id, s.auction_date_id
            from data_marts.f_ats_cons_details s
                 --tmp_ats_cons_details s
            where s.is_ofp_parent = true
              and s.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id  --
              --and s.ofp_parent_auctions_no is null
          ) s
          left join lateral
            (
              select t.auction_date_id, t.auction_id, t.order_id
                , row_number() over (partition by t.order_id order by t.auction_id) as ofp_parent_auctions_no_new
              from data_marts.f_ats_cons_details t
              where t.is_ofp_parent = true
                and t.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id --
                and t.auction_date_id = s.auction_date_id
                and t.order_id = s.order_id
              limit 10000 -- up to 10k auctions limitation per one OFP parent order per day.
            ) t ON true
      )
    update data_marts.f_ats_cons_details trg
      set ofp_parent_auctions_no = src.ofp_parent_auctions_no_new
    from src
    where trg.auction_date_id = src.auction_date_id
      and trg.auction_date_id = l_cur_date_id --
      and trg.auction_id = src.auction_id
      and trg.order_id = src.order_id
      and coalesce(trg.ofp_parent_auctions_no, -1) <> src.ofp_parent_auctions_no_new
      and trg.is_ofp_parent = true
    ;
*/

/*    update data_marts.f_ats_cons_details trg
      set ofp_parent_auctions_no = src.ofp_parent_auctions_no_new
    from
      (
        select s.auction_date_id, s.order_id
          , td.auction_id, td.ofp_parent_auctions_no_new
        from
          (
            select s.auction_date_id, s.order_id
            from data_marts.f_ats_cons_details s
                 --tmp_ats_cons_details s
            where s.is_ofp_parent = true
              and s.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id  --
              and s.ofp_parent_auctions_no is null
            group by s.auction_date_id, s.order_id -- distinct
          ) s
          inner join lateral
            (
              select t.auction_date_id, t.order_id, t.auction_id
                , row_number() over (partition by t.auction_date_id, t.order_id order by t.auction_id) as ofp_parent_auctions_no_new
              from data_marts.f_ats_cons_details t
              where t.is_ofp_parent = true
                and t.order_id = s.order_id
                and t.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id --
                and t.auction_date_id = s.auction_date_id
              limit 5000 -- up to 5k auctions limitation per one OFP parent order per day.
            ) td ON true and td.auction_id is not null
      ) src
    where trg.auction_date_id = l_cur_date_id --
      and trg.auction_date_id = src.auction_date_id
      and trg.order_id = src.order_id
      and trg.auction_id = src.auction_id
      and coalesce(trg.ofp_parent_auctions_no, -1) <> src.ofp_parent_auctions_no_new
      and trg.is_ofp_parent = true
    ;
*/

    with source as
    --select * count(1) from
      (
        select s.order_id, s.auction_date_id, s.is_ats_or_cons, ts.auction_id, ts.ofp_parent_auctions_no_new
        from
          (
            select s.order_id, s.auction_date_id, s.is_ats_or_cons
            from data_marts.f_ats_cons_details s
                 --tmp_ats_cons_details s
            where s.is_ofp_parent = true
              and s.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id  --
              and s.ofp_parent_auctions_no is null -->> column is not present in temp
            group by s.order_id, s.auction_date_id, s.is_ats_or_cons -- distinct
          ) s
          left join lateral
            (
              select t.auction_date_id, t.order_id, t.auction_id
                , row_number() over (partition by t.auction_date_id, t.order_id order by t.auction_id) as ofp_parent_auctions_no_new
              from data_marts.f_ats_cons_details t
              where t.is_ofp_parent = true
                and t.auction_date_id = l_cur_date_id -- 20190328 -- processing auction_date_id --
                and t.auction_date_id = s.auction_date_id
                and t.is_ats_or_cons = s.is_ats_or_cons
                and t.order_id = s.order_id
              limit 50000 -- up to 10k auctions limitation per one OFP parent order per day.
            ) ts ON true
      ) -- s
    , upd as
      (
        update data_marts.f_ats_cons_details trg
          set ofp_parent_auctions_no = src.ofp_parent_auctions_no_new
        from source src
        where trg.auction_date_id = src.auction_date_id
          and trg.auction_date_id = l_cur_date_id --
          and trg.auction_id = src.auction_id
          and trg.order_id = src.order_id
          and trg.is_ats_or_cons = src.is_ats_or_cons
          --and coalesce(trg.ofp_parent_auctions_no, -1) <> src.ofp_parent_auctions_no_new
          and trg.is_ofp_parent = true
        returning trg.auction_id
      )
    select count(1) into l_row_cnt
    from upd
    ;
    --GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, '5.2 Numeration of "ofp_parent_auctions_no" field completed.' , l_row_cnt , 'U')
    into l_step_id;

 -- Step 6. Recalculation of all auctions analytics and stats for OFP parent orders.
  -- analytics will only be present in the "ats_cons_stats" datamart. here. in the next steps.

 -- Step 7. Close processed subsctiptions
   update public.etl_subscriptions
    set is_processed = true,
        process_time = clock_timestamp()
    where load_batch_id = ANY(l_load_batch_arr) --subs_cursor.load_batch_id
      and not is_processed
      and subscription_name in ( 'ats_details' )
      and source_table_name ='client_order2auction' ;
  GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'load_batches to close subscriptions : '||left(array_to_string(l_load_batch_arr, ','),200) , l_row_cnt , 'U')
   into l_step_id;

END IF; -- there is no data to process




---------------------------------------------------------------------------------------------------------
  select public.load_log(l_load_id, l_step_id, 'load_ats_cons_inc COMPLETE ========= ' , 0, 'O')
   into l_step_id;
  RETURN 1;

exception when others then
  select public.load_log(l_load_id, l_step_id, sqlerrm , 0, 'E')
  into l_step_id;
   PERFORM public.load_error_log('load_ats_cons_inc',  'I', sqlerrm, l_load_id);

  RAISE;

END;
$$;


CREATE or replace FUNCTION dwh.reload_historic_order_and_mleg(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
-- PD: 20240118 https://dashfinancial.atlassian.net/browse/DS-7780 added new Optwap columns


declare
 l_row_cnt int;
begin

    raise  INFO  'Load historic orders+mleg started: %',  clock_timestamp()::text;

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
	   (CASE
	      WHEN CO.MULTILEG_REPORTING_TYPE = '3'
	      THEN 'M'
	      ELSE HSD.instrument_type_id
	   end)::char(1) as "InstrumentType",
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
	    and ex.exec_date_id = in_date_id
	    ) "LogTime",*/
	   CO.PROCESS_TIME as "RoutedTime",
	   CO.order_type_id as "OrderType",
	   CO.SIDE as "Side",
	   CO.ORDER_QTY as "OrderQty",
	   CO.PRICE as "Price",
	   CO.STOP_PRICE as "StopPx",
	   CO.time_in_force_id as "TimeInForce",
	   CO.EXPIRE_TIME as "ExpireTime",
	   CO.OPEN_CLOSE::char(1) as "OpenClose",
	   CO.EX_DESTINATION as "ExDestination",
	   CO.HANDL_INST::char(1) as "HandlInst",
	   --CO.EXEC_INST as "ExecInst",
	   CO.MAX_SHOW_QTY as "MaxShowQty",
	   CO.MAX_FLOOR as "MaxFloorQty",
	   CASE
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
	      		 then CO.clearing_firm_id
	      		 else null
	      	   end
	      ELSE CO.clearing_firm_id
	    END "ClearingFirmID",
	    CASE
	      WHEN HSD.instrument_type_id = 'E'
	      THEN NULL
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
	      		 then coalesce(doeb.opt_exec_broker , OPX.opt_exec_broker)
	      		 else OPX.opt_exec_broker
	      	   end
	      ELSE doeb.opt_exec_broker
	    END "ExecBroker",
	    --we store value in CLIENT_ORDER for all cases
	   (case
	     when CO.PARENT_ORDER_ID is null
	     then dcof.customer_or_firm_id
	     else null
	   end)::char(1) as "CustomerOrFirm",
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
	   EX.TRADE_LIQUIDITY_INDICATOR as "TradeLiquidityIndicator",
	   CO.MULTILEG_REPORTING_TYPE::char(1) as "MultilegReportingType",
	   COL.CLIENT_LEG_REF_ID as "LegRefID",
	   COL.MULTILEG_ORDER_ID as "MultilegOrderID",
	   FC.FIX_COMP_ID as "FixCompID", --sending firm
	   CO.client_id_text as "ClientID",
	   EX.exec_text as "Text",
	    (CASE
	      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
	      THEN 'Y'
	      ELSE 'N'
	    end)::char(1) "IsOSROrder",
		coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
	   CO.sub_strategy_desc as "SubStrategy",
	   CO.ALGO_STOP_PX as "AlgoStopPx",
	   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
	   CO.TRANS_TYPE as "TransType",
	   CO.DASH_CLIENT_ORDER_ID as "DashClOrdID",
	   CO.CROSS_ORDER_ID as "CrossOrderID",
	   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
	   dss.sub_system_id  as "SubSystemID",
	   CO.TRANSACTION_ID as "TransactionID",
	   CO.TOT_NO_ORDERS_IN_TRANSACTION as "TotNoOrdersInTransaction",
	   CO.EXCHANGE_ID as "ExchangeID",
	   CO.FEE_SENSITIVITY as "FeeSensitivity",
	   CO.ON_BEHALF_OF_SUB_ID as "OnBehalfOfSubID",
	   CO.strtg_decision_reason_code as "StrategyDecisionReasonCode",
	   CO.INTERNAL_ORDER_ID as "InternalOrderID",
	   CO.ALGO_START_TIME as "AlgoStartTime",
	   CO.ALGO_END_TIME as "AlgoEndTime",
	   --CO.MIN_TARGET_QTY as "MinTargetQty",
	   CO.EXTENDED_ORD_TYPE::char(1) as "ExtendedOrdType",
	   CO.PRIM_LISTING_EXCHANGE as "PrimListingExchange",
	   CO.POSTING_EXCHANGE as "PostingExchange",
	   CO.PRE_OPEN_BEHAVIOR::char(1) as "PreOpenBehavior",
	   CO.MAX_WAVE_QTY_PCT as "MaxWaveQtyPct",
	   CO.SWEEP_STYLE::char(1) as "SweepStyle",
	   CO.DISCRETION_OFFSET as "DiscretionOffset",
	   CRO.CROSS_TYPE::char(1) as "CrossType",
	   CO.AGGRESSION_LEVEL as "AggressionLevel",
	   CO.HIDDEN_FLAG::char(1) as "HiddenFlag",
	   CO.QUOTE_ID as "QuoteID",
	   CO.STEP_UP_PRICE_TYPE::char(1) as "StepUpPriceType",
	   CO.STEP_UP_PRICE as "StepUpPrice",
	   CO.CROSS_ACCOUNT_ID as "CrossAccountID",
	   AU."AuctionID" "AuctionID",
	   CO.CLEARING_ACCOUNT as "ClearingAccount",
	   CO.SUB_ACCOUNT as "SubAccount",
	   CO.REQUEST_NUMBER as "RequestNumber",
	   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
	   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",
	   CO.COMPLIANCE_ID as "ComplianceID",
	   CO.ALTERNATIVE_COMPLIANCE_ID as "AlternativeComplianceID",
	   CO.CONDITIONAL_CLIENT_ORDER_ID "ConditionalClientOrderID",
	   'N'::char(1) "IsConditionalOrder",
	   CO.co_routing_table_entry_id  "RoutingTableEntryID",
	   CO.MAX_VEGA_PER_STRIKE "MaxVegaPerStrike",
	   CO.PER_STRIKE_VEGA_EXPOSURE "PerStrikeVegaExposure",
	   CO.VEGA_BEHAVIOR "VegaBehavior",
	   CO.DELTA_BEHAVIOR "DeltaBehavior",
	   CO.HEDGE_PARAM_UNITS "HedgeParamUnits",
	   CO.MIN_DELTA "MinDelta",
	   AC.FIX_COMP_ID "FixCompID2",
	   I.SYMBOL_SUFFIX "SymbolSfx",
	   CO.PRODUCT_DESCRIPTION "ProductDescription",
	   CO.SESSION_ELIGIBILITY::char(1) "SessionEligibility",
	   CO.CREATE_DATE_ID "CreateDateID",
	   EX.exec_date_id "TradeDateID",
	   EX.exec_time::date as "TradeDate",
	   CO.optwap_bin_number as "OptwapBinNumber",
	   CO.optwap_phase as "OptwapPhase",
	   CO.optwap_order_price as "OptwapOrderPrice",
	   CO.optwap_bin_duration as "OptwapBinDuration",
	   CO.optwap_bin_qty as "OptwapBinQty",
	   CO.optwap_phase_duration as "OptwapPhaseDuration"
	   from dwh.execution ex
	   join dwh.client_order co on ex.order_id = co.order_id and ex.exec_date_id = co.create_date_id
	   join dwh.d_instrument i on i.instrument_id = co.instrument_id
	   left join dwh.historic_security_definition hsd on hsd.instrument_id = co.instrument_id
	   join dwh.d_fix_connection fc on  fc.fix_connection_id = co.fix_connection_id
	   join staging.acceptor ac on ac.acceptor_id = fc.acceptor_id
	   join d_account acc on co.account_id = acc.account_id
	   left join dwh.d_opt_exec_broker opx on opx.account_id = acc.account_id and opx.is_active = 'Y' and opx.is_default = 'Y'
	   left join dwh.client_order coorig on co.orig_order_id = coorig.order_id and coorig.create_date_id = co.create_date_id
	   left join dwh.client_order_leg col on co.order_id = col.order_id
	   left join dwh.d_order_type dot on dot.order_type_id = co.order_type_id
	   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force_id and dtif.is_active
	   left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = co.opt_exec_broker_id
	   left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
	   left join dwh.d_customer_or_firm dcof on dcof.customer_or_firm_id = co.customer_or_firm_id
	   left join dwh.cross_order cro on co.cross_order_id = cro.cross_order_id
	   left join lateral
	    (select sum(eq.last_qty) "DAY_CUM_QTY",
	      eq.order_id "order_id",
	      eq.exec_time::date "trade_date",
	     sum(eq.last_qty*eq.last_px)/nullif(sum(eq.last_qty),0) "DAY_AVG_PX"
	    from execution eq
	    where eq.exec_type in ('F', 'G')
	    and exec_date_id = in_date_id
	    and eq.is_busted   <> 'Y'
	    and ex.order_id = eq.order_id
	    and ex.exec_time::date  = eq.exec_time::date
	    group by eq.order_id,
	      eq.exec_time::date
	    limit 1
	    ) odcs on true
	   left join (select order_id, min(auction_id) "AuctionID" from dwh.client_order2auction where create_date_id = in_date_id  group by order_id) au on au.order_id = co.order_id
	   where ex.order_status <> '3'
	   and ex.time_in_force_id not in ('1','6')
	   and case when in_order_ids_arr <> '{}' then ex.order_id = any(in_order_ids_arr) else true end
	   and ex.exec_date_id = in_date_id;

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
	   select HOD."OrderID",
		  HOD."ClOrdID", HOD."OrigClOrdID", HOD."OrderClass", HOD."CustomerOrderID", HOD."ExecID",
		  HOD."RefExecID", HOD."InstrumentID", HOD."Symbol", HOD."InstrumentType", HOD."MaturityYear",
		  HOD."MaturityMonth", HOD."MaturityDay", HOD."PutCall", HOD."StrikePx", HOD."OPRASymbol",
		  HOD."DisplayInstrumentID", HOD."UnderlyingDisplayInstrID", HOD."OrderCreationTime",
		  HOD."TransactTime", /*HOD."LogTime",*/ HOD."RoutedTime", HOD."OrderType", HOD."Side", HOD."OrderQty",
		  HOD."Price", HOD."StopPx", HOD."TimeInForce", HOD."ExpireTime", HOD."OpenClose", HOD."ExDestination",
		  HOD."ExDestination" as "AliasExDestination", HOD."HandlInst", HOD."MaxShowQty", HOD."MaxFloorQty",
		  HOD."ClearingFirmID", HOD."ExecBroker", HOD."CustomerOrFirm", HOD."OrderCapacity",
		  HOD."MarketParticipantID", HOD."IsLocateRequired", HOD."LocateBroker", HOD."ExecType",
		  HOD."OrderStatus", HOD."RejectReason", HOD."LeavesQty", HOD."CumQty", HOD."AvgPx", HOD."LastQty",
		  HOD."LastPx", HOD."LastMkt", HOD."DayOrderQty", HOD."DayCumQty", HOD."DayAvgPx", HOD."AccountID",
		  HOD."TradeLiquidityIndicator", HOD."MultilegReportingType", HOD."LegRefID",
		  HOD."MultilegOrderID", HOD."FixCompID", HOD."ClientID", HOD."Text",
		  HOD."IsOSROrder", HOD."OSROrderID", HOD."SubStrategy", HOD."AlgoStopPx", HOD."AlgoClOrdID", HOD."DashClOrdID", HOD."OCCOptionalData", HOD."SubSystemID",
	    HOD."TransactionID",HOD."TotNoOrdersInTransaction",HOD."ExchangeID",HOD."CrossOrderID",HOD."AggressionLevel",HOD."HiddenFlag",
	    HOD."AlgoStartTime",HOD."AlgoEndTime",HOD."ExtendedOrdType",HOD."PrimListingExchange",HOD."PreOpenBehavior",HOD."MaxWaveQtyPct",HOD."SweepStyle",HOD."DiscretionOffset",HOD."CrossType",
	    HOD."QuoteID",HOD."StepUpPriceType",HOD."StepUpPrice",HOD."CrossAccountID",HOD."AuctionID",
	    HOD."ClearingAccount", HOD."SubAccount", HOD."RequestNumber", HOD."LiquidityProviderID", HOD."InternalComponentType",
	    HOD."ComplianceID", HOD."AlternativeComplianceID", HOD."ConditionalClientOrderID", HOD."IsConditionalOrder",
	    HOD."RoutingTableEntryID", HOD."MaxVegaPerStrike", HOD."PerStrikeVegaExposure", HOD."VegaBehavior", HOD."DeltaBehavior", HOD."HedgeParamUnits", HOD."MinDelta",
	    HOD."FixCompID2",HOD."SymbolSfx",HOD."StrategyDecisionReasonCode",HOD."SessionEligibility",HOD."CreateDateID",
	    "TradeDate" as "StatusDate", in_date_id as "Status_Date_id",
			HOD."OptwapBinNumber",
			HOD."OptwapPhase",
			HOD."OptwapOrderPrice",
			HOD."OptwapBinDuration",
			HOD."OptwapBinQty",
			HOD."OptwapPhaseDuration" from temp_hods HOD
	   	WHERE HOD."TransType" <> 'F'
			AND HOD."ExecID" in (
	        select max(e.exec_id) from execution e
		  	where case when in_order_ids_arr <> '{}' then e.order_id = any(in_order_ids_arr) else true end
			  and e.exec_date_id = in_date_id
	          and e.order_status <> '3'
	          group by e.order_id)
	    /*on conflict ("OrderID","StatusDate", "Status_Date_id" ) do update
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
$$;

CREATE or replace FUNCTION dwh.reload_historic_order_gtc(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
	   (CASE
	      WHEN CO.MULTILEG_REPORTING_TYPE = '3'
	      THEN 'M'
	      ELSE HSD.instrument_type_id
	   end)::char(1) as "InstrumentType",
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
	    and ex.exec_date_id = in_date_id
	    ) "LogTime",*/
	   CO.PROCESS_TIME as "RoutedTime",
	   CO.order_type_id as "OrderType",
	   CO.SIDE as "Side",
	   CO.ORDER_QTY as "OrderQty",
	   CO.PRICE as "Price",
	   CO.STOP_PRICE as "StopPx",
	   CO.time_in_force_id as "TimeInForce",
	   CO.EXPIRE_TIME as "ExpireTime",
	   CO.OPEN_CLOSE::char(1) as "OpenClose",
	   CO.EX_DESTINATION as "ExDestination",
	   CO.HANDL_INST::char(1) as "HandlInst",
	   --CO.EXEC_INST as "ExecInst",
	   CO.MAX_SHOW_QTY as "MaxShowQty",
	   CO.MAX_FLOOR as "MaxFloorQty",
	   CASE
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
	      		 then CO.clearing_firm_id
	      		 else null
	      	   end
	      ELSE CO.clearing_firm_id
	    END "ClearingFirmID",
	    CASE
	      WHEN HSD.instrument_type_id = 'E'
	      THEN NULL
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
	      		 then coalesce(doeb.opt_exec_broker , OPX.opt_exec_broker)
	      		 else OPX.opt_exec_broker
	      	   end
	      ELSE doeb.opt_exec_broker
	    END "ExecBroker",
	    --we store value in CLIENT_ORDER for all cases
	   (case
	     when CO.PARENT_ORDER_ID is null
	     then dcof.customer_or_firm_id
	     else null
	   end)::char(1) as "CustomerOrFirm",
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
	   "DAY_CUM_QTY" as "CumQty",
	    --EX.AVG_PX "AvgPx",
	    "DAY_AVG_PX" as "AvgPx",
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
	   EX.TRADE_LIQUIDITY_INDICATOR as "TradeLiquidityIndicator",
	   CO.MULTILEG_REPORTING_TYPE::char(1) as "MultilegReportingType",
	   COL.CLIENT_LEG_REF_ID as "LegRefID",
	   COL.MULTILEG_ORDER_ID as "MultilegOrderID",
	   FC.FIX_COMP_ID as "FixCompID", --sending firm
	   CO.client_id_text as "ClientID",
	   EX.exec_text as "Text",
	    (CASE
	      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
	      THEN 'Y'
	      ELSE 'N'
	    end)::char(1) "IsOSROrder",
		coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
	   CO.sub_strategy_desc as "SubStrategy",
	   CO.ALGO_STOP_PX as "AlgoStopPx",
	   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
	   CO.TRANS_TYPE as "TransType",
	   CO.DASH_CLIENT_ORDER_ID as "DashClOrdID",
	   CO.CROSS_ORDER_ID as "CrossOrderID",
	   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
	   dss.sub_system_id  as "SubSystemID",
	   CO.TRANSACTION_ID as "TransactionID",
	   CO.TOT_NO_ORDERS_IN_TRANSACTION as "TotNoOrdersInTransaction",
	   CO.EXCHANGE_ID as "ExchangeID",
	   CO.FEE_SENSITIVITY as "FeeSensitivity",
	   CO.ON_BEHALF_OF_SUB_ID as "OnBehalfOfSubID",
	   CO.strtg_decision_reason_code as "StrategyDecisionReasonCode",
	   CO.INTERNAL_ORDER_ID as "InternalOrderID",
	   CO.ALGO_START_TIME as "AlgoStartTime",
	   CO.ALGO_END_TIME as "AlgoEndTime",
	   --CO.MIN_TARGET_QTY as "MinTargetQty",
	   CO.EXTENDED_ORD_TYPE::char(1) as "ExtendedOrdType",
	   CO.PRIM_LISTING_EXCHANGE as "PrimListingExchange",
	   CO.POSTING_EXCHANGE as "PostingExchange",
	   CO.PRE_OPEN_BEHAVIOR::char(1) as "PreOpenBehavior",
	   CO.MAX_WAVE_QTY_PCT as "MaxWaveQtyPct",
	   CO.SWEEP_STYLE::char(1) as "SweepStyle",
	   CO.DISCRETION_OFFSET as "DiscretionOffset",
	   CRO.CROSS_TYPE::char(1) as "CrossType",
	   CO.AGGRESSION_LEVEL as "AggressionLevel",
	   CO.HIDDEN_FLAG::char(1) as "HiddenFlag",
	   CO.QUOTE_ID as "QuoteID",
	   CO.STEP_UP_PRICE_TYPE::char(1) as "StepUpPriceType",
	   CO.STEP_UP_PRICE as "StepUpPrice",
	   CO.CROSS_ACCOUNT_ID as "CrossAccountID",
	   AU."AuctionID" "AuctionID",
	   CO.CLEARING_ACCOUNT as "ClearingAccount",
	   CO.SUB_ACCOUNT as "SubAccount",
	   CO.REQUEST_NUMBER as "RequestNumber",
	   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
	   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",
	   CO.COMPLIANCE_ID as "ComplianceID",
	   CO.ALTERNATIVE_COMPLIANCE_ID as "AlternativeComplianceID",
	   CO.CONDITIONAL_CLIENT_ORDER_ID "ConditionalClientOrderID",
	   'N'::char(1) "IsConditionalOrder",
	   CO.co_routing_table_entry_id  "RoutingTableEntryID",
	   CO.MAX_VEGA_PER_STRIKE "MaxVegaPerStrike",
	   CO.PER_STRIKE_VEGA_EXPOSURE "PerStrikeVegaExposure",
	   CO.VEGA_BEHAVIOR "VegaBehavior",
	   CO.DELTA_BEHAVIOR "DeltaBehavior",
	   CO.HEDGE_PARAM_UNITS "HedgeParamUnits",
	   CO.MIN_DELTA "MinDelta",
	   AC.FIX_COMP_ID "FixCompID2",
	   I.SYMBOL_SUFFIX "SymbolSfx",
	   CO.PRODUCT_DESCRIPTION "ProductDescription",
	   CO.SESSION_ELIGIBILITY::char(1) "SessionEligibility",
	   CO.CREATE_DATE_ID "CreateDateID",
	   EX.exec_date_id "TradeDateID",
	   EX.exec_time::date as "TradeDate",
	   CO.optwap_bin_number as "OptwapBinNumber",
	   CO.optwap_phase as "OptwapPhase",
	   CO.optwap_order_price as "OptwapOrderPrice",
	   CO.optwap_bin_duration as "OptwapBinDuration",
	   CO.optwap_bin_qty as "OptwapBinQty",
	   CO.optwap_phase_duration as "OptwapPhaseDuration"
	   from dwh.gtc_order_status gto
	   join dwh.execution ex on ex.order_id = gto.order_id
	   join dwh.client_order co on ex.order_id = co.order_id and gto.create_date_id = co.create_date_id
	   join dwh.d_instrument i on i.instrument_id = co.instrument_id
	   left join dwh.historic_security_definition hsd on hsd.instrument_id = co.instrument_id
	   join dwh.d_fix_connection fc on  fc.fix_connection_id = co.fix_connection_id
	   join staging.acceptor ac on ac.acceptor_id = fc.acceptor_id
	   join d_account acc on co.account_id = acc.account_id
	   left join dwh.d_opt_exec_broker opx on opx.account_id = acc.account_id and opx.is_active = 'Y' and opx.is_default = 'Y'
	   left join dwh.client_order coorig on co.orig_order_id = coorig.order_id and coorig.create_date_id = co.create_date_id
	   left join dwh.client_order_leg col on co.order_id = col.order_id
	   left join dwh.d_order_type dot on dot.order_type_id = co.order_type_id
	   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force_id and dtif.is_active
	   left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = co.opt_exec_broker_id
	   left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
	   left join dwh.d_customer_or_firm dcof on dcof.customer_or_firm_id = co.customer_or_firm_id
	   left join dwh.cross_order cro on co.cross_order_id = cro.cross_order_id
	   left join lateral
	    (select sum(eq.last_qty) "DAY_CUM_QTY",
	      eq.order_id "order_id",
	      eq.exec_time::date "trade_date",
	     sum(eq.last_qty*eq.last_px)/nullif(sum(eq.last_qty),0) "DAY_AVG_PX"
	    from execution eq
	    where eq.exec_type in ('F', 'G')
	    and exec_date_id = in_date_id
	    and eq.is_busted   <> 'Y'
	    and ex.order_id = eq.order_id
	    and ex.exec_time::date  = eq.exec_time::date
	    group by eq.order_id,
	      eq.exec_time::date
	    limit 1
	    ) odcs on true
	   left join (select order_id, min(auction_id) "AuctionID" from dwh.client_order2auction where create_date_id = in_date_id  group by order_id) au on au.order_id = co.order_id
	   where ex.order_status <> '3'
	   and case when in_order_ids_arr <> '{}' then ex.order_id = any(in_order_ids_arr) else true end
	   and ex.exec_date_id = in_date_id
	   and (gto.close_date_id is null or gto.close_date_id = in_date_id);

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
	   select HOD."OrderID",
		  HOD."ClOrdID", HOD."OrigClOrdID", HOD."OrderClass", HOD."CustomerOrderID", HOD."ExecID",
		  HOD."RefExecID", HOD."InstrumentID", HOD."Symbol", HOD."InstrumentType", HOD."MaturityYear",
		  HOD."MaturityMonth", HOD."MaturityDay", HOD."PutCall", HOD."StrikePx", HOD."OPRASymbol",
		  HOD."DisplayInstrumentID", HOD."UnderlyingDisplayInstrID", HOD."OrderCreationTime",
		  HOD."TransactTime", /*HOD."LogTime",*/ HOD."RoutedTime", HOD."OrderType", HOD."Side", HOD."OrderQty",
		  HOD."Price", HOD."StopPx", HOD."TimeInForce", HOD."ExpireTime", HOD."OpenClose", HOD."ExDestination",
		  HOD."ExDestination" as "AliasExDestination", HOD."HandlInst", HOD."MaxShowQty", HOD."MaxFloorQty",
		  HOD."ClearingFirmID", HOD."ExecBroker", HOD."CustomerOrFirm", HOD."OrderCapacity",
		  HOD."MarketParticipantID", HOD."IsLocateRequired", HOD."LocateBroker", HOD."ExecType",
		  HOD."OrderStatus", HOD."RejectReason", HOD."LeavesQty", HOD."CumQty", HOD."AvgPx", HOD."LastQty",
		  HOD."LastPx", HOD."LastMkt", HOD."DayOrderQty", HOD."DayCumQty", HOD."DayAvgPx", HOD."AccountID",
		  HOD."TradeLiquidityIndicator", HOD."MultilegReportingType", HOD."LegRefID",
		  HOD."MultilegOrderID", HOD."FixCompID", HOD."ClientID", HOD."Text",
		  HOD."IsOSROrder", HOD."OSROrderID", HOD."SubStrategy", HOD."AlgoStopPx", HOD."AlgoClOrdID", HOD."DashClOrdID", HOD."OCCOptionalData", HOD."SubSystemID",
	    HOD."TransactionID",HOD."TotNoOrdersInTransaction",HOD."ExchangeID",HOD."CrossOrderID",HOD."AggressionLevel",HOD."HiddenFlag",
	    HOD."AlgoStartTime",HOD."AlgoEndTime",HOD."ExtendedOrdType",HOD."PrimListingExchange",HOD."PreOpenBehavior",HOD."MaxWaveQtyPct",HOD."SweepStyle",HOD."DiscretionOffset",HOD."CrossType",
	    HOD."QuoteID",HOD."StepUpPriceType",HOD."StepUpPrice",HOD."CrossAccountID",HOD."AuctionID",
	    HOD."ClearingAccount", HOD."SubAccount", HOD."RequestNumber", HOD."LiquidityProviderID", HOD."InternalComponentType",
	    HOD."ComplianceID", HOD."AlternativeComplianceID", HOD."ConditionalClientOrderID", HOD."IsConditionalOrder",
	    HOD."RoutingTableEntryID", HOD."MaxVegaPerStrike", HOD."PerStrikeVegaExposure", HOD."VegaBehavior", HOD."DeltaBehavior", HOD."HedgeParamUnits", HOD."MinDelta",
	    HOD."FixCompID2",HOD."SymbolSfx",HOD."StrategyDecisionReasonCode",HOD."SessionEligibility",HOD."CreateDateID",
	    "TradeDate" as "StatusDate", in_date_id as "Status_Date_id",
			HOD."OptwapBinNumber",
			HOD."OptwapPhase",
			HOD."OptwapOrderPrice",
			HOD."OptwapBinDuration",
			HOD."OptwapBinQty",
			HOD."OptwapPhaseDuration" from temp_hods HOD
	   	WHERE HOD."TransType" <> 'F'
			AND HOD."ExecID" in (
	        select max(e.exec_id) from execution e
		  	where case when in_order_ids_arr <> '{}' then e.order_id = any(in_order_ids_arr) else true end
			  and e.exec_date_id = in_date_id
	          and e.order_status <> '3'
	          group by e.order_id)
	     /*on conflict ("OrderID","StatusDate","Status_Date_id" ) do update
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
$$;



CREATE or replace FUNCTION dwh.reload_historic_tds(in_date_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
 l_row_cnt int;
begin



	insert into dwh.historic_trade_details_storage("OrderID","ExecID","RefExecID","TransactTime","ExecType",
	             "LeavesQty","CumQty","AvgPx","LastQty","LastPx",
	             "LastMkt","TradeLiquidityIndicator","Text","ExchExecID", "SecondaryOrderID", "ExchangeID",
	             "PrincipalAmount","AliasLastMkt", "AuctionID", "TradeDateID",
	             "StatusDate", "Status_Date_id" )
	select
	        "OrderID",
	        "ExecID",
	        "RefExecID"::bigint,
	        "TransactTime",
	        "ExecType",
	        "LeavesQty",
	        "CumQty",
	        "AvgPx",
	        "LastQty",
	        "LastPx",
	        "LastMkt",
	        "TradeLiquidityIndicator",
	        "Text",
	        "ExchExecID",
	        "SecondaryOrderID",
	        "ExchangeID",
	        /*"StreetCustomerOrFirm",
	        "StreetExecBroker",
	        "StreetClearingFirm",
	        "StreetAccount",*/
	        "PrincipalAmount",
	        "LastMkt",
	        "AuctionID",
	        "TradeDateID",
	        "TradeDateID"::varchar::date,
	        "Status_Date_id"
	    FROM
	        (
	            SELECT
	                co.order_id "OrderID",
	                ex.exec_id "ExecID",
	                NULL "RefExecID",
	                ex.exec_time "TransactTime",
	                ex.exec_type "ExecType",
	                ex.leaves_qty "LeavesQty",
	                ex.cum_qty "CumQty",
	                ex.avg_px "AvgPx",
	                ex.last_qty "LastQty",
	                ex.last_px "LastPx",
	                    CASE
	                        WHEN ex.exec_type NOT IN (
	                            'F','G'
	                        ) THEN NULL
	                        WHEN co.parent_order_id IS NULL THEN ex.last_mkt
	                        ELSE co.ex_destination
	                    END
	                "LastMkt",
	                ex.trade_liquidity_indicator "TradeLiquidityIndicator",
	                ex.exec_text "Text",
	                ex.exch_exec_id "ExchExecID",
	                ex.secondary_order_id "SecondaryOrderID",
	                ex.auction_id "AuctionID",
	                coch.exchange_id "ExchangeID",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'BATO','BOX','C2OX','CBOE','NQBXO','NSDQO'
	                        ) THEN coch.eq_order_capacity --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 47 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','GEMINI','ISE','MIAX','PHLX'
	                        ) THEN coch.customer_or_firm_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 204 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        ELSE NULL
	                    END
	                "StreetCustomerOrFirm",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO'
	                        ) THEN coch.market_participant_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 115 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'BOX','C2OX','CBOE','GEMINI','ISE'
	                        ) THEN doeb.opt_exec_broker --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 76 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'MIAX','PHLX'
	                        ) THEN ( fmj.fix_message->>'50')
	                        WHEN coch.exchange_id IN (
	                            'NQBXO','NSDQO'
	                        ) THEN coch.client_id_text --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 109 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        ELSE NULL
	                    END
	                "StreetExecBroker",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO','BOX','C2OX','CBOE','GEMINI','ISE','MIAX','NQBXO','NSDQO','PHLX'
	                        ) THEN coch.clearing_firm_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 439 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'AMEXML','BATOML','CBOEML','GMNIML','ISEML','MIAXML','PHLXML'
	                        ) THEN ( right(fmj.fix_message->>'1',3))
	                        ELSE NULL
	                    END
	                "StreetClearingFirm",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO','BOX','GEMINI','ISE','MIAX','NQBXO','NSDQO','PHLX','AMEXML','BATOML','CBOEML','GMNIML','ISEML','MIAXML','PHLXML'
	                        ) THEN (fmj.fix_message->>'1')
	                        WHEN coch.exchange_id IN (
	                            'C2OX','CBOE'
	                        ) THEN (fmj.fix_message->>'440')
	                        ELSE NULL
	                    END
	                "StreetAccount",
		--
	                    CASE i.INSTRUMENT_TYPE_ID
	                        WHEN 'O' THEN ex.last_qty * ex.last_px * os.contract_multiplier
	                        ELSE ex.last_qty * ex.last_px
	                    END
	                "PrincipalAmount",
	                ex.exec_date_id  "TradeDateID",
	                ex.exec_date_id as "Status_Date_id",
		--
	                coalesce(coch.parent_order_id, co.order_id) AS virtual_order_id
	            FROM
	                execution ex
	                JOIN client_order co ON ex.order_id = co.order_id and ex.exec_date_id = co.create_date_id
	                LEFT JOIN client_order coch ON (
						ex.secondary_order_id = coch.client_order_id
						AND co.order_id = coch.parent_order_id
						and co.create_date_id = coch.create_date_id
	                )
	                JOIN dwh.d_instrument i ON i.instrument_id = co.instrument_id
	                LEFT JOIN dwh.d_option_contract oc ON co.instrument_id = oc.instrument_id
	                LEFT JOIN dwh.d_option_series os ON os.option_series_id = oc.option_series_id
	                left join fix_capture.fix_message_json fmj on fmj.fix_message_id = coch.fix_message_id and fmj.date_id = coch.create_date_id
	                left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = coch.opt_exec_broker_id
	            WHERE ex.order_status <> '3'
	                AND co.multileg_reporting_type IN ('1','2')
	                AND co.trans_type <> 'F'
	                AND ex.exec_type = 'F'
	                AND ex.is_busted <> 'Y'
	                and ex.exec_date_id = in_date_id
	                and ex.time_in_force_id not in ('1','6')
			AND i.instrument_type_id IN ('E','O')
			AND i.is_active = 'Y'
	        ) abc
	    WHERE
	        virtual_order_id = "OrderID";

	   raise  INFO  '%: temp table has been created',  clock_timestamp()::text;

	   return l_row_cnt;

end
$$;



CREATE or replace FUNCTION dwh.reload_historic_tds_gtc(in_date_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
 l_row_cnt int;
begin



	insert into dwh.historic_trade_details_storage("OrderID","ExecID","RefExecID","TransactTime","ExecType",
	             "LeavesQty","CumQty","AvgPx","LastQty","LastPx",
	             "LastMkt","TradeLiquidityIndicator","Text","ExchExecID", "SecondaryOrderID", "ExchangeID",
	             "PrincipalAmount","AliasLastMkt", "AuctionID", "TradeDateID",
	             "StatusDate", "Status_Date_id" )
	select
	        "OrderID",
	        "ExecID",
	        "RefExecID"::bigint,
	        "TransactTime",
	        "ExecType",
	        "LeavesQty",
	        "CumQty",
	        "AvgPx",
	        "LastQty",
	        "LastPx",
	        "LastMkt",
	        "TradeLiquidityIndicator",
	        "Text",
	        "ExchExecID",
	        "SecondaryOrderID",
	        "ExchangeID",
	        /*"StreetCustomerOrFirm",
	        "StreetExecBroker",
	        "StreetClearingFirm",
	        "StreetAccount",*/
	        "PrincipalAmount",
	        "LastMkt",
	        "AuctionID",
	        "TradeDateID",
	        "TradeDateID"::varchar::date,
	        "Status_Date_id"
	    FROM
	        (
	            SELECT
	                co.order_id "OrderID",
	                ex.exec_id "ExecID",
	                NULL "RefExecID",
	                ex.exec_time "TransactTime",
	                ex.exec_type "ExecType",
	                ex.leaves_qty "LeavesQty",
	                ex.cum_qty "CumQty",
	                ex.avg_px "AvgPx",
	                ex.last_qty "LastQty",
	                ex.last_px "LastPx",
	                    CASE
	                        WHEN ex.exec_type NOT IN (
	                            'F','G'
	                        ) THEN NULL
	                        WHEN co.parent_order_id IS NULL THEN ex.last_mkt
	                        ELSE co.ex_destination
	                    END
	                "LastMkt",
	                ex.trade_liquidity_indicator "TradeLiquidityIndicator",
	                ex.exec_text "Text",
	                ex.exch_exec_id "ExchExecID",
	                ex.secondary_order_id "SecondaryOrderID",
	                ex.auction_id "AuctionID",
	                coch.exchange_id "ExchangeID",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'BATO','BOX','C2OX','CBOE','NQBXO','NSDQO'
	                        ) THEN coch.eq_order_capacity --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 47 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','GEMINI','ISE','MIAX','PHLX'
	                        ) THEN coch.customer_or_firm_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 204 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        ELSE NULL
	                    END
	                "StreetCustomerOrFirm",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO'
	                        ) THEN coch.market_participant_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 115 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'BOX','C2OX','CBOE','GEMINI','ISE'
	                        ) THEN doeb.opt_exec_broker --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 76 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'MIAX','PHLX'
	                        ) THEN ( fmj.fix_message->>'50')
	                        WHEN coch.exchange_id IN (
	                            'NQBXO','NSDQO'
	                        ) THEN coch.client_id_text --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 109 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        ELSE NULL
	                    END
	                "StreetExecBroker",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO','BOX','C2OX','CBOE','GEMINI','ISE','MIAX','NQBXO','NSDQO','PHLX'
	                        ) THEN coch.clearing_firm_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 439 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'AMEXML','BATOML','CBOEML','GMNIML','ISEML','MIAXML','PHLXML'
	                        ) THEN ( right(fmj.fix_message->>'1',3))
	                        ELSE NULL
	                    END
	                "StreetClearingFirm",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO','BOX','GEMINI','ISE','MIAX','NQBXO','NSDQO','PHLX','AMEXML','BATOML','CBOEML','GMNIML','ISEML','MIAXML','PHLXML'
	                        ) THEN (fmj.fix_message->>'1')
	                        WHEN coch.exchange_id IN (
	                            'C2OX','CBOE'
	                        ) THEN (fmj.fix_message->>'440')
	                        ELSE NULL
	                    END
	                "StreetAccount",
		--
	                    CASE i.INSTRUMENT_TYPE_ID
	                        WHEN 'O' THEN ex.last_qty * ex.last_px * os.contract_multiplier
	                        ELSE ex.last_qty * ex.last_px
	                    END
	                "PrincipalAmount",
	                ex.exec_date_id  "TradeDateID",
	                ex.exec_date_id as "Status_Date_id",
		--
	                coalesce(coch.parent_order_id, co.order_id) AS virtual_order_id
	            from dwh.gtc_order_status gto
		   		join dwh.execution ex on ex.order_id = gto.order_id
		   		join dwh.client_order co on ex.order_id = co.order_id and gto.create_date_id = co.create_date_id
	               LEFT JOIN client_order coch ON (
						ex.secondary_order_id = coch.client_order_id
						AND co.order_id = coch.parent_order_id
						--and co.create_date_id = coch.create_date_id
	                )
	                JOIN dwh.d_instrument i ON i.instrument_id = co.instrument_id
	                LEFT JOIN dwh.d_option_contract oc ON co.instrument_id = oc.instrument_id
	                LEFT JOIN dwh.d_option_series os ON os.option_series_id = oc.option_series_id
	                left join fix_capture.fix_message_json fmj on fmj.fix_message_id = coch.fix_message_id and fmj.date_id = coch.create_date_id
	                left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = coch.opt_exec_broker_id
	            WHERE ex.order_status <> '3'
	                AND co.multileg_reporting_type IN ('1','2')
	                AND co.trans_type <> 'F'
	                AND ex.exec_type = 'F'
	                AND ex.is_busted <> 'Y'
	                and ex.exec_date_id = in_date_id
	                and (gto.close_date_id is null or gto.close_date_id = in_date_id)
			AND i.instrument_type_id IN ('E','O')
			AND i.is_active = 'Y'
	        ) abc
	    WHERE
	        virtual_order_id = "OrderID";

	   raise  INFO  '%: temp table has been created',  clock_timestamp()::text;

	   return l_row_cnt;

end
$$;


-- select * from eod_reports.export_rbc_orders_tbl();
CREATE or replace FUNCTION eod_reports.export_rbc_orders_tbl(in_start_date_id integer DEFAULT NULL::integer, in_end_date_id integer DEFAULT NULL::integer, in_client_ids character varying[] DEFAULT '{}'::character varying[]) RETURNS TABLE("Account" character varying, "Is Cross" character varying, "Is MLeg" character varying, "Ord Status" character varying, "Event Type" character varying, "Routed Time" character varying, "Event Time" character varying, "Cl Ord ID" character varying, "Side" character varying, "Symbol" character varying, "Ord Qty" bigint, "Price" numeric, "Ex Qty" bigint, "Avg Px" numeric, "Sub Strategy" character varying, "Ex Dest" character varying, "Ord Type" character varying, "TIF" character varying, "Sending Firm" character varying, "Capacity" character varying, "Client ID" character varying, "CMTA" character varying, "Creation Date" character varying, "Cross Ord Type" character varying, "Event Date" character varying, "Exec Broker" character varying, "Expiration Day" date, "Leg ID" character varying, "Lvs Qty" bigint, "O/C" character varying, "Orig Cl Ord ID" character varying, "OSI Symbol" character varying, "Root Symbol" character varying, "Security Type" character varying, "Stop Px" numeric, "Underlying Symbol" character varying)
    LANGUAGE plpgsql
    AS $$
-- SY: 20240307 client_id and x_destination_code_id fields have been removed
DECLARE

   l_row_cnt integer;
   l_load_id integer;
   l_step_id integer;

  l_start_date_id integer;
  l_end_date_id   integer;

  l_gtc_start_date_id integer;

 -- ak 20210303 added new input parament in_client_ids and added filter to 129-133 lines
 -- MB: 20220929 removed join to data_marts.d_client and changed client_src_id with client_id_text field from dwh.client_order
BEGIN

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id := 1;

  raise notice 'l_load_id=%',l_load_id;

  select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl STARTED===', 0, 'O')
   into l_step_id;

  if in_start_date_id is not null and in_end_date_id is not null
  then
    l_start_date_id := in_start_date_id;
    l_end_date_id := in_end_date_id;
  else
    --l_start_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    --l_end_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    l_start_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
    l_end_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;

  end if;

  --l_start_date_id := coalesce(in_date_id, (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer);

  l_gtc_start_date_id := to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD')::date - interval '6 month'), 'YYYYMMDD');

    select public.load_log(l_load_id, l_step_id, 'Step 1. l_start_date_id = '||l_start_date_id::varchar||', l_end_date_id = '||l_end_date_id::varchar||', l_gtc_start_date_id = '||l_gtc_start_date_id::varchar, 0 , 'O')
     into l_step_id;

  return QUERY
/*  with par_ords as
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      ) */
    select --po.order_id
        ac.account_name as "Account"
      , (case when po.cross_order_id is not null then 'Y' else 'N' end)::varchar as "Is Cross"
      , (case when po.multileg_reporting_type = '1' then 'N' else 'Y' end)::varchar as "Is MLeg"
      , st.order_status_description as "Ord Status"
      , et.exec_type_description as "Event Type"
      , to_char(fyc.routed_time, 'HH24:MI:SS.US')::varchar as "Routed Time"
      --, to_char(po.process_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , to_char(fyc.exec_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , po.client_order_id as "Cl Ord ID"
      , (case po.side
                  when '1' then 'Buy'
                  when '2' then 'Sell'
                  when '3' then 'Buy minus'
                  when '4' then 'Sell plus'
                  when '5' then 'Sell short'
                  when '6' then 'Sell short exempt'
                  when '7' then 'Undisclosed'
                  when '8' then 'Cross'
                  when '9' then 'Cross short'
                end)::varchar as "Side"
      , i.display_instrument_id as "Symbol"
      , po.order_qty::bigint as "Ord Qty"
      , po.price as "Price"
      , fyc.filled_qty as "Ex Qty"
      , fyc.avg_px as "Avg Px"
      , ss.target_strategy_desc as "Sub Strategy"
      , dc.ex_destination_code_name as "Ex Dest"
      , ot.order_type_name as "Ord Type"
      , tif.tif_name as "TIF"
      , f.fix_comp_id as "Sending Firm"
      , cf.customer_or_firm_name as "Capacity"
      , oo.client_id_text as "Client ID"
      , coalesce(po.clearing_firm_id, fx_co.clearing_firm_id) as "CMTA"
      , to_char(to_date(po.create_date_id::varchar, 'YYYYMMDD'), 'DD.MM.YYYY')::varchar as "Creation Date"
      , cro.cross_type::varchar as "Cross Ord Type"
      , to_char(fyc.exec_time, 'DD.MM.YYYY')::varchar as "Event Date"
      , ebr.opt_exec_broker as "Exec Broker"
      , date_trunc('day', i.last_trade_date)::date as "Expiration Day"
      , l.client_leg_ref_id as "Leg ID"
      , ex.leaves_qty::bigint as "Lvs Qty"
      , (case when po.open_close = 'O' then 'Open' else 'Close' end)::varchar as "O/C"
      , oo.client_order_id as "Orig Cl Ord ID"
      , po.opra_symbol as "OSI Symbol"
      , po.root_symbol as "Root Symbol"
      , it.instrument_type_name as "Security Type"
      , po.stop_price as "Stop Px"
      , ui.display_instrument_id as "Underlying Symbol"
      --, po.*
--select count(1)
    from
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
          and case in_client_ids
  					when '{}'::varchar[]
  						then true
  			else co.client_id_text = any(in_client_ids)
  	  	end
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      )  scp
      left join lateral
      (
        select po.order_id
          , po.orig_order_id
          , po.account_id
          , po.multileg_reporting_type
          , po.multileg_order_id
          , po.cross_order_id
          , po.create_date_id
          , po.client_order_id
          , po.instrument_id
          , po.order_qty
          , po.price
          , po.side
          , po.sub_strategy_id
  --        , po.ex_destination_code_id
          , po.ex_destination
          , po.order_type_id
          , po.time_in_force_id
          , po.customer_or_firm_id
--          , po.client_id
          , po.process_time
          , po.opt_exec_broker_id
          , po.no_legs
          , po.open_close
          , po.fix_connection_id
          , po.clearing_firm_id
          , po.fix_message_id
          , po.stop_price
          , po.trans_type
          , oc.option_series_id
          , oc.opra_symbol
          , os.underlying_instrument_id
          , os.root_symbol
          --, po.*
        from dwh.client_order po
        left join dwh.d_option_contract oc
          ON po.instrument_id = oc.instrument_id
        left join dwh.d_option_series os
          --ON oc.option_series_id = os.option_series_id
          ON oc.option_series_id = os.option_series_id
        where 1=1
          and po.create_date_id between l_gtc_start_date_id and l_end_date_id -- last half of year. GTC purpose
          and po.order_id = scp.order_id
        limit 1 -- for NL acceleration
      ) po ON true
      left join dwh.client_order oo
        ON po.orig_order_id = oo.order_id
        and oo.create_date_id between l_gtc_start_date_id and l_end_date_id
      left join dwh.d_account ac
        ON po.account_id = ac.account_id
      left join lateral
        (
           select sum(fyc.day_cum_qty) as filled_qty
             , round(sum(fyc.day_avg_px*fyc.day_cum_qty)/nullif(sum(fyc.day_cum_qty), 0)::numeric, 4)::numeric as avg_px
             , min(fyc.routed_time) as routed_time
             , max(fyc.exec_time) as exec_time -- can it be event_time or transact time? min or max?
             , fyc.order_id
             , min(fyc.nbbo_bid_price) as nbbo_bid_price
             , min(fyc.nbbo_bid_quantity) as nbbo_bid_quantity
             , min(fyc.nbbo_ask_price) as nbbo_ask_price
             , min(fyc.nbbo_ask_quantity) as nbbo_ask_quantity
           from data_marts.f_yield_capture fyc -- here we have all orders, so we can use it for cum_qty calculation (instead of FTR)
           where fyc.order_id = po.order_id
             and fyc.status_date_id between l_gtc_start_date_id and l_end_date_id
           group by fyc.order_id
           limit 1 -- just in case to insure NL join method
        ) fyc on true
      -- the last execution
      left join lateral
        (
          select ex.exec_text
            , ex.order_status
            , ex.exec_type
            , ex.exec_id
            , ex.leaves_qty
          from dwh.execution ex
          where 1=1
            --and ex.exec_date_id = 20190604
            and ex.exec_date_id between l_start_date_id and l_end_date_id
            and ex.order_id = po.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      -- fix_message of order
      left join lateral
        (
          select (j.fix_message->>'439')::varchar as clearing_firm_id
          from fix_capture.fix_message_json j
          where 1=1
            and po.clearing_firm_id is null --
            and j.date_id between l_start_date_id and l_end_date_id -- l_gtc_start_date_id was very slow condition
            and j.fix_message_id = po.fix_message_id
            and j.date_id = po.create_date_id
          limit 1
        ) fx_co on true
      left join dwh.d_order_status st
        ON ex.order_status = st.order_status
      left join dwh.d_exec_type et
        ON ex.exec_type = et.exec_type
      left join dwh.d_instrument i
        ON po.instrument_id = i.instrument_id
      left join dwh.d_instrument_type it
        ON i.instrument_type_id = it.instrument_type_id
      left join dwh.d_instrument ui
        --ON os.underlying_instrument_id = ui.instrument_id
        ON po.underlying_instrument_id = ui.instrument_id
      left join dwh.d_target_strategy ss
        ON po.sub_strategy_id = ss.target_strategy_id
      left join dwh.d_ex_destination_code dc
        ON po.ex_destination = dc.ex_destination_code
      left join dwh.d_order_type ot
        ON po.order_type_id = ot.order_type_id
      left join dwh.d_time_in_force tif
        ON po.time_in_force_id = tif.tif_id
    /*  left join --lateral
        (
          select ---min(ecf.customer_or_firm_id) as customer_or_firm_id
            ecf.customer_or_firm_id
            , ecf.exch_customer_or_firm_id, ecf.exchange_id  -- lookup key
            , row_number() over (partition by ecf.exch_customer_or_firm_id, ecf.exchange_id order by ecf.customer_or_firm_id) as rn
          from dwh.d_exchange2customer_or_firm ecf
        ) ecf
        ON ecf.rn = 1 --true
          and o.customer_or_firm is null
          and ecf.exch_customer_or_firm_id = o.order_capacity
          and ecf.exchange_id = o.exchange_id */
      left join dwh.d_customer_or_firm cf ON cf.customer_or_firm_id = COALESCE(po.customer_or_firm_id, ac.opt_customer_or_firm) and cf.is_active = true -- ecf.customer_or_firm_id,
      left join dwh.cross_order cro
        ON po.cross_order_id = cro.cross_order_id
      left join dwh.d_opt_exec_broker ebr
        ON po.opt_exec_broker_id = ebr.opt_exec_broker_id
      left join dwh.d_fix_connection f
        ON po.fix_connection_id = f.fix_connection_id
      /*left join dwh.client_order_leg l
        ON l.order_id = po.order_id
        and l.multileg_order_id = po.multileg_order_id*/
      left join lateral
        (
          select l.order_id, l.client_leg_ref_id
          from dwh.client_order_leg l
          where l.multileg_order_id = po.multileg_order_id
          limit 3000
        ) l ON l.order_id = po.order_id
    where po.trans_type <> 'F' -- not cancell request
    order by po.process_time, 1;


    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

 select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl COMPLETE ========= ' , l_row_cnt, 'O')
   into l_step_id;
   RETURN;
END;
$$;



CREATE or replace FUNCTION external_data.p_load_f_box_street_executions_daily(in_date_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
   l_row_cnt integer;

   l_load_id int;
   l_step_id int;

   l_cur_date_id integer;
   l_min_gtc_date_id integer;

BEGIN


  select nextval('public.load_timing_seq') into l_load_id;

  l_step_id:=1;

  select public.load_log(l_load_id, l_step_id, 'p_load_f_box_street_executions_daily STARTED===', 0, 'O')
   into l_step_id;


   -- Variables definition
   l_cur_date_id   := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::integer);
   l_min_gtc_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '180 days', 'YYYYMMDD')::integer;




  --> delete calculated data befor recalculation
    delete
    from external_data.f_box_street_executions t
    where t.create_date_id = l_cur_date_id -- date_id of street orders
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'cleanup of external_data.f_box_street_executions before calculation. l_cur_date_id = '||l_cur_date_id::varchar, l_row_cnt , 'R')
     into l_step_id;


    INSERT INTO external_data.f_box_street_executions
      ( create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst
      , sender_comp_id
      , side
      , price
      , order_qty)
  select
        create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst
      , sender_comp_id
      , side
      , price
      , order_qty
  from
  (

    with str_ord as materialized
      (

        select so.create_date_id, so.client_order_id, so.order_id as order_id, so.fix_message_id -- message of order, not report. Sometimes it points to parent level fix message.
          , po.client_order_id as parent_client_order_id, so.parent_order_id, po.fix_message_id as parent_fix_message_id, po.create_date_id as parent_create_date_id, count(1)
          , so.orig_order_id, so_org.client_order_id as street_orig_client_order_id, po_org.client_order_id as parent_orig_client_order_id
          , so.multileg_reporting_type, so.client_id_text, ac.account_name, so.instrument_id
        from dwh.client_order so
          left join dwh.d_account ac
            on so.account_id = ac.account_id
          left join lateral
            (
              select po.client_order_id, po.create_date_id, po.fix_message_id, po.orig_order_id
              from dwh.client_order po
              where po.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and po.order_id = so.parent_order_id
                --and  cross_order_id is not null
              limit 1
            ) po on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = so.orig_order_id
              limit 1
            ) so_org on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = po.orig_order_id
              limit 1
            ) po_org on true
        where so.parent_order_id is not null -- street level
          and so.create_date_id = l_cur_date_id -- between 20190509 and 20190517 -- = 20190515 --l_cur_date_id
          --and so.ex_destination = 'W' -- box -- a little bit slower than via exchange_id
          and so.exchange_id in (select ex.exchange_id from dwh.d_exchange ex where ex.real_exchange_id = 'BOX')
          and so.multileg_reporting_type in ('1','2')
          and so.cross_order_id is not null
          --and so.client_order_id in ('AAA0053-20190514','LAA2248-20190517','MTA2616-20190509','MTA3809-20190509','MTA2333-20190513', 'MTA2355-20190513', 'MTA3079-20190510', 'MTA3086-20190510')
        group by so.create_date_id, so.client_order_id, so.order_id, so.fix_message_id, po.client_order_id, so.parent_order_id, po.fix_message_id, po.create_date_id
          , so.orig_order_id, so_org.client_order_id, po_org.client_order_id
          , so.multileg_reporting_type, so.client_id_text, ac.account_name, so.instrument_id
      )
    select str.create_date_id --count(1) -- 131309
      , sef.message_type
      , coalesce(sef.exec_type, ser.exec_type) as exec_type -- in executions we have replacement of 1 and 2 into F
      , ser.order_status
      , str.client_order_id as street_client_order_id
      , coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id) as street_orig_client_order_id
      --, str.street_orig_client_order_id --, sef.street_orig_client_order_id

      , sef.street_order_id as street_order_id -- 37
      , coalesce(ser.exch_exec_id, sef.street_exec_id) as street_exec_id -- 17 ? why aren't they equal
      , coalesce(ser.secondary_order_id, sef.street_secondary_order_id) as street_secondary_order_id
      , sef.street_orig_exec_id as street_orig_exec_id -- 19

      , coalesce(sef.street_transact_time, ser.exec_time) as street_transact_time
      , sef.street_sending_time as street_sending_time
      , sef.street_routed_time as street_routed_time
      , sef.target_location_id as target_location_id -- it is only for orders reports sent to exchange
      , coalesce(str.client_id_text, sef.client_id) as client_id
      , sef.clearing_optional_data -- 9324

      , str.parent_client_order_id
      , per.exch_exec_id as parent_exec_id
      , str.parent_orig_client_order_id
      , per.secondary_order_id as parent_secondary_order_id
      , per.secondary_exch_exec_id as parent_secondary_exec_id


      -- additional information needed
      , str.parent_create_date_id
      , sef.street_instrument_type
      , row_number() over (partition by str.client_order_id, ser.exch_exec_id, coalesce(sef.account_name, str.account_name) order by str.order_id) as rn1 -- need only one order record for multileg
      , row_number() over (partition by str.create_date_id, sef.message_type, str.client_order_id, sef.street_order_id, coalesce(ser.exch_exec_id, sef.street_exec_id), coalesce(sef.account_name, str.account_name), str.instrument_id order by str.order_id) as rn2 -- deduplication when we have (43) PossDupFlag = 'Y' (BAA0002-20181002)
      , coalesce(sef.account_name, str.account_name) as street_account_name

      -- requested by John
      , sef.fix_tag_115 as on_behalf_of_comp_id
      , sef.fix_tag_423 as price_type
      , sef.fix_tag_18 as exec_inst
      , sef.sender_comp_id
      , sef.side
      , sef.price::numeric
      , sef.order_qty::int

    from
      (
        select str.order_id -- for executions -> reports lookup
          , str.parent_order_id  -- for executions -> reports of parent orders lookup
          , null::bigint as fix_message_id        -- for orders messages lookup
          , null::bigint as parent_fix_message_id -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_id_text
          , str.parent_client_order_id
          , null as parent_orig_client_order_id
          , null as parent_create_date_id
          , str.account_name
          , str.instrument_id
        from str_ord  str -- the list of street orders
        union all
        select distinct null::bigint as order_id -- for executions -> reports lookup
          , null::bigint as parent_order_id     -- for executions -> reports of parent orders lookup
          , str.fix_message_id         -- for orders messages lookup
          , str.parent_fix_message_id  -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_id_text
          , str.parent_client_order_id
          , str.parent_orig_client_order_id
          , str.parent_create_date_id
          , str.account_name
          , null::bigint as instrument_id
        from str_ord  str -- the list of street orders
      ) str -- the list of street orders plus their orders fix message ids
      left join lateral
      (
        select -- for return
            e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- for join
          , e.fix_message_id, e.exec_id, e.order_id, e.exec_text
          --, e.*
        from dwh.execution e
        where 1=1
          and e.fix_message_id is not null -- if it is null then there is possibility that execution is syntethic generated
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.order_id -- in (1679652736,1679652738,1679652740,1679660660,1679660663,1679660666) --
          and e.exec_type not in ('4', 'A', 'b')
          --and not exists (select 1 from fix_capture.fix_message_json j where j.date_id = 20190513 and j.fix_message_id = e.fix_message_id and ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' ))
          --and e.order_id = 1679652736 -- in (1679652736,1679652738,1679652740) -- (1674593569, 1674593570, 1674593571) --
      ) ser on true -- street executions reports from exchange
      inner join lateral
      (
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
          , j.fix_message->>'49' as sender_comp_id
          , j.fix_message->>'54' as side
          , j.fix_message->>'44' as price
          , j.fix_message->>'38' as order_qty
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = ser.fix_message_id -- coalesce(ser.fix_message_id, fix_message_id) --in (3914795705, 3914778052) -- message for street report and not orders
          and j.fix_message->>'9383' = 'R'
          -- try to exclude multileg reports except rejects
          --and not ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' )
        union
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
          , j.fix_message->>'49' as sender_comp_id
          , j.fix_message->>'54' as side
          , j.fix_message->>'44' as price
          , j.fix_message->>'38' as order_qty
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = str.fix_message_id ---  3914778051 --  in (3914795705, 3914778052) -- message for street order and not report
          and j.fix_message->>'9383' = 'R'
      ) sef on true -- street execution fix messages for reports from exchange
      left join lateral
      (
        select -- fields to return
            e.fix_message_id -- for return
          , e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- other fields
          , e.fix_message_id, e.exec_id, e.order_id, e.exec_text
          --, e.*
        from dwh.execution e
        where 1=1
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.parent_order_id -- (1674593565, 1674593567)  two legs with their own parents
          -- get rid of multileg message
          and (e.secondary_order_id is not null or e.order_status = '0')
          -- status matching
          and
            (
              e.secondary_exch_exec_id = ser.exch_exec_id
              or
              (e.order_status = '0' and ser.order_status = '0')
            )
        order by e.secondary_order_id desc nulls last, e.exec_time desc -- in case of presence both mleg and opt order executions for order with status = '0'
        limit 1
      ) per on true -- parent execution reports from exchange
 -- order by coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id, str.client_order_id), sef.street_routed_time

    ) src
  where 1=1 and (case when src.street_instrument_type = 'MLEG' then src.rn1 else 1 end = 1) and src.rn2 = 1
  --order by coalesce(src.street_orig_client_order_id, src.street_client_order_id), src.street_routed_time
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Load into external_data.f_box_street_executions ', l_row_cnt , 'I')
     into l_step_id;



  select public.load_log(l_load_id, l_step_id, 'p_load_f_box_street_executions_daily COMPLETE ========= ' , 0, 'O')
   into l_step_id;
  RETURN 1;

exception when others then
  select public.load_log(l_load_id, l_step_id, sqlerrm , 0, 'E')
  into l_step_id;
  -- PERFORM public.load_error_log('p_load_f_box_street_executions_daily',  'I', sqlerrm, l_load_id);

  RAISE;

END;
$$;



CREATE or replace FUNCTION external_data.p_load_f_cboe_street_executions_daily(in_date_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
   l_row_cnt integer;

   l_load_id int;
   l_step_id int;

   l_cur_date_id integer;
   l_min_gtc_date_id integer;

BEGIN
  /*
    we don't need to run this AFTER the HODS processed.
  */

  --if in_recalc_date_id is null
  --then return -1;
  --end if;

  select nextval('public.load_timing_seq') into l_load_id;

  l_step_id:=1;

  select public.load_log(l_load_id, l_step_id, 'p_load_f_cboe_street_executions_daily STARTED===', 0, 'O')
   into l_step_id;


   -- Variables definition
   l_cur_date_id   := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::integer);
   l_min_gtc_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '180 days', 'YYYYMMDD')::integer;


  -- Temporary table definition

/*    execute 'CREATE TEMP TABLE IF NOT EXISTS tmp_cboe_street_orders (
      create_date_id int4 NULL,
      client_order_id varchar(256) NULL,
      parent_client_order_id varchar(256) NULL,
      parent_create_date_id int4 NULL,
      orders_count int4 NULL,
      CONSTRAINT "tmp_PK_tmp_cboe_street_orders" PRIMARY KEY (parent_client_order_id, create_date_id, client_order_id)
    )';

  execute 'truncate table tmp_cboe_street_orders';
*/

-- fill Temp table

/*    insert into tmp_cboe_street_orders
      (
        create_date_id,
        client_order_id,
        parent_client_order_id,
        parent_create_date_id,
        orders_count
      )
    select so.create_date_id, so.client_order_id, po.client_order_id as parent_client_order_id, po.create_date_id as parent_create_date_id, count(1)
    from dwh.client_order so
      left join lateral
        (
          select po.client_order_id, po.create_date_id
          from dwh.client_order po
          where po.create_date_id between l_min_gtc_date_id and l_cur_date_id --20190414 and 20190514
            and po.order_id = so.parent_order_id
          limit 1
        ) po on true
    where so.parent_order_id is not null -- street level
      and so.create_date_id = l_cur_date_id
      --and so.ex_destination = 'W' -- CBOE -- a little bit slower than via exchange_id
      and so.exchange_id in (select ex.exchange_id from dwh.d_exchange ex where ex.real_exchange_id = 'CBOE') -- быстрее
    group by so.create_date_id, so.client_order_id, po.client_order_id, po.create_date_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'street orders loaded into tmp_cboe_street_orders ', l_row_cnt , 'I')
     into l_step_id;

    ANALYZE tmp_cboe_street_orders;
    select public.load_log(l_load_id, l_step_id, 'Statistics gathered for tmp_cboe_street_orders ', 0 , 'O')
     into l_step_id;

 IF (l_row_cnt > 0) -- we have some data loaded
  THEN

  --> correction of Min date_id for parent orders
    select coalesce( (select min(parent_create_date_id) from tmp_cboe_street_orders), l_min_gtc_date_id) into l_min_gtc_date_id
    ;
    select public.load_log(l_load_id, l_step_id, 'Calculation date_id = '||l_cur_date_id::varchar||', MIN parent orders date_id = '||l_min_gtc_date_id::varchar, 0 , 'O')
     into l_step_id;

  --> delete calculated data befor recalculation
    delete
    from external_data.f_cboe_street_executions t
    where t.create_date_id = l_cur_date_id -- date_id of street orders
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'cleanup of external_data.f_cboe_street_executions before calculation.', l_row_cnt , 'D')
     into l_step_id;

  --> insert data
    INSERT INTO external_data.f_cboe_street_executions
      ( create_date_id
      , message_type
      , parent_message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_routed_time
      , parent_create_date_id )

--select count(1) into l_row_cnt from (
    select str.create_date_id
      , fs.message_type_2 as message_type
      , fp.message_type_2 as parent_message_type
      , fs.exec_type
      , fs.order_status
      , fs.street_client_order_id
      , fs.street_orig_client_order_id
      , fs.street_order_id
      , fs.street_exec_id
      , fs.street_secondary_order_id
      , fs.street_orig_exec_id
      --, to_char(fs.street_transact_time, 'YYYY-MM-DD HH24:MI:SS.MS') as street_transact_time
      --, to_char(fs.street_sending_time, 'YYYY-MM-DD HH24:MI:SS.MS') as street_sending_time
      --, to_char(fs.street_routed_time, 'YYYY-MM-DD HH24:MI:SS.US') as street_routed_time
      , fs.street_transact_time
      , fs.street_sending_time
      , fs.street_routed_time
      , fs.target_location_id
      , fs.client_id
      , fs.clearing_optional_data
      , coalesce(fs.parent_client_order_id, str.parent_client_order_id) as parent_client_order_id
      , fp.parent_exec_id
      , fp.parent_orig_client_order_id
      , fp.parent_secondary_order_id
      , fp.parent_secondary_exec_id
      , fp.parent_routed_time
      , case when fs.message_type not in ('8','9') then str.parent_create_date_id end as parent_create_date_id
      --select count(1) -- should be about 300k. nope. only 116k and it takes about 4 minutes to filter out street orders
    from
      (
        select tmp.create_date_id, tmp.client_order_id, tmp.parent_client_order_id, tmp.parent_create_date_id, tmp.orders_count
        from tmp_cboe_street_orders tmp
        --from staging.sdn_tmp_cboe_street_orders tmp
        --limit 10000
      ) str -- the list of street orders
      left join lateral
      (
        select j.message_type
          , j.fix_message->>'35' as message_type_2
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'39' as order_status
          , j.fix_message->>'11' as street_client_order_id
          , j.fix_message->>'41' as street_orig_client_order_id
          --, to_timestamp(j.fix_message->>'5050', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as routed_time_5050
          --, to_timestamp(j.fix_message->>'5051', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as routed_time_5051
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , j.fix_message->>'143' as target_location_id
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , coalesce(j.fix_message->>'10442', j.fix_message->>'5059')::varchar as parent_client_order_id
          -- additional attrinutes as 9769 tag is often missed in parent reports
          , j.fix_message->>'55' as symbol
          , j.fix_message->>'167' as instrument_type
          , j.fix_message->>'200' as exp_ym
          , j.fix_message->>'205' as exp_day
          , j.fix_message->>'201' as put_call
          , j.fix_message->>'202' as strike_px
          , j.fix_message->>'31' as last_px
          , j.fix_message->>'32' as last_qty
        from fix_capture.fix_message_json j
        where j.date_id = l_cur_date_id::integer
          and j.date_id = str.create_date_id
          and j.client_order_id = str.client_order_id
          and not ((j.fix_message->>'35')::varchar in ('8','9') and ((j.fix_message->>'167')::varchar = 'MLEG' or (j.fix_message->>'150')::varchar = '4' ))
        limit 1000 -- executions count for one street_client_order_id
      ) fs on true -- fix_str
      left join lateral
      (
        select j.message_type
          , j.fix_message->>'35' as message_type_2
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'39' as order_status
          , j.client_order_id
          , j.fix_message->>'17' as parent_exec_id
          , j.fix_message->>'41' as parent_orig_client_order_id
          , j.fix_message->>'198' as parent_secondary_order_id
          , j.fix_message->>'9769' as parent_secondary_exec_id
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as parent_routed_time
        from fix_capture.fix_message_json j
        where j.date_id = l_cur_date_id::integer --between l_min_gtc_date_id and l_cur_date_id
          --and j.date_id = str.create_date_id -- this is a question
          --and case when j.message_type in ('8','9') then str.create_date_id else str.parent_create_date_id end = j.date_id

--какой date_id у GTC-шного парентового ордера нам нужен?
-- теоретически для ордера - дата клайант-ордера
-- для репорта = дата репорта

          and j.client_order_id = str.parent_client_order_id --coalesce(fs.parent_client_order_id, str.parent_client_order_id)
          and ( (j.fix_message->>'9769')::varchar = fs.street_exec_id
               or
               ( ( ( (j.fix_message->>'442')::varchar = '2' -- only for legs including last prices and qty's
                     and (j.fix_message->>'31')::numeric = fs.last_px::numeric
                     and (j.fix_message->>'32')::varchar = fs.last_qty::varchar
                   )
                    or fs.exec_type = '0' -- first report can also not to have 9769 tag
                 )
                 --   (j.fix_message->>'39')::varchar = fs.order_status
                and (j.fix_message->>'150')::varchar <> 'E' -- not "pending replace" - exec_type
                and (case when (j.fix_message->>'150')::varchar = '5' then '0' else j.fix_message->>'150' end)::varchar = fs.exec_type -- Replaced status of report will be equal to New
                and (j.fix_message->>'55')::varchar = fs.symbol
                and (j.fix_message->>'167')::varchar = fs.instrument_type
                and coalesce((j.fix_message->>'200')::varchar, '-1') = coalesce(fs.exp_ym, '-1') -- exp_year_month
                and coalesce((j.fix_message->>'205')::varchar, '-1') = coalesce(fs.exp_day, '-1') -- exp_day
                and coalesce((j.fix_message->>'201')::varchar, '-1') = coalesce(fs.put_call, '-1') -- put_call
                and coalesce((j.fix_message->>'202')::numeric, '-1') = coalesce(fs.strike_px::numeric, '-1') -- strike
                --and (  )
               )
               or
               ( fs.message_type not in ('8','9') -- in case of orders(not reports). Just match them
                 --and (j.fix_message->>'41')::varchar = fs.
               )
              )
          and not ((j.fix_message->>'35')::varchar in ('8','9') and ((j.fix_message->>'167')::varchar = 'MLEG' or (j.fix_message->>'150')::varchar in ('4','E') ))
          and case when j.message_type in ('8','9') then 'r' else 'o' end = case when fs.message_type in ('8','9') then 'r' else 'o' end -- order messages to orders, reports to reports
        limit 1 -- just in case. We need one to one, street to parent matched executions.
      ) fp on true -- fix_par
    --order by coalesce(fs.street_orig_client_order_id, fs.street_client_order_id), fs.street_routed_time
--  ) src
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Load into external_data.f_cboe_street_executions ', l_row_cnt , 'I')
     into l_step_id;
*/

  --> delete calculated data befor recalculation
    delete
    from external_data.f_cboe_street_executions t
    where t.create_date_id = l_cur_date_id -- date_id of street orders
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'cleanup of external_data.f_cboe_street_executions before calculation. l_cur_date_id = '||l_cur_date_id::varchar, l_row_cnt , 'R')
     into l_step_id;


    INSERT INTO external_data.f_cboe_street_executions
      ( create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst)
  select
        create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst
  from
  (

    with str_ord as materialized
      (
        --select tmp.create_date_id, tmp.client_order_id, tmp.parent_client_order_id, tmp.parent_create_date_id, tmp.orders_count
        --from tmp_cboe_street_orders tmp
        --from staging.sdn_tmp_cboe_street_orders  tmp
        --limit 10000

        select so.create_date_id, so.client_order_id, so.order_id as order_id, so.fix_message_id -- message of order, not report. Sometimes it points to parent level fix message.
          , po.client_order_id as parent_client_order_id, so.parent_order_id, po.fix_message_id as parent_fix_message_id, po.create_date_id as parent_create_date_id, count(1)
          , so.orig_order_id, so_org.client_order_id as street_orig_client_order_id, po_org.client_order_id as parent_orig_client_order_id
          , so.multileg_reporting_type, so.client_id_text, ac.account_name, so.instrument_id
        from dwh.client_order so
          left join dwh.d_account ac
            on so.account_id = ac.account_id
          left join lateral
            (
              select po.client_order_id, po.create_date_id, po.fix_message_id, po.orig_order_id
              from dwh.client_order po
              where po.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and po.order_id = so.parent_order_id
              limit 1
            ) po on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = so.orig_order_id
              limit 1
            ) so_org on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = po.orig_order_id
              limit 1
            ) po_org on true
        where so.parent_order_id is not null -- street level
          and so.create_date_id = l_cur_date_id -- between 20190509 and 20190517 -- = 20190515 --l_cur_date_id
          --and so.ex_destination = 'W' -- CBOE -- a little bit slower than via exchange_id
          and so.exchange_id in (select ex.exchange_id from dwh.d_exchange ex where ex.real_exchange_id = 'CBOE' union select 'C1PAR' union select 'CBOEEH') -- быстрее
          and so.multileg_reporting_type in ('1','2')
          --and so.client_order_id in ('AAA0053-20190514','LAA2248-20190517','MTA2616-20190509','MTA3809-20190509','MTA2333-20190513', 'MTA2355-20190513', 'MTA3079-20190510', 'MTA3086-20190510')
        group by so.create_date_id, so.client_order_id, so.order_id, so.fix_message_id, po.client_order_id, so.parent_order_id, po.fix_message_id, po.create_date_id
          , so.orig_order_id, so_org.client_order_id, po_org.client_order_id
          , so.multileg_reporting_type, so.client_id_text, ac.account_name, so.instrument_id
      )
    select str.create_date_id --count(1) -- 131309
      , sef.message_type
      , coalesce(sef.exec_type, ser.exec_type) as exec_type -- in executions we have replacement of 1 and 2 into F
      , ser.order_status
      , str.client_order_id as street_client_order_id
      , coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id) as street_orig_client_order_id
      --, str.street_orig_client_order_id --, sef.street_orig_client_order_id

      , sef.street_order_id as street_order_id -- 37
      , coalesce(ser.exch_exec_id, sef.street_exec_id) as street_exec_id -- 17 ? why aren't they equal
      , coalesce(ser.secondary_order_id, sef.street_secondary_order_id) as street_secondary_order_id
      , sef.street_orig_exec_id as street_orig_exec_id -- 19

      , coalesce(sef.street_transact_time, ser.exec_time) as street_transact_time
      , sef.street_sending_time as street_sending_time
      , sef.street_routed_time as street_routed_time
      , sef.target_location_id as target_location_id -- it is only for orders reports sent to exchange
      , coalesce(str.client_id_text, sef.client_id) as client_id
      , sef.clearing_optional_data -- 9324

      , str.parent_client_order_id
      , per.exch_exec_id as parent_exec_id
      , str.parent_orig_client_order_id
      , per.secondary_order_id as parent_secondary_order_id
      , per.secondary_exch_exec_id as parent_secondary_exec_id


      -- additional information needed
      , str.parent_create_date_id
      , sef.street_instrument_type
      , row_number() over (partition by str.client_order_id, ser.exch_exec_id, coalesce(sef.account_name, str.account_name) order by str.order_id) as rn1 -- need only one order record for multileg
      , row_number() over (partition by str.create_date_id, sef.message_type, str.client_order_id, sef.street_order_id, coalesce(ser.exch_exec_id, sef.street_exec_id), coalesce(sef.account_name, str.account_name), str.instrument_id order by str.order_id) as rn2 -- deduplication when we have (43) PossDupFlag = 'Y' (BAA0002-20181002)
      , coalesce(sef.account_name, str.account_name) as street_account_name

      -- requested by John
      , sef.fix_tag_115 as on_behalf_of_comp_id
      , sef.fix_tag_423 as price_type
      , sef.fix_tag_18 as exec_inst

      /*, sef.client_order
      , str.fix_message_id
      , str.order_id
      , str.multileg_reporting_type
      , str.parent_order_id
      --, ser.* --exec_id
      , per.* */

    from
      (
        select str.order_id -- for executions -> reports lookup
          , str.parent_order_id  -- for executions -> reports of parent orders lookup
          , null::bigint as fix_message_id        -- for orders messages lookup
          , null::bigint as parent_fix_message_id -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_id_text
          , str.parent_client_order_id
          , null as parent_orig_client_order_id
          , null as parent_create_date_id
          , str.account_name
          , str.instrument_id
        from str_ord  str -- the list of street orders
        union all
        select distinct null::bigint as order_id -- for executions -> reports lookup
          , null::bigint as parent_order_id     -- for executions -> reports of parent orders lookup
          , str.fix_message_id         -- for orders messages lookup
          , str.parent_fix_message_id  -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_id_text
          , str.parent_client_order_id
          , str.parent_orig_client_order_id
          , str.parent_create_date_id
          , str.account_name
          , null::bigint as instrument_id
        from str_ord  str -- the list of street orders
      ) str -- the list of street orders plus their orders fix message ids
      left join lateral
      (
        select -- for return
            e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- for join
          , e.fix_message_id, e.exec_id, e.order_id, e.exec_text
          --, e.*
        from dwh.execution e
        where 1=1
          and e.fix_message_id is not null -- if it is null then there is possibility that execution is syntethic generated
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.order_id -- in (1679652736,1679652738,1679652740,1679660660,1679660663,1679660666) --
          and e.exec_type not in ('4', 'A', 'b')
          --and not exists (select 1 from fix_capture.fix_message_json j where j.date_id = 20190513 and j.fix_message_id = e.fix_message_id and ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' ))
          --and e.order_id = 1679652736 -- in (1679652736,1679652738,1679652740) -- (1674593569, 1674593570, 1674593571) --
      ) ser on true -- street executions reports from exchange
      inner join lateral
      (
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = ser.fix_message_id -- coalesce(ser.fix_message_id, fix_message_id) --in (3914795705, 3914778052) -- message for street report and not orders
          -- try to exclude multileg reports except rejects
          --and not ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' )
        union
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = str.fix_message_id ---  3914778051 --  in (3914795705, 3914778052) -- message for street order and not report
      ) sef on true -- street execution fix messages for reports from exchange
      left join lateral
      (
        select -- fields to return
            e.fix_message_id -- for return
          , e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- other fields
          , e.fix_message_id, e.exec_id, e.order_id, e.exec_text
          --, e.*
        from dwh.execution e
        where 1=1
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.parent_order_id -- (1674593565, 1674593567)  two legs with their own parents
          -- get rid of multileg message
          and (e.secondary_order_id is not null or e.order_status = '0')
          -- status matching
          and
            (
              e.secondary_exch_exec_id = ser.exch_exec_id
              or
              (e.order_status = '0' and ser.order_status = '0')
            )
        order by e.secondary_order_id desc nulls last, e.exec_time desc -- in case of presence both mleg and opt order executions for order with status = '0'
        limit 1
      ) per on true -- parent execution reports from exchange
 -- order by coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id, str.client_order_id), sef.street_routed_time

    ) src
  where 1=1 and (case when src.street_instrument_type = 'MLEG' then src.rn1 else 1 end = 1) and src.rn2 = 1
  --order by coalesce(src.street_orig_client_order_id, src.street_client_order_id), src.street_routed_time
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Load into external_data.f_cboe_street_executions ', l_row_cnt , 'I')
     into l_step_id;


  --> update GTC parent orders data
/*    update external_data.f_cboe_street_executions trg
      set parent_orig_client_order_id = src.parent_orig_client_order_id
        , parent_routed_time = src.parent_routed_time
        , parent_message_type = src.parent_message_type
    from
      (
        select to_timestamp(to_char(o.process_time, 'YYYY-MM-DD HH24:MI:SS')::varchar||'.'||o.process_time_micsec, 'YYYY-MM-DD HH24:MI:SS.US')::timestamp without time zone as parent_routed_time
          , oo.client_order_id as parent_orig_client_order_id
          , o.trans_type as parent_message_type
          , o.client_order_id as parent_client_order_id
          , o.create_date_id as parent_create_date_id
          , s.street_client_order_id
          , s.create_date_id
          , row_number() over (partition by s.street_client_order_id, o.client_order_id, o.create_date_id order by o.process_time) as rn
        from external_data.f_cboe_street_executions s
          inner join dwh.client_order o -- parent order
            on o.create_date_id between l_min_gtc_date_id and l_cur_date_id
            and o.client_order_id = s.parent_client_order_id
            and o.create_date_id = s.parent_create_date_id
            and o.multileg_reporting_type in ('1','3')
          left join dwh.client_order oo
            on o.orig_order_id = oo.order_id
        where s.create_date_id = l_cur_date_id
          and s.parent_create_date_id is not null
          and s.parent_routed_time is null
      ) src
    where trg.create_date_id = l_cur_date_id
      and trg.create_date_id = src.create_date_id
      and trg.parent_create_date_id is not null -- message type not in (8,9)
      and trg.parent_routed_time is null
      and trg.street_client_order_id = src.street_client_order_id
      and trg.parent_client_order_id = src.parent_client_order_id
      and src.rn = 1 -- it is not needed, but just in case
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'UPD of GTC parent orders data ', l_row_cnt , 'U')
     into l_step_id;

 END IF; */
---------------------------------------------------------------------------------------------------------
  select public.load_log(l_load_id, l_step_id, 'p_load_f_cboe_street_executions_daily COMPLETE ========= ' , 0, 'O')
   into l_step_id;
  RETURN 1;

exception when others then
  select public.load_log(l_load_id, l_step_id, sqlerrm , 0, 'E')
  into l_step_id;
  -- PERFORM public.load_error_log('p_load_f_cboe_street_executions_daily',  'I', sqlerrm, l_load_id);

  RAISE;

END;
$$;



CREATE or replace FUNCTION staging.load_temp_conditional_execution(in_l_seq integer, in_l_step integer, in_l_table_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$ declare
			date_id_curs cursor for select distinct date_id from staging.temp_conditional_execution where rtrim(operation )= 'I';
			l_sql text;
			l_date_id int;
			l_in_l_seq int;
			l_in_l_step int;
			l_in_table_name text;
	--		e1_step int;
	--		e2_step int;
begin
--e1_step:=0;
--e2_step:=0;
l_in_l_seq:= in_l_seq;
l_in_l_step:=in_l_step;
l_in_table_name:=in_l_table_name;
l_sql:= 	'insert into dwh.conditional_execution
				(exec_id,exch_exec_id,order_id,fix_message_id,exec_type,order_status,exec_time,leaves_qty,last_mkt,exec_text,is_busted,exchange_id,date_id,
				last_qty,cum_qty,last_px,ref_exec_id)
		select
			exec_id,exch_exec_id,order_id,fix_message_id,exec_type,order_status,exec_time,leaves_qty,last_mkt,text_,is_busted,exchange_id,date_id,
			last_qty,cum_qty,last_px,ref_exec_id
		from staging.temp_conditional_execution
		where operation = ''I'' and date_id = $1
			on conflict (exec_id) do update
				set date_id = coalesce(public.f_insert_etl_reject(''load_temp_conditional_execution''::varchar,''exec_id_pkey'',''(date_id= ''||EXCLUDED.date_id||'',exec_id= ''||EXCLUDED.exec_id||'',exec_time = ''||EXCLUDED.exec_time||'')''::varchar),
					EXCLUDED.date_id);';
open date_id_curs;

loop
fetch  date_id_curs into l_date_id;
exit when not found;

	--l_sql:= replace(l_sql,'&p_date_id',l_date_id::text);
execute l_sql
	using l_date_id;

	select public.load_log (l_in_l_seq,
							l_in_l_step,
							l_in_table_name,
							coalesce ( (select count(1) from staging.temp_conditional_execution where operation = 'I' and date_id = l_date_id),0)::int,
							'I'::text
							)
							into l_in_l_step;
end loop;

close date_id_curs;


	update dwh.conditional_execution a
	set exec_id 	   = EXCLUDED.exec_id,
		exch_exec_id   = EXCLUDED.exch_exec_id,
		order_id 	   = EXCLUDED.order_id,
		fix_message_id = EXCLUDED.fix_message_id,
		exec_type 	   = EXCLUDED.exec_type,
		order_status   = EXCLUDED.order_status,
		exec_time 	   = EXCLUDED.exec_time,
		leaves_qty 	   = EXCLUDED.leaves_qty,
		last_mkt 	   = EXCLUDED.last_mkt,
		exec_text 		   = EXCLUDED.exec_text,
		is_busted 	   = EXCLUDED.is_busted,
		exchange_id    = EXCLUDED.exchange_id,
		date_id 	   = EXCLUDED.date_id,
		last_qty	   = EXCLUDED.last_qty,
		cum_qty 	   = EXCLUDED.cum_qty,
		last_px 	   = EXCLUDED.last_px,
		ref_exec_id	   = EXCLUDED.ref_exec_id
	from staging.temp_conditional_execution  EXCLUDED
	where a.exec_id = EXCLUDED.exec_id
	and operation in('U','UN');

		select public.load_log(
							l_in_l_seq,
							l_in_l_step,
							l_in_table_name,
							coalesce ( (select count(1) from staging.temp_conditional_execution where rtrim(operation)='U' ),0)::int,
							'U'::text
							)
							into l_in_l_step;

return l_in_l_step;
end;
$_$;


CREATE or replace FUNCTION staging.tlnd_load_execution(in_l_seq integer, in_step integer, in_table_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
 	date_id_crs cursor for select distinct exec_date_id from staging.tlnd_temp_execution  where rtrim(operation)='I';
	l_sql_block text;
	l_sql text;
	l_date_id int;
	l_in_l_seq int;
	l_in_date_id_list text;
	l_in_step int;
	l_in_table_name text;
	e1_step int;
	date_id_crs_up cursor for select distinct exec_date_id from staging.tlnd_temp_execution where rtrim(operation)='UN';
	l_exec_analyze text;
	interval_rez int;
	neighbourhood int;
	last_partition_name text;
	l_sql_block2 text;
 begin
	e1_step :=0;
	l_in_l_seq:= in_l_seq;
	l_in_step:= in_step;
	--l_in_date_id_list:= in_date_id_list;
--	select string_agg(exec_date_id::varchar,',')
--		into l_in_date_id_list
--		from staging.tlnd_temp_execution
--		where operation='UN';
	select string_agg(exec_date_id::varchar,',')
		into l_in_date_id_list
		from(
			select distinct exec_date_id
				from staging.tlnd_temp_execution
					where operation='UN'
			)f ;

	l_in_table_name:= in_table_name;

	l_sql_block := 'INSERT INTO  partitions.execution_&p_month_id
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													exec_text, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt
				 FROM staging.tlnd_temp_execution
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt > 1
			on conflict (exec_id) do update
   set exec_date_id = coalesce(public.f_insert_etl_reject(''load_temp_execution''::varchar,''execution_202101_exec_id_exec_date_id_idx'',''(exec_date_id= ''||EXCLUDED.exec_date_id||'',exec_id= ''||EXCLUDED.exec_id||'',exec_time = ''||EXCLUDED.exec_time||'')''::varchar),
   EXCLUDED.exec_date_id),
		secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
		secondary_order_id= EXCLUDED.secondary_order_id,
		trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
		avg_px= EXCLUDED.avg_px,
		bust_qty= EXCLUDED.bust_qty,
		contra_account_capacity= EXCLUDED.contra_account_capacity,
		contra_broker= EXCLUDED.contra_broker,
		cum_qty= EXCLUDED.cum_qty,
		exch_exec_id= EXCLUDED.exch_exec_id,
		exec_time= EXCLUDED.exec_time,
		exec_type= EXCLUDED.exec_type,
		fix_message_id= EXCLUDED.fix_message_id,
		account_id= EXCLUDED.account_id,
		is_billed= EXCLUDED.is_billed,
		is_busted= EXCLUDED.is_busted,
		last_mkt= EXCLUDED.last_mkt,
		last_px= EXCLUDED.last_px,
		last_qty= EXCLUDED.last_qty,
		leaves_qty= EXCLUDED.leaves_qty,
		order_id= EXCLUDED.order_id,
		order_status= EXCLUDED.order_status,
		exec_text=EXCLUDED.exec_text ,
		is_parent_level = EXCLUDED.is_parent_level,
		exec_broker=EXCLUDED.exec_broker,
		dataset_id = EXCLUDED.dataset_id,
		auction_id = EXCLUDED.auction_id,
		match_qty = EXCLUDED.match_qty,
		match_px = EXCLUDED.match_px,
		internal_component_type = EXCLUDED.internal_component_type,
		exchange_id = EXCLUDED.exchange_id,
		contra_trader = EXCLUDED.contra_trader,
		ref_exec_id = EXCLUDED.ref_exec_id;';


l_sql_block2 := 'INSERT INTO  partitions.execution_&p_month_id
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													exec_text, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt
				 FROM staging.tlnd_temp_execution
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt = 1
			on conflict (exec_id) do nothing;';

	raise INFO 'SQL prepared';
	analyze staging.tlnd_temp_execution;
	raise INFO '%: analyze DONE', clock_timestamp() ;

	open date_id_crs;

	loop
	fetch date_id_crs into l_date_id;
	exit when not found;

		l_sql := replace (l_sql_block ,'&p_month_id', substring(l_date_id::text,1,6));
		l_sql := replace (l_sql ,'&p_date_id', l_date_id::text);

	raise INFO '%: executing INSERT %', clock_timestamp() , l_date_id;
	EXECUTE l_sql;
	raise INFO '%: DONE INSERT %', clock_timestamp() , l_date_id;

		select public.load_log(
							l_in_l_seq,
							l_in_step,
							l_in_table_name::text,
						coalesce ((select count(1) from staging.tlnd_temp_execution where rtrim(operation)='I' and exec_date_id = l_date_id),0)::int,
						'M'::text
						) into l_in_step
					;

		l_sql := replace (l_sql_block2 ,'&p_month_id', substring(l_date_id::text,1,6));
		l_sql := replace (l_sql ,'&p_date_id', l_date_id::text);

	raise INFO '%: executing INSERT2 %', clock_timestamp() , l_date_id;
	EXECUTE l_sql;
	raise INFO '%: executing DONE %', clock_timestamp() , l_date_id;

		select public.load_log(
							l_in_l_seq,
							l_in_step,
							l_in_table_name::text,
						coalesce ((select count(1) from staging.tlnd_temp_execution where rtrim(operation)='I' and exec_date_id = l_date_id),0)::int,
						'I'::text
						) into l_in_step
					;

	end loop;

	close date_id_crs;

--	l_exec_analyze:= 'analyze partitions.execution_'||left(right(l_in_date_id_list, 8), 6);
--	execute l_exec_analyze;

	neighbourhood:= 3600; --60 min
	last_partition_name:= 'select execution_'||left(right(l_in_date_id_list, 8), 6); --extract last date from date_id_list in format YYYYMM

	select abs(date_part('epoch'::text, clock_timestamp() AT TIME ZONE 'US/Eastern'
										- (clock_timestamp()::date::timestamp AT TIME ZONE 'US/Eastern' + interval '8 hours 15 minutes') --8:15 AM current date
						)
				) into interval_rez;
	--analyze only between 7:15 and 9:15
	if (interval_rez < neighbourhood) then
		perform  dwh.analyse_statistics (in_schema_name => 'partitions', in_table_name => last_partition_name, in_max_interval => 600);
	end if;

--			UPDATE dwh.execution ex
--				SET
--				secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
--				secondary_order_id= EXCLUDED.secondary_order_id,
--				trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
--				avg_px= EXCLUDED.avg_px,
--				bust_qty= EXCLUDED.bust_qty,
--				contra_account_capacity= EXCLUDED.contra_account_capacity,
--				contra_broker= EXCLUDED.contra_broker,
--				cum_qty= EXCLUDED.cum_qty,
--				exch_exec_id= EXCLUDED.exch_exec_id,
--				exec_time= EXCLUDED.exec_time,
--				exec_type= EXCLUDED.exec_type,
--				exec_date_id= EXCLUDED.exec_date_id,
--				fix_message_id= EXCLUDED.fix_message_id,
--				account_id= EXCLUDED.account_id,
--				is_billed= EXCLUDED.is_billed,
--				is_busted= EXCLUDED.is_busted,
--				last_mkt= EXCLUDED.last_mkt,
--				last_px= EXCLUDED.last_px,
--				last_qty= EXCLUDED.last_qty,
--				leaves_qty= EXCLUDED.leaves_qty,
--				order_id= EXCLUDED.order_id,
--				order_status= EXCLUDED.order_status,
--				text_=EXCLUDED.text_ ,
--				is_parent_level = EXCLUDED.is_parent_level,
--				exec_broker=EXCLUDED.exec_broker,
--				dataset_id = EXCLUDED.dataset_id,
--				auction_id = EXCLUDED.auction_id,
--				match_qty = EXCLUDED.match_qty,
--				match_px = EXCLUDED.match_px,
--				internal_component_type = EXCLUDED.internal_component_type,
--				exchange_id = EXCLUDED.exchange_id,
--				contra_trader = EXCLUDED.contra_trader,
--				ref_exec_id = EXCLUDED.ref_exec_id
--			FROM  staging.tlnd_temp_execution  EXCLUDED
--				WHERE  ex.exec_id = EXCLUDED.exec_id
--				and ex.exec_date_id = EXCLUDED.exec_date_id
--				and EXCLUDED.operation='UN'
--				and ex.exec_date_id in(SELECT c::int FROM regexp_split_to_table((select l_in_date_id_list),',') as c);
if l_in_date_id_list is not null
 then
execute 'UPDATE dwh.execution ex
				SET
				secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
				secondary_order_id= EXCLUDED.secondary_order_id,
				trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
				avg_px= EXCLUDED.avg_px,
				bust_qty= EXCLUDED.bust_qty,
				contra_account_capacity= EXCLUDED.contra_account_capacity,
				contra_broker= EXCLUDED.contra_broker,
				cum_qty= EXCLUDED.cum_qty,
				exch_exec_id= EXCLUDED.exch_exec_id,
				exec_time= EXCLUDED.exec_time,
				exec_type= EXCLUDED.exec_type,
				exec_date_id= EXCLUDED.exec_date_id,
				fix_message_id= EXCLUDED.fix_message_id,
				account_id= EXCLUDED.account_id,
				is_billed= EXCLUDED.is_billed,
				is_busted= EXCLUDED.is_busted,
				last_mkt= EXCLUDED.last_mkt,
				last_px= EXCLUDED.last_px,
				last_qty= EXCLUDED.last_qty,
				leaves_qty= EXCLUDED.leaves_qty,
				order_id= EXCLUDED.order_id,
				order_status= EXCLUDED.order_status,
				exec_text=EXCLUDED.exec_text ,
				is_parent_level = EXCLUDED.is_parent_level,
				exec_broker=EXCLUDED.exec_broker,
				dataset_id = EXCLUDED.dataset_id,
				auction_id = EXCLUDED.auction_id,
				match_qty = EXCLUDED.match_qty,
				match_px = EXCLUDED.match_px,
				internal_component_type = EXCLUDED.internal_component_type,
				exchange_id = EXCLUDED.exchange_id,
				contra_trader = EXCLUDED.contra_trader,
				ref_exec_id = EXCLUDED.ref_exec_id
			FROM  staging.tlnd_temp_execution  EXCLUDED
				WHERE  ex.exec_id = EXCLUDED.exec_id
				and ex.exec_date_id = EXCLUDED.exec_date_id
				and EXCLUDED.operation=''UN''
				and ex.exec_date_id in('||l_in_date_id_list||')';
end if;

select public.load_log(
						l_in_l_seq,
						l_in_step,
						l_in_table_name::text,
						coalesce ((select count(1) from staging.tlnd_temp_execution where rtrim(operation)= 'UN'),0)::int,
							'U'::text)
						into l_in_step
					;

select string_agg(exec_date_id::varchar,',')
		into l_in_date_id_list
		from(
			select distinct exec_date_id
				from staging.tlnd_temp_execution
			)f ;

	perform  public.etl_subscribe(l_in_l_seq, 'yield_capture', 'execution', l_in_date_id_list::varchar,coalesce((select count(distinct exec_id) from staging.tlnd_temp_execution /*where rtrim(operation)='I' and cnt > 1*/),0)::int ) ;

	RETURN l_in_step;

 end;
$$;




CREATE or replace PROCEDURE staging.tlnd_load_execution_sp(IN in_l_seq bigint, IN in_step integer, IN in_table_name character varying)
    LANGUAGE plpgsql
    AS $_$DECLARE
 	date_id_crs refcursor; --for select distinct exec_date_id from staging.tlnd_temp_execution  where rtrim(operation)='I';
	l_sql_block text;
	l_sql_block_rejected text;
	l_sql text;
	l_date_id int;
	l_in_l_seq bigint;
	l_in_date_id_list text;
	l_step_id int;
	l_in_table_name text;
	e1_step int;
	date_id_crs_up refcursor;-- for select distinct exec_date_id from staging.tlnd_temp_execution where rtrim(operation)='UN';
	l_exec_analyze text;
	interval_rez int;
	neighbourhood int;
	last_partition_name text;
	l_sql_block2 text;
	l_row_count int;
	l_max_pg_exec_id bigint;
	l_max_ora_exec_id bigint;
	l_run_condition int;
	l_max_time_stamp timestamp;
	l_max_exec_time timestamp;
	l_partition_name text;
 begin
	--l_step_id :=0;
	l_in_l_seq:= in_l_seq;
	l_step_id:= in_step;



	--==============================================================
	--============ Cheking if table not exists then exit============
	--==============================================================

	l_in_table_name:= 'tlnd_execution_'||in_l_seq::varchar;

	SELECT count(1)
	into l_run_condition
	from information_schema.tables
    	where table_schema = 'staging'
			and table_name =l_in_table_name
	;

	select public.load_log(l_in_l_seq, l_step_id, 'l_run_condition ='||l_run_condition::varchar, 0, 'O')
	into l_step_id;

	if l_run_condition = 0

		then

			return;

	end if;

	--================================================================

	select public.load_log(l_in_l_seq,l_step_id,'staging.tlnd_load_execution STARTED >>>>>>>>'::text,0 ,'S'::text)
	into l_step_id
			;


	l_sql:= 'select string_agg(exec_date_id::varchar,'','')
				from(select distinct exec_date_id
						from staging.tlnd_execution_'||in_l_seq::varchar||'
							where operation =''UN''
					)t ;';

	EXECUTE l_sql
	into l_in_date_id_list;



	l_in_table_name:= in_table_name;

	l_sql_block := 'INSERT INTO  &p_partition_name
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													exec_text, is_parent_level, time_in_force_id, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, time_in_force, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt
				 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt > 1
			on conflict (exec_id) do update
	 set
--   set exec_date_id = coalesce(public.f_insert_etl_reject(''load_temp_execution''::varchar,''execution_202101_exec_id_exec_date_id_idx'',''(exec_date_id= ''||EXCLUDED.exec_date_id||'',exec_id= ''||EXCLUDED.exec_id||'',exec_time = ''||EXCLUDED.exec_time||'')''::varchar),
--   EXCLUDED.exec_date_id),
		secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
		secondary_order_id= EXCLUDED.secondary_order_id,
		trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
		avg_px= EXCLUDED.avg_px,
		bust_qty= EXCLUDED.bust_qty,
		contra_account_capacity= EXCLUDED.contra_account_capacity,
		contra_broker= EXCLUDED.contra_broker,
		cum_qty= EXCLUDED.cum_qty,
		exch_exec_id= EXCLUDED.exch_exec_id,
		exec_time= EXCLUDED.exec_time,
		exec_type= EXCLUDED.exec_type,
		fix_message_id= EXCLUDED.fix_message_id,
		account_id= EXCLUDED.account_id,
		is_busted= EXCLUDED.is_busted,
		last_mkt= EXCLUDED.last_mkt,
		last_px= EXCLUDED.last_px,
		last_qty= EXCLUDED.last_qty,
		leaves_qty= EXCLUDED.leaves_qty,
		order_id= EXCLUDED.order_id,
		order_status= EXCLUDED.order_status,
		exec_text=EXCLUDED.exec_text ,
		is_parent_level = EXCLUDED.is_parent_level,
		time_in_force_id = EXCLUDED.time_in_force_id,
		exec_broker=EXCLUDED.exec_broker,
		dataset_id = EXCLUDED.dataset_id,
		auction_id = EXCLUDED.auction_id,
		match_qty = EXCLUDED.match_qty,
		match_px = EXCLUDED.match_px,
		internal_component_type = EXCLUDED.internal_component_type,
		exchange_id = EXCLUDED.exchange_id,
		contra_trader = EXCLUDED.contra_trader,
		ref_exec_id = EXCLUDED.ref_exec_id,
		reject_code = EXCLUDED.reject_code,
		order_create_date_id = EXCLUDED.order_create_date_id;';


	l_sql_block2 := 'INSERT INTO  &p_partition_name
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													exec_text, is_parent_level, time_in_force_id, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, time_in_force, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt
				 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt = 1
			on conflict (exec_id) do nothing;';

	l_sql_block_rejected := 'INSERT INTO staging.execution_rejected
									(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
											avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
											secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
											text_, is_parent_level, time_in_force_id, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt, error_message)
		 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_busted, leaves_qty, cum_qty,
											avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
											secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
											text_, is_parent_level, time_in_force, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader, ref_exec_id, reject_code, order_create_date_id, cnt, $1
		 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
		 WHERE rtrim(operation)=''I'' and exec_date_id = $2
		 on conflict (exec_id, dataset_id) do nothing;';

	raise INFO 'SQL prepared';
	--analyze staging.tlnd_temp_execution;

	execute 'analyze staging.tlnd_execution_'||in_l_seq::varchar||';';
	raise INFO '%: analyze DONE', clock_timestamp() ;

	open date_id_crs for execute format('select distinct exec_date_id from staging.tlnd_execution_%s  where rtrim(operation)=''I'';',in_l_seq::varchar);
	loop
	fetch date_id_crs into l_date_id;
	exit when not found;

	begin

	select partition_table
	into l_partition_name
	from (SELECT  partition_table,
			  (regexp_matches(partition_range, '\((.*?)\)'))[1] AS partition_start,
			  (regexp_matches(partition_range, 'TO \((.*?)\)'))[1] AS partition_end
				FROM ( SELECT
						  cn.nspname ||'.'|| c.relname AS partition_table,
			      		  pg_get_expr(c.relpartbound, c.oid) AS partition_range
			      	from pg_inherits
				    join pg_class as c on (inhrelid=c.oid)
				    join pg_class as p on (inhparent=p.oid)
					join pg_namespace pn on pn.oid = p.relnamespace
					join pg_namespace cn on cn.oid = c.relnamespace
					where p.relname = 'execution' and pn.nspname = 'dwh'
					and c.relkind not in ('f')
				  ) sub
      ) l
	where l_date_id >= partition_start::int
	and l_date_id < partition_end::int;

	l_sql := replace (l_sql_block ,'&p_partition_name', l_partition_name);
	l_sql := replace (l_sql ,'&p_date_id', l_date_id::text);

	raise INFO '%: executing INSERT %', clock_timestamp() , l_date_id;

	EXECUTE l_sql;

	GET diagnostics l_row_count= ROW_COUNT;

 			select public.load_log(
								l_in_l_seq,
								l_step_id,
								l_in_table_name::text||' for '||l_date_id::text,
						COALESCE( l_row_count, 0)::int ,
					'M'::text
				) into l_step_id
			;
	raise INFO '%: DONE INSERT %', clock_timestamp() , l_date_id;

	exception when others then

	execute l_sql_block_rejected
	using ''''|| left(sqlerrm,100) ||'''', l_date_id;

	PERFORM public.load_error_log('tlnd_load_execution_sp FAILED <UAT>!!! (loaded data to staging.execution_rejected)', 'I', sqlerrm, l_in_l_seq);
	end;

	begin
		l_sql := replace (l_sql_block2 ,'&p_partition_name', l_partition_name);
		l_sql := replace (l_sql ,'&p_date_id', l_date_id::text);

	raise INFO '%: executing INSERT2 %', clock_timestamp() , l_date_id;
	EXECUTE l_sql;
	raise INFO '%: executing DONE %', clock_timestamp() , l_date_id;

	GET diagnostics l_row_count= ROW_COUNT;

		select public.load_log(
							l_in_l_seq,
							l_step_id,
							l_in_table_name::text||' for '||l_date_id::text,
						COALESCE( l_row_count, 0)::int ,
						'I'::text
						) into l_step_id
					;

	exception when others then

	execute l_sql_block_rejected
	using ''''|| left(sqlerrm,100) ||'''', l_date_id;

	PERFORM public.load_error_log('tlnd_load_execution_sp FAILED <UAT>!!! (loaded data to staging.execution_rejected)', 'I', sqlerrm, l_in_l_seq);
	end;

	end loop;

	close date_id_crs;

--	l_exec_analyze:= 'analyze partitions.execution_'||left(right(l_in_date_id_list, 8), 6);
--	execute l_exec_analyze;

	neighbourhood:= 3600; --60 min
	last_partition_name:= 'select execution_'||left(right(l_in_date_id_list, 8), 6); --extract last date from date_id_list in format YYYYMM

	select abs(date_part('epoch'::text, clock_timestamp() AT TIME ZONE 'US/Eastern'
										- (clock_timestamp()::date::timestamp AT TIME ZONE 'US/Eastern' + interval '8 hours 15 minutes') --8:15 AM current date
						)
				) into interval_rez;
	--analyze only between 7:15 and 9:15
	if (interval_rez < neighbourhood) then
		perform  dwh.analyse_statistics (in_schema_name => 'partitions', in_table_name => last_partition_name, in_max_interval => 600);
	end if;

raise INFO ' anazyzed DONE %', clock_timestamp() ;

if l_in_date_id_list is not null
 then
execute 'UPDATE dwh.execution ex
				SET
				secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
				secondary_order_id= EXCLUDED.secondary_order_id,
				trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
				avg_px= EXCLUDED.avg_px,
				bust_qty= EXCLUDED.bust_qty,
				contra_account_capacity= EXCLUDED.contra_account_capacity,
				contra_broker= EXCLUDED.contra_broker,
				cum_qty= EXCLUDED.cum_qty,
				exch_exec_id= EXCLUDED.exch_exec_id,
				exec_time= EXCLUDED.exec_time,
				exec_type= EXCLUDED.exec_type,
				exec_date_id= EXCLUDED.exec_date_id,
				fix_message_id= EXCLUDED.fix_message_id,
				account_id= EXCLUDED.account_id,
				is_busted= EXCLUDED.is_busted,
				last_mkt= EXCLUDED.last_mkt,
				last_px= EXCLUDED.last_px,
				last_qty= EXCLUDED.last_qty,
				leaves_qty= EXCLUDED.leaves_qty,
				order_id= EXCLUDED.order_id,
				order_status= EXCLUDED.order_status,
				exec_text=EXCLUDED.text_ ,
				is_parent_level = EXCLUDED.is_parent_level,
				time_in_force_id = EXCLUDED.time_in_force,
				exec_broker=EXCLUDED.exec_broker,
				dataset_id = EXCLUDED.dataset_id,
				auction_id = EXCLUDED.auction_id,
				match_qty = EXCLUDED.match_qty,
				match_px = EXCLUDED.match_px,
				internal_component_type = EXCLUDED.internal_component_type,
				exchange_id = EXCLUDED.exchange_id,
				contra_trader = EXCLUDED.contra_trader,
				ref_exec_id = EXCLUDED.ref_exec_id,
				reject_code = EXCLUDED.reject_code,
				order_create_date_id = EXCLUDED.order_create_date_id
			FROM  staging.tlnd_execution_'||in_l_seq::varchar||'  EXCLUDED
				WHERE  ex.exec_id = EXCLUDED.exec_id
				and ex.exec_date_id = EXCLUDED.exec_date_id
				and EXCLUDED.operation=''UN''
				and ex.exec_date_id in('||l_in_date_id_list||')';

	GET diagnostics l_row_count= ROW_COUNT;

	select public.load_log(
						l_in_l_seq,
						l_step_id,
						l_in_table_name::text,
						coalesce (l_row_count,0)::int,
							'U'::text)
						into l_step_id
					;

raise INFO ' updated DONE %', clock_timestamp() ;
end if;



  --==========================================================================================================
	--======================= p_upd_fact_last_load_time part removed from ETL ==================================
	--==========================================================================================================

	--PERFORM dwh.p_upd_fact_last_load_time('execution');

	l_sql:=  'select max(exec_time) from staging.tlnd_execution_'||in_l_seq::varchar ;

	execute l_sql into l_max_exec_time;

  --RAISE NOTICE 'execution ID %', l_max_exec_id;
 	RAISE NOTICE 'Time %', l_max_exec_time;
  --RETURN l_max_process_time;

  l_max_time_stamp := l_max_exec_time;

  insert into dwh.fact_last_load_time(table_name, latest_load_time, pg_db_updated_time)
  select 'EXECUTION' as table_name
         , l_max_time_stamp as latest_load_time
         , clock_timestamp() as pg_db_updated_time
  on conflict (table_name) do
  update set
    latest_load_time = greatest(fact_last_load_time.latest_load_time, excluded.latest_load_time),
    pg_db_updated_time = excluded.pg_db_updated_time;

	select public.load_log(l_in_l_seq,l_step_id,'p_upd_fact_last_load_time finished ', 0,'F')
		into l_step_id;



	/*--==========================================================================================================
	--================= Update of Oracle table removed from ETL ================================================
	--==========================================================================================================

	select  last_loaded_id
		into l_max_pg_exec_id
	from staging.tlnd_inc_last_loaded_id tilli
		where table_name ='execution'
	;

	--select * from staging.last_loaded_id;


	update staging.last_loaded_id
		set MAX_PG_ID = greatest(l_max_pg_exec_id, MAX_PG_ID)
	where table_name = 'EXECUTION'
	;

	select public.load_log(l_in_l_seq,l_step_id,'updated MAX_PG_ID in staging.last_loaded_id ', 0,'F')
		into l_step_id;

	--==========================================================================================================
	--================= Update of PG table removed from ETL ====================================================
	--==========================================================================================================

	select max_ora_id
	into l_max_ora_exec_id
	from staging.last_loaded_id lli
	where table_name = 'EXECUTION'
	;

	update staging.tlnd_inc_last_loaded_id
		set last_loaded_id = greatest(l_max_ora_exec_id , last_loaded_id)
	where table_name = 'execution'
	;

	select public.load_log(l_in_l_seq,l_step_id,'updated last_loaded_id in staging.tlnd_inc_last_loaded_id', 0,'F')
		into l_step_id;

	*/



	execute 'select count(distinct exec_id) from staging.tlnd_execution_'||in_l_seq::varchar /*where rtrim(operation)=''I'' and cnt > 1*/
	into l_row_count;

	raise notice ' l_row_count = %', l_row_count;


	l_sql:= 'select string_agg(exec_date_id::varchar,'','')
				from(select distinct exec_date_id
						from staging.tlnd_execution_'||in_l_seq::varchar||'
					)t';

	EXECUTE l_sql
	into l_in_date_id_list;

	perform  public.etl_subscribe(l_in_l_seq, 'yield_capture', 'execution', l_in_date_id_list::varchar,coalesce(l_row_count,0)::int ) ;

	--execute 'drop table if exists staging.tlnd_execution_'||in_l_seq::varchar;


	select public.load_log(l_in_l_seq,l_step_id,'staging.tlnd_load_execution FINISHED >>>>>>>>'::text,0 ,'S'::text)
	into l_step_id
			;

	--RETURN l_step_id;

 end;
$_$;


-- select * from dwh.trade_record_v_historical
CREATE or replace VIEW dwh.trade_record_v_historical AS
 SELECT ex.exec_time AS trade_record_time,
    ex.exec_date_id AS date_id,
    cl.trans_type AS trade_record_trans_type,
    cl.strtg_decision_reason_code AS trade_record_reason,
    dss.sub_system_id,
    cl.account_id,
    cl.client_order_id,
    cl.instrument_id,
    cl.side,
    cl.open_close,
    cl.fix_connection_id,
    cl.price AS order_price,
    str.price AS street_order_price,
    cl.process_time AS order_process_time,
    ex.exec_id,
    ex.exchange_id,
    ex.trade_liquidity_indicator,
    ex.secondary_order_id,
    ex.exch_exec_id,
    ex.secondary_exch_exec_id,
    ex.last_mkt,
    ex.last_qty,
    ex.last_px,
    cl.ex_destination,
    cl.sub_strategy_desc AS sub_strategy,
    str.order_id AS street_order_id,
    cl.order_id,
    str.order_qty AS street_order_qty,
    cl.order_qty,
    cl.multileg_reporting_type,
    str.max_floor AS street_max_floor,
        CASE
            WHEN (i.instrument_type_id = 'O'::bpchar) THEN
            CASE
                WHEN ((acc.opt_is_fix_execbrok_processed)::text = 'Y'::text) THEN COALESCE(COALESCE(cl_br.opt_exec_broker, public.get_message_tag_string_cross_multileg(cl.fix_message_id, 76, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
                CASE
                    WHEN (cl.cross_order_id IS NULL) THEN false
                    ELSE true
                END)), opx.opt_exec_broker)
                ELSE opx.opt_exec_broker
            END
            ELSE public.get_message_tag_string_cross_multileg(str.fix_message_id, 76, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
            CASE
                WHEN (str.cross_order_id IS NULL) THEN false
                ELSE true
            END)
        END AS exec_broker,
    lpad(
        CASE
            WHEN (i.instrument_type_id = 'O'::bpchar) THEN NULLIF((COALESCE(COALESCE(COALESCE(public.get_message_tag_string(ex.fix_message_id, 439, ex.exec_date_id), public.get_message_tag_string(str_ex.fix_message_id, 439, str_ex.exec_date_id)), ((str.clearing_firm_id)::text)::character varying), public.get_message_tag_string_cross_multileg(cl.fix_message_id, 439, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
            CASE
                WHEN (cl.cross_order_id IS NULL) THEN false
                ELSE true
            END)))::text, '949'::text)
            ELSE NULL::text
        END, 3, '0'::text) AS cmta,
    str.time_in_force_id AS street_time_in_force,
    str.order_type_id AS street_order_type,
    cl.customer_or_firm_id AS opt_customer_firm,
    ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) AS str_opt_customer_firm,
    str.market_participant_id AS street_mpid,
        CASE
            WHEN (cl.cross_order_id IS NULL) THEN 'N'::text
            ELSE 'Y'::text
        END AS is_cross_order,
        CASE
            WHEN (str.cross_order_id IS NULL) THEN 'N'::text
            ELSE 'Y'::text
        END AS street_is_cross_order,
    ( SELECT c.cross_type
           FROM dwh.cross_order c
          WHERE (c.cross_order_id = str.cross_order_id)) AS street_cross_type,
    cl.is_originator AS cross_is_originator,
    str.is_originator AS street_cross_is_originator,
    ex.contra_account_capacity AS contra_account,
    ex.contra_broker,
    ex.exec_broker AS trade_exec_broker,
    cl.fix_message_id AS order_fix_message_id,
    ex.fix_message_id AS trade_fix_message_id,
    str.fix_message_id AS street_order_fix_message_id,
    cl.client_id_text AS client_id,
    str.transaction_id AS street_transaction_id,
    cl.transaction_id,
    fc.fix_comp_id,
    str.client_order_id AS street_client_order_id,
    ex.leaves_qty,
    str.exec_instruction AS street_exec_inst,
    public.get_message_tag_string(ex.fix_message_id, 9090, ex.exec_date_id) AS fee_sensitivity,
    COALESCE(str.strtg_decision_reason_code, cl.strtg_decision_reason_code) AS strategy_decision_reason_code,
    cl.compliance_id,
    public.get_message_tag_string_cross_multileg(cl.fix_message_id, 143, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
        CASE
            WHEN (cl.cross_order_id IS NULL) THEN false
            ELSE true
        END) AS floor_broker_id,
    str2au.auction_id,
        CASE
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('AMEX'::character varying)::text, ('ARCE'::character varying)::text])) THEN
            CASE ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text))
                WHEN '3'::text THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 50, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('ISE'::character varying)::text, ('GEMINI'::character varying)::text, ('MCRY'::character varying)::text, ('MIAX'::character varying)::text, ('MPRL'::character varying)::text, ('PHLX'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['4'::text, '5'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('BATO'::character varying)::text, ('EDGO'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'N'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('C2OX'::character varying)::text, ('CBOE'::character varying)::text, ('CBOEEH'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'N'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 1462, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = 'BOX'::text) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'X'::text])) THEN NULL::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('NSDQO'::character varying)::text, ('NQBXO'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'O'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            ELSE NULL::text
        END AS sub_account,
        CASE
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('AMEX'::character varying)::text, ('ARCE'::character varying)::text])) THEN
            CASE ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text))
                WHEN '3'::text THEN NULL::character varying
                ELSE cross_acc.account_name
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('BATO'::character varying)::text, ('EDGO'::character varying)::text])) THEN cross_acc.account_name
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('C2OX'::character varying)::text, ('CBOE'::character varying)::text, ('CBOEEH'::character varying)::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
            CASE
                WHEN (str.cross_order_id IS NULL) THEN false
                ELSE true
            END)
            WHEN ((ex.exchange_id)::text = 'BOX'::text) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'X'::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('ISE'::character varying)::text, ('GEMINI'::character varying)::text, ('MCRY'::character varying)::text, ('MIAX'::character varying)::text, ('MPRL'::character varying)::text, ('PHLX'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['4'::text, '5'::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('NSDQO'::character varying)::text, ('NQBXO'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'O'::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            ELSE NULL::character varying
        END AS clearing_account,
    cl.multileg_order_id,
    ex.internal_component_type,
    str_ex.fix_message_id AS str_trade_fix_message_id,
    cl.pt_basket_id,
    cl.pt_order_id,
    public.get_message_tag_string(str_ex.fix_message_id, 5049, str_ex.exec_date_id) AS str_cls_comp_id,
    COALESCE(public.get_message_tag_string(str_ex.fix_message_id, 1, str_ex.exec_date_id), public.get_message_tag_string_cross_multileg(str.fix_message_id, 1, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
        CASE
            WHEN (str.cross_order_id IS NULL) THEN false
            ELSE true
        END)) AS street_account_name,
    public.get_message_tag_string(str_ex.fix_message_id, 9861, str_ex.exec_date_id) AS branch_seq_num,
    str_ex.exec_text AS trade_text,
    public.get_message_tag_string(str_ex.fix_message_id, 21097, str_ex.exec_date_id) AS frequent_trader_id,
    cl.time_in_force_id AS time_in_force,
    cl.internal_component_type AS int_liq_source_type,
    cl.market_participant_id AS mpid,
    cl.alternative_compliance_id,
    str_ex.exec_time AS street_trade_record_time,
    str.process_time AS street_order_process_time,
    cl.co_client_leg_ref_id,
    public.get_message_tag_string_cross_multileg(cl.fix_message_id, 10445, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
        CASE
            WHEN (cl.cross_order_id IS NULL) THEN false
            ELSE true
        END) AS blaze_account_alias
   FROM ((((((((((((dwh.execution ex
     JOIN dwh.client_order cl ON (((ex.order_id = cl.order_id) AND (cl.multileg_reporting_type = ANY (ARRAY['1'::bpchar, '2'::bpchar])) AND (cl.parent_order_id IS NULL) AND (cl.trans_type <> 'F'::bpchar))))
     JOIN dwh.d_account acc ON ((cl.account_id = acc.account_id)))
     JOIN dwh.d_instrument i ON ((cl.instrument_id = i.instrument_id)))
     LEFT JOIN dwh.d_sub_system dss ON ((cl.sub_system_unq_id = dss.sub_system_unq_id)))
     LEFT JOIN dwh.client_order str ON ((((ex.secondary_order_id)::text = (str.client_order_id)::text) AND (str.parent_order_id = cl.order_id))))
     LEFT JOIN dwh.client_order2auction str2au ON (((str.order_id = str2au.order_id) AND (str.create_date_id = str2au.create_date_id))))
     LEFT JOIN dwh.d_account cross_acc ON ((str.cross_account_id = cross_acc.account_id)))
     LEFT JOIN dwh.execution str_ex ON ((((ex.secondary_exch_exec_id)::text = (str_ex.exch_exec_id)::text) AND (str_ex.order_id = str.order_id) AND (ex.exec_date_id = str_ex.exec_date_id))))
     LEFT JOIN dwh.d_opt_exec_broker opx ON (((cl.account_id = opx.account_id) AND opx.is_active AND ((opx.is_default)::text = 'Y'::text))))
     LEFT JOIN dwh.d_opt_exec_broker cl_br ON ((cl.opt_exec_broker_id = cl_br.opt_exec_broker_id)))
     LEFT JOIN dwh.d_opt_exec_broker str_br ON ((str_br.opt_exec_broker_id = opx.opt_exec_broker_id)))
     LEFT JOIN dwh.d_fix_connection fc ON ((fc.fix_connection_id = cl.fix_connection_id)))
  WHERE ((ex.is_busted <> 'Y'::bpchar) AND (ex.exec_type = 'F'::bpchar));


/*
---------------


CREATE FUNCTION dash360.order_blotter_get_order_details_bkp(in_order_id bigint) RETURNS TABLE(account_id integer, trading_firm_id character varying, auction_id bigint, order_id bigint, client_order_id character varying, multileg_reporting_type character varying, cross_order_id bigint, side character varying, create_time timestamp without time zone, process_time timestamp without time zone, order_qty bigint, price numeric, sub_strategy character varying, display_instrument_id character varying, instrument_type_id character varying, instrument_id bigint, last_trade_date timestamp without time zone, customer_or_firm_id character varying, clearing_firm_id character varying, opt_exec_broker character varying, time_in_force_id character varying, open_close character varying, client_id character varying, ratio_qty bigint, no_legs integer, co_client_leg_ref_id character varying, fix_message_id bigint, order_type character varying, ex_destination character varying, exchange_id character varying, extended_ord_type character varying, sweep_style character varying, aggression_level smallint, order_status character varying, exec_qty bigint, avg_px numeric, leaves_qty integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
	select_stmt     text;
	sql_params      text;
	row_cnt         integer;

  l_create_date_id integer;

   l_load_id        integer;
   l_step_id        integer;

begin
  --select nextval('public.load_timing_seq') into l_load_id;
  --l_step_id:=1;

 	 --select public.load_log(l_load_id, l_step_id, 'dash360.order_blotter_get_order_details STARTED===', 0, 'O')
	 --into l_step_id;

  l_create_date_id := coalesce((select o.create_date_id from dwh.client_order o where o.order_id = in_order_id limit 1)::integer, 21010101);

  RAISE info 'l_create_date_id = % ', l_create_date_id;

  --select public.load_log(l_load_id, l_step_id, 'l_create_date_id = '|| l_create_date_id::varchar, 0, 'O')
	-- into l_step_id;



   -- form the query
   RETURN QUERY
    select co.account_id
      , tf.trading_firm_id
      , auc.auction_id
      , co.order_id
      , co.client_order_id
      , co.multileg_reporting_type::varchar
      , co.cross_order_id
      , co.side::varchar
      , co.create_time
      , co.process_time
      , co.order_qty::bigint
      , co.price
      , co.sub_strategy_desc as sub_strategy
      , i.display_instrument_id
      , i.instrument_type_id::varchar
      , co.instrument_id
      , i.last_trade_date
      , co.customer_or_firm_id::varchar
      , co.clearing_firm_id
      --, clo.opt_exec_broker --co.opt_exec_broker_id -- !!!! should be 792 ???
      , eb.opt_exec_broker
      , co.time_in_force_id::varchar
      , co.open_close::varchar
      , c.client_src_id as client_id
      , co.ratio_qty
      , co.no_legs
      , co.co_client_leg_ref_id
      , co.fix_message_id
      , co.order_type_id::varchar as order_type --
      , co.ex_destination
      , co.exchange_id
      , co.extended_ord_type::varchar
      , co.sweep_style::varchar
      , co.aggression_level
      , ex.order_status::varchar
      , trd.exec_qty::bigint
      , trd.avg_px
      , ex.leaves_qty
      --, co.*
    from dwh.client_order co
      left join dwh.d_account ac on co.account_id = ac.account_id
      left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
      left join data_marts.d_client c on co.client_id = c.client_id
      left join dwh.d_opt_exec_broker eb on co.opt_exec_broker_id = eb.opt_exec_broker_id
      left join lateral
        ( select oa.auction_id -- как вариант, еще сгруппировать все аукционы ордера
          from dwh.client_order2auction oa
          where oa.create_date_id >= l_create_date_id
            and oa.order_id = co.order_id
          order by oa.rfq_transact_time
          limit 1 -- parent OFP orders can participate in thousands of auctions
        ) auc on true
      left join dwh.d_instrument i on co.instrument_id = i.instrument_id
      left join lateral
        ( select ex.text_
            , ex.order_status
            , ex.exec_id
            , ex.leaves_qty
          from dwh.execution ex
          where ex.exec_date_id >= l_create_date_id -- l_order_create_date_id --
            and ex.exec_date_id >= co.create_date_id
            and ex.order_id = co.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      left join lateral
        ( select sum(tr.last_qty) as exec_qty
            , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as avg_px
            , sum(tr.principal_amount) as principal_amount
            , min(tr.trade_record_time) as first_fill_date_time
            , max(tr.trade_record_id) as max_trade_record_id
            , case when co.parent_order_id is null then tr.order_id else tr.street_order_id end as order_id
          from dwh.flat_trade_record tr
          where 1=1 -- try to calculate for both parent and street level orders
            and tr.order_id = case when co.parent_order_id is null then co.order_id else co.parent_order_id end -- trade filter by parent level for both levels of orders
            and co.order_id = case when co.parent_order_id is null then tr.order_id else tr.street_order_id end -- trade filter for street level !!!
            and tr.date_id >= l_create_date_id
            and tr.is_busted = 'N'
          group by case when co.parent_order_id is null then tr.order_id else tr.street_order_id end
          limit 1
        ) trd ON true
    where co.multileg_reporting_type in ('1','2')
      and co.create_date_id = l_create_date_id
      and co.order_id = in_order_id
    limit 10000
    ;
  	 --GET DIAGNOSTICS row_cnt = ROW_COUNT;

   --select public.load_log(l_load_id, l_step_id, 'orders returned cnt', row_cnt, 'O')
	 --into l_step_id;

 	 --select public.load_log(l_load_id, l_step_id, 'dash360.order_blotter_get_order_details COMPLETE===', 0, 'O')
	 --into l_step_id;

END;
$$;



CREATE FUNCTION dash_reporting.get_parent_orders_trade_activity_bkp(p_accounts integer[] DEFAULT '{}'::integer[], p_exchanges character varying[] DEFAULT '{}'::character varying[], in_start_date_id integer DEFAULT NULL::integer, in_end_date_id integer DEFAULT NULL::integer) RETURNS TABLE(client_order_id character varying, exch_order_id character varying, order_id bigint, side character, order_qty integer, price numeric, time_in_force character varying, instrument_name character varying, last_trade_date timestamp without time zone, account_name character varying, sub_system_unq_id integer, multileg_reporting_type character, exec_id bigint, ref_exec_id bigint, exch_exec_id character varying, "Exec_Time_Orig" timestamp without time zone, exec_time text, "Exec_Type" character varying, "Order_Status" character varying, leaves_qty bigint, cum_qty bigint, avg_px numeric, last_qty bigint, last_px numeric, bust_qty bigint, last_mkt character varying, last_mkt_name character varying, text_ character varying, trade_liquidity_indicator character varying, is_busted character, exec_broker character varying, exchange_id character varying, exchange_name character varying)
    LANGUAGE plpgsql PARALLEL SAFE
    AS $$
begin

RETURN QUERY
	Select
	co.client_order_id --1
	, co.exch_order_id
	, ex.order_id
	, co.side
	, co.order_qty
	, co.price
	, tif.tif_short_name
	, inst.instrument_name
	, inst.last_trade_date
	, acc.account_name --10
	, dss.sub_system_id
	, co.multileg_reporting_type
	, ex.exec_id
	, ex.ref_exec_id
	, ex.exch_exec_id
	, ex.exec_time
	, to_char(ex.exec_time, 'HH:MI:SS.MS')
	, et.exec_type_description
	, os.order_status_description
	, ex.leaves_qty --20
	, ex.cum_qty
	, ex.avg_px
	, ex.last_qty
	, ex.last_px
	, ex.bust_qty
	, ex.last_mkt
	, lm.last_mkt_name
	, ex.text_
	, ex.trade_liquidity_indicator
	, ex.is_busted --30
	, ex.exec_broker
	, ex.exchange_id
	, e.exchange_name
	From execution ex
	INNER JOIN client_order co ON ex.order_id = co.order_id
	inner join d_sub_system dss on co.sub_system_unq_id = dss.sub_system_unq_id
	INNER JOIN d_account acc ON co.account_id = acc.account_id
	INNER JOIN d_instrument inst ON co.instrument_id = inst.instrument_id
	LEFT JOIN d_time_in_force tif ON co.time_in_force_id = tif.tif_id
	LEFT JOIN d_order_status os ON os.order_status = ex.order_status
	LEFT JOIN d_last_market lm ON lm.last_mkt = ex.last_mkt AND lm.is_active = true
	LEFT JOIN d_exchange e ON e.exchange_id = ex.exchange_id AND e.is_active = true
	LEFT JOIN d_exec_type et ON et.exec_type = ex.exec_type
	Where ex.exec_type In ('F','H')
	AND (p_accounts IS NULL OR co.account_id = any(p_accounts))
	AND (p_exchanges IS null OR ex.exchange_id = any(p_exchanges))
	And ex.exec_date_id  >= in_start_date_id
	And ex.exec_date_id < in_end_date_id
	And co.parent_order_id is null;
end;
$$;



CREATE FUNCTION dash_reporting.get_street_orders_trade_activity_bkp(p_accounts integer[] DEFAULT '{}'::integer[], p_exchanges character varying[] DEFAULT '{}'::character varying[], in_start_date_id integer DEFAULT NULL::integer, in_end_date_id integer DEFAULT NULL::integer) RETURNS TABLE(client_order_id character varying, exch_order_id character varying, order_id bigint, side character, order_qty integer, price numeric, time_in_force character varying, instrument_name character varying, last_trade_date timestamp without time zone, account_name character varying, sub_system_unq_id integer, multileg_reporting_type character, exec_id bigint, ref_exec_id bigint, exch_exec_id character varying, "Exec_Time_Orig" timestamp without time zone, exec_time text, "Exec_Type" character varying, "Order_Status" character varying, leaves_qty bigint, cum_qty bigint, avg_px numeric, last_qty bigint, last_px numeric, bust_qty bigint, last_mkt character varying, last_mkt_name character varying, text_ character varying, trade_liquidity_indicator character varying, is_busted character, exec_broker character varying, exchange_id character varying, exchange_name character varying)
    LANGUAGE plpgsql PARALLEL SAFE
    AS $$
begin

RETURN QUERY
	Select
	co.client_order_id --1
	, co.exch_order_id
	, ex.order_id
	, co.side
	, co.order_qty
	, co.price
	, tif.tif_short_name
	, inst.instrument_name
	, inst.last_trade_date
	, acc.account_name --10
	, co.sub_system_unq_id
	, co.multileg_reporting_type
	, ex.exec_id
	, ex.ref_exec_id
	, ex.exch_exec_id
	, ex.exec_time
	, to_char(ex.exec_time, 'HH:MI:SSxFF')
	, et.exec_type_description
	, os.order_status_description
	, ex.leaves_qty --20
	, ex.cum_qty
	, ex.avg_px
	, ex.last_qty
	, ex.last_px
	, ex.bust_qty
	, ex.last_mkt
	, lm.last_mkt_name
	, ex.text_
	, ex.trade_liquidity_indicator
	, ex.is_busted --30
	, ex.exec_broker
	, ex.exchange_id
	, e.exchange_name
	From execution ex
	INNER JOIN client_order co ON ex.order_id = co.order_id
	INNER JOIN d_account acc ON co.account_id = acc.account_id
	INNER JOIN d_instrument inst ON co.instrument_id = inst.instrument_id
	LEFT JOIN d_time_in_force tif ON co.time_in_force_id = tif.tif_id
	LEFT JOIN d_order_status os ON os.order_status = ex.order_status
	LEFT JOIN d_last_market lm ON lm.last_mkt = ex.last_mkt AND lm.is_active = true
	LEFT JOIN d_exchange e ON e.exchange_id = ex.exchange_id AND e.is_active = true
	LEFT JOIN d_exec_type et ON et.exec_type = ex.exec_type
	Where ex.exec_type In ('F','H')
	AND (p_accounts IS NULL OR co.account_id = any(p_accounts))
	AND (p_exchanges IS null OR ex.exchange_id = any(p_exchanges))
	And ex.exec_date_id  >= in_start_date_id
	And ex.exec_date_id <= in_end_date_id
	And co.parent_order_id is not null;
end;
$$;



CREATE FUNCTION eod_reports.export_rbc_orders_tbl_bkp(in_start_date_id integer DEFAULT NULL::integer, in_end_date_id integer DEFAULT NULL::integer, in_client_ids character varying[] DEFAULT '{}'::character varying[]) RETURNS TABLE("Account" character varying, "Is Cross" character varying, "Is MLeg" character varying, "Ord Status" character varying, "Event Type" character varying, "Routed Time" character varying, "Event Time" character varying, "Cl Ord ID" character varying, "Side" character varying, "Symbol" character varying, "Ord Qty" bigint, "Price" numeric, "Ex Qty" bigint, "Avg Px" numeric, "Sub Strategy" character varying, "Ex Dest" character varying, "Ord Type" character varying, "TIF" character varying, "Sending Firm" character varying, "Capacity" character varying, "Client ID" character varying, "CMTA" character varying, "Creation Date" character varying, "Cross Ord Type" character varying, "Event Date" character varying, "Exec Broker" character varying, "Expiration Day" date, "Leg ID" character varying, "Lvs Qty" bigint, "O/C" character varying, "Orig Cl Ord ID" character varying, "OSI Symbol" character varying, "Root Symbol" character varying, "Security Type" character varying, "Stop Px" numeric, "Underlying Symbol" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE

   l_row_cnt integer;
   l_load_id integer;
   l_step_id integer;

  l_start_date_id integer;
  l_end_date_id   integer;

  l_gtc_start_date_id integer;
BEGIN

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id := 1;

  raise notice 'l_load_id=%',l_load_id;

  select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl STARTED===', 0, 'O')
   into l_step_id;

  if in_start_date_id is not null and in_end_date_id is not null
  then
    l_start_date_id := in_start_date_id;
    l_end_date_id := in_end_date_id;
  else
    --l_start_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    --l_end_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    l_start_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
    l_end_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;

  end if;

  --l_start_date_id := coalesce(in_date_id, (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer);

  l_gtc_start_date_id := to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD')::date - interval '6 month'), 'YYYYMMDD');

    select public.load_log(l_load_id, l_step_id, 'Step 1. l_start_date_id = '||l_start_date_id::varchar||', l_end_date_id = '||l_end_date_id::varchar||', l_gtc_start_date_id = '||l_gtc_start_date_id::varchar, 0 , 'O')
     into l_step_id;

  if in_client_ids = '{}'
	then
  return QUERY
/*  with par_ords as
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      ) */
    select --po.order_id
        ac.account_name as "Account"
      , (case when po.cross_order_id is not null then 'Y' else 'N' end)::varchar as "Is Cross"
      , (case when po.multileg_reporting_type = '1' then 'N' else 'Y' end)::varchar as "Is MLeg"
      , st.order_status_description as "Ord Status"
      , et.exec_type_description as "Event Type"
      , to_char(fyc.routed_time, 'HH24:MI:SS.US')::varchar as "Routed Time"
      --, to_char(po.process_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , to_char(fyc.exec_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , po.client_order_id as "Cl Ord ID"
      , (case po.side
                  when '1' then 'Buy'
                  when '2' then 'Sell'
                  when '3' then 'Buy minus'
                  when '4' then 'Sell plus'
                  when '5' then 'Sell short'
                  when '6' then 'Sell short exempt'
                  when '7' then 'Undisclosed'
                  when '8' then 'Cross'
                  when '9' then 'Cross short'
                end)::varchar as "Side"
      , i.display_instrument_id as "Symbol"
      , po.order_qty::bigint as "Ord Qty"
      , po.price as "Price"
      , fyc.filled_qty as "Ex Qty"
      , fyc.avg_px as "Avg Px"
      , ss.target_strategy_desc as "Sub Strategy"
      , dc.ex_destination_code_name as "Ex Dest"
      , ot.order_type_name as "Ord Type"
      , tif.tif_name as "TIF"
      , f.fix_comp_id as "Sending Firm"
      , cf.customer_or_firm_name as "Capacity"
      , po.client_id_text as "Client ID"
      , coalesce(po.clearing_firm_id, fx_co.clearing_firm_id) as "CMTA"
      , to_char(to_date(po.create_date_id::varchar, 'YYYYMMDD'), 'DD.MM.YYYY')::varchar as "Creation Date"
      , cro.cross_type::varchar as "Cross Ord Type"
      , to_char(fyc.exec_time, 'DD.MM.YYYY')::varchar as "Event Date"
      , ebr.opt_exec_broker as "Exec Broker"
      , date_trunc('day', i.last_trade_date)::date as "Expiration Day"
      , l.client_leg_ref_id as "Leg ID"
      , ex.leaves_qty::bigint as "Lvs Qty"
      , (case when po.open_close = 'O' then 'Open' else 'Close' end)::varchar as "O/C"
      , oo.client_order_id as "Orig Cl Ord ID"
      , po.opra_symbol as "OSI Symbol"
      , po.root_symbol as "Root Symbol"
      , it.instrument_type_name as "Security Type"
      , po.stop_price as "Stop Px"
      , ui.display_instrument_id as "Underlying Symbol"
      --, po.*
--select count(1)
    from
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      )  scp
      left join lateral
      (
        select po.order_id
          , po.orig_order_id
          , po.account_id
          , po.multileg_reporting_type
          , po.multileg_order_id
          , po.cross_order_id
          , po.create_date_id
          , po.client_order_id
          , po.instrument_id
          , po.order_qty
          , po.price
          , po.side
          , po.sub_strategy_id
          , po.ex_destination_code_id
          , po.ex_destination
          , po.order_type_id
          , po.time_in_force_id
          , po.customer_or_firm_id
          , po.order_capacity_id
          , po.client_id_text
          , po.process_time
          , po.opt_exec_broker_id
          , po.no_legs
          , po.open_close
          , po.fix_connection_id
          , po.clearing_firm_id
          , po.fix_message_id
          , po.stop_price
          , po.trans_type
          , oc.option_series_id
          , oc.opra_symbol
          , os.underlying_instrument_id
          , os.root_symbol
          --, po.*
        from dwh.client_order po
        left join dwh.d_option_contract oc
          ON po.instrument_id = oc.instrument_id
        left join dwh.d_option_series os
          --ON oc.option_series_id = os.option_series_id
          ON oc.option_series_id = os.option_series_id
        where 1=1
          and po.create_date_id between l_gtc_start_date_id and l_end_date_id -- last half of year. GTC purpose
          and po.order_id = scp.order_id
        limit 1 -- for NL acceleration
      ) po ON true
      left join dwh.client_order oo
        ON po.orig_order_id = oo.order_id
        and oo.create_date_id between l_gtc_start_date_id and l_end_date_id
      left join dwh.d_account ac
        ON po.account_id = ac.account_id
      left join lateral
        (
           select sum(fyc.day_cum_qty) as filled_qty
             , round(sum(fyc.day_avg_px*fyc.day_cum_qty)/nullif(sum(fyc.day_cum_qty), 0)::numeric, 4)::numeric as avg_px
             , min(fyc.routed_time) as routed_time
             , max(fyc.exec_time) as exec_time -- can it be event_time or transact time? min or max?
             , fyc.order_id
             , min(fyc.nbbo_bid_price) as nbbo_bid_price
             , min(fyc.nbbo_bid_quantity) as nbbo_bid_quantity
             , min(fyc.nbbo_ask_price) as nbbo_ask_price
             , min(fyc.nbbo_ask_quantity) as nbbo_ask_quantity
           from data_marts.f_yield_capture fyc -- here we have all orders, so we can use it for cum_qty calculation (instead of FTR)
           where fyc.order_id = po.order_id
             and fyc.status_date_id between l_gtc_start_date_id and l_end_date_id
           group by fyc.order_id
           limit 1 -- just in case to insure NL join method
        ) fyc on true
      -- the last execution
      left join lateral
        (
          select ex.text_
            , ex.order_status
            , ex.exec_type
            , ex.exec_id
            , ex.leaves_qty
          from dwh.execution ex
          where 1=1
            --and ex.exec_date_id = 20190604
            and ex.exec_date_id between l_start_date_id and l_end_date_id
            and ex.order_id = po.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      -- fix_message of order
      left join lateral
        (
          select (j.fix_message->>'439')::varchar as clearing_firm_id
          from fix_capture.fix_message_json j
          where 1=1
            and po.clearing_firm_id is null --
            and j.date_id between l_start_date_id and l_end_date_id -- l_gtc_start_date_id was very slow condition
            and j.fix_message_id = po.fix_message_id
            and j.date_id = po.create_date_id
          limit 1
        ) fx_co on true
      left join dwh.d_order_status st
        ON ex.order_status = st.order_status
      left join dwh.d_exec_type et
        ON ex.exec_type = et.exec_type
      left join dwh.d_instrument i
        ON po.instrument_id = i.instrument_id
      left join dwh.d_instrument_type it
        ON i.instrument_type_id = it.instrument_type_id
      left join dwh.d_instrument ui
        --ON os.underlying_instrument_id = ui.instrument_id
        ON po.underlying_instrument_id = ui.instrument_id
      left join dwh.d_target_strategy ss
        ON po.sub_strategy_id = ss.target_strategy_id
      left join dwh.d_ex_destination_code dc
        ON po.ex_destination = dc.ex_destination_code
      left join dwh.d_order_type ot
        ON po.order_type_id = ot.order_type_id
      left join dwh.d_time_in_force tif
        ON po.time_in_force_id = tif.tif_id
    /*  left join --lateral
        (
          select ---min(ecf.customer_or_firm_id) as customer_or_firm_id
            ecf.customer_or_firm_id
            , ecf.exch_customer_or_firm_id, ecf.exchange_id  -- lookup key
            , row_number() over (partition by ecf.exch_customer_or_firm_id, ecf.exchange_id order by ecf.customer_or_firm_id) as rn
          from dwh.d_exchange2customer_or_firm ecf
        ) ecf
        ON ecf.rn = 1 --true
          and o.customer_or_firm is null
          and ecf.exch_customer_or_firm_id = o.order_capacity
          and ecf.exchange_id = o.exchange_id */
      left join dwh.d_customer_or_firm cf ON cf.customer_or_firm_id = COALESCE(po.customer_or_firm_id, ac.opt_customer_or_firm) and cf.is_active = true -- ecf.customer_or_firm_id,
      left join dwh.cross_order cro
        ON po.cross_order_id = cro.cross_order_id
      left join dwh.d_opt_exec_broker ebr
        ON po.opt_exec_broker_id = ebr.opt_exec_broker_id
      left join dwh.d_fix_connection f
        ON po.fix_connection_id = f.fix_connection_id
      /*left join dwh.client_order_leg l
        ON l.order_id = po.order_id
        and l.multileg_order_id = po.multileg_order_id*/
      left join lateral
        (
          select l.order_id, l.client_leg_ref_id
          from dwh.client_order_leg l
          where l.multileg_order_id = po.multileg_order_id
          limit 3000
        ) l ON l.order_id = po.order_id
    where po.trans_type <> 'F' -- not cancell request
    order by po.process_time, 1;


   else


     return QUERY
     /*  with par_ords as
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      ) */
    select --po.order_id
        ac.account_name as "Account"
      , (case when po.cross_order_id is not null then 'Y' else 'N' end)::varchar as "Is Cross"
      , (case when po.multileg_reporting_type = '1' then 'N' else 'Y' end)::varchar as "Is MLeg"
      , st.order_status_description as "Ord Status"
      , et.exec_type_description as "Event Type"
      , to_char(fyc.routed_time, 'HH24:MI:SS.US')::varchar as "Routed Time"
      --, to_char(po.process_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , to_char(fyc.exec_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , po.client_order_id as "Cl Ord ID"
      , (case po.side
                  when '1' then 'Buy'
                  when '2' then 'Sell'
                  when '3' then 'Buy minus'
                  when '4' then 'Sell plus'
                  when '5' then 'Sell short'
                  when '6' then 'Sell short exempt'
                  when '7' then 'Undisclosed'
                  when '8' then 'Cross'
                  when '9' then 'Cross short'
                end)::varchar as "Side"
      , i.display_instrument_id as "Symbol"
      , po.order_qty::bigint as "Ord Qty"
      , po.price as "Price"
      , fyc.filled_qty as "Ex Qty"
      , fyc.avg_px as "Avg Px"
      , ss.target_strategy_desc as "Sub Strategy"
      , dc.ex_destination_code_name as "Ex Dest"
      , ot.order_type_name as "Ord Type"
      , tif.tif_name as "TIF"
      , f.fix_comp_id as "Sending Firm"
      , cf.customer_or_firm_name as "Capacity"
      , po.client_id_text as "Client ID"
      , coalesce(po.clearing_firm_id, fx_co.clearing_firm_id) as "CMTA"
      , to_char(to_date(po.create_date_id::varchar, 'YYYYMMDD'), 'DD.MM.YYYY')::varchar as "Creation Date"
      , cro.cross_type::varchar as "Cross Ord Type"
      , to_char(fyc.exec_time, 'DD.MM.YYYY')::varchar as "Event Date"
      , ebr.opt_exec_broker as "Exec Broker"
      , date_trunc('day', i.last_trade_date)::date as "Expiration Day"
      , l.client_leg_ref_id as "Leg ID"
      , ex.leaves_qty::bigint as "Lvs Qty"
      , (case when po.open_close = 'O' then 'Open' else 'Close' end)::varchar as "O/C"
      , oo.client_order_id as "Orig Cl Ord ID"
      , po.opra_symbol as "OSI Symbol"
      , po.root_symbol as "Root Symbol"
      , it.instrument_type_name as "Security Type"
      , po.stop_price as "Stop Px"
      , ui.display_instrument_id as "Underlying Symbol"
      --, po.*
--select count(1)
    from
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      )  scp
      left join lateral
      (
        select po.order_id
          , po.orig_order_id
          , po.account_id
          , po.multileg_reporting_type
          , po.multileg_order_id
          , po.cross_order_id
          , po.create_date_id
          , po.client_order_id
          , po.instrument_id
          , po.order_qty
          , po.price
          , po.side
          , po.sub_strategy_id
          , po.ex_destination_code_id
          , po.ex_destination
          , po.order_type_id
          , po.time_in_force_id
          , po.customer_or_firm_id
          , po.order_capacity_id
          , po.client_id_text
          , po.process_time
          , po.opt_exec_broker_id
          , po.no_legs
          , po.open_close
          , po.fix_connection_id
          , po.clearing_firm_id
          , po.fix_message_id
          , po.stop_price
          , po.trans_type
          , oc.option_series_id
          , oc.opra_symbol
          , os.underlying_instrument_id
          , os.root_symbol
          --, po.*
        from dwh.client_order po
        left join dwh.d_option_contract oc
          ON po.instrument_id = oc.instrument_id
        left join dwh.d_option_series os
          --ON oc.option_series_id = os.option_series_id
          ON oc.option_series_id = os.option_series_id
        where 1=1
          and po.create_date_id between l_gtc_start_date_id and l_end_date_id -- last half of year. GTC purpose
          and po.order_id = scp.order_id
        limit 1 -- for NL acceleration
      ) po ON true
      left join dwh.client_order oo
        ON po.orig_order_id = oo.order_id
        and oo.create_date_id between l_gtc_start_date_id and l_end_date_id
      left join dwh.d_account ac
        ON po.account_id = ac.account_id
      left join lateral
        (
           select sum(fyc.day_cum_qty) as filled_qty
             , round(sum(fyc.day_avg_px*fyc.day_cum_qty)/nullif(sum(fyc.day_cum_qty), 0)::numeric, 4)::numeric as avg_px
             , min(fyc.routed_time) as routed_time
             , max(fyc.exec_time) as exec_time -- can it be event_time or transact time? min or max?
             , fyc.order_id
             , min(fyc.nbbo_bid_price) as nbbo_bid_price
             , min(fyc.nbbo_bid_quantity) as nbbo_bid_quantity
             , min(fyc.nbbo_ask_price) as nbbo_ask_price
             , min(fyc.nbbo_ask_quantity) as nbbo_ask_quantity
           from data_marts.f_yield_capture fyc -- here we have all orders, so we can use it for cum_qty calculation (instead of FTR)
           where fyc.order_id = po.order_id
             and fyc.status_date_id between l_gtc_start_date_id and l_end_date_id
           group by fyc.order_id
           limit 1 -- just in case to insure NL join method
        ) fyc on true
      -- the last execution
      left join lateral
        (
          select ex.text_
            , ex.order_status
            , ex.exec_type
            , ex.exec_id
            , ex.leaves_qty
          from dwh.execution ex
          where 1=1
            --and ex.exec_date_id = 20190604
            and ex.exec_date_id between l_start_date_id and l_end_date_id
            and ex.order_id = po.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      -- fix_message of order
      left join lateral
        (
          select (j.fix_message->>'439')::varchar as clearing_firm_id
          from fix_capture.fix_message_json j
          where 1=1
            and po.clearing_firm_id is null --
            and j.date_id between l_start_date_id and l_end_date_id -- l_gtc_start_date_id was very slow condition
            and j.fix_message_id = po.fix_message_id
            and j.date_id = po.create_date_id
          limit 1
        ) fx_co on true
      left join dwh.d_order_status st
        ON ex.order_status = st.order_status
      left join dwh.d_exec_type et
        ON ex.exec_type = et.exec_type
      left join dwh.d_instrument i
        ON po.instrument_id = i.instrument_id
      left join dwh.d_instrument_type it
        ON i.instrument_type_id = it.instrument_type_id
      left join dwh.d_instrument ui
        --ON os.underlying_instrument_id = ui.instrument_id
        ON po.underlying_instrument_id = ui.instrument_id
      left join dwh.d_target_strategy ss
        ON po.sub_strategy_id = ss.target_strategy_id
      left join dwh.d_ex_destination_code dc
        ON po.ex_destination = dc.ex_destination_code
      left join dwh.d_order_type ot
        ON po.order_type_id = ot.order_type_id
      left join dwh.d_time_in_force tif
        ON po.time_in_force_id = tif.tif_id
    /*  left join --lateral
        (
          select ---min(ecf.customer_or_firm_id) as customer_or_firm_id
            ecf.customer_or_firm_id
            , ecf.exch_customer_or_firm_id, ecf.exchange_id  -- lookup key
            , row_number() over (partition by ecf.exch_customer_or_firm_id, ecf.exchange_id order by ecf.customer_or_firm_id) as rn
          from dwh.d_exchange2customer_or_firm ecf
        ) ecf
        ON ecf.rn = 1 --true
          and o.customer_or_firm is null
          and ecf.exch_customer_or_firm_id = o.order_capacity
          and ecf.exchange_id = o.exchange_id */
      left join dwh.d_customer_or_firm cf ON cf.customer_or_firm_id = COALESCE(po.customer_or_firm_id, ac.opt_customer_or_firm) and cf.is_active = true -- ecf.customer_or_firm_id,
      left join dwh.cross_order cro
        ON po.cross_order_id = cro.cross_order_id
      left join dwh.d_opt_exec_broker ebr
        ON po.opt_exec_broker_id = ebr.opt_exec_broker_id
      left join dwh.d_fix_connection f
        ON po.fix_connection_id = f.fix_connection_id
      /*left join dwh.client_order_leg l
        ON l.order_id = po.order_id
        and l.multileg_order_id = po.multileg_order_id*/
      left join lateral
        (
          select l.order_id, l.client_leg_ref_id
          from dwh.client_order_leg l
          where l.multileg_order_id = po.multileg_order_id
          limit 3000
        ) l ON l.order_id = po.order_id
    where po.trans_type <> 'F' -- not cancell request
    order by po.process_time, 1;
  end if;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

 select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl COMPLETE ========= ' , l_row_cnt, 'O')
   into l_step_id;
   RETURN;
END;
$$;


CREATE FUNCTION external_data.p_load_f_box_street_executions_daily_bkp(in_date_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
   l_row_cnt integer;

   l_load_id int;
   l_step_id int;

   l_cur_date_id integer;
   l_min_gtc_date_id integer;

BEGIN
  /*
    we don't need to run this AFTER the HODS processed.
  */

  --if in_recalc_date_id is null
  --then return -1;
  --end if;

  select nextval('public.load_timing_seq') into l_load_id;

  l_step_id:=1;

  select public.load_log(l_load_id, l_step_id, 'p_load_f_box_street_executions_daily STARTED===', 0, 'O')
   into l_step_id;


   -- Variables definition
   l_cur_date_id   := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::integer);
   l_min_gtc_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '180 days', 'YYYYMMDD')::integer;


  -- Temporary table definition

/*    execute 'CREATE TEMP TABLE IF NOT EXISTS tmp_box_street_orders (
      create_date_id int4 NULL,
      client_order_id varchar(256) NULL,
      parent_client_order_id varchar(256) NULL,
      parent_create_date_id int4 NULL,
      orders_count int4 NULL,
      CONSTRAINT "tmp_PK_tmp_box_street_orders" PRIMARY KEY (parent_client_order_id, create_date_id, client_order_id)
    )';

  execute 'truncate table tmp_box_street_orders';
*/

-- fill Temp table

/*    insert into tmp_box_street_orders
      (
        create_date_id,
        client_order_id,
        parent_client_order_id,
        parent_create_date_id,
        orders_count
      )
    select so.create_date_id, so.client_order_id, po.client_order_id as parent_client_order_id, po.create_date_id as parent_create_date_id, count(1)
    from dwh.client_order so
      left join lateral
        (
          select po.client_order_id, po.create_date_id
          from dwh.client_order po
          where po.create_date_id between l_min_gtc_date_id and l_cur_date_id --20190414 and 20190514
            and po.order_id = so.parent_order_id
          limit 1
        ) po on true
    where so.parent_order_id is not null -- street level
      and so.create_date_id = l_cur_date_id
      --and so.ex_destination = 'W' -- box -- a little bit slower than via exchange_id
      and so.exchange_id in (select ex.exchange_id from dwh.d_exchange ex where ex.real_exchange_id = 'box') -- быстрее
    group by so.create_date_id, so.client_order_id, po.client_order_id, po.create_date_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'street orders loaded into tmp_box_street_orders ', l_row_cnt , 'I')
     into l_step_id;

    ANALYZE tmp_box_street_orders;
    select public.load_log(l_load_id, l_step_id, 'Statistics gathered for tmp_box_street_orders ', 0 , 'O')
     into l_step_id;

 IF (l_row_cnt > 0) -- we have some data loaded
  THEN

  --> correction of Min date_id for parent orders
    select coalesce( (select min(parent_create_date_id) from tmp_box_street_orders), l_min_gtc_date_id) into l_min_gtc_date_id
    ;
    select public.load_log(l_load_id, l_step_id, 'Calculation date_id = '||l_cur_date_id::varchar||', MIN parent orders date_id = '||l_min_gtc_date_id::varchar, 0 , 'O')
     into l_step_id;

  --> delete calculated data befor recalculation
    delete
    from external_data.f_box_street_executions t
    where t.create_date_id = l_cur_date_id -- date_id of street orders
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'cleanup of external_data.f_box_street_executions before calculation.', l_row_cnt , 'D')
     into l_step_id;

  --> insert data
    INSERT INTO external_data.f_box_street_executions
      ( create_date_id
      , message_type
      , parent_message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_routed_time
      , parent_create_date_id )

--select count(1) into l_row_cnt from (
    select str.create_date_id
      , fs.message_type_2 as message_type
      , fp.message_type_2 as parent_message_type
      , fs.exec_type
      , fs.order_status
      , fs.street_client_order_id
      , fs.street_orig_client_order_id
      , fs.street_order_id
      , fs.street_exec_id
      , fs.street_secondary_order_id
      , fs.street_orig_exec_id
      --, to_char(fs.street_transact_time, 'YYYY-MM-DD HH24:MI:SS.MS') as street_transact_time
      --, to_char(fs.street_sending_time, 'YYYY-MM-DD HH24:MI:SS.MS') as street_sending_time
      --, to_char(fs.street_routed_time, 'YYYY-MM-DD HH24:MI:SS.US') as street_routed_time
      , fs.street_transact_time
      , fs.street_sending_time
      , fs.street_routed_time
      , fs.target_location_id
      , fs.client_id
      , fs.clearing_optional_data
      , coalesce(fs.parent_client_order_id, str.parent_client_order_id) as parent_client_order_id
      , fp.parent_exec_id
      , fp.parent_orig_client_order_id
      , fp.parent_secondary_order_id
      , fp.parent_secondary_exec_id
      , fp.parent_routed_time
      , case when fs.message_type not in ('8','9') then str.parent_create_date_id end as parent_create_date_id
      --select count(1) -- should be about 300k. nope. only 116k and it takes about 4 minutes to filter out street orders
    from
      (
        select tmp.create_date_id, tmp.client_order_id, tmp.parent_client_order_id, tmp.parent_create_date_id, tmp.orders_count
        from tmp_box_street_orders tmp
        --from staging.sdn_tmp_box_street_orders tmp
        --limit 10000
      ) str -- the list of street orders
      left join lateral
      (
        select j.message_type
          , j.fix_message->>'35' as message_type_2
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'39' as order_status
          , j.fix_message->>'11' as street_client_order_id
          , j.fix_message->>'41' as street_orig_client_order_id
          --, to_timestamp(j.fix_message->>'5050', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as routed_time_5050
          --, to_timestamp(j.fix_message->>'5051', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as routed_time_5051
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , j.fix_message->>'143' as target_location_id
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , coalesce(j.fix_message->>'10442', j.fix_message->>'5059')::varchar as parent_client_order_id
          -- additional attrinutes as 9769 tag is often missed in parent reports
          , j.fix_message->>'55' as symbol
          , j.fix_message->>'167' as instrument_type
          , j.fix_message->>'200' as exp_ym
          , j.fix_message->>'205' as exp_day
          , j.fix_message->>'201' as put_call
          , j.fix_message->>'202' as strike_px
          , j.fix_message->>'31' as last_px
          , j.fix_message->>'32' as last_qty
        from fix_capture.fix_message_json j
        where j.date_id = l_cur_date_id::integer
          and j.date_id = str.create_date_id
          and j.client_order_id = str.client_order_id
          and not ((j.fix_message->>'35')::varchar in ('8','9') and ((j.fix_message->>'167')::varchar = 'MLEG' or (j.fix_message->>'150')::varchar = '4' ))
        limit 1000 -- executions count for one street_client_order_id
      ) fs on true -- fix_str
      left join lateral
      (
        select j.message_type
          , j.fix_message->>'35' as message_type_2
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'39' as order_status
          , j.client_order_id
          , j.fix_message->>'17' as parent_exec_id
          , j.fix_message->>'41' as parent_orig_client_order_id
          , j.fix_message->>'198' as parent_secondary_order_id
          , j.fix_message->>'9769' as parent_secondary_exec_id
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as parent_routed_time
        from fix_capture.fix_message_json j
        where j.date_id = l_cur_date_id::integer --between l_min_gtc_date_id and l_cur_date_id
          --and j.date_id = str.create_date_id -- this is a question
          --and case when j.message_type in ('8','9') then str.create_date_id else str.parent_create_date_id end = j.date_id

--какой date_id у GTC-шного парентового ордера нам нужен?
-- теоретически для ордера - дата клайант-ордера
-- для репорта = дата репорта

          and j.client_order_id = str.parent_client_order_id --coalesce(fs.parent_client_order_id, str.parent_client_order_id)
          and ( (j.fix_message->>'9769')::varchar = fs.street_exec_id
               or
               ( ( ( (j.fix_message->>'442')::varchar = '2' -- only for legs including last prices and qty's
                     and (j.fix_message->>'31')::numeric = fs.last_px::numeric
                     and (j.fix_message->>'32')::varchar = fs.last_qty::varchar
                   )
                    or fs.exec_type = '0' -- first report can also not to have 9769 tag
                 )
                 --   (j.fix_message->>'39')::varchar = fs.order_status
                and (j.fix_message->>'150')::varchar <> 'E' -- not "pending replace" - exec_type
                and (case when (j.fix_message->>'150')::varchar = '5' then '0' else j.fix_message->>'150' end)::varchar = fs.exec_type -- Replaced status of report will be equal to New
                and (j.fix_message->>'55')::varchar = fs.symbol
                and (j.fix_message->>'167')::varchar = fs.instrument_type
                and coalesce((j.fix_message->>'200')::varchar, '-1') = coalesce(fs.exp_ym, '-1') -- exp_year_month
                and coalesce((j.fix_message->>'205')::varchar, '-1') = coalesce(fs.exp_day, '-1') -- exp_day
                and coalesce((j.fix_message->>'201')::varchar, '-1') = coalesce(fs.put_call, '-1') -- put_call
                and coalesce((j.fix_message->>'202')::numeric, '-1') = coalesce(fs.strike_px::numeric, '-1') -- strike
                --and (  )
               )
               or
               ( fs.message_type not in ('8','9') -- in case of orders(not reports). Just match them
                 --and (j.fix_message->>'41')::varchar = fs.
               )
              )
          and not ((j.fix_message->>'35')::varchar in ('8','9') and ((j.fix_message->>'167')::varchar = 'MLEG' or (j.fix_message->>'150')::varchar in ('4','E') ))
          and case when j.message_type in ('8','9') then 'r' else 'o' end = case when fs.message_type in ('8','9') then 'r' else 'o' end -- order messages to orders, reports to reports
        limit 1 -- just in case. We need one to one, street to parent matched executions.
      ) fp on true -- fix_par
    --order by coalesce(fs.street_orig_client_order_id, fs.street_client_order_id), fs.street_routed_time
--  ) src
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Load into external_data.f_box_street_executions ', l_row_cnt , 'I')
     into l_step_id;
*/

  --> delete calculated data befor recalculation
    delete
    from external_data.f_box_street_executions t
    where t.create_date_id = l_cur_date_id -- date_id of street orders
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'cleanup of external_data.f_box_street_executions before calculation. l_cur_date_id = '||l_cur_date_id::varchar, l_row_cnt , 'R')
     into l_step_id;


    INSERT INTO external_data.f_box_street_executions
      ( create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst
      , sender_comp_id
      , side
      , price
      , order_qty)
  select
        create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst
      , sender_comp_id
      , side
      , price
      , order_qty
  from
  (

    with str_ord as materialized
      (
        --select tmp.create_date_id, tmp.client_order_id, tmp.parent_client_order_id, tmp.parent_create_date_id, tmp.orders_count
        --from tmp_box_street_orders tmp
        --from staging.sdn_tmp_box_street_orders  tmp
        --limit 10000

        select so.create_date_id, so.client_order_id, so.order_id as order_id, so.fix_message_id -- message of order, not report. Sometimes it points to parent level fix message.
          , po.client_order_id as parent_client_order_id, so.parent_order_id, po.fix_message_id as parent_fix_message_id, po.create_date_id as parent_create_date_id, count(1)
          , so.orig_order_id, so_org.client_order_id as street_orig_client_order_id, po_org.client_order_id as parent_orig_client_order_id
          , so.multileg_reporting_type, so.client_id_text, ac.account_name, so.instrument_id
        from dwh.client_order so
          left join dwh.d_account ac
            on so.account_id = ac.account_id
          left join lateral
            (
              select po.client_order_id, po.create_date_id, po.fix_message_id, po.orig_order_id
              from dwh.client_order po
              where po.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and po.order_id = so.parent_order_id
                --and  cross_order_id is not null
              limit 1
            ) po on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = so.orig_order_id
              limit 1
            ) so_org on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = po.orig_order_id
              limit 1
            ) po_org on true
        where so.parent_order_id is not null -- street level
          and so.create_date_id = l_cur_date_id -- between 20190509 and 20190517 -- = 20190515 --l_cur_date_id
          --and so.ex_destination = 'W' -- box -- a little bit slower than via exchange_id
          and so.exchange_id in (select ex.exchange_id from dwh.d_exchange ex where ex.real_exchange_id = 'BOX' union select 'C1PAR' union select 'CBOEEH') -- быстрее
          and so.multileg_reporting_type in ('1','2')
          and so.cross_order_id is not null
          --and so.client_order_id in ('AAA0053-20190514','LAA2248-20190517','MTA2616-20190509','MTA3809-20190509','MTA2333-20190513', 'MTA2355-20190513', 'MTA3079-20190510', 'MTA3086-20190510')
        group by so.create_date_id, so.client_order_id, so.order_id, so.fix_message_id, po.client_order_id, so.parent_order_id, po.fix_message_id, po.create_date_id
          , so.orig_order_id, so_org.client_order_id, po_org.client_order_id
          , so.multileg_reporting_type, so.client_id_text, ac.account_name, so.instrument_id
      )
    select str.create_date_id --count(1) -- 131309
      , sef.message_type
      , coalesce(sef.exec_type, ser.exec_type) as exec_type -- in executions we have replacement of 1 and 2 into F
      , ser.order_status
      , str.client_order_id as street_client_order_id
      , coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id) as street_orig_client_order_id
      --, str.street_orig_client_order_id --, sef.street_orig_client_order_id

      , sef.street_order_id as street_order_id -- 37
      , coalesce(ser.exch_exec_id, sef.street_exec_id) as street_exec_id -- 17 ? why aren't they equal
      , coalesce(ser.secondary_order_id, sef.street_secondary_order_id) as street_secondary_order_id
      , sef.street_orig_exec_id as street_orig_exec_id -- 19

      , coalesce(sef.street_transact_time, ser.exec_time) as street_transact_time
      , sef.street_sending_time as street_sending_time
      , sef.street_routed_time as street_routed_time
      , sef.target_location_id as target_location_id -- it is only for orders reports sent to exchange
      , coalesce(str.client_id_text, sef.client_id) as client_id
      , sef.clearing_optional_data -- 9324

      , str.parent_client_order_id
      , per.exch_exec_id as parent_exec_id
      , str.parent_orig_client_order_id
      , per.secondary_order_id as parent_secondary_order_id
      , per.secondary_exch_exec_id as parent_secondary_exec_id


      -- additional information needed
      , str.parent_create_date_id
      , sef.street_instrument_type
      , row_number() over (partition by str.client_order_id, ser.exch_exec_id, coalesce(sef.account_name, str.account_name) order by str.order_id) as rn1 -- need only one order record for multileg
      , row_number() over (partition by str.create_date_id, sef.message_type, str.client_order_id, sef.street_order_id, coalesce(ser.exch_exec_id, sef.street_exec_id), coalesce(sef.account_name, str.account_name), str.instrument_id order by str.order_id) as rn2 -- deduplication when we have (43) PossDupFlag = 'Y' (BAA0002-20181002)
      , coalesce(sef.account_name, str.account_name) as street_account_name

      -- requested by John
      , sef.fix_tag_115 as on_behalf_of_comp_id
      , sef.fix_tag_423 as price_type
      , sef.fix_tag_18 as exec_inst
      , sef.sender_comp_id
      , sef.side
      , sef.price::numeric
      , sef.order_qty::int

      /*, sef.client_order
      , str.fix_message_id
      , str.order_id
      , str.multileg_reporting_type
      , str.parent_order_id
      --, ser.* --exec_id
      , per.* */

    from
      (
        select str.order_id -- for executions -> reports lookup
          , str.parent_order_id  -- for executions -> reports of parent orders lookup
          , null::bigint as fix_message_id        -- for orders messages lookup
          , null::bigint as parent_fix_message_id -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_id_text
          , str.parent_client_order_id
          , null as parent_orig_client_order_id
          , null as parent_create_date_id
          , str.account_name
          , str.instrument_id
        from str_ord  str -- the list of street orders
        union all
        select distinct null::bigint as order_id -- for executions -> reports lookup
          , null::bigint as parent_order_id     -- for executions -> reports of parent orders lookup
          , str.fix_message_id         -- for orders messages lookup
          , str.parent_fix_message_id  -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_id_text
          , str.parent_client_order_id
          , str.parent_orig_client_order_id
          , str.parent_create_date_id
          , str.account_name
          , null::bigint as instrument_id
        from str_ord  str -- the list of street orders
      ) str -- the list of street orders plus their orders fix message ids
      left join lateral
      (
        select -- for return
            e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- for join
          , e.fix_message_id, e.exec_id, e.order_id, e.text_
          --, e.*
        from dwh.execution e
        where 1=1
          and e.fix_message_id is not null -- if it is null then there is possibility that execution is syntethic generated
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.order_id -- in (1679652736,1679652738,1679652740,1679660660,1679660663,1679660666) --
          and e.exec_type not in ('4', 'A', 'b')
          --and not exists (select 1 from fix_capture.fix_message_json j where j.date_id = 20190513 and j.fix_message_id = e.fix_message_id and ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' ))
          --and e.order_id = 1679652736 -- in (1679652736,1679652738,1679652740) -- (1674593569, 1674593570, 1674593571) --
      ) ser on true -- street executions reports from exchange
      inner join lateral
      (
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
          , j.fix_message->>'49' as sender_comp_id
          , j.fix_message->>'54' as side
          , j.fix_message->>'44' as price
          , j.fix_message->>'38' as order_qty
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = ser.fix_message_id -- coalesce(ser.fix_message_id, fix_message_id) --in (3914795705, 3914778052) -- message for street report and not orders
          and j.fix_message->>'9383' = 'R'
          -- try to exclude multileg reports except rejects
          --and not ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' )
        union
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
          , j.fix_message->>'49' as sender_comp_id
          , j.fix_message->>'54' as side
          , j.fix_message->>'44' as price
          , j.fix_message->>'38' as order_qty
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = str.fix_message_id ---  3914778051 --  in (3914795705, 3914778052) -- message for street order and not report
          and j.fix_message->>'9383' = 'R'
      ) sef on true -- street execution fix messages for reports from exchange
      left join lateral
      (
        select -- fields to return
            e.fix_message_id -- for return
          , e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- other fields
          , e.fix_message_id, e.exec_id, e.order_id, e.text_
          --, e.*
        from dwh.execution e
        where 1=1
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.parent_order_id -- (1674593565, 1674593567)  two legs with their own parents
          -- get rid of multileg message
          and (e.secondary_order_id is not null or e.order_status = '0')
          -- status matching
          and
            (
              e.secondary_exch_exec_id = ser.exch_exec_id
              or
              (e.order_status = '0' and ser.order_status = '0')
            )
        order by e.secondary_order_id desc nulls last, e.exec_time desc -- in case of presence both mleg and opt order executions for order with status = '0'
        limit 1
      ) per on true -- parent execution reports from exchange
 -- order by coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id, str.client_order_id), sef.street_routed_time

    ) src
  where 1=1 and (case when src.street_instrument_type = 'MLEG' then src.rn1 else 1 end = 1) and src.rn2 = 1
  --order by coalesce(src.street_orig_client_order_id, src.street_client_order_id), src.street_routed_time
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Load into external_data.f_box_street_executions ', l_row_cnt , 'I')
     into l_step_id;



  select public.load_log(l_load_id, l_step_id, 'p_load_f_box_street_executions_daily COMPLETE ========= ' , 0, 'O')
   into l_step_id;
  RETURN 1;

exception when others then
  select public.load_log(l_load_id, l_step_id, sqlerrm , 0, 'E')
  into l_step_id;
  -- PERFORM public.load_error_log('p_load_f_box_street_executions_daily',  'I', sqlerrm, l_load_id);

  RAISE;

END;
$$;


CREATE FUNCTION external_data.p_load_f_cboe_street_executions_daily_bkp(in_date_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
   l_row_cnt integer;

   l_load_id int;
   l_step_id int;

   l_cur_date_id integer;
   l_min_gtc_date_id integer;

BEGIN
  /*
    we don't need to run this AFTER the HODS processed.
  */

  --if in_recalc_date_id is null
  --then return -1;
  --end if;

  select nextval('public.load_timing_seq') into l_load_id;

  l_step_id:=1;

  select public.load_log(l_load_id, l_step_id, 'p_load_f_cboe_street_executions_daily STARTED===', 0, 'O')
   into l_step_id;


   -- Variables definition
   l_cur_date_id   := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::integer);
   l_min_gtc_date_id := to_char(to_date(l_cur_date_id::text,'YYYYMMDD') - interval '180 days', 'YYYYMMDD')::integer;


  -- Temporary table definition

/*    execute 'CREATE TEMP TABLE IF NOT EXISTS tmp_cboe_street_orders (
      create_date_id int4 NULL,
      client_order_id varchar(256) NULL,
      parent_client_order_id varchar(256) NULL,
      parent_create_date_id int4 NULL,
      orders_count int4 NULL,
      CONSTRAINT "tmp_PK_tmp_cboe_street_orders" PRIMARY KEY (parent_client_order_id, create_date_id, client_order_id)
    )';

  execute 'truncate table tmp_cboe_street_orders';
*/

-- fill Temp table

/*    insert into tmp_cboe_street_orders
      (
        create_date_id,
        client_order_id,
        parent_client_order_id,
        parent_create_date_id,
        orders_count
      )
    select so.create_date_id, so.client_order_id, po.client_order_id as parent_client_order_id, po.create_date_id as parent_create_date_id, count(1)
    from dwh.client_order so
      left join lateral
        (
          select po.client_order_id, po.create_date_id
          from dwh.client_order po
          where po.create_date_id between l_min_gtc_date_id and l_cur_date_id --20190414 and 20190514
            and po.order_id = so.parent_order_id
          limit 1
        ) po on true
    where so.parent_order_id is not null -- street level
      and so.create_date_id = l_cur_date_id
      --and so.ex_destination = 'W' -- CBOE -- a little bit slower than via exchange_id
      and so.exchange_id in (select ex.exchange_id from dwh.d_exchange ex where ex.real_exchange_id = 'CBOE') -- быстрее
    group by so.create_date_id, so.client_order_id, po.client_order_id, po.create_date_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'street orders loaded into tmp_cboe_street_orders ', l_row_cnt , 'I')
     into l_step_id;

    ANALYZE tmp_cboe_street_orders;
    select public.load_log(l_load_id, l_step_id, 'Statistics gathered for tmp_cboe_street_orders ', 0 , 'O')
     into l_step_id;

 IF (l_row_cnt > 0) -- we have some data loaded
  THEN

  --> correction of Min date_id for parent orders
    select coalesce( (select min(parent_create_date_id) from tmp_cboe_street_orders), l_min_gtc_date_id) into l_min_gtc_date_id
    ;
    select public.load_log(l_load_id, l_step_id, 'Calculation date_id = '||l_cur_date_id::varchar||', MIN parent orders date_id = '||l_min_gtc_date_id::varchar, 0 , 'O')
     into l_step_id;

  --> delete calculated data befor recalculation
    delete
    from external_data.f_cboe_street_executions t
    where t.create_date_id = l_cur_date_id -- date_id of street orders
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'cleanup of external_data.f_cboe_street_executions before calculation.', l_row_cnt , 'D')
     into l_step_id;

  --> insert data
    INSERT INTO external_data.f_cboe_street_executions
      ( create_date_id
      , message_type
      , parent_message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_routed_time
      , parent_create_date_id )

--select count(1) into l_row_cnt from (
    select str.create_date_id
      , fs.message_type_2 as message_type
      , fp.message_type_2 as parent_message_type
      , fs.exec_type
      , fs.order_status
      , fs.street_client_order_id
      , fs.street_orig_client_order_id
      , fs.street_order_id
      , fs.street_exec_id
      , fs.street_secondary_order_id
      , fs.street_orig_exec_id
      --, to_char(fs.street_transact_time, 'YYYY-MM-DD HH24:MI:SS.MS') as street_transact_time
      --, to_char(fs.street_sending_time, 'YYYY-MM-DD HH24:MI:SS.MS') as street_sending_time
      --, to_char(fs.street_routed_time, 'YYYY-MM-DD HH24:MI:SS.US') as street_routed_time
      , fs.street_transact_time
      , fs.street_sending_time
      , fs.street_routed_time
      , fs.target_location_id
      , fs.client_id
      , fs.clearing_optional_data
      , coalesce(fs.parent_client_order_id, str.parent_client_order_id) as parent_client_order_id
      , fp.parent_exec_id
      , fp.parent_orig_client_order_id
      , fp.parent_secondary_order_id
      , fp.parent_secondary_exec_id
      , fp.parent_routed_time
      , case when fs.message_type not in ('8','9') then str.parent_create_date_id end as parent_create_date_id
      --select count(1) -- should be about 300k. nope. only 116k and it takes about 4 minutes to filter out street orders
    from
      (
        select tmp.create_date_id, tmp.client_order_id, tmp.parent_client_order_id, tmp.parent_create_date_id, tmp.orders_count
        from tmp_cboe_street_orders tmp
        --from staging.sdn_tmp_cboe_street_orders tmp
        --limit 10000
      ) str -- the list of street orders
      left join lateral
      (
        select j.message_type
          , j.fix_message->>'35' as message_type_2
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'39' as order_status
          , j.fix_message->>'11' as street_client_order_id
          , j.fix_message->>'41' as street_orig_client_order_id
          --, to_timestamp(j.fix_message->>'5050', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as routed_time_5050
          --, to_timestamp(j.fix_message->>'5051', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as routed_time_5051
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , j.fix_message->>'143' as target_location_id
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , coalesce(j.fix_message->>'10442', j.fix_message->>'5059')::varchar as parent_client_order_id
          -- additional attrinutes as 9769 tag is often missed in parent reports
          , j.fix_message->>'55' as symbol
          , j.fix_message->>'167' as instrument_type
          , j.fix_message->>'200' as exp_ym
          , j.fix_message->>'205' as exp_day
          , j.fix_message->>'201' as put_call
          , j.fix_message->>'202' as strike_px
          , j.fix_message->>'31' as last_px
          , j.fix_message->>'32' as last_qty
        from fix_capture.fix_message_json j
        where j.date_id = l_cur_date_id::integer
          and j.date_id = str.create_date_id
          and j.client_order_id = str.client_order_id
          and not ((j.fix_message->>'35')::varchar in ('8','9') and ((j.fix_message->>'167')::varchar = 'MLEG' or (j.fix_message->>'150')::varchar = '4' ))
        limit 1000 -- executions count for one street_client_order_id
      ) fs on true -- fix_str
      left join lateral
      (
        select j.message_type
          , j.fix_message->>'35' as message_type_2
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'39' as order_status
          , j.client_order_id
          , j.fix_message->>'17' as parent_exec_id
          , j.fix_message->>'41' as parent_orig_client_order_id
          , j.fix_message->>'198' as parent_secondary_order_id
          , j.fix_message->>'9769' as parent_secondary_exec_id
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as parent_routed_time
        from fix_capture.fix_message_json j
        where j.date_id = l_cur_date_id::integer --between l_min_gtc_date_id and l_cur_date_id
          --and j.date_id = str.create_date_id -- this is a question
          --and case when j.message_type in ('8','9') then str.create_date_id else str.parent_create_date_id end = j.date_id

--какой date_id у GTC-шного парентового ордера нам нужен?
-- теоретически для ордера - дата клайант-ордера
-- для репорта = дата репорта

          and j.client_order_id = str.parent_client_order_id --coalesce(fs.parent_client_order_id, str.parent_client_order_id)
          and ( (j.fix_message->>'9769')::varchar = fs.street_exec_id
               or
               ( ( ( (j.fix_message->>'442')::varchar = '2' -- only for legs including last prices and qty's
                     and (j.fix_message->>'31')::numeric = fs.last_px::numeric
                     and (j.fix_message->>'32')::varchar = fs.last_qty::varchar
                   )
                    or fs.exec_type = '0' -- first report can also not to have 9769 tag
                 )
                 --   (j.fix_message->>'39')::varchar = fs.order_status
                and (j.fix_message->>'150')::varchar <> 'E' -- not "pending replace" - exec_type
                and (case when (j.fix_message->>'150')::varchar = '5' then '0' else j.fix_message->>'150' end)::varchar = fs.exec_type -- Replaced status of report will be equal to New
                and (j.fix_message->>'55')::varchar = fs.symbol
                and (j.fix_message->>'167')::varchar = fs.instrument_type
                and coalesce((j.fix_message->>'200')::varchar, '-1') = coalesce(fs.exp_ym, '-1') -- exp_year_month
                and coalesce((j.fix_message->>'205')::varchar, '-1') = coalesce(fs.exp_day, '-1') -- exp_day
                and coalesce((j.fix_message->>'201')::varchar, '-1') = coalesce(fs.put_call, '-1') -- put_call
                and coalesce((j.fix_message->>'202')::numeric, '-1') = coalesce(fs.strike_px::numeric, '-1') -- strike
                --and (  )
               )
               or
               ( fs.message_type not in ('8','9') -- in case of orders(not reports). Just match them
                 --and (j.fix_message->>'41')::varchar = fs.
               )
              )
          and not ((j.fix_message->>'35')::varchar in ('8','9') and ((j.fix_message->>'167')::varchar = 'MLEG' or (j.fix_message->>'150')::varchar in ('4','E') ))
          and case when j.message_type in ('8','9') then 'r' else 'o' end = case when fs.message_type in ('8','9') then 'r' else 'o' end -- order messages to orders, reports to reports
        limit 1 -- just in case. We need one to one, street to parent matched executions.
      ) fp on true -- fix_par
    --order by coalesce(fs.street_orig_client_order_id, fs.street_client_order_id), fs.street_routed_time
--  ) src
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Load into external_data.f_cboe_street_executions ', l_row_cnt , 'I')
     into l_step_id;
*/

  --> delete calculated data befor recalculation
    delete
    from external_data.f_cboe_street_executions t
    where t.create_date_id = l_cur_date_id -- date_id of street orders
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'cleanup of external_data.f_cboe_street_executions before calculation. l_cur_date_id = '||l_cur_date_id::varchar, l_row_cnt , 'R')
     into l_step_id;


    INSERT INTO external_data.f_cboe_street_executions
      ( create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst)
  select
        create_date_id
      , message_type
      , exec_type
      , order_status
      , street_client_order_id
      , street_orig_client_order_id
      , street_order_id
      , street_exec_id
      , street_secondary_order_id
      , street_orig_exec_id
      , street_transact_time
      , street_sending_time
      , street_routed_time
      , target_location_id
      , client_id
      , clearing_optional_data
      , parent_client_order_id
      , parent_exec_id
      , parent_orig_client_order_id
      , parent_secondary_order_id
      , parent_secondary_exec_id
      , parent_create_date_id
      , street_account_name
      , on_behalf_of_comp_id
      , price_type
      , exec_inst
  from
  (

    with str_ord as materialized
      (
        --select tmp.create_date_id, tmp.client_order_id, tmp.parent_client_order_id, tmp.parent_create_date_id, tmp.orders_count
        --from tmp_cboe_street_orders tmp
        --from staging.sdn_tmp_cboe_street_orders  tmp
        --limit 10000

        select so.create_date_id, so.client_order_id, so.order_id as order_id, so.fix_message_id -- message of order, not report. Sometimes it points to parent level fix message.
          , po.client_order_id as parent_client_order_id, so.parent_order_id, po.fix_message_id as parent_fix_message_id, po.create_date_id as parent_create_date_id, count(1)
          , so.orig_order_id, so_org.client_order_id as street_orig_client_order_id, po_org.client_order_id as parent_orig_client_order_id
          , so.multileg_reporting_type, cl.client_src_id, ac.account_name, so.instrument_id
        from dwh.client_order so
          left join data_marts.d_client cl
            on so.client_id = cl.client_id
          left join dwh.d_account ac
            on so.account_id = ac.account_id
          left join lateral
            (
              select po.client_order_id, po.create_date_id, po.fix_message_id, po.orig_order_id
              from dwh.client_order po
              where po.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and po.order_id = so.parent_order_id
              limit 1
            ) po on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = so.orig_order_id
              limit 1
            ) so_org on true
           left join lateral
            (
              select org.client_order_id, org.create_date_id
              from dwh.client_order org
              where org.create_date_id between l_min_gtc_date_id and l_cur_date_id  --l_min_gtc_date_id and l_cur_date_id --
                and org.order_id = po.orig_order_id
              limit 1
            ) po_org on true
        where so.parent_order_id is not null -- street level
          and so.create_date_id = l_cur_date_id -- between 20190509 and 20190517 -- = 20190515 --l_cur_date_id
          --and so.ex_destination = 'W' -- CBOE -- a little bit slower than via exchange_id
          and so.exchange_id in (select ex.exchange_id from dwh.d_exchange ex where ex.real_exchange_id = 'CBOE' union select 'C1PAR' union select 'CBOEEH') -- быстрее
          and so.multileg_reporting_type in ('1','2')
          --and so.client_order_id in ('AAA0053-20190514','LAA2248-20190517','MTA2616-20190509','MTA3809-20190509','MTA2333-20190513', 'MTA2355-20190513', 'MTA3079-20190510', 'MTA3086-20190510')
        group by so.create_date_id, so.client_order_id, so.order_id, so.fix_message_id, po.client_order_id, so.parent_order_id, po.fix_message_id, po.create_date_id
          , so.orig_order_id, so_org.client_order_id, po_org.client_order_id
          , so.multileg_reporting_type, cl.client_src_id, ac.account_name, so.instrument_id
      )
    select str.create_date_id --count(1) -- 131309
      , sef.message_type
      , coalesce(sef.exec_type, ser.exec_type) as exec_type -- in executions we have replacement of 1 and 2 into F
      , ser.order_status
      , str.client_order_id as street_client_order_id
      , coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id) as street_orig_client_order_id
      --, str.street_orig_client_order_id --, sef.street_orig_client_order_id

      , sef.street_order_id as street_order_id -- 37
      , coalesce(ser.exch_exec_id, sef.street_exec_id) as street_exec_id -- 17 ? why aren't they equal
      , coalesce(ser.secondary_order_id, sef.street_secondary_order_id) as street_secondary_order_id
      , sef.street_orig_exec_id as street_orig_exec_id -- 19

      , coalesce(sef.street_transact_time, ser.exec_time) as street_transact_time
      , sef.street_sending_time as street_sending_time
      , sef.street_routed_time as street_routed_time
      , sef.target_location_id as target_location_id -- it is only for orders reports sent to exchange
      , coalesce(str.client_src_id, sef.client_id) as client_id
      , sef.clearing_optional_data -- 9324

      , str.parent_client_order_id
      , per.exch_exec_id as parent_exec_id
      , str.parent_orig_client_order_id
      , per.secondary_order_id as parent_secondary_order_id
      , per.secondary_exch_exec_id as parent_secondary_exec_id


      -- additional information needed
      , str.parent_create_date_id
      , sef.street_instrument_type
      , row_number() over (partition by str.client_order_id, ser.exch_exec_id, coalesce(sef.account_name, str.account_name) order by str.order_id) as rn1 -- need only one order record for multileg
      , row_number() over (partition by str.create_date_id, sef.message_type, str.client_order_id, sef.street_order_id, coalesce(ser.exch_exec_id, sef.street_exec_id), coalesce(sef.account_name, str.account_name), str.instrument_id order by str.order_id) as rn2 -- deduplication when we have (43) PossDupFlag = 'Y' (BAA0002-20181002)
      , coalesce(sef.account_name, str.account_name) as street_account_name

      -- requested by John
      , sef.fix_tag_115 as on_behalf_of_comp_id
      , sef.fix_tag_423 as price_type
      , sef.fix_tag_18 as exec_inst

      /*, sef.client_order
      , str.fix_message_id
      , str.order_id
      , str.multileg_reporting_type
      , str.parent_order_id
      --, ser.* --exec_id
      , per.* */

    from
      (
        select str.order_id -- for executions -> reports lookup
          , str.parent_order_id  -- for executions -> reports of parent orders lookup
          , null::bigint as fix_message_id        -- for orders messages lookup
          , null::bigint as parent_fix_message_id -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_src_id
          , str.parent_client_order_id
          , null as parent_orig_client_order_id
          , null as parent_create_date_id
          , str.account_name
          , str.instrument_id
        from str_ord  str -- the list of street orders
        union all
        select distinct null::bigint as order_id -- for executions -> reports lookup
          , null::bigint as parent_order_id     -- for executions -> reports of parent orders lookup
          , str.fix_message_id         -- for orders messages lookup
          , str.parent_fix_message_id  -- for parent orders messages direct lookup
          , str.create_date_id
          , str.client_order_id
          , str.street_orig_client_order_id
          , str.multileg_reporting_type
          , str.client_src_id
          , str.parent_client_order_id
          , str.parent_orig_client_order_id
          , str.parent_create_date_id
          , str.account_name
          , null::bigint as instrument_id
        from str_ord  str -- the list of street orders
      ) str -- the list of street orders plus their orders fix message ids
      left join lateral
      (
        select -- for return
            e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- for join
          , e.fix_message_id, e.exec_id, e.order_id, e.text_
          --, e.*
        from dwh.execution e
        where 1=1
          and e.fix_message_id is not null -- if it is null then there is possibility that execution is syntethic generated
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.order_id -- in (1679652736,1679652738,1679652740,1679660660,1679660663,1679660666) --
          and e.exec_type not in ('4', 'A', 'b')
          --and not exists (select 1 from fix_capture.fix_message_json j where j.date_id = 20190513 and j.fix_message_id = e.fix_message_id and ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' ))
          --and e.order_id = 1679652736 -- in (1679652736,1679652738,1679652740) -- (1674593569, 1674593570, 1674593571) --
      ) ser on true -- street executions reports from exchange
      inner join lateral
      (
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = ser.fix_message_id -- coalesce(ser.fix_message_id, fix_message_id) --in (3914795705, 3914778052) -- message for street report and not orders
          -- try to exclude multileg reports except rejects
          --and not ( (j.fix_message->>'167')::varchar = 'MLEG' and (j.fix_message->>'150')::varchar <> '8' )
        union
        select j.fix_message->>'35' as message_type
          , j.fix_message->>'150' as exec_type
          , j.fix_message->>'11' as client_order
          , j.fix_message->>'41' as street_orig_client_order_id
          , to_timestamp(j.fix_message->>'60', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_transact_time -- order_creation_time - вообще это креэйшен тайм
          , to_timestamp(j.fix_message->>'52', 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC' as street_sending_time -- вообще это служебное поле
          , coalesce(to_timestamp((j.fix_message->>'5050')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC', to_timestamp((j.fix_message->>'5051')::varchar, 'YYYYMMDD-HH24:MI:SS.US' )::timestamp at time zone 'UTC') as street_routed_time -- а вот это как раз транзакт тайм
          , j.fix_message->>'143' as target_location_id -- will be filled for order message sent to exchange
          , j.fix_message->>'37' as street_order_id
          , j.fix_message->>'17' as street_exec_id -- почему-то не совпадает с exch_exec_id экзекьюшена
          , j.fix_message->>'198' as street_secondary_order_id
          , j.fix_message->>'19' as street_orig_exec_id
          , (j.fix_message->>'167')::varchar as street_instrument_type
          , j.fix_message->>'109' as client_id
          , j.fix_message->>'9324' as clearing_optional_data
          , j.fix_message->>'1' as account_name
          , j.fix_message->>'115' as fix_tag_115
          , j.fix_message->>'423' as fix_tag_423
          , j.fix_message->>'18' as fix_tag_18
        from fix_capture.fix_message_json j
        where 1=1
          and j.date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513
          and j.fix_message_id = str.fix_message_id ---  3914778051 --  in (3914795705, 3914778052) -- message for street order and not report
      ) sef on true -- street execution fix messages for reports from exchange
      left join lateral
      (
        select -- fields to return
            e.fix_message_id -- for return
          , e.order_status, e.exec_type, e.exec_time, e.exch_exec_id, e.secondary_exch_exec_id, e.secondary_order_id
          -- other fields
          , e.fix_message_id, e.exec_id, e.order_id, e.text_
          --, e.*
        from dwh.execution e
        where 1=1
          and e.exec_date_id = l_cur_date_id -- between 20190509 and 20190517 --= 20190513 -- 20190509 --
          and e.order_id = str.parent_order_id -- (1674593565, 1674593567)  two legs with their own parents
          -- get rid of multileg message
          and (e.secondary_order_id is not null or e.order_status = '0')
          -- status matching
          and
            (
              e.secondary_exch_exec_id = ser.exch_exec_id
              or
              (e.order_status = '0' and ser.order_status = '0')
            )
        order by e.secondary_order_id desc nulls last, e.exec_time desc -- in case of presence both mleg and opt order executions for order with status = '0'
        limit 1
      ) per on true -- parent execution reports from exchange
 -- order by coalesce(str.street_orig_client_order_id, sef.street_orig_client_order_id, str.client_order_id), sef.street_routed_time

    ) src
  where 1=1 and (case when src.street_instrument_type = 'MLEG' then src.rn1 else 1 end = 1) and src.rn2 = 1
  --order by coalesce(src.street_orig_client_order_id, src.street_client_order_id), src.street_routed_time
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'Load into external_data.f_cboe_street_executions ', l_row_cnt , 'I')
     into l_step_id;


  --> update GTC parent orders data
/*    update external_data.f_cboe_street_executions trg
      set parent_orig_client_order_id = src.parent_orig_client_order_id
        , parent_routed_time = src.parent_routed_time
        , parent_message_type = src.parent_message_type
    from
      (
        select to_timestamp(to_char(o.process_time, 'YYYY-MM-DD HH24:MI:SS')::varchar||'.'||o.process_time_micsec, 'YYYY-MM-DD HH24:MI:SS.US')::timestamp without time zone as parent_routed_time
          , oo.client_order_id as parent_orig_client_order_id
          , o.trans_type as parent_message_type
          , o.client_order_id as parent_client_order_id
          , o.create_date_id as parent_create_date_id
          , s.street_client_order_id
          , s.create_date_id
          , row_number() over (partition by s.street_client_order_id, o.client_order_id, o.create_date_id order by o.process_time) as rn
        from external_data.f_cboe_street_executions s
          inner join dwh.client_order o -- parent order
            on o.create_date_id between l_min_gtc_date_id and l_cur_date_id
            and o.client_order_id = s.parent_client_order_id
            and o.create_date_id = s.parent_create_date_id
            and o.multileg_reporting_type in ('1','3')
          left join dwh.client_order oo
            on o.orig_order_id = oo.order_id
        where s.create_date_id = l_cur_date_id
          and s.parent_create_date_id is not null
          and s.parent_routed_time is null
      ) src
    where trg.create_date_id = l_cur_date_id
      and trg.create_date_id = src.create_date_id
      and trg.parent_create_date_id is not null -- message type not in (8,9)
      and trg.parent_routed_time is null
      and trg.street_client_order_id = src.street_client_order_id
      and trg.parent_client_order_id = src.parent_client_order_id
      and src.rn = 1 -- it is not needed, but just in case
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'UPD of GTC parent orders data ', l_row_cnt , 'U')
     into l_step_id;

 END IF; */
---------------------------------------------------------------------------------------------------------
  select public.load_log(l_load_id, l_step_id, 'p_load_f_cboe_street_executions_daily COMPLETE ========= ' , 0, 'O')
   into l_step_id;
  RETURN 1;

exception when others then
  select public.load_log(l_load_id, l_step_id, sqlerrm , 0, 'E')
  into l_step_id;
  -- PERFORM public.load_error_log('p_load_f_cboe_street_executions_daily',  'I', sqlerrm, l_load_id);

  RAISE;

END;
$$;




CREATE FUNCTION staging.tlnd_load_execution_old(in_l_seq integer, in_date_id_list character varying, in_step integer, in_table_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
 	date_id_crs cursor for select distinct exec_date_id from staging.tlnd_temp_execution  where rtrim(operation)='I';
	l_sql_block text;
	l_sql text;
	l_date_id int;
	l_in_l_seq int;
	l_in_date_id_list text;
	l_in_step int;
	l_in_table_name text;
	e1_step int;
	date_id_crs_up cursor for select distinct exec_date_id from staging.tlnd_temp_execution where rtrim(operation)='UN';
	l_exec_analyze text;
	interval_rez int;
	neighbourhood int;
	last_partition_name text;
 begin
	e1_step :=0;
	l_in_l_seq:= in_l_seq;
	l_in_step:= in_step;
	l_in_date_id_list:= in_date_id_list;
	l_in_table_name:= in_table_name;

	l_sql_block := 'INSERT INTO  partitions.execution_&p_month_id
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id
				 FROM staging.tlnd_temp_execution
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
			on conflict (exec_id) do update
   set exec_date_id = coalesce(public.f_insert_etl_reject(''load_temp_execution''::varchar,''execution_202101_exec_id_exec_date_id_idx'',''(exec_date_id= ''||EXCLUDED.exec_date_id||'',exec_id= ''||EXCLUDED.exec_id||'',exec_time = ''||EXCLUDED.exec_time||'')''::varchar),
   EXCLUDED.exec_date_id);';

	analyze staging.tlnd_temp_execution;

	open date_id_crs;

	loop
	fetch date_id_crs into l_date_id;
	exit when not found;

		l_sql := replace (l_sql_block ,'&p_month_id', substring(l_date_id::text,1,6));
		l_sql := replace (l_sql ,'&p_date_id', l_date_id::text);

	EXECUTE l_sql;

		select public.load_log(
							l_in_l_seq,
							l_in_step,
							l_in_table_name::text,
						coalesce ((select count(1) from staging.tlnd_temp_execution where rtrim(operation)='I' and exec_date_id = l_date_id),0)::int,
						'I'::text
						) into e1_step
					;

	end loop;

	close date_id_crs;

--	l_exec_analyze:= 'analyze partitions.execution_'||left(right(l_in_date_id_list, 8), 6);
--	execute l_exec_analyze;

	neighbourhood:= 3600; --60 min
	last_partition_name:= 'select execution_'||left(right(l_in_date_id_list, 8), 6); --extract last date from date_id_list in format YYYYMM

	select abs(date_part('epoch'::text, clock_timestamp() AT TIME ZONE 'US/Eastern'
										- (clock_timestamp()::date::timestamp AT TIME ZONE 'US/Eastern' + interval '8 hours 15 minutes') --8:15 AM current date
						)
				) into interval_rez;
	--analyze only between 7:15 and 9:15
	if (interval_rez < neighbourhood) then
		perform  dwh.analyse_statistics (in_schema_name => 'partitions', in_table_name => last_partition_name, in_max_interval => 600);
	end if;

			UPDATE dwh.execution ex
				SET
				secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
				secondary_order_id= EXCLUDED.secondary_order_id,
				trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
				avg_px= EXCLUDED.avg_px,
				bust_qty= EXCLUDED.bust_qty,
				contra_account_capacity= EXCLUDED.contra_account_capacity,
				contra_broker= EXCLUDED.contra_broker,
				cum_qty= EXCLUDED.cum_qty,
				exch_exec_id= EXCLUDED.exch_exec_id,
				exec_time= EXCLUDED.exec_time,
				exec_type= EXCLUDED.exec_type,
				exec_date_id= EXCLUDED.exec_date_id,
				fix_message_id= EXCLUDED.fix_message_id,
				account_id= EXCLUDED.account_id,
				is_billed= EXCLUDED.is_billed,
				is_busted= EXCLUDED.is_busted,
				last_mkt= EXCLUDED.last_mkt,
				last_px= EXCLUDED.last_px,
				last_qty= EXCLUDED.last_qty,
				leaves_qty= EXCLUDED.leaves_qty,
				order_id= EXCLUDED.order_id,
				order_status= EXCLUDED.order_status,
				text_=EXCLUDED.text_ ,
				is_parent_level = EXCLUDED.is_parent_level,
				exec_broker=EXCLUDED.exec_broker,
				dataset_id = EXCLUDED.dataset_id,
				auction_id = EXCLUDED.auction_id,
				match_qty = EXCLUDED.match_qty,
				match_px = EXCLUDED.match_px,
				internal_component_type = EXCLUDED.internal_component_type,
				exchange_id = EXCLUDED.exchange_id,
				contra_trader = EXCLUDED.contra_trader,
				ref_exec_id = EXCLUDED.ref_exec_id
			FROM  staging.tlnd_temp_execution  EXCLUDED
				WHERE  ex.exec_id = EXCLUDED.exec_id
				and ex.exec_date_id = EXCLUDED.exec_date_id
				and EXCLUDED.operation='UN'
				and ex.exec_date_id in(SELECT c::int FROM regexp_split_to_table((select l_in_date_id_list),',') as c);

		select public.load_log(
							l_in_l_seq,
							e1_step,
							l_in_table_name::text,
						coalesce ((select count(1) from staging.tlnd_temp_execution where rtrim(operation)= 'UN'),0)::int,
							'U'::text)
						into e1_step
					;
	RETURN e1_step;

 end;
$$;



CREATE FUNCTION staging.tlnd_load_execution_test(in_l_seq bigint, in_step integer, in_table_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
 	date_id_crs refcursor; --for select distinct exec_date_id from staging.tlnd_temp_execution  where rtrim(operation)='I';
	l_sql_block text;
	l_sql text;
	l_date_id int;
	l_in_l_seq bigint;
	l_in_date_id_list text;
	l_step_id int;
	l_in_table_name text;
	e1_step int;
	date_id_crs_up refcursor;-- for select distinct exec_date_id from staging.tlnd_temp_execution where rtrim(operation)='UN';
	l_exec_analyze text;
	interval_rez int;
	neighbourhood int;
	last_partition_name text;
	l_sql_block2 text;
	l_row_count int;
	l_max_pg_exec_id bigint;
	l_max_ora_exec_id bigint;
 begin
	--l_step_id :=0;
	l_in_l_seq:= in_l_seq + 1;
	l_step_id:= in_step;


	select public.load_log(l_in_l_seq,l_step_id,'staging.tlnd_load_execution_test STARTED >>>>>>>>'::text,0 ,'S'::text)
	into l_step_id
			;


	l_sql:= 'select string_agg(exec_date_id::varchar,'','')
				from(select distinct exec_date_id
						from staging.tlnd_execution_'||in_l_seq::varchar||'
							where operation =''UN''
					)t ;';

	EXECUTE l_sql
	into l_in_date_id_list;



	l_in_table_name:= in_table_name;

	l_sql_block := 'INSERT INTO  partitions.execution_&p_month_id
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt
				 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt > 1
			on conflict (exec_id) do update
   set exec_date_id = coalesce(public.f_insert_etl_reject(''load_temp_execution''::varchar,''execution_202101_exec_id_exec_date_id_idx'',''(exec_date_id= ''||EXCLUDED.exec_date_id||'',exec_id= ''||EXCLUDED.exec_id||'',exec_time = ''||EXCLUDED.exec_time||'')''::varchar),
   EXCLUDED.exec_date_id),
		secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
		secondary_order_id= EXCLUDED.secondary_order_id,
		trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
		avg_px= EXCLUDED.avg_px,
		bust_qty= EXCLUDED.bust_qty,
		contra_account_capacity= EXCLUDED.contra_account_capacity,
		contra_broker= EXCLUDED.contra_broker,
		cum_qty= EXCLUDED.cum_qty,
		exch_exec_id= EXCLUDED.exch_exec_id,
		exec_time= EXCLUDED.exec_time,
		exec_type= EXCLUDED.exec_type,
		fix_message_id= EXCLUDED.fix_message_id,
		account_id= EXCLUDED.account_id,
		is_billed= EXCLUDED.is_billed,
		is_busted= EXCLUDED.is_busted,
		last_mkt= EXCLUDED.last_mkt,
		last_px= EXCLUDED.last_px,
		last_qty= EXCLUDED.last_qty,
		leaves_qty= EXCLUDED.leaves_qty,
		order_id= EXCLUDED.order_id,
		order_status= EXCLUDED.order_status,
		text_=EXCLUDED.text_ ,
		is_parent_level = EXCLUDED.is_parent_level,
		exec_broker=EXCLUDED.exec_broker,
		dataset_id = EXCLUDED.dataset_id,
		auction_id = EXCLUDED.auction_id,
		match_qty = EXCLUDED.match_qty,
		match_px = EXCLUDED.match_px,
		internal_component_type = EXCLUDED.internal_component_type,
		exchange_id = EXCLUDED.exchange_id,
		contra_trader = EXCLUDED.contra_trader,
		ref_exec_id = EXCLUDED.ref_exec_id;';


l_sql_block2 := 'INSERT INTO  partitions.execution_&p_month_id
											(exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt)
				 SELECT exec_id, order_id, order_status, exec_type, exec_date_id, exec_time, is_billed, is_busted, leaves_qty, cum_qty,
													avg_px, last_qty, last_px, bust_qty, dataset_id, last_mkt, contra_broker, secondary_order_id, exch_exec_id,
													secondary_exch_exec_id, contra_account_capacity, trade_liquidity_indicator, account_id, fix_message_id,
													text_, is_parent_level, exec_broker, auction_id, match_qty, match_px, internal_component_type, exchange_id, contra_trader,ref_exec_id,cnt
				 FROM staging.tlnd_execution_'||in_l_seq::varchar||'
				 WHERE rtrim(operation)=''I'' and exec_date_id = &p_date_id
				 and cnt = 1
			on conflict (exec_id) do nothing;';

	raise INFO 'SQL prepared';
	--analyze staging.tlnd_temp_execution;

	execute 'analyze staging.tlnd_execution_'||in_l_seq::varchar||';';
	raise INFO '%: analyze DONE', clock_timestamp() ;

	open date_id_crs for execute format('select distinct exec_date_id from staging.tlnd_execution_%s  where rtrim(operation)=''I'';',in_l_seq::varchar);
	loop
	fetch date_id_crs into l_date_id;
	exit when not found;

		l_sql := replace (l_sql_block ,'&p_month_id', substring(l_date_id::text,1,6));
		l_sql := replace (l_sql ,'&p_date_id', l_date_id::text);

	raise INFO '%: executing INSERT %', clock_timestamp() , l_date_id;
	EXECUTE l_sql;

	GET diagnostics l_row_count= ROW_COUNT;

 			select public.load_log(
								l_in_l_seq,
								l_step_id,
								l_in_table_name::text,
						COALESCE( l_row_count, 0)::int ,
					'M'::text
				) into l_step_id
			;
	raise INFO '%: DONE INSERT %', clock_timestamp() , l_date_id;


		l_sql := replace (l_sql_block2 ,'&p_month_id', substring(l_date_id::text,1,6));
		l_sql := replace (l_sql ,'&p_date_id', l_date_id::text);

	raise INFO '%: executing INSERT2 %', clock_timestamp() , l_date_id;
	EXECUTE l_sql;
	raise INFO '%: executing DONE %', clock_timestamp() , l_date_id;

	GET diagnostics l_row_count= ROW_COUNT;

		select public.load_log(
							l_in_l_seq,
							l_step_id,
							l_in_table_name::text,
						COALESCE( l_row_count, 0)::int ,
						'I'::text
						) into l_step_id
					;

	end loop;

	close date_id_crs;

--	l_exec_analyze:= 'analyze partitions.execution_'||left(right(l_in_date_id_list, 8), 6);
--	execute l_exec_analyze;

	neighbourhood:= 3600; --60 min
	last_partition_name:= 'select execution_'||left(right(l_in_date_id_list, 8), 6); --extract last date from date_id_list in format YYYYMM

	select abs(date_part('epoch'::text, clock_timestamp() AT TIME ZONE 'US/Eastern'
										- (clock_timestamp()::date::timestamp AT TIME ZONE 'US/Eastern' + interval '8 hours 15 minutes') --8:15 AM current date
						)
				) into interval_rez;
	--analyze only between 7:15 and 9:15
	if (interval_rez < neighbourhood) then
		perform  dwh.analyse_statistics (in_schema_name => 'partitions', in_table_name => last_partition_name, in_max_interval => 600);
	end if;

if l_in_date_id_list is not null
 then
execute 'UPDATE dwh.execution ex
				SET
				secondary_exch_exec_id= EXCLUDED.secondary_exch_exec_id,
				secondary_order_id= EXCLUDED.secondary_order_id,
				trade_liquidity_indicator= EXCLUDED.trade_liquidity_indicator,
				avg_px= EXCLUDED.avg_px,
				bust_qty= EXCLUDED.bust_qty,
				contra_account_capacity= EXCLUDED.contra_account_capacity,
				contra_broker= EXCLUDED.contra_broker,
				cum_qty= EXCLUDED.cum_qty,
				exch_exec_id= EXCLUDED.exch_exec_id,
				exec_time= EXCLUDED.exec_time,
				exec_type= EXCLUDED.exec_type,
				exec_date_id= EXCLUDED.exec_date_id,
				fix_message_id= EXCLUDED.fix_message_id,
				account_id= EXCLUDED.account_id,
				is_billed= EXCLUDED.is_billed,
				is_busted= EXCLUDED.is_busted,
				last_mkt= EXCLUDED.last_mkt,
				last_px= EXCLUDED.last_px,
				last_qty= EXCLUDED.last_qty,
				leaves_qty= EXCLUDED.leaves_qty,
				order_id= EXCLUDED.order_id,
				order_status= EXCLUDED.order_status,
				text_=EXCLUDED.text_ ,
				is_parent_level = EXCLUDED.is_parent_level,
				exec_broker=EXCLUDED.exec_broker,
				dataset_id = EXCLUDED.dataset_id,
				auction_id = EXCLUDED.auction_id,
				match_qty = EXCLUDED.match_qty,
				match_px = EXCLUDED.match_px,
				internal_component_type = EXCLUDED.internal_component_type,
				exchange_id = EXCLUDED.exchange_id,
				contra_trader = EXCLUDED.contra_trader,
				ref_exec_id = EXCLUDED.ref_exec_id
			FROM  staging.tlnd_execution_'||in_l_seq::varchar||'  EXCLUDED
				WHERE  ex.exec_id = EXCLUDED.exec_id
				and ex.exec_date_id = EXCLUDED.exec_date_id
				and EXCLUDED.operation=''UN''
				and ex.exec_date_id in('||l_in_date_id_list||')';

	GET diagnostics l_row_count= ROW_COUNT;

	select public.load_log(
						l_in_l_seq,
						l_step_id,
						l_in_table_name::text,
						coalesce (l_row_count,0)::int,
							'U'::text)
						into l_step_id
					;
end if;



 --==========================================================================================================
	--======================= p_upd_fact_last_load_time part removed from ETL ==================================
	--==========================================================================================================

	PERFORM dwh.p_upd_fact_last_load_time('execution');

	select public.load_log(l_in_l_seq,l_step_id,'p_upd_fact_last_load_time finished ', 0,'F')
		into l_step_id;

	--==========================================================================================================
	--================= Update of Oracle table removed from ETL ================================================
	--==========================================================================================================

	select  last_loaded_id
		into l_max_pg_exec_id
	from staging.tlnd_inc_last_loaded_id tilli
		where table_name ='execution'
	;

	--select * from staging.last_loaded_id;


	update staging.last_loaded_id
		set MAX_PG_ID = greatest(l_max_pg_exec_id, MAX_PG_ID)
	where table_name = 'EXECUTION'
	;

	select public.load_log(l_in_l_seq,l_step_id,'updated MAX_PG_ID in staging.last_loaded_id ', 0,'F')
		into l_step_id;

	--==========================================================================================================
	--================= Update of PG table removed from ETL ====================================================
	--==========================================================================================================

	select max_ora_id
	into l_max_ora_exec_id
	from staging.last_loaded_id lli
	where table_name = 'EXECUTION'
	;

	update staging.tlnd_inc_last_loaded_id
		set last_loaded_id = greatest(l_max_ora_exec_id , last_loaded_id)
	where table_name = 'execution'
	;

	select public.load_log(l_in_l_seq,l_step_id,'updated last_loaded_id in staging.tlnd_inc_last_loaded_id', 0,'F')
		into l_step_id;


	execute 'select count(distinct exec_id) from staging.tlnd_execution_'||in_l_seq::varchar /*where rtrim(operation)=''I'' and cnt > 1*/
	into l_row_count;

	raise notice ' l_row_count = %', l_row_count;

	perform  public.etl_subscribe(l_in_l_seq, 'yield_capture', 'execution', l_in_date_id_list::varchar,coalesce(l_row_count,0)::int ) ;

	--execute 'drop table if exists staging.tlnd_execution_'||in_l_seq::varchar;


	select public.load_log(l_in_l_seq,l_step_id,'staging.tlnd_load_execution_test FINISHED >>>>>>>>'::text,0 ,'S'::text)
	into l_step_id
			;

	RETURN l_step_id;

 end;
$$;


CREATE FUNCTION trash.ak_eod_reports_export_rbc_orders_tbl(in_start_date_id integer DEFAULT NULL::integer, in_end_date_id integer DEFAULT NULL::integer, in_client_ids character varying[] DEFAULT '{}'::character varying[]) RETURNS TABLE("Account" character varying, "Is Cross" character varying, "Is MLeg" character varying, "Ord Status" character varying, "Event Type" character varying, "Routed Time" character varying, "Event Time" character varying, "Cl Ord ID" character varying, "Side" character varying, "Symbol" character varying, "Ord Qty" bigint, "Price" numeric, "Ex Qty" bigint, "Avg Px" numeric, "Sub Strategy" character varying, "Ex Dest" character varying, "Ord Type" character varying, "TIF" character varying, "Sending Firm" character varying, "Capacity" character varying, "Client ID" character varying, "CMTA" character varying, "Creation Date" character varying, "Cross Ord Type" character varying, "Event Date" character varying, "Exec Broker" character varying, "Expiration Day" date, "Leg ID" character varying, "Lvs Qty" bigint, "O/C" character varying, "Orig Cl Ord ID" character varying, "OSI Symbol" character varying, "Root Symbol" character varying, "Security Type" character varying, "Stop Px" numeric, "Underlying Symbol" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE

   l_row_cnt integer;
   l_load_id integer;
   l_step_id integer;

  l_start_date_id integer;
  l_end_date_id   integer;

  l_gtc_start_date_id integer;
BEGIN

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id := 1;

  raise notice 'l_load_id=%',l_load_id;

  select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl STARTED===', 0, 'O')
   into l_step_id;

  if in_start_date_id is not null and in_end_date_id is not null
  then
    l_start_date_id := in_start_date_id;
    l_end_date_id := in_end_date_id;
  else
    --l_start_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    --l_end_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    l_start_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
    l_end_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;

  end if;

  --l_start_date_id := coalesce(in_date_id, (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer);

  l_gtc_start_date_id := to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD')::date - interval '6 month'), 'YYYYMMDD');

    select public.load_log(l_load_id, l_step_id, 'Step 1. l_start_date_id = '||l_start_date_id::varchar||', l_end_date_id = '||l_end_date_id::varchar||', l_gtc_start_date_id = '||l_gtc_start_date_id::varchar, 0 , 'O')
     into l_step_id;

  return QUERY
/*  with par_ords as
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      ) */
    select --po.order_id
        ac.account_name as "Account"
      , (case when po.cross_order_id is not null then 'Y' else 'N' end)::varchar as "Is Cross"
      , (case when po.multileg_reporting_type = '1' then 'N' else 'Y' end)::varchar as "Is MLeg"
      , st.order_status_description as "Ord Status"
      , et.exec_type_description as "Event Type"
      , to_char(fyc.routed_time, 'HH24:MI:SS.US')::varchar as "Routed Time"
      --, to_char(po.process_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , to_char(fyc.exec_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , po.client_order_id as "Cl Ord ID"
      , (case po.side
                  when '1' then 'Buy'
                  when '2' then 'Sell'
                  when '3' then 'Buy minus'
                  when '4' then 'Sell plus'
                  when '5' then 'Sell short'
                  when '6' then 'Sell short exempt'
                  when '7' then 'Undisclosed'
                  when '8' then 'Cross'
                  when '9' then 'Cross short'
                end)::varchar as "Side"
      , i.display_instrument_id as "Symbol"
      , po.order_qty::bigint as "Ord Qty"
      , po.price as "Price"
      , fyc.filled_qty as "Ex Qty"
      , fyc.avg_px as "Avg Px"
      , ss.target_strategy_desc as "Sub Strategy"
      , dc.ex_destination_code_name as "Ex Dest"
      , ot.order_type_name as "Ord Type"
      , tif.tif_name as "TIF"
      , f.fix_comp_id as "Sending Firm"
      , cf.customer_or_firm_name as "Capacity"
      , po.client_id_text as "Client ID"
      , coalesce(po.clearing_firm_id, fx_co.clearing_firm_id) as "CMTA"
      , to_char(to_date(po.create_date_id::varchar, 'YYYYMMDD'), 'DD.MM.YYYY')::varchar as "Creation Date"
      , cro.cross_type::varchar as "Cross Ord Type"
      , to_char(fyc.exec_time, 'DD.MM.YYYY')::varchar as "Event Date"
      , ebr.opt_exec_broker as "Exec Broker"
      , date_trunc('day', i.last_trade_date)::date as "Expiration Day"
      , l.client_leg_ref_id as "Leg ID"
      , ex.leaves_qty::bigint as "Lvs Qty"
      , (case when po.open_close = 'O' then 'Open' else 'Close' end)::varchar as "O/C"
      , oo.client_order_id as "Orig Cl Ord ID"
      , po.opra_symbol as "OSI Symbol"
      , po.root_symbol as "Root Symbol"
      , it.instrument_type_name as "Security Type"
      , po.stop_price as "Stop Px"
      , ui.display_instrument_id as "Underlying Symbol"
      --, po.*
--select count(1)
    from
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
          and case in_client_ids
  					when '{}'::varchar[]
  						then true
  			else co.client_id_text = any(in_client_ids)
  	  	end
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      )  scp
      left join lateral
      (
        select po.order_id
          , po.orig_order_id
          , po.account_id
          , po.multileg_reporting_type
          , po.multileg_order_id
          , po.cross_order_id
          , po.create_date_id
          , po.client_order_id
          , po.instrument_id
          , po.order_qty
          , po.price
          , po.side
          , po.sub_strategy_id
          , po.ex_destination_code_id
          , po.ex_destination
          , po.order_type_id
          , po.time_in_force_id
          , po.customer_or_firm_id
          , po.order_capacity_id
          , po.client_id_text
          , po.process_time
          , po.opt_exec_broker_id
          , po.no_legs
          , po.open_close
          , po.fix_connection_id
          , po.clearing_firm_id
          , po.fix_message_id
          , po.stop_price
          , po.trans_type
          , oc.option_series_id
          , oc.opra_symbol
          , os.underlying_instrument_id
          , os.root_symbol
          --, po.*
        from dwh.client_order po
        left join dwh.d_option_contract oc
          ON po.instrument_id = oc.instrument_id
        left join dwh.d_option_series os
          --ON oc.option_series_id = os.option_series_id
          ON oc.option_series_id = os.option_series_id
        where 1=1
          and po.create_date_id between l_gtc_start_date_id and l_end_date_id -- last half of year. GTC purpose
          and po.order_id = scp.order_id
        limit 1 -- for NL acceleration
      ) po ON true
      left join dwh.client_order oo
        ON po.orig_order_id = oo.order_id
        and oo.create_date_id between l_gtc_start_date_id and l_end_date_id
      left join dwh.d_account ac
        ON po.account_id = ac.account_id
      left join lateral
        (
           select sum(fyc.day_cum_qty) as filled_qty
             , round(sum(fyc.day_avg_px*fyc.day_cum_qty)/nullif(sum(fyc.day_cum_qty), 0)::numeric, 4)::numeric as avg_px
             , min(fyc.routed_time) as routed_time
             , max(fyc.exec_time) as exec_time -- can it be event_time or transact time? min or max?
             , fyc.order_id
             , min(fyc.nbbo_bid_price) as nbbo_bid_price
             , min(fyc.nbbo_bid_quantity) as nbbo_bid_quantity
             , min(fyc.nbbo_ask_price) as nbbo_ask_price
             , min(fyc.nbbo_ask_quantity) as nbbo_ask_quantity
           from data_marts.f_yield_capture fyc -- here we have all orders, so we can use it for cum_qty calculation (instead of FTR)
           where fyc.order_id = po.order_id
             and fyc.status_date_id between l_gtc_start_date_id and l_end_date_id
           group by fyc.order_id
           limit 1 -- just in case to insure NL join method
        ) fyc on true
      -- the last execution
      left join lateral
        (
          select ex.text_
            , ex.order_status
            , ex.exec_type
            , ex.exec_id
            , ex.leaves_qty
          from dwh.execution ex
          where 1=1
            --and ex.exec_date_id = 20190604
            and ex.exec_date_id between l_start_date_id and l_end_date_id
            and ex.order_id = po.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      -- fix_message of order
      left join lateral
        (
          select (j.fix_message->>'439')::varchar as clearing_firm_id
          from fix_capture.fix_message_json j
          where 1=1
            and po.clearing_firm_id is null --
            and j.date_id between l_start_date_id and l_end_date_id -- l_gtc_start_date_id was very slow condition
            and j.fix_message_id = po.fix_message_id
            and j.date_id = po.create_date_id
          limit 1
        ) fx_co on true
      left join dwh.d_order_status st
        ON ex.order_status = st.order_status
      left join dwh.d_exec_type et
        ON ex.exec_type = et.exec_type
      left join dwh.d_instrument i
        ON po.instrument_id = i.instrument_id
      left join dwh.d_instrument_type it
        ON i.instrument_type_id = it.instrument_type_id
      left join dwh.d_instrument ui
        --ON os.underlying_instrument_id = ui.instrument_id
        ON po.underlying_instrument_id = ui.instrument_id
      left join dwh.d_target_strategy ss
        ON po.sub_strategy_id = ss.target_strategy_id
      left join dwh.d_ex_destination_code dc
        ON po.ex_destination = dc.ex_destination_code
      left join dwh.d_order_type ot
        ON po.order_type_id = ot.order_type_id
      left join dwh.d_time_in_force tif
        ON po.time_in_force_id = tif.tif_id
    /*  left join --lateral
        (
          select ---min(ecf.customer_or_firm_id) as customer_or_firm_id
            ecf.customer_or_firm_id
            , ecf.exch_customer_or_firm_id, ecf.exchange_id  -- lookup key
            , row_number() over (partition by ecf.exch_customer_or_firm_id, ecf.exchange_id order by ecf.customer_or_firm_id) as rn
          from dwh.d_exchange2customer_or_firm ecf
        ) ecf
        ON ecf.rn = 1 --true
          and o.customer_or_firm is null
          and ecf.exch_customer_or_firm_id = o.order_capacity
          and ecf.exchange_id = o.exchange_id */
      left join dwh.d_customer_or_firm cf ON cf.customer_or_firm_id = COALESCE(po.customer_or_firm_id, ac.opt_customer_or_firm) and cf.is_active = true -- ecf.customer_or_firm_id,
      left join dwh.cross_order cro
        ON po.cross_order_id = cro.cross_order_id
      left join dwh.d_opt_exec_broker ebr
        ON po.opt_exec_broker_id = ebr.opt_exec_broker_id
      left join dwh.d_fix_connection f
        ON po.fix_connection_id = f.fix_connection_id
      /*left join dwh.client_order_leg l
        ON l.order_id = po.order_id
        and l.multileg_order_id = po.multileg_order_id*/
      left join lateral
        (
          select l.order_id, l.client_leg_ref_id
          from dwh.client_order_leg l
          where l.multileg_order_id = po.multileg_order_id
          limit 3000
        ) l ON l.order_id = po.order_id
    where po.trans_type <> 'F' -- not cancell request
    order by po.process_time, 1;


    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

 select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl COMPLETE ========= ' , l_row_cnt, 'O')
   into l_step_id;
   RETURN;
END;
$$;




CREATE FUNCTION trash.pd_generate_non_gth_hods(in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
--Initially created by - PD https://dashfinancial.atlassian.net/browse/DS-4817
    l_date_id int8;
    l_row_cnt int;
begin

with cte as(
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
   (CASE
      WHEN CO.MULTILEG_REPORTING_TYPE = '3'
      THEN 'M'
      ELSE HSD.instrument_type_id
   end)::char(1) as "InstrumentType",
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
    ) "LogTime",*/
   CO.PROCESS_TIME as "RoutedTime",
   CO.order_type_id as "OrderType",
   CO.SIDE as "Side",
   CO.ORDER_QTY as "OrderQty",
   CO.PRICE as "Price",
   CO.STOP_PRICE as "StopPx",
   CO.time_in_force_id as "TimeInForce",
   CO.EXPIRE_TIME as "ExpireTime",
   CO.OPEN_CLOSE::char(1) as "OpenClose",
   CO.EX_DESTINATION as "ExDestination",
   CO.HANDL_INST::char(1) as "HandlInst",
   --CO.EXEC_INST as "ExecInst",
   CO.MAX_SHOW_QTY as "MaxShowQty",
   CO.MAX_FLOOR as "MaxFloorQty",
   CASE
      WHEN CO.PARENT_ORDER_ID IS NULL
      THEN case
      		 when ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
      		 then CO.clearing_firm_id
      		 else null
      	   end
      ELSE CO.clearing_firm_id
    END "ClearingFirmID",
    CASE
      WHEN HSD.instrument_type_id = 'E'
      THEN NULL
      WHEN CO.PARENT_ORDER_ID IS NULL
      THEN case
      		 when ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
      		 then coalesce(doeb.opt_exec_broker , OPX.opt_exec_broker)
      		 else OPX.opt_exec_broker
      	   end
      ELSE doeb.opt_exec_broker
    END "ExecBroker",
    --we store value in CLIENT_ORDER for all cases
   (case
     when CO.PARENT_ORDER_ID is null
     then dcof.customer_or_firm_name
     else null
   end)::char(1) as "CustomerOrFirm",
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
   	 then EX.text_
   	 else null
   end as "RejectReason",
   EX.LEAVES_QTY as "LeavesQty",
     --EX.CUM_QTY "CumQty",
    (
    SELECT SUM(EO.LAST_QTY)
    FROM dwh.EXECUTION EO
    WHERE EO.ORDER_ID = EX.ORDER_ID
    and eo.exec_date_id = in_date_id
    AND EO.EXEC_TYPE IN ('F', 'G')
    AND EO.IS_BUSTED <> 'Y'
    AND EO.EXEC_ID   <= EX.EXEC_ID
    ) "CumQty",
    --EX.AVG_PX "AvgPx",
    (
    SELECT
      CASE
        WHEN SUM(EA.LAST_QTY) = 0
        THEN NULL
        ELSE SUM(EA.LAST_QTY*EA.LAST_PX)/nullif(SUM(EA.LAST_QTY),0)
      END
    FROM EXECUTION EA
    WHERE EA.ORDER_ID = EX.ORDER_ID
    and ea.exec_date_id = in_date_id
    AND EA.EXEC_TYPE IN ('F', 'G')
    AND EA.IS_BUSTED <> 'Y'
    AND EA.EXEC_ID   <= EX.EXEC_ID
    ) "AvgPx",
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
   EX.TRADE_LIQUIDITY_INDICATOR as "TradeLiquidityIndicator",
   CO.MULTILEG_REPORTING_TYPE::char(1) as "MultilegReportingType",
   COL.CLIENT_LEG_REF_ID as "LegRefID",
   COL.MULTILEG_ORDER_ID as "MultilegOrderID",
   FC.FIX_COMP_ID as "FixCompID", --sending firm
   CO.CLIENT_ID as "ClientID",
   EX.TEXT_ as "Text",
    (CASE
      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
      THEN 'Y'
      ELSE 'N'
    end)::char(1) "IsOSROrder",
	coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
   CO.sub_strategy_desc as "SubStrategy",
   CO.ALGO_STOP_PX as "AlgoStopPx",
   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
   CO.TRANS_TYPE as "TransType",
   CO.DASH_CLIENT_ORDER_ID as "DashClOrdID",
   CO.CROSS_ORDER_ID as "CrossOrderID",
   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
   dss.sub_system_name as "SubSystemID",
   CO.TRANSACTION_ID as "TransactionID",
   CO.TOT_NO_ORDERS_IN_TRANSACTION as "TotNoOrdersInTransaction",
   CO.EXCHANGE_ID as "ExchangeID",
   CO.FEE_SENSITIVITY as "FeeSensitivity",
   CO.ON_BEHALF_OF_SUB_ID as "OnBehalfOfSubID",
   CO.strtg_decision_reason_code as "StrategyDecisionReasonCode",
   CO.INTERNAL_ORDER_ID as "InternalOrderID",
   CO.ALGO_START_TIME as "AlgoStartTime",
   CO.ALGO_END_TIME as "AlgoEndTime",
   --CO.MIN_TARGET_QTY as "MinTargetQty",
   CO.EXTENDED_ORD_TYPE::char(1) as "ExtendedOrdType",
   CO.PRIM_LISTING_EXCHANGE as "PrimListingExchange",
   CO.POSTING_EXCHANGE as "PostingExchange",
   CO.PRE_OPEN_BEHAVIOR::char(1) as "PreOpenBehavior",
   CO.MAX_WAVE_QTY_PCT as "MaxWaveQtyPct",
   CO.SWEEP_STYLE::char(1) as "SweepStyle",
   CO.DISCRETION_OFFSET as "DiscretionOffset",
   CRO.CROSS_TYPE::char(1) as "CrossType",
   CO.AGGRESSION_LEVEL as "AggressionLevel",
   CO.HIDDEN_FLAG::char(1) as "HiddenFlag",
   CO.QUOTE_ID as "QuoteID",
   CO.STEP_UP_PRICE_TYPE::char(1) as "StepUpPriceType",
   CO.STEP_UP_PRICE as "StepUpPrice",
   CO.CROSS_ACCOUNT_ID as "CrossAccountID",
   AU."AuctionID" "AuctionID",
   CO.CLEARING_ACCOUNT as "ClearingAccount",
   CO.SUB_ACCOUNT as "SubAccount",
   CO.REQUEST_NUMBER as "RequestNumber",
   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",
   CO.COMPLIANCE_ID as "ComplianceID",
   CO.ALTERNATIVE_COMPLIANCE_ID as "AlternativeComplianceID",
   CO.CONDITIONAL_CLIENT_ORDER_ID "ConditionalClientOrderID",
   'N'::char(1) "IsConditionalOrder",
   CO.co_routing_table_entry_id  "RoutingTableEntryID",
   CO.MAX_VEGA_PER_STRIKE "MaxVegaPerStrike",
   CO.PER_STRIKE_VEGA_EXPOSURE "PerStrikeVegaExposure",
   CO.VEGA_BEHAVIOR "VegaBehavior",
   CO.DELTA_BEHAVIOR "DeltaBehavior",
   CO.HEDGE_PARAM_UNITS "HedgeParamUnits",
   CO.MIN_DELTA "MinDelta",
   AC.FIX_COMP_ID "FixCompID2",
   I.SYMBOL_SUFFIX "SymbolSfx",
   CO.PRODUCT_DESCRIPTION "ProductDescription",
   CO.SESSION_ELIGIBILITY::char(1) "SessionEligibility",
   CO.CREATE_DATE_ID "CreateDateID",
   EX.exec_date_id "TradeDateID",
   EX.exec_time::date as "TradeDate"
   FROM dwh.execution EX
   JOIN dwh.CLIENT_ORDER CO on EX.ORDER_ID = CO.ORDER_ID and ex.exec_date_id = co.create_date_id
   JOIN dwh.d_INSTRUMENT I ON I.INSTRUMENT_ID = CO.INSTRUMENT_ID
   LEFT JOIN dwh.HISTORIC_SECURITY_DEFINITION HSD on HSD.INSTRUMENT_ID = CO.INSTRUMENT_ID
   JOIN dwh.d_fix_connection FC on  FC.FIX_CONNECTION_ID = CO.FIX_CONNECTION_ID
   JOIN staging.ACCEPTOR AC ON AC.ACCEPTOR_ID = FC.ACCEPTOR_ID
   JOIN d_account ACC on CO.ACCOUNT_ID = ACC.ACCOUNT_ID
   LEFT JOIN dwh.d_opt_exec_broker OPX on OPX.ACCOUNT_ID = ACC.ACCOUNT_ID AND OPX.is_active = 'Y' AND OPX.is_default = 'Y'
   LEFT JOIN dwh.CLIENT_ORDER COORIG on CO.ORIG_ORDER_ID = COORIG.ORDER_ID and coorig.create_date_id = co.create_date_id
   LEFT JOIN dwh.client_order_leg COL on CO.ORDER_ID = COL.ORDER_ID
   left join dwh.d_order_type dot on dot.order_type_id = co.order_type_id
   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force_id and dtif.is_active
   left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = co.opt_exec_broker_id
   left join dwh.d_sub_system dss on dss.sub_system_unq_id = CO.sub_system_unq_id
   left join dwh.d_customer_or_firm dcof on dcof.customer_or_firm_id = CO.customer_or_firm_id
   LEFT JOIN dwh.cross_order CRO on CO.CROSS_ORDER_ID = CRO.CROSS_ORDER_ID
   LEFT join lateral
    (SELECT SUM(EQ.LAST_QTY) "DAY_CUM_QTY",
      EQ.ORDER_ID "ORDER_ID",
      EQ.EXEC_TIME::date "TRADE_DATE",
     SUM(EQ.LAST_QTY*EQ.LAST_PX)/nullif(SUM(EQ.LAST_QTY),0) "DAY_AVG_PX"
    FROM EXECUTION EQ
    WHERE EQ.EXEC_TYPE IN ('F', 'G')
    and eq.exec_date_id = in_date_id
    AND EQ.IS_BUSTED   <> 'Y'
    and EX.ORDER_ID = EQ.order_id  AND EX.exec_date_id  = EQ.exec_date_id
    GROUP BY EQ.ORDER_ID,
      EQ.EXEC_TIME::date
    limit 1
    ) ODCS on true
   LEFT JOIN (SELECT ORDER_ID, MIN(AUCTION_ID) "AuctionID" FROM dwh.CLIENT_ORDER2AUCTION where create_date_id = in_date_id  GROUP BY ORDER_ID) AU ON AU.ORDER_ID = CO.ORDER_ID
   WHERE 1=1
   --and EX.ORDER_STATUS <> '3'
   AND coalesce(co.session_eligibility,'R') not in ('A', 'G', 'D', 'F')
   and ex.exec_date_id = in_date_id)

   insert into trash.pd_hods ("OrderID",
	  "ClOrdID", "OrigClOrdID", "OrderClass", "CustomerOrderID", "ExecID",
	  "RefExecID", "InstrumentID", "Symbol", "InstrumentType", "MaturityYear",
	  "MaturityMonth", "MaturityDay", "PutCall", "StrikePx", "OPRASymbol",
	  "DisplayInstrumentID", "UnderlyingDisplayInstrID", "OrderCreationTime",
	  "TransactTime", "RoutedTime", "OrderType", "Side", "OrderQty",
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
    "StatusDate","Status_Date_id")
   select HOD."OrderID",
	  HOD."ClOrdID", HOD."OrigClOrdID", HOD."OrderClass", HOD."CustomerOrderID", HOD."ExecID",
	  HOD."RefExecID", HOD."InstrumentID", HOD."Symbol", HOD."InstrumentType", HOD."MaturityYear",
	  HOD."MaturityMonth", HOD."MaturityDay", HOD."PutCall", HOD."StrikePx", HOD."OPRASymbol",
	  HOD."DisplayInstrumentID", HOD."UnderlyingDisplayInstrID", HOD."OrderCreationTime",
	  HOD."TransactTime", HOD."RoutedTime", HOD."OrderType", HOD."Side", HOD."OrderQty",
	  HOD."Price", HOD."StopPx", HOD."TimeInForce", HOD."ExpireTime", HOD."OpenClose", HOD."ExDestination",
	  HOD."ExDestination" as "AliasExDestination", HOD."HandlInst", HOD."MaxShowQty", HOD."MaxFloorQty",
	  HOD."ClearingFirmID", HOD."ExecBroker", HOD."CustomerOrFirm", HOD."OrderCapacity",
	  HOD."MarketParticipantID", HOD."IsLocateRequired", HOD."LocateBroker", HOD."ExecType",
	  HOD."OrderStatus", HOD."RejectReason", HOD."LeavesQty", HOD."CumQty", HOD."AvgPx", HOD."LastQty",
	  HOD."LastPx", HOD."LastMkt", HOD."DayOrderQty", HOD."DayCumQty", HOD."DayAvgPx", HOD."AccountID",
	  HOD."TradeLiquidityIndicator", HOD."MultilegReportingType", HOD."LegRefID",
	  HOD."MultilegOrderID", HOD."FixCompID", HOD."ClientID", HOD."Text",
	  HOD."IsOSROrder", HOD."OSROrderID", HOD."SubStrategy", HOD."AlgoStopPx", HOD."AlgoClOrdID", HOD."DashClOrdID", HOD."OCCOptionalData", HOD."SubSystemID",
    HOD."TransactionID",HOD."TotNoOrdersInTransaction",HOD."ExchangeID",HOD."CrossOrderID",HOD."AggressionLevel",HOD."HiddenFlag",
    HOD."AlgoStartTime",HOD."AlgoEndTime",HOD."ExtendedOrdType",HOD."PrimListingExchange",HOD."PreOpenBehavior",HOD."MaxWaveQtyPct",HOD."SweepStyle",HOD."DiscretionOffset",HOD."CrossType",
    HOD."QuoteID",HOD."StepUpPriceType",HOD."StepUpPrice",HOD."CrossAccountID",HOD."AuctionID",
    HOD."ClearingAccount", HOD."SubAccount", HOD."RequestNumber", HOD."LiquidityProviderID", HOD."InternalComponentType",
    HOD."ComplianceID", HOD."AlternativeComplianceID", HOD."ConditionalClientOrderID", HOD."IsConditionalOrder",
    HOD."RoutingTableEntryID", HOD."MaxVegaPerStrike", HOD."PerStrikeVegaExposure", HOD."VegaBehavior", HOD."DeltaBehavior", HOD."HedgeParamUnits", HOD."MinDelta",
    HOD."FixCompID2",HOD."SymbolSfx",HOD."StrategyDecisionReasonCode",HOD."SessionEligibility",HOD."CreateDateID",
    "TradeDate" as "StatusDate", in_date_id as "Status_Date_id" from cte HOD
   	WHERE HOD."TransType" <> 'F'
		AND HOD."ExecID" in (
        SELECT MAX(E.EXEC_ID) FROM EXECUTION E
	  	WHERE 1=1
		  AND E.exec_date_id = in_date_id
          --AND E.ORDER_STATUS <> '3'
          group by e.order_id);

  GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;

  return l_row_cnt;


end
$$;


CREATE FUNCTION trash.pd_reload_historic_order(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
	   (CASE
	      WHEN CO.MULTILEG_REPORTING_TYPE = '3'
	      THEN 'M'
	      ELSE HSD.instrument_type_id
	   end)::char(1) as "InstrumentType",
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
	    and ex.exec_date_id = in_date_id
	    ) "LogTime",*/
	   CO.PROCESS_TIME as "RoutedTime",
	   CO.order_type_id as "OrderType",
	   CO.SIDE as "Side",
	   CO.ORDER_QTY as "OrderQty",
	   CO.PRICE as "Price",
	   CO.STOP_PRICE as "StopPx",
	   CO.time_in_force_id as "TimeInForce",
	   CO.EXPIRE_TIME as "ExpireTime",
	   CO.OPEN_CLOSE::char(1) as "OpenClose",
	   CO.EX_DESTINATION as "ExDestination",
	   CO.HANDL_INST::char(1) as "HandlInst",
	   --CO.EXEC_INST as "ExecInst",
	   CO.MAX_SHOW_QTY as "MaxShowQty",
	   CO.MAX_FLOOR as "MaxFloorQty",
	   CASE
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
	      		 then CO.clearing_firm_id
	      		 else null
	      	   end
	      ELSE CO.clearing_firm_id
	    END "ClearingFirmID",
	    CASE
	      WHEN HSD.instrument_type_id = 'E'
	      THEN NULL
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
	      		 then coalesce(doeb.opt_exec_broker , OPX.opt_exec_broker)
	      		 else OPX.opt_exec_broker
	      	   end
	      ELSE doeb.opt_exec_broker
	    END "ExecBroker",
	    --we store value in CLIENT_ORDER for all cases
	   (case
	     when CO.PARENT_ORDER_ID is null
	     then dcof.customer_or_firm_id
	     else null
	   end)::char(1) as "CustomerOrFirm",
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
	   	 then EX.text_
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
	   EX.TRADE_LIQUIDITY_INDICATOR as "TradeLiquidityIndicator",
	   CO.MULTILEG_REPORTING_TYPE::char(1) as "MultilegReportingType",
	   COL.CLIENT_LEG_REF_ID as "LegRefID",
	   COL.MULTILEG_ORDER_ID as "MultilegOrderID",
	   FC.FIX_COMP_ID as "FixCompID", --sending firm
	   CO.client_id_text as "ClientID",
	   EX.TEXT_ as "Text",
	    (CASE
	      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
	      THEN 'Y'
	      ELSE 'N'
	    end)::char(1) "IsOSROrder",
		coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
	   CO.sub_strategy_desc as "SubStrategy",
	   CO.ALGO_STOP_PX as "AlgoStopPx",
	   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
	   CO.TRANS_TYPE as "TransType",
	   CO.DASH_CLIENT_ORDER_ID as "DashClOrdID",
	   CO.CROSS_ORDER_ID as "CrossOrderID",
	   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
	   dss.sub_system_id  as "SubSystemID",
	   CO.TRANSACTION_ID as "TransactionID",
	   CO.TOT_NO_ORDERS_IN_TRANSACTION as "TotNoOrdersInTransaction",
	   CO.EXCHANGE_ID as "ExchangeID",
	   CO.FEE_SENSITIVITY as "FeeSensitivity",
	   CO.ON_BEHALF_OF_SUB_ID as "OnBehalfOfSubID",
	   CO.strtg_decision_reason_code as "StrategyDecisionReasonCode",
	   CO.INTERNAL_ORDER_ID as "InternalOrderID",
	   CO.ALGO_START_TIME as "AlgoStartTime",
	   CO.ALGO_END_TIME as "AlgoEndTime",
	   --CO.MIN_TARGET_QTY as "MinTargetQty",
	   CO.EXTENDED_ORD_TYPE::char(1) as "ExtendedOrdType",
	   CO.PRIM_LISTING_EXCHANGE as "PrimListingExchange",
	   CO.POSTING_EXCHANGE as "PostingExchange",
	   CO.PRE_OPEN_BEHAVIOR::char(1) as "PreOpenBehavior",
	   CO.MAX_WAVE_QTY_PCT as "MaxWaveQtyPct",
	   CO.SWEEP_STYLE::char(1) as "SweepStyle",
	   CO.DISCRETION_OFFSET as "DiscretionOffset",
	   CRO.CROSS_TYPE::char(1) as "CrossType",
	   CO.AGGRESSION_LEVEL as "AggressionLevel",
	   CO.HIDDEN_FLAG::char(1) as "HiddenFlag",
	   CO.QUOTE_ID as "QuoteID",
	   CO.STEP_UP_PRICE_TYPE::char(1) as "StepUpPriceType",
	   CO.STEP_UP_PRICE as "StepUpPrice",
	   CO.CROSS_ACCOUNT_ID as "CrossAccountID",
	   AU."AuctionID" "AuctionID",
	   CO.CLEARING_ACCOUNT as "ClearingAccount",
	   CO.SUB_ACCOUNT as "SubAccount",
	   CO.REQUEST_NUMBER as "RequestNumber",
	   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
	   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",
	   CO.COMPLIANCE_ID as "ComplianceID",
	   CO.ALTERNATIVE_COMPLIANCE_ID as "AlternativeComplianceID",
	   CO.CONDITIONAL_CLIENT_ORDER_ID "ConditionalClientOrderID",
	   'N'::char(1) "IsConditionalOrder",
	   CO.co_routing_table_entry_id  "RoutingTableEntryID",
	   CO.MAX_VEGA_PER_STRIKE "MaxVegaPerStrike",
	   CO.PER_STRIKE_VEGA_EXPOSURE "PerStrikeVegaExposure",
	   CO.VEGA_BEHAVIOR "VegaBehavior",
	   CO.DELTA_BEHAVIOR "DeltaBehavior",
	   CO.HEDGE_PARAM_UNITS "HedgeParamUnits",
	   CO.MIN_DELTA "MinDelta",
	   AC.FIX_COMP_ID "FixCompID2",
	   I.SYMBOL_SUFFIX "SymbolSfx",
	   CO.PRODUCT_DESCRIPTION "ProductDescription",
	   CO.SESSION_ELIGIBILITY::char(1) "SessionEligibility",
	   CO.CREATE_DATE_ID "CreateDateID",
	   EX.exec_date_id "TradeDateID",
	   EX.exec_time::date as "TradeDate"
	   from dwh.execution ex
	   join dwh.client_order co on ex.order_id = co.order_id and ex.exec_date_id = co.create_date_id
	   join dwh.d_instrument i on i.instrument_id = co.instrument_id
	   left join dwh.historic_security_definition hsd on hsd.instrument_id = co.instrument_id
	   join dwh.d_fix_connection fc on  fc.fix_connection_id = co.fix_connection_id
	   join staging.acceptor ac on ac.acceptor_id = fc.acceptor_id
	   join d_account acc on co.account_id = acc.account_id
	   left join dwh.d_opt_exec_broker opx on opx.account_id = acc.account_id and opx.is_active = 'Y' and opx.is_default = 'Y'
	   left join dwh.client_order coorig on co.orig_order_id = coorig.order_id and coorig.create_date_id = co.create_date_id
	   left join dwh.client_order_leg col on co.order_id = col.order_id
	   left join dwh.d_order_type dot on dot.order_type_id = co.order_type_id
	   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force_id and dtif.is_active
	   left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = co.opt_exec_broker_id
	   left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
	   left join dwh.d_customer_or_firm dcof on dcof.customer_or_firm_id = co.customer_or_firm_id
	   left join dwh.cross_order cro on co.cross_order_id = cro.cross_order_id
	   left join lateral
	    (select sum(eq.last_qty) "DAY_CUM_QTY",
	      eq.order_id "order_id",
	      eq.exec_time::date "trade_date",
	     sum(eq.last_qty*eq.last_px)/nullif(sum(eq.last_qty),0) "DAY_AVG_PX"
	    from execution eq
	    where eq.exec_type in ('F', 'G')
	    and exec_date_id = in_date_id
	    and eq.is_busted   <> 'Y'
	    and ex.order_id = eq.order_id
	    and ex.exec_time::date  = eq.exec_time::date
	    group by eq.order_id,
	      eq.exec_time::date
	    limit 1
	    ) odcs on true
	   left join (select order_id, min(auction_id) "AuctionID" from dwh.client_order2auction where create_date_id = in_date_id  group by order_id) au on au.order_id = co.order_id
	   where ex.order_status <> '3'
	   and case when in_order_ids_arr <> '{}' then ex.order_id = any(in_order_ids_arr) else true end
	   and ex.exec_date_id = in_date_id;

	   analyze temp_hods;


	   raise  INFO  '%: temp table has been created',  clock_timestamp()::text;


	   insert into --dwh.historic_order_details_storage
	   dwh.historic_order_details_storage
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
	    /*"ClearingAccount", "SubAccount", "RequestNumber", "LiquidityProviderID", "InternalComponentType",
	    "ComplianceID", "AlternativeComplianceID", "ConditionalClientOrderID", "IsConditionalOrder",
	    "RoutingTableEntryID", "MaxVegaPerStrike", "PerStrikeVegaExposure", "VegaBehavior", "DeltaBehavior", "HedgeParamUnits", "MinDelta",
	    "FixCompID2","SymbolSfx","StrategyDecisionReasonCode","SessionEligibility",*/"CreateDateID",
	    "StatusDate","Status_Date_id")
	   select HOD."OrderID",
		  HOD."ClOrdID", HOD."OrigClOrdID", HOD."OrderClass", HOD."CustomerOrderID", HOD."ExecID",
		  HOD."RefExecID", HOD."InstrumentID", HOD."Symbol", HOD."InstrumentType", HOD."MaturityYear",
		  HOD."MaturityMonth", HOD."MaturityDay", HOD."PutCall", HOD."StrikePx", HOD."OPRASymbol",
		  HOD."DisplayInstrumentID", HOD."UnderlyingDisplayInstrID", HOD."OrderCreationTime",
		  HOD."TransactTime", /*HOD."LogTime",*/ HOD."RoutedTime", HOD."OrderType", HOD."Side", HOD."OrderQty",
		  HOD."Price", HOD."StopPx", HOD."TimeInForce", HOD."ExpireTime", HOD."OpenClose", HOD."ExDestination",
		  HOD."ExDestination" as "AliasExDestination", HOD."HandlInst", HOD."MaxShowQty", HOD."MaxFloorQty",
		  HOD."ClearingFirmID", HOD."ExecBroker", HOD."CustomerOrFirm", HOD."OrderCapacity",
		  HOD."MarketParticipantID", HOD."IsLocateRequired", HOD."LocateBroker", HOD."ExecType",
		  HOD."OrderStatus", HOD."RejectReason", HOD."LeavesQty", HOD."CumQty", HOD."AvgPx", HOD."LastQty",
		  HOD."LastPx", HOD."LastMkt", HOD."DayOrderQty", HOD."DayCumQty", HOD."DayAvgPx", HOD."AccountID",
		  HOD."TradeLiquidityIndicator", HOD."MultilegReportingType", HOD."LegRefID",
		  HOD."MultilegOrderID", HOD."FixCompID", HOD."ClientID", HOD."Text",
		  HOD."IsOSROrder", HOD."OSROrderID", HOD."SubStrategy", HOD."AlgoStopPx", HOD."AlgoClOrdID", HOD."DashClOrdID", HOD."OCCOptionalData", HOD."SubSystemID",
	    HOD."TransactionID",HOD."TotNoOrdersInTransaction",HOD."ExchangeID",HOD."CrossOrderID",HOD."AggressionLevel",HOD."HiddenFlag",
	    HOD."AlgoStartTime",HOD."AlgoEndTime",HOD."ExtendedOrdType",HOD."PrimListingExchange",HOD."PreOpenBehavior",HOD."MaxWaveQtyPct",HOD."SweepStyle",HOD."DiscretionOffset",HOD."CrossType",
	    HOD."QuoteID",HOD."StepUpPriceType",HOD."StepUpPrice",HOD."CrossAccountID",HOD."AuctionID",
	    /*HOD."ClearingAccount", HOD."SubAccount", HOD."RequestNumber", HOD."LiquidityProviderID", HOD."InternalComponentType",
	    HOD."ComplianceID", HOD."AlternativeComplianceID", HOD."ConditionalClientOrderID", HOD."IsConditionalOrder",
	    HOD."RoutingTableEntryID", HOD."MaxVegaPerStrike", HOD."PerStrikeVegaExposure", HOD."VegaBehavior", HOD."DeltaBehavior", HOD."HedgeParamUnits", HOD."MinDelta",
	    HOD."FixCompID2",HOD."SymbolSfx",HOD."StrategyDecisionReasonCode",HOD."SessionEligibility",*/ HOD."CreateDateID",
	    "TradeDate" as "StatusDate", in_date_id as "Status_Date_id" from temp_hods HOD
	   	WHERE HOD."TransType" <> 'F'
			AND HOD."ExecID" in (
	        select max(e.exec_id) from execution e
		  	where case when in_order_ids_arr <> '{}' then e.order_id = any(in_order_ids_arr) else true end
			  and e.exec_date_id = in_date_id
	          and e.order_status <> '3'
	          group by e.order_id);


	   GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;

	   raise  INFO  '%:  inserted rows: %',  clock_timestamp()::text, l_row_cnt;

	   return l_row_cnt;

end
$$;




CREATE FUNCTION trash.pd_reload_historic_order_and_mleg(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
 l_row_cnt int;
begin



	create temp table temp_hods_1
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
	   (CASE
	      WHEN CO.MULTILEG_REPORTING_TYPE = '3'
	      THEN 'M'
	      ELSE HSD.instrument_type_id
	   end)::char(1) as "InstrumentType",
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
	    and ex.exec_date_id = in_date_id
	    ) "LogTime",*/
	   CO.PROCESS_TIME as "RoutedTime",
	   CO.order_type_id as "OrderType",
	   CO.SIDE as "Side",
	   CO.ORDER_QTY as "OrderQty",
	   CO.PRICE as "Price",
	   CO.STOP_PRICE as "StopPx",
	   CO.time_in_force_id as "TimeInForce",
	   CO.EXPIRE_TIME as "ExpireTime",
	   CO.OPEN_CLOSE::char(1) as "OpenClose",
	   CO.EX_DESTINATION as "ExDestination",
	   CO.HANDL_INST::char(1) as "HandlInst",
	   --CO.EXEC_INST as "ExecInst",
	   CO.MAX_SHOW_QTY as "MaxShowQty",
	   CO.MAX_FLOOR as "MaxFloorQty",
	   CASE
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
	      		 then CO.clearing_firm_id
	      		 else null
	      	   end
	      ELSE CO.clearing_firm_id
	    END "ClearingFirmID",
	    CASE
	      WHEN HSD.instrument_type_id = 'E'
	      THEN NULL
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
	      		 then coalesce(doeb.opt_exec_broker , OPX.opt_exec_broker)
	      		 else OPX.opt_exec_broker
	      	   end
	      ELSE doeb.opt_exec_broker
	    END "ExecBroker",
	    --we store value in CLIENT_ORDER for all cases
	   (case
	     when CO.PARENT_ORDER_ID is null
	     then dcof.customer_or_firm_id
	     else null
	   end)::char(1) as "CustomerOrFirm",
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
	   	 then EX.text_
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
	   EX.TRADE_LIQUIDITY_INDICATOR as "TradeLiquidityIndicator",
	   CO.MULTILEG_REPORTING_TYPE::char(1) as "MultilegReportingType",
	   COL.CLIENT_LEG_REF_ID as "LegRefID",
	   COL.MULTILEG_ORDER_ID as "MultilegOrderID",
	   FC.FIX_COMP_ID as "FixCompID", --sending firm
	   CO.client_id_text as "ClientID",
	   EX.TEXT_ as "Text",
	    (CASE
	      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
	      THEN 'Y'
	      ELSE 'N'
	    end)::char(1) "IsOSROrder",
		coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
	   CO.sub_strategy_desc as "SubStrategy",
	   CO.ALGO_STOP_PX as "AlgoStopPx",
	   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
	   CO.TRANS_TYPE as "TransType",
	   CO.DASH_CLIENT_ORDER_ID as "DashClOrdID",
	   CO.CROSS_ORDER_ID as "CrossOrderID",
	   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
	   dss.sub_system_id  as "SubSystemID",
	   CO.TRANSACTION_ID as "TransactionID",
	   CO.TOT_NO_ORDERS_IN_TRANSACTION as "TotNoOrdersInTransaction",
	   CO.EXCHANGE_ID as "ExchangeID",
	   CO.FEE_SENSITIVITY as "FeeSensitivity",
	   CO.ON_BEHALF_OF_SUB_ID as "OnBehalfOfSubID",
	   CO.strtg_decision_reason_code as "StrategyDecisionReasonCode",
	   CO.INTERNAL_ORDER_ID as "InternalOrderID",
	   CO.ALGO_START_TIME as "AlgoStartTime",
	   CO.ALGO_END_TIME as "AlgoEndTime",
	   --CO.MIN_TARGET_QTY as "MinTargetQty",
	   CO.EXTENDED_ORD_TYPE::char(1) as "ExtendedOrdType",
	   CO.PRIM_LISTING_EXCHANGE as "PrimListingExchange",
	   CO.POSTING_EXCHANGE as "PostingExchange",
	   CO.PRE_OPEN_BEHAVIOR::char(1) as "PreOpenBehavior",
	   CO.MAX_WAVE_QTY_PCT as "MaxWaveQtyPct",
	   CO.SWEEP_STYLE::char(1) as "SweepStyle",
	   CO.DISCRETION_OFFSET as "DiscretionOffset",
	   CRO.CROSS_TYPE::char(1) as "CrossType",
	   CO.AGGRESSION_LEVEL as "AggressionLevel",
	   CO.HIDDEN_FLAG::char(1) as "HiddenFlag",
	   CO.QUOTE_ID as "QuoteID",
	   CO.STEP_UP_PRICE_TYPE::char(1) as "StepUpPriceType",
	   CO.STEP_UP_PRICE as "StepUpPrice",
	   CO.CROSS_ACCOUNT_ID as "CrossAccountID",
	   AU."AuctionID" "AuctionID",
	   /*CO.CLEARING_ACCOUNT as "ClearingAccount",
	   CO.SUB_ACCOUNT as "SubAccount",
	   CO.REQUEST_NUMBER as "RequestNumber",
	   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
	   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",*/
	   CO.COMPLIANCE_ID as "ComplianceID",
	   CO.ALTERNATIVE_COMPLIANCE_ID as "AlternativeComplianceID",
	   CO.CONDITIONAL_CLIENT_ORDER_ID "ConditionalClientOrderID",
	   'N'::char(1) "IsConditionalOrder",
	   CO.co_routing_table_entry_id  "RoutingTableEntryID",
	   CO.MAX_VEGA_PER_STRIKE "MaxVegaPerStrike",
	   CO.PER_STRIKE_VEGA_EXPOSURE "PerStrikeVegaExposure",
	   CO.VEGA_BEHAVIOR "VegaBehavior",
	   CO.DELTA_BEHAVIOR "DeltaBehavior",
	   CO.HEDGE_PARAM_UNITS "HedgeParamUnits",
	   CO.MIN_DELTA "MinDelta",
	   AC.FIX_COMP_ID "FixCompID2",
	   I.SYMBOL_SUFFIX "SymbolSfx",
	   CO.PRODUCT_DESCRIPTION "ProductDescription",
	   CO.SESSION_ELIGIBILITY::char(1) "SessionEligibility",
	   CO.CREATE_DATE_ID "CreateDateID",
	   EX.exec_date_id "TradeDateID",
	   EX.exec_time::date as "TradeDate"
	   from dwh.execution ex
	   join dwh.client_order co on ex.order_id = co.order_id and ex.exec_date_id = co.create_date_id
	   join dwh.d_instrument i on i.instrument_id = co.instrument_id
	   left join dwh.historic_security_definition hsd on hsd.instrument_id = co.instrument_id
	   join dwh.d_fix_connection fc on  fc.fix_connection_id = co.fix_connection_id
	   join staging.acceptor ac on ac.acceptor_id = fc.acceptor_id
	   join d_account acc on co.account_id = acc.account_id
	   left join dwh.d_opt_exec_broker opx on opx.account_id = acc.account_id and opx.is_active = 'Y' and opx.is_default = 'Y'
	   left join dwh.client_order coorig on co.orig_order_id = coorig.order_id and coorig.create_date_id = co.create_date_id
	   left join dwh.client_order_leg col on co.order_id = col.order_id
	   left join dwh.d_order_type dot on dot.order_type_id = co.order_type_id
	   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force_id and dtif.is_active
	   left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = co.opt_exec_broker_id
	   left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
	   left join dwh.d_customer_or_firm dcof on dcof.customer_or_firm_id = co.customer_or_firm_id
	   left join dwh.cross_order cro on co.cross_order_id = cro.cross_order_id
	   left join lateral
	    (select sum(eq.last_qty) "DAY_CUM_QTY",
	      eq.order_id "order_id",
	      eq.exec_time::date "trade_date",
	     sum(eq.last_qty*eq.last_px)/nullif(sum(eq.last_qty),0) "DAY_AVG_PX"
	    from execution eq
	    where eq.exec_type in ('F', 'G')
	    and exec_date_id = in_date_id
	    and eq.is_busted   <> 'Y'
	    and ex.order_id = eq.order_id
	    and ex.exec_time::date  = eq.exec_time::date
	    group by eq.order_id,
	      eq.exec_time::date
	    limit 1
	    ) odcs on true
	   left join (select order_id, min(auction_id) "AuctionID" from dwh.client_order2auction where create_date_id = in_date_id  group by order_id) au on au.order_id = co.order_id
	   where ex.order_status <> '3'
	   and ex.time_in_force_id not in ('1','6')
	   and case when in_order_ids_arr <> '{}' then ex.order_id = any(in_order_ids_arr) else true end
	   and ex.exec_date_id = in_date_id;

	   analyze temp_hods_1;


	   raise  INFO  '%: temp table has been created',  clock_timestamp()::text;


	   insert into dwh.historic_order_details_storage--trash.pd_historic_order_details_storage
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
	    /*"ClearingAccount", "SubAccount", "RequestNumber", "LiquidityProviderID", "InternalComponentType",*/
	    "ComplianceID", "AlternativeComplianceID", "ConditionalClientOrderID", "IsConditionalOrder",
	    "RoutingTableEntryID", "MaxVegaPerStrike", "PerStrikeVegaExposure", "VegaBehavior", "DeltaBehavior", "HedgeParamUnits", "MinDelta",
	    "FixCompID2","SymbolSfx","StrategyDecisionReasonCode","SessionEligibility","CreateDateID",
	    "StatusDate","Status_Date_id")
	   select HOD."OrderID",
		  HOD."ClOrdID", HOD."OrigClOrdID", HOD."OrderClass", HOD."CustomerOrderID", HOD."ExecID",
		  HOD."RefExecID", HOD."InstrumentID", HOD."Symbol", HOD."InstrumentType", HOD."MaturityYear",
		  HOD."MaturityMonth", HOD."MaturityDay", HOD."PutCall", HOD."StrikePx", HOD."OPRASymbol",
		  HOD."DisplayInstrumentID", HOD."UnderlyingDisplayInstrID", HOD."OrderCreationTime",
		  HOD."TransactTime", /*HOD."LogTime",*/ HOD."RoutedTime", HOD."OrderType", HOD."Side", HOD."OrderQty",
		  HOD."Price", HOD."StopPx", HOD."TimeInForce", HOD."ExpireTime", HOD."OpenClose", HOD."ExDestination",
		  HOD."ExDestination" as "AliasExDestination", HOD."HandlInst", HOD."MaxShowQty", HOD."MaxFloorQty",
		  HOD."ClearingFirmID", HOD."ExecBroker", HOD."CustomerOrFirm", HOD."OrderCapacity",
		  HOD."MarketParticipantID", HOD."IsLocateRequired", HOD."LocateBroker", HOD."ExecType",
		  HOD."OrderStatus", HOD."RejectReason", HOD."LeavesQty", HOD."CumQty", HOD."AvgPx", HOD."LastQty",
		  HOD."LastPx", HOD."LastMkt", HOD."DayOrderQty", HOD."DayCumQty", HOD."DayAvgPx", HOD."AccountID",
		  HOD."TradeLiquidityIndicator", HOD."MultilegReportingType", HOD."LegRefID",
		  HOD."MultilegOrderID", HOD."FixCompID", HOD."ClientID", HOD."Text",
		  HOD."IsOSROrder", HOD."OSROrderID", HOD."SubStrategy", HOD."AlgoStopPx", HOD."AlgoClOrdID", HOD."DashClOrdID", HOD."OCCOptionalData", HOD."SubSystemID",
	    HOD."TransactionID",HOD."TotNoOrdersInTransaction",HOD."ExchangeID",HOD."CrossOrderID",HOD."AggressionLevel",HOD."HiddenFlag",
	    HOD."AlgoStartTime",HOD."AlgoEndTime",HOD."ExtendedOrdType",HOD."PrimListingExchange",HOD."PreOpenBehavior",HOD."MaxWaveQtyPct",HOD."SweepStyle",HOD."DiscretionOffset",HOD."CrossType",
	    HOD."QuoteID",HOD."StepUpPriceType",HOD."StepUpPrice",HOD."CrossAccountID",HOD."AuctionID",
	    /*HOD."ClearingAccount", HOD."SubAccount", HOD."RequestNumber", HOD."LiquidityProviderID", HOD."InternalComponentType",*/
	    HOD."ComplianceID", HOD."AlternativeComplianceID", HOD."ConditionalClientOrderID", HOD."IsConditionalOrder",
	    HOD."RoutingTableEntryID", HOD."MaxVegaPerStrike", HOD."PerStrikeVegaExposure", HOD."VegaBehavior", HOD."DeltaBehavior", HOD."HedgeParamUnits", HOD."MinDelta",
	    HOD."FixCompID2",HOD."SymbolSfx",HOD."StrategyDecisionReasonCode",HOD."SessionEligibility",HOD."CreateDateID",
	    "TradeDate" as "StatusDate", in_date_id as "Status_Date_id" from temp_hods_1 HOD
	   	WHERE HOD."TransType" <> 'F'
			AND HOD."ExecID" in (
	        select max(e.exec_id) from execution e
		  	where case when in_order_ids_arr <> '{}' then e.order_id = any(in_order_ids_arr) else true end
			  and e.exec_date_id = in_date_id
	          and e.order_status <> '3'
	          group by e.order_id)
	         /*on conflict ("OrderID","StatusDate", "Status_Date_id" ) do update
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
$$;


CREATE FUNCTION trash.pd_reload_historic_order_cond(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
 l_row_cnt int;
begin



	create temp table temp_hods_2
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
	   	 then EX.text_
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
	   CO.client_id as "ClientID",
	   EX.TEXT_ as "Text",
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
	   EX.exec_time::date as "TradeDate"
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

	   analyze temp_hods_2;


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
	   /* "ClearingAccount", "SubAccount", "RequestNumber", "LiquidityProviderID", "InternalComponentType",*/
	    "ComplianceID", "AlternativeComplianceID", "ConditionalClientOrderID", "IsConditionalOrder",
	    "RoutingTableEntryID", "MaxVegaPerStrike", "PerStrikeVegaExposure", "VegaBehavior", "DeltaBehavior", "HedgeParamUnits", "MinDelta",
	    "FixCompID2","SymbolSfx","StrategyDecisionReasonCode","SessionEligibility","CreateDateID",
	    "StatusDate","Status_Date_id")
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
			/*null "ClearingAccount",
			null "SubAccount",
			null "RequestNumber",
			null "LiquidityProviderID",
			null "InternalComponentType",*/
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
			in_date_id as "Status_Date_id"
			from temp_hods_2 HCOD
	   	WHERE HCOD."TransType" <> 'F'
			AND HCOD."ExecID" in (
	        select max(e.exec_id) from dwh.conditional_execution e
		  	where case when in_order_ids_arr <> '{}' then e.order_id = any(in_order_ids_arr) else true end
			  and e.date_id = in_date_id
	          and e.order_status <> '3'
	          group by e.order_id)
	         /*on conflict ("OrderID","StatusDate", "Status_Date_id" ) do update
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
$$;


CREATE FUNCTION trash.pd_reload_historic_order_gtc(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
	   (CASE
	      WHEN CO.MULTILEG_REPORTING_TYPE = '3'
	      THEN 'M'
	      ELSE HSD.instrument_type_id
	   end)::char(1) as "InstrumentType",
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
	    and ex.exec_date_id = in_date_id
	    ) "LogTime",*/
	   CO.PROCESS_TIME as "RoutedTime",
	   CO.order_type_id as "OrderType",
	   CO.SIDE as "Side",
	   CO.ORDER_QTY as "OrderQty",
	   CO.PRICE as "Price",
	   CO.STOP_PRICE as "StopPx",
	   CO.time_in_force_id as "TimeInForce",
	   CO.EXPIRE_TIME as "ExpireTime",
	   CO.OPEN_CLOSE::char(1) as "OpenClose",
	   CO.EX_DESTINATION as "ExDestination",
	   CO.HANDL_INST::char(1) as "HandlInst",
	   --CO.EXEC_INST as "ExecInst",
	   CO.MAX_SHOW_QTY as "MaxShowQty",
	   CO.MAX_FLOOR as "MaxFloorQty",
	   CASE
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
	      		 then CO.clearing_firm_id
	      		 else null
	      	   end
	      ELSE CO.clearing_firm_id
	    END "ClearingFirmID",
	    CASE
	      WHEN HSD.instrument_type_id = 'E'
	      THEN NULL
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
	      		 then coalesce(doeb.opt_exec_broker , OPX.opt_exec_broker)
	      		 else OPX.opt_exec_broker
	      	   end
	      ELSE doeb.opt_exec_broker
	    END "ExecBroker",
	    --we store value in CLIENT_ORDER for all cases
	   (case
	     when CO.PARENT_ORDER_ID is null
	     then dcof.customer_or_firm_id
	     else null
	   end)::char(1) as "CustomerOrFirm",
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
	   	 then EX.text_
	   	 else null
	   end as "RejectReason",
	   EX.LEAVES_QTY as "LeavesQty",
	     --EX.CUM_QTY "CumQty",
	   "DAY_CUM_QTY" as "CumQty",
	    --EX.AVG_PX "AvgPx",
	    "DAY_AVG_PX" as "AvgPx",
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
	   EX.TRADE_LIQUIDITY_INDICATOR as "TradeLiquidityIndicator",
	   CO.MULTILEG_REPORTING_TYPE::char(1) as "MultilegReportingType",
	   COL.CLIENT_LEG_REF_ID as "LegRefID",
	   COL.MULTILEG_ORDER_ID as "MultilegOrderID",
	   FC.FIX_COMP_ID as "FixCompID", --sending firm
	   CO.client_id_text as "ClientID",
	   EX.TEXT_ as "Text",
	    (CASE
	      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
	      THEN 'Y'
	      ELSE 'N'
	    end)::char(1) "IsOSROrder",
		coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
	   CO.sub_strategy_desc as "SubStrategy",
	   CO.ALGO_STOP_PX as "AlgoStopPx",
	   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
	   CO.TRANS_TYPE as "TransType",
	   CO.DASH_CLIENT_ORDER_ID as "DashClOrdID",
	   CO.CROSS_ORDER_ID as "CrossOrderID",
	   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
	   dss.sub_system_id  as "SubSystemID",
	   CO.TRANSACTION_ID as "TransactionID",
	   CO.TOT_NO_ORDERS_IN_TRANSACTION as "TotNoOrdersInTransaction",
	   CO.EXCHANGE_ID as "ExchangeID",
	   CO.FEE_SENSITIVITY as "FeeSensitivity",
	   CO.ON_BEHALF_OF_SUB_ID as "OnBehalfOfSubID",
	   CO.strtg_decision_reason_code as "StrategyDecisionReasonCode",
	   CO.INTERNAL_ORDER_ID as "InternalOrderID",
	   CO.ALGO_START_TIME as "AlgoStartTime",
	   CO.ALGO_END_TIME as "AlgoEndTime",
	   --CO.MIN_TARGET_QTY as "MinTargetQty",
	   CO.EXTENDED_ORD_TYPE::char(1) as "ExtendedOrdType",
	   CO.PRIM_LISTING_EXCHANGE as "PrimListingExchange",
	   CO.POSTING_EXCHANGE as "PostingExchange",
	   CO.PRE_OPEN_BEHAVIOR::char(1) as "PreOpenBehavior",
	   CO.MAX_WAVE_QTY_PCT as "MaxWaveQtyPct",
	   CO.SWEEP_STYLE::char(1) as "SweepStyle",
	   CO.DISCRETION_OFFSET as "DiscretionOffset",
	   CRO.CROSS_TYPE::char(1) as "CrossType",
	   CO.AGGRESSION_LEVEL as "AggressionLevel",
	   CO.HIDDEN_FLAG::char(1) as "HiddenFlag",
	   CO.QUOTE_ID as "QuoteID",
	   CO.STEP_UP_PRICE_TYPE::char(1) as "StepUpPriceType",
	   CO.STEP_UP_PRICE as "StepUpPrice",
	   CO.CROSS_ACCOUNT_ID as "CrossAccountID",
	   AU."AuctionID" "AuctionID",
	   /*CO.CLEARING_ACCOUNT as "ClearingAccount",
	   CO.SUB_ACCOUNT as "SubAccount",
	   CO.REQUEST_NUMBER as "RequestNumber",
	   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
	   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",*/
	   CO.COMPLIANCE_ID as "ComplianceID",
	   CO.ALTERNATIVE_COMPLIANCE_ID as "AlternativeComplianceID",
	   CO.CONDITIONAL_CLIENT_ORDER_ID "ConditionalClientOrderID",
	   'N'::char(1) "IsConditionalOrder",
	   CO.co_routing_table_entry_id  "RoutingTableEntryID",
	   CO.MAX_VEGA_PER_STRIKE "MaxVegaPerStrike",
	   CO.PER_STRIKE_VEGA_EXPOSURE "PerStrikeVegaExposure",
	   CO.VEGA_BEHAVIOR "VegaBehavior",
	   CO.DELTA_BEHAVIOR "DeltaBehavior",
	   CO.HEDGE_PARAM_UNITS "HedgeParamUnits",
	   CO.MIN_DELTA "MinDelta",
	   AC.FIX_COMP_ID "FixCompID2",
	   I.SYMBOL_SUFFIX "SymbolSfx",
	   CO.PRODUCT_DESCRIPTION "ProductDescription",
	   CO.SESSION_ELIGIBILITY::char(1) "SessionEligibility",
	   CO.CREATE_DATE_ID "CreateDateID",
	   EX.exec_date_id "TradeDateID",
	   EX.exec_time::date as "TradeDate"
	   from dwh.gtc_order_status gto
	   join dwh.execution ex on ex.order_id = gto.order_id
	   join dwh.client_order co on ex.order_id = co.order_id and gto.create_date_id = co.create_date_id
	   join dwh.d_instrument i on i.instrument_id = co.instrument_id
	   left join dwh.historic_security_definition hsd on hsd.instrument_id = co.instrument_id
	   join dwh.d_fix_connection fc on  fc.fix_connection_id = co.fix_connection_id
	   join staging.acceptor ac on ac.acceptor_id = fc.acceptor_id
	   join d_account acc on co.account_id = acc.account_id
	   left join dwh.d_opt_exec_broker opx on opx.account_id = acc.account_id and opx.is_active = 'Y' and opx.is_default = 'Y'
	   left join dwh.client_order coorig on co.orig_order_id = coorig.order_id and coorig.create_date_id = co.create_date_id
	   left join dwh.client_order_leg col on co.order_id = col.order_id
	   left join dwh.d_order_type dot on dot.order_type_id = co.order_type_id
	   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force_id and dtif.is_active
	   left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = co.opt_exec_broker_id
	   left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
	   left join dwh.d_customer_or_firm dcof on dcof.customer_or_firm_id = co.customer_or_firm_id
	   left join dwh.cross_order cro on co.cross_order_id = cro.cross_order_id
	   left join lateral
	    (select sum(eq.last_qty) "DAY_CUM_QTY",
	      eq.order_id "order_id",
	      eq.exec_time::date "trade_date",
	     sum(eq.last_qty*eq.last_px)/nullif(sum(eq.last_qty),0) "DAY_AVG_PX"
	    from execution eq
	    where eq.exec_type in ('F', 'G')
	    and exec_date_id = in_date_id
	    and eq.is_busted   <> 'Y'
	    and ex.order_id = eq.order_id
	    and ex.exec_time::date  = eq.exec_time::date
	    group by eq.order_id,
	      eq.exec_time::date
	    limit 1
	    ) odcs on true
	   left join (select order_id, min(auction_id) "AuctionID" from dwh.client_order2auction where create_date_id = in_date_id  group by order_id) au on au.order_id = co.order_id
	   where ex.order_status <> '3'
	   and case when in_order_ids_arr <> '{}' then ex.order_id = any(in_order_ids_arr) else true end
	   and ex.exec_date_id = in_date_id
	   and (gto.close_date_id is null or gto.close_date_id = in_date_id);

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
	    /*"ClearingAccount", "SubAccount", "RequestNumber", "LiquidityProviderID", "InternalComponentType",*/
	    "ComplianceID", "AlternativeComplianceID", "ConditionalClientOrderID", "IsConditionalOrder",
	    "RoutingTableEntryID", "MaxVegaPerStrike", "PerStrikeVegaExposure", "VegaBehavior", "DeltaBehavior", "HedgeParamUnits", "MinDelta",
	    "FixCompID2","SymbolSfx","StrategyDecisionReasonCode","SessionEligibility","CreateDateID",
	    "StatusDate","Status_Date_id")
	   select HOD."OrderID",
		  HOD."ClOrdID", HOD."OrigClOrdID", HOD."OrderClass", HOD."CustomerOrderID", HOD."ExecID",
		  HOD."RefExecID", HOD."InstrumentID", HOD."Symbol", HOD."InstrumentType", HOD."MaturityYear",
		  HOD."MaturityMonth", HOD."MaturityDay", HOD."PutCall", HOD."StrikePx", HOD."OPRASymbol",
		  HOD."DisplayInstrumentID", HOD."UnderlyingDisplayInstrID", HOD."OrderCreationTime",
		  HOD."TransactTime", /*HOD."LogTime",*/ HOD."RoutedTime", HOD."OrderType", HOD."Side", HOD."OrderQty",
		  HOD."Price", HOD."StopPx", HOD."TimeInForce", HOD."ExpireTime", HOD."OpenClose", HOD."ExDestination",
		  HOD."ExDestination" as "AliasExDestination", HOD."HandlInst", HOD."MaxShowQty", HOD."MaxFloorQty",
		  HOD."ClearingFirmID", HOD."ExecBroker", HOD."CustomerOrFirm", HOD."OrderCapacity",
		  HOD."MarketParticipantID", HOD."IsLocateRequired", HOD."LocateBroker", HOD."ExecType",
		  HOD."OrderStatus", HOD."RejectReason", HOD."LeavesQty", HOD."CumQty", HOD."AvgPx", HOD."LastQty",
		  HOD."LastPx", HOD."LastMkt", HOD."DayOrderQty", HOD."DayCumQty", HOD."DayAvgPx", HOD."AccountID",
		  HOD."TradeLiquidityIndicator", HOD."MultilegReportingType", HOD."LegRefID",
		  HOD."MultilegOrderID", HOD."FixCompID", HOD."ClientID", HOD."Text",
		  HOD."IsOSROrder", HOD."OSROrderID", HOD."SubStrategy", HOD."AlgoStopPx", HOD."AlgoClOrdID", HOD."DashClOrdID", HOD."OCCOptionalData", HOD."SubSystemID",
	    HOD."TransactionID",HOD."TotNoOrdersInTransaction",HOD."ExchangeID",HOD."CrossOrderID",HOD."AggressionLevel",HOD."HiddenFlag",
	    HOD."AlgoStartTime",HOD."AlgoEndTime",HOD."ExtendedOrdType",HOD."PrimListingExchange",HOD."PreOpenBehavior",HOD."MaxWaveQtyPct",HOD."SweepStyle",HOD."DiscretionOffset",HOD."CrossType",
	    HOD."QuoteID",HOD."StepUpPriceType",HOD."StepUpPrice",HOD."CrossAccountID",HOD."AuctionID",
	    /*HOD."ClearingAccount", HOD."SubAccount", HOD."RequestNumber", HOD."LiquidityProviderID", HOD."InternalComponentType",*/
	    HOD."ComplianceID", HOD."AlternativeComplianceID", HOD."ConditionalClientOrderID", HOD."IsConditionalOrder",
	    HOD."RoutingTableEntryID", HOD."MaxVegaPerStrike", HOD."PerStrikeVegaExposure", HOD."VegaBehavior", HOD."DeltaBehavior", HOD."HedgeParamUnits", HOD."MinDelta",
	    HOD."FixCompID2",HOD."SymbolSfx",HOD."StrategyDecisionReasonCode",HOD."SessionEligibility",HOD."CreateDateID",
	    "TradeDate" as "StatusDate", in_date_id as "Status_Date_id" from temp_hods HOD
	   	WHERE HOD."TransType" <> 'F'
			AND HOD."ExecID" in (
	        select max(e.exec_id) from execution e
		  	where case when in_order_ids_arr <> '{}' then e.order_id = any(in_order_ids_arr) else true end
			  and e.exec_date_id = in_date_id
	          and e.order_status <> '3'
	          group by e.order_id)
	     /*on conflict ("OrderID","StatusDate", "Status_Date_id" ) do update
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
$$;


CREATE FUNCTION trash.reload_historic_order_and_mleg(in_date_id integer, in_order_ids_arr bigint[] DEFAULT NULL::bigint[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$


declare
 l_row_cnt int;
begin

    raise  INFO  '%: Load historic orders+mleg started',  clock_timestamp()::text;

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
	   (CASE
	      WHEN CO.MULTILEG_REPORTING_TYPE = '3'
	      THEN 'M'
	      ELSE HSD.instrument_type_id
	   end)::char(1) as "InstrumentType",
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
	    and ex.exec_date_id = in_date_id
	    ) "LogTime",*/
	   CO.PROCESS_TIME as "RoutedTime",
	   CO.order_type_id as "OrderType",
	   CO.SIDE as "Side",
	   CO.ORDER_QTY as "OrderQty",
	   CO.PRICE as "Price",
	   CO.STOP_PRICE as "StopPx",
	   CO.time_in_force_id as "TimeInForce",
	   CO.EXPIRE_TIME as "ExpireTime",
	   CO.OPEN_CLOSE::char(1) as "OpenClose",
	   CO.EX_DESTINATION as "ExDestination",
	   CO.HANDL_INST::char(1) as "HandlInst",
	   --CO.EXEC_INST as "ExecInst",
	   CO.MAX_SHOW_QTY as "MaxShowQty",
	   CO.MAX_FLOOR as "MaxFloorQty",
	   CASE
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y'
	      		 then CO.clearing_firm_id
	      		 else null
	      	   end
	      ELSE CO.clearing_firm_id
	    END "ClearingFirmID",
	    CASE
	      WHEN HSD.instrument_type_id = 'E'
	      THEN NULL
	      WHEN CO.PARENT_ORDER_ID IS NULL
	      THEN case
	      		 when ACC.OPT_IS_FIX_EXECBROK_PROCESSED = 'Y'
	      		 then coalesce(doeb.opt_exec_broker , OPX.opt_exec_broker)
	      		 else OPX.opt_exec_broker
	      	   end
	      ELSE doeb.opt_exec_broker
	    END "ExecBroker",
	    --we store value in CLIENT_ORDER for all cases
	   (case
	     when CO.PARENT_ORDER_ID is null
	     then dcof.customer_or_firm_id
	     else null
	   end)::char(1) as "CustomerOrFirm",
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
	   	 then EX.text_
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
	   EX.TRADE_LIQUIDITY_INDICATOR as "TradeLiquidityIndicator",
	   CO.MULTILEG_REPORTING_TYPE::char(1) as "MultilegReportingType",
	   COL.CLIENT_LEG_REF_ID as "LegRefID",
	   COL.MULTILEG_ORDER_ID as "MultilegOrderID",
	   FC.FIX_COMP_ID as "FixCompID", --sending firm
	   CO.client_id_text as "ClientID",
	   EX.TEXT_ as "Text",
	    (CASE
	      WHEN CO.EX_DESTINATION IN ('SMART', 'ALGO')
	      THEN 'Y'
	      ELSE 'N'
	    end)::char(1) "IsOSROrder",
		coalesce(CO.OSR_CUSTOMER_ORDER_ID, CO.OSR_STREET_ORDER_ID) as "OSROrderID",
	   CO.sub_strategy_desc as "SubStrategy",
	   CO.ALGO_STOP_PX as "AlgoStopPx",
	   CO.ALGO_CLIENT_ORDER_ID as "AlgoClOrdID",
	   CO.TRANS_TYPE as "TransType",
	   CO.DASH_CLIENT_ORDER_ID as "DashClOrdID",
	   CO.CROSS_ORDER_ID as "CrossOrderID",
	   CO.OCC_OPTIONAL_DATA as "OCCOptionalData",
	   dss.sub_system_id  as "SubSystemID",
	   CO.TRANSACTION_ID as "TransactionID",
	   CO.TOT_NO_ORDERS_IN_TRANSACTION as "TotNoOrdersInTransaction",
	   CO.EXCHANGE_ID as "ExchangeID",
	   CO.FEE_SENSITIVITY as "FeeSensitivity",
	   CO.ON_BEHALF_OF_SUB_ID as "OnBehalfOfSubID",
	   CO.strtg_decision_reason_code as "StrategyDecisionReasonCode",
	   CO.INTERNAL_ORDER_ID as "InternalOrderID",
	   CO.ALGO_START_TIME as "AlgoStartTime",
	   CO.ALGO_END_TIME as "AlgoEndTime",
	   --CO.MIN_TARGET_QTY as "MinTargetQty",
	   CO.EXTENDED_ORD_TYPE::char(1) as "ExtendedOrdType",
	   CO.PRIM_LISTING_EXCHANGE as "PrimListingExchange",
	   CO.POSTING_EXCHANGE as "PostingExchange",
	   CO.PRE_OPEN_BEHAVIOR::char(1) as "PreOpenBehavior",
	   CO.MAX_WAVE_QTY_PCT as "MaxWaveQtyPct",
	   CO.SWEEP_STYLE::char(1) as "SweepStyle",
	   CO.DISCRETION_OFFSET as "DiscretionOffset",
	   CRO.CROSS_TYPE::char(1) as "CrossType",
	   CO.AGGRESSION_LEVEL as "AggressionLevel",
	   CO.HIDDEN_FLAG::char(1) as "HiddenFlag",
	   CO.QUOTE_ID as "QuoteID",
	   CO.STEP_UP_PRICE_TYPE::char(1) as "StepUpPriceType",
	   CO.STEP_UP_PRICE as "StepUpPrice",
	   CO.CROSS_ACCOUNT_ID as "CrossAccountID",
	   AU."AuctionID" "AuctionID",
	   CO.CLEARING_ACCOUNT as "ClearingAccount",
	   CO.SUB_ACCOUNT as "SubAccount",
	   CO.REQUEST_NUMBER as "RequestNumber",
	   CO.LIQUIDITY_PROVIDER_ID as "LiquidityProviderID",
	   CO.INTERNAL_COMPONENT_TYPE::char(1) "InternalComponentType",
	   CO.COMPLIANCE_ID as "ComplianceID",
	   CO.ALTERNATIVE_COMPLIANCE_ID as "AlternativeComplianceID",
	   CO.CONDITIONAL_CLIENT_ORDER_ID "ConditionalClientOrderID",
	   'N'::char(1) "IsConditionalOrder",
	   CO.co_routing_table_entry_id  "RoutingTableEntryID",
	   CO.MAX_VEGA_PER_STRIKE "MaxVegaPerStrike",
	   CO.PER_STRIKE_VEGA_EXPOSURE "PerStrikeVegaExposure",
	   CO.VEGA_BEHAVIOR "VegaBehavior",
	   CO.DELTA_BEHAVIOR "DeltaBehavior",
	   CO.HEDGE_PARAM_UNITS "HedgeParamUnits",
	   CO.MIN_DELTA "MinDelta",
	   AC.FIX_COMP_ID "FixCompID2",
	   I.SYMBOL_SUFFIX "SymbolSfx",
	   CO.PRODUCT_DESCRIPTION "ProductDescription",
	   CO.SESSION_ELIGIBILITY::char(1) "SessionEligibility",
	   CO.CREATE_DATE_ID "CreateDateID",
	   EX.exec_date_id "TradeDateID",
	   EX.exec_time::date as "TradeDate",
	   CO.optwap_bin_number as "OptwapBinNumber",
	   CO.optwap_phase as "OptwapPhase",
	   CO.optwap_order_price as "OptwapOrderPrice",
	   CO.optwap_bin_duration as "OptwapBinDuration",
	   CO.optwap_bin_qty as "OptwapBinQty",
	   CO.optwap_phase_duration as "OptwapPhaseDuration"
	   from dwh.execution ex
	   join dwh.client_order co on ex.order_id = co.order_id and ex.exec_date_id = co.create_date_id
	   join dwh.d_instrument i on i.instrument_id = co.instrument_id
	   left join dwh.historic_security_definition hsd on hsd.instrument_id = co.instrument_id
	   join dwh.d_fix_connection fc on  fc.fix_connection_id = co.fix_connection_id
	   join staging.acceptor ac on ac.acceptor_id = fc.acceptor_id
	   join d_account acc on co.account_id = acc.account_id
	   left join dwh.d_opt_exec_broker opx on opx.account_id = acc.account_id and opx.is_active = 'Y' and opx.is_default = 'Y'
	   left join dwh.client_order coorig on co.orig_order_id = coorig.order_id and coorig.create_date_id = co.create_date_id
	   left join dwh.client_order_leg col on co.order_id = col.order_id
	   left join dwh.d_order_type dot on dot.order_type_id = co.order_type_id
	   left join dwh.d_time_in_force dtif on dtif.tif_id = co.time_in_force_id and dtif.is_active
	   left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = co.opt_exec_broker_id
	   left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
	   left join dwh.d_customer_or_firm dcof on dcof.customer_or_firm_id = co.customer_or_firm_id
	   left join dwh.cross_order cro on co.cross_order_id = cro.cross_order_id
	   left join lateral
	    (select sum(eq.last_qty) "DAY_CUM_QTY",
	      eq.order_id "order_id",
	      eq.exec_time::date "trade_date",
	     sum(eq.last_qty*eq.last_px)/nullif(sum(eq.last_qty),0) "DAY_AVG_PX"
	    from execution eq
	    where eq.exec_type in ('F', 'G')
	    and exec_date_id = in_date_id
	    and eq.is_busted   <> 'Y'
	    and ex.order_id = eq.order_id
	    and ex.exec_time::date  = eq.exec_time::date
	    group by eq.order_id,
	      eq.exec_time::date
	    limit 1
	    ) odcs on true
	   left join (select order_id, min(auction_id) "AuctionID" from dwh.client_order2auction where create_date_id = in_date_id  group by order_id) au on au.order_id = co.order_id
	   where ex.order_status <> '3'
	   and ex.time_in_force_id not in ('1','6')
	   and case when in_order_ids_arr <> '{}' then ex.order_id = any(in_order_ids_arr) else true end
	   and ex.exec_date_id = in_date_id;

	   analyze temp_hods;


	   raise  INFO  '%: temp table has been created',  clock_timestamp()::text;


	   insert into trash.pd_historic_order_details_storage
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
	   select HOD."OrderID",
		  HOD."ClOrdID", HOD."OrigClOrdID", HOD."OrderClass", HOD."CustomerOrderID", HOD."ExecID",
		  HOD."RefExecID", HOD."InstrumentID", HOD."Symbol", HOD."InstrumentType", HOD."MaturityYear",
		  HOD."MaturityMonth", HOD."MaturityDay", HOD."PutCall", HOD."StrikePx", HOD."OPRASymbol",
		  HOD."DisplayInstrumentID", HOD."UnderlyingDisplayInstrID", HOD."OrderCreationTime",
		  HOD."TransactTime", /*HOD."LogTime",*/ HOD."RoutedTime", HOD."OrderType", HOD."Side", HOD."OrderQty",
		  HOD."Price", HOD."StopPx", HOD."TimeInForce", HOD."ExpireTime", HOD."OpenClose", HOD."ExDestination",
		  HOD."ExDestination" as "AliasExDestination", HOD."HandlInst", HOD."MaxShowQty", HOD."MaxFloorQty",
		  HOD."ClearingFirmID", HOD."ExecBroker", HOD."CustomerOrFirm", HOD."OrderCapacity",
		  HOD."MarketParticipantID", HOD."IsLocateRequired", HOD."LocateBroker", HOD."ExecType",
		  HOD."OrderStatus", HOD."RejectReason", HOD."LeavesQty", HOD."CumQty", HOD."AvgPx", HOD."LastQty",
		  HOD."LastPx", HOD."LastMkt", HOD."DayOrderQty", HOD."DayCumQty", HOD."DayAvgPx", HOD."AccountID",
		  HOD."TradeLiquidityIndicator", HOD."MultilegReportingType", HOD."LegRefID",
		  HOD."MultilegOrderID", HOD."FixCompID", HOD."ClientID", HOD."Text",
		  HOD."IsOSROrder", HOD."OSROrderID", HOD."SubStrategy", HOD."AlgoStopPx", HOD."AlgoClOrdID", HOD."DashClOrdID", HOD."OCCOptionalData", HOD."SubSystemID",
	    HOD."TransactionID",HOD."TotNoOrdersInTransaction",HOD."ExchangeID",HOD."CrossOrderID",HOD."AggressionLevel",HOD."HiddenFlag",
	    HOD."AlgoStartTime",HOD."AlgoEndTime",HOD."ExtendedOrdType",HOD."PrimListingExchange",HOD."PreOpenBehavior",HOD."MaxWaveQtyPct",HOD."SweepStyle",HOD."DiscretionOffset",HOD."CrossType",
	    HOD."QuoteID",HOD."StepUpPriceType",HOD."StepUpPrice",HOD."CrossAccountID",HOD."AuctionID",
	    HOD."ClearingAccount", HOD."SubAccount", HOD."RequestNumber", HOD."LiquidityProviderID", HOD."InternalComponentType",
	    HOD."ComplianceID", HOD."AlternativeComplianceID", HOD."ConditionalClientOrderID", HOD."IsConditionalOrder",
	    HOD."RoutingTableEntryID", HOD."MaxVegaPerStrike", HOD."PerStrikeVegaExposure", HOD."VegaBehavior", HOD."DeltaBehavior", HOD."HedgeParamUnits", HOD."MinDelta",
	    HOD."FixCompID2",HOD."SymbolSfx",HOD."StrategyDecisionReasonCode",HOD."SessionEligibility",HOD."CreateDateID",
	    "TradeDate" as "StatusDate", in_date_id as "Status_Date_id",
			HOD."OptwapBinNumber",
			HOD."OptwapPhase",
			HOD."OptwapOrderPrice",
			HOD."OptwapBinDuration",
			HOD."OptwapBinQty",
			HOD."OptwapPhaseDuration"
		from temp_hods HOD
		inner join lateral (
	        select e.exec_id from execution e
		  	where e.order_id = HOD."OrderID"
			  and e.exec_date_id = in_date_id
	          and e.order_status <> '3'
	          order by exec_time desc, exec_id desc
	          limit 1) execs on HOD."ExecID" = execs.exec_id
	   	where HOD."TransType" <> 'F';


	   GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;

	   raise  INFO  '%:  inserted rows: %',  clock_timestamp()::text, l_row_cnt;

	   return l_row_cnt;

end
$$;

select * from trash.dash360_order_blotter_get_order_details(in_order_id := 1)
CREATE or replace FUNCTION trash.dash360_order_blotter_get_order_details(in_order_id bigint)
    RETURNS TABLE
            (
                account_id              integer,
                trading_firm_id         character varying,
                auction_id              bigint,
                order_id                bigint,
                client_order_id         character varying,
                multileg_reporting_type character varying,
                cross_order_id          bigint,
                side                    character varying,
                create_time             timestamp without time zone,
                process_time            timestamp without time zone,
                order_qty               bigint,
                price                   numeric,
                sub_strategy            character varying,
                display_instrument_id   character varying,
                instrument_type_id      character varying,
                instrument_id           bigint,
                last_trade_date         timestamp without time zone,
                customer_or_firm_id     character varying,
                clearing_firm_id        character varying,
                opt_exec_broker         character varying,
                time_in_force_id        character varying,
                open_close              character varying,
                client_id               character varying,
                ratio_qty               bigint,
                no_legs                 integer,
                co_client_leg_ref_id    character varying,
                fix_message_id          bigint,
                order_type              character varying,
                ex_destination          character varying,
                exchange_id             character varying,
                extended_ord_type       character varying,
                sweep_style             character varying,
                aggression_level        smallint,
                order_status            character varying,
                exec_qty                bigint,
                avg_px                  numeric,
                leaves_qty              integer
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
	select_stmt     text;
	sql_params      text;
	row_cnt         integer;

  l_create_date_id integer;

   l_load_id        integer;
   l_step_id        integer;

begin
  --select nextval('public.load_timing_seq') into l_load_id;
  --l_step_id:=1;

 	 --select public.load_log(l_load_id, l_step_id, 'dash360.order_blotter_get_order_details STARTED===', 0, 'O')
	 --into l_step_id;

  l_create_date_id := coalesce((select o.create_date_id from dwh.client_order o where o.order_id = in_order_id limit 1)::integer, 21010101);

  RAISE info 'l_create_date_id = % ', l_create_date_id;

  --select public.load_log(l_load_id, l_step_id, 'l_create_date_id = '|| l_create_date_id::varchar, 0, 'O')
	-- into l_step_id;



   -- form the query
   RETURN QUERY
    select co.account_id
      , tf.trading_firm_id
      , auc.auction_id
      , co.order_id
      , co.client_order_id
      , co.multileg_reporting_type::varchar
      , co.cross_order_id
      , co.side::varchar
      , co.create_time
      , co.process_time
      , co.order_qty::bigint
      , co.price
      , case  when  co.sub_strategy_desc  =  'SENSORDRK'  then  'SENSORDARK'  else  co.sub_strategy_desc  end  sub_strategy
      , i.display_instrument_id2 display_instrument_id
      , i.instrument_type_id::varchar
      , co.instrument_id
      , i.last_trade_date
      , co.customer_or_firm_id::varchar
      , co.clearing_firm_id
      --, clo.opt_exec_broker --co.opt_exec_broker_id -- !!!! should be 792 ???
      , eb.opt_exec_broker
      , co.time_in_force_id::varchar
      , co.open_close::varchar
      , co.client_id_text as client_id
      , co.ratio_qty
      , co.no_legs
      , co.co_client_leg_ref_id
      , co.fix_message_id
      , co.order_type_id::varchar as order_type --
      , co.ex_destination
      , co.exchange_id
      , co.extended_ord_type::varchar
      , co.sweep_style::varchar
      , co.aggression_level
      , ex.order_status::varchar
      , trd.exec_qty::bigint
      , trd.avg_px
      , ex.leaves_qty
      --, co.*
    from dwh.client_order co
      left join dwh.d_account ac on co.account_id = ac.account_id
      left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
      left join dwh.d_opt_exec_broker eb on co.opt_exec_broker_id = eb.opt_exec_broker_id
      left join lateral
        ( select oa.auction_id -- как вариант, еще сгруппировать все аукционы ордера
          from dwh.client_order2auction oa
          where oa.create_date_id >= l_create_date_id
            and oa.order_id = co.order_id
          order by oa.rfq_transact_time
          limit 1 -- parent OFP orders can participate in thousands of auctions
        ) auc on true
      left join dwh.d_instrument i on co.instrument_id = i.instrument_id
      left join lateral
        ( select ex.exec_text
            , ex.order_status
            , ex.exec_id
            , ex.leaves_qty
          from dwh.execution ex
          where ex.exec_date_id >= l_create_date_id -- l_order_create_date_id --
            and ex.exec_date_id >= co.create_date_id
            and ex.order_id = co.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      left join lateral
        ( select sum(tr.last_qty) as exec_qty
            , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as avg_px
            , sum(tr.principal_amount) as principal_amount
            , min(tr.trade_record_time) as first_fill_date_time
            , max(tr.trade_record_id) as max_trade_record_id
            , case when co.parent_order_id is null then tr.order_id else tr.street_order_id end as order_id
          from dwh.flat_trade_record tr
          where 1=1 -- try to calculate for both parent and street level orders
            and tr.order_id = case when co.parent_order_id is null then co.order_id else co.parent_order_id end -- trade filter by parent level for both levels of orders
            and co.order_id = case when co.parent_order_id is null then tr.order_id else tr.street_order_id end -- trade filter for street level !!!
            and tr.date_id >= l_create_date_id
            and tr.is_busted = 'N'
          group by case when co.parent_order_id is null then tr.order_id else tr.street_order_id end
          limit 1
        ) trd ON true
    where co.multileg_reporting_type in ('1','2')
      and co.create_date_id = l_create_date_id
      and co.order_id = in_order_id
    limit 10000
    ;
  	 --GET DIAGNOSTICS row_cnt = ROW_COUNT;

   --select public.load_log(l_load_id, l_step_id, 'orders returned cnt', row_cnt, 'O')
	 --into l_step_id;

 	 --select public.load_log(l_load_id, l_step_id, 'dash360.order_blotter_get_order_details COMPLETE===', 0, 'O')
	 --into l_step_id;

END;
$$;


 */

