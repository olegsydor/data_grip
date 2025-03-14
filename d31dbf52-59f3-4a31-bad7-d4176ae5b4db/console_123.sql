select ftr.order_id, last_qty, tcce_firm_execution_cost, last_px, symbol, display_instrument_id, display_instrument_id2, fmj.fix_message,
       * from dwh.flat_trade_record ftr
         join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
         join fix_capture.fix_message_json fmj on fmj.fix_message_id = ftr.street_trade_fix_message_id and ftr.date_id = fmj.date_id
where ftr.date_id = 20250311
and ftr.street_client_order_id = 'CNAA3966-20250311'
and ftr.client_order_id = '20250311CSMS1417'
and is_busted = 'N'


select * from dwh.execution ex
where order_id in (19509684091, 19509684092)
and exec_date_id = 20250311
          and ex.is_busted = 'N'
          and ex.exec_type not in ('E', 'S', 'D', 'y')
and exec_type = 'F'
and exec_id in (64500019291,
64500019279,
64500019284,
64500019267,
64500019297,
64500019270
)