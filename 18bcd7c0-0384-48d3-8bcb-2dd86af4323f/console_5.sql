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
select base_eod.fn, base_inc.fn, base_inc.loaded_row as sum_inc, base_inc.batchs, base_eod.loaded_row as sum_eod, base_eod.batchs
from base_inc
left join base_eod using(fn)
where base_inc.loaded_row <> base_eod.loaded_row;