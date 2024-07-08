drop table if exists trash.so_cons_req;
create table trash.so_cons_req as
select ri.*
from
  (
    select ri.date_id, ri.route_type, ri.side, ri.exchange, ri.cross_exchange, ri.coa_indicator, ri.account, ri.cons_message_id, ri.cancel_chaser
    from consolidator.routing_instruction_message ri
    where ri.date_id between 20230902 and 20230929
      --and cm.rfr_id = '600303900085'
      and ri.route_type in (10,11,3)
  ) ri
;

--2 Oct
drop table if exists trash.so_cons_req_2;
create table trash.so_cons_req_2 as
--explain
select ri.date_id, ri.route_type, ri.side, ri.exchange, ri.cons_message_id, ri.cancel_chaser
  , cm.rfr_id, cm.request_number
from trash.so_cons_req ri
  join consolidator.consolidator_message cm
    on cm.cons_message_id = ri.cons_message_id and cm.message_type in (8, 9)
    and cm.date_id between 20230902 and 20230929 -- = 20230731
where ri.date_id between 20230902 and 20230929
and cm.rfr_id in ('760204378479', '740245810547', '710317275002', '780105394924');


--3 Oct
drop table if exists trash.so_cons_req_short_3;
create table trash.so_cons_req_short_3 as
-- explain
    select cm_8.date_id, cm_8.route_type
      , case cm_8.route_type
          when 10 then '94 (Route Type - 10 - Post then Cross)'  -- (Post then Cross) // Post order as part of Post then Cross
          when 11 then '96 (Route Type - 11 - Flash)'  -- (Flash) // Flash order
          when 3 then '97 (Route Type - 3 - DMA route to Post to the book + cancel_chaser = Y)'   -- (DMA route to Post to the book) // DMA to Post order... with Cancel Chaser
          when 12 then '98 (Route Type - 12 - Post as COA)'  -- (Post as COA) // Post as COA order
        end as reason_code
      , cm_8.exchange, cm_8.side --, ri.volume, ri.price, ri.cross_volume, ri.account, ri.cross_exchange, ri.cancel_chaser, ri.coa_indicator,
      , cm_8.rfr_id, cm_8.request_number, cm_8.cancel_chaser
      --, cm_9.* --
      , cm_9.date_id as routed_date_id, cm_9.side as routed_side, cm_9.mechanism as route_mechanism, cm_9.exchange as routed_exchange, cm_9.volume as routed_volume, cm_9.accepted_or_rejected, cm_9.executed_volume --, cm_9.message
      --, row_number() over (partition by cm_8.route_type, cm_9.exchange order by random()) rn_random
    from trash.so_cons_req_2 cm_8
      inner join lateral
        (
          select roi.date_id, roi.side, roi.mechanism, roi.exchange, roi.volume, roi.accepted_or_rejected, roi.executed_volume
            , cm_9.message, cm_9.rfr_id, cm_9.request_number--, cm_9.date_id
            , row_number() over (partition by cm_9.date_id, cm_9.rfr_id, cm_9.request_number, roi.side, roi.exchange order by roi.executed_volume asc nulls first) as dedup --
          from consolidator.consolidator_message cm_9
            left join consolidator.routed_order_information roi
              on cm_9.cons_message_id = roi.cons_message_id and cm_9.date_id = roi.date_id
          where 1=1 and cm_9.message_type = 9 -- Routed Order Information
            and cm_9.date_id between 20230902 and 20230929 -- 20230101 and 20230930 -- = 20231108 --
            and roi.date_id between 20230902 and 20230929 -- 20230101 and 20230930 -- = 20231108 --
            and cm_8.rfr_id = cm_9.rfr_id
            and cm_8.request_number = cm_9.request_number
            and cm_8.date_id = cm_9.date_id
             and cm_8.side = roi.side -- get rid off roi side which is for another RouteType
             and cm_8.exchange = roi.exchange -- important, as it can be in several exchanges for different RouteTypes for one side, so having just a side is not enough.
            and roi.accepted_or_rejected = 1
            --and roi.executed_volume > 0 -- !!! WTF!!!???
          limit 2
        ) cm_9 on true and cm_9.dedup = 1
    where cm_8.date_id between 20230902 and 20230929 -- 20230101 and 20230930 -- = 20231108 --
      and (
            (cm_8.route_type = 10) --(Post then Cross) -- var SA_RR_PC_POST_ORDER = 94 // Post order as part of Post then cross
            or
            (cm_8.route_type = 11) --(Flash)           -- var SA_RR_FLASH_ORDER = 96    // Flash order
            or
            (cm_8.route_type = 3 and cm_8.cancel_chaser = 'Y') --(DMA route to Post to the book) -- var SA_RR_DMA2POST_ORDER_CXL = 97 // DMA to Post order with Cancel Chaser
            or
            (cm_8.route_type = 12) --(Post as COA)     -- var SA_RR_POST_COA_ORDER = 98 // Post as COA order
          )
