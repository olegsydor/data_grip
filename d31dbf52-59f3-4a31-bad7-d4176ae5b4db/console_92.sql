drop procedure trash.so_imc_report_making;
CREATE PROCEDURE trash.so_imc_report_making(IN in_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer)
    LANGUAGE plpgsql
AS $procedure$
    -- 20240821 SO https://dashfinancial.atlassian.net/browse/DS-8299
-- permanent tables instead of temp ones is used to be able reviewing potential incidents after finishing the report
declare
    l_load_id           int;
    l_row_cnt           int;
    l_step_id           int;
    l_retention_date_id int4 := 20230901;
    l_order_ids int8[] := '{16506564843,16507613090,17210557035,17221750807}';

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg for ' || in_date_id::text || ' STARTED ===',
                           0, 'O')
    into l_step_id;

--     call dash_reporting.match_cross_trades_pg(in_date_id);

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: match_cross_trades_pg finished',
                           0, 'O')
    into l_step_id;

-- Daily orders
    drop table if exists dash_reporting.imc_base;
    create table dash_reporting.imc_base as
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
           cl.exchange_id                                                               as cl_exchange_id,
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
           cl.multileg_order_id,
           cl.dash_rfr_id,
           rn.leg_number,
           ex.exec_id                                                                   as ex_exec_id,
           ex.exec_time                                                                 as ex_exec_time,
           ex.exec_type                                                                 as ex_exec_type,
           ex.cum_qty                                                                   as ex_cum_qty,
           ex.order_status                                                              as ex_order_status,
           ex.last_px                                                                   as ex_last_px,
           ex.last_qty                                                                  as ex_last_qty,
           ex.contra_account_capacity                                                   as ex_contra_account_capacity,
           ex.trade_liquidity_indicator                                                 as ex_trade_liquidity_indicator,
           ex.exch_exec_id                                                              as ex_exch_exec_id,
           ex.exchange_id                                                               as ex_exchange_id,
           ex.contra_broker                                                             as ex_contra_broker,
           ex.contra_trader                                                             as ex_contra_trader,
           ex.secondary_order_id                                                        as ex_secondary_order_id,
           ex.secondary_exch_exec_id                                                    as ex_secondary_exch_exec_id,
           ex.exec_date_id                                                              as ex_exec_date_id,
           ex.fix_message_id                                                            as ex_fix_message_id,
           ac.trading_firm_id                                                           as ac_trading_firm_id,
           ac.opt_is_fix_clfirm_processed                                               as ac_opt_is_fix_clfirm_processed,
           ac.opt_customer_or_firm                                                      as ac_opt_customer_or_firm,
           ac.account_id                                                                as ac_account_id,
           ac.account_demo_mnemonic                                                     as ac_account_demo_mnemonic,
           opx.opt_exec_broker                                                          as opx_opt_exec_broker,
           fc.acceptor_id                                                               as fc_acceptor_id,
           par.order_id                                                                 as par_order_id,
           par.client_order_id                                                          as par_client_order_id,
           par.create_date_id                                                           as par_create_date_id,
           par.sub_strategy_desc                                                        as par_sub_strategy_desc,
           par.order_type_id                                                            as par_order_type_id,
           par.time_in_force_id                                                         as par_time_in_force_id,
           par.exch_order_id                                                            as par_exch_order_id,
           par.orig_order_id                                                            as par_orig_order_id,
           str.cons_payment_per_contract                                                as str_cons_payment_per_contract,
           str.order_id                                                                 as str_order_id,
           str.cross_order_id                                                           as str_cross_order_id,
           str.strtg_decision_reason_code                                               as str_strtg_decision_reason_code,
           str.request_number                                                           as str_request_number,
           str.create_date_id                                                           as str_create_date_id,
           es.FIX_MESSAGE_ID                                                            as es_fix_message_id,
           es.exec_id                                                                   as es_exec_id,
           es.contra_broker                                                             as es_contra_broker,
           es.contra_account_capacity                                                   as es_contra_account_capacity,
           es.contra_trader                                                             as es_contra_trader,
           es.exchange_id                                                               as es_exchange_id,
           case
               when cl.parent_order_id is not null and ac.trading_firm_id = 'imc01' then
                   (select max(parent_order_id)
                    from dwh.client_order co
                    where co.cross_order_id = cl.cross_order_id
                      and co.is_originator <> cl.is_originator
                      and co.create_date_id > l_retention_date_id)
               else null end                                                            as max_orig_parent_order_id
    from dwh.client_order cl
             inner join dwh.execution ex on ex.order_id = cl.order_id
             inner join dwh.d_fix_connection fc
                        on (fc.fix_connection_id = cl.fix_connection_id and fc.fix_comp_id <> 'IMCCONS')
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_trading_firm tf
                        on (tf.trading_firm_id = ac.trading_firm_id and tf.is_eligible4consolidator = 'Y')
             left join lateral (
        select leg_number
        from (select order_id, dense_rank() over (partition by co.multileg_order_id order by co.order_id) as leg_number
              from dwh.client_order co
              where co.multileg_order_id = cl.multileg_order_id
                and co.create_date_id = in_date_id) x
        where x.order_id = cl.order_id
          and cl.multileg_order_id is not null
        limit 1
        ) rn on true
             left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = cl.opt_exec_broker_id
             left join lateral (select order_id,
                                       client_order_id,
                                       create_date_id,
                                       sub_strategy_desc,
                                       order_type_id,
                                       time_in_force_id,
                                       exch_order_id,
                                       orig_order_id
                                from dwh.client_order pro
                                where cl.parent_order_id = pro.order_id
                                  and pro.create_date_id = get_dateid(cl.parent_order_process_time::date)
                                  and pro.parent_order_id is null
                                  and cl.parent_order_id is not null
                                  and pro.create_date_id >= l_retention_date_id
                                order by create_date_id desc
                                limit 1) par on true

             left join dwh.client_order str
                       on (cl.order_id = str.parent_order_id
                           and ex.secondary_order_id = str.client_order_id
                           and ex.exec_type = 'F'
                           and str.create_date_id = in_date_id
                           and str.parent_order_id is not null)
             left join dwh.execution es
                       on (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id and
                           es.exec_date_id = cl.create_date_id)
    where true
      and ex.exec_date_id = in_date_id
      and cl.create_date_id = in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and case when l_order_ids <> '{}' then cl.order_id = any(l_order_ids) else true end;
    get diagnostics l_row_cnt = row_count;

    create index on dash_reporting.imc_base (order_id, ex_exec_id);

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: daily orders counted',
                           l_row_cnt, 'O')
    into l_step_id;

