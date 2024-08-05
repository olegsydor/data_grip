
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
drop table if exists trash.so_imc;
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

       ex.exec_id                     as ex_exec_id,
       ex.exec_time                   as ex_exec_time,
       ex.exec_type                   as ex_exec_type,
       ex.cum_qty                     as ex_cum_qty,
       ex.order_status                as order_status,
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
  and cl.trans_type <> 'F'
  and cl.create_date_id > :l_retention_date_id;
create index on trash.so_imc (order_id, ex_exec_id);


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

       ex.exec_id                     as ex_exec_id,
       ex.exec_time                   as ex_exec_time,
       ex.exec_type                   as ex_exec_type,
       ex.cum_qty                     as ex_cum_qty,
       ex.order_status                as order_status,
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
                       and str.create_date_id >= cl.create_date_id
                       and str.parent_order_id is not null)
         left join dwh.execution es
                   on (es.order_id = STR.ORDER_ID and es.exch_exec_id = ex.secondary_exch_exec_id and
                       es.exec_date_id >= cl.create_date_id)
where true
  and ex.exec_date_id = :in_date_id
--   and cl.create_date_id = :in_date_id
  and cl.multileg_reporting_type in ('1', '2')
  and ex.is_busted = 'N'
  and ex.exec_type not in ('E', 'S', 'D', 'y')
  and cl.trans_type <> 'F'
  and cl.create_date_id > :l_retention_date_id
 and not exists (select null from trash.so_imc tao where tao.order_id = ex.order_id)
;