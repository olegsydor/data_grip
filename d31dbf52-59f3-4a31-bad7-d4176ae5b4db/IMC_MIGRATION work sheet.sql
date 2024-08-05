
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
  and constr.create_date_id = :in_date_id;

create index on t_alp (cross_order_id, order_id);

-- Day part
create table trash.so_imc as
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
       cl.fix_connection_id,
       cl.side,
       cl.multileg_order_id,
       ex.exec_id                     as ex_exec_id,
       ex.exec_time                   as ex_exec_time,
       ex.exec_type                   as ex_exec_type,
       ex.cum_qty                     as ex_cum_qty,
       ex.order_status                as ex_order_status,
       ex.last_px                     as ex_last_px,
       ex.last_qty                    as ex_last_qty,
       ex.contra_account_capacity     as ex_contra_account_capacity,
       ex.trade_liquidity_indicator   as ex_trade_liquidity_indicator,
       ex.exch_exec_id                as ex_exch_exec_id,
       ex.exchange_id                 as ex_exchange_id,
       ex.contra_broker               as ex_contra_broker,
       ex.contra_trader               as ex_contra_trader,
       ex.secondary_order_id          as ex_secondary_order_id,
       ex.secondary_exch_exec_id      as ex_secondary_exch_exec_id,
       ex.exec_date_id                as ex_exec_date_id,
       ex.fix_message_id              as ex_fix_message_id,
       ac.trading_firm_id             as ac_trading_firm_id,
       ac.opt_is_fix_clfirm_processed as ac_opt_is_fix_clfirm_processed,
       ac.opt_customer_or_firm        as ac_opt_customer_or_firm,
       ac.account_id                  as ac_account_id,
       ac.account_demo_mnemonic       as ac_account_demo_mnemonic,
       opx.opt_exec_broker            as opx_opt_exec_broker,
       fc.acceptor_id                 as fc_acceptor_id,
       par.order_id                   as par_order_id,
       par.client_order_id            as par_client_order_id,
       par.create_date_id             as par_create_date_id,
       par.sub_strategy_desc          as par_sub_strategy_desc,
       par.order_type_id              as par_order_type_id,
       par.time_in_force_id           as par_time_in_force_id,
       str.cons_payment_per_contract  as str_cons_payment_per_contract,
       str.order_id                   as str_order_id,
       str.cross_order_id             as str_cross_order_id,
       str.strtg_decision_reason_code as str_strtg_decision_reason_code,
       str.request_number             as str_request_number,
       str.create_date_id             as str_create_date_id,
       es.FIX_MESSAGE_ID              as es_fix_message_id,
       es.exec_id                     as es_exec_id,
       es.contra_broker               as es_contra_broker,
       es.contra_account_capacity     as es_contra_account_capacity,
       es.contra_trader               as es_contra_trader,
       es.exchange_id                 as es_exchange_id
from dwh.client_order cl
         inner join dwh.execution ex on ex.order_id = cl.order_id
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

         left join dwh.client_order str
                   on (cl.order_id = str.parent_order_id
                       and ex.secondary_order_id = str.client_order_id
                       and ex.exec_type = 'F'
                       and str.create_date_id = :in_date_id
                       and str.parent_order_id is not null)
         left join dwh.execution es
                   on (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id and
                       es.exec_date_id = cl.create_date_id)
where true
  and ex.exec_date_id = :in_date_id
  and cl.create_date_id = :in_date_id
  and cl.multileg_reporting_type in ('1', '2')
  and ex.is_busted = 'N'
  and ex.exec_type not in ('E', 'S', 'D', 'y')
  and cl.trans_type <> 'F';

create index on trash.so_imc (order_id, ex_exec_id);



create temp table t_left_orders as
select order_id
from dwh.execution
where exec_date_id = :in_date_id
  and is_busted = 'N'
  and exec_type not in ('E', 'S', 'D', 'y')
except
select order_id
from trash.so_imc;
create index on t_left_orders (order_id);

analyze t_left_orders;