-- counting missed orders
    create temp table t_left_orders as
    select order_id
    from dwh.execution
    where exec_date_id = in_date_id
      and is_busted = 'N'
      and exec_type not in ('E', 'S', 'D', 'y')
      and case when l_order_ids <> '{}' then order_id = any(l_order_ids) else true end
    except
    select order_id
    from dash_reporting.imc_base;

    create index on t_left_orders (order_id);
    analyze t_left_orders;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: non daily orders selected',
                           0, 'O')
    into l_step_id;

-- non daily orders
    insert into dash_reporting.imc_base
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
           cl.exchange_id                                                                                 as cl_exchange_id,
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
           cl.multileg_order_id,
           cl.dash_rfr_id,
           rn.leg_number,
           ex.exec_id                                                                                     as ex_exec_id,
           ex.exec_time                                                                                   as ex_exec_time,
           ex.exec_type                                                                                   as ex_exec_type,
           ex.cum_qty                                                                                     as ex_cum_qty,
           ex.order_status                                                                                as ex_order_status,
           ex.last_px                                                                                     as ex_last_px,
           ex.last_qty                                                                                    as ex_last_qty,
           ex.contra_account_capacity                                                                     as ex_contra_account_capacity,
           ex.trade_liquidity_indicator                                                                   as ex_trade_liquidity_indicator,
           ex.exch_exec_id                                                                                as ex_exch_exec_id,
           ex.exchange_id                                                                                 as ex_exchange_id,
           ex.contra_broker                                                                               as ex_contra_broker,
           ex.contra_trader                                                                               as ex_contra_trader,
           ex.secondary_order_id                                                                          as ex_secondary_order_id,
           ex.secondary_exch_exec_id                                                                      as ex_secondary_exch_exec_id,
           ex.exec_date_id                                                                                as ex_exec_date_id,
           ex.fix_message_id                                                                              as ex_fix_message_id,
           ac.trading_firm_id                                                                             as ac_trading_firm_id,
           ac.opt_is_fix_clfirm_processed                                                                 as ac_opt_is_fix_clfirm_processed,
           ac.opt_customer_or_firm                                                                        as ac_opt_customer_or_firm,
           ac.account_id                                                                                  as ac_account_id,
           ac.account_demo_mnemonic                                                                       as ac_account_demo_mnemonic,
           opx.opt_exec_broker                                                                            as opx_opt_exec_broker,
           fc.acceptor_id                                                                                 as fc_acceptor_id,
           par.order_id                                                                                   as par_order_id,
           par.client_order_id                                                                            as par_client_order_id,
           par.create_date_id                                                                             as par_create_date_id,
           par.sub_strategy_desc                                                                          as par_sub_strategy_desc,
           par.order_type_id                                                                              as par_order_type_id,
           par.time_in_force_id                                                                           as par_time_in_force_id,
           par.exch_order_id                                                                              as par_exch_order_id,
           par.orig_order_id                                                                              as par_orig_order_id,
           str.cons_payment_per_contract                                                                  as str_cons_payment_per_contract,
           str.order_id                                                                                   as str_order_id,
           str.cross_order_id                                                                             as str_cross_order_id,
           str.strtg_decision_reason_code                                                                 as str_strtg_decision_reason_code,
           str.request_number                                                                             as str_request_number,
           str.create_date_id                                                                             as str_create_date_id,
           es.FIX_MESSAGE_ID                                                                              as es_fix_message_id,
           es.exec_id                                                                                     as es_exec_id,
           es.contra_broker                                                                               as es_contra_broker,
           es.contra_account_capacity                                                                     as es_contra_account_capacity,
           es.contra_trader                                                                               as es_contra_trader,
           es.exchange_id                                                                                 as es_exchange_id,
           case
               when cl.parent_order_id is not null and ac.trading_firm_id = 'imc01' then
                   (select max(parent_order_id)
                    from dwh.client_order co
                    where co.cross_order_id = cl.cross_order_id
                      and co.is_originator <> cl.is_originator
                      and co.create_date_id > l_retention_date_id)
               else null end                                                                              as max_orig_parent_order_id
    from dwh.execution ex
             join t_left_orders tlo on ex.order_id = tlo.order_id
             inner join dwh.client_order cl on ex.order_id = cl.order_id
             inner join dwh.d_fix_connection fc
                        on (fc.fix_connection_id = cl.fix_connection_id and fc.fix_comp_id <> 'IMCCONS')
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_trading_firm tf
                        on (tf.trading_firm_id = ac.trading_firm_id and tf.is_eligible4consolidator = 'Y')
             left join lateral (
        select leg_number
        from (select order_id, dense_rank() over (partition by co.multileg_order_id order by co.order_id) as leg_number
              from dwh.client_order co
              where co.multileg_order_id = cl.multileg_order_id
                and co.create_date_id >= cl.create_date_id) x
        where x.order_id = cl.order_id
          and cl.multileg_order_id is not null
        limit 1
        ) rn on true
             left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = cl.opt_exec_broker_id
             left join lateral (select order_id,
                                       client_order_id,
                                       create_date_id,
                                       sub_strategy_desc,
                                       order_type_id,
                                       time_in_force_id,
                                       exch_order_id,
                                       orig_order_id
                                from dwh.client_order pro
                                where cl.parent_order_id = pro.order_id
                                  and pro.create_date_id = get_dateid(cl.parent_order_process_time::date)
                                  and pro.parent_order_id is null
                                  and cl.parent_order_id is not null
                                  and pro.create_date_id >= l_retention_date_id
                                order by create_date_id desc
                                limit 1) par on true

             left join lateral (select *
                                from dwh.client_order str
                                where (cl.order_id = str.parent_order_id
                                    and ex.secondary_order_id = str.client_order_id
                                    and ex.exec_type = 'F'
                                    and str.create_date_id >= cl.create_date_id
                                    and str.create_date_id >= l_retention_date_id
                                    and str.parent_order_id is not null)
                                limit 1) str on true
             left join lateral (select *
                                from dwh.execution es
                                where (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id
                                    and es.exec_date_id >= cl.create_date_id
                                    and es.exec_date_id >= l_retention_date_id
                                          )
                                limit 1) es on true
    where true
      and ex.exec_date_id = in_date_id
