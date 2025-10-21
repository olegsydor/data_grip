select *
from monitoring.error_tracking
where true
--     and regexp_replace(error_text, '\\', '') ilike '%bigdatatail2%'
--          and regexp_replace(error_text, '\\', '') ilike '%l1_snapshot%'
and db_host = 'pgbigdata1.dashops.net'
and db_create_time::date = '2025-10-21'
-- and db_process_time is null
order by error_tracking_id desc