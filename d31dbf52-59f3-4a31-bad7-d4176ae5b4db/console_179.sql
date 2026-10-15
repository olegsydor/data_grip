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
and fmj.fix_message_id in (511225838383750452,511221818295383500);


select fmj.fix_message_id,
       matched.obj ->> '10707' as tag_10707,
       matched.obj ->> '10609' as tag_10609
from fix_capture.fix_message_json fmj
         left join lateral (
    select g.obj
    from jsonb_array_elements(
                 case
                     when fmj.fix_message_jsonb ? '552' then fmj.fix_message_jsonb -> '552'
                     else jsonb_build_array(fmj.fix_message_jsonb)
                     end
         ) as g(obj)
    where not (fmj.fix_message_jsonb ? '552')
       or (
        g.obj ->> '11' = :in_tag_11
            and g.obj ->> '10009' = :in_tag_10009
        )
    ) matched on true
where fmj.date_id = 20261009
  and fmj.fix_message_id in (511225838383750452, 511221818295383500);