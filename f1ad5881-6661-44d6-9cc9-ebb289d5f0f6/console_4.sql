select ex.order_id, cl.parent_order_id
from dwh.execution ex
         join lateral (select parent_order_id
                       from dwh.client_order cl
                       where cl.order_id = ex.order_id
                         and cl.create_date_id <= ex.exec_date_id
                         and cl.parent_order_id is not null
                       limit 1 ) cl on true
where exec_date_id = 20240306


status_date_id
order_id
create_date_id
time_in_Force_id
account_id
trading_firm_id / trading_firm_unq_id !?!?!
instrument_id
instrument_type_id
number_of streets
number_of_trades
order_qty
street_order_qty
last_qty / traded_qty ?????- means sum(last_qty)
vwap ???
pg_db_create_time
pg_db_update_time
process_time