--   and cl.create_date_id = in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and cl.create_date_id > l_retention_date_id
      and case when l_order_ids <> '{}' then ex.order_id = any(l_order_ids) else true end;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: non daily orders counted',
                           l_row_cnt, 'O')
    into l_step_id;

    drop table if exists t_left_orders;
    analyze dash_reporting.imc_base;

    drop table if exists t_alp;

    create temp table t_alp as
    select constr.cross_order_id, constr.order_id, alp.lp_demo_mnemonic
    from dwh.client_order constr
             inner join dwh.client_order pcon on constr.parent_order_id = pcon.order_id --contra parent
             inner join staging.lp_connection lc on lc.fix_connection_id = pcon.fix_connection_id
             inner join staging.ats_liquidity_provider alp on alp.liquidity_provider_id = lc.liquidity_provider_id
    where true
      and constr.multileg_reporting_type in ('1', '3')
      and constr.cross_order_id is not null
      and constr.create_date_id = in_date_id;
    create index on t_alp (cross_order_id, order_id);
    analyze t_alp;


    drop table if exists t_providers;
    create temp table t_providers as
    select al.liquidity_provider_id, atp.lp_symbol_list_id, al.account_id, sl.symbol
    from dwh.d_acc_allowed_liquidity_provider al
             inner join dwh.d_ats_liquidity_provider atp
                        on atp.liquidity_provider_id = al.liquidity_provider_id
             join lateral (select sl.symbol
                           from staging.symbol2lp_symbol_list sl
                           where sl.lp_symbol_list_id = atp.lp_symbol_list_id
                           limit 1) sl on true
--                              and sl.symbol = :in_symbol
    where atp.lp_symbol_list_id is not null
      and atp.is_active
      and al.is_active
    union
    select al.liquidity_provider_id, atp.lp_symbol_list_id, al.account_id, null
    from dwh.d_acc_allowed_liquidity_provider al
             inner join dwh.d_ats_liquidity_provider atp
                        on atp.liquidity_provider_id = al.liquidity_provider_id
    where atp.lp_symbol_list_id is null
      and atp.is_active
      and al.is_active;
    create index on t_providers(account_id);


    drop table if exists dash_reporting.imc_base_ext;
    create table dash_reporting.imc_base_ext as
    select cl.order_id,
           cl.transaction_id,
           cl.create_time,
           cl.order_qty,
           cl.price,
           cl.par_order_id,
           cl.exch_order_id,
           cl.cross_order_id,
           cl.is_originator,
           cl.orig_order_id,
           cl.client_order_id,
           cl.cl_exchange_id,
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
           coalesce(lnb.no_legs, 1)         as no_legs,
           cl.leg_number                    as leg_number,
           cl.side,
           cl.ex_exec_id,
           cl.ex_exec_time,
           cl.ex_exec_type,
           cl.ex_cum_qty,
           cl.ex_order_status,
           cl.ex_last_px,
           cl.ex_last_qty,
           cl.ex_contra_account_capacity,
           cl.ex_trade_liquidity_indicator,
           cl.ex_exch_exec_id,
           cl.ex_exchange_id,
           cl.ex_contra_broker,
           cl.ex_contra_trader,
           cl.ex_secondary_order_id,
           cl.ex_secondary_exch_exec_id,
           cl.ac_trading_firm_id,
           cl.ac_opt_is_fix_clfirm_processed,
           cl.ac_opt_customer_or_firm,
           cl.ac_account_id,
           cl.opx_opt_exec_broker,
           cl.ex_exec_date_id,
           cl.ex_fix_message_id,
           cl.par_sub_strategy_desc,
           cl.par_client_order_id,
           cl.par_order_type_id,
           cl.par_time_in_force_id,
           cl.str_cons_payment_per_contract,
           cl.str_order_id,
           cl.str_cross_order_id,
           cl.STR_strtg_decision_reason_code,
           cl.STR_request_number,
           cl.str_create_date_id,

           case
               when cl.par_order_id is null then cl.exch_order_id
               when cl.ac_trading_firm_id <> 'imc01' then cl.par_exch_order_id
               else cl.dash_rfr_id
               end                       as rfr_id,--rfr_id

           case
               when cl.par_order_id is null then orig.exch_order_id
               when cl.ac_trading_firm_id <> 'imc01' then (select orig.exch_order_id
                                                           from dwh.client_order orig
                                                           where orig.order_id = cl.par_orig_order_id
                                                           limit 1)
               else (select orig.exch_order_id
                     from dwh.client_order co
                              join dwh.client_order orig on co.orig_order_id = orig.order_id
                     where co.order_id = cl.max_orig_parent_order_id
                       and co.create_date_id >= l_retention_date_id
                       and orig.create_date_id >= l_retention_date_id)
               end as ORIG_RFR_ID,--orig_rfr_id

           case
               when cl.ex_exec_type in ('S', 'W') then orig.client_order_id
