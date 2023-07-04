select rt.routing_table_id,
       tf1.trading_firm_name,
       acc.account_name,
       rt.routing_table_name,
       case rt.intended_scope_of_use
           when 'A' then 'Account-specific'
           when 'D' then 'Platform-wide (default)'
           when 'T' then 'Trading firm-specific'
           end ::character varying             as intended_scope_of_use,
       case rt.owner
           when 'D' then 'DASH administrator'
           when 'T' then 'Trading firm manager'
           end ::character varying             as owner,
       tf.trading_firm_name                    as owner_trading_firm,
--       rt.is_active,
       rt.is_default::character,
       rt.routing_table_desc,
       case rt.account_class_id
           when 'S' then 'Standard'
           when 'H' then 'Hammer'
           when 'G' then 'Giveup'
           end ::character varying             as account_class,
       case rt.instr_class_id
           when 'PP' then 'Penny Premium'
           when 'PN' then 'Penny Non-Premium'
           when 'NP' then 'Nickel Premium'
           when 'NN' then 'Nickel Non-Premium'
           end ::character varying             as instrument_class,
       case rt.routing_table_type
           when 'C' then 'Specific for option instrument class'
           when 'L' then 'Specific for symbol list'
           when 'S' then 'Specific for option root symbol or equity symbol'
           when 'T' then 'Specific for instrument type'
           end ::character varying             as routing_table_type,
       case rt.instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           when 'M' then 'Multileg'
           end ::character varying             as instrument_type,
       rt.root_symbol::character varying,
       rt.symbol_suffix::character varying,
       rt.symbol_list_id::character varying,
       case rt.capacity_group_id
           when 1 then 'Customer'
           when 2 then 'Pro Cust'
           when 3 then 'Non Cust'
           when 4 then 'Market Maker'
           when 21 then 'Firm'
           when 22 then 'Broker/Dealer'
           when 41 then 'JBO'
           when 42 then 'NTPH'
           end ::character varying             as capacity_group,
       rt.market_state,
       target_strategy_name::character varying as sub_strategy,
       rt.fee_sensitivity::int4,
       rta.num_of_orders,
       rta.num_of_accounts,
       rta.num_of_trading_firms,
       rta.total_order_qty,
       rta.total_exec_qty,
       rta.principal_amount,
       rta.last_routed_time,
       rta.last_trade_time,
       rta.min_routed_time,
       rta.min_trade_time
from dwh.d_routing_table rt
-- from staging.routing_table rt
         left join (select case when :p_mode = 'A' then co.account_id else null end               account_id,
                           case when :p_mode in ('T', 'A') then acc.trading_firm_id else null end trading_firm_id,
                           co.routing_table_id,
                           count(distinct (co.client_order_id))                                   num_of_orders,
                           count(distinct (co.account_id))                                        num_of_accounts,
                           count(distinct (acc.trading_firm_id))                                  num_of_trading_firms,
                           sum(co.order_qty)                                                      total_order_qty,
                           sum(ftr.exec_qty)                                                      total_exec_qty,
                           sum(ftr.principal_amount)                                              principal_amount,
                           max(co.process_time)                                                   last_routed_time,
                           max(ftr.trade_record_time)                                             last_trade_time,
                           min(co.process_time)                                                   min_routed_time,
                           min(ftr.trade_record_time)                                             min_trade_time
                    from dwh.client_order co
                             inner join dwh.d_account acc on acc.account_id = co.account_id
                             left join (select ftr.order_id,
                                               sum(ftr.last_qty)          exec_qty,
                                               max(ftr.trade_record_time) trade_record_time,
                                               sum(ftr.principal_amount)  principal_amount
                                        from dwh.flat_trade_record ftr
                                        where ftr.date_id between :p_start_status_date_id and :p_end_status_date_id
                                          and ftr.is_busted = 'N'
                                          and order_id > 0
--                      and case when p_client_ids = '{}' then 1=1 else ftr.client_id = any(p_client_ids) end
                                        group by ftr.order_id) ftr on co.order_id = ftr.order_id
                    where co.create_date_id between :p_start_status_date_id and :p_end_status_date_id
                      and co.parent_order_id is null
                      and co.multileg_reporting_type in ('1', '2')
--                  and (p_trading_firm_ids is null or acc.trading_firm_id=any(p_trading_firm_ids))
--                  and case when p_client_ids = '{}' then 1=1 else co.client_id_text = any(p_client_ids) end
                    group by 1, 2, 3) rta on rta.routing_table_id = rt.routing_table_id
         left join data_marts.d_sub_strategy ss on ss.sub_strategy_id = rt.target_strategy
         left join dwh.d_trading_firm tf on rt.owner_trading_firm_id = tf.trading_firm_id and tf.is_active
         left outer join dwh.d_account acc on acc.account_id = rta.account_id and acc.is_active
         left outer join dwh.d_trading_firm tf1 on tf1.trading_firm_id = rta.trading_firm_id and tf1.is_active
         left outer join dwh.d_target_strategy ts on ts.target_strategy_id = rt.target_strategy
-- where rt.is_deleted = 'N'
where rt.routing_table_id = 20469
and rt.is_active;

select *
-- from dwh.d_routing_table rt
from staging.routing_table rt