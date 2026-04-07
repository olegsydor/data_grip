select (638333907-638355181)/638333907.0*100; --EOD left vs INC right
-- -21274

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
select base_inc.fn, base_inc.loaded_row as sum_inc, base_inc.batchs, base_eod.loaded_row as sum_eod, base_eod.loaded_row - base_inc.loaded_row as diff, base_eod.batchs
from base_eod
left join base_inc using(fn)
where base_inc.loaded_row != base_eod.loaded_row;

select count(*) from partitions.hft_fix_message_event_20260217_eod
where load_batch_id = any ('{724518,724517,724515,724516,724505,724522,724509}')
union
select count(*)
from partitions.hft_fix_message_event_20260217
where load_batch_id = any ('{723821,723880,723950,724024,724089,724152,724215,724278,724339,724400,724457}')


SELECT split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) -1 ), '.', 1) as fn, sum(x.loaded_row) as  loaded_row, array_agg(load_batch_id) as batchs
FROM public.load_hft_log x
WHERE date_id = :p_date_id
and load_batch_id = 760128
group by split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) -1 ), '.', 1)

create index on partitions.hft_fix_message_event_20260406_eod (load_batch_id);

with base as (select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id--, load_batch_id
              from partitions.hft_fix_message_event_20260406_eod
              where true
                and load_batch_id = any ('{760153,760152,760134}')
                and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                     'US/Eastern')::time <= '16:30'::time
              except
              select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
              from partitions.hft_fix_message_event_20260406
              where true
                and load_batch_id = any ('{760128, 759429,759450,759463,759483,759507,759531,759555,759579,759603,759627,759651,759676,759700,759723,759748,759771,759795,759820,759843,759867,759891,759915,759939,759964,759987,760011,760035,760060,760083}')
                and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                     'US/Eastern')::time <= '16:30'::time
/*              except
              select orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id--, load_batch_id

              from partitions.hft_fix_message_event_20260217_eod
              where load_batch_id = any ('{724527}')
                and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                     'US/Eastern')::time <= '16:30'::time
 */
)
-- insert into trash.so_20260406_diff
select *, '{0}'::int4[] as load_batch_id_eod
into trash.so_20260406_diff
from base;


select * from trash.so_20260406_diff1

select *
--     min(to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS.MS')), max(to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS.MS'))
    from trash.so_20260406_diff1
where true
	        and case
                 when (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                       'US/Eastern')::time > '16:30'::time then
                     msg_type not in ('9', 'F')
                 else true end

create table trash.diff_20260406 as
select
    eod.*
