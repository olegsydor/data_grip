
with tm as (
    select * from generate_series(11, 17, 1) as x(hr)
)
, grp as (
select dl.date_id, tm.hr, sum(dl.loaded_rows) as sm
from loader.files fl
   join loader.daily_load dl using (date_id, file_id)
   join tm on true
where dl.date_id >= 20260803
  and true
and end_processing < (fl.date_id::text::date + '1 hour'::interval * tm.hr)
group by dl.date_id, tm.hr)
select date_id, hr, to_char(sm, 'FM9,999,999,990') from grp
where hr = 17
order by sm desc
