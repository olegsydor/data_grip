select 21117307
+ 8691883

select cm.message_type, count(*)
    from consolidator.consolidator_message cm
    where cm.date_id between 20230902 and 20230929
    and cm.message ilike '%IMC%'
    and cm.message_type = any('{6, 7}')
group by cm.message_type;
--         and ri.rfr_id = '760204378479'

drop table if exists trash.so_consolidator_message;
create table trash.so_consolidator_message
as
select *
from consolidator.consolidator_message cm
where true
  and cm.date_id between 20230902 and 20230929
--   and cm.rfr_id in ('760204378479', '740245810547', '710317275002', '780105394924', '100284649835')
;
create index on trash.so_consolidator_message (cons_message_id, message_type);
create index on trash.so_consolidator_message (rfr_id);

drop table if exists trash.so_routing_instruction_message;
create table trash.so_routing_instruction_message as
select *
from consolidator.routing_instruction_message ri
where ri.date_id between 20230902 and 20230929
  and ri.route_type in (3, 10, 11)
-- and cons_message_id in (select cons_message_id from trash.so_consolidator_message)
;
drop table if exists trash.so_routed_order_information;
create table trash.so_routed_order_information as
    select * from consolidator.routed_order_information
        where date_id between 20230902 and 20230929;
create index on trash.so_routed_order_information (cons_message_id, date_id);


drop table if exists trash.so_base;
create table trash.so_base as
--explain
select ri.date_id,
       ri.route_type,
       ri.side,
       ri.exchange,
       ri.cons_message_id,
       ri.cancel_chaser,
       cm.rfr_id,
       cm.request_number,
       case ri.route_type
           when 10
               then '94 (Route Type - 10 - Post then Cross)' -- (Post then Cross) // Post order as part of Post then Cross
           when 11 then '96 (Route Type - 11 - Flash)' -- (Flash) // Flash order
           when 3
               then '97 (Route Type - 3 - DMA route to Post to the book + cancel_chaser = Y)' -- (DMA route to Post to the book) // DMA to Post order... with Cancel Chaser
           end        as reason_code,
       cm_9.date_id   as routed_date_id,
       cm_9.side      as routed_side,
       cm_9.mechanism as route_mechanism,
       cm_9.exchange  as routed_exchange,
       cm_9.volume    as routed_volume,
       cm_9.accepted_or_rejected,
       cm_9.executed_volume --, cm_9.message
from trash.so_routing_instruction_message ri
         join trash.so_consolidator_message cm
              on cm.cons_message_id = ri.cons_message_id and cm.message_type = 8
                  and cm.date_id between 20230902 and 20230929
         left join lateral
    (
    select roi.date_id
         , roi.side
         , roi.mechanism
         , roi.exchange
         , roi.volume
         , roi.accepted_or_rejected
         , roi.executed_volume
         , cmi.message
         , cmi.rfr_id
         , cmi.request_number--, cm_9.date_id
         , row_number()
           over (partition by cmi.date_id, cmi.rfr_id, cmi.request_number, roi.side, roi.exchange order by roi.executed_volume asc nulls first) as dedup --
    from trash.so_consolidator_message cmi
             left join trash.so_routed_order_information roi
                       on cmi.cons_message_id = roi.cons_message_id and cmi.date_id = roi.date_id
    where true
      and cmi.message_type = 9       -- Routed Order Information
      and cmi.date_id between 20230902 and 20230929
      and roi.date_id between 20230902 and 20230929
      and cm.rfr_id = cmi.rfr_id
      and cm.request_number = cmi.request_number
      and cm.date_id = cmi.date_id
      and ri.side = roi.side         -- get rid off roi side which is for another RouteType
      and ri.exchange = roi.exchange -- important, as it can be in several exchanges for different RouteTypes for one side, so having just a side is not enough.
--       and roi.accepted_or_rejected = 1
    limit 2
    ) cm_9 on true and cm_9.dedup = 1
where ri.date_id between 20230902 and 20230929
  and cm.message ilike '%IMC%'
--   and cm.rfr_id = '100284649835'
 and (
            (ri.route_type = 10) --(Post then Cross) -- var SA_RR_PC_POST_ORDER = 94 // Post order as part of Post then cross
            or
            (ri.route_type = 11) --(Flash)           -- var SA_RR_FLASH_ORDER = 96    // Flash order
            or
            (ri.route_type = 3 and ri.cancel_chaser = 'Y') --(DMA route to Post to the book) -- var SA_RR_DMA2POST_ORDER_CXL = 97 // DMA to Post order with Cancel Chaser
--             or
--             (ri.route_type = 12) --(Post as COA)     -- var SA_RR_POST_COA_ORDER = 98 // Post as COA order
          );