;
--select * from trash.so_cons_req_short_4
--4 Oct
drop table if exists trash.so_cons_req_short_4;
create table trash.so_cons_req_short_4 as
select co.*
  , t.* --t.reason_code, count(1)
from trash.so_cons_req_short_3 t
  left join lateral
    ( select str.* , ec.order_status
      from
        (
          select co.order_id, co.exchange_id, co.strtg_decision_reason_code
          from dwh.client_order co
          where co.create_date_id = t.date_id and co.create_date_id between 20230902 and 20230929
            and co.parent_order_id is not null  -- street level
            and co.dash_rfr_id = t.rfr_id
            and co.order_qty = t.routed_volume
            and co.side = t.side
            and co.request_number = t.request_number
            --and co.exchange_id ilike t.exch_beg||'%'
            and co.trans_type <> 'F' -- co.trans_type = 'F' --
            and co.multileg_reporting_type in ('1','2')
            and co.strtg_decision_reason_code::varchar = left(reason_code, 2)
          limit 1
        ) str
    --) co on true
      left join lateral
        (
          select ec.order_id, ec.order_status
          from dwh.execution ec
          where ec.exec_date_id = t.date_id and ec.exec_date_id between 20230902 and 20230929
            and ec.order_id = str.order_id
            and (ec.exec_type = '4' or ec.order_status = '4')
          limit 1
        ) ec on true
      where ec.order_id is not null
    ) co on true
where 1=1
  --and executed_volume = 0
  --and t.route_type not in (12)
  and co.order_id is not null
--group by t.reason_code
order by executed_volume
;




-- 5 Oct + Nov
drop table if exists trash.so_cons_req_short_5;
create table trash.so_cons_req_short_5 as
-- explain (30 min - WTF!!! so long...)
with all_msg_cte as materialized
  (
    select t.date_id, t.route_type
      , t.reason_code
      , t.exchange, t.side, t.cancel_chaser --, ri.cross_exchange, ri.coa_indicator, ri.volume, ri.price, ri.cross_volume, ri.account
      , t.rfr_id, t.request_number
      , t.routed_date_id, t.routed_side, t.route_mechanism, t.routed_exchange, t.routed_volume, t.accepted_or_rejected, t.executed_volume --, cm_9.message
      , ex.exch_beg, ex.exchange_name, t.order_id, t.exchange_id, t.strtg_decision_reason_code
      , row_number() over (partition by t.route_type, t.routed_exchange order by random()) rn
    from
      (
        select date_id, route_type, reason_code, exchange, side, rfr_id, request_number, cancel_chaser, routed_date_id, routed_side, route_mechanism, routed_exchange, routed_volume, accepted_or_rejected, executed_volume
          , order_id, exchange_id, strtg_decision_reason_code
        from trash.so_cons_req_short_4
--         union all
--         select date_id, route_type, reason_code, exchange, side, rfr_id, request_number, cancel_chaser, routed_date_id, routed_side, route_mechanism, routed_exchange, routed_volume, accepted_or_rejected, executed_volume
--           , order_id, exchange_id, strtg_decision_reason_code
--         from trash.sdn_tmp_tim_miller_consolidator_request_20231111_4_roi_11v3_canc
      ) t
      left join
        (
          select distinct t.exchange_number, t.exchange_name , left(ex.exchange_id,2) as exch_beg
            --t.*, ex.*
          from consolidator.cons_message_exchange t
            left join dwh.d_exchange ex
              on ( lower(t.exchange_name) = lower(ex.exchange_name)
                or lower(t.exchange_name) = lower(ex.exchange_id)
                or lower(t.exchange_name) = lower(ex.mic_code)
                or lower(t.exchange_name) = lower(ex.last_mkt)
                or lower(t.exchange_name) = lower(ex.cat_exchange_id)
                or (ex.exchange_id = 'MCRY' and t.exchange_name = 'MERCURY') --) (lower(ex.exchange_name) ilike '%'||lower(t.exchange_name)||'%')  and
                )
              and ex.is_active
              and ex.activ_exchange_code is not null
        ) ex on t.routed_exchange = ex.exchange_number
    where t.date_id between 20230902 and 20230929 -- = 20231108 --
      and t.accepted_or_rejected = 1
      and t.exchange_id ilike ex.exch_beg||'%'
  )
    select t.date_id, t.route_type, t.reason_code, t.routed_exchange, t.exchange, t.executed_volume, t.cancel_chaser, t.side --, t.coa_indicator, t.cross_exchange, t.account
      , t.rfr_id, t.request_number, t.routed_volume, t.exch_beg, t.exchange_name, t.order_id, t.exchange_id, t.strtg_decision_reason_code
    from all_msg_cte t
    where 1=1
      and t.rn <= 3000