insert into trash.so_imc
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
       cl.fix_connection_id,
       cl.side,
       cl.multileg_order_id,
       ex.exec_id                     as ex_exec_id,
       ex.exec_time                   as ex_exec_time,
       ex.exec_type                   as ex_exec_type,
       ex.cum_qty                     as ex_cum_qty,
       ex.order_status                as ex_order_status,
       ex.last_px                     as ex_last_px,
       ex.last_qty                    as ex_last_qty,
       ex.contra_account_capacity     as ex_contra_account_capacity,
       ex.trade_liquidity_indicator   as ex_trade_liquidity_indicator,
       ex.exch_exec_id                as ex_exch_exec_id,
       ex.exchange_id                 as ex_exchange_id,
       ex.contra_broker               as ex_contra_broker,
       ex.contra_trader               as ex_contra_trader,
       ex.secondary_order_id          as ex_secondary_order_id,
       ex.secondary_exch_exec_id      as ex_secondary_exch_exec_id,
       ex.exec_date_id                as ex_exec_date_id,
       ex.fix_message_id              as ex_fix_message_id,
       ac.trading_firm_id             as ac_trading_firm_id,
       ac.opt_is_fix_clfirm_processed as ac_opt_is_fix_clfirm_processed,
       ac.opt_customer_or_firm        as ac_opt_customer_or_firm,
       ac.account_id                  as ac_account_id,
       ac.account_demo_mnemonic       as ac_account_demo_mnemonic,
       opx.opt_exec_broker            as opx_opt_exec_broker,
       fc.acceptor_id                 as fc_acceptor_id,
       par.order_id                   as par_order_id,
       par.client_order_id            as par_client_order_id,
       par.create_date_id             as par_create_date_id,
       par.sub_strategy_desc          as par_sub_strategy_desc,
       par.order_type_id              as par_order_type_id,
       par.time_in_force_id           as par_time_in_force_id,
       str.cons_payment_per_contract  as str_cons_payment_per_contract,
       str.order_id                   as str_order_id,
       str.cross_order_id             as str_cross_order_id,
       str.strtg_decision_reason_code as str_strtg_decision_reason_code,
       str.request_number             as str_request_number,
       str.create_date_id             as str_create_date_id,
       es.FIX_MESSAGE_ID              as es_fix_message_id,
       es.exec_id                     as es_exec_id,
       es.contra_broker               as es_contra_broker,
       es.contra_account_capacity     as es_contra_account_capacity,
       es.contra_trader               as es_contra_trader,
       es.exchange_id                 as es_exchange_id
from dwh.execution ex
    join t_left_orders tlo on ex.order_id = tlo.order_id
         inner join dwh.client_order cl on ex.order_id = cl.order_id
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

         left join lateral (select *
                            from dwh.client_order str
                            where (cl.order_id = str.parent_order_id
                                and ex.secondary_order_id = str.client_order_id
                                and ex.exec_type = 'F'
                                and str.create_date_id >= cl.create_date_id
                                and str.create_date_id >= :l_retention_date_id
                                and str.parent_order_id is not null)
                            limit 1) str on true
         left join lateral (select *
                            from dwh.execution es
                            where (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id
                                and es.exec_date_id >= cl.create_date_id
                                and es.exec_date_id >= :l_retention_date_id
                                      )
                            limit 1) es on true
where true
  and ex.exec_date_id = :in_date_id
--   and cl.create_date_id = :in_date_id
  and cl.multileg_reporting_type in ('1', '2')
  and ex.is_busted = 'N'
  and ex.exec_type not in ('E', 'S', 'D', 'y')
  and cl.trans_type <> 'F'
  and cl.create_date_id > :l_retention_date_id;

drop table if exists t_left_orders;
/*
select order_id, ex_exec_id
from trash.so_imc
except
select order_id, exec_id--, rec
from trash.imc_oracle_report
except
select order_id, ex_exec_id
from trash.so_imc;

select count(*)
from trash.so_imc
union all
select count(*)
from trash.imc_oracle_report
*/
-------------------------------------------
drop table if exists t_next;
create temp table t_next as
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
       coalesce(lnb.no_legs, 1)       as no_legs,
       case
           when cl.multileg_reporting_type = '2'
               then trash.get_multileg_leg_number(cl.order_id, cl.multileg_order_id) end
                                      as leg_number,
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
/*
           case
               when cl.par_order_id is null then cl.exch_order_id
               when cl.ac_trading_firm_id <> 'imc01' then (select exch_order_id
                                                        from dwh.client_order
                                                        where order_id = cl.par_order_id
--                                                          and create_date_id = :in_date_id
                                                        limit 1)
               else (select exch_order_id
                     from dwh.client_order
                     where order_id = (select max(parent_order_id)
                                       from dwh.client_order
                                       where cross_order_id = cl.cross_order_id
                                         and is_originator <> cl.is_originator
--                                         and create_date_id = :in_date_id
                                         )
                       and create_date_id = :in_date_id
                     limit 1)
               end                        as RFR_ID,--rfr_id

           case
               when cl.par_order_id is null then (select orig.exch_order_id
                                                     from dwh.client_order orig
                                                     where orig.order_id = cl.orig_order_id
--                                                       and orig.create_date_id = :in_date_id
                                                     limit 1)
               when cl.ac_trading_firm_id <> 'imc01' then (select orig.exch_order_id
                                                        from client_order co
                                                                 join dwh.client_order orig
                                                                      on orig.order_id = co.orig_order_id
--                                                                          and co.create_date_id = :in_date_id
                                                        where co.order_id = cl.par_order_id
--                                                          and orig.create_date_id = :in_date_id
                                                        limit 1)
               else (select orig.exch_order_id
                     from dwh.client_order orig
                              join dwh.client_order co on co.orig_order_id = orig.order_id
                     where co.order_id = (select max(parent_order_id) as max_orig_parent_order_id
                                          from dwh.client_order cr
                                          where cr.cross_order_id = cl.cross_order_id
                                            and cr.is_originator <> cl.is_originator
--                                            and cr.create_date_id = :in_date_id
                                          limit 1)
                       and orig.create_date_id = :in_date_id
                       and co.create_date_id = :in_date_id)
               end                        as ORIG_RFR_ID,--orig_rfr_id
*/

       case
           when cl.ex_exec_type in ('S', 'W') then orig.client_order_id
