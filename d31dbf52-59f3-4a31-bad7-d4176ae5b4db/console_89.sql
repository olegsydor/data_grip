insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240801;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240802;
-- insert into trash.sy_gtc_cache
-- select l.*
-- from gtc_order_status gos
--          inner join lateral (select *
--                              from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
--                                                                                        gos.create_date_id) ) l on true
-- where gos.close_date_id is null
--   and create_date_id = 20240805;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240806;

insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240807;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240808;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240809;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240812;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240813;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240814;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240815;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240816;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240819;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240820;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240821;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240822;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240823;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240826;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240827;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240828;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240829;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240830;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240903;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240904;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240905;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240906;
insert into trash.sy_gtc_cache
select l.*
from gtc_order_status gos
         inner join lateral (select *
                             from trash.order_blotter_fix_messages_chain_by_order_dmp2(gos.order_id,
                                                                                       gos.create_date_id) ) l on true
where gos.close_date_id is null
  and create_date_id = 20240909;