from trash.so_20260406_diff1 df
         join partitions.hft_fix_message_event_20260406_eod eod on (true
    and eod.load_batch_id = any ('{760132,760136,760154}')
    and eod.cl_ord_id = df.cl_ord_id
    and coalesce(eod.parent_cl_ord_id, 'parent') = coalesce(df.parent_cl_ord_id, 'parent')
    and coalesce(eod.orig_cl_ord_id, 'orig') = coalesce(df.orig_cl_ord_id, 'orig')
    and eod.msg_type = df.msg_type
    and coalesce(eod.leg_ref_id, 'leg') = coalesce(df.leg_ref_id, 'leg')
    and eod.fix_date = df.fix_date
--     and load_batch_id = any ('{668941,668943,668946,668940,668949,668939,668970,668963,668959,668965}')
    )
    and (to_timestamp(df.fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone 'US/Eastern')::time <= '16:30'::time;
--     and case
--                   when (to_timestamp(df.fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
--                         'US/Eastern')::time > '16:40'::time then false
-- --                       df.msg_type not in ('9', 'F')
--                   else true end;



select (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                        'US/Eastern')::time, * from trash.so_disc_20260105
where true
--     and cl_ord_id = 'HFAHNS8649'
order by fix_date
select 29748-5008



select * from
staging.sync_test_calculated_metrics
where date_id = :p_date_id;


-- check 20251118
select orig_cl_ord_id,
       msg_type,
       cl_ord_id,
       parent_cl_ord_id,
       fix_date,
       eod.leg_ref_id,
       inc.leg_ref_id--, load_batch_id
from partitions.hft_fix_message_event_20251118_eod eod
         join lateral ( select inc.leg_ref_id
                        from partitions.hft_fix_message_event_20251117 inc
                        where inc.orig_cl_ord_id = eod.orig_cl_ord_id
                          and eod.msg_type = inc.msg_type
                          and eod.cl_ord_id = inc.cl_ord_id
                          and eod.parent_cl_ord_id = inc.parent_cl_ord_id
                          and eod.fix_date = inc.fix_date
--                           and eod.leg_ref_id = inc.leg_ref_id
                        limit 1) inc on true
limit 500;


select * from hft.hft_fix_message_event
where date_id = 20251117
and cl_ord_id = 'EBAA0078-20251117'

select * from partitions.hft_fix_message_event_new_--partitions.hft_fix_message_event_reload_node2
where date_id = 20251117
and cl_ord_id = 'EBAA0078-20251117'
----
create table trash.so_disc_20260105 as
select *--orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20260105 inc
where load_batch_id = any ('{700717,700780,700663,700848,700912,700975,701034,701091,701154,701216,701279}')
  and not exists (select null
                  from partitions.hft_fix_message_event_20260105_eod eod
                  where load_batch_id = any ('{701369}')
                    and eod.orig_cl_ord_id is not distinct from inc.orig_cl_ord_id
                    and eod.msg_type = inc.msg_type
                    and eod.date_id = inc.date_id
                    and eod.cl_ord_id = inc.cl_ord_id
                    and eod.parent_cl_ord_id is not distinct from inc.parent_cl_ord_id
                    and eod.fix_date = inc.fix_date
                    and eod.leg_ref_id is not distinct from inc.leg_ref_id
);
select * from trash.so_disc_20260105;

create table trash.so_disc_20260105 as
select eod.*--orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20260105_eod eod
where load_batch_id = any ('{701369}')
  and not exists (select null
                  from partitions.hft_fix_message_event_20260105 inc
                  where load_batch_id = any ('{700717,700780,700663,700848,700912,700975,701034,701091,701154,701216,701279}')
                    and eod.orig_cl_ord_id is not distinct from inc.orig_cl_ord_id
                    and eod.msg_type = inc.msg_type
                    and eod.date_id = inc.date_id
                    and eod.cl_ord_id = inc.cl_ord_id
                    and eod.parent_cl_ord_id is not distinct from inc.parent_cl_ord_id
                    and eod.fix_date = inc.fix_date
                    and eod.leg_ref_id is not distinct from inc.leg_ref_id
);



select inc.cl_ord_id,
        eod.cl_ord_id,
       inc.*--orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20260105 inc
         left join partitions.hft_fix_message_event_20260105_eod eod
                   on true and eod.orig_cl_ord_id is not distinct from inc.orig_cl_ord_id
                       and eod.msg_type = inc.msg_type
                       and eod.date_id = inc.date_id
                       and eod.cl_ord_id = inc.cl_ord_id
                       and eod.parent_cl_ord_id is not distinct from inc.parent_cl_ord_id
                       and eod.fix_date = inc.fix_date
                       and eod.leg_ref_id is not distinct from inc.leg_ref_id
                       and eod.sec_exch_exec_id is not distinct from  inc.sec_exch_exec_id
where inc.load_batch_id = any ('{700717,700780,700663,700848,700912,700975,701034,701091,701154,701216,701279}')
   and eod.load_batch_id = any ('{701369}')
and inc.cl_ord_id = '390043863081847';


select 'inc',
       *
--        orig_cl_ord_id,
--        msg_type,
--        date_id,
--        cl_ord_id,
--        parent_cl_ord_id,
--        fix_date,
--        leg_ref_id,
--        sec_exch_exec_id
from partitions.hft_fix_message_event_20260105 inc
where inc.load_batch_id = any ('{700717,700780,700663,700848,700912,700975,701034,701091,701154,701216,701279}')
  and inc.cl_ord_id = '390043863081847'
union all
select 'eod',
       *
--        orig_cl_ord_id,
--        msg_type,
--        date_id,
--        cl_ord_id,
--        parent_cl_ord_id,
--        fix_date,
--        leg_ref_id,
--        sec_exch_exec_id
from partitions.hft_fix_message_event_20260105_eod eod
where eod.cl_ord_id = '390043863081847'
  and eod.load_batch_id = any ('{701369}')

select inc.*--orig_cl_ord_id, msg_type, date_id, cl_ord_id, parent_cl_ord_id, fix_date, leg_ref_id
from partitions.hft_fix_message_event_20260105 inc
where load_batch_id = any ('{700717,700780,700663,700848,700912,700975,701034,701091,701154,701216,701279}')
  and exists (select null
                  from partitions.hft_fix_message_event_20260105_eod eod
                  where load_batch_id = any ('{701369}')
                    and eod.orig_cl_ord_id is not distinct from inc.orig_cl_ord_id
                    and eod.msg_type = inc.msg_type
                    and eod.date_id = inc.date_id
                    and eod.cl_ord_id = inc.cl_ord_id
                    and eod.parent_cl_ord_id is not distinct from inc.parent_cl_ord_id
                    and eod.fix_date = inc.fix_date
                    and eod.leg_ref_id = inc.leg_ref_id
)
and inc.cl_ord_id = '390043863081847';

    call trash.check_discrepancy(20260105);

create or replace procedure trash.check_discrepancy(in_date_id int4)
    language plpgsql
as
$$
declare
    rc record;
begin
    for rc in (with base_inc
        as (select split_part(RIGHT(filename, POSITION('/' in REVERSE(filename)) - 1), '.', 1) as fn,
                   sum(processed_rows)                                                         as loaded_row,
                   array_agg(load_batch_id)                                                    as batchs
            from inc_hft.hft_incremental_files
            where date_id = in_date_id
              and is_active = 'Y'
            group by split_part(RIGHT(filename, POSITION('/' in REVERSE(filename)) - 1), '.', 1))
                  , base_eod
            as (SELECT split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) - 1), '.', 1) as fn,
                       sum(x.loaded_row)                                                               as loaded_row,
                       array_agg(load_batch_id)                                                        as batchs
                FROM public.load_hft_log x
                WHERE date_id = in_date_id
                group by split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) - 1), '.', 1))
               select base_inc.fn,
                      base_inc.loaded_row                       as sum_inc,
                      base_inc.batchs                           as batch_inc,
                      base_eod.loaded_row                       as sum_eod,
                      base_eod.loaded_row - base_inc.loaded_row as diff,
                      base_eod.batchs                           as batch_eod
               from base_eod
                        left join base_inc using (fn)
               where base_inc.loaded_row != base_eod.loaded_row)
        loop
            begin
                insert into trash.so_diff_20250105
                select table_name, date_id, cn, count_cl_ord_id, count_parent_cl_ord, count_exec_type
                from (SELECT rc.fn || 'inc'             AS table_name,
                             in_date_id::NUMERIC        AS date_id,
                             count(ne.cl_ord_id)        AS cn,
                             null::int8                       AS count_cl_ord_id,
                             count(ne.parent_cl_ord_id) AS count_parent_cl_ord,
                             count(ne.exec_type)        AS count_exec_type
                      FROM partitions.hft_fix_message_event_20260105 AS ne
                      where msg_type not in ('1', '5')
                        and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                             'US/Eastern')::time <= '16:30'::time
                        and load_batch_id = any (rc.batch_inc)
                      union all
                      SELECT rc.fn || 'eod'             AS table_name,
                             in_date_id::NUMERIC        AS date_id,
                             count(ne.cl_ord_id)        AS cn,
                             null                       AS count_cl_ord_id,
                             count(ne.parent_cl_ord_id) AS count_parent_cl_ord,
                             count(ne.exec_type)        AS count_exec_type
                      FROM partitions.hft_fix_message_event_20260105_eod AS ne
                      where msg_type not in ('1', '5')
                        and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                             'US/Eastern')::time <= '16:30'::time
                        and load_batch_id = any (rc.batch_eod)) x;
                raise notice '%: printed - %', to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS'), rc.fn;
            end;
        end loop;
