create or replace procedure trash.get_consolidator_eod_pg_7(in_date_id int4)
--     returns int4
    language plpgsql
as
$$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg for  ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    -- Matching orders
--     call trash.match_cross_trades_pg(in_date_id);
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: match_cross_trades_pg finished',
                           0, 'O')
    into l_step_id;


    -- temp tables
    drop table if exists t_alp_agg;
    create temp table t_alp_agg as
    select lc.fix_connection_id, string_agg(distinct alp.lp_demo_mnemonic, ' ') as lp_demo_mnemonic
    from staging.lp_connection lc
             inner join staging.ats_liquidity_provider alp on alp.liquidity_provider_id = lc.liquidity_provider_id
    group by fix_connection_id;
    create index on t_alp_agg (fix_connection_id);


    drop table if exists t_clearing_account;
    create temp table t_clearing_account as
    select *
    from dwh.d_clearing_account ca
    where ca.is_default = 'Y'
      and ca.is_active
      and ca.market_type = 'O'
      and ca.clearing_account_type = '1';
    create index on t_clearing_account (account_id);
    analyze t_clearing_account;

    drop table if exists t_opt_exec_broker;
    create temp table t_opt_exec_broker as
    select * from dwh.d_opt_exec_broker opx where opx.is_default = 'Y' and opx.is_active;
    create index on t_opt_exec_broker (account_id);
    analyze t_opt_exec_broker;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: temp tables have been created',
                           0, 'O')
    into l_step_id;

    -- GTC_ORDERS

    drop table if exists trash.t_base_gtc;
    create table trash.t_base_gtc with (parallel_workers = 4) as
    select cl.order_id,
           cl.transaction_id,
           cl.create_time,
           cl.order_qty,
           cl.price,
           cl.parent_order_id,
           cl.exch_order_id,
           cl.cross_order_id,
           cl.is_originator,
           cl.orig_order_id,
           cl.client_order_id,
           cl.exchange_id                 as cl_exchange_id,
           cl.sub_strategy_id,
           cl.sub_strategy_desc,
           cl.sub_system_unq_id,
           cl.opt_exec_broker_id,
           cl.clearing_firm_id,
           cl.clearing_account,
           cl.sub_account,
           cl.open_close,
           cl.customer_or_firm_id,
           cl.opt_customer_firm_street,
           cl.eq_order_capacity,
           cl.exec_instruction,
           cl.strtg_decision_reason_code,
           cl.request_number,
           cl.order_type_id,
           cl.time_in_force_id,
           cl.multileg_reporting_type,
           cl.cons_payment_per_contract,
           cl.instrument_id,
           cl.create_date_id,
           cl.fix_connection_id,
           coalesce(cl.no_legs, 1)        as no_legs,
           cl.co_client_leg_ref_id        as leg_number,
           cl.side,
           ex.exec_id,
           ex.exec_time,
           ex.exec_type,
           ex.cum_qty,
           ex.order_status,
           ex.last_px,
           ex.last_qty,
           ex.contra_account_capacity,
           ex.trade_liquidity_indicator,
           ex.exch_exec_id,
           ex.exchange_id                 as ex_exchange_id,
           ex.contra_broker,
           ex.contra_trader,
           ex.secondary_order_id,
           ex.secondary_exch_exec_id,
           ac.trading_firm_id,
           ac.opt_is_fix_clfirm_processed,
           ac.opt_customer_or_firm,
           ac.account_id,
           opx.opt_exec_broker,
           ex.exec_date_id,
           ex.fix_message_id,
           pro.sub_strategy_desc          as pro_sub_strategy_desc,
           pro.client_order_id            as pro_client_order_id,
           pro.order_type_id              as pro_order_type_id,
           pro.time_in_force_id           as pro_time_in_force_id,
           str.cons_payment_per_contract  as str_cons_payment_per_contract,
           STR.ORDER_ID                   as STR_ORDER_ID,
           STR.CROSS_ORDER_ID             as STR_CROSS_ORDER_ID,
           STR.strtg_decision_reason_code as STR_strtg_decision_reason_code,
           STR.request_number             as STR_request_number,
           str.create_date_id             as str_create_date_id,
           case
               when cl.parent_order_id is null then cl.exch_order_id
               when ac.trading_firm_id <> 'imc01' then (select exch_order_id
                                                        from dwh.client_order
                                                        where order_id = cl.parent_order_id)
               else (select exch_order_id
                     from dwh.client_order
                     where order_id = (select max(parent_order_id)
                                       from dwh.client_order
                                       where cross_order_id = cl.cross_order_id
                                         and is_originator <> cl.is_originator))
               end                        as RFR_ID,--rfr_id
           case
               when cl.parent_order_id is null then (select orig.exch_order_id
                                                     from dwh.client_order orig
                                                     where orig.order_id = cl.orig_order_id
                                                     limit 1)
               when ac.trading_firm_id <> 'imc01' then (select orig.exch_order_id
                                                        from dwh.client_order orig
                                                                 join client_order co on co.orig_order_id = orig.order_id
                                                        where co.order_id = cl.parent_order_id
                                                        limit 1)
               else (select orig.exch_order_id
                     from dwh.client_order orig
                              join dwh.client_order co on co.orig_order_id = orig.order_id
                     where co.order_id = (select max(parent_order_id)
                                          from dwh.client_order
                                          where cross_order_id = cl.cross_order_id
                                            and is_originator <> cl.is_originator))
               end                        as ORIG_RFR_ID,--orig_rfr_id
           case
               when ex.exec_type in ('S', 'W') then orig.client_order_id
--                   (select orig.client_order_id from client_order orig where orig.order_id = tbs.orig_order_id) -- SO MOVED TO LATERAL
               end                        as REPLACED_ORDER_ID,
           case
               when ex.exec_type in ('b', '4') then cxl.client_order_id
