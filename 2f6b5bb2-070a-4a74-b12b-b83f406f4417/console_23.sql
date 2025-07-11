WITH Numbers(N) AS (SELECT N
                    FROM (VALUES (1), (2), (3), (4)) Numbers(N)
                    )
     , Recur (N, Combination) AS (SELECT N, CAST(N AS VARCHAR(1000))
                               FROM Numbers
                               UNION ALL
                               SELECT n.N, CAST(r.Combination + ',' + CAST(n.N AS VARCHAR(10)) AS VARCHAR(1000))
                               FROM Recur r
                                        INNER JOIN Numbers n ON n.N > r.N
                               )
SELECT Combination
FROM Recur
ORDER BY LEN(Combination), Combination;


select * from training.comb
where list_id between 1 and 30;


with base as (
select list_id,
       array_agg(list_id) over (order by list_sum desc) as l,
       list_sum, sum(list_sum) over (order by list_sum desc) as sm
from training.comb
where list_id between 1 and 15
    )
select array_agg(list_id) as list_id,
       sm
from base where







create table training.comb (
    list_id int4,
    list_sum int4
);
insert into training.comb(list_id, list_sum) values (0, 1), (22, 1), (23, 1), (24, 1), (25, 1);
insert into training.comb(list_id, list_sum) values (26, 1), (27, 1), (28, 1), (29, 1), (30, 1);


with recursive subset_sum as (select array [list_id] as ids,
                                      list_id         as max_id,
                                      list_sum,
                                      1               as depth
                               from training.comb
                               where true
                                 and list_sum <= :sum


                                  union all

                              select
                                  ss.ids || c.list_id, c.list_id, ss.list_sum + c.list_sum, ss.depth + 1
                              from subset_sum ss
                                  join training.comb c
                              on c.list_id > ss.max_id
                              where ss.list_sum + c.list_sum <= :sum
--                               and depth <= 5
                              )
select *
from subset_sum
where list_sum = :sum
-- order by depth, ids
limit 1;

truncate training.comb;

INSERT INTO training.comb
SELECT id+61, power(2, id)
FROM    generate_series(0, 30) AS id;


with months (month_numb, month_name, ret_val) as (select *
                                                  from (values ('1', 'січень', 1),
                                                               ('2', 'лютий', 2),
                                                               ('3', 'березень', 3),
                                                               ('4', 'квітень', 4),
                                                               ('5', 'травень', 5),
                                                               ('6', 'червень', 6),
                                                               ('7', 'липень', 7),
                                                               ('8', 'серпень', 8),
                                                               ('9', 'вересень', 9),
                                                               ('10', 'жовтень', 10),
                                                               ('11', 'листопад', 11),
                                                               ('12', 'грудень', 12)))
    select array_agg(ret_val) from months
where month_name = any('{січень,лютий}');


select mnt
from regexp_split_to_array('01,02,03',',') as mnt


-- <h1.+>(.*?)</h1>

SELECT REGEXP_MATCHES('and ci = 1 and f = 0 and oc = 2  and rc = 3', '(and [^(and)]+)', 'g');

SELECT REGEXP_MATCHES('Фінансування на виплату за 01,02,03 січня 2025 року. Без ПДВ.', 'за ([\d]{2}(?:,[\d]{2})*) \w+ \d{4} року');


WITH input(text) AS (
    VALUES
    ('Виплата за січень, лютий і березень 2025 року')
)

-- Витягуємо блок місяців і ділимо його на частини
SELECT trim(both ' ' from value) AS month_name
FROM input,
     LATERAL regexp_match(text, 'за ((?:січень|лютий|березень|квітень|травень|червень|липень|серпень|вересень|жовтень|листопад|грудень)(?:, | і )?(?:січень|лютий|березень|квітень|травень|червень|липень|серпень|вересень|жовтень|листопад|грудень)*) \d{4} року') AS m(months_block),
     LATERAL regexp_split_to_table(m.months_block::text, ', | і ') AS value;



-- clearing account
alter table genesis2.clearing_account add column if not exists is_autoalloc_to bpchar null;

