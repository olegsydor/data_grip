select cl.parent_order_id, cl.order_id, fmj.fix_message_id, fix_message::jsonb->>'9730' as "9730", fix_message::jsonb->>'9882' as "9882", cl.strtg_decision_reason_code, * from dwh.client_order cl
         join fix_capture.fix_message_json fmj on fmj.client_order_id = cl.client_order_id
where cl.client_order_id = 'CDAB2262-20240423';



select cl.parent_order_id,
       cl.order_id,
       fmj.fix_message_id,
       fix_message::jsonb ->> '9730' as "9730",
       fix_message::jsonb ->> '9882' as "9882",
       cl.strtg_decision_reason_code,
       *
from dwh.client_order cl
    join dwh.execution ex on ex.order_id = cl.order_id and ex.exec_date_id >= cl.create_date_id
         left join fix_capture.fix_message_json fmj on fmj.fix_message_id = ex.fix_message_id--and fmj.date_id = ex.exec_date_id--fmj.client_order_id = cl.client_order_id
where cl.client_order_id = 'CDAB2262-20240423'
and cl.create_date_id = 20240423;


select fix_message::jsonb->>'9730' as "9730", fix_message::jsonb->>'9882' as "9882", fix_message::jsonb, * from fix_capture.fix_message_json
where client_order_id = 'CDAB2262-20240423';