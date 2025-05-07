select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
       coalesce(tr.client_order_id, '')            as "OrderID",
       coalesce(tr.secondary_order_id, '')         as "ExchOrderID",
       case
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX') then jos.t_880
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP') then jos.t_880
           end                                     as aux_tag_street,

--        tr.account_id,
       coalesce(tr.secondary_exch_exec_id, '')     as "ReportID", -- Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange
       coalesce(tr.exch_exec_id, '')               as "Tag17"
--            ,tr.order_id
--        ,           *
from dwh.flat_trade_record tr
         left join lateral (select jo.fix_message ->> '143' as t_143
                            from fix_capture.fix_message_json jo
                            where tr.order_fix_message_id = jo.fix_message_id
                              and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                            limit 1) jo on true
         left join lateral (select jo.fix_message ->> '143'  as t_143,
                                   jo.fix_message ->> '9483' as t_9483,
                                   jo.fix_message ->> '1003' as t_1003,
                                   jo.fix_message ->> '880'  as t_880
                            from fix_capture.fix_message_json jo
                            where tr.street_trade_fix_message_id = jo.fix_message_id
                              and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                            limit 1) jos on true
         left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
where true
--   and tr.secondary_exch_exec_id in ('l25akrts0002', 'l25akrts0000')
--       and tr.client_order_id = '20250325VSIND28939'
  and tr.date_id between :l_start_date_id and :p_end_date_id
  and tr.account_id = any (:l_account_ids)
  and tr.is_busted = 'N'
--         and tr.order_id in (100000019696533965, 100000019696533916)
--   and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE')
  and case
          when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
              then false
          else true end;


select * from dwh.execution
where exec_date_id = 20250325
and order_id in (100000019696533965, 100000019696533916)
and secondary_exch_exec_id in ('l25akrts0002', 'l25akrts0000')

select * from dwh.d_account
where 	true
  and trading_firm_id in ('xfa', 'xfachi')
		and account_name <> 'XFADESKTCM'


select * from client_order
where parent_order_id = 100000019696533916;
---
with base as (
select to_char(ex.exec_time, 'YYYY-MM-DD') as "Date",
                     cl.client_order_id                  as "OrderID",
                     str.client_order_id                 as "ExchOrderID",
                     case
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX')
                             then jos.t_880
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP')
                             then jos.t_880
                         end                             as aux_tag_street,
                     ex.secondary_exch_exec_id           as "ReportID",
                     ex.exch_exec_id                     as "Tag17"
                      ,
                     cl.trading_firm_id,
                     ac.account_name,
                     fxm.*,
                     ex.*,
                     cl.* --ex.*, order_qty
              from client_order cl
                       inner join d_account ac on ac.account_id = cl.account_id and ac.is_active = true
                       join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                       left join dwh.d_exchange dex on dex.exchange_id = cl.exchange_id and dex.is_active
                  -- 		inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
--
-- 		inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
-- 		inner join d_option_contract oc on oc.instrument_id = cl.instrument_id
-- 		inner join d_option_series os on os.option_series_id  = oc.option_series_id
-- 		left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
                       left join lateral
                  (select j.fix_message,
                          j.fix_message ->> '143'   as tag_143,
                          j.fix_message ->> '423'   as tag_423,
                          j.fix_message ->> '9281'  as tag_9281,
                          j.fix_message ->> '22017' as tag_22017,
                          j.fix_message ->> '115'   as tag_115,
                          j.fix_message ->> '109'   as tag_109--, j.fix_message->>'5059' as tag_5059, j.fix_message->>'134' as tag_134, j.fix_message->>'135' as tag_135
                   from fix_capture.fix_message_json j
                   where j.fix_message_id = cl.fix_message_id
                     and j.date_id = :in_date_id
                   limit 1
                  ) fxm on true
                       left join lateral (select client_order_id
                                          from dwh.client_order str
                                          where str.parent_order_id = cl.order_id
                                          limit 1) str on true
                       left join lateral (select exch_exec_id, exec_time, ex.fix_message_id, ex.secondary_exch_exec_id
                                          from dwh.execution ex
                                          where ex.order_id = cl.order_id
                                            and ex.exec_type = 'F'
                  ) ex on true
                       left join lateral (select jo.fix_message ->> '143'  as t_143,
                                                 jo.fix_message ->> '9483' as t_9483,
                                                 jo.fix_message ->> '1003' as t_1003,
                                                 jo.fix_message ->> '880'  as t_880
                                          from fix_capture.fix_message_json jo
                                          where ex.fix_message_id = jo.fix_message_id
                                            and jo.date_id = cl.create_date_id
                                          limit 1) jos on true
              where cl.create_date_id = :in_date_id
                and case
                        when cl.parent_order_id is null then true
                        when cl.parent_order_id is not null and cl.trading_firm_id in ('xfa', 'xfachi') and
                             ac.account_name <> 'XFADESKTCM' then true -- XFA
                        when cl.parent_order_id is not null and fxm.tag_143 in ('RFAC', 'DASH')
                            then true -- routed to DASH Desk (143=DASH), Casey Securities (Tag 143 = RFAC)
--           when cl.parent_order_id is not null and ac.account_name in ('TASTYSPX', 'TDSPX_BP')
--               then true -- for SPX
                        else false end
                and ac.account_id = 73660)
select * from base
where true
    and row_to_json(base.*)::text ilike '%394215660%'

; -- e.g. Vision March 2025 example--BEAA0023-20250325

select row_to_json(ftr.*), * from dwh.flat_trade_record ftr
where date_id = 20250325
-- and account_id = 73660
  and alternative_compliance_id = '20250325VSIND28939'
and row_to_json(ftr.*)::text ilike '%1407944308%'
;



select * from staging.dash_trade_record
where date_id = 20250325
and account_id = 73660


'20250325VSIND28939'

select * from dwh.execution ex
    where true
      and ex.exec_date_id = 20250325
and row_to_json(ex.*)::text ilike 'l25akrts0002'--, 'l25akrts0000')

-------

select *  from dwh.client_order
where account_id = 73660
and create_date_id = 20250325
