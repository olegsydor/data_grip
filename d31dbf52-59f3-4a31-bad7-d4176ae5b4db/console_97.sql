select *
into trash.so_worm_trades
from eod_reports.export_rbc_trades_tbl(in_start_date_id=>20181001, in_end_date_id=>20181231)
;
select array_agg(v)
from (select distinct "Sending Firm" as v
      from trash.so_worm_trades
--       where "Ask Px" is null
      limit 5) x