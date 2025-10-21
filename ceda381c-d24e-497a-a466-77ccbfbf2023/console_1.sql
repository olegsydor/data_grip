select *
from monitoring.error_tracking
where true
--     and regexp_replace(error_text, '\\', '') ilike '%bigdatatail2%'
--          and regexp_replace(error_text, '\\', '') ilike '%l1_snapshot%'
and db_host = 'pgbigdata1.dashops.net'
and db_create_time::date = '2025-10-21'
-- and db_process_time is null
order by error_tracking_id desc;


WITH src AS (
  SELECT '{"2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [121-1]ERROR:  could not connect to server \"bigdatatail2\"","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [122-1]DETAIL:  connection to server at \"pgbigdata2.dashops.net\" (172.20.65.161), port 5432 failed: Connection timed out","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [123-1]CONTEXT:  SQL statement \"WITH RECURSIVE Pre_PositionHierarchy AS materialized ","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [124-1]STATEMENT:  FETCH 10000 FROM c2","2025-10-21 07:25:22.701 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [125-1]LOG:  duration: 0.061 ms","2025-10-21 07:25:22.713 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [126-1]LOG:  duration: 0.168 ms","2025-10-21 07:25:22.715 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [127-1]LOG:  durat'::text AS line
)
SELECT ARRAY[
  -- перший timestamp
  regexp_replace(line, '^.*?"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+ [A-Z]+).*$','\1'),

  -- очищений текст
  regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              regexp_replace(line,
                '"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+ [A-Z]+ ', '', 'g'  -- прибираємо всі timestamp’и
              ),
              '\(\d+\)|\[\d+(?:-\d+)?\]', '', 'g'                             -- прибираємо (123), [123-1]
            ),
            'duration: [0-9\.]+ ms', 'duration: ms', 'g'                      -- duration
          ),
          'session time: [0-9:]+', 'session time:', 'g'                       -- session time
        ),
        '\s+', ' ', 'g'                                                      -- зайві пробіли
      ),
      '^"|"$', '', 'g'                                                       -- лапки на краях
    ),
    '","', ', ', 'g'                                                         -- з’єднання елементів у рядок
  )
] AS result
FROM src;