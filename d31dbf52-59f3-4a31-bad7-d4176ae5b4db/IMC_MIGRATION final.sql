
CREATE OR REPLACE PROCEDURE trash.get_consolidator_eod_pg_88(IN in_date_id integer)
 LANGUAGE plpgsql
AS $procedure$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
    l_nothing int4;
    l_retention_date int4 := 20230905;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg NON GTC flow for  ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;


drop table if exists t_alp;
create temp table t_alp as
select CONSTR.CROSS_ORDER_ID, CONSTR.ORDER_ID, ALP.LP_DEMO_MNEMONIC
from dwh.CLIENT_ORDER CONSTR
         inner join dwh.CLIENT_ORDER PCON on CONSTR.PARENT_ORDER_ID = PCON.ORDER_ID --contra parent
         inner join staging.lp_connection lc on LC.FIX_CONNECTION_ID = PCON.FIX_CONNECTION_ID
         inner join staging.ats_liquidity_provider alp on alp.liquidity_provider_id = lc.liquidity_provider_id
where true
  and CONSTR.MULTILEG_REPORTING_TYPE in ('1', '3')
  and constr.cross_order_id is not null
  and constr.create_date_id = in_date_id
;

create index on t_alp (CROSS_ORDER_ID, ORDER_ID);
--create index on t_alp (ORDER_ID);   


    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: temp tables have been created',
                           0, 'O')
    into l_step_id;
   
--   select count(*) into l_nothing
--   from dwh.l1_snapshot ls
--   where ls.start_date_id = in_date_id;


    drop table if exists trash.t_base;
    create table trash.t_base with (parallel_workers = 8) as
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
           coalesce(lnb.no_legs, 1)       as no_legs,
           case 
	           when cl.multileg_reporting_type = '2' 
	              then trash.get_multileg_leg_number(cl.order_id, cl.multileg_order_id) end
	                                      as leg_number,
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
           coalesce(pro.sub_strategy_desc, pro1.sub_strategy_desc) as pro_sub_strategy_desc,
           coalesce(pro.client_order_id, pro1.client_order_id)     as pro_client_order_id,
           coalesce(pro.order_type_id, pro1.order_type_id)         as pro_order_type_id,
           coalesce(pro.time_in_force_id, pro1.time_in_force_id)   as pro_time_in_force_id,
           str.cons_payment_per_contract                           as str_cons_payment_per_contract,
           str.order_id                                            as str_order_id,
           str.cross_order_id                                      as str_cross_order_id,
           str.strtg_decision_reason_code                          as str_strtg_decision_reason_code,
           str.request_number                                      as str_request_number,
           str.create_date_id                                      as str_create_date_id,
