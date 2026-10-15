select ftr.order_id,
       ftr.client_order_id,
       ftr.order_fix_message_id,
       ftr.is_cross_order,
       fmj.fix_message ->> '10707' AS tag_10707,
       *
from dwh.flat_trade_record ftr
         inner join fix_capture.fix_message_json fmj
                    on fmj.fix_message_id = ftr.order_fix_message_id and fmj.date_id = ftr.date_id
where ftr.date_id = 20261009
  and ftr.trade_record_id in (
                              5519282182, 5519283182
    )




select * from fix_capture.fix_message_json fmj
where fmj.date_id = 20261009
and fmj.fix_message_id in (511225838383750452,511221818295383500)