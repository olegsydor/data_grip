select *
into table trash.so_worm_orders
from eod_reports.export_rbc_orders_tbl(in_start_date_id=>20181001, in_end_date_id=>20181231)
;
select array_agg(v)
from (select *--distinct "Liq Ind Description" as v
      from trash.so_worm_orders
--       where "Ask Px" is null
      limit 50) x