--                   (select min(cxl.client_order_id) from client_order cxl where cxl.orig_order_id = tbs.order_id) -- SO MOVED TO LATERAL
               end                        as cancel_order_id,
           case
               when ex.EXEC_TYPE = 'F' then
                       (select LAST_QTY from EXECUTION exc where EXEC_ID = MCT.CONTRA_EXEC_ID)
               end                        as CONTRA_CROSS_EXEC_QTY,

           case
               when cl.PARENT_ORDER_ID is null and STR.CROSS_ORDER_ID is not null
                   then cc_str.contr_str
               when cl.PARENT_ORDER_ID is not null and cl.CROSS_ORDER_ID is not null
                   then cc.contr
               end                        as CONTRA_CROSS_LP_ID,
           es.FIX_MESSAGE_ID              as es_fix_message_id,
           es.exec_id                     as es_exec_id,
           case
               when ex.EXEC_TYPE = 'F' then
                   case
                       --
                       when coalesce(pro.sub_strategy_desc, cl.sub_strategy_desc) = 'DMA' then 'DMA'
                       when coalesce(pro.sub_strategy_desc, cl.sub_strategy_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(cl.REQUEST_NUMBER, STR.request_number, -1) between 0 and 99 then 'IMC'
                       when coalesce(pro.SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(cl.REQUEST_NUMBER, STR.REQUEST_NUMBER, -1) > 99 then 'Exhaust'
                       when (
                           coalesce(pro.SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                           coalesce(cl.request_number, STR.request_number, -1) = -1)
                           then
                           case
                               when coalesce(pro.ORDER_TYPE_id, cl.ORDER_TYPE_id) in ('3', '4', '5', 'B')
                                   then 'Exhaust_IMC'
                               when coalesce(pro.time_in_force_id, cl.time_in_force_id) in ('2', '7')
                                   then 'Exhaust_IMC'
                               --                               when (staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, in_date_id::text::date) is null and
--                                     staging.get_lp_list_lite_tmp(ac.ACCOUNT_ID, OS.ROOT_SYMBOL,
--                                                              case cl.MULTILEG_REPORTING_TYPE
--                                                                  when '1' then 'O'
--                                                                  when '2' then 'M' end) is null)
--                                   then 'Exhaust_IMC'
                               else 'Exhaust'
                               end
                       else 'Other'
                       --
                       end
               end                        as BILLING_CODE,
           es.contra_broker               as es_contra_broker,
           es.contra_account_capacity     as es_contra_account_capacity,
           es.contra_trader               as es_contra_trader,
           es.exchange_id                 as es_exchange_id,
           ac.account_demo_mnemonic,
           fc.acceptor_id,
-- market_data
           amex.bid_quantity              as BidSzA,
           amex.bid_price                 as BidA,
           amex.ask_price                 as AskA,
           amex.ask_quantity              as AskSzA,

           bato.bid_quantity              as BidSzZ,
           bato.bid_price                 as BidZ,
           bato.ask_price                 as AskZ,
           bato.ask_quantity              as AskSzZ,

           box.bid_quantity               as BidSzB,
           box.bid_price                  as BidB,
           box.ask_price                  as AskB,
           box.ask_quantity               as AskSzB,
--
           cboe.bid_quantity              as BidSzC,
           cboe.bid_price                 as BidC,
           cboe.ask_price                 as AskC,
           cboe.ask_quantity              as AskSzC,

           c2ox.bid_quantity              as BidSzW,
           c2ox.bid_price                 as BidW,
           c2ox.ask_price                 as AskW,
           c2ox.ask_quantity              as AskSzW,

           nqbxo.bid_quantity             as BidSzT,
           nqbxo.bid_price                as BidT,
           nqbxo.ask_price                as AskT,
           nqbxo.ask_quantity             as AskSzT,

           ise.bid_quantity               as BidSzI,
           ise.bid_price                  as BidI,
           ise.ask_price                  as AskI,
           ise.ask_quantity               as AskSzI,

           arca.bid_quantity              as BidSzP,
           arca.bid_price                 as BidP,
           arca.ask_price                 as AskP,
           arca.ask_quantity              as AskSzP,

           miax.bid_quantity              as BidSzM,
           miax.bid_price                 as BidM,
           miax.ask_price                 as AskM,
           miax.ask_quantity              as AskSzM,

           gemini.bid_quantity            as BidSzH,
           gemini.bid_price               as BidH,
           gemini.ask_price               as AskH,
           gemini.ask_quantity            as AskSzH,

           nsdqo.bid_quantity             as BidSzQ,
           nsdqo.bid_price                as BidQ,
           nsdqo.ask_price                as AskQ,
           nsdqo.ask_quantity             as AskSzQ,

           phlx.bid_quantity              as BidSzX,
           phlx.bid_price                 as BidX,
           phlx.ask_price                 as AskX,
           phlx.ask_quantity              as AskSzX,

           edgo.bid_quantity              as BidSzE,
           edgo.bid_price                 as BidE,
           edgo.ask_price                 as AskE,
           edgo.ask_quantity              as AskSzE,

           mcry.bid_quantity              as BidSzJ,
           mcry.bid_price                 as BidJ,
           mcry.ask_price                 as AskJ,
           mcry.ask_quantity              as AskSzJ,

           mprl.bid_quantity              as BidSzR,
           mprl.bid_price                 as BidR,
           mprl.ask_price                 as AskR,
           mprl.ask_quantity              as AskSzR,

           emld.bid_quantity              as BidSzD,
           emld.bid_price                 as BidD,
           emld.ask_price                 as AskD,
           emld.ask_quantity              as AskSzD,
-----
           sphr.bid_qty                   as BidSzS,
           sphr.bid_price                 as BidS,
           sphr.ask_price                 as AskS,
           sphr.ask_qty                   as AskSzS,

           mxop.bid_qty                   as BidSzU,
           mxop.bid_price                 as BidU,
           mxop.ask_price                 as AskU,
           mxop.ask_qty                   as AskSzU

    from dwh.execution ex
             inner join dwh.gtc_order_status gos
                        on gos.order_id = ex.order_id and (gos.close_date_id is null or gos.close_date_id >= in_date_id)
             inner join dwh.client_order cl on gos.create_date_id = cl.create_date_id and gos.order_id = cl.order_id
             inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
             left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = cl.opt_exec_broker_id
             left join lateral (select sub_strategy_desc, client_order_id, order_type_id, time_in_force_id
                                from dwh.client_order pro
                                where cl.parent_order_id = pro.order_id
                                  and pro.create_date_id >= cl.create_date_id
                                limit 1) pro on true
             left join dwh.client_order str
                       on (cl.order_id = str.parent_order_id and ex.secondary_order_id = str.client_order_id and
                           ex.exec_type = 'F' and str.create_date_id >= cl.create_date_id)
             left join dwh.execution es
                       on (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id and
                           es.exec_date_id >= str.create_date_id)
             left join trash.matched_cross_trades_pg mct on mct.orig_exec_id = coalesce(es.exec_id, ex.exec_id)
             left join lateral (select orig.client_order_id
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and ex.exec_type in ('S', 'W')
                                limit 1) orig on true
             left join lateral (select min(cxl.client_order_id) as client_order_id
                                from client_order cxl
                                where cxl.orig_order_id = cl.order_id
                                  and ex.exec_type in ('b', '4')
                                limit 1) cxl on true

             left join lateral (select string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr_str
--                                        t_alp.lp_demo_mnemonic as contr_str
                                from dwh.client_order constr
                                         inner join dwh.client_order pcon
                                                    on constr.parent_order_id = pcon.order_id --contra parent
                                         inner join t_alp_agg t_alp on t_alp.fix_connection_id = pcon.fix_connection_id
                                where true
                                  and cl.PARENT_ORDER_ID is null
                                  and STR.CROSS_ORDER_ID is not null
                                  and constr.cross_order_id = STR.CROSS_ORDER_ID
                                  and constr.order_id <> STR.ORDER_ID
                                  and constr.multileg_reporting_type in ('1', '3')
                                  and constr.cross_order_id is not null
                                  and constr.create_date_id = in_date_id
                                --                              and pcon.create_date_id >= 20220121
--                              group by pcon.fix_connection_id
                                limit 1) cc_str on true

             left join lateral (select string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr
--                                        t_alp.lp_demo_mnemonic as contr
                                from dwh.client_order constr
                                         inner join dwh.client_order pcon
                                                    on constr.parent_order_id = pcon.order_id --contra parent
                                         inner join t_alp_agg t_alp on t_alp.fix_connection_id = pcon.fix_connection_id
                                where true
                                  and cl.PARENT_ORDER_ID is not null
                                  and cl.CROSS_ORDER_ID is not null
                                  and constr.cross_order_id = cl.CROSS_ORDER_ID
                                  and constr.order_id <> cl.ORDER_ID
                                  and constr.multileg_reporting_type in ('1', '3')
                                  and constr.cross_order_id is not null
                                  and constr.create_date_id = in_date_id
                                limit 1) cc on true

        -- amex
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'AMEX'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) amex on true
-- bato
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'BATO'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) bato on true
-- box
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'BOX'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) box on true
-- cboe
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'CBOE'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) cboe on true
-- c2ox
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'C2OX'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) c2ox on true
-- nqbxo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'NQBXO'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) nqbxo on true
-- ise
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'ISE'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) ise on true
-- arca
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'ARCA'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) arca on true
-- miax
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MIAX'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) miax on true
-- gemini
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'GEMINI'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) gemini on true
-- nsdqo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'NSDQO'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) nsdqo on true
-- phlx
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'PHLX'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) phlx on true
-- edgo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'EDGO'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) edgo on true
-- mcry
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MCRY'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) mcry on true
-- mprl
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MPRL'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) mprl on true
-- emld
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'EMLD'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) emld on true
             left join lateral (select ls.ask_price,
                                       ls.bid_price,
                                       ls.ask_quantity as ask_qty,
                                       ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'SPHR'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) sphr on true
             left join lateral (select ls.ask_price,
                                       ls.bid_price,
                                       ls.ask_quantity as ask_qty,
                                       ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MXOP'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) mxop on true

    where ex.exec_date_id = in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and tf.is_eligible4consolidator = 'Y'
      and fc.fix_comp_id <> 'IMCCONS'
    --     and es.exec_id = any('{0,52469985240,52469985262,52469985241,52469985271,52469985155,52469985130,52469985164,52469985132,52447600067,52447600070,52447600051,52447600053,52447611732,52447611727,52447604870,52447604859,52447604872,52447604860,52447604747}')
--       and cl.client_order_id = any('{"JZ/0605/X78/262201/24123G0CVZ","JZ/3919/X63/097217/24080H1F5N ","LV/3494/X20/549258/24068IRN1H ","JZ/2731/413/241683/24017HNBLP ","JZ/3948/Z06/635197/24054HYLVV ","JZ/6443/309/110400/24053HBK7Z ","10Z2378338922248","9Z1278827287575","JZ/0465/196/276642/24155JGEIA","JZ/0496/Z06/496444/24156G0NZ4 "}')
    ;

    create index on trash.t_base_gtc (order_id);
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: GTC orders were added',
                           l_row_cnt, 'O')
    into l_step_id;

    end;