;

select * from trash.so_cons_req_short_5;
-- 6 Oct + Nov
drop table if exists trash.so_cons_req_short_6;
create table trash.so_cons_req_short_6
as
with all_msg_cte_canc as materialized
  ( -- EXPLAIN
    select t.date_id, t.route_type, t.reason_code, t.routed_exchange, t.exchange, t.executed_volume, t.cancel_chaser, t.side --, t.coa_indicator, t.cross_exchange, t.account
      , row_number() over (partition by t.route_type, t.routed_exchange order by random()) rn_c -- to take 30-ty samples per 1 exchange in the 2 months range
      , t.order_id, t.exchange_id
      , t.rfr_id, t.request_number, t.routed_volume, t.exch_beg
    from --trash.sdn_tmp_tim_miller_consolidator_request_20231113_4_3k t
         trash.so_cons_req_short_5 t
--      left join lateral
--        (
--          select co.order_id, co.exchange_id
--          from dwh.client_order co
--          where 1=1 and co.create_date_id::varchar = t.date_id::varchar
--            and co.create_date_id between 20230101 and 20230531
--            and co.parent_order_id is not null  -- street level
--            and co.dash_rfr_id = t.rfr_id
--            and co.order_qty = t.routed_volume
--            and co.side = t.side
--            and co.request_number = t.request_number
--            and co.exchange_id ilike t.exch_beg||'%'
--            and co.trans_type <> 'F' -- co.trans_type = 'F' --
--            and co.multileg_reporting_type in ('1','2')
--            and co.strtg_decision_reason_code::varchar = left(t.reason_code, 2)
--          limit 1
--        ) str on true
--      left join lateral
--        (
--          select ec.exec_id
--          from dwh.execution ec
--          where 1=1
--            and ec.order_id = str.order_id
--            and (ec.exec_type = '4' or ec.order_status = '4')
--            and ec.exec_date_id = t.date_id and ec.exec_date_id between 20230101 and 20230531
--          limit 1
--        ) canc on true
--    where 1=1
--      --and t.rn <= 3000
--      and str.order_id is not null
--      and canc.exec_id is not null
  )
select to_char(to_date(t.date_id::varchar,'YYYYMMDD'), 'YYYY-MM-DD') as trade_date
  , po_ofp.client_order_id as ofp_parent_cl_ord_id --, po_lpo.client_order_id as lpo_parent_cl_ord_id
  , ac.account_name  as ofp_tag_1 , ac_lpo.account_name as lpo_tag_1 -- coalesce(t.account, ac_lpo.account_name) as lpo_tag_1
  , t.reason_code as reason_code_
  , case coalesce(t.routed_exchange, t.exchange)::varchar -- t.cross_exchange,
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
        else coalesce(t.exchange_id, t.routed_exchange::varchar, t.exchange::varchar)  -- t.cross_exchange,
    end as exchange_routed
  , t.*
  , po_ofp.order_id, po_ofp.multileg_reporting_type
  , ac.trading_firm_id , ac_lpo.trading_firm_id as lpo_trading_firm_id
