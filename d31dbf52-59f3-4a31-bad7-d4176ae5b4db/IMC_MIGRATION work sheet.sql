
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
       cl.multileg_order_id,
       cl.dash_rfr_id,
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
       cl.dash_rfr_id,
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
  and cl.create_date_id > :l_retention_date_id
---  and not exists (select null from trash.so_imc tao where tao.order_id = ex.order_id)
;

-------------------------------------------
drop table if exists trash.so_imc_base;
create table trash.so_imc_base as
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

           case
               when cl.par_order_id is null then cl.exch_order_id
               else cl.dash_rfr_id
               end                        as rfr_id,--rfr_id

                     case
                         when cl.par_order_id is null then orig.exch_order_id
                         when cl.ac_trading_firm_id <> 'imc01' then orig.exch_order_id
                         else orig.exch_order_id
                         end as ORIG_RFR_ID,--orig_rfr_id


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
;

drop table if exists trash.so_imc_base;
create table trash.so_imc_base as
select * from trash.so_imc_ext cl
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
                              and ls.start_date_id = :in_date_id
                            group by ls.transaction_id
                            limit 1
    ) md on true;




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


create table trash.so_imc_fin as
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
               then ui.symbol end                                                               as base_code,
       case i.instrument_type_id
           when 'E' then i.symbol
           when 'O'
               then os.root_symbol end                                                          as root_symbol,
       case ui.instrument_type_id when 'E' then 'EQUITY' when 'I' then 'INDEX' end              as base_asset_type,
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
       OS.ROOT_SYMBOL                                                                           as os_ROOT_SYMBOL,
       case tbs.MULTILEG_REPORTING_TYPE
           when '1' then 'O'
           when '2'
               then 'M' end                                                                        as instrument_type,
       tbs.BILLING_CODE,
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
-----
       tbs.sphr_bid_quantity                                                                       as BidSzS,
       tbs.sphr_bid_price                                                                          as BidS,
       tbs.sphr_ask_price                                                                          as AskS,
       tbs.sphr_ask_quantity                                                                       as AskSzS,

       tbs.mxop_bid_quantity                                                                       as BidSzU,
       tbs.mxop_bid_price                                                                          as BidU,
       tbs.mxop_ask_price                                                                          as AskU,
       tbs.mxop_ask_quantity                                                                       as AskSzU

from trash.so_imc_base tbs
    inner join dwh.d_instrument i on i.instrument_id = tbs.instrument_id
--          inner join lateral (select i.instrument_type_id, i.symbol
--                              from dwh.d_instrument i
--                              where i.instrument_id = tbs.instrument_id
--                              limit 1) i on true
--              inner join dwh.d_fix_connection fc on (fc.fix_connection_id = tbs.fix_connection_id)
         left join dwh.cross_order cro on cro.cross_order_id = tbs.cross_order_id
         left join dwh.d_exchange exc on exc.exchange_id = tbs.cl_exchange_id and exc.is_active
--          left join lateral (
--     select oc.instrument_id,
--            oc.opra_symbol,
--            oc.maturity_year,
--            oc.maturity_month,
--            oc.maturity_day,
--            oc.strike_price,
--            oc.put_call,
--            os.root_symbol        as os_root_symbol,
--            ui.instrument_type_id as ui_instrument_type_id,
--            ui.symbol             as ui_symbol
--     from dwh.d_option_contract oc
--              left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
--              left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
--     where oc.instrument_id = tbs.instrument_id
--     limit 1) oc on true
                 left join dwh.d_option_contract oc on (oc.instrument_id = tbs.instrument_id)
             left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
             left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
         left join t_clearing_account ca
                   on tbs.ac_account_id = ca.account_id --and ca.is_default = 'Y' and ca.is_active and ca.market_type = 'O' and ca.clearing_account_type = '1'
         left join t_opt_exec_broker opx on opx.account_id = tbs.ac_account_id --and opx.is_default = 'Y' and opx.is_active
         left join dwh.d_order_type ot on ot.order_type_id = tbs.order_type_id
         left join dwh.d_time_in_force tif on tif.tif_id = tbs.time_in_force_id
         left join dwh.d_sub_system dss on dss.sub_system_unq_id = tbs.sub_system_unq_id