--                   (select orig.client_order_id from client_order orig where orig.order_id = tbs.orig_order_id) -- SO MOVED TO LATERAL
               end                       as REPLACED_ORDER_ID,
           case
               when cl.ex_exec_type in ('b', '4') then cxl.client_order_id
--                   (select min(cxl.client_order_id) from client_order cxl where cxl.orig_order_id = tbs.order_id) -- SO MOVED TO LATERAL
               end                       as cancel_order_id,
           case
               when cl.ex_exec_type = 'F' then
                   (select LAST_QTY from EXECUTION exc where EXEC_ID = MCT.CONTRA_EXEC_ID and exec_date_id = in_date_id)
               end                       as CONTRA_CROSS_EXEC_QTY,

           case
               when cl.PAR_ORDER_ID is null and cl.STR_CROSS_ORDER_ID is not null
                   then cc_str.t_alp_agg
               when cl.PAR_ORDER_ID is not null and cl.CROSS_ORDER_ID is not null
                   then cc.t_alp_agg
               end                       as CONTRA_CROSS_LP_ID,
           cl.es_FIX_MESSAGE_ID          as es_fix_message_id,
           cl.es_exec_id                 as es_exec_id,
           case
               when cl.ex_exec_type = 'F' then
                   case
                       --
                       when coalesce(cl.par_sub_strategy_desc, cl.sub_strategy_desc) = 'DMA' then 'DMA'
                       when coalesce(cl.par_sub_strategy_desc, cl.sub_strategy_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(cl.REQUEST_NUMBER, cl.STR_request_number, -1) between 0 and 99 then 'IMC'
                       when coalesce(cl.par_SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) in ('CSLDTR', 'RETAIL') and
                            coalesce(cl.REQUEST_NUMBER, cl.STR_REQUEST_NUMBER, -1) > 99 then 'Exhaust'
                       when (
                           coalesce(cl.par_SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) not in
                           ('DMA', 'CSLDTR', 'RETAIL') or
                           coalesce(cl.request_number, cl.STR_request_number, -1) = -1)
                           then
                           case
                               when coalesce(cl.par_ORDER_TYPE_id, cl.ORDER_TYPE_id) in ('3', '4', '5', 'B')
                                   then 'Exhaust_IMC'
                               when coalesce(cl.par_time_in_force_id, cl.time_in_force_id) in ('2', '7')
                                   then 'Exhaust_IMC'
                               end
                       else 'Other'
                       --
                       end
               end                       as BILLING_CODE,
           cl.es_contra_broker           as es_contra_broker,
           cl.es_contra_account_capacity as es_contra_account_capacity,
           cl.es_contra_trader           as es_contra_trader,
           cl.es_exchange_id             as es_exchange_id,
           cl.ac_account_demo_mnemonic,
           cl.fc_acceptor_id,
           fmj.t9730                     as str_t9730,
           fmj_p.t9730                   as par_t9730

    from dash_reporting.imc_base cl
             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.es_fix_message_id
                                  and fmj.date_id = in_date_id
                                limit 1) fmj on true
             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.ex_fix_message_id
                                  and fmj.date_id = in_date_id
                                limit 1) fmj_p on true
             left join dash_reporting.matched_cross_trades_pg mct on mct.orig_exec_id = coalesce(cl.es_exec_id, cl.ex_exec_id)
             left join lateral (select orig.client_order_id, exch_order_id
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
--                                   and cl.ex_exec_type in ('S', 'W')
                                  and orig.create_date_id <= in_date_id
                                  and cl.orig_order_id is not null
                                  and orig.create_date_id >= l_retention_date_id
                                order by orig.create_date_id desc
                                limit 1) orig on true
             left join lateral (select cxl.client_order_id as client_order_id
                                from client_order cxl
                                where cxl.orig_order_id = cl.order_id
--                                   and cl.ex_exec_type in ('b', '4')
--                                   and cxl.create_date_id = in_date_id --??
                                  and cxl.orig_order_id is not null
                                  and cxl.create_date_id >= l_retention_date_id
                                order by cxl.order_id
                                limit 1) cxl on true

             left join lateral (select cnl.no_legs
                                from dwh.client_order cnl
                                where cnl.order_id = cl.multileg_order_id
--                                   and cnl.create_date_id = in_date_id --??
                                  and cnl.create_date_id >= l_retention_date_id
                                limit 1) lnb on true

             left join lateral (select string_agg(LP_DEMO_MNEMONIC, ' ') as t_alp_agg
                                from t_alp as cc_str
                                where cc_str.cross_order_id = cl.STR_CROSS_ORDER_ID
                                  and cc_str.order_id <> cl.STR_ORDER_ID
                                  and cl.PAR_ORDER_ID is null
                                  and cl.STR_CROSS_ORDER_ID is not null
                                group by cc_str.CROSS_ORDER_ID
                                limit 1) cc_str on true
             left join lateral (select string_agg(lp_demo_mnemonic, ' ') as t_alp_agg
                                from t_alp as cc
                                where cc.cross_order_id = cl.CROSS_ORDER_ID
                                  and cc.order_id <> cl.ORDER_ID
                                  and cl.PAR_ORDER_ID is not null
                                  and cl.CROSS_ORDER_ID is not null
                                group by cc.cross_order_id
                                limit 1) cc on true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: extended table created',
                           l_row_cnt, 'O')
    into l_step_id;
    analyze dash_reporting.imc_base_ext;

    drop table if exists t_alp;

    drop table if exists dash_reporting.imc_base_ext_md;
    create table dash_reporting.imc_base_ext_md as
    select *
    from dash_reporting.imc_base_ext cl
             left join lateral (select
                                    -- AMEX
                                    max(case when ls.exchange_id = 'AMEX' then ls.ask_price end)      as amex_ask_price,
                                    max(case when ls.exchange_id = 'AMEX' then ls.bid_price end)      as amex_bid_price,
                                    max(case when ls.exchange_id = 'AMEX' then ls.ask_quantity end)   as amex_ask_quantity,
                                    max(case when ls.exchange_id = 'AMEX' then ls.bid_quantity end)   as amex_bid_quantity,
                                    -- BATO
                                    max(case when ls.exchange_id = 'BATO' then ls.ask_price end)      as bato_ask_price,
                                    max(case when ls.exchange_id = 'BATO' then ls.bid_price end)      as bato_bid_price,
                                    max(case when ls.exchange_id = 'BATO' then ls.ask_quantity end)   as bato_ask_quantity,
                                    max(case when ls.exchange_id = 'BATO' then ls.bid_quantity end)   as bato_bid_quantity,
                                    -- BOX
                                    max(case when ls.exchange_id = 'BOX' then ls.ask_price end)       as box_ask_price,
                                    max(case when ls.exchange_id = 'BOX' then ls.bid_price end)       as box_bid_price,
                                    max(case when ls.exchange_id = 'BOX' then ls.ask_quantity end)    as box_ask_quantity,
                                    max(case when ls.exchange_id = 'BOX' then ls.bid_quantity end)    as box_bid_quantity,
                                    -- CBOE
                                    max(case when ls.exchange_id = 'CBOE' then ls.ask_price end)      as cboe_ask_price,
                                    max(case when ls.exchange_id = 'CBOE' then ls.bid_price end)      as cboe_bid_price,
                                    max(case when ls.exchange_id = 'CBOE' then ls.ask_quantity end)   as cboe_ask_quantity,
                                    max(case when ls.exchange_id = 'CBOE' then ls.bid_quantity end)   as cboe_bid_quantity,
                                    -- C2OX
                                    max(case when ls.exchange_id = 'C2OX' then ls.ask_price end)      as c2ox_ask_price,
                                    max(case when ls.exchange_id = 'C2OX' then ls.bid_price end)      as c2ox_bid_price,
                                    max(case when ls.exchange_id = 'C2OX' then ls.ask_quantity end)   as c2ox_ask_quantity,
                                    max(case when ls.exchange_id = 'C2OX' then ls.bid_quantity end)   as c2ox_bid_quantity,
                                    -- NQBXO
                                    max(case when ls.exchange_id = 'NQBXO' then ls.ask_price end)     as nqbxo_ask_price,
                                    max(case when ls.exchange_id = 'NQBXO' then ls.bid_price end)     as nqbxo_bid_price,
                                    max(case when ls.exchange_id = 'NQBXO' then ls.ask_quantity end)  as nqbxo_ask_quantity,
                                    max(case when ls.exchange_id = 'NQBXO' then ls.bid_quantity end)  as nqbxo_bid_quantity,
                                    -- ISE
                                    max(case when ls.exchange_id = 'ISE' then ls.ask_price end)       as ise_ask_price,
                                    max(case when ls.exchange_id = 'ISE' then ls.bid_price end)       as ise_bid_price,
                                    max(case when ls.exchange_id = 'ISE' then ls.ask_quantity end)    as ise_ask_quantity,
                                    max(case when ls.exchange_id = 'ISE' then ls.bid_quantity end)    as ise_bid_quantity,
                                    -- ARCA
                                    max(case when ls.exchange_id = 'ARCA' then ls.ask_price end)      as arca_ask_price,
                                    max(case when ls.exchange_id = 'ARCA' then ls.bid_price end)      as arca_bid_price,
                                    max(case when ls.exchange_id = 'ARCA' then ls.ask_quantity end)   as arca_ask_quantity,
                                    max(case when ls.exchange_id = 'ARCA' then ls.bid_quantity end)   as arca_bid_quantity,
                                    -- MIAX
                                    max(case when ls.exchange_id = 'MIAX' then ls.ask_price end)      as miax_ask_price,
                                    max(case when ls.exchange_id = 'MIAX' then ls.bid_price end)      as miax_bid_price,
                                    max(case when ls.exchange_id = 'MIAX' then ls.ask_quantity end)   as miax_ask_quantity,
                                    max(case when ls.exchange_id = 'MIAX' then ls.bid_quantity end)   as miax_bid_quantity,
                                    -- GEMINI
                                    max(case when ls.exchange_id = 'GEMINI' then ls.ask_price end)    as gemini_ask_price,
                                    max(case when ls.exchange_id = 'GEMINI' then ls.bid_price end)    as gemini_bid_price,
                                    max(case when ls.exchange_id = 'GEMINI' then ls.ask_quantity end) as gemini_ask_quantity,
                                    max(case when ls.exchange_id = 'GEMINI' then ls.bid_quantity end) as gemini_bid_quantity,
                                    -- NSDQO
                                    max(case when ls.exchange_id = 'NSDQO' then ls.ask_price end)     as nsdqo_ask_price,
                                    max(case when ls.exchange_id = 'NSDQO' then ls.bid_price end)     as nsdqo_bid_price,
                                    max(case when ls.exchange_id = 'NSDQO' then ls.ask_quantity end)  as nsdqo_ask_quantity,
                                    max(case when ls.exchange_id = 'NSDQO' then ls.bid_quantity end)  as nsdqo_bid_quantity,
                                    -- PHLX
                                    max(case when ls.exchange_id = 'PHLX' then ls.ask_price end)      as phlx_ask_price,
                                    max(case when ls.exchange_id = 'PHLX' then ls.bid_price end)      as phlx_bid_price,
                                    max(case when ls.exchange_id = 'PHLX' then ls.ask_quantity end)   as phlx_ask_quantity,
                                    max(case when ls.exchange_id = 'PHLX' then ls.bid_quantity end)   as phlx_bid_quantity,
                                    -- EDGO
                                    max(case when ls.exchange_id = 'EDGO' then ls.ask_price end)      as edgo_ask_price,
                                    max(case when ls.exchange_id = 'EDGO' then ls.bid_price end)      as edgo_bid_price,
                                    max(case when ls.exchange_id = 'EDGO' then ls.ask_quantity end)   as edgo_ask_quantity,
                                    max(case when ls.exchange_id = 'EDGO' then ls.bid_quantity end)   as edgo_bid_quantity,
                                    -- MCRY
                                    max(case when ls.exchange_id = 'MCRY' then ls.ask_price end)      as mcry_ask_price,
                                    max(case when ls.exchange_id = 'MCRY' then ls.bid_price end)      as mcry_bid_price,
                                    max(case when ls.exchange_id = 'MCRY' then ls.ask_quantity end)   as mcry_ask_quantity,
                                    max(case when ls.exchange_id = 'MCRY' then ls.bid_quantity end)   as mcry_bid_quantity,
                                    -- MPRL
                                    max(case when ls.exchange_id = 'MPRL' then ls.ask_price end)      as mprl_ask_price,
                                    max(case when ls.exchange_id = 'MPRL' then ls.bid_price end)      as mprl_bid_price,
                                    max(case when ls.exchange_id = 'MPRL' then ls.ask_quantity end)   as mprl_ask_quantity,
                                    max(case when ls.exchange_id = 'MPRL' then ls.bid_quantity end)   as mprl_bid_quantity,
                                    -- EMLD
                                    max(case when ls.exchange_id = 'EMLD' then ls.ask_price end)      as emld_ask_price,
                                    max(case when ls.exchange_id = 'EMLD' then ls.bid_price end)      as emld_bid_price,
                                    max(case when ls.exchange_id = 'EMLD' then ls.ask_quantity end)   as emld_ask_quantity,
                                    max(case when ls.exchange_id = 'EMLD' then ls.bid_quantity end)   as emld_bid_quantity,
                                    -- SPHR
                                    max(case when ls.exchange_id = 'SPHR' then ls.ask_price end)      as sphr_ask_price,
                                    max(case when ls.exchange_id = 'SPHR' then ls.bid_price end)      as sphr_bid_price,
                                    max(case when ls.exchange_id = 'SPHR' then ls.ask_quantity end)   as sphr_ask_quantity,
                                    max(case when ls.exchange_id = 'SPHR' then ls.bid_quantity end)   as sphr_bid_quantity,
                                    -- MXOP
                                    max(case when ls.exchange_id = 'MXOP' then ls.ask_price end)      as mxop_ask_price,
                                    max(case when ls.exchange_id = 'MXOP' then ls.bid_price end)      as mxop_bid_price,
                                    max(case when ls.exchange_id = 'MXOP' then ls.ask_quantity end)   as mxop_ask_quantity,
                                    max(case when ls.exchange_id = 'MXOP' then ls.bid_quantity end)   as mxop_bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.start_date_id = cl.create_date_id
                                group by ls.transaction_id
                                limit 1
        ) md on true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: market_data was added',
                           l_row_cnt, 'O')
    into l_step_id;

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
    analyze dash_reporting.imc_base_ext_md;

