create table training.clearing_account
(
    clearing_account_id int4,
    account_id          int4,
    koef                numeric
);

insert into training.clearing_account (clearing_account_id, account_id, koef)
values (4, 1, 0.1),
       (2, 1, 0.5),
       (3, 1, 0.1);

select * from training.clearing_account;

with base as (
select clearing_account_id,
                     account_id,
                     koef,
                     :qty                                                          as qty,
                     :qty * koef                                                   as pre_sum,
                     round(:qty * koef)                                            as rnd_sum,
                     sum(round(:qty * koef)) over w                                as acc_rnd_sum,
                     row_number() over w                                           as rn
              from training.clearing_account
              window w as (partition by account_id order by koef)
              )
select clearing_account_id,
       koef,
       pre_sum,
       case
           when rn != (select max(rn) from base) then false else true end base.rnd_sum
           else :qty - lag(base.acc_rnd_sum) over (partition by account_id order by koef) end,
       rn
from base



with base as (select clearing_account_id as id,
                     account_id,
                     koef,
                     :qty                           as qty,
                     :qty * koef                    as pre_sum,
                     round(:qty * koef)             as rnd_sum,
                     sum(round(:qty * koef)) over w as acc_rnd_sum,
                     row_number() over w            as rn
              from training.clearing_account
              window w as (partition by account_id order by koef, clearing_account_id))
select id,
       koef,
       pre_sum,
       rnd_sum,
       case
           when rn != (select max(rn) from base) then rnd_sum
           else :qty - lag(base.acc_rnd_sum) over (partition by account_id order by koef) end,
       rn
from base

select ceil(10.01)