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


WITH src AS (
  SELECT '{"2025-10-21 07:23:56.673 EDT big_data dwh postgres_fdw 000.00.00.00(40176) [2848248]: [41-1]ERROR:  could not connect to server \"bigdatatail2\"",
           "2025-10-21 07:23:56.673 EDT big_data dwh postgres_fdw 000.00.00.00(40176) [2848248]: [42-1]DETAIL:  connection to server at \"pgbigdata2.dashops.net\" (111.11.11.111), port 5432 failed: Connection timed out",
           "2025-10-21 07:23:56.673 EDT big_data dwh postgres_fdw 000.00.00.00(40176) [2848248]: [43-1]STATEMENT:  EXPLAIN SELECT fix_message FROM fix_capture.fix_message_json WHERE ((fix_message_id = ((SELECT null::bigint)::bigint))) AND ((date_id = ((SELECT null::integer)::integer)))",
           "2025-10-21 07:23:56.676 EDT big_data dwh postgres_fdw 000.00.00.00(40176) [2848248]: [44-1]LOG:  duration: 0.059 ms",
           "2025-10-21 07:23:56.738 EDT big_data dwh postgres_fdw 000.00.00.00(40176) [2848248]: [45-1]LOG:  duration: 0.016 ms",
           "2025-10-21 07:23:56.739 EDT big_data dwh postgres_fdw 000.00.00.00(40176) [2848248]: [46-1]LOG:  disconnection: session time: 0:02"}'::text AS line
),
cleaned AS (
  SELECT
    regexp_replace(line, '^.*?"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+ [A-Z]+).*$', '\1') AS time_val,
    regexp_split_to_array(
      regexp_replace(line, '(^"|"$)', '', 'g'),
      '","'
    ) AS arr
  FROM src
),
expanded AS (
  SELECT
    c.time_val,
    elem AS raw_line
  FROM cleaned c,
  LATERAL unnest(c.arr) AS elem
),
parsed AS (
  SELECT
    time_val,
    -- визначаємо тип повідомлення
    CASE
      WHEN raw_line ~ 'ERROR:' THEN 'ERROR'
      WHEN raw_line ~ 'DETAIL:' THEN 'DETAIL'
      WHEN raw_line ~ 'STATEMENT:' THEN 'STATEMENT'
      WHEN raw_line ~ 'LOG:' THEN 'LOG'
    END AS msg_type,
    -- очищаємо текст повідомлення
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(raw_line,
            '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+ [A-Z]+ ', '', 'g'
          ),
          '\(\d+\)|\[\d+(?:-\d+)?\]', '', 'g'
        ),
        '^[^:]+:\s*', '', 'g'
      ),
      '\s+', ' ', 'g'
    ) AS msg_clean
  FROM expanded
)
SELECT jsonb_build_object(
  'TIME', (SELECT DISTINCT time_val FROM parsed),
  'ERROR', (SELECT msg_clean FROM parsed WHERE msg_type = 'ERROR' LIMIT 1),
  'DETAIL', (SELECT msg_clean FROM parsed WHERE msg_type = 'DETAIL' LIMIT 1),
  'STATEMENT', (SELECT msg_clean FROM parsed WHERE msg_type = 'STATEMENT' LIMIT 1),
  'LOG', (SELECT jsonb_agg(msg_clean) FROM parsed WHERE msg_type = 'LOG')
) AS parsed_json
FROM parsed
LIMIT 1;


select '{"2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [121-1]ERROR:  could not connect to server \"bigdatatail2\"","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [122-1]DETAIL:  connection to server at \"pgbigdata2.dashops.net\" (172.20.65.161), port 5432 failed: Connection timed out","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [123-1]CONTEXT:  SQL statement \"WITH RECURSIVE Pre_PositionHierarchy AS materialized ","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [124-1]STATEMENT:  FETCH 10000 FROM c2","2025-10-21 07:25:22.701 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [125-1]LOG:  duration: 0.061 ms","2025-10-21 07:25:22.713 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [126-1]LOG:  duration: 0.168 ms","2025-10-21 07:25:22.715 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [127-1]LOG:  durat'::text


select :in_text


SELECT regexp_replace(:in_text, '.*ERROR: (.*?)(ERROR|DETAIL|STATEMENT|LOG).*', '\1') as error,
       regexp_replace(:in_text, '.*DETAIL: (.*?)(ERROR|DETAIL|STATEMENT|LOG).*', '\1') as detail,
       regexp_replace(:in_text, '.*STATEMENT: (.*?)(ERROR|DETAIL|STATEMENT|LOG).*', '\1') as statement,
       regexp_replace(:in_text, '.*LOG: (.*?)(ERROR|DETAIL|STATEMENT|LOG).*', '\1') as log;

select regexp_replace(:in_mod_text, '"|\\|\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d+ EDT|\[\d+\]|\(\d+\)|\[\d+-\d+\]|:', '', 'g');
select regexp_replace(:in_mod_text, '"|\\|\d+-\d+-\d+ \d+:\d+:\d+.\d+ EDT|\[\d+\]|\(\d+\)|\[\d+-\d+\]|:', '', 'g');

create or replace function monitoring.clean_text(in_text text)
    returns text
    language plpgsql
as
$fx$
declare
    f_text      text;
    f_error     text;
    f_detail    text;
    f_statement text;
begin
    SELECT regexp_replace(in_text, '.*ERROR: (.*?)(ERROR|DETAIL|STATEMENT|LOG).*', '\1')     as error,
           regexp_replace(in_text, '.*DETAIL: (.*?)(ERROR|DETAIL|STATEMENT|LOG).*', '\1')    as detail,
           regexp_replace(in_text, '.*STATEMENT: (.*?)(ERROR|DETAIL|STATEMENT|LOG).*', '\1') as statement
    into f_error, f_detail, f_statement;

    select 'ERROR: ' ||
           regexp_replace(f_error, '"|\\|\d+-\d+-\d+ \d+:\d+:\d+.\d+ EDT|\[\d+\]|\(\d+\)|\[\d+-\d+\]|:', '', 'g') ||
           '. DETAIL:' ||
           regexp_replace(f_detail, '"|\\|\d+-\d+-\d+ \d+:\d+:\d+.\d+ EDT|\[\d+\]|\(\d+\)|\[\d+-\d+\]|:', '', 'g') ||
           '. STATEMENT:' ||
           regexp_replace(f_statement, '"|\\|\d+-\d+-\d+ \d+:\d+:\d+.\d+ EDT|\[\d+\]|\(\d+\)|\[\d+-\d+\]|:', '', 'g')
    into f_text;
    return regexp_replace(regexp_replace(regexp_replace(f_text, '\s+', ' ', 'g'), '\s*\,\s+', ', ', 'g'), '\s*\.\s+', '. ', 'g');

end;
$fx$;

select monitoring.clean_text('{"2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [121-1]ERROR:  could , not connect to server \"bigdatatail2\"","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [122-1]DETAIL:  connection to server at \"pgbigdata2.dashops.net\" (172.20.65.161), port 5432 failed: Connection timed out","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [123-1]CONTEXT:  SQL statement \"WITH RECURSIVE Pre_PositionHierarchy AS materialized ","2025-10-21 07:25:22.690 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [124-1]STATEMENT:  FETCH 10000 FROM c2","2025-10-21 07:25:22.701 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [125-1]LOG:  duration: 0.061 ms","2025-10-21 07:25:22.713 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [126-1]LOG:  duration: 0.168 ms","2025-10-21 07:25:22.715 EDT big_data dwh postgres_fdw 000.00.00.00(50254) [2849509]: [127-1]LOG:  durat'::text)