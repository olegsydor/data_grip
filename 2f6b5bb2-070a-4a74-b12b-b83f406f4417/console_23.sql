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






select array[1,2,3,4,9] @> array[3,9];


WITH
    RECURSIVE base as (select *
                       FROM training.comb
                       where list_id between 0 and 4)
   , combs AS (
    -- стартуємо з одного елементу
    SELECT ARRAY [list_id] AS ids,
           list_id         AS max_id,
           list_sum,
           1               AS depth
    FROM base

    UNION ALL

    -- додаємо нові унікальні list_id з більшими значеннями
    SELECT c.ids || t.list_id,
           t.list_id,
           c.list_sum + t.list_sum,
           c.depth + 1
    FROM combs c
             JOIN base t ON t.list_id > c.max_id
    WHERE c.depth < 3 -- N=3
)
SELECT ids                                AS group_n_ids,
       list_sum                           AS group_n_sum,
       -- решта ID
       (SELECT array_agg(list_id)
        FROM base
        WHERE list_id <> ALL (combs.ids)) AS rest_ids,
       (SELECT sum(list_sum)
        FROM base
        WHERE list_id <> ALL (combs.ids)) AS rest_sum
FROM combs
WHERE depth = 3
ORDER BY group_n_ids;
------===
    -----------------------
select * from t_trade_combine

do
$$
    declare
        rc          record;
        cs          int4;
        l_row_cnt   int4;
        l_alloc     int4[] := '{}';
        l_trade     int8[] := '{}';
        l_new_trade int4[];
        l_is_ok     bool   := true;
    begin
        --         drop table if exists t_allocations;
--         create temp table t_allocations as
--         with base as (select alloc_instr_entry_id, ratio
--                       from unnest(:in_alloc_instr_entry_ids::int8[], :in_ratios::numeric[]) as t(alloc_instr_entry_id, ratio))
--         select *
--         from base;

        drop table if exists t_ret;
        create temp table t_ret
        (
            alloc_instr_entry_id int4,
            trade_record_id      int8
        );
        for rc in (select * from t_allocations order by ratio)
            loop
                raise notice 'rc - %', rc;
                select tr_with_1_prev
                into l_new_trade
                from t_trade_combine
                where in_ratio_1 = rc.ratio
                  and not (tr_with_1_prev && l_trade)
                limit 1;
                raise notice 'l_new_trade - %', l_new_trade;

                get diagnostics l_row_cnt = row_count;
                if l_row_cnt = 0 then
                    l_is_ok = false;
                    truncate table t_ret;
                    exit;
                end if;
                if l_row_cnt = 1 then
                    l_trade = l_trade || l_new_trade;
                    insert into t_ret(alloc_instr_entry_id, trade_record_id)
                    select rc.alloc_instr_entry_id, unnest(l_new_trade);
                end if;
            end loop;
        --         if l_is_ok then
--             return query
--             select
--         end if;

        raise notice '%, %', l_alloc, l_trade;

    end;
$$

select * from t_ret

select ((:array_1 @> :array_2) and (:array_1 <@ :array_2) )

select *
from t_trade_combine


select array_agg((val::numeric / total_sum)::numeric)
from (
    select val, sum(val) over () as total_sum
    from unnest('{10,20,30,40,100}'::int[]) as t(val)
) t;

----------
-- Good because ratios are the same in tr and alloc
select *
from genesis2.combine_trade_records(in_trade_record_ids := '{1, 2, 3, 4}', in_qty := '{10, 20, 30, 40}',
                                    in_ratios := '{0.1,0.2,0.4,0.3}', in_alloc_instr_entry_ids := '{100,101,102,103}');


select *
from genesis2.combine_trade_records(in_trade_record_ids := '{1, 2}', in_qty := '{10, 10}',
                                    in_ratios := '{0.5,0.5}', in_alloc_instr_entry_ids := '{100,101}');

-- wrong - ratios are different and cannot be matched
select *
from genesis2.combine_trade_records(in_trade_record_ids := '{1, 2, 3, 4}', in_qty := '{10, 20, 30, 41}',
                                    in_ratios := '{0.1,0.2,0.4,0.3}', in_alloc_instr_entry_ids := '{100,101,102,103}');


select *
from genesis2.combine_trade_records(in_trade_record_ids := '{1, 2, 3, 4}', in_qty := '{10, 30, 30, 30}',
                                    in_ratios := '{0.1,0.6,0.3}', in_alloc_instr_entry_ids := '{101,102,103}');

select *
from genesis2.combine_trade_records(in_trade_record_ids := '{1, 2, 3, 4}', in_qty := '{10, 30, 30, 30}',
                                    in_ratios := '{0.1,0.9}', in_alloc_instr_entry_ids := '{101,102}');


