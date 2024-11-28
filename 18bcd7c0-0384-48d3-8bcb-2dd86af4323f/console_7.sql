select inc_hft.unfinished_hft_inc()       as files_in_prog,
       sum(end_position - start_position) as all_rows,
       sum(processed_rows)                as processed_rows,
       case
           when exists (select null from inc_hft.load_finish where date_id = to_char(current_date, 'YYYYMMDD')::int)
               then true
           else false end                 as finished
from inc_hft.hft_incremental_files
where date_id = to_char(current_date, 'YYYYMMDD')::int