------------------
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


    drop table if exists dash_reporting.imc_final;
    create table dash_reporting.imc_final as
    with white as (select symbol, instrument_type_id from t_wht)
       , black as (select symbol, instrument_type_id from t_blk)
    select tbs.transaction_id,
           tbs.ex_exec_id,
           tbs.ac_trading_firm_id,                                                                                               --entitycode
           tbs.create_time,
           tbs.ex_exec_time,
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
               when tbs.ex_exec_type = '4' then 'Canceled'
               when tbs.ex_exec_type = '5' then 'Replaced'
               when tbs.ex_exec_type = 'F' and tbs.ex_order_status = '6' then
                   case
                       when tbs.ex_cum_qty = tbs.order_qty then 'Filled'
                       else 'Partial Fill'
                       end
               when tbs.ex_order_status = 'A' then 'Pending New'
               when tbs.ex_order_status = '0' then 'New'
               when tbs.ex_order_status = '8' then 'Rejected'
               when tbs.ex_order_status = 'a' then 'Pending Replace'
               when tbs.ex_order_status = 'b' then 'Pending Cancel'
               when tbs.ex_order_status = '1' then 'Partial Fill'
               when tbs.ex_order_status = '2' then 'Filled'
               when tbs.ex_order_status = '3' then 'Done For Day'
               else tbs.ex_order_status end                                                            as ORD_STATUS,
           tbs.price,
           tbs.ex_last_px,
           tbs.order_qty,                                                                                                        --entered qty
           -- ask++
           tbs.ex_last_qty,                                                                                                      --statusqty


           tbs.RFR_ID,--rfr_id
           tbs.ORIG_RFR_ID,--orig_rfr_id
           tbs.client_order_id,

           tbs.REPLACED_ORDER_ID,
           tbs.cancel_order_id,

           tbs.par_client_order_id                                                                     as parent_client_order_id,
           tbs.order_id,                                                                                                         --systemorderid
           case
               when tbs.cl_exchange_id = 'ALGOWX' then 'WEX_SWEEP'
               else coalesce(tbs.sub_strategy_desc, exc.mic_code)
               end                                                                                     as exchange_code,

           case
               when tbs.par_order_id is null then tbs.fc_acceptor_id
               when dss.sub_system_id like '%CONS%' then 'CONS'
               when dss.sub_system_id like '%OSR%' then 'SOR'
               when dss.sub_system_id like '%ATLAS%' or dss.sub_system_id like '%ATS%' then 'ATS'
               else dss.sub_system_id
               end                                                                                     as EX_CONNECTION,


           lpad(coalesce(tbs.opx_opt_exec_broker, opx.opt_exec_broker), 3, '0')                        as give_up_firm,
           case
               when tbs.ac_opt_is_fix_clfirm_processed = 'Y' then tbs.clearing_firm_id
               else coalesce(lpad(ca.cmta, 3, '0'), tbs.clearing_firm_id)
               end                                                                                     as cmta_firm,
           tbs.clearing_account,
           tbs.sub_account,
           tbs.open_close,
           case
               when (tbs.par_order_id is null or tbs.customer_or_firm_id is not null)
                   then case coalesce(tbs.customer_or_firm_id, tbs.ac_opt_customer_or_firm)
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
               when tbs.ex_exec_type = 'F' then
                   case
                       when tbs.par_order_id is not null then tbs.ex_contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
           ot.order_type_short_name,
           tif.tif_short_name,                                                                                                   -- TIME_IN_FORCE
           tbs.exec_instruction,                                                                                                 -- EXEC_INST
           tbs.ex_trade_liquidity_indicator,

           tbs.ex_exch_exec_id,
           tbs.exch_order_id,
           tbs.cross_order_id,
           case
               when tbs.REQUEST_NUMBER >= 99 then ''
               else tbs.REQUEST_NUMBER::text
               end                                                                                     as REQUEST_COUNT,

