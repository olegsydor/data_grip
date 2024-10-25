select
    last_trade_date, last_trade_date::time, close_date_id, db_update_time
--     time_in_force_id, count(*)
from dwh.gtc_order_status
where close_date_id is not null
and closing_reason = 'I'
and to_char(last_trade_date, 'YYYYMMDD')::int < to_char(db_update_time, 'YYYYMMDD')::int
and close_date_id > 20240101
and time_in_force_id = '6'
order by 2
