select ftr.order_id, ftr.trade_record_id, ftr.orig_trade_record_id, ftr.exec_id, last_px, tcce_firm_execution_cost, last_px, symbol, display_instrument_id, display_instrument_id2, fmj.fix_message,
       * from dwh.flat_trade_record ftr
         join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
         join fix_capture.fix_message_json fmj on fmj.fix_message_id = ftr.order_fix_message_id and ftr.date_id = fmj.date_id
where ftr.date_id = 20250311
and ftr.street_client_order_id = 'CNAA3966-20250311'
and ftr.client_order_id = '20250311CSMS1417'
and is_busted = 'N'
and exec_id in (64500019291,
64500019279,
64500019284,
64500019267,
64500019297,
64500019270
);

19509684092
19509684092
19509684092
19509684091
19509684091
19509684091


select exec_id, last_px, * from dwh.execution ex
where order_id in (19509684091, 19509684092)
and exec_date_id = 20250311
          and ex.is_busted = 'N'
          and ex.exec_type not in ('E', 'S', 'D', 'y')
and exec_type = 'F'
  order by order_id, leaves_qty desc
/*and exec_id in (64500019291,
64500019279,
64500019284,
64500019267,
64500019297,
64500019270
)

 */

 select is_parent_level , is_busted , last_qty , last_px , exec_type, order_id , secondary_exch_exec_id , exch_exec_id , *
from execution
--where order_id in (19509684092,19509997932)
where order_id in (19509684091,19509997931)
and exec_id in (64500019265,64500019291)
and exec_date_id = 20250311
order by exec_time