$$;



create or replace procedure trash.get_consolidator_eod_pg_8(in_date_id int4)
--     returns int4
    language plpgsql
as
$$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg for  ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    -- Matching orders
--     call trash.match_cross_trades_pg(in_date_id);
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: match_cross_trades_pg finished',
                           0, 'O')
    into l_step_id;


    -- temp tables
    drop table if exists t_alp_agg;
    create temp table t_alp_agg as
    select lc.fix_connection_id, string_agg(distinct alp.lp_demo_mnemonic, ' ') as lp_demo_mnemonic
    from staging.lp_connection lc
             inner join staging.ats_liquidity_provider alp on alp.liquidity_provider_id = lc.liquidity_provider_id
    group by fix_connection_id;
    create index on t_alp_agg (fix_connection_id);


    drop table if exists t_clearing_account;
    create temp table t_clearing_account as
    select *
    from dwh.d_clearing_account ca
    where ca.is_default = 'Y'
      and ca.is_active
      and ca.market_type = 'O'
      and ca.clearing_account_type = '1';
    create index on t_clearing_account (account_id);
    analyze t_clearing_account;

    drop table if exists t_opt_exec_broker;
    create temp table t_opt_exec_broker as
    select * from dwh.d_opt_exec_broker opx where opx.is_default = 'Y' and opx.is_active;
    create index on t_opt_exec_broker (account_id);
    analyze t_opt_exec_broker;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: temp tables have been created',
                           0, 'O')
    into l_step_id;


    drop table if exists trash.t_base;
    create table trash.t_base with (parallel_workers = 4) as
    select cl.order_id,
           cl.transaction_id,
           cl.create_time,
           cl.order_qty,
           cl.price,
           cl.parent_order_id,
           cl.exch_order_id,
           cl.cross_order_id,
           cl.is_originator,
           cl.orig_order_id,
           cl.client_order_id,
           cl.exchange_id                 as cl_exchange_id,
           cl.sub_strategy_id,
           cl.sub_strategy_desc,
           cl.sub_system_unq_id,
           cl.opt_exec_broker_id,
           cl.clearing_firm_id,
           cl.clearing_account,
           cl.sub_account,
           cl.open_close,
           cl.customer_or_firm_id,
           cl.opt_customer_firm_street,
           cl.eq_order_capacity,
           cl.exec_instruction,
           cl.strtg_decision_reason_code,
           cl.request_number,
           cl.order_type_id,
           cl.time_in_force_id,
           cl.multileg_reporting_type,
           cl.cons_payment_per_contract,
           cl.instrument_id,
           cl.create_date_id,
           cl.fix_connection_id,
           coalesce(cl.no_legs, 1)        as no_legs,
           cl.co_client_leg_ref_id        as leg_number,
           cl.side,
           ex.exec_id,
           ex.exec_time,
           ex.exec_type,
           ex.cum_qty,
           ex.order_status,
           ex.last_px,
           ex.last_qty,
           ex.contra_account_capacity,
           ex.trade_liquidity_indicator,
           ex.exch_exec_id,
           ex.exchange_id                 as ex_exchange_id,
           ex.contra_broker,
           ex.contra_trader,
           ex.secondary_order_id,
           ex.secondary_exch_exec_id,
           ac.trading_firm_id,
           ac.opt_is_fix_clfirm_processed,
           ac.opt_customer_or_firm,
           ac.account_id,
           opx.opt_exec_broker,
           ex.exec_date_id,
           ex.fix_message_id,
           pro.sub_strategy_desc          as pro_sub_strategy_desc,
           pro.client_order_id            as pro_client_order_id,
           pro.order_type_id              as pro_order_type_id,
           pro.time_in_force_id           as pro_time_in_force_id,
           str.cons_payment_per_contract  as str_cons_payment_per_contract,
           STR.ORDER_ID                   as STR_ORDER_ID,
           STR.CROSS_ORDER_ID             as STR_CROSS_ORDER_ID,
           STR.strtg_decision_reason_code as STR_strtg_decision_reason_code,
           STR.request_number             as STR_request_number,
           str.create_date_id             as str_create_date_id,
           case
               when cl.parent_order_id is null then cl.exch_order_id
               when ac.trading_firm_id <> 'imc01' then (select exch_order_id
                                                        from dwh.client_order
                                                        where order_id = cl.parent_order_id
                                                          and create_date_id = in_date_id
                                                        limit 1)
               else (select exch_order_id
                     from dwh.client_order
                     where order_id = (select max(parent_order_id)
                                       from dwh.client_order
                                       where cross_order_id = cl.cross_order_id
                                         and is_originator <> cl.is_originator
                                         and create_date_id = in_date_id)
                       and create_date_id = in_date_id
                     limit 1)
               end                        as RFR_ID,--rfr_id

           case
               when cl.parent_order_id is null then (select orig.exch_order_id
                                                     from dwh.client_order orig
                                                     where orig.order_id = cl.orig_order_id
                                                       and orig.create_date_id = in_date_id
                                                     limit 1)
               when ac.trading_firm_id <> 'imc01' then (select orig.exch_order_id
                                                        from client_order co
                                                                 join dwh.client_order orig
                                                                      on orig.order_id = co.orig_order_id
                                                                          and co.create_date_id = in_date_id
                                                        where co.order_id = cl.parent_order_id
                                                          and orig.create_date_id = in_date_id
                                                        limit 1)
               else (select orig.exch_order_id
                     from dwh.client_order orig
                              join dwh.client_order co on co.orig_order_id = orig.order_id
                     where co.order_id = (select max(parent_order_id) as max_orig_parent_order_id
                                          from dwh.client_order cr
                                          where cr.cross_order_id = cl.cross_order_id
                                            and cr.is_originator <> cl.is_originator
                                            and cr.create_date_id = in_date_id
                                          limit 1)
                       and orig.create_date_id = in_date_id
                       and co.create_date_id = in_date_id)
               end                        as ORIG_RFR_ID,--orig_rfr_id

           case
               when ex.exec_type in ('S', 'W') then orig.client_order_id
--                   (select orig.client_order_id from client_order orig where orig.order_id = tbs.orig_order_id) -- SO MOVED TO LATERAL
               end                        as REPLACED_ORDER_ID,
           case
               when ex.exec_type in ('b', '4') then cxl.client_order_id
