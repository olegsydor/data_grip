select 358127158-358122790;

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

create index on partitions.hft_fix_message_event_20251111_eod (load_batch_id);

with base as (
select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id--, load_batch_id
--from partitions.hft_fix_message_event_reload
from partitions.hft_fix_message_event_20251111_eod
where load_batch_id = any ('{670526}')
except
select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20251111
where load_batch_id = any ('{670492,670177,669844,670195,670209,670227,669861,669879,670244,669778,669893,669907,670259,669925,670127,670277,669796,669941,669814,670145,669830,670295,669957,670159,670311,670328,669992,670006,670346,670025,670360,670377,670393,670043,670058,670409,670076,670426,669974,670093,670443,670460,670108,670474}')
)
insert into trash.so_20251111_diff
select *, '{670526}'::int4[] as load_batch_id_eod
-- into table trash.so_20251111_diff
from base;

select *
--     min(to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS.MS')), max(to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS.MS'))
    from trash.so_20251111_diff
where true
	        and case
                 when (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                       'US/Eastern')::time > '16:40'::time then
                     msg_type not in ('9', 'F')
                 else true end

create table trash.diff_20251111 as
select
--     (to_timestamp(df.fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone 'US/Eastern')::time,
    eod.*
from trash.so_20251111_diff df
         join partitions.hft_fix_message_event_20251111_eod eod on (true
    and eod.load_batch_id = any (df.load_batch_id_eod)
    and eod.cl_ord_id = df.cl_ord_id
    and coalesce(eod.parent_cl_ord_id, 'parent') = coalesce(df.parent_cl_ord_id, 'parent')
    and coalesce(eod.orig_cl_ord_id, 'orig') = coalesce(df.orig_cl_ord_id, 'orig')
    and eod.msg_type = df.msg_type
    and coalesce(eod.leg_ref_id, 'leg') = coalesce(df.leg_ref_id, 'leg')
    and eod.fix_date = df.fix_date
--     and load_batch_id = any ('{668941,668943,668946,668940,668949,668939,668970,668963,668959,668965}')
    )
    and (to_timestamp(df.fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone 'US/Eastern')::time <= '16:40'::time;
--     and case
--                   when (to_timestamp(df.fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
--                         'US/Eastern')::time > '16:40'::time then false
-- --                       df.msg_type not in ('9', 'F')
--                   else true end;

select
--     account_name, count(*)
*
from trash.diff_20251111
group by account_name;

select (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                        'US/Eastern')::time, * from trash.diff_20251111
where true
--     and cl_ord_id = 'HFAHNS8649'
order by fix_date
select 29748-5008



select * from
staging.sync_test_calculated_metrics
where date_id = :p_date_id