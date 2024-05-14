create table test.mab_order
(
    order_id          varchar(32)  not null,
    amount            int8         null,
    upc_order_date    timestamp    null,
    upc_approval_code varchar(6)   null,
    rrn               varchar(12)  null,
    terminal_id       varchar(15)  null,
    sys_from          varchar(100) null,
    advice_id         int8         null,
    insdate_int       int          not null
)
    partition by range (insdate_int);

create table partitions.mab_order_202301 partition of test.mab_order  for values from (20230101) to (20230201);
create table partitions.mab_order_202302 partition of test.mab_order  for values from (20230201) to (20230301);
create table partitions.mab_order_202303 partition of test.mab_order  for values from (20230301) to (20230401);
create table partitions.mab_order_202304 partition of test.mab_order  for values from (20230401) to (20230501);
create table partitions.mab_order_202305 partition of test.mab_order  for values from (20230501) to (20230601);
create table partitions.mab_order_202306 partition of test.mab_order  for values from (20230601) to (20230701);
create table partitions.mab_order_202307 partition of test.mab_order  for values from (20230701) to (20230801);
create table partitions.mab_order_202308 partition of test.mab_order  for values from (20230801) to (20230901);
create table partitions.mab_order_202309 partition of test.mab_order  for values from (20230901) to (20231001);
create table partitions.mab_order_202310 partition of test.mab_order  for values from (20231001) to (20231101);
create table partitions.mab_order_202311 partition of test.mab_order  for values from (20231101) to (20231201);
create table partitions.mab_order_202312 partition of test.mab_order  for values from (20231201) to (20240101);
create table partitions.mab_order_202401 partition of test.mab_order  for values from (20240101) to (20240201);
create table partitions.mab_order_202402 partition of test.mab_order  for values from (20240201) to (20240301);
create table partitions.mab_order_202403 partition of test.mab_order  for values from (20240301) to (20240401);
create table partitions.mab_order_202404 partition of test.mab_order  for values from (20240401) to (20240501);
create table partitions.mab_order_202405 partition of test.mab_order  for values from (20240501) to (20240601);
create table partitions.mab_order_202406 partition of test.mab_order  for values from (20240601) to (20240701);



create table test.mab_order_old
(
    order_id          varchar(32)  not null,
    amount            int8         null,
    upc_order_date    timestamp    null,
    upc_approval_code varchar(6)   null,
    rrn               varchar(12)  null,
    terminal_id       varchar(15)  null,
    sys_from          varchar(100) null,
    advice_id         int8         null,
    insdate_int       int          not null
);

insert into test.mab_order_old
select * from test.mab_order;

create index on test.mab_order_old (advice_id);

select advice_id, count(*)
from test.mab_order
where advice_id > 100000
group by advice_id
having count(*) > 10
limit 10;


insert into test.mab_order(order_id, amount, upc_order_date, upc_approval_code, rrn, terminal_id, sys_from, advice_id,
                           insdate_int)
select v1,
       n1,
       t1,
       v2,
       v3,
       v4,
       v5,
       n2,
       to_char(t1, 'YYYYMMDD')::int
from (select left(md5(i::text), 32)                                                               as v1,
             left(md5(random()::text), 6)                                                         as v2,
             left(md5(random()::text), 12)                                                        as v3,
             left(md5(random()::text), 15)                                                        as v4,
             left(md5(random()::text), 100)                                                       as v5,
             '2023-01-01'::timestamp + interval '1 minute' * round(random()::numeric * 758880, 0) as t1,
             round(random() * 100000)                                                             as n1,
             round(random() * 2000000)                                                            as n2
      from generate_series(1, 10000000) s(i)
      ) x;


select * from test.mab_order_old
where advice_id = 100008

show all