--                   (select min(cxl.client_order_id) from client_order cxl where cxl.orig_order_id = tbs.order_id) -- SO MOVED TO LATERAL
               end                        as cancel_order_id,
           case
               when ex.EXEC_TYPE = 'F' then
                   (select LAST_QTY from EXECUTION exc where EXEC_ID = MCT.CONTRA_EXEC_ID and exec_date_id = in_date_id)
               end                        as CONTRA_CROSS_EXEC_QTY,

           case
               when cl.PARENT_ORDER_ID is null and STR.CROSS_ORDER_ID is not null
                   then cc_str.contr_str
               when cl.PARENT_ORDER_ID is not null and cl.CROSS_ORDER_ID is not null
                   then cc.contr
               end                        as CONTRA_CROSS_LP_ID,
           es.FIX_MESSAGE_ID              as es_fix_message_id,
           es.exec_id                     as es_exec_id,
           case
               when ex.EXEC_TYPE = 'F' then
                   case
                       --
                       when coalesce(pro.sub_strategy_desc, cl.sub_strategy_desc) = 'DMA' then 'DMA'
                       when coalesce(pro.sub_strategy_desc, cl.sub_strategy_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(cl.REQUEST_NUMBER, STR.request_number, -1) between 0 and 99 then 'IMC'
                       when coalesce(pro.SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(cl.REQUEST_NUMBER, STR.REQUEST_NUMBER, -1) > 99 then 'Exhaust'
                       when (
                           coalesce(pro.SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                           coalesce(cl.request_number, STR.request_number, -1) = -1)
                           then
                           case
                               when coalesce(pro.ORDER_TYPE_id, cl.ORDER_TYPE_id) in ('3', '4', '5', 'B')
                                   then 'Exhaust_IMC'
                               when coalesce(pro.time_in_force_id, cl.time_in_force_id) in ('2', '7')
                                   then 'Exhaust_IMC'
                               --                               when (staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, in_date_id::text::date) is null and
--                                     staging.get_lp_list_lite_tmp(ac.ACCOUNT_ID, OS.ROOT_SYMBOL,
--                                                              case cl.MULTILEG_REPORTING_TYPE
--                                                                  when '1' then 'O'
--                                                                  when '2' then 'M' end) is null)
--                                   then 'Exhaust_IMC'
                               else 'Exhaust'
                               end
                       else 'Other'
                       --
                       end
               end                        as BILLING_CODE,
           es.contra_broker               as es_contra_broker,
           es.contra_account_capacity     as es_contra_account_capacity,
           es.contra_trader               as es_contra_trader,
           es.exchange_id                 as es_exchange_id,
           ac.account_demo_mnemonic,
           fc.acceptor_id,

           amex.bid_quantity              as BidSzA,
           amex.bid_price                 as BidA,
           amex.ask_price                 as AskA,
           amex.ask_quantity              as AskSzA,

           bato.bid_quantity              as BidSzZ,
           bato.bid_price                 as BidZ,
           bato.ask_price                 as AskZ,
           bato.ask_quantity              as AskSzZ,

           box.bid_quantity               as BidSzB,
           box.bid_price                  as BidB,
           box.ask_price                  as AskB,
           box.ask_quantity               as AskSzB,
--
           cboe.bid_quantity              as BidSzC,
           cboe.bid_price                 as BidC,
           cboe.ask_price                 as AskC,
           cboe.ask_quantity              as AskSzC,

           c2ox.bid_quantity              as BidSzW,
           c2ox.bid_price                 as BidW,
           c2ox.ask_price                 as AskW,
           c2ox.ask_quantity              as AskSzW,

           nqbxo.bid_quantity             as BidSzT,
           nqbxo.bid_price                as BidT,
           nqbxo.ask_price                as AskT,
           nqbxo.ask_quantity             as AskSzT,

           ise.bid_quantity               as BidSzI,
           ise.bid_price                  as BidI,
           ise.ask_price                  as AskI,
           ise.ask_quantity               as AskSzI,

           arca.bid_quantity              as BidSzP,
           arca.bid_price                 as BidP,
           arca.ask_price                 as AskP,
           arca.ask_quantity              as AskSzP,

           miax.bid_quantity              as BidSzM,
           miax.bid_price                 as BidM,
           miax.ask_price                 as AskM,
           miax.ask_quantity              as AskSzM,

           gemini.bid_quantity            as BidSzH,
           gemini.bid_price               as BidH,
           gemini.ask_price               as AskH,
           gemini.ask_quantity            as AskSzH,

           nsdqo.bid_quantity             as BidSzQ,
           nsdqo.bid_price                as BidQ,
           nsdqo.ask_price                as AskQ,
           nsdqo.ask_quantity             as AskSzQ,

           phlx.bid_quantity              as BidSzX,
           phlx.bid_price                 as BidX,
           phlx.ask_price                 as AskX,
           phlx.ask_quantity              as AskSzX,

           edgo.bid_quantity              as BidSzE,
           edgo.bid_price                 as BidE,
           edgo.ask_price                 as AskE,
           edgo.ask_quantity              as AskSzE,

           mcry.bid_quantity              as BidSzJ,
           mcry.bid_price                 as BidJ,
           mcry.ask_price                 as AskJ,
           mcry.ask_quantity              as AskSzJ,

           mprl.bid_quantity              as BidSzR,
           mprl.bid_price                 as BidR,
           mprl.ask_price                 as AskR,
           mprl.ask_quantity              as AskSzR,

           emld.bid_quantity              as BidSzD,
           emld.bid_price                 as BidD,
           emld.ask_price                 as AskD,
           emld.ask_quantity              as AskSzD,
-----
           sphr.bid_qty                   as BidSzS,
           sphr.bid_price                 as BidS,
           sphr.ask_price                 as AskS,
           sphr.ask_qty                   as AskSzS,

           mxop.bid_qty                   as BidSzU,
           mxop.bid_price                 as BidU,
           mxop.ask_price                 as AskU,
           mxop.ask_qty                   as AskSzU
    from dwh.execution ex
             inner join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = in_date_id
             inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)


             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
             left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = cl.opt_exec_broker_id
             left join lateral (select sub_strategy_desc, client_order_id, order_type_id, time_in_force_id
                                from dwh.client_order pro
                                where cl.parent_order_id = pro.order_id
                                  and pro.create_date_id = in_date_id
                                limit 1) pro on true
             left join dwh.client_order str
                       on (cl.order_id = str.parent_order_id and ex.secondary_order_id = str.client_order_id and
                           ex.exec_type = 'F' and str.create_date_id >= cl.create_date_id
                           and str.create_date_id = in_date_id)
             left join dwh.execution es
                       on (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id and
                           es.exec_date_id >= str.create_date_id and es.exec_date_id = in_date_id)
             left join trash.matched_cross_trades_pg mct on mct.orig_exec_id = coalesce(es.exec_id, ex.exec_id)
             left join lateral (select orig.client_order_id
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and ex.exec_type in ('S', 'W')
                                  and orig.create_date_id = in_date_id
                                limit 1) orig on true
             left join lateral (select min(cxl.client_order_id) as client_order_id
                                from client_order cxl
                                where cxl.orig_order_id = cl.order_id
                                  and ex.exec_type in ('b', '4')
                                  and cxl.create_date_id = in_date_id
                                limit 1) cxl on true

             left join lateral (select string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr_str
--                                        t_alp.lp_demo_mnemonic as contr_str
                                from dwh.client_order constr
                                         inner join dwh.client_order pcon
                                                    on constr.parent_order_id = pcon.order_id --contra parent
                                         inner join t_alp_agg t_alp on t_alp.fix_connection_id = pcon.fix_connection_id
                                where true
                                  and cl.PARENT_ORDER_ID is null
                                  and STR.CROSS_ORDER_ID is not null
                                  and constr.cross_order_id = STR.CROSS_ORDER_ID
                                  and constr.order_id <> STR.ORDER_ID
                                  and constr.multileg_reporting_type in ('1', '3')
                                  and constr.cross_order_id is not null
                                  and constr.create_date_id = in_date_id
                                  and pcon.create_date_id = in_date_id
--                              group by pcon.fix_connection_id
                                limit 1) cc_str on true

             left join lateral (select string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr
--                                        t_alp.lp_demo_mnemonic as contr
                                from dwh.client_order constr
                                         inner join dwh.client_order pcon
                                                    on constr.parent_order_id = pcon.order_id --contra parent
                                         inner join t_alp_agg t_alp on t_alp.fix_connection_id = pcon.fix_connection_id
                                where true
                                  and cl.PARENT_ORDER_ID is not null
                                  and cl.CROSS_ORDER_ID is not null
                                  and constr.cross_order_id = cl.CROSS_ORDER_ID
                                  and constr.order_id <> cl.ORDER_ID
                                  and constr.multileg_reporting_type in ('1', '3')
                                  and constr.cross_order_id is not null
                                  and constr.create_date_id = in_date_id
                                  and pcon.create_date_id = in_date_id
--                              group by pcon.fix_connection_id
                                limit 1) cc on true
        -- amex
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'AMEX'
                                  and ls.start_date_id = in_date_id
        ) amex on true
-- bato
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'BATO'
                                  and ls.start_date_id = in_date_id
        ) bato on true
-- box
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'BOX'
                                  and ls.start_date_id = in_date_id
        ) box on true
-- cboe
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'CBOE'
                                  and ls.start_date_id = in_date_id
        ) cboe on true
-- c2ox
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'C2OX'
                                  and ls.start_date_id = in_date_id
        ) c2ox on true
-- nqbxo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'NQBXO'
                                  and ls.start_date_id = in_date_id
        ) nqbxo on true
-- ise
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'ISE'
                                  and ls.start_date_id = in_date_id
        ) ise on true
-- arca
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'ARCA'
                                  and ls.start_date_id = in_date_id
        ) arca on true
-- miax
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MIAX'
                                  and ls.start_date_id = in_date_id
        ) miax on true
-- gemini
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'GEMINI'
                                  and ls.start_date_id = in_date_id
        ) gemini on true
-- nsdqo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'NSDQO'
                                  and ls.start_date_id = in_date_id
        ) nsdqo on true
-- phlx
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'PHLX'
                                  and ls.start_date_id = in_date_id
        ) phlx on true
-- edgo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'EDGO'
                                  and ls.start_date_id = in_date_id
        ) edgo on true
