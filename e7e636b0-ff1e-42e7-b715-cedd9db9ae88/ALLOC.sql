select trade_record_id , orig_trade_record_id , is_busted ,
trade_record_reason , secondary_order_id , secondary_exch_exec_id , last_qty , last_px , * from genesis2.trade_record tr
where tr.date_id = 20241129
and tr.secondary_exch_exec_id = 'S09GVAB00000001'
and tr.secondary_order_id = 'BKAA0009-20241129'
order by trade_record_id asc