/*
           case
               when cl.parent_order_id is null then cl.exch_order_id
               when ac.trading_firm_id <> 'imc01' then (select exch_order_id
                                                        from dwh.client_order
                                                        where order_id = cl.parent_order_id
--                                                          and create_date_id = in_date_id
                                                        limit 1)
               else (select exch_order_id
                     from dwh.client_order
                     where order_id = (select max(parent_order_id)
                                       from dwh.client_order
                                       where cross_order_id = cl.cross_order_id
                                         and is_originator <> cl.is_originator
--                                         and create_date_id = in_date_id
                                         )
                       and create_date_id = in_date_id
                     limit 1)
               end                        as RFR_ID,--rfr_id

           case
               when cl.parent_order_id is null then (select orig.exch_order_id
                                                     from dwh.client_order orig
                                                     where orig.order_id = cl.orig_order_id
--                                                       and orig.create_date_id = in_date_id
                                                     limit 1)
               when ac.trading_firm_id <> 'imc01' then (select orig.exch_order_id
                                                        from client_order co
                                                                 join dwh.client_order orig
                                                                      on orig.order_id = co.orig_order_id
--                                                                          and co.create_date_id = in_date_id
                                                        where co.order_id = cl.parent_order_id
--                                                          and orig.create_date_id = in_date_id
                                                        limit 1)
               else (select orig.exch_order_id
                     from dwh.client_order orig
                              join dwh.client_order co on co.orig_order_id = orig.order_id
                     where co.order_id = (select max(parent_order_id) as max_orig_parent_order_id
                                          from dwh.client_order cr
                                          where cr.cross_order_id = cl.cross_order_id
                                            and cr.is_originator <> cl.is_originator
--                                            and cr.create_date_id = in_date_id
                                          limit 1)
                       and orig.create_date_id = in_date_id
                       and co.create_date_id = in_date_id)
               end                        as ORIG_RFR_ID,--orig_rfr_id
*/
           0 as RFR_ID,
           0 as ORIG_RFR_ID,

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
                   then cc_str.t_alp_agg
               when cl.PARENT_ORDER_ID is not null and cl.CROSS_ORDER_ID is not null
                   then cc.t_alp_agg
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
-- the other part is moved into the end part for billing_code!!!!!                                   
--                               when (staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, in_date_id::text::date) is null and
--                                     staging.get_lp_list_lite_tmp(ac.ACCOUNT_ID, OS.ROOT_SYMBOL,
--                                                              case cl.MULTILEG_REPORTING_TYPE
--                                                                  when '1' then 'O'
--                                                                  when '2' then 'M' end) is null)
--                                   then 'Exhaust_IMC'
--                               else 'Exhaust'
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
           fmj.t9730                      as str_t9730,
           fmj_p.t9730                    as par_t9730,
           

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
           sphr.bid_quantity              as BidSzS,
           sphr.bid_price                 as BidS,
           sphr.ask_price                 as AskS,
           sphr.ask_quantity              as AskSzS,

           mxop.bid_quantity              as BidSzU,
           mxop.bid_price                 as BidU,
           mxop.ask_price                 as AskU,
           mxop.ask_quantity              as AskSzU
    from dwh.client_order cl
             inner join dwh.execution ex on cl.order_id = ex.order_id and cl.create_date_id = in_date_id
             inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)


             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
             left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = cl.opt_exec_broker_id
             left join lateral (select sub_strategy_desc,
                                       client_order_id,
                                       order_type_id,
                                       time_in_force_id,
                                       exch_order_id
                                from dwh.client_order pro
                                where cl.parent_order_id = pro.order_id
                                  and pro.create_date_id = in_date_id
                                  and pro.parent_order_id is null
                                  and cl.parent_order_id is not null
--                                  order by pro.create_date_id desc
                                  and pro.create_date_id >= l_retention_date
                                limit 1) pro on true
             left join lateral (select sub_strategy_desc,
                                       client_order_id,
                                       order_type_id,
                                       time_in_force_id,
                                       exch_order_id
                                from trash.f_get_parent_order_attr(cl.parent_order_id,
                                                                   get_dateid(cl.parent_order_process_time::date),
                                                                   l_retention_date)
                                where pro.client_order_id is null
                                  and cl.parent_order_id is not null ) pro1 on true
             left join dwh.client_order str
                       on (cl.order_id = str.parent_order_id and ex.secondary_order_id = str.client_order_id and
                           ex.exec_type = 'F' and str.create_date_id >= cl.create_date_id
                           and str.create_date_id = in_date_id
                           and str.parent_order_id is not null)
             left join dwh.execution es
                       on (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id and
                           es.exec_date_id >= str.create_date_id and es.exec_date_id = in_date_id)
             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = es.fix_message_id
                                  and fmj.date_id = in_date_id
                                limit 1) fmj on true
             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = ex.fix_message_id
                                  and fmj.date_id = in_date_id
                                limit 1) fmj_p on true                         
             left join trash.matched_cross_trades_pg mct on mct.orig_exec_id = coalesce(es.exec_id, ex.exec_id)
             left join lateral (select orig.client_order_id, exch_order_id
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and ex.exec_type in ('S', 'W')
                                  and orig.create_date_id <= in_date_id
                                  and cl.orig_order_id is not null
                                  order by orig.create_date_id desc
                                limit 1) orig on true
             left join lateral (select cxl.client_order_id as client_order_id
                                from client_order cxl
                                where cxl.orig_order_id = cl.order_id
                                  and ex.exec_type in ('b', '4')
                                  and cxl.create_date_id = in_date_id
                                  and cxl.orig_order_id is not null
                                  order by cxl.order_id
                                limit 1) cxl on true
             left join lateral (select cnl.no_legs
                                from dwh.client_order cnl
                                where cnl.order_id = cl.multileg_order_id
                                and cnl.create_date_id = in_date_id
                                limit 1) lnb on true

             left join lateral(select string_agg(LP_DEMO_MNEMONIC, ' ') as t_alp_agg from t_alp as cc_str 
             where  cc_str.cross_order_id = STR.CROSS_ORDER_ID and cc_str.order_id <> STR.ORDER_ID
                                  and cl.PARENT_ORDER_ID is null
                                  and STR.CROSS_ORDER_ID is not null
                                  group by cc_str.CROSS_ORDER_ID
                                  limit 1) cc_str on true
             left join lateral (select string_agg(lp_demo_mnemonic, ' ') as t_alp_agg from t_alp as cc 
             where cc.cross_order_id = cl.CROSS_ORDER_ID  and cc.order_id <> cl.ORDER_ID 
                                  and cl.PARENT_ORDER_ID is not null
                                  and cl.CROSS_ORDER_ID is not null
                                  group by cc.cross_order_id
                                  limit 1) cc on true   
                                  

        -- amex
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'AMEX'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) amex on true
-- bato
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'BATO'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) bato on true
-- box
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'BOX'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) box on true
-- cboe
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'CBOE'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) cboe on true
-- c2ox
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'C2OX'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) c2ox on true
-- nqbxo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'NQBXO'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) nqbxo on true
-- ise
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'ISE'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) ise on true
-- arca
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'ARCA'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) arca on true
-- miax
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MIAX'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) miax on true
-- gemini
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'GEMINI'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) gemini on true
-- nsdqo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'NSDQO'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) nsdqo on true
-- phlx
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'PHLX'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) phlx on true
-- edgo
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'EDGO'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) edgo on true
-- mcry
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MCRY'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) mcry on true
-- mprl
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MPRL'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) mprl on true
-- emld
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'EMLD'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) emld on true
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'SPHR'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) sphr on true
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MXOP'
                                  and ls.start_date_id = in_date_id
                                  limit 1
        ) mxop on true

    where ex.exec_date_id = in_date_id
      and cl.create_date_id = in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and tf.is_eligible4consolidator = 'Y'
      and fc.fix_comp_id <> 'IMCCONS'
    --       and cl.client_order_id = any('{"JZ/0605/X78/262201/24123G0CVZ","JZ/3919/X63/097217/24080H1F5N ","LV/3494/X20/549258/24068IRN1H ","JZ/2731/413/241683/24017HNBLP ","JZ/3948/Z06/635197/24054HYLVV ","JZ/6443/309/110400/24053HBK7Z ","10Z2378338922248","9Z1278827287575","JZ/0465/196/276642/24155JGEIA","JZ/0496/Z06/496444/24156G0NZ4 "}')
      and not exists (select null from trash.t_base_gtc gtc where gtc.order_id = ex.order_id and gtc.exec_id = ex.exec_id)