-- mcry
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MCRY'
                                  and ls.start_date_id = in_date_id
        ) mcry on true
-- mprl
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MPRL'
                                  and ls.start_date_id = in_date_id
        ) mprl on true
-- emld
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'EMLD'
                                  and ls.start_date_id = in_date_id
        ) emld on true
             left join lateral (select ls.ask_price,
                                       ls.bid_price,
                                       ls.ask_quantity as ask_qty,
                                       ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'SPHR'
                                  and ls.start_date_id = in_date_id
        ) sphr on true
             left join lateral (select ls.ask_price,
                                       ls.bid_price,
                                       ls.ask_quantity as ask_qty,
                                       ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MXOP'
                                  and ls.start_date_id = in_date_id
        ) mxop on true
    where ex.exec_date_id = in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and tf.is_eligible4consolidator = 'Y'
      and fc.fix_comp_id <> 'IMCCONS'
    --       and cl.client_order_id = any('{"JZ/0605/X78/262201/24123G0CVZ","JZ/3919/X63/097217/24080H1F5N ","LV/3494/X20/549258/24068IRN1H ","JZ/2731/413/241683/24017HNBLP ","JZ/3948/Z06/635197/24054HYLVV ","JZ/6443/309/110400/24053HBK7Z ","10Z2378338922248","9Z1278827287575","JZ/0465/196/276642/24155JGEIA","JZ/0496/Z06/496444/24156G0NZ4 "}')
      and not exists (select null from trash.t_base_gtc gtc where gtc.order_id = ex.order_id and gtc.exec_id = ex.exec_id)
    ;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: NON GTC orders were added',
                           l_row_cnt, 'O')
    into l_step_id;

        end;
$$;


create or replace procedure trash.get_consolidator_eod_pg_9(in_date_id int4)
--     returns int4
    language plpgsql
as
$$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg for  ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    -- Matching orders
--     call trash.match_cross_trades_pg(in_date_id);
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: match_cross_trades_pg finished',
                           0, 'O')
    into l_step_id;


    -- temp tables


    drop table if exists t_clearing_account;
    create temp table t_clearing_account as
    select *
    from dwh.d_clearing_account ca
    where ca.is_default = 'Y'
      and ca.is_active
      and ca.market_type = 'O'
      and ca.clearing_account_type = '1';
    create index on t_clearing_account (account_id);
    analyze t_clearing_account;

    drop table if exists t_opt_exec_broker;
    create temp table t_opt_exec_broker as
    select * from dwh.d_opt_exec_broker opx where opx.is_default = 'Y' and opx.is_active;
    create index on t_opt_exec_broker (account_id);
    analyze t_opt_exec_broker;

    drop table if exists t_wht;
    create temp table t_wht as (select ss.symbol, clp.instrument_type_id
                                from staging.symbol2lp_symbol_list ss
                                         inner join staging.cons_lp_symbol_list clp
                                                    on clp.lp_symbol_list_id = ss.lp_symbol_list_id
                                where clp.liquidity_provider_id = 'IMC');

    drop table if exists t_blk;
    create temp table t_blk as
        (select ss.symbol, clp.instrument_type_id
         from staging.symbol2lp_symbol_list ss
                  inner join staging.cons_lp_symbol_black_list clp
                             on clp.lp_symbol_list_id = ss.lp_symbol_list_id
         where clp.liquidity_provider_id = 'IMC');
    analyze t_wht;
    analyze t_blk;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: temp tables have been created',
                           0, 'O')
    into l_step_id;

    drop table if exists trash.so_imc_base;
    create table trash.so_imc_base as
    select order_id,
           transaction_id,
           create_time,
           order_qty,
           price,
           parent_order_id,
           exch_order_id,
           cross_order_id,
           is_originator,
           orig_order_id,
           client_order_id,
           cl_exchange_id,
           sub_strategy_id,
           sub_strategy_desc,
           sub_system_unq_id,
           opt_exec_broker_id,
           clearing_firm_id,
           clearing_account,
           sub_account,
           open_close,
           customer_or_firm_id,
           opt_customer_firm_street,
           eq_order_capacity,
           exec_instruction,
           strtg_decision_reason_code,
           request_number,
           order_type_id,
           time_in_force_id,
           multileg_reporting_type,
           cons_payment_per_contract,
           instrument_id,
           create_date_id,
           fix_connection_id,
           no_legs,
           leg_number,
           side,
           exec_id,
           exec_time,
           exec_type,
           cum_qty,
           order_status,
           last_px,
           last_qty,
           contra_account_capacity,
           trade_liquidity_indicator,
           exch_exec_id,
           ex_exchange_id,
           contra_broker,
           contra_trader,
           secondary_order_id,
           secondary_exch_exec_id,
           trading_firm_id,
           opt_is_fix_clfirm_processed,
           opt_customer_or_firm,
           account_id,
           opt_exec_broker,
           exec_date_id,
           fix_message_id,
           pro_sub_strategy_desc,
           pro_client_order_id,
           pro_order_type_id,
           pro_time_in_force_id,
           str_cons_payment_per_contract,
           str_order_id,
           str_cross_order_id,
           str_strtg_decision_reason_code,
           str_request_number,
           str_create_date_id,
           rfr_id,
           orig_rfr_id,
           replaced_order_id,
           cancel_order_id,
           contra_cross_exec_qty,
           contra_cross_lp_id,
           es_fix_message_id,
           es_exec_id,
           billing_code,
           es_contra_broker,
           es_contra_account_capacity,
           es_contra_trader,
           es_exchange_id,
           account_demo_mnemonic,
           acceptor_id,
           bidsza,
           bida,
           aska,
           asksza,
           bidszz,
           bidz,
           askz,
           askszz,
           bidszb,
           bidb,
           askb,
           askszb,
           bidszc,
           bidc,
           askc,
           askszc,
           bidszw,
           bidw,
           askw,
           askszw,
           bidszt,
           bidt,
           askt,
           askszt,
           bidszi,
           bidi,
           aski,
           askszi,
           bidszp,
           bidp,
           askp,
           askszp,
           bidszm,
           bidm,
           askm,
           askszm,
           bidszh,
           bidh,
           askh,
           askszh,
           bidszq,
           bidq,
           askq,
           askszq,
           bidszx,
           bidx,
           askx,
           askszx,
           bidsze,
           bide,
           aske,
           asksze,
           bidszj,
           bidj,
           askj,
           askszj,
           bidszr,
           bidr,
           askr,
           askszr,
           bidszd,
           bidd,
           askd,
           askszd,
           bidszs,
           bids,
           asks,
           askszs,
           bidszu,
           bidu,
           asku,
           askszu
    from trash.t_base_gtc;

    insert into trash.so_imc_base
    select order_id,
           transaction_id,
           create_time,
           order_qty,
           price,
           parent_order_id,
           exch_order_id,
           cross_order_id,
           is_originator,
           orig_order_id,
           client_order_id,
           cl_exchange_id,
           sub_strategy_id,
           sub_strategy_desc,
           sub_system_unq_id,
           opt_exec_broker_id,
           clearing_firm_id,
           clearing_account,
           sub_account,
           open_close,
           customer_or_firm_id,
           opt_customer_firm_street,
           eq_order_capacity,
           exec_instruction,
           strtg_decision_reason_code,
           request_number,
           order_type_id,
           time_in_force_id,
           multileg_reporting_type,
           cons_payment_per_contract,
           instrument_id,
           create_date_id,
           fix_connection_id,
           no_legs,
           leg_number,
           side,
           exec_id,
           exec_time,
           exec_type,
           cum_qty,
           order_status,
           last_px,
           last_qty,
           contra_account_capacity,
           trade_liquidity_indicator,
           exch_exec_id,
           ex_exchange_id,
           contra_broker,
           contra_trader,
           secondary_order_id,
           secondary_exch_exec_id,
           trading_firm_id,
           opt_is_fix_clfirm_processed,
           opt_customer_or_firm,
           account_id,
           opt_exec_broker,
           exec_date_id,
           fix_message_id,
           pro_sub_strategy_desc,
           pro_client_order_id,
           pro_order_type_id,
           pro_time_in_force_id,
           str_cons_payment_per_contract,
           str_order_id,
           str_cross_order_id,
           str_strtg_decision_reason_code,
           str_request_number,
           str_create_date_id,
           rfr_id,
           orig_rfr_id,
           replaced_order_id,
           cancel_order_id,
           contra_cross_exec_qty,
           contra_cross_lp_id,
           es_fix_message_id,
           es_exec_id,
           billing_code,
           es_contra_broker,
           es_contra_account_capacity,
           es_contra_trader,
           es_exchange_id,
           account_demo_mnemonic,
           acceptor_id,
           bidsza,
           bida,
           aska,
           asksza,
           bidszz,
           bidz,
           askz,
           askszz,
           bidszb,
           bidb,
           askb,
           askszb,
           bidszc,
           bidc,
           askc,
           askszc,
           bidszw,
           bidw,
           askw,
           askszw,
           bidszt,
           bidt,
           askt,
           askszt,
           bidszi,
           bidi,
           aski,
           askszi,
           bidszp,
           bidp,
           askp,
           askszp,
           bidszm,
           bidm,
           askm,
           askszm,
           bidszh,
           bidh,
           askh,
           askszh,
           bidszq,
           bidq,
           askq,
           askszq,
           bidszx,
           bidx,
           askx,
           askszx,
           bidsze,
           bide,
           aske,
           asksze,
           bidszj,
           bidj,
           askj,
           askszj,
           bidszr,
           bidr,
           askr,
           askszr,
           bidszd,
           bidd,
           askd,
           askszd,
           bidszs,
           bids,
           asks,
           askszs,
           bidszu,
           bidu,
           asku,
           askszu
    from trash.t_base;
    analyze trash.so_imc_base;

    select count(*) into l_row_cnt from trash.so_imc_base;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: imc_base is ready',
                           l_row_cnt, 'O')
    into l_step_id;

    -- MAIN PART
    drop table if exists trash.so_imc_main;
    create table trash.so_imc_main as
    with white as (select symbol, instrument_type_id from t_wht)
       , black as (select symbol, instrument_type_id from t_blk)
    select tbs.transaction_id,
           tbs.exec_id,
           tbs.trading_firm_id,                                                                                                  --entitycode
           tbs.create_time,
           tbs.exec_time,
           oc.opra_symbol,                                                                                                       --osi
           case i.instrument_type_id
               when 'E' then i.symbol
               when 'O'
                   then ui.symbol end                                                                  as base_code,
           case i.instrument_type_id
               when 'E' then i.symbol
               when 'O'
                   then os.root_symbol end                                                             as root_symbol,
           case ui.instrument_type_id when 'E' then 'EQUITY' when 'I' then 'INDEX' end                 as base_asset_type,
           --
           to_char(oc.maturity_year, 'FM0000') || to_char(oc.maturity_month, 'FM00') ||
           to_char(oc.maturity_day, 'FM00')                                                            as expiration_date,
           oc.strike_price,
           case oc.put_call when '0' then 'P' when '1' then 'C' else 'S' end                           as type_code,
           case tbs.side when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SS' end as SIDE,