where true;



select cl.transaction_id,
           cl.order_id,
           cl.ex_exec_id as exec_id,
           cl.ac_trading_firm_id || ',' || --EntityCode
           to_char(cl.create_time, 'YYYYMMDD') || ',' || --CreateDate
           to_char(cl.create_time, 'HH24MISSFF3') || ',' || --CreateTime
           to_char(cl.ex_exec_time, 'YYYYMMDD') || ',' || --StatusDate
           to_char(cl.ex_exec_time, 'HH24MISSFF3') || ',' || --StatusTime
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
           coalesce(to_char(cl.ex_last_px, 'FM999990D0099'), '') || ',' || --StatusPrice
           coalesce(cl.order_qty::text, '') || ',' || --EnteredQty
-- ask++
           coalesce(cl.ex_last_qty::text, '') || ',' || --StatusQty
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
           coalesce(staging.get_trade_liquidity_indicator(cl.ex_trade_liquidity_indicator), '') || ',' || --Maker/Take
           coalesce(cl.ex_exch_exec_id, '') || ',' || --ExchangeTransactionID
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
               else coalesce(CL.CROSS_TYPE, '') end || ',' || --Auc.type


           coalesce(cl.request_count, '') || ',' || --Req.count
           coalesce(cl.billing_code, '') || ',' ||--Billing Code
           coalesce(cl.contra_broker, '') || ',' || --ContraBroker
           coalesce(cl.contra_trader, '') || ',' || --ContraTrader
           coalesce(cl.white_list, '') || ',' || --WhiteList
           coalesce(staging.trailing_dot(cl.cons_payment_per_contract), '') || ',' ||
           coalesce(cl.contra_cross_exec_qty::text, '') || ',' ||
           coalesce(cl.contra_cross_lp_id, '') || ',' ||
           coalesce(cl.ac_account_demo_mnemonic, '')
               as rec
    from trash.so_imc_fin cl;

select cl.order_id,
       cl.multileg_order_id,
       cl.multileg_reporting_type,
       cl.co_client_leg_ref_id as pg_leg_number,
       (select client_leg_ref_id from dwh.client_order_leg col where col.order_id = cl.order_id) as ora_leg_number,
       case
           when cl.multileg_reporting_type = '2'
               then trash.get_multileg_leg_number(cl.order_id, cl.multileg_order_id) end
           as leg_number,
    lnb.no_legs,
    *
from dwh.client_order cl
    join dwh.execution ex on ex.order_id = cl.order_id
             left join lateral (select cnl.no_legs
                                from dwh.client_order cnl
                                where cnl.order_id = cl.multileg_order_id
--                                   and cnl.create_date_id = :in_date_id --??
--                                       and cnl.create_date_id >= :l_retention_date_id
                                limit 1) lnb on true
where cl.order_id = 16575861885
and ex.exec_id = 54948658879
and ex.exec_date_id = :in_date_id

select * from dwh.client_order_leg col where col.order_id =16572988717


select cl.order_id,
       cl.parent_order_id,
       ac.trading_firm_id,
       cl.exch_order_id,
       (select max(parent_order_id)
        from dwh.client_order
        where cross_order_id = cl.cross_order_id
          and is_originator <> cl.is_originator)                       as max_cross_order_id,
(select ORIG.EXCH_ORDER_ID from CLIENT_ORDER ORIG, CLIENT_ORDER CO where ORIG.ORDER_ID = CO.ORIG_ORDER_ID and CO.ORDER_ID =  CL.PARENT_ORDER_ID) as oracle_orig,
orig.exch_order_id,
    (select orig.exch_order_id
        from dwh.client_order co
                 join dwh.client_order orig on co.orig_order_id = orig.order_id
        where co.order_id = (select max(parent_order_id)
                             from dwh.client_order
                             where cross_order_id = cl.cross_order_id
                               and is_originator <> cl.is_originator)) as orig_rfr_id_true,

       case
           when par.order_id is null then orig.exch_order_id
           when ac.trading_firm_id <> 'imc01' then (select orig.exch_order_id
                                                           from dwh.client_order orig
                                                           where orig.order_id = par.orig_order_id
                                                           limit 1)
