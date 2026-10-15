select ftr.order_id,
       ftr.client_order_id,
       ftr.order_fix_message_id,
       ftr.is_cross_order,
       fmj.fix_message ->> '10707' AS tag_10707,
       ftr.cross_is_originator
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


create or replace function trash.get_repeating_tags(in_fix_message_id int8, in_date_id int4,
                                                    in_client_order_id varchar(256), in_cross_is_originator char)
    returns table
            (
                tag_10707 text,
                tag_10609 text
            )
    language sql
as
$fx$
select matched.obj ->> '10707' as tag_10707,
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
        g.obj ->> '11' = in_client_order_id
            and g.obj ->> '10009' = in_cross_is_originator
        )
    ) matched on true
where fmj.date_id = in_date_id
  and fmj.fix_message_id = in_fix_message_id
limit 1;
$fx$
;

select * from trash.get_repeating_tags(in_fix_message_id := 511221818295383500, in_date_id := 20261009, in_client_order_id := '1_1p1261009', in_cross_is_originator := 'O');

select ftr.trade_record_id, ftr.order_fix_message_id,
       (trash.get_repeating_tags(in_fix_message_id := ftr.order_fix_message_id, in_date_id := ftr.date_id,
                                in_client_order_id := ftr.client_order_id,
                                in_cross_is_originator := ftr.cross_is_originator)).*
from dwh.flat_trade_record ftr
join fix_capture.fix_message_json fmj on fmj.fix_message_id = ftr.order_fix_message_id and fmj.date_id = ftr.date_id
where ftr.date_id = 20261009
  and fmj.fix_message->>'10609' is not null
and ftr.trade_record_id in (5519282182, 5519283182)


select tag_10609,
       tag_10707
           as lifecycleorderid
from trash.get_repeating_tags(in_fix_message_id := 511221818295383500, in_date_id := 20261009,
                              in_client_order_id := '1_1p1261009', in_cross_is_originator := 'O')
limit 1