-- 		NVL((select CO_NO_LEGS from CLIENT_ORDER where ORDER_ID = tbs.CO_MULTILEG_ORDER_ID),1), --LEG_COUNT
           tbs.no_legs,                                                                                                          --LEG_COUNT ???
           tbs.leg_number,
           case
               when tbs.exec_type = '4' then 'Canceled'
               when tbs.exec_type = '5' then 'Replaced'
               when tbs.exec_type = 'F' and tbs.order_status = '6' then
                   case
                       when tbs.cum_qty = tbs.order_qty then 'Filled'
                       else 'Partial Fill'
                       end
               when tbs.order_status = 'A' then 'Pending New'
               when tbs.order_status = '0' then 'New'
               when tbs.order_status = '8' then 'Rejected'
               when tbs.order_status = 'a' then 'Pending Replace'
               when tbs.order_status = 'b' then 'Pending Cancel'
               when tbs.order_status = '1' then 'Partial Fill'
               when tbs.order_status = '2' then 'Filled'
               when tbs.order_status = '3' then 'Done For Day'
               else tbs.order_status end                                                               as ORD_STATUS,
           tbs.price,
           tbs.last_px,
           tbs.order_qty,                                                                                                        --entered qty
           -- ask++
           tbs.last_qty,                                                                                                         --statusqty


           tbs.RFR_ID,--rfr_id
           tbs.ORIG_RFR_ID,--orig_rfr_id
           tbs.client_order_id,

           tbs.REPLACED_ORDER_ID,
           tbs.cancel_order_id,

           tbs.pro_client_order_id                                                                     as parent_client_order_id,
           tbs.order_id,                                                                                                         --systemorderid
           case
               when tbs.cl_exchange_id = 'ALGOWX' then 'WEX_SWEEP'
               else coalesce(tbs.sub_strategy_desc, exc.mic_code)
               end                                                                                     as exchange_code,

           case
               when tbs.parent_order_id is null then tbs.acceptor_id
               when dss.sub_system_id like '%CONS%' then 'CONS'
               when dss.sub_system_id like '%OSR%' then 'SOR'
               when dss.sub_system_id like '%ATLAS%' or dss.sub_system_id like '%ATS%' then 'ATS'
               else dss.sub_system_id
               end                                                                                     as EX_CONNECTION,


           coalesce(tbs.opt_exec_broker, opx.opt_exec_broker)                                          as give_up_firm,
           case
               when tbs.opt_is_fix_clfirm_processed = 'Y' then tbs.clearing_firm_id
               else coalesce(lpad(ca.cmta, 3, '0'), tbs.clearing_firm_id)
               end                                                                                     as cmta_firm,
           tbs.clearing_account,
           tbs.sub_account,
           tbs.open_close,
           case
               when (tbs.parent_order_id is null or tbs.customer_or_firm_id is not null)
                   then case coalesce(tbs.customer_or_firm_id, tbs.opt_customer_or_firm)
                            when '0' then 'CUST'
                            when '1' then 'FIRM'
                            when '2' then 'BD'
                            when '3' then 'BD-CUST'
                            when '4' then 'MM'
                            when '5' then 'AMM'
                            when '7' then 'BD-FIRM'
                            when '8' then 'CUST-PRO'
                            when 'J' then 'JBO' end
               else coalesce(tbs.customer_or_firm_id, tbs.eq_order_capacity, tbs.opt_customer_firm_street)
               end                                                                                     as RANGE,
           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.parent_order_id is not null then tbs.contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
           ot.order_type_short_name,
           tif.tif_short_name,                                                                                                   -- TIME_IN_FORCE
           tbs.exec_instruction,                                                                                                 -- EXEC_INST
           tbs.trade_liquidity_indicator,

           tbs.exch_exec_id,
           tbs.exch_order_id,
           tbs.cross_order_id,
           case
               when tbs.REQUEST_NUMBER >= 99 then ''
               else tbs.REQUEST_NUMBER::text
               end                                                                                     as REQUEST_COUNT,