select *--clearing_account_id, account_id, cmta, is_default, is_autoalloc_to, default_alloc_ratio
from genesis2.clearing_account
where true
  and account_id = 4858;

drop table t_clearing_account_aa;
  create temp table t_clearing_account_aa as
  with base as (
      select ca.account_id,
         coalesce(aa.clearing_account_id, ca.clearing_account_id) as clearing_account_id,
         coalesce(aa.cmta, ca.cmta)          as cmta,
         coalesce(aa.default_alloc_ratio, 1) as ratio
  from genesis2.clearing_account ca
           left join genesis2.clearing_account aa on ca.account_id = aa.account_id and aa.is_autoalloc_to = 'Y'
  where true
    and ca.is_deleted = 'N'
    and ca.market_type = 'O'
    and ca.is_default = 'Y')
  , check_sum_ratio as (select account_id, sum(ratio) as sum_ratio
                        from base
                        group by account_id
                        having sum(ratio) = 1)
  select * from base
  join check_sum_ratio using (account_id);

select * from genesis2.trade_for_allocations
select * from t_clearing_account_aa


select * from genesis2.trade_for_allocations ta
join lateral ( select coalesce(array_agg(ratio), '{1}'::numeric[]) as ratio from t_clearing_account_aa aa where aa.account_id = ta.account_id limit 1) aa on true



create table genesis2.trade_for_allocations
(
    account_id    int4,
    instrument_id int8,
    side          char,
    open_close    char,
    cmta          varchar(3),
    mpid          varchar,
    eq_grp        varchar,
    avg_px        numeric,
    total_qty     int8,
    trade_ids     int8[],
    last_qtys     int[]
)
;

INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (2525, 180656818, '2', 'C', '019', null, null, 1.5, 15, '{2347367681,2347367740,2347367743}', '{5,5,5}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (2525, 180656818, '2', 'C', null, null, null, 1.5, 10, '{2347367744,2347367755}', '{5,5}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (4858, 181837076, '1', 'O', '659', 'SGAS', null, 0.013333, 3, '{2347366213,2347366214,2347366219}', '{1,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (4858, 181867748, '1', 'O', '659', 'SGAS', null, 11.3, 1, '{2347365895}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (4858, 182031552, '1', 'O', '659', 'SGAS', null, 21.2, 5, '{2347365886}', '{5}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (4858, 182044613, '1', 'O', '659', 'SGAS', null, 27, 2, '{2347365884,2347365885}', '{1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (4858, 182044618, '1', 'O', '659', 'SGAS', null, 25.6, 1, '{2347365864}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (4858, 182044997, '1', 'O', '659', 'SGAS', null, 359.1, 3, '{2347366036}', '{3}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (4858, 182045004, '1', 'O', '659', 'SGAS', null, 174.6, 1, '{2347366197}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9490, 182044393, '1', 'C', null, 'JSEB', null, 320.95619, 21, '{2347367634,2347367655,2347367911,2347368173,2347368177,2347368179,2347368195,2347368198,2347368210,2347368212,2347368249,2347368257}', '{1,10,1,1,1,1,1,1,1,1,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9490, 182044393, '2', 'C', null, 'JSEB', null, 320.95619, 21, '{2347367635,2347367654,2347367909,2347368172,2347368176,2347368178,2347368194,2347368197,2347368209,2347368211,2347368248,2347368256}', '{1,10,1,1,1,1,1,1,1,1,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179338374, '1', 'C', '235', null, null, 2.2, 32, '{2347365909,2347365910,2347365911,2347366022,2347366023}', '{5,10,1,15,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179338374, '1', 'C', null, null, null, 5.675, 42, '{2347366150,2347366282}', '{21,21}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179338374, '2', 'C', null, null, null, 5.9, 21, '{2347366154}', '{21}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179338374, '2', 'O', '235', null, null, 10.85, 16, '{2347366275}', '{16}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179338374, '2', 'O', null, null, null, 5.45, 21, '{2347366288}', '{21}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179347015, '1', 'C', null, null, null, 28.55, 13, '{2347366148}', '{13}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179347015, '2', 'C', null, null, null, 28.55, 13, '{2347366146}', '{13}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179347613, '1', 'O', '161', null, null, 17.55, 8, '{2347366290}', '{8}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179347613, '2', 'O', '161', null, null, 17.55, 8, '{2347366291}', '{8}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179348161, '1', 'C', null, null, null, 0.01, 23, '{2347366157}', '{23}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179348161, '1', 'O', null, null, null, 0.01, 23, '{2347366287}', '{23}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179348161, '2', 'C', null, null, null, 0.01, 23, '{2347366153}', '{23}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179348161, '2', 'O', null, null, null, 0.01, 23, '{2347366285}', '{23}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179397346, '1', 'C', null, null, null, 27.21, 57, '{2347366147,2347366151,2347366156}', '{13,21,23}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179397346, '1', 'O', '161', null, null, 20.3, 10, '{2347366268,2347366273}', '{3,7}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179397346, '1', 'O', '235', null, null, 2.2, 32, '{2347365932,2347365933,2347366269,2347366270,2347366271}', '{15,1,9,6,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179397346, '1', 'O', null, null, null, 27.607273, 44, '{2347366283,2347366286}', '{21,23}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179397346, '2', 'C', '161', null, null, 20.3, 10, '{2347366272,2347366274}', '{3,7}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179397346, '2', 'C', '235', null, null, 20.65, 35, '{2347366024,2347366025}', '{19,16}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179397346, '2', 'C', null, null, null, 27.383069, 101, '{2347366149,2347366152,2347366155,2347366284,2347366289}', '{13,23,21,23,21}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179545330, '2', 'O', '123', null, null, 1.72, 56, '{2347366906,2347366911}', '{28,28}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179545330, '2', 'O', '161', null, null, 1.44, 90, '{2347366897}', '{90}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179545330, '2', 'O', '235', null, null, 1.701509, 444, '{2347366824,2347366825,2347366836,2347366861,2347366881,2347366882,2347366883,2347366884,2347366885,2347366886,2347366887,2347366901,2347366912,2347366913,2347366918}', '{1,89,90,19,22,4,10,22,4,8,1,90,28,28,28}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179545330, '2', 'O', '552', null, null, 1.44, 90, '{2347366849}', '{90}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179826277, '1', 'O', '019', null, null, 2, 35, '{2347367149}', '{35}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 179826277, '1', 'O', '235', null, null, 2, 214, '{2347367090,2347367114,2347367132,2347367161,2347367162}', '{48,48,48,35,35}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181218290, '2', 'O', '123', null, null, 2, 100, '{2347367411,2347367412,2347367413,2347367414}', '{3,5,6,86}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181218290, '2', 'O', '235', null, null, 1.17, 10, '{2347367415,2347367416}', '{9,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181837081, '1', 'O', '161', null, null, 1.7, 1, '{2347366917}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181837081, '2', 'O', '161', null, null, 1.75, 1, '{2347367075}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181837081, '2', 'O', null, null, null, 2, 1, '{2347366914}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181838815, '1', 'O', '235', null, null, 4.3, 11, '{2347366829,2347366830,2347366831,2347366905}', '{4,5,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181894664, '1', 'C', '161', null, null, 36.141129, 62, '{2347365918,2347366008,2347366010,2347366011}', '{1,1,10,50}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181894664, '1', 'C', '235', null, null, 2.2, 1, '{2347366128}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 181894664, '2', 'C', '161', null, null, 36.141129, 62, '{2347365908,2347366009,2347366012,2347366014}', '{1,1,10,50}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 182021749, '1', 'C', '235', null, null, 2.2, 30, '{2347365828,2347365829,2347365904,2347365905,2347365930,2347365931}', '{9,1,9,1,9,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 182021749, '2', 'C', '161', null, null, 5.37, 10, '{2347365966,2347365968,2347365969}', '{7,2,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 182024458, '1', 'O', '552', null, null, 3.25, 2, '{2347368189}', '{2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 182024458, '2', 'C', '552', null, null, 3.25, 2, '{2347368191}', '{2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 182024839, '1', 'O', '552', null, null, 3.25, 2, '{2347368190}', '{2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (9908, 182024839, '2', 'C', '552', null, null, 3.25, 2, '{2347368192}', '{2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (10068, 179913739, '1', 'O', null, null, null, 55.808257, 109, '{2347366777,2347366784,2347366785,2347366788,2347366790,2347366794,2347366795,2347366796,2347366808,2347366826,2347366834}', '{10,10,10,10,10,10,10,10,9,10,10}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (10068, 179913739, '2', 'O', null, null, null, 55.808257, 109, '{2347366776,2347366783,2347366786,2347366789,2347366791,2347366792,2347366793,2347366797,2347366807,2347366827,2347366833}', '{10,10,10,10,10,10,10,10,9,10,10}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (10208, 181861566, '2', 'O', null, null, null, 276.4, 2, '{2347367602}', '{2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (10248, 181861566, '1', 'O', null, null, null, 276.4, 2, '{2347367601}', '{2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (12931, 181968170, '2', 'O', '552', null, null, 5.6, 1, '{2347367707}', '{1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (12931, 182022650, '2', 'C', '019', null, null, 3.303846, 13, '{2347367391,2347367410}', '{1,12}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (12931, 182022650, '2', 'C', '642', null, null, 3.75, 17, '{2347367409}', '{17}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (166174, 180532183, '2', 'C', '571', 'OPCO', null, 12.603271, 107, '{2347367787,2347367788}', '{100,7}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (166174, 182030173, '1', 'O', '551', 'OPCO', null, 2.61, 1000, '{2347368250}', '{1000}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (166177, 182030173, '2', 'O', '551', 'OPCO', null, 2.61, 1000, '{2347368251}', '{1000}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255198, 181877970, '1', 'O', '123', null, null, 2, 3800, '{2347365819,2347365890,2347365915,2347365939,2347365991,2347366201,2347366364,2347366428,2347366766,2347366804,2347366814,2347366891,2347366922,2347367086,2347367169,2347367195,2347367419,2347367427,2347367438,2347367498,2347367525,2347367558,2347367570,2347367613,2347367631,2347367649,2347367696,2347367735,2347367750,2347367769,2347367880,2347368094,2347368162,2347368181,2347368203,2347368224,2347368239,2347368259}', '{100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255198, 181877970, '2', 'O', '123', null, null, 2, 3800, '{2347365816,2347365887,2347365912,2347365936,2347365988,2347366198,2347366361,2347366431,2347366763,2347366801,2347366817,2347366888,2347366919,2347367083,2347367166,2347367192,2347367422,2347367430,2347367435,2347367495,2347367522,2347367555,2347367573,2347367616,2347367628,2347367646,2347367699,2347367732,2347367747,2347367772,2347367877,2347368091,2347368165,2347368184,2347368206,2347368227,2347368236,2347368262}', '{100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255198, 181881671, '1', 'O', '123', null, null, 2, 3800, '{2347365820,2347365891,2347365916,2347365940,2347365992,2347366202,2347366365,2347366429,2347366767,2347366805,2347366815,2347366892,2347366923,2347367087,2347367170,2347367196,2347367420,2347367428,2347367439,2347367499,2347367526,2347367559,2347367571,2347367614,2347367632,2347367650,2347367697,2347367736,2347367751,2347367770,2347367881,2347368095,2347368163,2347368182,2347368204,2347368225,2347368240,2347368260}', '{100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255198, 181881671, '2', 'O', '123', null, null, 2, 3800, '{2347365817,2347365888,2347365913,2347365937,2347365989,2347366199,2347366362,2347366432,2347366764,2347366802,2347366818,2347366889,2347366920,2347367084,2347367167,2347367193,2347367423,2347367431,2347367436,2347367496,2347367523,2347367556,2347367574,2347367617,2347367629,2347367647,2347367700,2347367733,2347367748,2347367773,2347367878,2347368092,2347368166,2347368185,2347368207,2347368228,2347368237,2347368263}', '{100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255429, 179500526, '1', 'C', null, null, null, 144.754545, 2200, '{2347367745,2347367767,2347367776,2347367780,2347367783,2347367785,2347367791,2347368275}', '{500,500,500,500,50,50,50,50}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255429, 179510109, '2', 'O', null, null, null, 1.454545, 2200, '{2347367746,2347367768,2347367777,2347367781,2347367784,2347367786,2347367792,2347368276}', '{500,500,500,500,50,50,50,50}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255429, 180529611, '1', 'O', '019', null, null, 39.952941, 68, '{2347367039,2347367040,2347367043,2347367044,2347367045,2347367048,2347367049,2347367050,2347367053,2347367055,2347367056,2347367058,2347367060,2347367061,2347367062,2347367064,2347367065,2347367066,2347367067,2347367069,2347367070,2347367072,2347367073,2347367074,2347367537,2347367538,2347367543,2347367544,2347367546,2347367547,2347367549,2347367550,2347367551,2347367553,2347367577,2347367578,2347367580,2347367582,2347367585,2347367587,2347367589,2347367590}', '{2,1,2,1,2,2,2,1,2,2,1,2,2,2,1,2,1,1,2,1,1,1,1,1,3,3,3,3,2,3,3,2,1,1,1,1,1,1,1,1,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (255429, 180529611, '1', 'O', null, null, null, 40.438983, 59, '{2347366450,2347366787,2347366832,2347366864,2347367041,2347367042,2347367046,2347367047,2347367051,2347367052,2347367054,2347367057,2347367059,2347367063,2347367068,2347367071,2347367507,2347367511,2347367539,2347367540,2347367541,2347367542,2347367545,2347367548,2347367554,2347367576,2347367579,2347367581,2347367583,2347367584,2347367586,2347367588,2347367661}', '{2,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,2,1,1,1,1,1,1,1,2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (257077, 182004011, '1', 'C', '792', null, null, 0.04, 180, '{2347365870,2347365871,2347365872,2347365874,2347365875,2347365880}', '{30,30,30,30,30,30}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (257077, 182044732, '1', 'O', null, null, null, 8.9, 104, '{2347365920,2347365923,2347365924,2347365926,2347365927,2347365928,2347365977,2347365987,2347365999,2347366281,2347366798,2347367186,2347367187,2347367190,2347367191,2347367760,2347367828,2347368193,2347368201,2347368213,2347368217,2347368234,2347368242,2347368245,2347368246,2347368252,2347368254,2347368265,2347368266,2347368268,2347368270,2347368271}', '{9,1,33,1,1,1,1,1,1,1,14,3,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (257077, 182044732, '2', 'O', null, null, null, 9.196721, 183, '{2347365902,2347365903,2347365919,2347365921,2347365922,2347365925,2347365951,2347365953,2347365967,2347365973,2347365974,2347366171,2347366379,2347366380,2347366384}', '{17,33,44,24,9,33,6,1,1,1,10,1,1,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (257077, 182045805, '1', 'O', null, null, null, 29.310435, 345, '{2347367502,2347367503,2347367504,2347367505,2347367506,2347367513,2347367514,2347367521,2347367528,2347367536,2347368267,2347368269,2347368272}', '{333,1,1,1,1,1,1,1,1,1,1,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (257077, 182045805, '2', 'O', null, null, null, 29.894336, 512, '{2347367501,2347367605,2347367606,2347367607,2347367608,2347367611,2347367612,2347367619,2347367620,2347367621,2347367622,2347367626,2347367627,2347367636,2347367638,2347367641,2347367643,2347367645,2347367789,2347367790,2347367800,2347367811,2347367818,2347367821,2347367874,2347368102,2347368129,2347368154,2347368156,2347368157,2347368158,2347368159,2347368160,2347368168,2347368170,2347368174,2347368214,2347368215,2347368219,2347368222,2347368230,2347368232,2347368253,2347368255}', '{333,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,14,1,1,2,1,1,1,1,1,1,1,123,1,1,1,1,1,1,1,1,1,1,1,1,1,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (257078, 182004011, '2', 'C', null, null, null, 0.04, 180, '{2347365873,2347365876,2347365877,2347365878,2347365879,2347365881}', '{30,30,30,30,30,30}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 179434755, '1', 'O', null, null, null, 110, 1896, '{2347365056,2347365060,2347365064,2347365068,2347365117,2347365121,2347365127,2347365131,2347365133,2347365137,2347365141,2347365145}', '{210,210,105,107,210,105,210,107,210,210,107,105}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 181535859, '2', 'O', null, null, null, 5.796296, 54, '{2347365046,2347365047,2347365049,2347365108,2347365110,2347365111}', '{25,1,1,1,25,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 181535937, '2', 'O', null, null, null, 6.736429, 56, '{2347365045,2347365048,2347365050,2347365104,2347365107,2347365109}', '{26,1,1,1,26,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 181838812, '1', 'O', null, null, null, 0.01, 5, '{2347368233}', '{5}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 181866786, '2', 'O', '009', null, null, 0.02, 50, '{2347365152}', '{50}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 181894374, '2', 'O', null, null, null, 24.31, 5, '{2347368277,2347368278}', '{2,3}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 181894376, '1', 'O', '000', null, null, 36.15, 3, '{2347366237,2347366238}', '{1,2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182014195, '2', 'O', null, null, null, 7.131404, 57, '{2347365032,2347365036,2347365038,2347365041,2347365097,2347365101,2347365103}', '{1,26,1,1,1,26,1}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182021749, '2', 'O', '009', null, null, 7.25, 50, '{2347365151}', '{50}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182029053, '2', 'O', '009', null, null, 20.783333, 300, '{2347365148,2347365149,2347365150}', '{50,200,50}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182033330, '1', 'O', null, null, null, 4.1, 80, '{2347365030,2347365031,2347365093,2347365095}', '{20,20,20,20}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182033330, '2', 'O', null, null, null, 6.08931, 87, '{2347365033,2347365035,2347365039,2347365042,2347365051,2347365052,2347365053,2347365054,2347365098,2347365099,2347365102,2347365112,2347365113,2347365114,2347365115}', '{25,1,1,1,4,4,4,4,1,25,1,4,4,4,4}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182033331, '1', 'O', null, null, null, 4.719109, 2094, '{2347365023,2347365027,2347365057,2347365061,2347365065,2347365069,2347365082,2347365088,2347365118,2347365122,2347365125,2347365128,2347365134,2347365138,2347365142,2347365146}', '{9,90,210,210,107,105,9,90,210,210,105,107,210,210,107,105}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035972, '1', 'O', null, null, null, 6.351948, 2772, '{2347365022,2347365024,2347365026,2347365028,2347365029,2347365034,2347365037,2347365040,2347365058,2347365062,2347365066,2347365070,2347365083,2347365085,2347365090,2347365091,2347365092,2347365094,2347365096,2347365100,2347365119,2347365124,2347365126,2347365129,2347365135,2347365139,2347365143,2347365147}', '{9,9,90,90,60,60,60,60,210,210,107,105,9,9,90,90,60,60,60,60,210,210,105,107,210,210,107,105}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035990, '1', 'O', null, null, null, 65.5, 4, '{2347365010,2347365073}', '{2,2}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035990, '2', 'O', null, null, null, 64.4444, 10, '{2347365011,2347365074}', '{5,5}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035991, '1', 'O', null, null, null, 5.2, 200, '{2347365008,2347365071}', '{100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035991, '2', 'O', null, null, null, 5.2, 200, '{2347365009,2347365072}', '{100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035992, '1', 'O', null, null, null, 24, 4000, '{2347365020,2347365080}', '{2000,2000}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035992, '2', 'O', null, null, null, 25.252525, 2020, '{2347365019,2347365079}', '{1010,1010}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035993, '1', 'O', null, null, null, 9.8, 400, '{2347365012,2347365017,2347365075,2347365086}', '{100,100,100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035993, '2', 'O', null, null, null, 9.8, 200, '{2347365014,2347365077}', '{100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035994, '1', 'O', null, null, null, 8.1, 400, '{2347365013,2347365018,2347365076,2347365087}', '{100,100,100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035994, '2', 'O', null, null, null, 8.1, 200, '{2347365015,2347365078}', '{100,100}');
INSERT INTO genesis2.trade_for_allocations(account_id, instrument_id, side, open_close, cmta, mpid, eq_grp, avg_px, total_qty, trade_ids, last_qtys) VALUES (258492, 182035997, '1', 'O', null, null, null, 5.6, 20, '{2347365016,2347365081}', '{10,10}');