end;
$$;

select * from trash.so_diff_20250105;

create table trash.so_diff_20250105 as
SELECT
		'CAT_HFT'::TEXT						AS table_name,
		:p_date_id::NUMERIC					AS date_id,
--		count(ne.date_id) 					AS cn,
		count(ne.cl_ord_id) 				AS cn,
		count(ne.cl_ord_id) 				AS count_cl_ord_id,
		count(ne.parent_cl_ord_id) 			AS count_parent_cl_ord,
		count(ne.exec_type) 				AS count_exec_type
	FROM partitions.hft_fix_message_event_20260105 AS ne
	where msg_type not in('1', '5')
	        and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                        'US/Eastern')::time <= '16:30'::time
and load_batch_id = any ('{700712}')
union all
SELECT
		'CAT_HFT'::TEXT						AS table_name,
		:p_date_id::NUMERIC					AS date_id,
--		count(ne.date_id) 					AS cn,
		count(ne.cl_ord_id) 				AS cn,
		count(ne.cl_ord_id) 				AS count_cl_ord_id,
		count(ne.parent_cl_ord_id) 			AS count_parent_cl_ord,
		count(ne.exec_type) 				AS count_exec_type
	FROM partitions.hft_fix_message_event_20260105_eod AS ne
	where msg_type not in('1', '5')
	        and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                        'US/Eastern')::time <= '16:30'::time
