create or replace function trash.get_consolidator_eod_pg(in_date_id int4)
    returns table (ret_row text)
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
    call trash.match_cross_trades_pg(:in_date_id);
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


    create temp table t_clearing_account as
    select *
    from dwh.d_clearing_account ca
    where ca.is_default = 'Y'
      and ca.is_active
      and ca.market_type = 'O'
      and ca.clearing_account_type = '1';
    create index on t_clearing_account (account_id);
    analyze t_clearing_account;

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


    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: temp tables have been created',
                           0, 'O')
    into l_step_id;

    -- GTC_ORDERS

    drop table if exists t_base_gtc;
    create temp table t_base_gtc with (parallel_workers = 4) as
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
         es.contra_broker as es_contra_broker,
         es.contra_account_capacity as es_contra_account_capacity,
         es.contra_trader as es_contra_trader

    from dwh.execution ex
             inner join dwh.gtc_order_status gos on gos.order_id = ex.order_id and gos.close_date_id is null
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

             left join lateral (select --string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr_str
                                       t_alp.lp_demo_mnemonic as contr_str
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

             left join lateral (select --string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr
                                       t_alp.lp_demo_mnemonic as contr
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
                                --                              and pcon.create_date_id >= 20220121
--                              group by pcon.fix_connection_id
                                limit 1) cc on true
    where ex.exec_date_id = in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and tf.is_eligible4consolidator = 'Y'
      and fc.fix_comp_id <> 'IMCCONS';

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: GTC orders were added',
                           0, 'O')
    into l_step_id;

-- NON GTC ORDERS
    create index on t_base_gtc (order_id);

    drop table if exists t_base;
    create temp table t_base with (parallel_workers = 4) as
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
           es.exec_id                     as es_exec_id
            ,
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
         es.contra_broker as es_contra_broker,
         es.contra_account_capacity as es_contra_account_capacity,
         es.contra_trader as es_contra_trader
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

             left join lateral (select --string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr_str
                                       t_alp.lp_demo_mnemonic as contr_str
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

             left join lateral (select --string_agg(distinct t_alp.lp_demo_mnemonic, ' ') as contr
                                       t_alp.lp_demo_mnemonic as contr
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

    where ex.exec_date_id = in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and tf.is_eligible4consolidator = 'Y'
      and fc.fix_comp_id <> 'IMCCONS'
      and not exists (select null from t_base_gtc gtc where gtc.order_id = ex.order_id);


    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: NON GTC orders were added',
                           0, 'O')
    into l_step_id;


    -- MAIN PART
create temp table t_main as
  with white as (select symbol, instrument_type_id from t_wht)
       , black as (select symbol, instrument_type_id from t_blk)
    select tbs.transaction_id,
           tbs.order_id                                                                                as rec_type,
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

           tbs.pro_client_order_id                                                                         as parent_client_order_id,
           tbs.order_id,                                                                                                         --systemorderid
           case
               when tbs.cl_exchange_id = 'ALGOWX' then 'WEX_SWEEP'
               else coalesce(tbs.sub_strategy_desc, exc.mic_code)
               end                                                                                     as exchange_code,

           case
               when tbs.parent_order_id is null then fc.acceptor_id
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
                       else es.contra_account_capacity
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
                       when tbs.PARENT_ORDER_ID is null and es.exchange_id = 'CBOE'
                           then ltrim(ES.CONTRA_BROKER, 'CBOE:')
                       when tbs.PARENT_ORDER_ID is null then ES.CONTRA_BROKER end
               end as CONTRA_BROKER,

           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.PARENT_ORDER_ID is not null then tbs.CONTRA_TRADER
                       else ES.CONTRA_TRADER
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
                    tbs.STR_strtg_decision_reason_code)                                                    as STRATEGY_DECISION_REASON_CODE,
           cro.CROSS_TYPE,
           tbs.fix_message_id                                                                          as parent_fix_message_id, -- ex.fix_message_id parent order
           tbs.es_FIX_MESSAGE_ID,
           tbs.ex_exchange_id,
           tbs.cl_exchange_id,
           tbs.es_exec_id,

           tbs.ACCOUNT_ID,
           I.SYMBOL,
           OS.ROOT_SYMBOL as os_ROOT_SYMBOL,
           case tbs.MULTILEG_REPORTING_TYPE
                                                                  when '1' then 'O'
                                                                  when '2' then 'M' end as instrument_type,
/*                      case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       --
                       when coalesce(tbs.pro_sub_strategy_desc, tbs.sub_strategy_desc) = 'DMA' then 'DMA'
                       when coalesce(tbs.pro_sub_strategy_desc, tbs.sub_strategy_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(tbs.REQUEST_NUMBER, tbs.STR_REQUEST_NUMBER, -1) between 0 and 99 then 'IMC'
                       when coalesce(tbs.pro_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(tbs.REQUEST_NUMBER, tbs.STR_REQUEST_NUMBER, -1) > 99 then 'Exhaust'
                       when (
                           coalesce(tbs.pro_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                           coalesce(tbs.request_number, tbs.STR_request_number) is null)
                           then
                           case
                               when coalesce(tbs.pro_ORDER_TYPE_id, tbs.ORDER_TYPE_id) in ('3', '4', '5', 'B') then 'Exhaust_IMC'
                               when coalesce(tbs.pro_time_in_force_id, tbs.time_in_force_id) in ('2', '7') then 'Exhaust_IMC'
--                               when staging.get_lp_list_tmp(tbs.ACCOUNT_ID, I.SYMBOL, 20240528::text::date) is not null then 'Exhaust'
--                               when staging.get_lp_list_lite_tmp(tbs.ACCOUNT_ID, OS.ROOT_SYMBOL,
--                                                              case tbs.MULTILEG_REPORTING_TYPE
--                                                                  when '1' then 'O'
--                                                                  when '2' then 'M' end) is not null then 'Exhaust'
                               else 'Exhaust_IMC'
                               end
                       else 'Other'
                       --
                       end
               end                                                                                     as BILLING_CODE,
               */
           tbs.BILLING_CODE
--     select tbs.transaction_id, es.exec_date_id, tbs.exec_date_id
--     select *
    from trash.so_imc tbs
             inner join dwh.d_instrument i on i.instrument_id = tbs.instrument_id
             inner join dwh.d_fix_connection fc on (fc.fix_connection_id = tbs.fix_connection_id)
--             left join lateral(select es.exec_id, es.FIX_MESSAGE_ID, ES.CONTRA_TRADER, ES.CONTRA_broker, es.exchange_id, es.contra_account_capacity from dwh.execution es where (es.order_id = tbs.str_order_id and es.exch_exec_id = tbs.secondary_exch_exec_id and es.exec_date_id >= tbs.str_create_date_id and es.exec_date_id >= 20240117) limit 1) es on true
             left join dwh.execution es on (es.order_id = tbs.str_order_id and es.exch_exec_id = tbs.secondary_exch_exec_id and es.exec_date_id >= tbs.str_create_date_id and es.exec_date_id >= 20240117)
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


$$