--           tbs.BILLING_CODE,


           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.PARENT_ORDER_ID is not null and tbs.ex_exchange_id = 'CBOE'
                           then ltrim(tbs.CONTRA_BROKER, 'CBOE:')
                       when tbs.PARENT_ORDER_ID is not null then tbs.CONTRA_BROKER
                       when tbs.PARENT_ORDER_ID is null and tbs.es_exchange_id = 'CBOE'
                           then ltrim(tbs.ES_CONTRA_BROKER, 'CBOE:')
                       when tbs.PARENT_ORDER_ID is null then tbs.ES_CONTRA_BROKER end
               end                                                                                     as CONTRA_BROKER,

           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.PARENT_ORDER_ID is not null then tbs.CONTRA_TRADER
                       else tbs.ES_CONTRA_TRADER
                       end
               end                                                                                     as CONTRA_TRADER,

           case
               when case I.INSTRUMENT_TYPE_ID when 'E' then I.SYMBOL when 'O' then OS.ROOT_SYMBOL end in
                    (select SYMBOL
                     from black
                     where INSTRUMENT_TYPE_ID = case when tbs.multileg_reporting_type = '1' then 'O' else 'M' end)
                   then 'N'
               when case I.INSTRUMENT_TYPE_ID when 'E' then I.SYMBOL when 'O' then OS.ROOT_SYMBOL end in
                    (select SYMBOL
                     from white
                     where INSTRUMENT_TYPE_ID = case when tbs.multileg_reporting_type = '1' then 'O' else 'M' end)
                   then 'Y'
               when (select count(*)
                     from white
                     where INSTRUMENT_TYPE_ID = case when tbs.multileg_reporting_type = '1' then 'O' else 'M' end) = 0
                   then 'Y'
               else 'N'
               end                                                                                     as white_list,            --WHITE_LIST
           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.parent_order_id is not null then tbs.cons_payment_per_contract
                       else tbs.STR_cons_payment_per_contract
                       end
               end                                                                                     as cons_payment_per_contract,
           tbs.CONTRA_CROSS_EXEC_QTY,

           --getContraCrossLPID(NVL(tbs.STR_ORDER_ID,CL.ORDER_ID))-- ALP.LP_DEMO_MNEMONIC

           CONTRA_CROSS_LP_ID,

           coalesce(tbs.strtg_decision_reason_code,
                    tbs.STR_strtg_decision_reason_code)                                                as STRATEGY_DECISION_REASON_CODE,
           cro.CROSS_TYPE,
           tbs.fix_message_id                                                                          as parent_fix_message_id, -- ex.fix_message_id parent order
           tbs.es_FIX_MESSAGE_ID,
           tbs.ex_exchange_id,
           tbs.cl_exchange_id,
           tbs.es_exec_id,

           tbs.ACCOUNT_ID,
           I.SYMBOL,
           OS.ROOT_SYMBOL                                                                              as os_ROOT_SYMBOL,
           case tbs.MULTILEG_REPORTING_TYPE
               when '1' then 'O'
               when '2'
                   then 'M' end                                                                        as instrument_type,
           tbs.BILLING_CODE,
           tbs.account_demo_mnemonic,
           bidsza,
           bida,
           aska,
           asksza,
           bidszz,
           bidz,
           askz,
           askszz,
           bidszb,
           bidb,
           askb,
           askszb,
           bidszc,
           bidc,
           askc,
           askszc,
           bidszw,
           bidw,
           askw,
           askszw,
           bidszt,
           bidt,
           askt,
           askszt,
           bidszi,
           bidi,
           aski,
           askszi,
           bidszp,
           bidp,
           askp,
           askszp,
           bidszm,
           bidm,
           askm,
           askszm,
           bidszh,
           bidh,
           askh,
           askszh,
           bidszq,
           bidq,
           askq,
           askszq,
           bidszx,
           bidx,
           askx,
           askszx,
           bidsze,
           bide,
           aske,
           asksze,
           bidszj,
           bidj,
           askj,
           askszj,
           bidszr,
           bidr,
           askr,
           askszr,
           bidszd,
           bidd,
           askd,
           askszd,
           bidszs,
           bids,
           asks,
           askszs,
           bidszu,
           bidu,
           asku,
           askszu
    from trash.so_imc_base tbs
             inner join dwh.d_instrument i on i.instrument_id = tbs.instrument_id
--              inner join dwh.d_fix_connection fc on (fc.fix_connection_id = tbs.fix_connection_id)
             left join dwh.cross_order cro on cro.cross_order_id = tbs.cross_order_id
             left join dwh.d_exchange exc on exc.exchange_id = tbs.cl_exchange_id and exc.is_active
             left join dwh.d_option_contract oc on (oc.instrument_id = tbs.instrument_id)
             left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
             left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id


             left join t_clearing_account ca
                       on tbs.account_id = ca.account_id-- and ca.is_default = 'Y' and ca.is_active and ca.market_type = 'O' and ca.clearing_account_type = '1')
             left join t_opt_exec_broker opx on opx.account_id = tbs.account_id-- and opx.is_default = 'Y' and opx.is_active)
             left join dwh.d_order_type ot on ot.order_type_id = tbs.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = tbs.time_in_force_id
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = tbs.sub_system_unq_id
    where true;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: main db is ready',
                           l_row_cnt, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: COMPLETED===',
                           l_row_cnt, 'O')
    into l_step_id;
--     return l_row_cnt;
end;
$$;

create or replace function trash.get_consolidator_eod_pg_6(in_date_id int4)
    returns int4
    language plpgsql
as
$$
declare
    l_load_id            int;
    l_row_cnt            int;
    l_step_id            int;


begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg for  ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;


    -- REPORT TABLE
    drop table if exists trash.imc_pg_report;
    create table trash.imc_pg_report as
    select cl.transaction_id,
           cl.order_id,
           cl.exec_id,
           cl.trading_firm_id || ',' || --EntityCode
           to_char(cl.create_time, 'YYYYMMDD') || ',' || --CreateDate
           to_char(cl.create_time, 'HH24MISSFF3') || ',' || --CreateTime
           to_char(cl.exec_time, 'YYYYMMDD') || ',' || --StatusDate
           to_char(cl.exec_time, 'HH24MISSFF3') || ',' || --StatusTime
           coalesce(cl.opra_symbol, '') || ',' || --OSI
           coalesce(cl.base_code, '') || ',' ||--BaseCode
           coalesce(cl.root_symbol, '') || ',' || --Root
           coalesce(cl.base_asset_type, '') || ',' ||
               --
           coalesce(cl.expiration_date, '') || ',' ||
           coalesce(staging.trailing_dot(cl.strike_price), '') || ',' ||
           coalesce(cl.type_code, '') || ',' || -- (S - stock)
           coalesce(cl.side, '') || ',' ||
           coalesce(cl.no_legs::text, '') || ',' || --LegCount
           coalesce(cl.leg_number::text, '') || ',' || --LegNumber
           '' || ',' || --OrderType
           coalesce(cl.ord_status, '') || ',' ||
           coalesce(to_char(cl.price, 'FM999990D0099'), '') || ',' ||
           coalesce(to_char(cl.last_px, 'FM999990D0099'), '') || ',' || --StatusPrice
           coalesce(cl.order_qty::text, '') || ',' || --EnteredQty
-- ask++
           coalesce(cl.last_qty::text, '') || ',' || --StatusQty
           coalesce(cl.rfr_id, '') || ',' ||--RFRID
           coalesce(cl.orig_rfr_id, '') || ',' ||--OrigRFRID
           coalesce(cl.client_order_id, '') || ',' ||
           coalesce(cl.replaced_order_id, '') || ',' || --Replaced Order
           coalesce(cl.cancel_order_id, '') || ',' || --CancelOrderID
           coalesce(cl.parent_client_order_id, '') || ',' ||
           coalesce(cl.order_id::text, '') || ',' || --SystemOrderID
           coalesce(cl.exchange_code, '') || ',' || --ExchangeCode
           coalesce(cl.ex_connection, '') || ',' || --ExConnection
           coalesce(cl.give_up_firm, '') || ',' ||--GiveUpFirm
           coalesce(cl.cmta_firm, '') || ',' || --CMTAFirm
           coalesce(cl.clearing_account, '') || ',' || --Account
           coalesce(cl.sub_account, '') || ',' || --SubAccount
           coalesce(cl.open_close, '') || ',' ||
           coalesce(cl.range, '') || ',' || --Range
--EX.CONTRA_ACCOUNT_CAPACITY
--		coalesce(cl.counterparty_range, '')||','||
           coalesce(case ascii(cl.counterparty_range) when 0 then repeat(' ', 1) else cl.counterparty_range end,
                    '') || ',' ||
           coalesce(cl.order_type_short_name, '') || ',' || --PriceQualifier
           coalesce(cl.tif_short_name, '') || ',' || --TimeQualifier
           coalesce(cl.exec_instruction, '') || ',' || --ExecInst
-- The next row was changed within https://dashfinancial.atlassian.net/browse/DEVREQ-3278
           coalesce(staging.get_trade_liquidity_indicator(cl.trade_liquidity_indicator), '') || ',' || --Maker/Take
           coalesce(cl.exch_exec_id, '') || ',' || --ExchangeTransactionID
           coalesce(cl.exch_order_id, '') || ',' || --ExchangeOrderID

           coalesce(BidSzA::text, '') || ',' || --BidSzA
           coalesce(to_char(BidA, 'FM999999.0099'), '') || ',' || --BidA
           coalesce(to_char(AskA, 'FM999999.0099'), '') || ',' || --AskA
           coalesce(AskSzA::text, '') || ',' || --AskSzA

           coalesce(BidSzZ::text, '') || ',' || --BidSzZ
           coalesce(to_char(BidZ, 'FM999999.0099'), '') || ',' || --BidZ
           coalesce(to_char(AskZ, 'FM999999.0099'), '') || ',' || --AskZ
           coalesce(AskSzZ::text, '') || ',' || --AskSzZ

           coalesce(BidSzB::text, '') || ',' || --BidSzB
           coalesce(to_char(BidB, 'FM999999.0099'), '') || ',' || --BidB
           coalesce(to_char(AskB, 'FM999999.0099'), '') || ',' || --AskB
           coalesce(AskSzB::text, '') || ',' || --AskSzB