and load_batch_id = any ('{701367}')


select (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                        'US/Eastern')::time, * from partitions.hft_fix_message_event_20260105
where load_batch_id = 701304
and msg_type not in('1', '5')
	        and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
                        'US/Eastern')::time <= '16:30'::time;


select *
           from inc_hft.hft_incremental_files
where date_id = 20260105
and load_batch_id = 701304;


SELECT cl_ord_id, load_batch_id, *
FROM partitions.hft_fix_message_event_20260105 AS ne
where msg_type not in ('1', '5')
  and (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::timestamp at time zone 'UTC' at time zone
       'US/Eastern')::time <= '16:30'::time
  and load_batch_id = any ('{701303, 701304}')
order by cl_ord_id, load_batch_id

;
alter table inc_hft.hft_incremental_files
    add column if not exists is_str_modif_processed bool not null default false;
comment on column inc_hft.hft_incremental_files.is_str_modif_processed is 'Switched into true as soon as the process of filling the very orig message 35=D';



with frst as (SELECT date_id,
                     left(split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) - 1), '.', 1), 10) as eos,
--                      split_part(RIGHT(x.filename, POSITION('/' in REVERSE(x.filename)) - 1), '.', 1)           as file,
                     sum(loaded_row)                                                                           as first_rows
              FROM public.load_hft_log AS x
              WHERE date_id between 20251201 and 20260131
                and x.start_time::date between 20251201::text::date and 20251231::text::date
              group by 1, 2)
   , sec as (select date_id,
                    left(split_part(RIGHT(filename, POSITION('/' in REVERSE(filename)) - 1), '.', 1), 10) as eos,
--                     split_part(RIGHT(filename, POSITION('/' in REVERSE(filename)) - 1), '.', 1)           as file,
                    sum(loaded_row)                                                                       as reloaded_rows
             from public.load_hft_log
             where date_id between 20251201 and 20251231
               and start_time::date >= '2026-04-01'
               and comment is null
             group by 1, 2)
select date_id, eos, first_rows, reloaded_rows
from frst
         left join sec using (eos, date_id)
where eos = 'EOS1INTDC1'
order by 1, 2