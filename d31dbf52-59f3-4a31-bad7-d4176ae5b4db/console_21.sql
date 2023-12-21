ac.trading_firm_id in ('baml')
select * from d_target_strategy
where d_target_strategy.target_strategy_desc ilike 'SENSOR%'

select * from dwh.d_exchange
where exchange_id ilike '%BATSML%'

select al from dwh.client_order

select * from d_routing_table