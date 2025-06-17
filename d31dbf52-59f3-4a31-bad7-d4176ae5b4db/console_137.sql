select *
from dwh.client_order cl
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id
         join dwh.target_strategy ts on ts.target_strategy_id = cl.sub_strategy_id and ts.is_active
where true
  and parent_order_id is not null
  and create_date_id between 20250407 and 20250410
  and cl.account_id in (select account_id
                        from dwh.d_trading_firm tf
                                 join dwh.d_account ac using (trading_firm_id)
                        where trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus', 'Cowen Prime Services')
                          and ac.is_active
                          and tf.is_active)
  and di.instrument_type_id = 'E'
  and ts.target_strategy_name = 'SENSOR'


    select * from dwh.d_target_strategy