--
           coalesce(BidSzC::text, '') || ',' || --BidSzC
           coalesce(to_char(BidC, 'FM999999.0099'), '') || ',' || --BidC
           coalesce(to_char(AskC, 'FM999999.0099'), '') || ',' || --AskC
           coalesce(AskSzC::text, '') || ',' || --AskSzC

           coalesce(BidSzW::text, '') || ',' || --BidSzW
           coalesce(to_char(BidW, 'FM999999.0099'), '') || ',' || --BidW
           coalesce(to_char(AskW, 'FM999999.0099'), '') || ',' || --AskW
           coalesce(AskSzW::text, '') || ',' || --AskSzW

           coalesce(BidSzT::text, '') || ',' || --BidSzT
           coalesce(to_char(BidT, 'FM999999.0099'), '') || ',' || --BidT
           coalesce(to_char(AskT, 'FM999999.0099'), '') || ',' || --AskT
           coalesce(AskSzT::text, '') || ',' || --AskSzT

           coalesce(BidSzI::text, '') || ',' || --BidSzI
           coalesce(to_char(BidI, 'FM999999.0099'), '') || ',' || --BidI
           coalesce(to_char(AskI, 'FM999999.0099'), '') || ',' || --AskI
           coalesce(AskSzI::text, '') || ',' || --AskSzI

           coalesce(BidSzP::text, '') || ',' || --BidSzP
           coalesce(to_char(BidP, 'FM999999.0099'), '') || ',' || --BidP
           coalesce(to_char(AskP, 'FM999999.0099'), '') || ',' || --AskP
           coalesce(AskSzP::text, '') || ',' || --AskSzP

           coalesce(BidSzM::text, '') || ',' || --BidSzM
           coalesce(to_char(BidM, 'FM999999.0099'), '') || ',' || --BidM
           coalesce(to_char(AskM, 'FM999999.0099'), '') || ',' || --AskM
           coalesce(AskSzM::text, '') || ',' || --AskSzM

           coalesce(BidSzH::text, '') || ',' || --BidSzH
           coalesce(to_char(BidH, 'FM999999.0099'), '') || ',' || --BidH
           coalesce(to_char(AskH, 'FM999999.0099'), '') || ',' || --AskH
           coalesce(AskSzH::text, '') || ',' || --AskSzH

           coalesce(BidSzQ::text, '') || ',' || --BidSzQ
           coalesce(to_char(BidQ, 'FM999999.0099'), '') || ',' || --BidQ
           coalesce(to_char(AskQ, 'FM999999.0099'), '') || ',' || --AskQ
           coalesce(AskSzQ::text, '') || ',' || --AskSzQ

           coalesce(BidSzX::text, '') || ',' || --BidSzX
           coalesce(to_char(BidX, 'FM999999.0099'), '') || ',' || --BidX
           coalesce(to_char(AskX, 'FM999999.0099'), '') || ',' || --AskX
           coalesce(AskSzX::text, '') || ',' || --AskSzX

           coalesce(BidSzE::text, '') || ',' || --BidSzE
           coalesce(to_char(BidE, 'FM999999.0099'), '') || ',' || --BidE
           coalesce(to_char(AskE, 'FM999999.0099'), '') || ',' || --AskE
           coalesce(AskSzE::text, '') || ',' || --AskSzE

           coalesce(BidSzJ::text, '') || ',' || --BidSzJ
           coalesce(to_char(BidJ, 'FM999999.0099'), '') || ',' || --BidJ
           coalesce(to_char(AskJ, 'FM999999.0099'), '') || ',' || --AskJ
           coalesce(AskSzJ::text, '') || ',' || --AskSzJ

           coalesce(BidSzR::text, '') || ',' || --BidSzR
           coalesce(to_char(BidR, 'FM999999.0099'), '') || ',' || --BidR
           coalesce(to_char(AskR, 'FM999999.0099'), '') || ',' || --AskR
           coalesce(AskSzR::text, '') || ',' || --AskSzR

           coalesce(BidSzD::text, '') || ',' || --BidSzD
           coalesce(to_char(BidD, 'FM999999.0099'), '') || ',' || --BidD
           coalesce(to_char(AskD, 'FM999999.0099'), '') || ',' || --AskD
           coalesce(AskSzD::text, '') || ',' || --AskSzD
-----
           coalesce(BidSzS::text, '') || ',' || --BidSzS
           coalesce(to_char(BidS, 'FM999999.0099'), '') || ',' || --BidS
           coalesce(to_char(AskS, 'FM999999.0099'), '') || ',' || --AskS
           coalesce(AskSzS::text, '') || ',' || --AskSzS

           coalesce(BidSzU::text, '') || ',' || --BidSzU
           coalesce(to_char(BidU, 'FM999999.0099'), '') || ',' || --BidU
           coalesce(to_char(AskU, 'FM999999.0099'), '') || ',' || --AskU
           coalesce(AskSzU::text, '') || ',' || --AskSzU
-----
--CrossOrderID,AuctionType,RequestCount,BillingType,ContraBroker,ContraTrader,WhiteList,PaymentPerContract,ContraCrossExecutedQty
           coalesce(cl.cross_order_id::text, '') || ',' || --CrossOrderID
-- 		coalesce(cl.auction_type, '')||','|| --Auc.type
           case
               when cl.STRATEGY_DECISION_REASON_CODE in ('74') and
                    cl.ex_exchange_id in
                    ('AMEX', 'BOX', 'CBOE', 'EDGO', 'GEMINI', 'ISE', 'MCRY', 'MIAX', 'NQBXO', 'PHLX')
                   and exists (select upper(description)
                               from dwh.d_liquidity_indicator li
                               where (upper(description) like '%FLASH%'
                                   or upper(description) like '%EXPOSURE%')
                                 and li.trade_liquidity_indicator = cl.trade_liquidity_indicator)
                   then 'FLASH'
               when CL.STRATEGY_DECISION_REASON_CODE in ('74') and substring(fmj_p.t9730, 2, 1) in ('B', 'b', 's')
                   then 'FLASH'
               when CL.STRATEGY_DECISION_REASON_CODE in ('74') and substring(fmj.t9730, 2, 1) in ('B', 'b', 's')
                   then 'FLASH'
               when CL.STRATEGY_DECISION_REASON_CODE in ('32', '62', '96', '99') then 'FLASH'
               when Cl.CROSS_TYPE = 'P' then 'PIM'
               when Cl.CROSS_TYPE = 'Q' then 'QCC'
               when Cl.CROSS_TYPE = 'F' then 'Facilitation'
               when Cl.CROSS_TYPE = 'S' then 'Solicitation'
               else coalesce(CL.CROSS_TYPE, '') end || ',' || --Auc.type


           coalesce(cl.request_count, '') || ',' || --Req.count
           coalesce(cl.billing_code, '') || ',' ||--Billing Code
           coalesce(cl.contra_broker, '') || ',' || --ContraBroker
           coalesce(cl.contra_trader, '') || ',' || --ContraTrader
           coalesce(cl.white_list, '') || ',' || --WhiteList
           coalesce(staging.trailing_dot(cl.cons_payment_per_contract), '') || ',' ||
           coalesce(cl.contra_cross_exec_qty::text, '') || ',' ||
           coalesce(cl.contra_cross_lp_id, '') || ',' ||
           coalesce(cl.account_demo_mnemonic, '')
               as rec
    from trash.so_imc_main cl
             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.es_fix_message_id
--                                   and fmj.date_id = public.get_dateid(cl.exec_time::date)
                                  and fmj.date_id = to_char(cl.exec_time, 'YYYYMMDD')::int4
                                  and fmj.date_id >= 20240606
                                limit 1) fmj on true
             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.parent_fix_message_id
--                                   and fmj.date_id = public.get_dateid(cl.exec_time::date)
                                  and fmj.date_id = to_char(cl.exec_time, 'YYYYMMDD')::int4
                                  and fmj.date_id >= 20240606
                                limit 1) fmj_p on true;

    get diagnostics l_row_cnt = row_count;
    create index on trash.imc_pg_report (order_id);

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: unordered csv is ready',
                           l_row_cnt, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: COMPLETED===',
                           l_row_cnt, 'O')
    into l_step_id;
    return l_row_cnt;

end;
$$


