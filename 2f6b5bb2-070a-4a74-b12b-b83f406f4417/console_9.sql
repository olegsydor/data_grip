create table training.pack
(
    pack_id          int4,
    pack_approve_dec bool,
    pack_approve_req bool,
    pack_status_id   int
);
alter table training.pack add column decs_id int;
alter table training.pack add column reqs_id int;

insert into training.pack (pack_id, pack_approve_dec, pack_approve_req)
values (1, true, false);


select * from training.pack;
update training.pack
set pack_approve_dec = case when :in_decs_id is not null then true else pack_approve_dec end