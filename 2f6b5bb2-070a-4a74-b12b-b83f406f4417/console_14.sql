create table blaze7.src (id int4, ts timestamp);
create table blaze7.dst (id int4, ts timestamp);


insert into blaze7.src (id, ts)
values (1, clock_timestamp()),
       (2, clock_timestamp()),
       (3, clock_timestamp()),
       (4, clock_timestamp()),
       (5, clock_timestamp());


insert into blaze7.dst
select id, ts from blaze7.src
where id in (5)

select * from blaze7.src
select * from blaze7.dst;

select max(id)
from blaze7.src

select ts
from blaze7.src
order by id desc
limit 1

select * from blaze7.src
where ((id > 5)
or (ts > '2025-02-13 08:29:58.418223'));

select unnest(array[2346722287,2346722288,2346722301,2346722302,2346722303,2346722307,2346722308,2346722309,2346722310,2346722312,2346722313,2346722340,2346722342,2346722348,2346722352,2346722365,2346722370])