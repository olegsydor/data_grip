-- create index on partitions.hft_fix_message_event_20240502_eod (cl_ord_id, msg_type, exec_type)

select load_batch_id, count(*)--orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id --142138
from partitions.hft_fix_message_event_20240502_eod
where load_batch_id = any ('{435084,435060,435061,435064,435065,435071,435072,435069,435070,435067,435063, 435058}')
group by load_batch_id
except
select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20240502
where load_batch_id = any ('{434995,434929,434896,434962}')


select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id --142138
from partitions.hft_fix_message_event_20240502_eod
where load_batch_id = any ('{435084,435060,435061,435064,435065,435071,435072,435069,435070,435067,435063, 435058}')
and cl_ord_id in ('HFECNV5581', 'HFEEGQ0666')
except
select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20240502
where load_batch_id = any ('{434995,434929,434896,434962}')
and cl_ord_id in ('HFECNV5581', 'HFEEGQ0666')