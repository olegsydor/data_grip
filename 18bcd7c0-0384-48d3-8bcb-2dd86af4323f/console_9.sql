with tm as (select extract('hour' from clock_timestamp()) as hr)
   , grp as (select dl.date_id,
                    tm.hr               as hr,
                    sum(dl.loaded_rows) as current_hour,
                    sum(case
                            when end_processing < (fl.date_id::text::date + '1 hour'::interval * tm.hr)
                                then dl.loaded_rows
                            else 0 end) as prev_hour

             from loader.files fl
                      join loader.daily_load dl using (date_id, file_id)
                      join tm on true
             where dl.date_id >= 20260803
               and true
               and end_processing < (fl.date_id::text::date + '1 hour'::interval * (tm.hr + 1))
             group by dl.date_id, tm.hr)
select case when date_id = to_char(current_date, 'YYYYMMDD')::int then true else false end,
       date_id,
       hr,
       to_char(current_hour, 'FM9,999,999,990') as current_hour,
       to_char(prev_hour, 'FM9,999,999,990')    as prev_hour
from grp
where true
order by current_hour desc;
