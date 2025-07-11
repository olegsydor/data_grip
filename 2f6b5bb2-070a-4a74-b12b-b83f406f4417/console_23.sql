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

with base as (select *
              from training.comb
              where list_id between 0 and 4)
select a.list_id as a_list, b.b_list
from base as a
         join lateral (select array_agg(b.list_id) as b_list from base as b where b.list_id != a.list_id limit 1) b on true;




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



drop table if exists t_aie;
  create temp table t_aie on commit drop as
  with base as (select ai.alloc_instr_id,
                       ca.clearing_account_id,
                       ai.account_id,
                       ca.auto_alloc_ratio,
                       ai.total_qty                                          as qty,
                       ai.total_qty * auto_alloc_ratio                    as pre_sum,
                       floor(ai.total_qty * auto_alloc_ratio)             as rnd_sum,
                       sum(floor(ai.total_qty * auto_alloc_ratio)) over w as acc_rnd_sum,
                       row_number() over w                                   as rn,
                       ca.occ_actionable_id
                from genesis2.allocation_instruction ai
                         inner join t_clearing_account_aa ca on (ca.account_id = ai.account_id)
                where ai.date_id = :l_date_id
--                   and ai.dataset_id = l_load_batch_id
                  and ai.is_deleted = 'N'
                group by ai.date_id, ai.alloc_instr_id, ai.total_qty, ca.occ_actionable_id, ca.clearing_account_id,
                         ai.account_id, ca.auto_alloc_ratio, ca.clearing_account_number
                window w as ( partition by ai.alloc_instr_id, ai.account_id
                        order by ca.auto_alloc_ratio, ca.clearing_account_number desc, ca.clearing_account_id)
                )
  select alloc_instr_id,
         clearing_account_id,
         case
             when rn != (select max(rn) from base b where b.alloc_instr_id = base.alloc_instr_id) then rnd_sum
             else qty - lag(base.acc_rnd_sum)
                        over (partition by alloc_instr_id order by auto_alloc_ratio) end  as alloc_qty,
--          rn,
--          qty as alloc_qty,
         occ_actionable_id,
--          l_date_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;

with base as (select tr, qty, sum(qty) over () as sm
              from unnest(:trade_ids::int8[], :last_qtys::int4[]) as t(tr, qty))
select *, qty * 1.0 / sm
from base;




select array[1,2,3,4,9] @> array[3,9];



create function genesis2.combine_trade_records(in_trade_record_ids int8[], in_qty int4[],
                                               in_ratios numeric[], in_alloc_instr_entry_ids int4[])
    returns table
            (
                alloc_instr_entry_id int4,
                trade_record_id      int8
            )
    language plpgsql
as
$fx$
declare

begin


end;
$fx$