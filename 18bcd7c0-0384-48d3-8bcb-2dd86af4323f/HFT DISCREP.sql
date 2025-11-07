select 499046330-499046322;

with base_inc as (
select split_part(RIGHT(filename, POSITION('/' in REVERSE(filename)) -1 ), '.', 1) as fn, sum(processed_rows) as loaded_row, array_agg(load_batch_id) as batchs
from inc_hft.hft_incremental_files
where date_id = :p_date_id
and is_active= 'Y'
group by split_part(RIGHT(filename, POSITION('/' in REVERSE(filename)) -1 ), '.', 1)
)
, base_eod as (
SELECT split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) -1 ), '.', 1) as fn, sum(x.loaded_row) as  loaded_row, array_agg(load_batch_id) as batchs
FROM public.load_hft_log x
WHERE date_id = :p_date_id
group by split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) -1 ), '.', 1)
)
select base_eod.fn, base_inc.fn, base_inc.loaded_row as sum_inc, base_inc.batchs, base_eod.loaded_row as sum_eod, base_eod.loaded_row - base_inc.loaded_row as diff, base_eod.batchs
from base_inc
left join base_eod using(fn)
where base_inc.loaded_row != base_eod.loaded_row;

create index on partitions.hft_fix_message_event_20251106_eod (load_batch_id);

with base as (
select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id--, load_batch_id
--from partitions.hft_fix_message_event_reload
from partitions.hft_fix_message_event_20251106_eod
where load_batch_id = any ('{668157}')
except
select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20251106
where load_batch_id = any ('{667460,667495,667512,667525,667573,667556,667477,667583,667595,667610,667629,667643,667538,667655,667686,667703,667714,667728,667747,667763,667775,667808,667823,667669,667836,667853,667871,667885,667901,667918,667934,667947,667963,667981,667790,667995,668011,668027,668044,668057,668073,668092,668105,668120,668139}')
)
--insert into trash.so_20250717_full_diff
select *, '{668157}'::int4[] as load_batch_id_eod
into table trash.so_20251106_diff
from base;



create table trash.diff_20251106 as
select eod.*
from partitions.hft_fix_message_event_20251106_eod eod
         join trash.so_20251106_diff df on (true
    and eod.load_batch_id = any (df.load_batch_id_eod)
    and eod.cl_ord_id = df.cl_ord_id
    and coalesce(eod.parent_cl_ord_id, 'parent') = coalesce(df.parent_cl_ord_id, 'parent')
    and coalesce(eod.orig_cl_ord_id, 'orig') = coalesce(df.orig_cl_ord_id, 'orig')
    and eod.msg_type = df.msg_type
    and coalesce(eod.leg_ref_id, 'leg') = coalesce(df.leg_ref_id, 'leg')
    and eod.fix_date = df.fix_date
    and load_batch_id = any ('{668157}')
    )
    and case
                  when (to_timestamp(df.fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                        'US/Eastern')::time > '16:40'::time then
                      df.msg_type not in ('9', 'F')
                  else true end;

select account_name, count(*) from trash.diff_20251027
group by account_name;

select (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::time at time zone 'UTC' at time zone
                        'US/Eastern')::time, * from trash.diff_20251027
where true
--     and cl_ord_id = 'HFAHNS8649'
order by fix_date
select 29748-5008