--                   (select orig.client_order_id from client_order orig where orig.order_id = tbs.orig_order_id) -- SO MOVED TO LATERAL
           end                        as REPLACED_ORDER_ID,
       case
           when cl.ex_exec_type in ('b', '4') then cxl.client_order_id
--                   (select min(cxl.client_order_id) from client_order cxl where cxl.orig_order_id = tbs.order_id) -- SO MOVED TO LATERAL
           end                        as cancel_order_id,
       case
           when cl.ex_exec_type = 'F' then
               (select LAST_QTY from EXECUTION exc where EXEC_ID = MCT.CONTRA_EXEC_ID and exec_date_id = :in_date_id)
           end                        as CONTRA_CROSS_EXEC_QTY,

       case
           when cl.PAR_ORDER_ID is null and cl.STR_CROSS_ORDER_ID is not null
               then cc_str.t_alp_agg
           when cl.PAR_ORDER_ID is not null and cl.CROSS_ORDER_ID is not null
               then cc.t_alp_agg
           end                        as CONTRA_CROSS_LP_ID,
       cl.es_FIX_MESSAGE_ID              as es_fix_message_id,
       cl.es_exec_id                     as es_exec_id,
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
                       coalesce(cl.par_SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                       coalesce(cl.request_number, cl.STR_request_number, -1) = -1)
                       then
                       case
                           when coalesce(cl.par_ORDER_TYPE_id, cl.ORDER_TYPE_id) in ('3', '4', '5', 'B')
                               then 'Exhaust_IMC'
                           when coalesce(cl.par_time_in_force_id, cl.time_in_force_id) in ('2', '7')
                               then 'Exhaust_IMC'
                           -- the other part is moved into the end part for billing_code!!!!!
--                               when (staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, :in_date_id::text::date) is null and
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
       cl.es_contra_broker               as es_contra_broker,
       cl.es_contra_account_capacity     as es_contra_account_capacity,
       cl.es_contra_trader               as es_contra_trader,
       cl.es_exchange_id                 as es_exchange_id,
       cl.ac_account_demo_mnemonic,
       cl.fc_acceptor_id,
       fmj.t9730                      as str_t9730,
       fmj_p.t9730                    as par_t9730

from trash.so_imc cl

         left join lateral (select fix_message ->> '9730' as t9730
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = cl.es_fix_message_id
                              and fmj.date_id = :in_date_id
                            limit 1) fmj on true
         left join lateral (select fix_message ->> '9730' as t9730
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = cl.ex_fix_message_id
                              and fmj.date_id = :in_date_id
                            limit 1) fmj_p on true
         left join trash.matched_cross_trades_pg mct on mct.orig_exec_id = coalesce(cl.es_exec_id, cl.ex_exec_id)
         left join lateral (select orig.client_order_id, exch_order_id
                            from dwh.client_order orig
                            where orig.order_id = cl.orig_order_id
                              and cl.ex_exec_type in ('S', 'W')
                              and orig.create_date_id <= :in_date_id
                              and cl.orig_order_id is not null
                            order by orig.create_date_id desc
                            limit 1) orig on true
         left join lateral (select cxl.client_order_id as client_order_id
                            from client_order cxl
                            where cxl.orig_order_id = cl.order_id
                              and cl.ex_exec_type in ('b', '4')
                              and cxl.create_date_id = :in_date_id --??
                              and cxl.orig_order_id is not null
                            order by cxl.order_id
                            limit 1) cxl on true
         left join lateral (select cnl.no_legs
                            from dwh.client_order cnl
                            where cnl.order_id = cl.multileg_order_id
                              and cnl.create_date_id = :in_date_id --??
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
                            limit 1) cc on true