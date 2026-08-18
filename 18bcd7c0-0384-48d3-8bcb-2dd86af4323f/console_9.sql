drop table if exists t_os;

create temp table t_os as
with tm as (
    select * from generate_series(11, 17, 1) as x(hr)
)
select dl.date_id, tm.hr, to_char(sum(dl.loaded_rows), 'FM9,999,999,990')
from loader.files fl
   join loader.daily_load dl using (date_id, file_id)
   join tm on true
where dl.date_id >= 20260725
  and true
and end_processing < (fl.date_id::text::date + '1 hour'::interval * tm.hr)
group by dl.date_id, tm.hr;

select * from t_os
where hr = 14
order by 3 desc