--           tbs.BILLING_CODE,


           case
               when tbs.ex_EXEC_TYPE = 'F' then
                   case
                       when tbs.PAR_ORDER_ID is not null and tbs.ex_exchange_id = 'CBOE'
                           then ltrim(tbs.ex_contra_broker, 'CBOE:')
                       when tbs.PAR_ORDER_ID is not null then tbs.ex_contra_broker
                       when tbs.PAR_ORDER_ID is null and tbs.es_exchange_id = 'CBOE'
                           then ltrim(tbs.ES_CONTRA_BROKER, 'CBOE:')
                       when tbs.PAR_ORDER_ID is null then tbs.ES_CONTRA_BROKER end
               end                                                                                     as CONTRA_BROKER,

           case
               when tbs.ex_EXEC_TYPE = 'F' then
                   case
                       when tbs.PAR_ORDER_ID is not null then tbs.ex_CONTRA_TRADER
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
               when tbs.ex_EXEC_TYPE = 'F' then
                   case
                       when tbs.par_order_id is not null then tbs.cons_payment_per_contract
                       else tbs.STR_cons_payment_per_contract
                       end
               end                                                                                     as cons_payment_per_contract,
           tbs.CONTRA_CROSS_EXEC_QTY,

           --getContraCrossLPID(NVL(tbs.STR_ORDER_ID,CL.ORDER_ID))-- ALP.LP_DEMO_MNEMONIC

           CONTRA_CROSS_LP_ID,

           coalesce(tbs.strtg_decision_reason_code,
                    tbs.STR_strtg_decision_reason_code)                                                as STRATEGY_DECISION_REASON_CODE,
           cro.CROSS_TYPE,
           tbs.ex_fix_message_id                                                                       as parent_fix_message_id, -- ex.fix_message_id parent order
           tbs.es_FIX_MESSAGE_ID,
           tbs.ex_exchange_id,
           tbs.cl_exchange_id,
           tbs.es_exec_id,

           tbs.ac_account_id,
           I.SYMBOL,
           OS.ROOT_SYMBOL                                                                              as os_ROOT_SYMBOL,
           case tbs.MULTILEG_REPORTING_TYPE
               when '1' then 'O'
               when '2'
                   then 'M' end                                                                        as instrument_type,
           case
               when tbs.billing_code is not null then tbs.billing_code
               when tbs.ex_EXEC_TYPE = 'F' and
                    (coalesce(tbs.par_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   and dash_reporting.get_lp_list(tbs.ac_account_id, i.symbol, tbs.create_time::date) -- equal staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, in_date_id::text::date) is NOT null
                   then 'Exhaust'
               when tbs.ex_EXEC_TYPE = 'F' and
                    (coalesce(tbs.par_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   and staging.get_lp_list_lite(tbs.ac_ACCOUNT_ID, OS.ROOT_SYMBOL,
                                                case tbs.MULTILEG_REPORTING_TYPE
                                                    when '1' then 'O'
                                                    when '2' then 'M' end) is not null
                   then 'Exhaust'
               when tbs.ex_EXEC_TYPE = 'F' and
                    (coalesce(tbs.par_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   then 'Exhaust_IMC'
               end as BILLING_CODE,
           tbs.ac_account_demo_mnemonic,

           tbs.str_t9730,
           tbs.par_t9730,

           tbs.amex_bid_quantity                                                                       as BidSzA,
           tbs.amex_bid_price                                                                          as BidA,
           tbs.amex_ask_price                                                                          as AskA,
           tbs.amex_ask_quantity                                                                       as AskSzA,

           tbs.bato_bid_quantity                                                                       as BidSzZ,
           tbs.bato_bid_price                                                                          as BidZ,
           tbs.bato_ask_price                                                                          as AskZ,
           tbs.bato_ask_quantity                                                                       as AskSzZ,

           tbs.box_bid_quantity                                                                        as BidSzB,
           tbs.box_bid_price                                                                           as BidB,
           tbs.box_ask_price                                                                           as AskB,
           tbs.box_ask_quantity                                                                        as AskSzB,
--
           tbs.cboe_bid_quantity                                                                       as BidSzC,
           tbs.cboe_bid_price                                                                          as BidC,
           tbs.cboe_ask_price                                                                          as AskC,
           tbs.cboe_ask_quantity                                                                       as AskSzC,

           tbs.c2ox_bid_quantity                                                                       as BidSzW,
           tbs.c2ox_bid_price                                                                          as BidW,
           tbs.c2ox_ask_price                                                                          as AskW,
           tbs.c2ox_ask_quantity                                                                       as AskSzW,

           tbs.nqbxo_bid_quantity                                                                      as BidSzT,
           tbs.nqbxo_bid_price                                                                         as BidT,
           tbs.nqbxo_ask_price                                                                         as AskT,
           tbs.nqbxo_ask_quantity                                                                      as AskSzT,

           tbs.ise_bid_quantity                                                                        as BidSzI,
           tbs.ise_bid_price                                                                           as BidI,
           tbs.ise_ask_price                                                                           as AskI,
           tbs.ise_ask_quantity                                                                        as AskSzI,

           tbs.arca_bid_quantity                                                                       as BidSzP,
           tbs.arca_bid_price                                                                          as BidP,
           tbs.arca_ask_price                                                                          as AskP,
           tbs.arca_ask_quantity                                                                       as AskSzP,

           tbs.miax_bid_quantity                                                                       as BidSzM,
           tbs.miax_bid_price                                                                          as BidM,
           tbs.miax_ask_price                                                                          as AskM,
           tbs.miax_ask_quantity                                                                       as AskSzM,

           tbs.gemini_bid_quantity                                                                     as BidSzH,
           tbs.gemini_bid_price                                                                        as BidH,
           tbs.gemini_ask_price                                                                        as AskH,
           tbs.gemini_ask_quantity                                                                     as AskSzH,

           tbs.nsdqo_bid_quantity                                                                      as BidSzQ,
           tbs.nsdqo_bid_price                                                                         as BidQ,
           tbs.nsdqo_ask_price                                                                         as AskQ,
           tbs.nsdqo_ask_quantity                                                                      as AskSzQ,

           tbs.phlx_bid_quantity                                                                       as BidSzX,
           tbs.phlx_bid_price                                                                          as BidX,
           tbs.phlx_ask_price                                                                          as AskX,
           tbs.phlx_ask_quantity                                                                       as AskSzX,

           tbs.edgo_bid_quantity                                                                       as BidSzE,
           tbs.edgo_bid_price                                                                          as BidE,
           tbs.edgo_ask_price                                                                          as AskE,
           tbs.edgo_ask_quantity                                                                       as AskSzE,

           tbs.mcry_bid_quantity                                                                       as BidSzJ,
           tbs.mcry_bid_price                                                                          as BidJ,
           tbs.mcry_ask_price                                                                          as AskJ,
           tbs.mcry_ask_quantity                                                                       as AskSzJ,

           tbs.mprl_bid_quantity                                                                       as BidSzR,
           tbs.mprl_bid_price                                                                          as BidR,
           tbs.mprl_ask_price                                                                          as AskR,
           tbs.mprl_ask_quantity                                                                       as AskSzR,

           tbs.emld_bid_quantity                                                                       as BidSzD,
           tbs.emld_bid_price                                                                          as BidD,
           tbs.emld_ask_price                                                                          as AskD,
           tbs.emld_ask_quantity                                                                       as AskSzD,

           tbs.sphr_bid_quantity                                                                       as BidSzS,
           tbs.sphr_bid_price                                                                          as BidS,
           tbs.sphr_ask_price                                                                          as AskS,
           tbs.sphr_ask_quantity                                                                       as AskSzS,

           tbs.mxop_bid_quantity                                                                       as BidSzU,
           tbs.mxop_bid_price                                                                          as BidU,
           tbs.mxop_ask_price                                                                          as AskU,
           tbs.mxop_ask_quantity                                                                       as AskSzU

    from dash_reporting.imc_base_ext_md tbs
             inner join dwh.d_instrument i on i.instrument_id = tbs.instrument_id
             left join dwh.cross_order cro on cro.cross_order_id = tbs.cross_order_id
             left join dwh.d_exchange exc on exc.exchange_id = tbs.cl_exchange_id and exc.is_active

             left join dwh.d_option_contract oc on (oc.instrument_id = tbs.instrument_id)
             left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
             left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
             left join t_clearing_account ca
                       on tbs.ac_account_id = ca.account_id --and ca.is_default = 'Y' and ca.is_active and ca.market_type = 'O' and ca.clearing_account_type = '1'
             left join t_opt_exec_broker opx
                       on opx.account_id = tbs.ac_account_id --and opx.is_default = 'Y' and opx.is_active
             left join dwh.d_order_type ot on ot.order_type_id = tbs.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = tbs.time_in_force_id
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = tbs.sub_system_unq_id
    where true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: all data was prepared',
                           l_row_cnt, 'O')
    into l_step_id;
end;
$procedure$
;

call trash.so_imc_report_making(in_date_id := 20240801)

------------------------------------------------

select cl.order_id,
       cl.ex_exec_id,
       cl.ex_exchange_id,
       CL.STRATEGY_DECISION_REASON_CODE,
       cl.par_t9730,
       Cl.CROSS_TYPE,

       case
                   when --cl.STRATEGY_DECISION_REASON_CODE in ('74') and
                       cl.ex_exchange_id in
                       ('AMEX', 'BOX', 'CBOE', 'EDGO', 'GEMINI', 'ISE', 'MCRY', 'MIAX', 'NQBXO', 'PHLX')
                           and exists (select upper(description)
                                       from dwh.d_liquidity_indicator li
                                       where (upper(description) like '%FLASH%'
                                           or upper(description) like '%EXPOSURE%')
                                         and li.trade_liquidity_indicator = cl.ex_trade_liquidity_indicator)
                       then 'FLASH'
                   when CL.STRATEGY_DECISION_REASON_CODE in ('74') and substring(cl.par_t9730, 2, 1) in ('B', 'b', 's')
                       then 'FLASH'
                   when CL.STRATEGY_DECISION_REASON_CODE in ('74') and substring(cl.str_t9730, 2, 1) in ('B', 'b', 's')
                       then 'FLASH'
                   when CL.STRATEGY_DECISION_REASON_CODE in ('32', '62', '96', '99') then 'FLASH'
                   when Cl.CROSS_TYPE = 'P' then 'PIM'
                   when Cl.CROSS_TYPE = 'Q' then 'QCC'
                   when Cl.CROSS_TYPE = 'F' then 'Facilitation'
                   when Cl.CROSS_TYPE = 'S' then 'Solicitation'
                   else coalesce(CL.CROSS_TYPE, '') end,
    *
from dash_reporting.imc_final cl
where ex_exec_id in (54723278351, 54726649438);