--      and cl.order_id in (16286700696, 16293318805, 16290488887)
--      order by random()
    ;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: NON GTC orders were added',
                           l_row_cnt, 'O')
    into l_step_id;

        end;
$procedure$
;


------------
create temp table t_all_orders_n as
select cl.order_id,
       cl.create_date_id,
       cl.transaction_id,
       cl.create_time,
       cl.order_qty,
       cl.price,
       cl.exch_order_id,
       cl.cross_order_id,
       cl.is_originator,
       cl.orig_order_id,
       cl.client_order_id,
       cl.exchange_id        as cl_exchange_id,
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
       cl.fix_connection_id,
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
       ex.exchange_id        as ex_exchange_id,
       ex.contra_broker,
       ex.contra_trader,
       ex.secondary_order_id,
       ex.secondary_exch_exec_id,
       ex.exec_date_id,
       ex.fix_message_id,
       ac.trading_firm_id,
       ac.opt_is_fix_clfirm_processed,
       ac.opt_customer_or_firm,
       ac.account_id,
       opx.opt_exec_broker,
       par.order_id          as parent_order_id,
       par.client_order_id   as parent_client_order_id,
       par.create_date_id    as parent_create_date_id,
       par.sub_strategy_desc as parent_sub_strategy_desc,
       par.order_type_id     as parent_order_type_id,
       par.time_in_force_id  as parent_time_in_force_id
from dwh.execution ex
         inner join lateral (select * from dwh.client_order cl where cl.order_id = ex.order_id and cl.create_date_id < :in_date_id order by create_date_id desc limit 1) cl on true
         inner join dwh.d_fix_connection fc
                    on (fc.fix_connection_id = cl.fix_connection_id and fc.fix_comp_id <> 'IMCCONS')
         inner join dwh.d_account ac on ac.account_id = cl.account_id
         inner join dwh.d_trading_firm tf
                    on (tf.trading_firm_id = ac.trading_firm_id and tf.is_eligible4consolidator = 'Y')
         left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = cl.opt_exec_broker_id
         left join lateral (select order_id,
                                   client_order_id,
                                   create_date_id,
                                   sub_strategy_desc,
                                   ORDER_TYPE_id,
                                   time_in_force_id
                            from dwh.client_order pro
                            where cl.parent_order_id = pro.order_id
                              and pro.create_date_id = get_dateid(cl.parent_order_process_time::date)
                              and pro.parent_order_id is null
                              and cl.parent_order_id is not null
                              and pro.create_date_id >= :l_retention_date_id
                            order by create_date_id desc
                            limit 1) par on true
where true
  and ex.exec_date_id = :in_date_id
--   and cl.create_date_id < :in_date_id
  and cl.multileg_reporting_type in ('1', '2')
  and ex.is_busted = 'N'
  and ex.exec_type not in ('E', 'S', 'D', 'y')
  and cl.trans_type <> 'F'
  and cl.create_date_id > :l_retention_date_id
and not exists (select null from t_all_orders tao where  tao.order_id = ex.order_id)
-- and cl.order_id = 14386720503
;
create index on trash.so_imc (order_id, exec_id);
create table trash.so_imc as
select *
from t_all_orders
union all
select *
from t_all_orders_n

select order_id, exec_id from trash.imc_oracle_report
except
select order_id, exec_id from trash.so_imc
except
select order_id, exec_id from trash.imc_oracle_report


select * from trash.so_imc
where order_id = 14386720503