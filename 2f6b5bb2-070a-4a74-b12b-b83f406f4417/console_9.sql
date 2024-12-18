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
values (2, false, true);


select * from training.pack;

update training.pack dst
set pack_approve_dec = case when :in_decs_id is not null then true else dst.pack_approve_dec end,
    pack_approve_req = case when :in_reqs_id is not null then true else dst.pack_approve_req end,
    pack_status_id   = case
                           when ((dst.reqs_id is not null and dst.pack_approve_req) or dst.reqs_id is null) then 1
                           when ((dst.decs_id is not null and dst.pack_approve_dec) or dst.decs_id is null) then 1
                           else src.pack_status_id end
from training.pack src
where src.pack_id = dst.pack_id
  and dst.pack_id = 1

