select *
from monitoring.error_tracking

where true
  and regexp_replace(error_text, '\\', '') ilike '%insert or update on table "f_yield_capture_20250624%'
  and db_host = 'pgtest1.uat.dashops.net'
and db_create_time::date = '2025-06-24'
order by error_tracking_id desc