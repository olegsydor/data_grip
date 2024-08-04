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
       par.order_id                   as par_order_id,
       par.client_order_id            as par_client_order_id,
       par.create_date_id             as par_create_date_id,
       par.sub_strategy_desc          as par_sub_strategy_desc,
       par.order_type_id              as par_order_type_id,
       par.time_in_force_id           as par_time_in_force_id,
       fc.acceptor_id                 as fc_acceptor_id
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
where true
  and ex.exec_date_id = :in_date_id
  and cl.create_date_id = :in_date_id
  and cl.multileg_reporting_type in ('1', '2')
  and ex.is_busted = 'N'
  and ex.exec_type not in ('E', 'S', 'D', 'y')
  and cl.trans_type <> 'F'
  and cl.create_date_id > :l_retention_date_id;

------------------------------------------------------

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
--            coalesce(lnb.no_legs, 1)       as no_legs,
--            case
-- 	           when cl.multileg_reporting_type = '2'
-- 	              then trash.get_multileg_leg_number(cl.order_id, cl.multileg_order_id) end
-- 	                                      as leg_number,
           cl.side,
           cl.ex_exec_id,
           cl.ex_exec_time,
           cl.ex_exec_type,
           cl.ex_cum_qty,
--            cl.ex_order_status,
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
cl.par_order_id,
       cl.par_client_order_id,
       cl.par_create_date_id,
       cl.par_sub_strategy_desc,
       cl.par_order_type_id,
       cl.par_time_in_force_id,
           str.cons_payment_per_contract  as str_cons_payment_per_contract,
           str.order_id                   as str_order_id,
           str.cross_order_id             as str_cross_order_id,
           str.strtg_decision_reason_code as str_strtg_decision_reason_code,
           str.request_number             as str_request_number,
           str.create_date_id             as str_create_date_id,
--            case
--                when cl.parent_order_id is null then cl.exch_order_id
--                when ac.trading_firm_id <> 'imc01' then (select exch_order_id
--                                                         from dwh.client_order
--                                                         where order_id = cl.parent_order_id)
--                else (select exch_order_id
--                      from dwh.client_order
--                      where order_id = (select max(parent_order_id)
--                                        from dwh.client_order
--                                        where cross_order_id = cl.cross_order_id
--                                          and is_originator <> cl.is_originator))
--                end                        as RFR_ID,--rfr_id
--            case
--                when cl.parent_order_id is null then (select orig.exch_order_id
--                                                      from dwh.client_order orig
--                                                      where orig.order_id = cl.orig_order_id
--                                                      limit 1)
--                when ac.trading_firm_id <> 'imc01' then (select orig.exch_order_id
--                                                         from dwh.client_order orig
--                                                                  join client_order co on co.orig_order_id = orig.order_id
--                                                         where co.order_id = cl.parent_order_id
--                                                         limit 1)
--                else (select orig.exch_order_id
--                      from dwh.client_order orig
--                               join dwh.client_order co on co.orig_order_id = orig.order_id
--                      where co.order_id = (select max(parent_order_id)
--                                           from dwh.client_order
--                                           where cross_order_id = cl.cross_order_id
--                                             and is_originator <> cl.is_originator))
--                end                        as ORIG_RFR_ID,--orig_rfr_id
--            case
--                when ex.exec_type in ('S', 'W') then orig.client_order_id
-- --                   (select orig.client_order_id from client_order orig where orig.order_id = tbs.orig_order_id) -- SO MOVED TO LATERAL
--                end                        as REPLACED_ORDER_ID,
--            case
--                when ex.exec_type in ('b', '4') then cxl.client_order_id
-- --                   (select min(cxl.client_order_id) from client_order cxl where cxl.orig_order_id = tbs.order_id) -- SO MOVED TO LATERAL
--                end                        as cancel_order_id,
--            case
--                when ex.EXEC_TYPE = 'F' then
--                        (select LAST_QTY from EXECUTION exc where EXEC_ID = MCT.CONTRA_EXEC_ID)
--                end                        as CONTRA_CROSS_EXEC_QTY,
--
--            case
--                when cl.PARENT_ORDER_ID is null and STR.CROSS_ORDER_ID is not null
--                    then cc_str.contr_str
--                when cl.PARENT_ORDER_ID is not null and cl.CROSS_ORDER_ID is not null
--                    then cc.contr
--                end                        as CONTRA_CROSS_LP_ID,
           es.FIX_MESSAGE_ID              as es_fix_message_id,
           es.exec_id                     as es_exec_id,
