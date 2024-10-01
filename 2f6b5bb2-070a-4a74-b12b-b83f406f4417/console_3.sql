create table training.cantor (n int);

insert into training.cantor (n)
select x from generate_series(1, 1000000, 1) n(x)

select n, format(case m % 2 when 0 then '%1$s/%2$s' else '%2$s/%1$s' end, m - i, 1 + i) res
from
	training.cantor a,
	cast(sqrt(2 * n) as int) m,
	lateral(values ((m * (m + 1)) / 2 - n)) b(i);


WITH sequence_number AS (
  SELECT
    n,
    CASE
      WHEN n = 1 THEN 1
      ELSE CAST(FLOOR(0.5*(1 + SQRT(1 + 8*(n-1)))) AS INT)
    END AS S_n
  FROM training.cantor
),
prepped_data AS (
  SELECT
    n,
    S_n,
    n - S_n AS diff,
    CAST(0.5*(S_n-1)*(S_n-2) AS INT) AS begin_diff,
    n - S_n - CAST(0.5*(S_n-1)*(S_n-2) AS INT) AS increment
  FROM
    sequence_number
)
SELECT
  n,
  CASE
    WHEN n=1 THEN '1/1'
    WHEN MOD(S_n,2) = 0 THEN FORMAT('%s/%s', (1+increment), (S_n-increment))
    WHEN MOD(S_n,2) != 0 THEN FORMAT('%s/%s', (S_n-increment),(1+increment))
    ELSE NULL
  END as res
FROM prepped_data

C:\Users\Oleh_Sydor\AppData\Roaming\JetBrains\DataGrip2024.1\consoles\db\2f6b5bb2-070a-4a74-b12b-b83f406f4417\console_3.sql