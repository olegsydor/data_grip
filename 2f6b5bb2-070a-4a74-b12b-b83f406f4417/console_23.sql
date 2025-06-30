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




create table training.comb (
    list_id int4,
    list_sum int4
);
insert into training.comb(list_id, list_sum) values (6, 1), (7, 2), (8, 3), (9, 5), (10, 4)

with recursive subset_sum as (
    select
        array[list_id] as ids,
        list_id as max_id,
        list_sum,
        1 as depth
    from training.comb

    union all

    select
        ss.ids || c.list_id,
        c.list_id,
        ss.list_sum + c.list_sum,
        ss.depth + 1
    from subset_sum ss
    join training.comb c
      on c.list_id > ss.max_id
    where ss.list_sum + c.list_sum <= :sum
)
select *
from subset_sum
where list_sum = :sum
order by depth, ids
limit 1;


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


select array_agg(mnt) from regexp_split_to_table('01,02,03,січень',',') as mnt
where mnt ~* '[A]'