select * from  trash.so_base
where rfr_id = '100284649835';

drop table if exists trash.so_main_ext;
create table trash.so_main_ext as
select co.*
     , main.* --t.reason_code, count(1)
from trash.so_base main
         left join lateral
    (
    select co.order_id, co.exchange_id, co.strtg_decision_reason_code, ec.exec_id_arr, cnt
    from dwh.client_order co
             left join lateral (select ec.order_id, count(*) as cnt, array_agg(exec_id order by exec_id) as exec_id_arr
                                from dwh.execution ec
                                where ec.exec_date_id >= co.create_date_id
                                  and ec.exec_date_id between 20230902 and 20230929
                                  and ec.order_id = co.order_id
                                  and ec.exec_type in ('A', 'O', '5', 'F')--= 'F'
                                group by ec.order_id
                                limit 1) ec on true
    where co.create_date_id = main.date_id
      and co.create_date_id between 20230902 and 20230929
      and co.parent_order_id is not null -- street level
      and co.dash_rfr_id = main.rfr_id
      and co.order_qty = main.routed_volume
      and co.side = main.side
      and co.request_number = main.request_number
      --and co.exchange_id ilike t.exch_beg||'%'
      and co.trans_type <> 'F'           -- co.trans_type = 'F' --
      and co.multileg_reporting_type in ('1', '2')
      and co.strtg_decision_reason_code::varchar = left(reason_code, 2)
    limit 1
    ) co on true
where true
and main.rfr_id = '100284649835';

select * from trash.so_main_ext;
create index on trash.so_main_ext (rfr_id, route_type, request_number);

drop table if exists trash.so_cons_prepared;
create table trash.so_cons_prepared as
select rfr_id,
       request_number,
       route_type,
       dense_rank() over (partition by rfr_id, route_type order by request_number) as rn,
       dense_rank() over (partition by rfr_id order by request_number)             as rn_total,
       executed_volume,
       cnt,
       case coalesce(routed_exchange::varchar, exchange::varchar) -- t.cross_exchange,
           when '1' then 'AMEX'
           when '2' then 'ARCA'
           when '3' then 'BATS'
           when '4' then 'BOX'
           when '5' then 'BX'
           when '6' then 'C2'
           when '7' then 'CBOE'
           when '8' then 'EDGE'
           when '9' then 'GEMINI'
           when '10' then 'ISE'
           when '11' then 'MCRY'
           when '12' then 'MIAX'
           when '13' then 'PEARL'
           when '14' then 'NOM'
           when '15' then 'PHLX'
           when '16' then 'EMERALD'
           when '17' then 'MXOP'
           else coalesce(exchange_id, routed_exchange::varchar, exchange::varchar)
           end                                                                     as exchange_routed,
    side
from trash.so_main_ext
 where rfr_id = '100284649835'
;

select * from trash.so_cons_prepared
where rfr_id = '740245810547';

with al as (select rfr_id,
                   request_number,
                   route_type,
                   executed_volume,
                   exchange_routed,
                   cnt,
                   case
                       when rn = 1 and nullif(executed_volume, 0) is not null then 'a'
                       when rn = 1 and nullif(executed_volume, 0) is null then 'b'
                       when rn_total > 1 and nullif(executed_volume, 0) is not null then 'c'
                       when rn_total > 1 and nullif(executed_volume, 0) is null then 'd' end as routed_type
            from trash.so_cons_prepared
            where true
            and rfr_id = '760204378479'
            and executed_volume is not null
            )
select
route_type, routed_type, count(*)
from al
group by route_type, routed_type
order by 1, 2;


with al as (select rfr_id,
                   request_number,
                   route_type,
                   sum(executed_volume),
                   min(rn) as rn,
                   min(rn_total) as rn_total
                   ,
                   case
                       when min(rn) = 1 and sum(executed_volume) > 0 then 'a'
                       when min(rn) = 1 and sum(executed_volume)  = 0  then 'b'
                       when min(rn_total) > 1 and sum(executed_volume) > 0 then 'c'
                       when min(rn_total) > 1 and sum(executed_volume) = 0 then 'd' end as routed_type
            from trash.so_cons_prepared
            where true
            and rfr_id = '100284649835'
            and executed_volume is not null
            group by rfr_id, request_number, route_type
            )