select *
from genesis2.combine_trade_records(in_trade_record_ids := '{1, 2, 3, 4}', in_qty := '{10, 30, 30, 30}',
                                    in_ratios := '{0.9,0.1}', in_alloc_instr_entry_ids := '{101,102}');


select *
from genesis2.combine_trade_records(in_trade_record_ids := '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}', in_qty := '{10, 30, 30, 30, 40, 50, 10, 50, 50, 100}',
                                    in_ratios := '{0.25,0.75}', in_alloc_instr_entry_ids := '{101,102}');


drop function if exists genesis2.combine_trade_records;
create or replace function genesis2.combine_trade_records(in_trade_record_ids int8[], in_qty int4[],
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
    l_total_qty          int4;
    l_row_count          int4;
    l_trade_ratio        numeric[];
    l_alloc_ratio        numeric[];
    l_trade_array_length int4   := array_length(in_trade_record_ids, 1);
    l_alloc_array_length int4   := array_length(in_alloc_instr_entry_ids, 1);
    l_rc                 record;
    l_trade              int8[] := '{}';
    l_new_trade          int4[];
    l_cnt_alloc          int4;
    l_ratio_left         numeric;
begin
    -- case 1: when trade and alloc arrays have 1 element only
    if l_trade_array_length = 1 and l_alloc_array_length = 1 then
        return query
            select unnest(in_alloc_instr_entry_ids),
                   unnest(in_trade_record_ids)
                       return;
    end if;

    -- case 1: when trade has more elements than alloc array has
    -- we don't manage cases like this because it definitely requires PTM
    if l_alloc_array_length > l_trade_array_length then
        return query
            select null,
                   unnest(in_trade_record_ids)
                       return;
    end if;


    drop table if exists t_trades;
    create temp table t_trades as
    with base as (select tr, qty, sum(qty) over () as sm
                  from unnest(in_trade_record_ids::int8[], in_qty::int4[]) as t(tr, qty))
    select *, qty * 1.0 / sm as ratio
    from base;

/*
    drop table if exists t_allocations;
    create temp table t_allocations as
    with base as (select t.alloc_instr_entry_id, t.ratio
                  from unnest(in_alloc_instr_entry_ids::int4[], in_ratios::numeric[]) as t(alloc_instr_entry_id, ratio))
    select *
    from base;
*/

    select array_agg((val::numeric / total_sum)::numeric)
    into l_trade_ratio
    from (select val, sum(val) over () as total_sum
          from unnest(in_qty) as t(val)
          order by 1) t;


    select array_agg(val::numeric)
    into l_alloc_ratio
    from (select val
          from unnest(in_ratios) as t(val)
          order by 1) t;


    -- case: if ratios match 1:1 (excluding the case when ratios are equal like 0.5 and 0.5 or 4 * 0.25 etc
    if l_trade_ratio = l_alloc_ratio then
        raise notice 'Matched CASE 0';
        return query
            select * from unnest(in_alloc_instr_entry_ids, in_trade_record_ids);
        return;
    end if;

    -- complicated cases
    -- -- preparing
    drop table if exists t_trade_combine;
    create temp table t_trade_combine as
    with base as (select tr,
                         qty,
                         -- 1
                         sum(qty) over (order by tr rows 1 preceding)           as qty_with_1_prev,
                         array_agg(tr) over (order by tr rows 1 preceding)      as tr_with_1_prev,

                         -- 2
                         sum(qty) over (order by tr desc rows 1 preceding)      as qty_with_1_next,
                         array_agg(tr) over (order by tr desc rows 1 preceding) as tr_with_1_next,

                         -- 3
                         sum(qty) over (order by tr rows 2 preceding)           as qty_with_2_prev,
                         array_agg(tr) over (order by tr rows 2 preceding)      as tr_with_2_prev,

                         -- 4
                         sum(qty) over (order by tr desc rows 2 preceding)      as qty_with_2_next,
                         array_agg(tr) over (order by tr desc rows 2 preceding) as tr_with_2_next,

                         sum(qty) over ()                                       as sum_total
                  from unnest(in_trade_record_ids::int8[], in_qty::int4[]) as t(tr, qty))
    select row_number() over ()                 as rn,
           tr,
           qty,
           qty::numeric / sum_total             as in_ratio_ind,

           qty_with_1_prev::numeric / sum_total as in_ratio_1,
           tr_with_1_prev,

           qty_with_1_next::numeric / sum_total as in_ratio_2,
           tr_with_1_next,

           qty_with_2_prev::numeric / sum_total as in_ratio_3,
           tr_with_2_prev,

           qty_with_2_next::numeric / sum_total as in_ratio_4,
           tr_with_2_next,
           sum_total
    from base;

    drop table if exists t_ret;
    create temp table t_ret
    (
        alloc_instr_entry_id int4,
        trade_record_id      int8
    );

    -- case 1C (1 complicated)
    l_trade := '{}';
    l_new_trade := '{}';
    l_cnt_alloc = l_alloc_array_length;
    l_ratio_left = 1;
    for l_rc in (select *
                 from unnest(in_alloc_instr_entry_ids::int4[], in_ratios::numeric[]) as t(alloc_instr_entry_id, ratio)
                 order by ratio desc)
        loop
            raise notice 'case - %, l_rc - %, l_cnt_alloc - %, l_ratio_left - %', 1, l_rc, l_cnt_alloc, l_ratio_left;
            if l_cnt_alloc = 1 /*Залишився останній запис*/ then
                raise notice 'last chance';
                if l_ratio_left = l_rc.ratio then
                    insert into t_ret
                    select l_rc.alloc_instr_entry_id, tr
                    from t_trades
                    except
                    select l_rc.alloc_instr_entry_id, unnest(l_trade);
                    raise notice 'Matched CASE 1C';
                    return query
                        select t_ret.alloc_instr_entry_id, t_ret.trade_record_id from t_ret;
                    return;
                else
                    truncate t_ret;
                    exit;
                end if;
            end if;

            select tr_with_1_prev
            into l_new_trade
            from t_trade_combine
            where in_ratio_1 = l_rc.ratio
              and not (tr_with_1_prev && l_trade)
            limit 1;
            get diagnostics l_row_count = row_count;
            if l_row_count = 0 then
                truncate t_ret;
                exit;
            else
                l_trade = l_trade || l_new_trade;
                insert into t_ret(alloc_instr_entry_id, trade_record_id)
                select l_rc.alloc_instr_entry_id, unnest(l_new_trade);
            end if;
            l_cnt_alloc = l_cnt_alloc - 1;
            l_ratio_left = l_ratio_left - l_rc.ratio;
        end loop;


    -- case 2C (2 complicated)
    l_trade := '{}';
    l_new_trade := '{}';
    l_cnt_alloc = l_alloc_array_length;
    l_ratio_left = 1;
    for l_rc in (select *
                 from unnest(in_alloc_instr_entry_ids::int4[], in_ratios::numeric[]) as t(alloc_instr_entry_id, ratio)
                 order by ratio desc)
        loop
            raise notice 'case - %, l_rc - %, l_cnt_alloc - %, l_ratio_left - %', 2, l_rc, l_cnt_alloc, l_ratio_left;
            if l_cnt_alloc = 1 /*Залишився останній запис*/ then
                raise notice 'last chance';
                if l_ratio_left = l_rc.ratio then
                    insert into t_ret
                    select l_rc.alloc_instr_entry_id, tr
                    from t_trades
                    except
                    select l_rc.alloc_instr_entry_id, unnest(l_trade);
                    raise notice 'Matched CASE 2C';
                    return query
                        select t_ret.alloc_instr_entry_id, t_ret.trade_record_id from t_ret;
                    return;
                else
                    truncate t_ret;
                    exit;
                end if;
            end if;

            select tr_with_2_prev
            into l_new_trade
            from t_trade_combine
            where in_ratio_3 = l_rc.ratio
              and not (tr_with_2_prev && l_trade)
            limit 1;
            get diagnostics l_row_count = row_count;
            if l_row_count = 0 then
                truncate t_ret;
                exit;
            else
                l_trade = l_trade || l_new_trade;
                insert into t_ret(alloc_instr_entry_id, trade_record_id)
                select l_rc.alloc_instr_entry_id, unnest(l_new_trade);
            end if;
            l_cnt_alloc = l_cnt_alloc - 1;
            l_ratio_left = l_ratio_left - l_rc.ratio;
        end loop;


    -- case 3C (3 complicated)
    l_trade := '{}';
    l_new_trade := '{}';
    l_cnt_alloc = l_alloc_array_length;
    l_ratio_left = 1;
    for l_rc in (select *
                 from unnest(in_alloc_instr_entry_ids::int4[], in_ratios::numeric[]) as t(alloc_instr_entry_id, ratio)
                 order by ratio desc)
        loop
            raise notice 'case - %, l_rc - %, l_cnt_alloc - %, l_ratio_left - %', 3, l_rc, l_cnt_alloc, l_ratio_left;
            if l_cnt_alloc = 1 /*Залишився останній запис*/ then
                raise notice 'last chance';
                if l_ratio_left = l_rc.ratio then
                    insert into t_ret
                    select l_rc.alloc_instr_entry_id, tr
                    from t_trades
                    except
                    select l_rc.alloc_instr_entry_id, unnest(l_trade);
                    raise notice 'Matched CASE 3C';
                    return query
                        select t_ret.alloc_instr_entry_id, t_ret.trade_record_id from t_ret;
                    return;
                else
                    truncate t_ret;
                    exit;
                end if;
            end if;

            select tr_with_1_next
            into l_new_trade
            from t_trade_combine
            where in_ratio_2 = l_rc.ratio
              and not (tr_with_1_next && l_trade)
            limit 1;
            get diagnostics l_row_count = row_count;
            if l_row_count = 0 then
                truncate t_ret;
                exit;
            else
                l_trade = l_trade || l_new_trade;
                insert into t_ret(alloc_instr_entry_id, trade_record_id)
                select l_rc.alloc_instr_entry_id, unnest(l_new_trade);
            end if;
            l_cnt_alloc = l_cnt_alloc - 1;
            l_ratio_left = l_ratio_left - l_rc.ratio;
        end loop;


    -- case 4C (4 complicated)
    l_trade := '{}';
    l_new_trade := '{}';
    l_cnt_alloc = l_alloc_array_length;
    l_ratio_left = 1;
    for l_rc in (select *
                 from unnest(in_alloc_instr_entry_ids::int4[], in_ratios::numeric[]) as t(alloc_instr_entry_id, ratio)
                 order by ratio desc)
        loop
            raise notice 'case - %, l_rc - %, l_cnt_alloc - %, l_ratio_left - %', 4, l_rc, l_cnt_alloc, l_ratio_left;
            if l_cnt_alloc = 1 /*Залишився останній запис*/ then
                raise notice 'last chance';
                if l_ratio_left = l_rc.ratio then
                    insert into t_ret
                    select l_rc.alloc_instr_entry_id, tr
                    from t_trades
                    except
                    select l_rc.alloc_instr_entry_id, unnest(l_trade);
                    raise notice 'Matched CASE 4C';
                    return query
                        select t_ret.alloc_instr_entry_id, t_ret.trade_record_id from t_ret;
                    return;
                else
                    truncate t_ret;
                    exit;
                end if;
            end if;

            select tr_with_2_next
            into l_new_trade
            from t_trade_combine
            where in_ratio_4 = l_rc.ratio
              and not (tr_with_2_next && l_trade)
            limit 1;
            get diagnostics l_row_count = row_count;
            if l_row_count = 0 then
                truncate t_ret;
                exit;
            else
                l_trade = l_trade || l_new_trade;
                insert into t_ret(alloc_instr_entry_id, trade_record_id)
                select l_rc.alloc_instr_entry_id, unnest(l_new_trade);
            end if;
            l_cnt_alloc = l_cnt_alloc - 1;
            l_ratio_left = l_ratio_left - l_rc.ratio;
        end loop;

    -- case 5C (4 complicated)
    l_trade := '{}';
    l_new_trade := '{}';
    l_cnt_alloc = l_alloc_array_length;
    l_ratio_left = 1;
    for l_rc in (select *
                 from unnest(in_alloc_instr_entry_ids::int4[], in_ratios::numeric[]) as t(alloc_instr_entry_id, ratio)
                 order by ratio)
        loop
            raise notice 'case - %, l_rc - %, l_cnt_alloc - %, l_ratio_left - %', 5, l_rc, l_cnt_alloc, l_ratio_left;
            if l_cnt_alloc = 1 /*Залишився останній запис*/ then
                raise notice 'last chance';
                if l_ratio_left = l_rc.ratio then
                    insert into t_ret
                    select l_rc.alloc_instr_entry_id, tr
                    from t_trades
                    except
                    select l_rc.alloc_instr_entry_id, unnest(l_trade);
                    raise notice 'Matched CASE 4C';
                    return query
                        select t_ret.alloc_instr_entry_id, t_ret.trade_record_id from t_ret;
                    return;
                else
                    truncate t_ret;
                    exit;
                end if;
            end if;

            select tr_with_2_next
            into l_new_trade
            from t_trade_combine
            where in_ratio_4 = l_rc.ratio
              and not (tr_with_2_next && l_trade)
            limit 1;
            get diagnostics l_row_count = row_count;
            if l_row_count = 0 then
                truncate t_ret;
                exit;
            else
                l_trade = l_trade || l_new_trade;
                insert into t_ret(alloc_instr_entry_id, trade_record_id)
                select l_rc.alloc_instr_entry_id, unnest(l_new_trade);
            end if;
            l_cnt_alloc = l_cnt_alloc - 1;
            l_ratio_left = l_ratio_left - l_rc.ratio;
        end loop;



    -- was not matched;
    return query
        select null::int4, tr from t_trades;
    return;

end;
$fx$;
select * from t_trade_combine