from
  (
    select t.date_id, t.route_type, t.reason_code, t.routed_exchange, t.exchange, t.executed_volume, t.cancel_chaser --, t.coa_indicator, t.cross_exchange, t.account
      --, row_number() over (partition by t.route_type, t.routed_exchange order by random()) rn -- to take 30-ty samples per 1 exchange in the 2 months range
      , t.exchange_id
      , t.rfr_id, t.request_number  --, t.rn
    from all_msg_cte_canc t --all_msg_cte t
    where 1=1 and t.rn_c <= 30
      --and t.rfr_id = '720283831966'
  ) t
  --left join dwh.d_account ac on ac.account_name = t.account and ac.is_active = true -- аккаунт есть не везде, можно будет выдернуть из месседжа 8-ки
  left join lateral
    ( -- OFP
      select po_ofp.client_order_id , po_ofp.account_id, po_ofp.order_id, po_ofp.multileg_reporting_type
      from dwh.client_order po_ofp
      where t.rfr_id::bigint = po_ofp.internal_order_id and po_ofp.parent_order_id is null and po_ofp.dash_rfr_id is null
        and po_ofp.create_date_id >= 20220101
      limit 1
    ) po_ofp on true
  left join dwh.d_account ac
    on po_ofp.account_id = ac.account_id
  left join lateral
    ( -- LPO
      select po_lpo.client_order_id , po_lpo.account_id
      from dwh.client_order po_lpo
      where t.rfr_id = po_lpo.dash_rfr_id and po_lpo.parent_order_id is null
        and po_lpo.create_date_id >= 20230101
        and po_lpo.create_date_id = t.date_id
      limit 1
    ) po_lpo on true
  left join dwh.d_account ac_lpo
    on po_lpo.account_id = ac_lpo.account_id
where 1=1
order by t.reason_code, 6 --coalesce(t.routed_exchange, t.cross_exchange, t.exchange)::varchar
;


-- 7
 -- 94
Copy (

select t.trade_date as "Trade Date"
  , t.ofp_parent_cl_ord_id as "OFP Parent Cl Ord Id"
  , t.ofp_tag_1 as "OFP Tag 1"
  , t.reason_code_ as "Reason Code"
  , t.exchange_routed as "Exchange Routed"
from
  (
    --select * from trash.sdn_tmp_tim_miller_consolidator_request_20231113_4_30rprt t union all
    select * from trash.so_cons_req_short_6 t
  ) t
where 1=1 and t.exchange_routed not in ('0')
  and reason_code_ ilike '94%'
order by t.reason_code_, t.exchange_routed

)
  To '/var/lib/pgsql/scripts/Postgres_jobs/helper_script/hods/Consolidator_94 reason code_Oct_Nov.csv' with (HEADER, FORMAT CSV, DELIMITER ';')
;

 -- 96
Copy (

select t.trade_date as "Trade Date"
  , t.ofp_parent_cl_ord_id as "OFP Parent Cl Ord Id"
  , t.ofp_tag_1 as "OFP Tag 1"
  , t.reason_code_ as "Reason Code"
  , t.exchange_routed as "Exchange Routed"
from
  (
    --select * from trash.sdn_tmp_tim_miller_consolidator_request_20231113_4_30rprt t union all
    select * from trash.so_cons_req_short_6 t
  ) t
where 1=1 and t.exchange_routed not in ('0')
  and reason_code_ ilike '96%'
order by t.reason_code_, t.exchange_routed

)
  To '/var/lib/pgsql/scripts/Postgres_jobs/helper_script/hods/Consolidator_96 reason code_Oct_Nov.csv' with (HEADER, FORMAT CSV, DELIMITER ';')
;

 -- 97
Copy (

select t.trade_date as "Trade Date"
  , t.ofp_parent_cl_ord_id as "OFP Parent Cl Ord Id"
  , t.ofp_tag_1 as "OFP Tag 1"
  , t.reason_code_ as "Reason Code"
  , t.exchange_routed as "Exchange Routed"
from
  (
    --select * from trash.sdn_tmp_tim_miller_consolidator_request_20231113_4_30rprt t union all
    select * from trash.so_cons_req_short_6 t
  ) t
where 1=1 and t.exchange_routed not in ('0')
  and reason_code_ ilike '97%'
order by t.reason_code_, t.exchange_routed

)
  To '/var/lib/pgsql/scripts/Postgres_jobs/helper_script/hods/Consolidator_97 reason code_Oct_Nov.csv' with (HEADER, FORMAT CSV, DELIMITER ';')
;

 -- 98
Copy (

select t.trade_date as "Trade Date"
  , t.ofp_parent_cl_ord_id as "OFP Parent Cl Ord Id"
  , t.ofp_tag_1 as "OFP Tag 1"
  , t.reason_code_ as "Reason Code"
  , t.exchange_routed as "Exchange Routed"
from
  (
    --select * from trash.sdn_tmp_tim_miller_consolidator_request_20231113_4_30rprt t union all
    select * from trash.so_cons_req_short_6 t
  ) t
where 1=1 and t.exchange_routed not in ('0')
  and reason_code_ ilike '98%'
order by t.reason_code_, t.exchange_routed

)
  To '/var/lib/pgsql/scripts/Postgres_jobs/helper_script/hods/Consolidator_98 reason code_Oct_Nov.csv' with (HEADER, FORMAT CSV, DELIMITER ';')
;