-- select
-- route_type, routed_type, count(*)
-- from al
-- group by route_type, routed_type
-- order by 1, 2;
select rfr_id, request_number, route_type, routed_type
from al

select * from (values (0, 'zero'), (1, 'one'), (2, 'two')) as t(digit, string);

select ARRAY_AGG(X) from (values (	16260247914	),
(	16260247918	),
(	16260248044	),
(	16260248045	),
(	16260248067	),
(	16260248068	),
(	16260248069	),
(	16260248070	),
(	16260248071	),
(	16260248100	),
(	16260248101	),
(	16260248102	),
(	16260248128	),
(	16260248129	),
(	16260248130	),
(	16260248152	),
(	16260248153	),
(	16260248154	),
(	16260248319	),
(	16260248320	),
(	16260248321	),
(	16260248322	),
(	16260248323	),
(	16260248361	),
(	16260248383	),
(	16260248408	),
(	16260248420	),
(	16260248421	),
(	16260248437	),
(	16260248582	),
(	16260248583	),
(	16260248584	),
(	16260248588	),
(	16260249362	),
(	16260273255	),
(	16260273256	),
(	16260273257	),
(	16260273258	),
(	16260273259	),
(	16260249374	),
(	16260249375	),
(	16260249376	),
(	16260249377	),
(	16260249378	),
(	16260249379	),
(	16260249389	),
(	16260249390	),
(	16260273271	),
(	16260249403	),
(	16260270425	),
(	16260270426	),
(	16260270428	),
(	16260270430	),
(	16260270431	),
(	16260270432	),
(	16260270433	),
(	16260270434	),
(	16260270435	),
(	16260275228	),
(	16260275229	),
(	16260275230	),
(	16260275231	),
(	16260275232	),
(	16260275233	),
(	16260275234	),
(	16260275235	),
(	16260275236	),
(	16260248629	),
(	16260248630	),
(	16260248631	),
(	16260248663	),
(	16260248701	),
(	16260248702	),
(	16260248703	),
(	16260248704	),
(	16260248725	),
(	16260248726	),
(	16260248727	),
(	16260248728	),
(	16260248789	),
(	16260248790	),
(	16260248791	),
(	16260248798	),
(	16260248799	),
(	16260248800	),
(	16260248860	),
(	16260248908	),
(	16260248950	),
(	16260248951	),
(	16260248952	),
(	16260248958	),
(	16260248959	),
(	16260248960	),
(	16260248970	),
(	16260248971	),
(	16260248972	),
(	16260248973	),
(	16260248974	),
(	16260248975	),
(	16260248987	),
(	16260248995	),
(	16260249029	),
(	16260249120	),
(	16260249148	),
(	16260249149	),
(	16260249160	),
(	16260249210	),
(	16260249212	),
(	16260249213	),
(	16260249214	),
(	16260249215	),
(	16260249216	),
(	16260249232	),
(	16260249235	),
(	16260249255	),
(	16260249256	),
(	16260249257	),
(	16260249258	),
(	16260249259	),
(	16260249306	),
(	16260334530	),
(	16260334606	),
(	16260334635	),
(	16260282758	),
(	16260282759	),
(	16260282760	),
(	16260282761	),
(	16260282762	),
(	16260282763	),
(	16260308030	),
(	16260444919	),
(	16260444920	),
(	16260444897	),
(	16260444898	),
(	16260445129	),
(	16260445130	),
(	16260445131	),
(	16260445132	),
(	16260308086	),
(	16260234072	),
(	16260319751	),
(	16260283952	),
(	16260284040	),
(	16260288701	),
(	16260288702	),
(	16260288703	),
(	16260308691	),
(	16260286181	),
(	16260307700	),
(	16260307732	),
(	16260271131	),
(	16260271132	),
(	16260271133	),
(	16260271134	),
(	16260271135	),
(	16260336204	),
(	16260336205	),
(	16260336206	),
(	16260336207	),
(	16260336208	),
(	16260271260	),
(	16260271261	),
(	16260271262	),
(	16260277248	),
(	16260337851	),
(	16260337852	),
(	16260337853	),
(	16260337907	),
(	16260337908	),
(	16260337909	),
(	16260271564	),
(	16260271565	),
(	16260271566	),
(	16260271567	),
(	16260271568	),
(	16260271569	),
(	16260271570	),
(	16260271571	),
(	16260337933	),
(	16260337934	),
(	16260337935	),
(	16260271613	),
(	16260271614	),
(	16260271615	),
(	16260271629	),
(	16260271630	),
(	16260271631	),
(	16260338019	),
(	16260338020	),
(	16260338021	),
(	16260271714	),
(	16260271715	),
(	16260271716	),
(	16260338022	),
(	16260338096	),
(	16260338097	),
(	16260338098	),
(	16260338151	),
(	16260338152	),
(	16260338153	),
(	16260271829	),
(	16260271830	),
(	16260271831	),
(	16260307821	),
(	16260338220	),
(	16260338221	),
(	16260338222	),
(	16260338223	),
(	16260271893	),
(	16260271894	),
(	16260271895	),
(	16260271896	),
(	16260275867	),
(	16260275868	),
(	16260275869	),
(	16260349800	),
(	16260349801	),
(	16260349802	),
(	16260307839	),
(	16260338282	),
(	16260338283	),
(	16260338284	),
(	16260338285	),
(	16260338286	),
(	16260307870	),
(	16260338312	),
(	16260338348	),
(	16260338349	),
(	16260338350	),
(	16260338413	),
(	16260338414	),
(	16260338415	),
(	16260338416	),
(	16260338477	),
(	16260338478	),
(	16260338479	),
(	16260338480	),
(	16260308593	),
(	16260301072	),
(	16260300163	),
(	16260300164	),
(	16260300165	),
(	16260300166	),
(	16260300167	),
(	16260300168	),
(	16260300169	),
(	16260300170	),
(	16260300171	),
(	16260300172	),
(	16260300173	),
(	16260300174	),
(	16260300175	),
(	16260300176	),
(	16260300177	),
(	16260300178	),
(	16260300179	),
(	16260300180	),
(	16260300181	),
(	16260300182	),
(	16260300332	),
(	16260300333	),
(	16260300334	),
(	16260300335	),
(	16260300336	),
(	16260300337	),
(	16260300338	),
(	16260300339	),
(	16260300340	),
(	16260300341	),
(	16260300342	),
(	16260300343	),
(	16260300344	),
(	16260300345	),
(	16260300346	),
(	16260300347	),
(	16260300348	),
(	16260300349	),
(	16260300350	),
(	16260300351	),
(	16260300384	),
(	16260300385	),
(	16260300386	),
(	16260300387	),
(	16260300388	),
(	16260302673	),
(	16260302674	),
(	16260302675	),
(	16260249542	),
(	16260302690	),
(	16260302691	),
(	16260302692	),
(	16260302693	),
(	16260302741	),
(	16260302742	),
(	16260302743	),
(	16260446136	),
(	16260446137	),
(	16260446138	),
(	16260446139	),
(	16260446140	),
(	16260446141	),
(	16260446142	),
(	16260446143	),
(	16260446144	),
(	16260446145	),
(	16260301894	),
(	16260302992	),
(	16260303019	),
(	16260303020	),
(	16260303021	),
(	16260303036	),
(	16260303037	),
(	16260303038	),
(	16260235222	),
(	16260235223	),
(	16260235224	),
(	16260308529	),
(	16260310258	),
(	16260310259	),
(	16260310260	),
(	16260310281	),
(	16260310282	),
(	16260310283	),
(	16260247131	),
(	16260247132	),
(	16260247133	),
(	16260310348	),
(	16260310349	),
(	16260310350	),
(	16260310728	),
(	16260310729	),
(	16260310730	),
(	16260247528	),
(	16260247529	),
(	16260247530	),
(	16260310798	),
(	16260310799	),
(	16260310800	),
(	16260247607	),
(	16260247608	),
(	16260247609	),
(	16260310850	),
(	16260310851	),
(	16260310852	),
(	16260242885	),
(	16260242886	),
(	16260242887	),
(	16260242888	),
(	16260242889	),
(	16260242890	),
(	16260242891	),
(	16260242892	),
(	16260242893	),
(	16260242894	),
(	16260242895	),
(	16260242896	),
(	16260242897	),
(	16260242898	),
(	16260242899	),
(	16260242900	),
(	16260242901	),
(	16260242902	),
(	16260242903	),
(	16260242904	),
(	16260242905	),
(	16260242906	),
(	16260242907	),
(	16260242908	),
(	16260242909	),
(	16260242910	),
(	16260242911	),
(	16260242912	),
(	16260242913	),
(	16260242914	),
(	16260242765	),
(	16260242766	),
(	16260242767	),
(	16260242768	),
(	16260242769	),
(	16260242770	),
(	16260242771	),
(	16260242772	),
(	16260242773	),
(	16260242613	),
(	16260242614	),
(	16260242615	),
(	16260242616	),
(	16260242617	),
(	16260242618	)) AS Y(X)