create table training.t1
(
    id  int8 primary key,
    txt text
);

create table training.t2
(
    id    bigserial primary key,
    t1_id int8
        constraint t2_t1_fk references training.t1 (id),
    txt   text
);

insert into training.t1 (id, txt)
values (1, 'txt1'),
       (2, 'txt2'),
       (3, 'txt3');

insert into training.t2 (t1_id, txt)
values (1, 'text'),
       (1, 'text2'),
       (2, 'text4'),
       (2, 'text4');

select *
from training.t1
         left join training.t2 on t2.t1_id = t1.id


select * from dwh.d_account
-- where account_name not in ('ITAC','CACEIS','dashautotest6')
where account_name not ilike all ('{ITAC, CACEIS, DASHAUTOTEST6}')