--            else (select orig.exch_order_id
--                      from dwh.client_order co
--                               join dwh.client_order orig on co.orig_order_id = orig.order_id
--                      where co.order_id = cl.max_orig_parent_order_id
--                      and co.create_date_id >= l_retention_date_id
--                      and orig.create_date_id >= l_retention_date_id)
           end                                                         as ORIG_RFR_ID,--orig_rfr_id
       ''
from dwh.client_order cl
         join dwh.d_account ac on ac.account_id = cl.account_id
         join dwh.execution ex on ex.order_id = cl.order_id
         left join lateral (select cxl.client_order_id as client_order_id, cxl.create_date_id
                            from client_order cxl
                            where cxl.orig_order_id = cl.order_id
--                                   and cl.ex_exec_type in ('b', '4')
                              and cxl.create_date_id = :in_date_id --??
                              and cxl.orig_order_id is not null
                              and cxl.create_date_id >= :l_retention_date_id
--                                 order by cxl.order_id
                            order by cxl.client_order_id
                            limit 10) cxl on true
         left join lateral (select order_id,
                                   client_order_id,
                                   create_date_id,
                                   sub_strategy_desc,
                                   ORDER_TYPE_id,
                                   time_in_force_id,
                                   exch_order_id,
                                   orig_order_id
                            from dwh.client_order pro
                            where cl.parent_order_id = pro.order_id
                              and pro.create_date_id = get_dateid(cl.parent_order_process_time::date)
                              and pro.parent_order_id is null
                              and cl.parent_order_id is not null
                              and pro.create_date_id >= :l_retention_date_id
                            order by create_date_id desc
                            limit 1) par on true
         left join lateral (select orig.client_order_id, exch_order_id
                            from dwh.client_order orig
                            where orig.order_id = cl.orig_order_id
--                                   and cl.ex_exec_type in ('S', 'W')
                              and orig.create_date_id <= :in_date_id
                              and cl.orig_order_id is not null
                              and orig.create_date_id >= :l_retention_date_id
                            order by orig.create_date_id desc
                            limit 1) orig on true
where cl.order_id = 16628220611
--   and ex.exec_id = 54997186681
  and ex.exec_date_id = :in_date_id
;

select no_legs, co_client_leg_ref_id, * from dwh.client_order
where order_id = 16623856596;


select co.no_legs, lnb.no_legs, left(co_client_leg_ref_id, 1), multileg_order_id, * from dwh.client_order co
--          join fix_capture.fix_message_json fmj on fmj.fix_message_id = co.fix_message_id
                                         left join lateral (select cnl.no_legs
                                from dwh.client_order cnl
                                where cnl.order_id = co.multileg_order_id
--                                   and cnl.create_date_id = :in_date_id --??
--                                       and cnl.create_date_id >= :l_retention_date_id
                                limit 10) lnb on true
    where true
        and co.create_date_id = 20240808
      and order_id = 16623856596
and multileg_order_id = 16623856596

select left(null::varchar(30));

alter function trash.get_multileg_leg_number_old rename to get_multileg_leg_number;

create or replace function trash.get_multileg_leg_number(in_order_id bigint, in_multileg_order_id bigint, in_min_date_id int4)
    returns int4
    language plpgsql
    IMMUTABLE
as
$function$
declare
    l_leg_number int4;
begin
    select rn
    into l_leg_number
    from (select order_id, dense_rank() over (partition by multileg_order_id order by order_id) as rn
          from dwh.client_order
          where multileg_order_id = in_multileg_order_id
          and create_date_id >= in_min_date_id) x
    where order_id = in_order_id
    limit 1;
    return l_leg_number;
end;
$function$
;


select rn
    into l_leg_number
    from (select order_id, dense_rank() over (partition by multileg_order_id order by order_id) as rn
          from dwh.client_order
          where multileg_order_id = 16293729942
          and create_date_id >= 20230901) x
    where order_id = in_order_id
    limit 1;

