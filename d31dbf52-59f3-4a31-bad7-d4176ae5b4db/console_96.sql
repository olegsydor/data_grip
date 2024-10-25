select * from dwh.gtc_order_status
where close_date_id is not null
and closing_reason = 'I'
and 