--            case
--                when ex.EXEC_TYPE = 'F' then
--                    case
--                        --
--                        when coalesce(pro.sub_strategy_desc, cl.sub_strategy_desc) = 'DMA' then 'DMA'
--                        when coalesce(pro.sub_strategy_desc, cl.sub_strategy_desc) in ('CSLDTR', 'RETAIL') and
--                             coalesce(cl.REQUEST_NUMBER, STR.request_number, -1) between 0 and 99 then 'IMC'
--                        when coalesce(pro.SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) in ('CSLDTR', 'RETAIL') and
--                             coalesce(cl.REQUEST_NUMBER, STR.REQUEST_NUMBER, -1) > 99 then 'Exhaust'
--                        when (
--                            coalesce(pro.SUB_STRATEGY_desc, cl.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
--                            coalesce(cl.request_number, STR.request_number, -1) = -1)
--                            then
--                            case
--                                when coalesce(pro.ORDER_TYPE_id, cl.ORDER_TYPE_id) in ('3', '4', '5', 'B')
--                                    then 'Exhaust_IMC'
--                                when coalesce(pro.time_in_force_id, cl.time_in_force_id) in ('2', '7')
--                                    then 'Exhaust_IMC'
--                                --                               when (staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, in_date_id::text::date) is null and
-- --                                     staging.get_lp_list_lite_tmp(ac.ACCOUNT_ID, OS.ROOT_SYMBOL,
-- --                                                              case cl.MULTILEG_REPORTING_TYPE
-- --                                                                  when '1' then 'O'
-- --                                                                  when '2' then 'M' end) is null)
-- --                                   then 'Exhaust_IMC'
-- --                               else 'Exhaust'
--                                end
--                        else 'Other'
--                        --
--                        end
--                end                        as BILLING_CODE,
           es.contra_broker               as es_contra_broker,
           es.contra_account_capacity     as es_contra_account_capacity,
           es.contra_trader               as es_contra_trader,
           es.exchange_id                 as es_exchange_id,
--            ac.account_demo_mnemonic,
           fc.acceptor_id,
           fmj.t9730                      as str_t9730,
           fmj_p.t9730                    as par_t9730
   ''
    from trash.so_imc cl
             left join dwh.client_order str
                       on (cl.order_id = str.parent_order_id and cl.ex_secondary_order_id = str.client_order_id and
                           cl.ex_exec_type = 'F' and str.create_date_id >= cl.create_date_id and str.parent_order_id is not null)
             left join dwh.execution es
                       on (es.order_id = STR.ORDER_ID and es.exch_exec_id = cl.ex_secondary_exch_exec_id and
                           es.exec_date_id >= str.create_date_id)

             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = es.fix_message_id
                                  and fmj.date_id = to_char(es.exec_time, 'YYYYMMDD')::int4
                                limit 1) fmj on true
             left join lateral (select fix_message ->> '9730' as t9730
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.ex_fix_message_id
                                  and fmj.date_id = to_char(cl.ex_exec_time, 'YYYYMMDD')::int4
                                limit 1) fmj_p on true

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
             left join lateral (select cnl.no_legs
                                from dwh.client_order cnl
                                where cnl.order_id = cl.multileg_order_id
                                limit 1) lnb on true

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
                                limit 1) cc on true