select trash.get_multileg_leg_number(in_order_id := 16293729946, in_multileg_order_id := 16293729942, in_min_date_id := 20230901)

select multileg_order_id, * from dwh.client_order
where true
     and multileg_order_id = 16293729942
and order_id = 16293729946;


    select rn
    from (select order_id, dense_rank() over (partition by multileg_order_id order by order_id) as rn
          from dwh.client_order
          where multileg_order_id = :in_multileg_order_id) x
    where order_id = in_order_id;


select exch_order_id, * from dwh.client_order
where order_id = 16647044468
;

select order_id, dense_rank() over (partition by multileg_order_id order by order_id) as rn, *
          from dwh.client_order
          where multileg_order_id = :in_multileg_order_id
          and create_date_id >= :in_min_date_id

select cl.order_id, ex.is_busted, ex.exec_type, cl.trans_type, dense_rank() over (partition by cl.multileg_order_id order by cl.order_id) as rn,
       rn.*, *
from dwh.client_order cl
             inner join dwh.execution ex on ex.order_id = cl.order_id
             inner join dwh.d_fix_connection fc
                        on (fc.fix_connection_id = cl.fix_connection_id and fc.fix_comp_id <> 'IMCCONS')
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_trading_firm tf
                        on (tf.trading_firm_id = ac.trading_firm_id and tf.is_eligible4consolidator = 'Y')
             left join dwh.d_opt_exec_broker opx on opx.opt_exec_broker_id = cl.opt_exec_broker_id
left join lateral (
    select rn from (select order_id, dense_rank() over (partition by co.multileg_order_id order by co.order_id) as rn
                    from dwh.client_order co
                    where co.multileg_order_id = cl.multileg_order_id) x
    where x.order_id = cl.order_id
    and cl.multileg_order_id is not null
    limit 1
    ) rn on true
    where true
      and ex.exec_date_id = :in_date_id
--       and cl.create_date_id = :in_date_id
      and cl.multileg_reporting_type in ('1', '2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
and cl.order_id in (16293729943,16293729946)
;
drop table if exists trash.so_imc_base;
create table trash.so_imc_base as
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
       cl.dash_rfr_id,
--            case
--                when cl.multileg_order_id is not null then
--                    trash.get_multileg_leg_number(cl.order_id, cl.multileg_order_id, l_retention_date_id)
--                end as leg_number,
       rn.rn                          as leg_number,
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
       par.exch_order_id              as par_exch_order_id,
       par.orig_order_id              as par_orig_order_id,
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
       es.exchange_id                 as es_exchange_id,
       case
           when cl.parent_order_id is not null and ac.trading_firm_id = 'imc01' then
               (select max(parent_order_id)
                from dwh.client_order co
                where co.cross_order_id = cl.cross_order_id
                  and co.is_originator <> cl.is_originator
                  and co.create_date_id > :l_retention_date_id)
           else null end              as max_orig_parent_order_id
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
                                   order_type_id,
                                   time_in_force_id,
                                   exch_order_id,
                                   orig_order_id
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
         left join lateral (
    select rn
    from (select order_id, dense_rank() over (partition by co.multileg_order_id order by co.order_id) as rn
          from dwh.client_order co
          where co.multileg_order_id = cl.multileg_order_id
            and co.create_date_id >= :l_retention_date_id) x
    where x.order_id = cl.order_id
      and cl.multileg_order_id is not null
    limit 1
    ) rn on true
where true
  and ex.exec_date_id = :in_date_id
--   and cl.create_date_id = :in_date_id
  and cl.multileg_reporting_type in ('1', '2')
  and ex.is_busted = 'N'
  and ex.exec_type not in ('E', 'S', 'D', 'y')
  and cl.trans_type <> 'F'
and cl.order_id in (16591626591);

select trash.get_multileg_leg_number(in_order_id := cl.order_id, in_multileg_order_id := cl.multileg_order_id, in_min_date_id := cl.create_date_id),
* from dwh.client_order cl
where true
and order_id in (16591626591, 16293729943,16293729946);
