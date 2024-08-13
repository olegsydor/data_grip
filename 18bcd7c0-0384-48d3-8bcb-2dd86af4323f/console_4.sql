select distinct cl_ord_id
--  (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::time at time zone 'UTC' at time zone 'US/Eastern')::time
from trash.so_20240812_disc
where true
and msg_type not in('1', '5')
	        and case
                  when (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::time at time zone 'UTC' at time zone
                        'US/Eastern')::time > '16:40'::time then
                      msg_type not in ('9', 'F')
                  else true end


select eod.*
--into trash.so_20240812_full
from partitions.hft_fix_message_event_20240812_eod eod
where load_batch_id = any ('{479150}')
  and not exists (select null
                  from partitions.hft_fix_message_event_20240812 inc
                  where inc.load_batch_id in
                        (478879, 478714, 478747, 478780, 478813, 478846, 478912, 478945, 478978, 479011, 479044, 479077,
                         479110)
                    and coalesce(inc.orig_cl_ord_id, '') = coalesce(eod.orig_cl_ord_id, '')
                    and inc.msg_type = eod.msg_type
                    and inc.cl_ord_id = eod.cl_ord_id
                    and inc.parent_cl_ord_id = eod.parent_cl_ord_id
                    and inc.fix_date = eod.fix_date
                    and inc.leg_ref_id is not distinct from eod.leg_ref_id)


with base as (select date_id,
                     fix_date,
                     msg_type,
                     sub_system_id,
                     sender_comp_id,
                     target_comp_id,
                     account_name,
                     cl_ord_id,
                     parent_cl_ord_id,
                     secondary_ord_id,
                     exch_exec_id,
                     sec_exch_exec_id,
                     exch_ord_id,
                     session_id,
                     orig_cl_ord_id,
                     security_type,
                     leg_cfi_code,
                     fix_msg_json,
                     exec_type,
                     leg_ref_id,
                     alternative_cl_ord_id
              from partitions.hft_fix_message_event_20240812_eod eod
              where load_batch_id = any ('{479150}')
              except
              select date_id,
                     fix_date,
                     msg_type,
                     sub_system_id,
                     sender_comp_id,
                     target_comp_id,
                     account_name,
                     cl_ord_id,
                     parent_cl_ord_id,
                     secondary_ord_id,
                     exch_exec_id,
                     sec_exch_exec_id,
                     exch_ord_id,
                     session_id,
                     orig_cl_ord_id,
                     security_type,
                     leg_cfi_code,
                     fix_msg_json,
                     exec_type,
                     leg_ref_id,
                     alternative_cl_ord_id
              from partitions.hft_fix_message_event_20240812 inc
              where load_batch_id = any
                    ('{478871,478706,478739,478772,478805,478838,478904,478937,478970,479003,479036,479069,479102}'))
select * into trash.so_20240812_full
from base

select * from trash.so_20240812_full