select *
from monitoring.error_tracking
where true
--    and regexp_replace(error_text, '\\', '') ilike '%insert or update on table "f_yield_capture_20250624%'
       and regexp_replace(error_text, '\\', '') ilike '%her=TLS_AES_256_GCM_SHA384) id 15.20.8964.20 via Frontend Transport%'
--   and db_host = 'pgtest1.uat.dashops.net'
and db_create_time::date = '2025-07-24'
-- and db_process_time is null
order by error_tracking_id desc