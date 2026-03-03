select *
from trash.report_obo_compliance_xls_with_clordid(in_date_begin_id := 20260106, in_date_end_id := 20260106,
                                                  in_include_routes := 'Y', in_include_acks := 'Y',
                                                  in_client_order_ids := '{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}');
select * from t_base
------------------------------------------------------------

drop table if exists t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord;
create temp table t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord as
select di.symbol
     , di.symbol_suffix
     , di.instrument_type_id
     , oc.opra_symbol
     , os.root_symbol
     , ui.symbol       as underlying_symbol
     , di.last_trade_date
     , oc.put_call
     , oc.strike_price
     , fc.fix_comp_id
     , fc.is_high_frequency_trader
     , ac.trading_firm_id as ac_trading_firm_id
     , ac.cat_suppress as ac_cat_suppress
     , ac.account_name
     , ac.account_holder_type
     , tf.cat_imid
     , tf.cat_crd
     , tf.cat_suppress as tf_cat_suppress
     , so.cpar_cnt
     , so.cross_cnt
     , ml.no_legs      as ml_no_legs
     , tif.tif_short_name
     , tf.is_broker_dealer
     , ac.broker_dealer_mpid
     , ac.cat_report_on_behalf_of
     , ac.crd_number
     , cl.*
from dwh.client_order cl
         inner join dwh.d_instrument di on cl.instrument_id = di.instrument_id
         left join dwh.d_option_contract oc on di.instrument_id = oc.instrument_id
         left join d_option_series os on os.option_series_id = oc.option_series_id
         left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
         inner join d_account ac on ac.account_id = cl.account_id
         inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
         inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
         left join lateral
    ( select str.parent_order_id,
             --count(*) filter (where str.cross_order_id is null) single_cnt,
             count(*) filter (where str.exchange_id = 'C1PAR')      cpar_cnt,
             count(*) filter (where str.cross_order_id is not null) cross_cnt
      from client_order str
      where str.trans_type <> 'F'
        and str.parent_order_id is not null
        and str.create_date_id = 20260106 --in_date_id
        and str.parent_order_id = cl.order_id
      group by str.parent_order_id
      limit 1
    ) so on true
         left join lateral
    (
    select ml.order_id
         , ml.client_order_id
         , ml.fix_message_id
         , ml.no_legs
    from client_order ml
    where cl.multileg_reporting_type = '2'
      and ml.order_id = cl.multileg_order_id
      and ml.multileg_reporting_type = '3'
      and ml.create_date_id = 20260106
    limit 1
    ) ml on true
         left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
where cl.create_date_id = 20260106
--   and di.symbol in ('PRGO','AAPL','GOOG','MSFT','NVDA','SPY','TSLA')
  and cl.trans_type <> 'F'
  and cl.parent_order_id is null
  and cl.multileg_reporting_type in ('1', '2')
  and cl.trans_type <> 'F'
  and cl.client_order_id = any
      ('{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}');


drop table if exists t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_cancells;
create temp table t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_cancells as
select ec.exec_date_id,
       min(ec.exec_time) as exec_time,
       min(ec.cum_qty)   as cum_qty,
       ec.order_id,
       ec.account_id,
       cl.fix_connection_id,
       cl.sub_strategy_desc,
       cl.co_client_leg_ref_id,
       cl.instrument_id,
       cl.order_qty,
       cl.client_order_id,
       cl.process_time,
       cl.create_time,
       cl.side,
       cl.ex_destination,
       cl.create_date_id,
       cl.multileg_reporting_type,
       cl.trans_type,
       ml.no_legs,
       di.symbol
from execution ec
         inner join client_order cl on ec.order_id = cl.order_id
         left join dwh.d_instrument di on cl.instrument_id = di.instrument_id
         left join lateral
    (
    select ml.order_id
         , ml.client_order_id
         , ml.fix_message_id
         , ml.no_legs
    from client_order ml
    where cl.multileg_reporting_type = '2'
      and ml.order_id = cl.multileg_order_id
      and ml.multileg_reporting_type = '3'
      and ml.create_date_id = 20260106
    limit 1
    ) ml on true
where ec.exec_date_id = 20260106
  and ec.is_parent_level = true
  and (ec.exec_type = '4' or ec.order_status = '4')
  and cl.create_date_id > 20230619 --l_gtc_date_id
  and (cl.create_date_id = 20260106 or cl.time_in_force_id in ('1', '6'))
  and cl.parent_order_id is null
  and cl.trans_type in ('D', 'G')
  and (cl.multileg_reporting_type in ('1', '2') or cl.sub_strategy_desc = 'VEGA')
  and coalesce(cl.time_in_force_id, '0') <> '3'
  and cl.ex_destination not in ('RPTR', 'SQHT', 'WEEDN', 'JSEB', 'TRAFX', 'FBMS', 'CTDH', 'DASH', 'OUTCR', 'SLXX')
--   and di.symbol in ('PRGO', 'AAPL', 'GOOG', 'MSFT', 'NVDA', 'SPY', 'TSLA')
 and cl.client_order_id = any
      ('{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}');
group by ec.exec_date_id,
         ec.order_id,
         ec.account_id,
         cl.fix_connection_id,
         cl.sub_strategy_desc,
         cl.co_client_leg_ref_id,
         cl.instrument_id,
         cl.order_qty,
         cl.client_order_id,
         cl.process_time,
         cl.create_time,
         cl.side,
         cl.ex_destination,
         cl.create_date_id,
         cl.multileg_reporting_type,
         cl.trans_type,
         ml.no_legs,
         di.symbol
;

select is_broker_dealer,* from t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord;


drop table if exists t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_cancells;
create table t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_cancells as
select ec.exec_date_id,
       min(ec.exec_time)      as exec_time,
       min(ec.fix_message_id) as ex_fix_message_id,
       min(ec.cum_qty)        as cum_qty,
       ec.order_id,
       ec.account_id,
       cl.fix_connection_id,
       cl.fix_message_id,
       cl.exchange_id,
       cl.instrument_id,
       cl.order_qty,
       cl.client_order_id,
       cl.parent_order_id,
       cl.process_time,
       cl.side,
       cl.market_participant_id,
       cl.sub_strategy_desc,
       cl.co_client_leg_ref_id,
       cl.create_time,
       cl.ex_destination,
       cl.create_date_id,
       cl.multileg_reporting_type,
       cl.trans_type,
       cl.orig_order_id,
       cl.ratio_qty,
       ml.no_legs,
       di.symbol,
       di.instrument_type_id,
       di.symbol_suffix,
       di.last_trade_date
from execution ec
         inner join client_order cl on ec.order_id = cl.order_id
         left join dwh.d_instrument di on cl.instrument_id = di.instrument_id
         left join lateral
    (
    select ml.order_id
         , ml.client_order_id
         , ml.fix_message_id
         , ml.no_legs
    from client_order ml
    where cl.multileg_reporting_type = '2'
      and ml.order_id = cl.multileg_order_id
      and ml.multileg_reporting_type = '3'
      and ml.create_date_id = 20260106
    limit 1
    ) ml on true
where ec.exec_date_id = 20260106
  and ec.is_parent_level = false
  and (ec.exec_type = '4' or ec.order_status = '4')
  and cl.create_date_id > 20230619                                --l_gtc_date_id
  and (cl.create_date_id = 20260106 or cl.time_in_force_id in ('1', '6'))
  and cl.parent_order_id is not null
  and cl.trans_type in ('D', 'G')
  and (cl.multileg_reporting_type in ('1', '2') or cl.sub_strategy_desc = 'VEGA')
  and cl.client_order_id = any
      ('{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1"}')
  and cl.ex_destination not in ('RPTR', 'BRKPT', 'SLXX', 'BLAZE') --suppression
  --and cl.exchange_id not in ('JSEB','PHLXFB','SQHT','TRAFX','WEEDN','WEEDNE','CTDLHT')--collapsion
--   and di.symbol in ('PRGO', 'AAPL', 'GOOG', 'MSFT', 'NVDA', 'SPY', 'TSLA')
group by ec.exec_date_id,
         ec.order_id,
         ec.account_id,
         cl.fix_connection_id,
         cl.fix_message_id,
         cl.exchange_id,
         cl.instrument_id,
         cl.order_qty,
         cl.client_order_id,
         cl.parent_order_id,
         cl.process_time,
         cl.side,
         cl.market_participant_id,
         cl.sub_strategy_desc,
         cl.co_client_leg_ref_id,
         cl.create_time,
         cl.ex_destination,
         cl.create_date_id,
         cl.multileg_reporting_type,
         cl.trans_type,
         cl.orig_order_id,
         cl.ratio_qty,
         ml.no_legs,
         di.symbol,
         di.instrument_type_id,
         di.symbol_suffix,
         di.last_trade_date
;


drop table if exists t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_ord;
create temp table t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_ord as
    -- explain
select po.client_order_id         as po_client_order_id
     , po.create_date_id          as po_create_date_id
     , po.order_id                as po_order_id
     , po.fix_connection_id       as po_fix_connection_id
     , po.multileg_reporting_type as po_multileg_reporting_type
     , po.co_client_leg_ref_id    as po_co_client_leg_ref_id
     , po.sub_strategy_desc       as po_sub_strategy_desc
     , po.ex_destination          as po_ex_destination
     , po.process_time            as po_process_time
     , po.fix_message_id          as po_fix_message_id
     , po.trans_type              as po_trans_type
     , po.time_in_force_id        as po_time_in_force_id
     , po.orig_order_id           as po_orig_order_id
     , ac.trading_firm_id         as ac_trading_firm_id
     , ac.account_name
     , fc.fix_comp_id             as fc_fix_comp_id
     , tf.is_broker_dealer        as tf_is_broker_dealer
     , tf.cat_imid                as tf_cat_imid
     , di.symbol
     , di.symbol_suffix
     , di.instrument_type_id
     , di.last_trade_date --, oc.opra_symbol, ui.symbol as underlying_symbol
     , cl.*
from client_order cl--DUAK3206-20260106
         inner join d_account ac on ac.account_id = cl.account_id and ac.is_active = true
         inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
         inner join client_order po
                    on cl.parent_order_id = po.order_id -- and po.create_date_id between 20200619 and 20260106 - dup condition
         inner join d_fix_connection fc on fc.fix_connection_id = po.fix_connection_id and fc.is_active = true
         left join dwh.d_instrument di on cl.instrument_id = di.instrument_id

where cl.create_date_id = 20260106                                --in_date_id
  and po.create_date_id > 20230717
  and (po.create_date_id between 20260101 and 20260106 or po.time_in_force_id in ('1', '6'))
  and cl.parent_order_id is not null
  and cl.trans_type in ('D', 'G')
  and cl.multileg_reporting_type in ('1', '2')
  --and (cl.multileg_reporting_type = '1' or (cl.exchange_id in ('BOX','PHLX') and cl.cross_order_Id is not null))
  and coalesce(tf.cat_suppress, 'N') <> 'Y'
  and coalesce(ac.cat_suppress, 'N') <> 'Y'
  and cl.ex_destination not in ('RPTR', 'BRKPT', 'SLXX', 'BLAZE') --suppression
  --and cl.exchange_id not in ('JSEB','PHLXFB','SQHT','TRAFX','WEEDN','WEEDNE','CTDLHT') --collapsion. there is nothing here.
  and (cl.exchange_id not in ('C1PAR')
    or
    --fc.fix_comp_id not in ('LPEQP','LPOPTP','LQPNCP','LPOFP','LPOPTB','LPOPTSTP','LPEQSTP','LQPNCP5INT','LQPNCPINT',
    --             'LPEQPGTH','LPOPTPGTH','LPCROSSGTHINT','DASHOPTP')
       po.fix_connection_id not in (6116, 6200, 6320, 8225, 6985, 9485, 636, 958, 1043,
                                    1607, 1461, 1462, 1465)
    )
  --and cl.order_id not in (select order_id from compliance.aggregated_street_cross)
--   and di.symbol in ('PRGO', 'AAPL', 'GOOG', 'MSFT', 'NVDA', 'SPY', 'TSLA')
  and po.client_order_id = any
      ('{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}');
;
select * from t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_ord;


drop table if exists t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status;
create temp table t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status as
    -- explain
select cl.*
     , le.order_status
     , case
           when cl.parent_order_id is null
               then tr.filled_qty
           else le.filled_qty
    end as filled_qty
     , le.max_cum_qty
     , le.last_mkt
from (
         -- 1047654
         select t.order_id, t.parent_order_id, t.create_date_id, t.time_in_force_id, t.symbol, t.order_qty
         from t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord t
         union all
         -- 1724736
         select t.order_id, t.parent_order_id, t.create_date_id, t.time_in_force_id, t.symbol, t.order_qty
         from t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_ord t
         --limit 1000
     ) cl
         left join lateral
    (
    select e.order_id
         , e.exec_id
         , e.order_status
         , e.exec_type
         , e.last_qty
         , e.last_mkt
         , e.cum_qty
         , e.exec_time
         , row_number() over (partition by e.order_id order by e.exec_time desc, e.exec_id desc) as rn
         , sum(e.last_qty) over (partition by e.order_id)                                        as filled_qty
         , max(e.cum_qty) over (partition by e.order_id)                                         as max_cum_qty
    --, max(e.last_mkt) over (partition by e.order_id) as max_last_mkt -- looks like it is wrong as each trade can have last_mkt
    --, last_value(e.last_mkt) over (partition by e.order_id order by e.exec_time, e.exec_id) as max_last_mkt -- Oh, last_mkt usually is on PARENT level trades
    from dwh.execution e
    where e.order_id = cl.order_id
      and e.exec_date_id between 20260101 and 20260106 -- last status as for 12/23, but including GTH
      and e.exec_type not in ('A') --,'3') -- remove DoneForDay if we need
    ) le on rn = 1 --last status
         left join lateral
    ( -- for parent orders only
    select tr.order_id, sum(tr.last_qty) as filled_qty
    from dwh.flat_trade_record tr
    where tr.date_id = 20260106
      and cl.parent_order_id is null
      and cl.order_id = tr.order_id
      and tr.is_busted = 'N'
    group by tr.order_id
    ) tr on true

--order by cl.order_id, le.exec_time
;

select * from t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status;

--------------

with ord_par_new as
  (  -- explain  -- very long
      select case
                 when t.trading_firm_id = 'ctctrad01' then
                     replace(t.client_order_id, '|', '-') || '_' || t.fix_comp_id
                 when t.sub_strategy_desc = 'VEGA'
                     then replace(t.client_order_id, '|', '-') || '_' || coalesce(t.co_client_leg_ref_id, '0')
                 when t.ex_destination = 'LIQPT' then t.client_order_id || '_' || t.side::varchar
                 else replace(t.client_order_id, '|', '-')
          end                                                                                          as orderID
           , 'NEW'                                                                                     as event_type
           , to_char(t.process_time, 'YYYYMMDD')                                                       as event_date
           , to_char(t.process_time, 'HH24:MI:SS.US')                                                  as event_time
           , ''::varchar                                                                               as orig_cl_ord_id        -- need for modification and cancel
           , coalesce(t.order_qty, 0)                                                                  as event_qty
           , case
          --when t.order_type_id in ('2','4') then to_char(abs(coalesce(t.price,0)), 'FM9999999990.09999999')
                 when t.order_type_id in ('2', '4') then to_char((coalesce(t.price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as event_price
           , case when t.multileg_reporting_type = '2' then 'Y' else 'N' end                           as multi_leg_indicator
           , t.ml_no_legs                                                                              as number_of_legs
           , t.co_client_leg_ref_id                                                                    as leg_order_id
           , t.ratio_qty::varchar                                                                      as leg_ratio
--            , ls.order_status_description                                                              as order_status          --  ???????????? status
           , t.opra_symbol                                                                             as osi_symbol
           , t.symbol                                                                                  as base_symbol
           , t.symbol || coalesce(' ' || t.symbol_suffix, '')                                          as symbol
           , t.instrument_type_id                                                                      as security_type         -- missed in EOS
           , t.underlying_symbol                                                                       as underlying_symbol
           , case t.put_call
                 when '0' then 'P'
                 when '1' then 'C'
                 else 'S'
          end                                                                                          as put_call_stock
           , to_char(t.last_trade_date, 'YYYYMMDD')                                                    as expiration_date
           , case
                 when t.side in ('1', '3') then 'B'
                 when t.instrument_type_id = 'O' and t.side not in ('1', '3') then 'S'
                 when t.side = '2' then 'SL'
                 when t.side = '5' then 'SS'
                 when t.side = '6' then 'SX'
                 else 'B'
          end                                                                                          as side
           , case
                 when t.tif_short_name in ('GTC', 'IOC') then t.tif_short_name
                 when t.tif_short_name = 'GTX' then 'GTX=' || to_char(t.process_time, 'YYYYMMDD')
                 when t.tif_short_name = 'GTD' then 'GTD=' || coalesce(to_char(t.expire_time, 'YYYYMMDD'), fxm.tag_432,
                                                                       to_char(t.process_time, 'YYYYMMDD'))
                 when t.time_in_force_id in ('C', 'M') then 'GTC'
                 else 'DAY=' || to_char(t.process_time, 'YYYYMMDD')
          end                                                                                          as tif
           , coalesce(to_char(t.expire_time, 'YYYYMMDD'), left(coalesce(fxm.tag_126, fxm.tag_432), 8)) as good_till_date
           , to_char(coalesce(t.expire_time, (to_timestamp((coalesce(fxm.tag_126, fxm.tag_432))::text,
                                                           'YYYYMMDD HH24:MI:SS.US')::timestamp at time zone 'UTC')),
                     'HH24:MI:SS.US')::varchar                                                         as good_till_time
           , ls.filled_qty::varchar                                                                    as filled_qty            --  ???????????? status
           , case
                 when t.order_type_id in ('2', '4') and fxm.tag_423 = '0' then 'CAB'
                 when t.order_type_id in ('2', '4') then 'LMT'
                 else 'MKT'
          end                                                                                          as order_type
           , case
                 when t.time_in_force_id = '7' and t.order_type_id = '2' then 'LOC'
                 when t.time_in_force_id = '7' and t.order_type_id = '1' then 'MOC'
                 when t.time_in_force_id = '2' and t.order_type_id = '2' then 'LOO'
                 when t.time_in_force_id = '2' and t.order_type_id = '1' then 'MOO'
          end                                                                                          as limit_market_type
           , case
          --when t.order_type_id in ('2') then to_char(abs(coalesce(t.price,0)), 'FM9999999990.09999999')
                 when t.order_type_id in ('2') then to_char((coalesce(t.price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as order_price
           , to_char(t.create_time, 'YYYYMMDD')::varchar                                               as order_creation_date
           , to_char(t.create_time, 'HH24:MI:SS.MS')::varchar                                          as order_creation_time
           , case t.open_close
                 when 'C' then 'Close'
                 when 'O' then 'Open'
                 else ''
          end                                                                                          as open_close
           , (case when t.max_floor > 0 then 'Y' else '' end)::varchar                                 as is_reserve_size_order ---- ????????????? Is Reserve Size Order - populate 'Y’ when tag 111>0. Tag 111 - is max_floor
           , case
                 when t.cross_order_id is not null
                     then 'Y'
                 else 'N'
          end::varchar                                                                                 as is_cross
           , 'False'::varchar                                                                          as is_manual
           , (case when fxm.tag_389 is not null then 'Y' else '' end)::varchar                         as with_discretion_price ---- ????????????? With Discretion Price - populate ‘Y' when offset tag 389 is present
           , to_char(t.algo_start_time, 'YYYYMMDD HH24:MI:SS.MS')                                      as trigger_time_of_managed_order
           , (case
                  when t.instrument_type_id = 'E' and t.exec_instruction ~ '(f)' then 'Y'::varchar
                  else ''::varchar end)::varchar                                                       as iso_flag
           , null::varchar                                                                             as representative_order  ---- ?????????????
           , case
          --when t.order_type_id in ('3','4') then to_char(abs(coalesce(t.stop_price,0)), 'FM9999999990.09999999')
                 when t.order_type_id in ('3', '4') then to_char((coalesce(t.stop_price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as stop_price
           , t.max_floor::varchar                                                                      as max_floor
           , case when t.max_floor > 0 then t.max_floor::varchar end                                   as display_quantity
           , coalesce(t.customer_or_firm_id, t.eq_order_capacity)                                      as capacity              -- SO removed order_capacity_id
--            , coalesce(t.customer_or_firm_id, t.order_capacity_id, t.eq_order_capacity)                 as capacity
           , fxm.tag_109                                                                               as user_
           , t.account_name                                                                            as account_name
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
                     then t.account_id::varchar
          end                                                                                          as fdid
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
                     then coalesce(t.account_holder_type, 'A')
          end                                                                                          as account_holder_type
           , case
                 when t.fix_comp_id in ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTPA', 'TESTOFP',
                     --GTH
                                        'TESTGTHLB1', 'TESTGTHDASH') then '' --'BLAZE7PROD2' removed
          --cowen01
                 when t.trading_firm_id in
                      ('cowen01', 'cuttone', 'etcinc01', 'monrchccm', 'jscap', 'LPTF259', 'greatpnt', 'triadsc01',
                       'merrill01', 'wedbush', 'EFP0009', 'OFP0042', 'veloclear', 'volantats',
                       'OFP0045', 'OFP0016', 'wain01', 'OFP0032') and coalesce(t.cat_report_on_behalf_of, 'N') = 'N'
                     then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = t.broker_dealer_mpid
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' || t.broker_dealer_mpid,
                              t.crd_number || ':' || t.broker_dealer_mpid,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --precision
                 when t.trading_firm_id in ('precision') and t.fix_comp_id in ('SILEXXP') and
                      coalesce(t.cat_report_on_behalf_of, 'N') = 'N' then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = t.broker_dealer_mpid
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' || t.broker_dealer_mpid,
                         --coalesce(fcn.crd_number||':','')||t.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
                 when t.is_broker_dealer = 'Y' and
                      (
                          t.fix_comp_id in
                          ('TRAFIXP2', 'TRAFIXP3', 'TRAFIXCP', 'TRAFIXB1', 'TRAFIXWBINT', 'TRFWBUL', 'TRFWBULL',
                           'TRAFIXCROSS', 'DASTRP') or t.trading_firm_id in ('limebroke', 'OFP0040')
                          --or
                          --(fc.fix_comp_id in ('REDIMBK1INT','REDIOPTMB1INT') and t.trading_firm_id = 'triadsc01')
                          ) then
                     --coalesce((select crd_number from compliance.crd_number_list where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y'))||':','') ||coalesce(fxm.tag_115,'')
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = fxm.tag_115
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' ||
                              fxm.tag_115,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
          --STERLP3
                 when t.is_broker_dealer = 'Y' and t.fix_comp_id in ('STERLP3', 'DASTRP') then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = fxm.tag_109
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' ||
                              fxm.tag_109,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
                 else coalesce(coalesce(t.cat_crd || ':', '') || t.cat_imid, '')--coalesce(coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
          end                                                                                          as imid
           , case
                 when t.fix_comp_id in ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTPA', 'TESTOFP')
                     then ''
                 when t.is_broker_dealer = 'Y' then 'F'
                 else ''
          end                                                                                          as sender_type
           , case
                 when t.ex_destination = 'LIQPT' then 'ATS'
                 else 'A'
          end                                                                                          as dept_type
           , t.alternative_compliance_id                                                               as catid                 -- 6376
           , t.compliance_id                                                                           as parent_catid          --376
           , fxm.tag_115                                                                               as on_behalf_of_comp_id
           , t.sub_strategy_desc                                                                       as sub_strategy
           , t.exec_instruction                                                                        as exec_instruction
           , fxm.tag_389                                                                               as discretion_offset
           , ''::varchar                                                                               as last_mkt              --  ???????????? status ls.last_mkt
           , case
                 when t.instrument_type_id = 'E'
                     then compliance.get_eq_sor_trading_session(t.order_id, t.create_date_id)
                 when fxm.tag_9281 in ('A', 'D', 'G') or fxm.tag_22017 = 'A' then 'ALL'
                 when fxm.tag_9281 in ('F', 'C') or fxm.tag_22017 = 'B' then 'REGPOST'
                 else 'REG'
          end                                                                                          as trading_session_id
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') in ('NONE','DFIN') -- non-B/D
                     and t.sub_strategy_desc = 'DMA' then 'Y'
                 else ''::varchar
          end                                                                                          as is_directed
           , case
                 when t.is_broker_dealer = 'Y' --coalesce(t.cat_imid,'NONE') not in ('NONE','DFIN') -- B/D
                     and t.sub_strategy_desc = 'DMA' then 'Y'
                 else ''::varchar
          end                                                                                          as routed_as_received
           , case when t.cross_order_id is not null then 'Y' else ''::varchar end                      as is_idx
           , t.client_order_id                                                                         as out_cl_ord_id

      from t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord t
               left join lateral
          (select j.fix_message,
                  j.fix_message ->> '9281'  as tag_9281,
                  j.fix_message ->> '22017' as tag_22017,
                  j.fix_message ->> '432'   as tag_432, -- expire date
                  j.fix_message ->> '423'   as tag_423,
                  j.fix_message ->> '126'   as tag_126, -- expire time
                  j.fix_message ->> '109'   as tag_109, -- user
                  j.fix_message ->> '115'   as tag_115, -- order_on_behalf_of_comp_id
                  j.fix_message ->> '389'   as tag_389
           from fix_capture.fix_message_json j
           where j.fix_message_id = t.fix_message_id
             and j.date_id = 20260106 --in_date_id
           limit 1
          ) fxm on true
               left join lateral
          (
          select ls.order_id, ls.order_status, ls.filled_qty, ls.last_mkt
          from t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status ls
          where ls.order_id = t.order_id
          limit 1
          ) ls on true


  )
  , ord_par_ir as
  ( -- there is internal route
      select case
                 when t.trading_firm_id = 'ctctrad01' then
                     replace(t.client_order_id, '|', '-') || '_' || t.fix_comp_id
                 when t.sub_strategy_desc = 'VEGA'
                     then replace(t.client_order_id, '|', '-') || '_' || coalesce(t.co_client_leg_ref_id, '0')
                 when t.ex_destination = 'LIQPT' then t.client_order_id || '_' || t.side::varchar
                 else replace(t.client_order_id, '|', '-')
          end                                                                                          as orderID
           , 'Internal Route'                                                                          as event_type
           , to_char(t.process_time, 'YYYYMMDD')                                                       as event_date
           , to_char(t.process_time, 'HH24:MI:SS.US')                                                  as event_time
           , ''::varchar                                                                               as orig_cl_ord_id        -- need for modification and cancel
           , coalesce(t.order_qty, 0)                                                                  as event_qty
           , case
                 when t.order_type_id in ('2', '4') then to_char((coalesce(t.price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as event_price
           , case when t.multileg_reporting_type = '2' then 'Y' else 'N' end                           as multi_leg_indicator
           , t.ml_no_legs                                                                              as number_of_legs
           , t.co_client_leg_ref_id                                                                    as leg_order_id
           , t.ratio_qty::varchar                                                                      as leg_ratio
           , ls.order_status_description                                                               as order_status          --  ???????????? status
           , t.opra_symbol                                                                             as osi_symbol
           , t.symbol                                                                                  as base_symbol
           , t.symbol || coalesce(' ' || t.symbol_suffix, '')                                          as symbol
           , t.instrument_type_id                                                                      as security_type         -- missed in EOS
           , t.underlying_symbol                                                                       as underlying_symbol
           , case t.put_call
                 when '0' then 'P'
                 when '1' then 'C'
                 else 'S'
          end                                                                                          as put_call_stock
           , to_char(t.last_trade_date, 'YYYYMMDD')                                                    as expiration_date
           , case
                 when t.side in ('1', '3') then 'B'
                 when t.instrument_type_id = 'O' and t.side not in ('1', '3') then 'S'
                 when t.side = '2' then 'SL'
                 when t.side = '5' then 'SS'
                 when t.side = '6' then 'SX'
                 else 'B'
          end                                                                                          as side
           , case
                 when t.tif_short_name in ('GTC', 'IOC') then t.tif_short_name
                 when t.tif_short_name = 'GTX' then 'GTX=' || to_char(t.process_time, 'YYYYMMDD')
                 when t.tif_short_name = 'GTD' then 'GTD=' || coalesce(to_char(t.expire_time, 'YYYYMMDD'), fxm.tag_432,
                                                                       to_char(t.process_time, 'YYYYMMDD'))
                 when t.time_in_force_id in ('C', 'M') then 'GTC'
                 else 'DAY=' || to_char(t.process_time, 'YYYYMMDD')
          end                                                                                          as tif
           , coalesce(to_char(t.expire_time, 'YYYYMMDD'), left(coalesce(fxm.tag_126, fxm.tag_432), 8)) as good_till_date
           , to_char(coalesce(t.expire_time, (to_timestamp((coalesce(fxm.tag_126, fxm.tag_432))::text,
                                                           'YYYYMMDD HH24:MI:SS.US')::timestamp at time zone 'UTC')),
                     'HH24:MI:SS.US')::varchar                                                         as good_till_time
           , ls.filled_qty::varchar                                                                    as filled_qty            --  ???????????? status
           , case
                 when t.order_type_id in ('2', '4') and fxm.tag_423 = '0' then 'CAB'
                 when t.order_type_id in ('2', '4') then 'LMT'
                 else 'MKT'
          end                                                                                          as order_type
           , case
                 when t.time_in_force_id = '7' and t.order_type_id = '2' then 'LOC'
                 when t.time_in_force_id = '7' and t.order_type_id = '1' then 'MOC'
                 when t.time_in_force_id = '2' and t.order_type_id = '2' then 'LOO'
                 when t.time_in_force_id = '2' and t.order_type_id = '1' then 'MOO'
          end                                                                                          as limit_market_type
           , case
                 when t.order_type_id in ('2') then to_char((coalesce(t.price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as order_price
           , to_char(t.create_time, 'YYYYMMDD')::varchar                                               as order_creation_date
           , to_char(t.create_time, 'HH24:MI:SS.MS')::varchar                                          as order_creation_time
           , case t.open_close
                 when 'C' then 'Close'
                 when 'O' then 'Open'
                 else ''
          end                                                                                          as open_close
           , (case when t.max_floor > 0 then 'Y' else '' end)::varchar                                 as is_reserve_size_order ---- ?????????????
           , case
                 when t.cross_order_id is not null
                     then 'Y'
                 else 'N'
          end::varchar                                                                                 as is_cross
           , 'False'::varchar                                                                          as is_manual
           , (case when fxm.tag_389 is not null then 'Y' else '' end)::varchar                         as with_discretion_price ---- ?????????????
           , to_char(t.algo_start_time, 'YYYYMMDD HH24:MI:SS.MS')                                      as trigger_time_of_managed_order
           , (case
                  when t.instrument_type_id = 'E' and t.exec_instruction ~ '(f)' then 'Y'::varchar
                  else ''::varchar end)::varchar                                                       as iso_flag
           , null::varchar                                                                             as representative_order  ---- ?????????????
           , case
                 when t.order_type_id in ('3', '4') then to_char((coalesce(t.stop_price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as stop_price
           , t.max_floor::varchar                                                                      as max_floor
           , case when t.max_floor > 0 then t.max_floor::varchar end                                   as display_quantity
           , coalesce(t.customer_or_firm_id, /*t.order_capacity_id ,*/ t.eq_order_capacity)            as capacity
--       , coalesce(t.customer_or_firm_id , t.order_capacity_id , t.eq_order_capacity) as capacity
           , fxm.tag_109                                                                               as user_
           , t.account_name                                                                            as account_name
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
                     then t.account_id::varchar
          end                                                                                          as fdid
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
                     then coalesce(t.account_holder_type, 'A')
          end                                                                                          as account_holder_type
           , case
                 when t.fix_comp_id in ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTPA', 'TESTOFP',
                     --GTH
                                        'TESTGTHLB1', 'TESTGTHDASH') then '' --'BLAZE7PROD2' removed
          --cowen01
                 when t.trading_firm_id in
                      ('cowen01', 'cuttone', 'etcinc01', 'monrchccm', 'jscap', 'LPTF259', 'greatpnt', 'triadsc01',
                       'merrill01', 'wedbush', 'EFP0009', 'OFP0042', 'veloclear', 'volantats',
                       'OFP0045', 'OFP0016', 'wain01', 'OFP0032') and coalesce(t.cat_report_on_behalf_of, 'N') = 'N'
                     then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = t.broker_dealer_mpid
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' || t.broker_dealer_mpid,
                              t.crd_number || ':' || t.broker_dealer_mpid,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --precision
                 when t.trading_firm_id in ('precision') and t.fix_comp_id in ('SILEXXP') and
                      coalesce(t.cat_report_on_behalf_of, 'N') = 'N' then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = t.broker_dealer_mpid
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' || t.broker_dealer_mpid,
                         --coalesce(fcn.crd_number||':','')||t.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
                 when t.is_broker_dealer = 'Y' and
                      (
                          t.fix_comp_id in
                          ('TRAFIXP2', 'TRAFIXP3', 'TRAFIXCP', 'TRAFIXB1', 'TRAFIXWBINT', 'TRFWBUL', 'TRFWBULL',
                           'TRAFIXCROSS', 'DASTRP') or t.trading_firm_id in ('limebroke', 'OFP0040')
                          --or
                          --(fc.fix_comp_id in ('REDIMBK1INT','REDIOPTMB1INT') and t.trading_firm_id = 'triadsc01')
                          ) then
                     --coalesce((select crd_number from compliance.crd_number_list where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y'))||':','') ||coalesce(fxm.tag_115,'')
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y')) || ':' ||
                              fxm.tag_115,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
          --STERLP3
                 when t.is_broker_dealer = 'Y' and t.fix_comp_id in ('STERLP3', 'DASTRP') then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = fxm.tag_109 and (crd_amount = 1 or is_default = 'Y')) || ':' ||
                              fxm.tag_109,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
                 else coalesce(coalesce(t.cat_crd || ':', '') || t.cat_imid, '')--coalesce(coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
          end                                                                                          as imid
           , case
                 when t.fix_comp_id in ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTPA', 'TESTOFP')
                     then ''
                 when t.is_broker_dealer = 'Y' then 'F'
                 else ''
          end                                                                                          as sender_type
           , case
                 when t.ex_destination = 'LIQPT' then 'ATS'
                 else 'A'
          end                                                                                          as dept_type
           , t.alternative_compliance_id                                                               as catid                 -- 6376
           , t.compliance_id                                                                           as parent_catid          --376
           , fxm.tag_115                                                                               as on_behalf_of_comp_id
           , t.sub_strategy_desc                                                                       as sub_strategy
           , t.exec_instruction                                                                        as exec_instruction
           , fxm.tag_389                                                                               as discretion_offset
           , ''::varchar                                                                               as last_mkt              --  ???????????? status ls.last_mkt
           , case
                 when t.instrument_type_id = 'E'
                     then compliance.get_eq_sor_trading_session(t.order_id, t.create_date_id)
                 when fxm.tag_9281 in ('A', 'D', 'G') or fxm.tag_22017 = 'A' then 'ALL'
                 when fxm.tag_9281 in ('F', 'C') or fxm.tag_22017 = 'B' then 'REGPOST'
                 else 'REG'
          end                                                                                          as trading_session_id
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') in ('NONE','DFIN') -- non-B/D
                     and t.sub_strategy_desc = 'DMA' then 'Y'
                 else ''::varchar
          end                                                                                          as is_directed
           , case
                 when t.is_broker_dealer = 'Y' --coalesce(t.cat_imid,'NONE') not in ('NONE','DFIN') -- B/D
                     and t.sub_strategy_desc = 'DMA' then 'Y'
                 else ''::varchar
          end                                                                                          as routed_as_received
           , case when t.cross_order_id is not null then 'Y' else ''::varchar end                      as is_idx
           , t.client_order_id                                                                         as out_cl_ord_id
      from t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord t
               left join lateral
          (select j.fix_message,
                  j.fix_message ->> '9281'  as tag_9281,
                  j.fix_message ->> '22017' as tag_22017,
                  j.fix_message ->> '432'   as tag_432, -- expire date
                  j.fix_message ->> '423'   as tag_423,
                  j.fix_message ->> '126'   as tag_126, -- expire time
                  j.fix_message ->> '109'   as tag_109, -- user
                  j.fix_message ->> '115'   as tag_115, -- order_on_behalf_of_comp_id
                  j.fix_message ->> '389'   as tag_389
           from fix_capture.fix_message_json j
           where j.fix_message_id = t.fix_message_id
             and j.date_id = 20260106 --in_date_id
           limit 1
          ) fxm on true
               left join lateral
          (
          select ls.order_id, ls.order_status, dos.order_status_description, ls.filled_qty, ls.last_mkt
          from t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status ls
                   left join dwh.d_order_status dos
                             on ls.order_status = dos.order_status and dos.is_active
          where ls.order_id = t.order_id
          limit 1
          ) ls on true
      where 1 = 1
        and t.trans_type = 'D'                                            -- new or acceptance, not modify
        and (coalesce(t.cat_imid, 'NONE') = 'DFIN' -- internal route
          or
             t.fix_comp_id in ('IRCHNY2EQPT1INT', 'IRCHNY2EQPT2INT', 'IRCHNY2EQPT3INT',
                               'IRCHNY2OPTPT1INT') -- internal route. hope there are none of this
          )
        and t.fix_comp_id not in
            ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB4', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTOFPLB2', 'TESTOFPLB3',
             'TESTPA', 'TESTOFP', 'TESTGTHLB1')
        and coalesce(t.tf_cat_suppress, 'N') <> 'Y'
        and coalesce(t.ac_cat_suppress, 'N') <> 'Y'
        and t.is_high_frequency_trader = 'N'                              -- non-EOS
        and (coalesce(t.cpar_cnt, 0) = 0 -- LP to C1PAR collaption
          or
             t.fix_comp_id not in
             ('LPEQP', 'LPOPTP', 'LQPNCP', 'LPOFP', 'LPOFP2', 'LPOPTB', 'LPOPTSTP', 'LPEQSTP', 'LQPNCP5INT',
              'LQPNCPINT',
                 --GTH
              'LPEQPGTH', 'LPOPTPGTH', 'LPCROSSGTHINT', 'DASHOPTP')
          )
        and (t.ex_destination <> 'LIQPT' or coalesce(t.cross_cnt, 0) > 0) -- non-empty LPO responses
        --
        --and (t.trading_firm_id not in ('BMO','dynamex01','Guggen','nbcanf') or t.fix_comp_id not in ('BOOKP','BOOKP2')) --???
        --
        --and t.ex_destination not in ('RPTR','SQHT','WEEDN','JSEB','TRAFX','FBMS','CTDH','DASH','OUTCR','SLXX','BLAZE')
        --and (t.ex_destination not in ('BRKPT','BLAZE') or t.account_name in ('TASTYSPX','TDSPX_BP')) --??? suppressed in MOOC
        and t.ex_destination not in ('RPTR', 'BRKPT', 'SLXX', 'BLAZE')
--       and t.symbol in ('PRGO')
      --and t.tif_short_name = 'GTD'
      --and t.time_in_force_id in ('2','7')
      --and t.exec_instruction is not null
  )
  , ord_par_modify as
  ( -- there is internal route
      select case
                 when t.trading_firm_id = 'ctctrad01' then
                     replace(t.client_order_id, '|', '-') || '_' || t.fix_comp_id
                 when t.sub_strategy_desc = 'VEGA'
                     then replace(t.client_order_id, '|', '-') || '_' || coalesce(t.co_client_leg_ref_id, '0')
                 when t.ex_destination = 'LIQPT' then t.client_order_id || '_' || t.side::varchar
                 else replace(t.client_order_id, '|', '-')
          end                                                                                          as orderID
           , 'Order Modify'                                                                            as event_type
           , to_char(t.process_time, 'YYYYMMDD')                                                       as event_date
           , to_char(t.process_time, 'HH24:MI:SS.US')                                                  as event_time
           , case
                 when t.trading_firm_id = 'ctctrad01' then
                     replace(orig.client_order_id, '|', '-') || '_' || t.fix_comp_id
                 when t.sub_strategy_desc = 'VEGA'
                     then replace(orig.client_order_id, '|', '-') || '_' || coalesce(orig.co_client_leg_ref_id, '0')
                 when t.ex_destination = 'LIQPT' then orig.client_order_id || '_' || orig.side::varchar
                 else replace(orig.client_order_id, '|', '-')
          end                                                                                          as orig_cl_ord_id        -- need for modification and cancel
           , coalesce(t.order_qty, 0)                                                                  as event_qty
           , case
                 when t.order_type_id in ('2', '4') then to_char((coalesce(t.price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as event_price
           , case when t.multileg_reporting_type = '2' then 'Y' else 'N' end                           as multi_leg_indicator
           , t.ml_no_legs                                                                              as number_of_legs
           , t.co_client_leg_ref_id                                                                    as leg_order_id
           , t.ratio_qty::varchar                                                                      as leg_ratio
           , ls.order_status_description                                                               as order_status          --  ???????????? status
           , t.opra_symbol                                                                             as osi_symbol
           , t.symbol                                                                                  as base_symbol
           , t.symbol || coalesce(' ' || t.symbol_suffix, '')                                          as symbol
           , t.instrument_type_id                                                                      as security_type         -- missed in EOS
           , t.underlying_symbol                                                                       as underlying_symbol
           , case t.put_call
                 when '0' then 'P'
                 when '1' then 'C'
                 else 'S'
          end                                                                                          as put_call_stock
           , to_char(t.last_trade_date, 'YYYYMMDD')                                                    as expiration_date
           , case
                 when t.side in ('1', '3') then 'B'
                 when t.instrument_type_id = 'O' and t.side not in ('1', '3') then 'S'
                 when t.side = '2' then 'SL'
                 when t.side = '5' then 'SS'
                 when t.side = '6' then 'SX'
                 else 'B'
          end                                                                                          as side
           , case
                 when t.tif_short_name in ('GTC', 'IOC') then t.tif_short_name
                 when t.tif_short_name = 'GTX' then 'GTX=' || to_char(t.process_time, 'YYYYMMDD')
                 when t.tif_short_name = 'GTD' then 'GTD=' || coalesce(to_char(t.expire_time, 'YYYYMMDD'), fxm.tag_432,
                                                                       to_char(t.process_time, 'YYYYMMDD'))
                 when t.time_in_force_id in ('C', 'M') then 'GTC'
                 else 'DAY=' || to_char(t.process_time, 'YYYYMMDD')
          end                                                                                          as tif
           , coalesce(to_char(t.expire_time, 'YYYYMMDD'), left(coalesce(fxm.tag_126, fxm.tag_432), 8)) as good_till_date
           , to_char(coalesce(t.expire_time, (to_timestamp((coalesce(fxm.tag_126, fxm.tag_432))::text,
                                                           'YYYYMMDD HH24:MI:SS.US')::timestamp at time zone 'UTC')),
                     'HH24:MI:SS.US')::varchar                                                         as good_till_time
           , ls.filled_qty::varchar                                                                    as filled_qty            --  ???????????? status
           , case
                 when t.order_type_id in ('2', '4') and fxm.tag_423 = '0' then 'CAB'
                 when t.order_type_id in ('2', '4') then 'LMT'
                 else 'MKT'
          end                                                                                          as order_type
           , case
                 when t.time_in_force_id = '7' and t.order_type_id = '2' then 'LOC'
                 when t.time_in_force_id = '7' and t.order_type_id = '1' then 'MOC'
                 when t.time_in_force_id = '2' and t.order_type_id = '2' then 'LOO'
                 when t.time_in_force_id = '2' and t.order_type_id = '1' then 'MOO'
          end                                                                                          as limit_market_type
           , case
                 when t.order_type_id in ('2') then to_char((coalesce(t.price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as order_price
           , to_char(t.create_time, 'YYYYMMDD')::varchar                                               as order_creation_date
           , to_char(t.create_time, 'HH24:MI:SS.MS')::varchar                                          as order_creation_time
           , case t.open_close
                 when 'C' then 'Close'
                 when 'O' then 'Open'
                 else ''
          end                                                                                          as open_close
           , (case when t.max_floor > 0 then 'Y' else '' end)::varchar                                 as is_reserve_size_order ---- ?????????????
           , case
                 when t.cross_order_id is not null
                     then 'Y'
                 else 'N'
          end::varchar                                                                                 as is_cross
           , 'False'::varchar                                                                          as is_manual
           , (case when fxm.tag_389 is not null then 'Y' else '' end)::varchar                         as with_discretion_price ---- ?????????????
           , to_char(t.algo_start_time, 'YYYYMMDD HH24:MI:SS.MS')                                      as trigger_time_of_managed_order
           , (case
                  when t.instrument_type_id = 'E' and t.exec_instruction ~ '(f)' then 'Y'::varchar
                  else ''::varchar end)::varchar                                                       as iso_flag
           , null::varchar                                                                             as representative_order  ---- ?????????????
           , case
                 when t.order_type_id in ('3', '4') then to_char((coalesce(t.stop_price, 0)), 'FM9999999990.09999999')
                 else ''
          end                                                                                          as stop_price
           , t.max_floor::varchar                                                                      as max_floor
           , case when t.max_floor > 0 then t.max_floor::varchar end                                   as display_quantity
           , coalesce(t.customer_or_firm_id, /*t.order_capacity_id ,*/ t.eq_order_capacity)            as capacity
--       , coalesce(t.customer_or_firm_id , t.order_capacity_id , t.eq_order_capacity) as capacity
           , fxm.tag_109                                                                               as user_
           , t.account_name                                                                            as account_name
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
                     then t.account_id::varchar
          end                                                                                          as fdid
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
                     then coalesce(t.account_holder_type, 'A')
          end                                                                                          as account_holder_type
           , case
                 when t.fix_comp_id in ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTPA', 'TESTOFP',
                     --GTH
                                        'TESTGTHLB1', 'TESTGTHDASH') then '' --'BLAZE7PROD2' removed
          --cowen01
                 when t.trading_firm_id in
                      ('cowen01', 'cuttone', 'etcinc01', 'monrchccm', 'jscap', 'LPTF259', 'greatpnt', 'triadsc01',
                       'merrill01', 'wedbush', 'EFP0009', 'OFP0042', 'veloclear', 'volantats',
                       'OFP0045', 'OFP0016', 'wain01', 'OFP0032') and coalesce(t.cat_report_on_behalf_of, 'N') = 'N'
                     then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = t.broker_dealer_mpid
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' || t.broker_dealer_mpid,
                              t.crd_number || ':' || t.broker_dealer_mpid,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --precision
                 when t.trading_firm_id in ('precision') and t.fix_comp_id in ('SILEXXP') and
                      coalesce(t.cat_report_on_behalf_of, 'N') = 'N' then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = t.broker_dealer_mpid
                                 and (crd_amount = 1 or is_default = 'Y')) || ':' || t.broker_dealer_mpid,
                         --coalesce(fcn.crd_number||':','')||t.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
                 when t.is_broker_dealer = 'Y' and
                      (
                          t.fix_comp_id in
                          ('TRAFIXP2', 'TRAFIXP3', 'TRAFIXCP', 'TRAFIXB1', 'TRAFIXWBINT', 'TRFWBUL', 'TRFWBULL',
                           'TRAFIXCROSS', 'DASTRP') or t.trading_firm_id in ('limebroke', 'OFP0040')
                          --or
                          --(fc.fix_comp_id in ('REDIMBK1INT','REDIOPTMB1INT') and t.trading_firm_id = 'triadsc01')
                          ) then
                     --coalesce((select crd_number from compliance.crd_number_list where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y'))||':','') ||coalesce(fxm.tag_115,'')
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y')) || ':' ||
                              fxm.tag_115,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
          --STERLP3
                 when t.is_broker_dealer = 'Y' and t.fix_comp_id in ('STERLP3', 'DASTRP') then
                     coalesce((select crd_number
                               from compliance.crd_number_list
                               where cat_imid = fxm.tag_109 and (crd_amount = 1 or is_default = 'Y')) || ':' ||
                              fxm.tag_109,
                         --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                              coalesce(t.cat_crd || ':', '') || t.cat_imid, '')
          --
                 else coalesce(coalesce(t.cat_crd || ':', '') || t.cat_imid, '')--coalesce(coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
          end                                                                                          as imid
           , case
                 when t.fix_comp_id in ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTPA', 'TESTOFP')
                     then ''
                 when t.is_broker_dealer = 'Y' then 'F'
                 else ''
          end                                                                                          as sender_type
           , case
                 when t.ex_destination = 'LIQPT' then 'ATS'
                 else 'A'
          end                                                                                          as dept_type
           , t.alternative_compliance_id                                                               as catid                 -- 6376
           , t.compliance_id                                                                           as parent_catid          --376
           , fxm.tag_115                                                                               as on_behalf_of_comp_id
           , t.sub_strategy_desc                                                                       as sub_strategy
           , t.exec_instruction                                                                        as exec_instruction
           , fxm.tag_389                                                                               as discretion_offset
           , ''::varchar                                                                               as last_mkt              --  ???????????? status ls.last_mkt
           , case
                 when t.instrument_type_id = 'E'
                     then compliance.get_eq_sor_trading_session(t.order_id, t.create_date_id)
                 when fxm.tag_9281 in ('A', 'D', 'G') or fxm.tag_22017 = 'A' then 'ALL'
                 when fxm.tag_9281 in ('F', 'C') or fxm.tag_22017 = 'B' then 'REGPOST'
                 else 'REG'
          end                                                                                          as trading_session_id
           , case
                 when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') in ('NONE','DFIN') -- non-B/D
                     and t.sub_strategy_desc = 'DMA' then 'Y'
                 else ''::varchar
          end                                                                                          as is_directed
           , case
                 when t.is_broker_dealer = 'Y' --coalesce(t.cat_imid,'NONE') not in ('NONE','DFIN') -- B/D
                     and t.sub_strategy_desc = 'DMA' then 'Y'
                 else ''::varchar
          end                                                                                          as routed_as_received
           , (t.order_qty - ls.max_cum_qty)::varchar                                                   as leaves_qty
           , case when t.cross_order_id is not null then 'Y' else ''::varchar end                      as is_idx
           , (compliance.get_sor_first_orig(in_order_id => t.order_id, in_date_id => t.create_date_id)).out_cl_ord_id
      from t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord t
               left join lateral
          (
          select orig.co_client_leg_ref_id
               , orig.client_order_id
               , orig.side
          from client_order orig
          where orig.order_id = t.orig_order_id
            and orig.create_date_id > 20230717
            and (orig.create_date_id = 20260106 or orig.time_in_force_id in ('1', '6'))
            and orig.parent_order_id is null
          ) orig on true
               left join lateral
          (select j.fix_message,
                  j.fix_message ->> '9281'  as tag_9281,
                  j.fix_message ->> '22017' as tag_22017,
                  j.fix_message ->> '432'   as tag_432, -- expire date
                  j.fix_message ->> '423'   as tag_423,
                  j.fix_message ->> '126'   as tag_126, -- expire time
                  j.fix_message ->> '109'   as tag_109, -- user
                  j.fix_message ->> '115'   as tag_115, -- order_on_behalf_of_comp_id
                  j.fix_message ->> '389'   as tag_389
           from fix_capture.fix_message_json j
           where j.fix_message_id = t.fix_message_id
             and j.date_id = 20260106 --in_date_id
           limit 1
          ) fxm on true
               left join lateral
          (
          select ls.order_id, ls.order_status, dos.order_status_description, ls.filled_qty, ls.last_mkt, ls.max_cum_qty
          from t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status ls
                   left join dwh.d_order_status dos
                             on ls.order_status = dos.order_status and dos.is_active
          where ls.order_id = t.order_id
          limit 1
          ) ls on true
      where 1 = 1
        and t.trans_type = 'G'
        and (coalesce(t.cat_imid, 'NONE') <> 'DFIN' -- non-internal route
          or
             t.fix_comp_id in
             ('TESTFASTLB1', 'TESTFASTLB3', 'TESTFASTLB4', 'TESTFASTLB5', 'TESTOFPLB1', 'TESTOFPLB2', 'TESTOFPLB3',
              'TESTPA', 'TESTOFP') --'BLAZE7PROD2' removed
          )
        and t.fix_comp_id not in
            ('IRCHNY2EQPT1INT', 'IRCHNY2EQPT2INT', 'IRCHNY2EQPT3INT', 'IRCHNY2OPTPT1INT') -- non-internal route
        --
        --and t.ex_destination not in ('RPTR','SQHT','WEEDN','JSEB','TRAFX','FBMS','CTDH','DASH','OUTCR','SLXX','BLAZE')
        --and (t.ex_destination not in ('BRKPT','BLAZE') or t.account_name in ('TASTYSPX','TDSPX_BP'))
        and t.ex_destination not in ('RPTR', 'BRKPT', 'SLXX', 'BLAZE')
        --
        and coalesce(t.tf_cat_suppress, 'N') <> 'Y'
        and coalesce(t.ac_cat_suppress, 'N') <> 'Y'
        and t.is_high_frequency_trader = 'N'                                              -- non-EOS
        and (coalesce(t.cpar_cnt, 0) = 0 -- LP to C1PAR collaption
          or
             t.fix_comp_id not in
             ('LPEQP', 'LPOPTP', 'LQPNCP', 'LPOFP', 'LPOFP2', 'LPOPTB', 'LPOPTSTP', 'LPEQSTP', 'LQPNCP5INT',
              'LQPNCPINT',
                 --GTH
              'LPEQPGTH', 'LPOPTPGTH', 'LPCROSSGTHINT', 'DASHOPTP')
          )
        and (t.ex_destination <> 'LIQPT' or coalesce(t.cross_cnt, 0) > 0) -- non-empty LPO responses
      --
      --and (t.trading_firm_id not in ('BMO','dynamex01','Guggen','nbcanf') or t.fix_comp_id not in ('BOOKP','BOOKP2')) --???
      --
--       and t.symbol in ('PRGO')
      --and t.tif_short_name = 'GTD'
      --and t.time_in_force_id in ('2','7')
      --and t.exec_instruction is not null
  )
  , ord_par_ir_modify as
  ( -- there are no internal route modify
    select
        case
          when t.trading_firm_id = 'ctctrad01' then
            replace(t.client_order_id,'|','-')||'_'||t.fix_comp_id
          when t.sub_strategy_desc = 'VEGA'
            then replace(t.client_order_id,'|','-')||'_'||coalesce(t.co_client_leg_ref_id,'0')
          when t.ex_destination = 'LIQPT' then t.client_order_id||'_'||t.side::varchar
          else replace(t.client_order_id,'|','-')
        end as orderID
      , 'Internal Route Modify' as event_type
      , to_char(t.process_time,'YYYYMMDD') as event_date
      , to_char(t.process_time,'HH24:MI:SS.US') as event_time
      , case
          when t.trading_firm_id = 'ctctrad01' then
            replace(orig.client_order_id,'|','-')||'_'||t.fix_comp_id
          when t.sub_strategy_desc = 'VEGA'
            then replace(orig.client_order_id,'|','-')||'_'||coalesce(orig.co_client_leg_ref_id,'0')
          when t.ex_destination = 'LIQPT' then orig.client_order_id||'_'||orig.side::varchar
          else replace(orig.client_order_id,'|','-')
        end as orig_cl_ord_id -- need for modification and cancel
      , coalesce(t.order_qty,0) as event_qty
      , case
            when t.order_type_id in ('2','4') then to_char((coalesce(t.price,0)), 'FM9999999990.09999999')
          else ''
        end as event_price
      , case when t.multileg_reporting_type = '2' then 'Y' else 'N' end as multi_leg_indicator
      , t.ml_no_legs as number_of_legs
      , t.co_client_leg_ref_id as leg_order_id
      , t.ratio_qty::varchar as leg_ratio
      , ls.order_status_description as order_status   --  ???????????? status
      , t.opra_symbol as osi_symbol
      , t.symbol as base_symbol
      , t.symbol||coalesce(' '||t.symbol_suffix,'') as symbol
      , t.instrument_type_id as security_type                                           -- missed in EOS
      , t.underlying_symbol as underlying_symbol
      , case t.put_call
          when '0' then 'P'
          when '1' then 'C'
          else 'S'
        end as put_call_stock
      , to_char(t.last_trade_date, 'YYYYMMDD') as expiration_date
      , case
          when t.side in ('1','3') then 'B'
          when t.instrument_type_id = 'O' and t.side not in ('1','3') then 'S'
          when t.side = '2' then 'SL'
          when t.side = '5' then 'SS'
          when t.side = '6' then 'SX'
          else 'B'
        end as side
      , case
          when t.tif_short_name in ('GTC','IOC') then t.tif_short_name
          when t.tif_short_name = 'GTX' then 'GTX='||to_char(t.process_time,'YYYYMMDD')
          when t.tif_short_name = 'GTD' then 'GTD='||coalesce(to_char(t.expire_time,'YYYYMMDD'), fxm.tag_432, to_char(t.process_time,'YYYYMMDD'))
          when t.time_in_force_id in ('C','M') then 'GTC'
          else 'DAY='||to_char(t.process_time,'YYYYMMDD')
        end as tif
      , coalesce(to_char(t.expire_time,'YYYYMMDD'), left(coalesce(fxm.tag_126, fxm.tag_432), 8)) as good_till_date
      , to_char(coalesce(t.expire_time, (to_timestamp((coalesce(fxm.tag_126, fxm.tag_432))::text, 'YYYYMMDD HH24:MI:SS.US')::timestamp at time zone 'UTC')), 'HH24:MI:SS.US')::varchar as good_till_time
      , ls.filled_qty::varchar as filled_qty      --  ???????????? status
      , case
            when t.order_type_id in ('2','4') and fxm.tag_423 = '0' then 'CAB'
            when t.order_type_id in ('2','4') then 'LMT'
          else 'MKT'
        end as order_type
      , case
          when t.time_in_force_id = '7' and t.order_type_id = '2' then 'LOC'
          when t.time_in_force_id = '7' and t.order_type_id = '1' then 'MOC'
          when t.time_in_force_id = '2' and t.order_type_id = '2' then 'LOO'
          when t.time_in_force_id = '2' and t.order_type_id = '1' then 'MOO'
        end as limit_market_type
      , case
            when t.order_type_id in ('2') then to_char((coalesce(t.price,0)), 'FM9999999990.09999999')
          else ''
        end as order_price
      , to_char(t.create_time, 'YYYYMMDD')::varchar as order_creation_date
      , to_char(t.create_time, 'HH24:MI:SS.MS')::varchar as order_creation_time
      , case t.open_close
          when 'C' then 'Close'
          when 'O' then 'Open'
          else ''
        end as open_close
      , (case when t.max_floor > 0 then 'Y' else '' end)::varchar as is_reserve_size_order  ---- ?????????????
      , case
          when t.cross_order_id is not null
            then 'Y'
          else 'N'
        end::varchar as is_cross
      , 'False'::varchar as is_manual
      , (case when fxm.tag_389 is not null then 'Y' else '' end)::varchar as with_discretion_price   ---- ?????????????
      , to_char(t.algo_start_time,'YYYYMMDD HH24:MI:SS.MS') as trigger_time_of_managed_order
      , (case when t.instrument_type_id = 'E' and t.exec_instruction ~ '(f)' then 'Y'::varchar else ''::varchar end)::varchar as iso_flag
      , null::varchar as representative_order   ---- ?????????????
      , case
            when t.order_type_id in ('3','4') then to_char((coalesce(t.stop_price,0)), 'FM9999999990.09999999')
          else ''
        end as stop_price
      , t.max_floor::varchar as max_floor
      , case when t.max_floor > 0 then t.max_floor::varchar end as display_quantity
      , coalesce(t.customer_or_firm_id , /*t.order_capacity_id ,*/ t.eq_order_capacity) as capacity
      , fxm.tag_109 as user_
      , t.account_name as account_name
      , case
          when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
            then t.account_id::varchar
        end as fdid
      , case
          when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') = 'NONE'
            then coalesce(t.account_holder_type,'A')
        end as account_holder_type
      , case
          when t.fix_comp_id in ('TESTFASTLB1','TESTFASTLB3','TESTFASTLB5','TESTOFPLB1','TESTPA','TESTOFP',
                      --GTH
                       'TESTGTHLB1','TESTGTHDASH') then '' --'BLAZE7PROD2' removed
          --cowen01
          when t.trading_firm_id in ('cowen01','cuttone','etcinc01','monrchccm','jscap','LPTF259','greatpnt','triadsc01','merrill01','wedbush','EFP0009','OFP0042','veloclear','volantats',
                        'OFP0045','OFP0016','wain01','OFP0032')  and coalesce(t.cat_report_on_behalf_of,'N') = 'N' then
            coalesce((select crd_number from compliance.crd_number_list where cat_imid = t.broker_dealer_mpid and (crd_amount = 1 or is_default = 'Y'))||':'||t.broker_dealer_mpid, t.crd_number||':'||t.broker_dealer_mpid,
                   --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                   coalesce(t.cat_crd||':','')||t.cat_imid,'')
          --precision
          when t.trading_firm_id in ('precision') and t.fix_comp_id in ('SILEXXP') and coalesce(t.cat_report_on_behalf_of,'N') = 'N' then
            coalesce((select crd_number from compliance.crd_number_list where cat_imid = t.broker_dealer_mpid and (crd_amount = 1 or is_default = 'Y'))||':'||t.broker_dealer_mpid,
                   --coalesce(fcn.crd_number||':','')||t.cat_imid,'')
                   coalesce(t.cat_crd||':','')||t.cat_imid,'')
          --
          when t.is_broker_dealer = 'Y' and
            (
              t.fix_comp_id in ('TRAFIXP2','TRAFIXP3','TRAFIXCP','TRAFIXB1','TRAFIXWBINT','TRFWBUL','TRFWBULL','TRAFIXCROSS','DASTRP')  or t.trading_firm_id in ('limebroke','OFP0040')
              --or
             --(fc.fix_comp_id in ('REDIMBK1INT','REDIOPTMB1INT') and t.trading_firm_id = 'triadsc01')
            ) then
            --coalesce((select crd_number from compliance.crd_number_list where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y'))||':','') ||coalesce(fxm.tag_115,'')
            coalesce((select crd_number from compliance.crd_number_list where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y'))||':'||fxm.tag_115,
                   --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                   coalesce(t.cat_crd||':','')||t.cat_imid,'')
            --
          --STERLP3
          when t.is_broker_dealer = 'Y' and t.fix_comp_id in ('STERLP3','DASTRP') then
            coalesce((select crd_number from compliance.crd_number_list where cat_imid = fxm.tag_109 and (crd_amount = 1 or is_default = 'Y'))||':'||fxm.tag_109,
                   --coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
                   coalesce(t.cat_crd||':','')||t.cat_imid,'')
          --
          else coalesce(coalesce(t.cat_crd||':','')||t.cat_imid,'')--coalesce(coalesce(fcn.crd_number||':','')||tf.cat_imid,'')
        end as imid
      , case
            when t.fix_comp_id in ('TESTFASTLB1','TESTFASTLB3','TESTFASTLB5','TESTOFPLB1','TESTPA','TESTOFP') then ''
          when t.is_broker_dealer = 'Y' then 'F'
          else ''
        end as sender_type
      , case
          when t.ex_destination = 'LIQPT' then 'ATS'
          else 'A'
        end as dept_type
      , t.alternative_compliance_id as catid  -- 6376
      , t.compliance_id as parent_catid --376
      , fxm.tag_115 as on_behalf_of_comp_id
      , t.sub_strategy_desc as sub_strategy
      , t.exec_instruction as exec_instruction
      , fxm.tag_389 as discretion_offset
      , ''::varchar as last_mkt --  ???????????? status ls.last_mkt
      , case
          when t.instrument_type_id = 'E' then compliance.get_eq_sor_trading_session(t.order_id, t.create_date_id)
          when fxm.tag_9281 in ('A','D','G') or fxm.tag_22017 = 'A' then 'ALL'
          when fxm.tag_9281 in ('F','C') or fxm.tag_22017 = 'B' then 'REGPOST'
          else 'REG'
        end as trading_session_id
      , case
          when t.is_broker_dealer = 'N' --coalesce(t.cat_imid,'NONE') in ('NONE','DFIN') -- non-B/D
            and t.sub_strategy_desc = 'DMA' then 'Y'
          else ''::varchar
        end as is_directed
      , case
          when t.is_broker_dealer = 'Y' --coalesce(t.cat_imid,'NONE') not in ('NONE','DFIN') -- B/D
            and t.sub_strategy_desc = 'DMA' then 'Y'
          else ''::varchar
        end as routed_as_received
      , (t.order_qty - ls.max_cum_qty)::varchar as leaves_qty
      , case when t.cross_order_id is not null then 'Y' else ''::varchar end as is_idx
      , (compliance.get_sor_first_orig(in_order_id => t.order_id, in_date_id => t.create_date_id)).out_cl_ord_id
    from t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_ord t
      left join lateral
        (
          select orig.co_client_leg_ref_id
            , orig.client_order_id
            , orig.side
          from client_order orig
          where orig.order_id = t.orig_order_id
            and orig.create_date_id > 20230717
            and (orig.create_date_id = 20260106 or orig.time_in_force_id in ('1','6'))
            and orig.parent_order_id is null
        ) orig on true
      left join lateral
            (select j.fix_message,
                j.fix_message->>'9281' as tag_9281,j.fix_message->>'22017' as tag_22017,
                j.fix_message->>'432' as tag_432,  -- expire date
                j.fix_message->>'423' as tag_423,
                j.fix_message->>'126' as tag_126,  -- expire time
                j.fix_message->>'109' as tag_109,  -- user
                j.fix_message->>'115' as tag_115,   -- order_on_behalf_of_comp_id
                j.fix_message->>'389' as tag_389
             from fix_capture.fix_message_json j
             where j.fix_message_id  = t.fix_message_id
             and j.date_id = 20260106 --in_date_id
             limit 1
            ) fxm on true
      left join lateral
        (
          select ls.order_id , ls.order_status, dos.order_status_description  , ls.filled_qty , ls.last_mkt, ls.max_cum_qty
          from t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status ls
            left join dwh.d_order_status dos
              on ls.order_status = dos.order_status and dos.is_active
          where ls.order_id = t.order_id
          limit 1
        ) ls on true
    where 1=1
      and t.trans_type = 'G'
      and (coalesce(t.cat_imid,'NONE') = 'DFIN' -- internal route
          or
          t.fix_comp_id in ('IRCHNY2EQPT1INT','IRCHNY2EQPT2INT','IRCHNY2EQPT3INT','IRCHNY2OPTPT1INT') -- internal route
        )
      and t.fix_comp_id not in ('TESTFASTLB1','TESTFASTLB3','TESTFASTLB4','TESTFASTLB5','TESTOFPLB1','TESTOFPLB2','TESTOFPLB3','TESTPA','TESTOFP') --'BLAZE7PROD2' removed
      --
      --and t.ex_destination not in ('RPTR','SQHT','WEEDN','JSEB','TRAFX','FBMS','CTDH','DASH','OUTCR','SLXX','BLAZE')
      --and (t.ex_destination not in ('BRKPT','BLAZE') or t.account_name in ('TASTYSPX','TDSPX_BP'))
      and t.ex_destination not in ('RPTR','BRKPT','SLXX','BLAZE')
      --
      and coalesce(t.tf_cat_suppress,'N') <> 'Y'
      and coalesce(t.ac_cat_suppress,'N') <> 'Y'
      and t.is_high_frequency_trader = 'N' -- non-EOS
      and (coalesce(t.cpar_cnt,0) = 0  -- LP to C1PAR collaption
           or
           t.fix_comp_id not in ('LPEQP','LPOPTP','LQPNCP','LPOFP','LPOFP2','LPOPTB','LPOPTSTP','LPEQSTP','LQPNCP5INT','LQPNCPINT',
                      --GTH
                      'LPEQPGTH','LPOPTPGTH','LPCROSSGTHINT','DASHOPTP')
          )
      and (t.ex_destination <> 'LIQPT' or coalesce(t.cross_cnt,0) > 0 ) -- non-empty LPO responses
      --
      --and (t.trading_firm_id not in ('BMO','dynamex01','Guggen','nbcanf') or t.fix_comp_id not in ('BOOKP','BOOKP2')) --???
      --
--       and t.symbol in ('PRGO')
      --and t.tif_short_name = 'GTD'
      --and t.time_in_force_id in ('2','7')
      --and t.exec_instruction is not null
  )
  , ord_par_cancelled as
  ( -- for all, new orders, modifications and internal routes
    select
        case
            when tf.trading_firm_id = 'ctctrad01' then
            replace(cl.client_order_id,'|','-')||'_'||fc.fix_comp_id
          when cl.sub_strategy_desc = 'VEGA'
            then replace(cl.client_order_id,'|','-')||'_'||coalesce(cl.co_client_leg_ref_id,'0')
          else replace(cl.client_order_id,'|','-')
        end as orderID
      , 'Cancelled' as event_type
      , to_char(cl.exec_time,'YYYYMMDD') as event_date
      , to_char(cl.exec_time,'HH24:MI:SS.US') as event_time
      , null::varchar as orig_cl_ord_id
      , case
          when cl.sub_strategy_desc = 'VEGA' then coalesce(cl.order_qty,0)
          else coalesce(cl.order_qty,0)-coalesce(cl.cum_qty,0)
          --(select coalesce(sum(ex.last_qty),0) from execution ex where ex.order_id = cl.order_id and ex.exec_type = 'F' and ex.is_busted = 'N' and ex.exec_date_id > l_gtc_date_id limit 1)
        end as event_qty -- cancelled qty
      , ''::varchar as event_price
      , case when cl.multileg_reporting_type = '2' then 'Y' else 'N' end as multi_leg_indicator
      , cl.no_legs as number_of_legs
      , co_client_leg_ref_id as leg_order_id
      , ''::varchar as leg_ratio
      , ''::varchar as order_status
      , oc.opra_symbol as osi_symbol
      , i.symbol as base_symbol
      , i.symbol||coalesce(' '||i.symbol_suffix,'') as symbol
      , i.instrument_type_id as security_type                                           -- missed in EOS
      , ui.symbol as underlying_symbol
      , case oc.put_call
          when '0' then 'P'
          when '1' then 'C'
          else 'S'
        end as put_call_stock
      , to_char(i.last_trade_date, 'YYYYMMDD') as expiration_date
      , case
          when cl.side in ('1','3') then 'B'
          when i.instrument_type_id = 'O' and cl.side not in ('1','3') then 'S'
          when cl.side = '2' then 'SL'
          when cl.side = '5' then 'SS'
          when cl.side = '6' then 'SX'
          else 'B'
        end as side
      , to_char(cl.create_time, 'YYYYMMDD')::varchar as order_creation_date
      , to_char(cl.create_time, 'HH24:MI:SS.MS')::varchar as order_creation_time
      --, coalesce( (compliance.get_sor_first_orig(in_order_id => cl.order_id, in_date_id => cl.create_date_id)).out_cl_ord_id, cl.client_order_id ) as out_cl_ord_id
      , case when cl.trans_type = 'G' then coalesce( (compliance.get_sor_first_orig(in_order_id => cl.order_id, in_date_id => cl.create_date_id)).out_cl_ord_id, cl.client_order_id ) else cl.client_order_id end as out_cl_ord_id

    from t_sdn_tmp_SOR_fix_message_event_20260106_exam_parent_cancells cl
      inner join d_account ac on ac.account_id = cl.account_id
      inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
      inner join d_instrument i on cl.instrument_id = i.instrument_id
      left join lateral
        (select oc.option_series_id, oc.opra_symbol, oc.put_call
         from d_option_contract oc
         where oc.instrument_id = cl.instrument_id
         limit 1) oc on true
      left join d_option_series os on os.option_series_id  = oc.option_series_id
      left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
      inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
      left join lateral
        (select str.parent_order_id,
         count(*) filter (where str.exchange_id = 'C1PAR') cpar_cnt,
         count(*) filter (where str.cross_order_id is not null) cross_cnt
         from client_order str
         where str.trans_type <> 'F'
         and str.parent_order_id is not null
         and str.create_date_id = 20260106 --in_date_id
         and str.parent_order_id = cl.order_id
         group by str.parent_order_id
         limit 1
        ) so on true
    where 1=1
      and ac.is_active = true
      and tf.is_active = true
      and coalesce(tf.cat_suppress,'N') <> 'Y'
      and coalesce(ac.cat_suppress,'N') <> 'Y'
      --
      --and (ac.trading_firm_id not in ('BMO','dynamex01','Guggen','nbcanf') or fc.fix_comp_id not in ('BOOKP','BOOKP2'))
      --
      --and (cl.ex_destination not in ('BRKPT','BLAZE') or ac.account_name in ('TASTYSPX','TDSPX_BP'))
      -- and cl.ex_destination not in ('RPTR','SQHT','WEEDN','JSEB','TRAFX','FBMS','CTDH','DASH','OUTCR','SLXX') ---do we really need it?
      and cl.ex_destination not in ('RPTR','BRKPT','SLXX','BLAZE')
      --
      and fc.is_high_frequency_trader = 'N'
      and (coalesce(so.cpar_cnt,0) = 0
           or
           fc.fix_comp_id not in ('LPEQP','LPOPTP','LQPNCP','LPOFP','LPOFP2','LPOPTB','LPOPTSTP','LPEQSTP','LQPNCP5INT','LQPNCPINT',
                      --GTH
                      'LPEQPGTH','LPOPTPGTH','LPCROSSGTHINT','DASHOPTP')
          )
      and (cl.ex_destination <> 'LIQPT' or coalesce(so.cross_cnt,0) > 0 )
--       and cl.symbol in ('PRGO')
  )
  , trade as
  (
    select
        case
            when tf.trading_firm_id = 'ctctrad01' then
            replace(tr.client_order_id,'|','-')||'_'||tr.fix_comp_id
          when tr.sub_strategy = 'VEGA'
            then replace(tr.client_order_id,'|','-')||'_'||coalesce(tr.leg_ref_id,'0')
          else replace(tr.client_order_id,'|','-')
        end as orderID
      , 'Trade' as event_type
      , to_char(tr.trade_record_time,'YYYYMMDD') as event_date
      , to_char(tr.trade_record_time,'HH24:MI:SS.US') as event_time
      , null::varchar as orig_cl_ord_id
      , tr.last_qty as event_qty
      , tr.last_px as event_price
      , case when cl.multileg_reporting_type = '2' then 'Y' else 'N' end as multi_leg_indicator
      , ml.no_legs as number_of_legs
      , cl.co_client_leg_ref_id as leg_order_id
      , cl.ratio_qty::varchar as leg_ratio
      , null as order_status   --  ???????????? status
      , oc.opra_symbol as osi_symbol
      , i.symbol as base_symbol
      , i.symbol||coalesce(' '||i.symbol_suffix,'') as symbol
      , i.instrument_type_id as security_type                                           -- missed in EOS
      , ui.symbol as underlying_symbol
      , case oc.put_call
          when '0' then 'P'
          when '1' then 'C'
          else 'S'
        end as put_call_stock
      , to_char(i.last_trade_date, 'YYYYMMDD') as expiration_date
      , case
          when cl.side in ('1','3') then 'B'
          when i.instrument_type_id = 'O' and cl.side not in ('1','3') then 'S'
          when cl.side = '2' then 'SL'
          when cl.side = '5' then 'SS'
          when cl.side = '6' then 'SX'
          else 'B'
        end as side
      , tr.secondary_order_id as cl_ord_id
      , to_char(cl.create_time, 'YYYYMMDD')::varchar as order_creation_date
      , to_char(cl.create_time, 'HH24:MI:SS.MS')::varchar as order_creation_time
      , to_char(tr.trade_record_time,'HH24:MI:SS.US') as executed_timestamp
      , tr.secondary_exch_exec_id  as exec_id --coalesce(, tr.exch_exec_id)
      , 'N/A'::varchar as tape_trade_id
      , tr.last_mkt
      , dex.mic_code as mic_code
      --, coalesce( (compliance.get_sor_first_orig(in_order_id => tr.order_id, in_date_id => to_char(tr.order_process_time, 'YYYYMMDD')::integer)).out_cl_ord_id, tr.client_order_id ) as out_cl_ord_id
      , case when cl.trans_type = 'G' then coalesce( (compliance.get_sor_first_orig(in_order_id => cl.order_id, in_date_id => cl.create_date_id)).out_cl_ord_id, cl.client_order_id ) else cl.client_order_id end as out_cl_ord_id
    from dwh.flat_trade_record tr
      left join d_account ac on ac.account_id = tr.account_id
      inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
      inner join d_instrument i on tr.instrument_id = i.instrument_id
      left join lateral
        (select oc.option_series_id, oc.opra_symbol, oc.put_call
         from d_option_contract oc
         where oc.instrument_id = tr.instrument_id
         limit 1) oc on true
      left join d_option_series os on os.option_series_id  = oc.option_series_id
      left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
      inner join lateral
        (
          select cl.*
          from dwh.client_order cl
          where cl.order_id = tr.order_id
            and cl.create_date_id between to_char(tr.order_process_time, 'YYYYMMDD')::integer and 20260106
          limit 1
        ) cl on true
      inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
      left join lateral
        (select str.parent_order_id,
         count(*) filter (where str.exchange_id = 'C1PAR') cpar_cnt,
         count(*) filter (where str.cross_order_id is not null) cross_cnt
         from client_order str
         where str.trans_type <> 'F'
         and str.parent_order_id is not null
         and str.create_date_id = 20260106 --in_date_id
         and str.parent_order_id = cl.order_id
         group by str.parent_order_id
         limit 1
        ) so on true
      left join lateral
        (
          select ml.order_id , ml.client_order_id , ml.fix_message_id
            , ml.no_legs
          from client_order ml
          where cl.multileg_reporting_type = '2'
            and ml.order_id = cl.multileg_order_id
            and ml.multileg_reporting_type = '3'
            and ml.create_date_id = 20260106
          limit 1
        ) ml on true
      left join d_exchange dex on tr.exchange_id = dex.exchange_id and dex.is_active = true
    where tr.date_id = 20260106
      and tr.is_busted = 'N'
      and ac.is_active = true
      and tf.is_active = true
      --
      --and (ac.trading_firm_id not in ('BMO','dynamex01','Guggen','nbcanf') or fc.fix_comp_id not in ('BOOKP','BOOKP2'))
      --
      --and (cl.ex_destination not in ('BRKPT','BLAZE') or ac.account_name in ('TASTYSPX','TDSPX_BP'))
      -- and cl.ex_destination not in ('RPTR','SQHT','WEEDN','JSEB','TRAFX','FBMS','CTDH','DASH','OUTCR','SLXX') ---do we really need it?
      and cl.ex_destination not in ('RPTR','BRKPT','SLXX','BLAZE')
      --
      and fc.is_high_frequency_trader = 'N'
      and (coalesce(so.cpar_cnt,0) = 0
           or
           fc.fix_comp_id not in ('LPEQP','LPOPTP','LQPNCP','LPOFP','LPOFP2','LPOPTB','LPOPTSTP','LPEQSTP','LQPNCP5INT','LQPNCPINT',
                      --GTH
                      'LPEQPGTH','LPOPTPGTH','LPCROSSGTHINT','DASHOPTP')
          )
      and (cl.ex_destination <> 'LIQPT' or coalesce(so.cross_cnt,0) > 0 )
    and tr.client_order_id = any('{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}')
      --
--       and i.symbol in ('PRGO') --,'AAPL','GOOG','MSFT','NVDA','SPY','TSLA')
  )
  , ord_str_new as
  (select                                                                                        --t.parent_cl_ord_id
       case
           when cl.trading_firm_id = 'ctctrad01' then
               replace(cl.po_client_order_id, '|', '-') || '_' || cl.fc_fix_comp_id
           when cl.po_sub_strategy_desc = 'VEGA'
               then replace(cl.po_client_order_id, '|', '-') || '_' || coalesce(cl.po_co_client_leg_ref_id, '0')
           when cl.po_ex_destination = 'LIQPT' then cl.po_client_order_id || '_' || cl.side::varchar
           when cl.trading_firm_id in ('imc01', 'cutler') and cl.po_fix_connection_id = 7345
               then cl.po_client_order_id || '_' || cl.order_id::varchar
           when cl.po_fix_connection_id in (503, 8785) --fc.fix_comp_id in ('BOOKP','BOOKP2')
               and cl.trading_firm_id in ('BMO', 'dynamex01', 'Guggen', 'nbcanf') then
               --coalesce((select fxp.fix_message->>'5583' from fix_capture.fix_message_json fxp where fxp.fix_message_id  = po.fix_message_id and fxp.date_id = in_date_id limit 1),po.client_order_id)
               coalesce(left(fxp.tag_9602, strpos(fxp.tag_9602, '-') - 1) ||
                        right(fxp.tag_9602, strpos(reverse(fxp.tag_9602), '-')), cl.po_client_order_id)
           else replace(cl.po_client_order_id, '|', '-')
           end                                                                  as orderID
--        case
--            when tf.trading_firm_id = 'ctctrad01' then
--            replace(cl.client_order_id,'|','-')||'_'||fc.fix_comp_id
--          when cl.sub_strategy_desc = 'VEGA'
--            then replace(cl.client_order_id,'|','-')||'_'||coalesce(cl.co_client_leg_ref_id,'0')
--          else replace(cl.client_order_id,'|','-')
--        end as orderID
        , 'Order Route'                                                         as event_type
        , to_char(cl.process_time, 'YYYYMMDD')                                  as event_date
        , to_char(cl.process_time, 'HH24:MI:SS.US')                             as event_time
        , null::varchar                                                         as orig_cl_ord_id
        , coalesce(cl.order_qty, 0)                                             as event_qty
        , case
              when cl.order_type_id in ('2', '4') then to_char((coalesce(cl.price, 0)), 'FM9999999990.09999999')
              else ''
          end                                                                   as event_price
        , case when cl.multileg_reporting_type = '2' then 'Y' else 'N' end      as multi_leg_indicator
        , ml.no_legs                                                            as number_of_legs
        , cl.co_client_leg_ref_id                                               as leg_order_id
        , cl.ratio_qty::varchar                                                 as leg_ratio
        , dos.order_status_description                                          as order_status  --  ???????????? status
        , oc.opra_symbol                                                        as osi_symbol
        , cl.symbol                                                             as base_symbol
        , cl.symbol || coalesce(' ' || cl.symbol_suffix, '')                    as symbol
        , cl.instrument_type_id                                                 as security_type -- missed in EOS
        , ui.symbol                                                             as underlying_symbol
        , case oc.put_call
              when '0' then 'P'
              when '1' then 'C'
              else 'S'
          end                                                                   as put_call_stock
        , to_char(cl.last_trade_date, 'YYYYMMDD')                               as expiration_date
        , case
              when cl.side in ('1', '3') then 'B'
              when cl.instrument_type_id = 'O' and cl.side not in ('1', '3') then 'S'
              when cl.side = '2' then 'SL'
              when cl.side = '5' then 'SS'
              when cl.side = '6' then 'SX'
              else 'B'
          end                                                                   as side
        , cl.client_order_id                                                    as cl_ord_id     -- maybe also 11011 for arca/amex ?
--      , case
--          when cl.exchange_id = 'XCHI' and cl.instrument_type_id = 'E' then
--            case cl.side
--              when '1' then 'B'||cl.client_order_id
--              else 'S'||cl.client_order_id
--            end
--          else cl.client_order_id
--        end as routed_order_id - street_cl_ord_id???
        , ''::varchar                                                           as executed_timestamp
        --!, coalesce(nullif(r.filled_qty, 0)::varchar, '') as filled_qty
        , ls.filled_qty::varchar                                                as filled_qty
        , to_char(cl.algo_start_time, 'YYYYMMDD HH24:MI:SS.US')                 as algo_start_time
        , to_char(cl.algo_end_time, 'YYYYMMDD HH24:MI:SS.US')                   as algo_end_time
        , case
              when cl.instrument_type_id = 'E'
                  then compliance.get_eq_sor_trading_session(cl.order_id, cl.create_date_id)
              else
                  case
                      --when fxm.tag_9281 in ('A','D','G') or fxm.tag_22017 = 'A' then 'ALL'
                      --when fxm.tag_9281 in ('F','C') or fxm.tag_22017 = 'B' then 'REGPOST'
                      when fxm.fix_message ->> '9281' in ('A', 'D', 'G') or fxm.fix_message ->> '22017' = 'A' then 'ALL'
                      when fxm.fix_message ->> '9281' in ('F', 'C') or fxm.fix_message ->> '22017' = 'B' then 'REGPOST'
                      else 'REG'
                      end
          end                                                                   as trading_session_id
        , (fxm.fix_message ->> '9281')::varchar                                 as tag_9281
        , (fxm.fix_message ->> '22017')::varchar                                as tag_22017
        , case
              when cl.exec_instruction ~ '(1)' then 'NH'
              when cl.exec_instruction ~ '(5)' then 'H'
              when (fxm.fix_message ->> '9291')::varchar = 'Y' then 'H' -- is held
              when (fxm.fix_message ->> '20012')::varchar = 'Y' then 'H'
          --else 'NH'
          end                                                                   as is_held
        --, (t.fix_msg_json ->> '9291')::varchar as t_9291
        --, (t.fix_msg_json ->> '20012')::varchar as t_20012
        , case
              when cl.tf_is_broker_dealer = 'N' and cl.po_sub_strategy_desc = 'DMA'
                  then 'Y'
          end                                                                   as is_directed
        , case
              when cl.tf_is_broker_dealer = 'Y' and cl.po_sub_strategy_desc = 'DMA'
                  then 'Y'
          end                                                                   as routed_as_received
        , case
              when cl.exchange_id = 'NYSE' and (fxm.fix_message ->> '128') is not null
                  then --sent to Floor broker
                  (select min(crd_number)
                   from compliance.crd_number_list
                   where cat_imid = (fxm.fix_message ->> '128')) || ':' || (fxm.fix_message ->> '128')
              when cl.exchange_id = 'XCHI' and (fxm.fix_message ->> '115') is not null
                  then
                  coalesce((select crd_number
                            from compliance.crd_number_list
                            where cat_imid = (fxm.fix_message ->> '115')
                              and (crd_amount = 1 or is_default = 'Y')) || ':' || (fxm.fix_message ->> '115'),
                           coalesce(coalesce(dcn.crd_number || ':', '') || dex.cat_exchange_id, ''))
              when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
                  then
                  coalesce(dex.cat_exchange_id, '')
              else
                  case
                      when cl.instrument_type_id = 'E'
                          then coalesce(coalesce(dcn.crd_number || ':', '') || dex.cat_exchange_id, '')
                      else coalesce(coalesce(dex.cat_crd || ':', '') || dex.cat_exchange_id, '')
                      end
          end                                                                   as ex_destination
        , case
              when cl.instrument_type_id = 'E' and cl.exchange_id = 'NYSE' and (fxm.fix_message ->> '128') is not null
                  then 'F' --sent to Floor Broker
              when cl.instrument_type_id = 'E' and cl.exchange_id = 'XCHI' and (fxm.fix_message ->> '115') is not null
                  then 'F'
              when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
                  then 'E'
              else 'F'
          end                                                                   as destination_type
--      , (fxm.fix_message ->> '49')::varchar as sender_comp_id
--      , r.max_last_mkt as last_mkt -- from trade? yes, from the last execution !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        , ''::varchar                                                           as last_mkt      --  ???????????? status ls.last_mkt
        , ''::varchar                                                           as mic_code      -- from exchange? dex.mic_code
        , (fxm.fix_message ->> '50')::varchar                                   as sender_sub_id
        , (fxm.fix_message ->> '109')::varchar                                  as street_client_id
        , (fxm.fix_message ->> '439')::varchar                                  as clearing_firm
        , (fxm.fix_message ->> '115')::varchar                                  as street_on_behalf_of_comp_id
        , (fxm.fix_message ->> '7933')::varchar                                 as routing_firm_id
        , coalesce((fxm.fix_message ->> '440')::varchar, cl.clearing_account)   as clearing_account
        , (fxm.fix_message ->> '76')::varchar                                   as exec_broker
        , (fxm.fix_message ->> '7906')::varchar                                 as combined_ord_type
        , (fxm.fix_message ->> '9016')::varchar                                 as tag_9016
        , (fxm.fix_message ->> '9140')::varchar                                 as tag_9140
        , (fxm.fix_message ->> '9152')::varchar                                 as tag_9152
        , (fxm.fix_message ->> '9183')::varchar                                 as tag_9183
        , (fxm.fix_message ->> '9303')::varchar                                 as routing_inst
        , (fxm.fix_message ->> '9355')::varchar                                 as tag_9355
        , (fxm.fix_message ->> '9416')::varchar                                 as tag_9416
        , case
              when cl.instrument_type_id = 'E' and cl.multileg_reporting_type = '2' then 'MKT' -- ???
              when cl.order_type_id in ('2', '4') and fxm.fix_message ->> '423' = '0' then 'CAB'
              when cl.order_type_id in ('2', '4') then 'LMT'
              when fxm.fix_message ->> '423' = '0' then 'CAB'
              else 'MKT'
          end                                                                   as order_type
        , case
              when tif.tif_short_name in ('GTC', 'IOC') then tif.tif_short_name
              when tif.tif_short_name = 'GTX' then 'GTX=' || to_char(cl.process_time, 'YYYYMMDD')
              when tif.tif_short_name = 'GTD' then 'GTD=' || coalesce(to_char(cl.expire_time, 'YYYYMMDD'),
                                                                      fxm.fix_message ->> '432',
                                                                      to_char(cl.process_time, 'YYYYMMDD'))
              when cl.time_in_force_id in ('C', 'M') then 'GTC'
              else 'DAY=' || to_char(cl.process_time, 'YYYYMMDD')
          end                                                                   as tif
        , case cl.open_close
              when 'C' then 'Close'
              when 'O' then 'Open'
              else ''
          end                                                                   as open_close
        , case
              when cl.exchange_id = 'NYSE' and (fxm.fix_message ->> '128') is not null and cl.instrument_type_id = 'E'
                  then ''
              when cl.exchange_id = 'XCHI' and (fxm.fix_message ->> '115') is not null and cl.instrument_type_id = 'E'
                  then ''
              when cl.exchange_id in ('CBOEDH', 'CBOEEH', 'CBOE', 'C2OX', 'BATO', 'BATODH', 'EDGO') or
                   (cl.exchange_id in ('BATS', 'BATY', 'EDGA', 'EDGX') and cl.instrument_type_id = 'E')
                  then
                  coalesce(sfc.fix_comp_id || coalesce(sfc.sender_sub_id, ''), ec.session_placeholder, '')
              when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
                  then
                  coalesce(sfc.fix_comp_id, ec.session_placeholder, '')
              else ''
          end                                                                   as session_
        , case
              when dex.trading_venue_class = 'E' then
                  coalesce(cl.customer_or_firm_id, cl.eq_order_capacity)
              else ''
          end                                                                   as exch_origin_code
        , cl.po_sub_strategy_desc                                               as sub_strategy
        , (case
               when cl.instrument_type_id = 'E' and cl.exec_instruction ~ '(f)' then 'Y'::varchar
               else '' end)::varchar                                            as iso_flag
        , cl.exec_instruction
        , case when cl.cross_order_id is not null then 'Y' else ''::varchar end as is_idx
        , case when cl.cross_order_id is not null then 'Y' else ''::varchar end as is_cross
        --, coalesce( (compliance.get_sor_first_orig(in_order_id => cl.po_order_id, in_date_id => cl.po_create_date_id)).out_cl_ord_id, cl.po_client_order_id ) as out_cl_ord_id
        , case
              when cl.po_trans_type = 'G' then coalesce((compliance.get_sor_first_orig(in_order_id => cl.po_order_id,
                                                                                       in_date_id => cl.po_create_date_id)).out_cl_ord_id,
                                                        cl.po_client_order_id)
              else cl.po_client_order_id end                                    as out_cl_ord_id
   from t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_ord cl
            left join lateral
       (select j.fix_message ->> '9602' as tag_9602
        from fix_capture.fix_message_json j
        where j.fix_message_id = cl.po_fix_message_id
          and j.date_id = 20260106
        limit 1
       ) fxp on true
            left join d_option_contract oc on oc.instrument_id = cl.instrument_id
            left join lateral
       (
       select os.option_series_id, os.underlying_instrument_id
       from d_option_series os
       where os.option_series_id = oc.option_series_id::bigint
       limit 1
       ) os on true
            left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
            left join lateral
       (select j.fix_message_id, j.fix_message--, j.fix_message->>'9281' as tag_9281,j.fix_message->>'22017' as tag_22017
        from fix_capture.fix_message_json j
        where j.fix_message_id = cl.fix_message_id
          and j.date_id = 20260106 --in_date_id
        limit 1
       ) fxm on true
            left join lateral
       (
       select dex.exchange_id, dex.cat_exchange_id, dex.trading_venue_class, dex.cat_crd
       from d_exchange dex
       where cl.exchange_id = dex.exchange_id
         and dex.is_active = true
       limit 1
       ) dex on true
            left join compliance.crd_number_list dcn on (dex.cat_exchange_id = dcn.cat_imid
       and
                                                         (dcn.crd_amount = 1 or dcn.is_default = 'Y')
       )
            left join lateral
       (
       select tif.tif_id, tif.tif_short_name
       from d_time_in_force tif
       where tif.tif_id = cl.time_in_force_id::bpchar(1)
       limit 1
       ) tif on true
            left join lateral
       (
       select ec.exchange_id, ec.session_placeholder
       from compliance.cat_exchange_config ec
       where ec.exchange_id = cl.exchange_id
       limit 1
       ) ec on true
            left join lateral
       (select ex.order_id,
               min(ex.fix_message_id) as                     fix_message_id,
               count(*) filter (where ex.exec_type in ('8')) rej_cnt,
               count(*)                                      other_cnt
        from execution ex
        where ex.order_id = cl.order_id
          and ex.exec_date_id = 20260106 --in_date_id
          and ex.is_parent_level = false
          and ex.exec_type in ('0', '4', '5', '8', 'F')
        group by ex.order_id
        limit 1
       ) er on true
            left join lateral
       (select j.fix_message ->> '10099' as tag_10099
        from fix_capture.fix_message_json j
        where j.fix_message_id = er.fix_message_id
          --(select min(ex.fix_message_id) from execution ex where ex.order_id = cl.order_id and ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type in ('0','4','8','F') limit 1)
          and j.date_id = 20260106 --in_date_id
        limit 1
       ) fxc on true
            left join lateral
       (
       select sfc.fix_connection_id, sfc.fix_comp_id, sfc.sender_sub_id
       from d_fix_connection sfc
       where sfc.fix_connection_id = (fxc.tag_10099)::smallint
         and sfc.is_active = true
       limit 1
       ) sfc on true
            left join lateral
       (
       select ml.order_id
            , ml.client_order_id
            , ml.fix_message_id
            , ml.no_legs
       from client_order ml
       where cl.multileg_reporting_type = '2'
         and ml.order_id = cl.multileg_order_id
         and ml.multileg_reporting_type = '3'
         and ml.create_date_id = 20260106
       limit 1
       ) ml on true
            left join lateral
       (
       select ls.order_id, ls.order_status, ls.filled_qty, ls.last_mkt --, dos.order_status_description
       from t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status ls
       where ls.order_id = cl.order_id
       limit 1
       ) ls on true
            left join dwh.d_order_status dos
                      on ls.order_status = dos.order_status and dos.is_active
   where 1 = 1
     --and cl.order_id not in (select order_id from compliance.aggregated_street_cross) -- ????
     and cl.trans_type = 'D' -- will be a separate route modification
--       and cl.symbol in ('PRGO')
      --
      --and fxm.fix_message->>'440' is not null
      --and cl.client_order_id  = '20260106006000000113'
  )
  , ord_str_modify as
  (
    select --t.parent_cl_ord_id
        case
          when cl.trading_firm_id = 'ctctrad01' then
            replace(cl.po_client_order_id,'|','-')||'_'||cl.fc_fix_comp_id
          when cl.po_sub_strategy_desc = 'VEGA'
            then replace(cl.po_client_order_id,'|','-')||'_'||coalesce(cl.po_co_client_leg_ref_id,'0')
          when cl.po_ex_destination = 'LIQPT' then cl.po_client_order_id||'_'||cl.side::varchar
          when cl.trading_firm_id in ('imc01','cutler') and cl.po_fix_connection_id = 7345 then cl.po_client_order_id||'_'||cl.order_id::varchar
          when cl.po_fix_connection_id in (503,8785) --fc.fix_comp_id in ('BOOKP','BOOKP2')
            and cl.trading_firm_id in ('BMO','dynamex01','Guggen','nbcanf') then
            --coalesce((select fxp.fix_message->>'5583' from fix_capture.fix_message_json fxp where fxp.fix_message_id  = po.fix_message_id and fxp.date_id = in_date_id limit 1),po.client_order_id)
            coalesce(left(fxp.tag_9602,strpos(fxp.tag_9602,'-')-1)||right(fxp.tag_9602,strpos(reverse(fxp.tag_9602),'-')), cl.po_client_order_id)
          else replace(cl.po_client_order_id,'|','-')
        end as orderID
--        case
--            when tf.trading_firm_id = 'ctctrad01' then
--            replace(cl.client_order_id,'|','-')||'_'||fc.fix_comp_id
--          when cl.sub_strategy_desc = 'VEGA'
--            then replace(cl.client_order_id,'|','-')||'_'||coalesce(cl.co_client_leg_ref_id,'0')
--          else replace(cl.client_order_id,'|','-')
--        end as orderID
      , 'Modify Route' as event_type
      , to_char(cl.process_time,'YYYYMMDD') as event_date
      , to_char(cl.process_time,'HH24:MI:SS.US') as event_time
      , case
          when orig.exchange_id = 'XCHI' and cl.instrument_type_id = 'E' then
            case orig.side
              when '1' then 'B'||orig.client_order_id
              else 'S'||orig.client_order_id
            end
          else orig.client_order_id
        end as orig_cl_ord_id
      , coalesce(cl.order_qty,0) as event_qty
      , case
            when cl.order_type_id in ('2','4') then to_char((coalesce(cl.price,0)), 'FM9999999990.09999999')
          else ''
        end as event_price
      , case when cl.multileg_reporting_type = '2' then 'Y' else 'N' end as multi_leg_indicator
      , ml.no_legs as number_of_legs
      , cl.co_client_leg_ref_id as leg_order_id
      , cl.ratio_qty::varchar as leg_ratio
      , dos.order_status_description as order_status   --  ???????????? status
      , oc.opra_symbol as osi_symbol
      , cl.symbol as base_symbol
      , cl.symbol||coalesce(' '||cl.symbol_suffix,'') as symbol
      , cl.instrument_type_id as security_type                                           -- missed in EOS
      , ui.symbol as underlying_symbol
      , case oc.put_call
          when '0' then 'P'
          when '1' then 'C'
          else 'S'
        end as put_call_stock
      , to_char(cl.last_trade_date, 'YYYYMMDD') as expiration_date
      , case
          when cl.side in ('1','3') then 'B'
          when cl.instrument_type_id = 'O' and cl.side not in ('1','3') then 'S'
          when cl.side = '2' then 'SL'
          when cl.side = '5' then 'SS'
          when cl.side = '6' then 'SX'
          else 'B'
        end as side
      , cl.client_order_id as cl_ord_id  -- maybe also 11011 for arca/amex ?
--      , case
--          when cl.exchange_id = 'XCHI' and cl.instrument_type_id = 'E' then
--            case cl.side
--              when '1' then 'B'||cl.client_order_id
--              else 'S'||cl.client_order_id
--            end
--          else cl.client_order_id
--        end as routed_order_id - street_cl_ord_id???
      , ''::varchar as executed_timestamp
      --!, coalesce(nullif(r.filled_qty, 0)::varchar, '') as filled_qty
      , ls.filled_qty::varchar as filled_qty
      , to_char(cl.algo_start_time, 'YYYYMMDD HH24:MI:SS.US') as algo_start_time
      , to_char(cl.algo_end_time, 'YYYYMMDD HH24:MI:SS.US') as algo_end_time
      , case when cl.instrument_type_id = 'E'
               then compliance.get_eq_sor_trading_session(cl.order_id, cl.create_date_id)
             else
              case
                --when fxm.tag_9281 in ('A','D','G') or fxm.tag_22017 = 'A' then 'ALL'
                --when fxm.tag_9281 in ('F','C') or fxm.tag_22017 = 'B' then 'REGPOST'
                when fxm.fix_message->>'9281' in ('A','D','G') or fxm.fix_message->>'22017' = 'A' then 'ALL'
                when fxm.fix_message->>'9281' in ('F','C') or fxm.fix_message->>'22017' = 'B' then 'REGPOST'
                else 'REG'
              end
        end as trading_session_id
      , (fxm.fix_message->>'9281')::varchar as tag_9281
      , (fxm.fix_message ->> '22017')::varchar as tag_22017
      , case
          when cl.exec_instruction ~ '(1)' then 'NH'
          when cl.exec_instruction  ~ '(5)' then 'H'
          when (fxm.fix_message ->> '9291')::varchar = 'Y' then 'H' -- is held
          when (fxm.fix_message ->> '20012')::varchar = 'Y' then 'H'
          --else 'NH'
        end as is_held
        --, (t.fix_msg_json ->> '9291')::varchar as t_9291
        --, (t.fix_msg_json ->> '20012')::varchar as t_20012
      , case when cl.tf_is_broker_dealer = 'N' and cl.po_sub_strategy_desc = 'DMA'
             then 'Y'
        end as is_directed
      , case when cl.tf_is_broker_dealer = 'Y' and cl.po_sub_strategy_desc = 'DMA'
             then 'Y'
        end as routed_as_received
      , case
          when cl.exchange_id = 'NYSE' and (fxm.fix_message ->> '128') is not null
            then --sent to Floor broker
              (select min(crd_number) from compliance.crd_number_list where cat_imid = (fxm.fix_message ->> '128'))||':'||(fxm.fix_message ->> '128')
          when cl.exchange_id = 'XCHI' and (fxm.fix_message ->> '115') is not null
            then
              coalesce((select crd_number from compliance.crd_number_list where cat_imid = (fxm.fix_message ->> '115') and (crd_amount = 1 or is_default = 'Y'))||':'||(fxm.fix_message ->> '115'),
                  coalesce(coalesce(dcn.crd_number||':','')||dex.cat_exchange_id,''))
          when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
            then
            coalesce(dex.cat_exchange_id,'')
          else
            case when cl.instrument_type_id = 'E'
              then coalesce(coalesce(dcn.crd_number||':','')||dex.cat_exchange_id,'')
              else coalesce(coalesce(dex.cat_crd||':','')||dex.cat_exchange_id,'')
            end
        end as ex_destination
      , case
          when cl.instrument_type_id = 'E' and cl.exchange_id = 'NYSE' and (fxm.fix_message ->> '128') is not null
            then 'F' --sent to Floor Broker
          when cl.instrument_type_id = 'E' and cl.exchange_id = 'XCHI' and (fxm.fix_message ->> '115') is not null
            then 'F'
          when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
            then 'E'
          else 'F'
        end as destination_type
--      , (fxm.fix_message ->> '49')::varchar as sender_comp_id
--      , r.max_last_mkt as last_mkt -- from trade? yes, from the last execution !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      , ''::varchar as last_mkt --  ???????????? status ls.last_mkt
      , ''::varchar as mic_code -- from exchange? dex.mic_code as mic_code -- from exchange?
      , (fxm.fix_message ->> '50')::varchar as sender_sub_id
      , (fxm.fix_message ->> '109')::varchar as street_client_id
      , (fxm.fix_message ->> '439')::varchar as clearing_firm
      , (fxm.fix_message ->> '115')::varchar as street_on_behalf_of_comp_id
      , (fxm.fix_message ->> '7933')::varchar as routing_firm_id
      , coalesce((fxm.fix_message ->> '440')::varchar, cl.clearing_account) as clearing_account
      , (fxm.fix_message ->> '76')::varchar as exec_broker
      , (fxm.fix_message ->> '7906')::varchar as combined_ord_type
      , (fxm.fix_message ->> '9016')::varchar as tag_9016
      , (fxm.fix_message ->> '9140')::varchar as tag_9140
      , (fxm.fix_message ->> '9152')::varchar as tag_9152
      , (fxm.fix_message ->> '9183')::varchar as tag_9183
      , (fxm.fix_message ->> '9303')::varchar as routing_inst
      , (fxm.fix_message ->> '9355')::varchar as tag_9355
      , (fxm.fix_message ->> '9416')::varchar as tag_9416
      , case
            when cl.instrument_type_id = 'E' and cl.multileg_reporting_type = '2'  then 'MKT' -- ???
            when cl.order_type_id in ('2','4') and fxm.fix_message->>'423' = '0' then 'CAB'
            when cl.order_type_id in ('2','4') then 'LMT'
            when fxm.fix_message->>'423' = '0' then 'CAB'
          else 'MKT'
        end as order_type
      , case
          when tif.tif_short_name in ('GTC','IOC') then tif.tif_short_name
          when tif.tif_short_name = 'GTX' then 'GTX='||to_char(cl.process_time,'YYYYMMDD')
          when tif.tif_short_name = 'GTD' then 'GTD='||coalesce(to_char(cl.expire_time,'YYYYMMDD'), fxm.fix_message->>'432' , to_char(cl.process_time,'YYYYMMDD'))
          when cl.time_in_force_id in ('C','M') then 'GTC'
          else 'DAY='||to_char(cl.process_time,'YYYYMMDD')
        end as tif
      , case cl.open_close
          when 'C' then 'Close'
          when 'O' then 'Open'
          else ''
        end as open_close
      , case
          when cl.exchange_id = 'NYSE' and (fxm.fix_message ->> '128') is not null and cl.instrument_type_id = 'E'
            then ''
          when cl.exchange_id = 'XCHI' and (fxm.fix_message ->> '115') is not null and cl.instrument_type_id = 'E'
            then ''
          when cl.exchange_id in ('CBOEDH','CBOEEH','CBOE','C2OX','BATO','BATODH','EDGO') or (cl.exchange_id in ('BATS','BATY','EDGA','EDGX') and cl.instrument_type_id = 'E')
            then
            coalesce(sfc.fix_comp_id||coalesce(sfc.sender_sub_id,''),ec.session_placeholder,'')
          when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
            then
            coalesce(sfc.fix_comp_id,ec.session_placeholder,'')
          else ''
        end as session_
      , case
          when dex.trading_venue_class = 'E' then
          coalesce(cl.customer_or_firm_id, cl.eq_order_capacity)
          else ''
        end as exch_origin_code
      , cl.po_sub_strategy_desc as sub_strategy
      , (case when cl.instrument_type_id = 'E' and cl.exec_instruction ~ '(f)' then 'Y'::varchar else '' end)::varchar as iso_flag
      , cl.exec_instruction
      , case when cl.cross_order_id is not null then 'Y' else ''::varchar end as is_idx
      , case when cl.cross_order_id is not null then 'Y' else ''::varchar end as is_cross
      , (cl.order_qty - ls.max_cum_qty)::varchar as leaves_qty
      --, coalesce( (compliance.get_sor_first_orig(in_order_id => cl.po_order_id, in_date_id => cl.po_create_date_id)).out_cl_ord_id, cl.po_client_order_id ) as out_cl_ord_id
      , case when cl.po_trans_type = 'G' then coalesce( (compliance.get_sor_first_orig(in_order_id => cl.po_order_id, in_date_id => cl.po_create_date_id)).out_cl_ord_id, cl.po_client_order_id ) else cl.po_client_order_id end as out_cl_ord_id
    from t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_ord cl
      inner join client_order orig on cl.orig_order_id = orig.order_id
      left join lateral
            (select j.fix_message->>'9602' as tag_9602
             from fix_capture.fix_message_json j
             where j.fix_message_id  = cl.po_fix_message_id
             and j.date_id = 20260106
             limit 1
            ) fxp on true
      left join d_option_contract oc on oc.instrument_id = cl.instrument_id
      left join lateral
        (
          select os.option_series_id, os.underlying_instrument_id
          from d_option_series os
          where os.option_series_id  = oc.option_series_id::bigint
          limit 1
        ) os on true
      left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
      left join lateral
            (select j.fix_message--, j.fix_message->>'9281' as tag_9281,j.fix_message->>'22017' as tag_22017
             from fix_capture.fix_message_json j
             where j.fix_message_id  = cl.fix_message_id
             and j.date_id = 20260106 --in_date_id
             limit 1
            ) fxm on true
      left join lateral
        (
          select dex.exchange_id, dex.cat_exchange_id, dex.trading_venue_class, dex.cat_crd
          from d_exchange dex
          where cl.exchange_id = dex.exchange_id
            and dex.is_active = true
          limit 1
        ) dex on true
      left join compliance.crd_number_list dcn on (dex.cat_exchange_id = dcn.cat_imid
                             and
                             (dcn.crd_amount = 1 or dcn.is_default = 'Y')
                               )
      left join lateral
        (
          select tif.tif_id, tif.tif_short_name
          from d_time_in_force tif
          where tif.tif_id = cl.time_in_force_id::bpchar(1)
          limit 1
        ) tif on true
      left join lateral
        (
          select ec.exchange_id, ec.session_placeholder
          from compliance.cat_exchange_config ec
          where ec.exchange_id = cl.exchange_id
          limit 1
        ) ec on true
      left join lateral
            (select ex.order_id,
             min(ex.fix_message_id) as fix_message_id,
             count(*) filter (where ex.exec_type in ('8')) rej_cnt,
             count(*) other_cnt
             from execution ex
                 where ex.order_id = cl.order_id
                 and ex.exec_date_id = 20260106 --in_date_id
                 and ex.is_parent_level = false
                 and ex.exec_type in ('0','4','5','8','F')
             group by ex.order_id
             limit 1
            ) er on true
      left join lateral
            (select j.fix_message->>'10099' as tag_10099
             from fix_capture.fix_message_json j
             where j.fix_message_id  = er.fix_message_id
              --(select min(ex.fix_message_id) from execution ex where ex.order_id = cl.order_id and ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type in ('0','4','8','F') limit 1)
             and j.date_id = 20260106 --in_date_id
             limit 1
            ) fxc on true
      left join lateral
        (
          select sfc.fix_connection_id, sfc.fix_comp_id, sfc.sender_sub_id
          from d_fix_connection sfc
          where sfc.fix_connection_id = (fxc.tag_10099)::smallint and sfc.is_active = true
          limit 1
        ) sfc on true
      left join lateral
        (
          select ml.order_id , ml.client_order_id , ml.fix_message_id
            , ml.no_legs
          from client_order ml
          where cl.multileg_reporting_type = '2'
            and ml.order_id = cl.multileg_order_id
            and ml.multileg_reporting_type = '3'
            and ml.create_date_id = 20260106
          limit 1
        ) ml on true
      left join lateral
        (
          select ls.order_id , ls.order_status , ls.filled_qty , ls.last_mkt, ls.max_cum_qty --, dos.order_status_description
          from t_sdn_tmp_SOR_fix_message_event_20260106_exam_ord_status ls
          where ls.order_id = cl.order_id
          limit 1
        ) ls on true
      left join dwh.d_order_status dos
        on ls.order_status = dos.order_status and dos.is_active
    where 1=1
      and orig.create_date_id > 20230717
      and (orig.create_date_id = 20260106 or orig.time_in_force_id in ('1','6'))
      and orig.parent_order_id is not null
      --
      and cl.trans_type = 'G' -- will be a separate route modification
--       and cl.symbol in ('PRGO')
      --
  )
  , route_cancelled as
  (
    select
        case
          --when po.sub_strategy_desc  = 'VEGA' and po.side = '1' then 'B_'||replace(po.client_order_id,'|','-')
          --when po.sub_strategy_desc  = 'VEGA' and po.side <> '1' then 'S_'||replace(po.client_order_id,'|','-')
          when tf.trading_firm_id = 'ctctrad01' then
            replace(po.client_order_id,'|','-')||'_'||fc.fix_comp_id
          when po.sub_strategy_desc = 'VEGA'
            then replace(po.client_order_id,'|','-')||'_'||coalesce(po.co_client_leg_ref_id,'0')
          when cl.instrument_type_id = 'E' and ac.account_name in ('TB_NLBC','TB_DYNX','TB_BMON','TB_GUGG') then
            coalesce(left(fxp.tag_9602,strpos(fxp.tag_9602,'-')-1)||right(fxp.tag_9602,strpos(reverse(fxp.tag_9602),'-')), po.client_order_id)
                  --coalesce((select substring(fxp.fix_message->>'9600',1,8) from fix_capture.fix_message_json fxp where fxp.fix_message_id  = po.fix_message_id and fxp.date_id = in_date_id limit 1),po.client_order_id)
          when cl.instrument_type_id = 'O' and tf.trading_firm_id in ('imc01','cutler') and po.fix_connection_id = 7345 then po.client_order_id||'_'||cl.order_id::varchar
          when cl.instrument_type_id = 'O' and po.ex_destination = 'LIQPT' then po.client_order_id||'_'||cl.side::varchar
          when cl.instrument_type_id = 'O' and po.fix_connection_id in (503,8785) --fc.fix_comp_id in ('BOOKP','BOOKP2')
            and ac.trading_firm_id in ('BMO','dynamex01','Guggen','nbcanf') then
            --coalesce((select fxp.fix_message->>'5583' from fix_capture.fix_message_json fxp where fxp.fix_message_id  = po.fix_message_id and fxp.date_id = in_date_id),po.client_order_id)
            coalesce(left(fxp.tag_9602,strpos(fxp.tag_9602,'-')-1)||right(fxp.tag_9602,strpos(reverse(fxp.tag_9602),'-')), po.client_order_id)
          else replace(po.client_order_id,'|','-')
        end as orderID
      , 'Route Cancelled' as event_type
      , to_char(cl.exec_time,'YYYYMMDD') as event_date
      , to_char(cl.exec_time,'HH24:MI:SS.US') as event_time
      , orig.client_order_id as orig_cl_ord_id
      , coalesce(cl.order_qty,0)-coalesce(cl.cum_qty,0) as event_qty
      , ''::varchar as event_price
      , case when cl.multileg_reporting_type = '2' then 'Y' else 'N' end as multi_leg_indicator
      , cl.no_legs as number_of_legs
      , cl.co_client_leg_ref_id as leg_order_id
      , cl.ratio_qty::varchar as leg_ratio
      , ''::varchar as order_status
      , oc.opra_symbol as osi_symbol
      , cl.symbol as base_symbol
      , cl.symbol||coalesce(' '||cl.symbol_suffix,'') as symbol
      , cl.instrument_type_id as security_type                                           -- missed in EOS
      , ui.symbol as underlying_symbol
      , case oc.put_call
          when '0' then 'P'
          when '1' then 'C'
          else 'S'
        end as put_call_stock
      , to_char(cl.last_trade_date, 'YYYYMMDD') as expiration_date
      , case
          when cl.side in ('1','3') then 'B'
          when cl.instrument_type_id = 'O' and cl.side not in ('1','3') then 'S'
          when cl.side = '2' then 'SL'
          when cl.side = '5' then 'SS'
          when cl.side = '6' then 'SX'
          else 'B'
        end as side
      , to_char(cl.create_time, 'YYYYMMDD')::varchar as order_creation_date
      , to_char(cl.create_time, 'HH24:MI:SS.MS')::varchar as order_creation_time
      , cl.client_order_id as cl_ord_id
      , case
          when cl.instrument_type_id='E' and cl.exchange_id = 'NYSE' and fxm.tag_128 is not null then --sent to Floor broker
              (select min(crd_number) from compliance.crd_number_list where cat_imid = fxm.tag_128)||':'||fxm.tag_128
          when cl.instrument_type_id='E' and  cl.exchange_id = 'XCHI' and fxm.tag_115 is not null then
              coalesce((select crd_number from compliance.crd_number_list where cat_imid = fxm.tag_115 and (crd_amount = 1 or is_default = 'Y'))||':'||fxm.tag_115,
                  --coalesce(coalesce(dcn.crd_number||':','')||dex.cat_exchange_id,'')
                  coalesce(coalesce(dex.cat_crd||':','')||dex.cat_exchange_id,'')
                  )
          when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
            then
            coalesce(dex.cat_exchange_id,'')
          else
            --coalesce(coalesce(dcn.crd_number||':','')||dex.cat_exchange_id,'')
            coalesce(coalesce(dex.cat_crd||':','')||dex.cat_exchange_id,'')
        end as ex_destination
      , case
          when cl.instrument_type_id='E' and cl.exchange_id = 'NYSE' and fxm.tag_128 is not null then 'F' --sent to Floor Broker
          when cl.instrument_type_id='E' and cl.exchange_id = 'XCHI' and fxm.tag_115 is not null then 'F'
          when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
            then 'E'
          else 'F'
        end as destination_type
      , coalesce(fxm.fix_message->>'50', '') as sender_sub_id
      , case
          when cl.instrument_type_id='E' and cl.exchange_id = 'NYSE' and fxm.tag_128 is not null then ''
          when cl.instrument_type_id='E' and cl.exchange_id = 'XCHI' and fxm.tag_115 is not null then ''
          when cl.exchange_id in ('CBOEDH','CBOEEH','CBOE','C2OX','BATO','BATODH','EDGO') or ( cl.instrument_type_id='E' and cl.exchange_id in ('BATS','BATY','EDGA','EDGX' )) then
            coalesce(sfc.fix_comp_id||coalesce(sfc.sender_sub_id,''),ec.session_placeholder,'')
          when dex.trading_venue_class = 'E' --or cl.exchange_id in ('XCHIML')
            then
            coalesce(sfc.fix_comp_id,ec.session_placeholder,'')
          else ''
        end session_
      , coalesce(fxm.fix_message->>'7933', '') as routing_firm_id
      , fxm.tag_115::varchar as street_on_behalf_of_comp_id
      --, coalesce( (compliance.get_sor_first_orig(in_order_id => po.order_id, in_date_id => po.create_date_id)).out_cl_ord_id, po.client_order_id ) as out_cl_ord_id
      , case when po.trans_type = 'G' then coalesce( (compliance.get_sor_first_orig(in_order_id => po.order_id, in_date_id => po.create_date_id)).out_cl_ord_id, po.client_order_id ) else po.client_order_id end as out_cl_ord_id
    from t_sdn_tmp_SOR_fix_message_event_20260106_exam_street_cancells cl
      inner join d_account ac on ac.account_id = cl.account_id
      inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
      left join lateral
        (
          select po.order_id, po.client_order_id, po.co_client_leg_ref_id
            , po.fix_message_id, po.ex_destination, po.fix_connection_id, po.sub_strategy_desc
            , po.create_date_id, po.process_time
            , po.trans_type
          from client_order po
          where cl.parent_order_id = po.order_id
            and po.create_date_id <= 20260106
            and po.create_date_id > 20230717
          limit 1
        ) po on true
      left join d_fix_connection fc on fc.fix_connection_id = po.fix_connection_id and fc.is_active = true
      left join lateral
        (select j.fix_message->>'9602' as tag_9602
         from fix_capture.fix_message_json j
         where j.fix_message_id  = po.fix_message_id
         and j.date_id > 20200717 -- this approach is more correct
         and j.date_id between po.create_date_id and 20260106
         limit 1
        ) fxp on true
      left join lateral
        (
          select orig.order_id, orig.client_order_id, orig.co_client_leg_ref_id
            , orig.fix_message_id
          from client_order orig
          where cl.orig_order_id = orig.order_id
            and orig.create_date_id <= 20260106
            and orig.create_date_id > 20230717
          limit 1
        ) orig on true
      left join lateral
        (select oc.option_series_id, oc.opra_symbol, oc.put_call
         from d_option_contract oc
         where oc.instrument_id = cl.instrument_id
         limit 1) oc on true
      left join d_option_series os on os.option_series_id  = oc.option_series_id
      left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
      left join lateral
        (select j.fix_message,j.fix_message->>'128' as tag_128,j.fix_message->>'115' as tag_115
         from fix_capture.fix_message_json j
         where j.fix_message_id  = cl.fix_message_id
         and j.date_id = 20260106
         limit 1
        ) fxm on true
      left join d_exchange dex on cl.exchange_id = dex.exchange_id and dex.is_active = true
      left join lateral
        (select j.fix_message->>'10099' as tag_10099
         from fix_capture.fix_message_json j
         where j.fix_message_id = cl.ex_fix_message_id
          --(select max(ex.fix_message_id) from execution ex where ex.order_id = cl.order_id and ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type = '0' limit 1)
         and j.date_id = 20260106
         limit 1
        ) fxc on true
      left join d_fix_connection sfc on sfc.fix_connection_id::varchar = fxc.tag_10099 and sfc.is_active = true
      left join compliance.cat_exchange_config ec on ec.exchange_id = cl.exchange_id
    where 1=1
      and cl.symbol in ('PRGO')
  )
select  s.orderID, s.event_type, s.event_date, s.event_time, s.orig_cl_ord_id, s.event_qty, s.event_price::varchar, s.order_status, s.street_cl_ord_id, s.leaves_qty, s.multi_leg_indicator, s.number_of_legs, s.leg_order_id, s.leg_ratio
      , s.osi_symbol, s.base_symbol, s.symbol, s.security_type, s.underlying_symbol, s.put_call_stock, s.expiration_date, s.side
      , s.tif, s.good_till_date, s.good_till_time, s.filled_qty, s.order_type, s.limit_market_type, s.order_price, s.order_creation_date, s.order_creation_time, s.open_close, s.is_reserve_size_order, s.is_cross, s.is_manual, s.with_discretion_price, s.trigger_time_of_managed_order, s.iso_flag, s.representative_order
      , s.stop_price, s.max_floor, s.display_quantity, s.capacity, s.user_, s.account_name, s.fdid, s.account_holder_type, s.imid, s.sender_type, s.dept_type, s.catid, s.parent_catid, s.on_behalf_of_comp_id, s.sub_strategy, s.exec_instruction, s.discretion_offset
      , s.executed_timestamp, s.algo_start_time, s.algo_end_time, s.trading_session_id, s.tag_9281, s.tag_22017, s.is_held, s.is_directed, s.routed_as_received, s.ex_destination, s.destination_type, s.last_mkt, s.mic_code, s.sender_sub_id, s.street_client_id, s.clearing_firm, s.street_on_behalf_of_comp_id, s.routing_firm_id, s.clearing_account, s.exec_broker, s.combined_ord_type
      , s.tag_9016, s.tag_9140, s.tag_9152, s.tag_9183, s.routing_inst, s.tag_9355, s.tag_9416, s.session_, s.exch_origin_code
      , s.exec_id, s.tape_trade_id, s.is_idx
      --, case when s.security_type = 'E' and s.multi_leg_indicator = 'Y' then 'O' else s.security_type end as security_type_mleg_eq
from
  (
    select op.out_cl_ord_id, op.orderID, op.event_type, op.event_date, op.event_time, op.orig_cl_ord_id, op.event_qty, op.event_price::varchar, op.order_status, ''::varchar as street_cl_ord_id, ''::varchar as leaves_qty, op.multi_leg_indicator, op.number_of_legs, op.leg_order_id, op.leg_ratio
      , op.osi_symbol, op.base_symbol, op.symbol, op.security_type, op.underlying_symbol, op.put_call_stock, op.expiration_date, op.side
      , op.tif, op.good_till_date, op.good_till_time, op.filled_qty, op.order_type, op.limit_market_type, op.order_price, op.order_creation_date, op.order_creation_time, op.open_close, op.is_reserve_size_order, op.is_cross, op.is_manual, op.with_discretion_price, op.trigger_time_of_managed_order, op.iso_flag, op.representative_order
      , op.stop_price, op.max_floor, op.display_quantity, op.capacity, op.user_, op.account_name, op.fdid, op.account_holder_type, op.imid, op.sender_type, op.dept_type, op.catid, op.parent_catid, op.on_behalf_of_comp_id, op.sub_strategy, op.exec_instruction, op.discretion_offset
      , ''::varchar as executed_timestamp, ''::varchar as algo_start_time, ''::varchar as algo_end_time, op.trading_session_id, ''::varchar as tag_9281, ''::varchar as tag_22017, ''::varchar as is_held, op.is_directed, op.routed_as_received, ''::varchar as ex_destination, ''::varchar as destination_type, op.last_mkt, ''::varchar as mic_code, ''::varchar as sender_sub_id, ''::varchar as street_client_id, ''::varchar as clearing_firm, ''::varchar as street_on_behalf_of_comp_id, ''::varchar as routing_firm_id, ''::varchar as clearing_account, ''::varchar as exec_broker, ''::varchar as combined_ord_type
      , ''::varchar as tag_9016, ''::varchar as tag_9140, ''::varchar as tag_9152, ''::varchar as tag_9183, ''::varchar as routing_inst, ''::varchar as tag_9355, ''::varchar as tag_9416, ''::varchar as session_, ''::varchar as exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, op.is_idx
    from ord_par_new op
    union all
    select op.out_cl_ord_id, op.orderID, op.event_type, op.event_date, op.event_time, op.orig_cl_ord_id, op.event_qty, op.event_price::varchar, op.order_status, ''::varchar as street_cl_ord_id, op.leaves_qty, op.multi_leg_indicator, op.number_of_legs, op.leg_order_id, op.leg_ratio
      , op.osi_symbol, op.base_symbol, op.symbol, op.security_type, op.underlying_symbol, op.put_call_stock, op.expiration_date, op.side
      , op.tif, op.good_till_date, op.good_till_time, op.filled_qty, op.order_type, op.limit_market_type, op.order_price, op.order_creation_date, op.order_creation_time, op.open_close, op.is_reserve_size_order, op.is_cross, op.is_manual, op.with_discretion_price, op.trigger_time_of_managed_order, op.iso_flag, op.representative_order
      , op.stop_price, op.max_floor, op.display_quantity, op.capacity, op.user_, op.account_name, op.fdid, op.account_holder_type, op.imid, op.sender_type, op.dept_type, op.catid, op.parent_catid, op.on_behalf_of_comp_id, op.sub_strategy, op.exec_instruction, op.discretion_offset
      , ''::varchar as executed_timestamp, ''::varchar as algo_start_time, ''::varchar as algo_end_time, op.trading_session_id, ''::varchar as tag_9281, ''::varchar as tag_22017, ''::varchar as is_held, op.is_directed, op.routed_as_received, ''::varchar as ex_destination, ''::varchar as destination_type, op.last_mkt, ''::varchar as mic_code, ''::varchar as sender_sub_id, ''::varchar as street_client_id, ''::varchar as clearing_firm, ''::varchar as street_on_behalf_of_comp_id, ''::varchar as routing_firm_id, ''::varchar as clearing_account, ''::varchar as exec_broker, ''::varchar as combined_ord_type
      , ''::varchar as tag_9016, ''::varchar as tag_9140, ''::varchar as tag_9152, ''::varchar as tag_9183, ''::varchar as routing_inst, ''::varchar as tag_9355, ''::varchar as tag_9416, ''::varchar as session_, ''::varchar as exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, op.is_idx
    from ord_par_modify op
    union all
    select op.out_cl_ord_id, op.orderID, op.event_type, op.event_date, op.event_time, op.orig_cl_ord_id, op.event_qty, op.event_price::varchar, op.order_status, ''::varchar as street_cl_ord_id, ''::varchar as leaves_qty, op.multi_leg_indicator, op.number_of_legs, op.leg_order_id, op.leg_ratio
      , op.osi_symbol, op.base_symbol, op.symbol, op.security_type, op.underlying_symbol, op.put_call_stock, op.expiration_date, op.side
      , op.tif, op.good_till_date, op.good_till_time, op.filled_qty, op.order_type, op.limit_market_type, op.order_price, op.order_creation_date, op.order_creation_time, op.open_close, op.is_reserve_size_order, op.is_cross, op.is_manual, op.with_discretion_price, op.trigger_time_of_managed_order, op.iso_flag, op.representative_order
      , op.stop_price, op.max_floor, op.display_quantity, op.capacity, op.user_, op.account_name, op.fdid, op.account_holder_type, op.imid, op.sender_type, op.dept_type, op.catid, op.parent_catid, op.on_behalf_of_comp_id, op.sub_strategy, op.exec_instruction, op.discretion_offset
      , ''::varchar as executed_timestamp, ''::varchar as algo_start_time, ''::varchar as algo_end_time, op.trading_session_id, ''::varchar as tag_9281, ''::varchar as tag_22017, ''::varchar as is_held, op.is_directed, op.routed_as_received, ''::varchar as ex_destination, ''::varchar as destination_type, op.last_mkt, ''::varchar as mic_code, ''::varchar as sender_sub_id, ''::varchar as street_client_id, ''::varchar as clearing_firm, ''::varchar as street_on_behalf_of_comp_id, ''::varchar as routing_firm_id, ''::varchar as clearing_account, ''::varchar as exec_broker, ''::varchar as combined_ord_type
      , ''::varchar as tag_9016, ''::varchar as tag_9140, ''::varchar as tag_9152, ''::varchar as tag_9183, ''::varchar as routing_inst, ''::varchar as tag_9355, ''::varchar as tag_9416, ''::varchar as session_, ''::varchar as exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, op.is_idx
    from ord_par_ir op
    union all
    select op.out_cl_ord_id, op.orderID, op.event_type, op.event_date, op.event_time, op.orig_cl_ord_id, op.event_qty, op.event_price::varchar, op.order_status, ''::varchar as street_cl_ord_id, op.leaves_qty, op.multi_leg_indicator, op.number_of_legs, op.leg_order_id, op.leg_ratio
      , op.osi_symbol, op.base_symbol, op.symbol, op.security_type, op.underlying_symbol, op.put_call_stock, op.expiration_date, op.side
      , op.tif, op.good_till_date, op.good_till_time, op.filled_qty, op.order_type, op.limit_market_type, op.order_price, op.order_creation_date, op.order_creation_time, op.open_close, op.is_reserve_size_order, op.is_cross, op.is_manual, op.with_discretion_price, op.trigger_time_of_managed_order, op.iso_flag, op.representative_order
      , op.stop_price, op.max_floor, op.display_quantity, op.capacity, op.user_, op.account_name, op.fdid, op.account_holder_type, op.imid, op.sender_type, op.dept_type, op.catid, op.parent_catid, op.on_behalf_of_comp_id, op.sub_strategy, op.exec_instruction, op.discretion_offset
      , ''::varchar as executed_timestamp, ''::varchar as algo_start_time, ''::varchar as algo_end_time, op.trading_session_id, ''::varchar as tag_9281, ''::varchar as tag_22017, ''::varchar as is_held, op.is_directed, op.routed_as_received, ''::varchar as ex_destination, ''::varchar as destination_type, op.last_mkt, ''::varchar as mic_code, ''::varchar as sender_sub_id, ''::varchar as street_client_id, ''::varchar as clearing_firm, ''::varchar as street_on_behalf_of_comp_id, ''::varchar as routing_firm_id, ''::varchar as clearing_account, ''::varchar as exec_broker, ''::varchar as combined_ord_type
      , ''::varchar as tag_9016, ''::varchar as tag_9140, ''::varchar as tag_9152, ''::varchar as tag_9183, ''::varchar as routing_inst, ''::varchar as tag_9355, ''::varchar as tag_9416, ''::varchar as session_, ''::varchar as exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, op.is_idx
    from ord_par_ir_modify op
    union all
    select cc.out_cl_ord_id, cc.orderID, cc.event_type, cc.event_date, cc.event_time, cc.orig_cl_ord_id, cc.event_qty, cc.event_price::varchar, cc.order_status, ''::varchar as street_cl_ord_id, ''::varchar as leaves_qty, cc.multi_leg_indicator, cc.number_of_legs, cc.leg_order_id, cc.leg_ratio
      , cc.osi_symbol, cc.base_symbol, cc.symbol, cc.security_type, cc.underlying_symbol, cc.put_call_stock, cc.expiration_date, cc.side
      , ''::varchar as tif, ''::varchar as good_till_date, ''::varchar as good_till_time, ''::varchar as filled_qty, ''::varchar as order_type, ''::varchar as limit_market_type, ''::varchar as order_price, ''::varchar as order_creation_date, ''::varchar as order_creation_time, ''::varchar as open_close, ''::varchar as is_reserve_size_order, ''::varchar as is_cross, ''::varchar as is_manual, ''::varchar as with_discretion_price, ''::varchar as trigger_time_of_managed_order, ''::varchar as iso_flag, ''::varchar as representative_order
      , ''::varchar as stop_price, ''::varchar as max_floor, ''::varchar as display_quantity, ''::varchar as capacity, ''::varchar as user_, ''::varchar as account_name, ''::varchar as fdid, ''::varchar as account_holder_type, ''::varchar as imid, ''::varchar as sender_type, ''::varchar as dept_type, ''::varchar as catid, ''::varchar as parent_catid, ''::varchar as on_behalf_of_comp_id, ''::varchar as sub_strategy, ''::varchar as exec_instruction, ''::varchar as discretion_offset
      , ''::varchar as executed_timestamp, ''::varchar as algo_start_time, ''::varchar as algo_end_time, ''::varchar as trading_session_id, ''::varchar as tag_9281, ''::varchar as tag_22017, ''::varchar as is_held, ''::varchar as is_directed, ''::varchar as routed_as_received, ''::varchar as ex_destination, ''::varchar as destination_type, ''::varchar as last_mkt, ''::varchar as mic_code, ''::varchar as sender_sub_id, ''::varchar as street_client_id, ''::varchar as clearing_firm, ''::varchar as street_on_behalf_of_comp_id, ''::varchar as routing_firm_id, ''::varchar as clearing_account, ''::varchar as exec_broker, ''::varchar as combined_ord_type
      , ''::varchar as tag_9016, ''::varchar as tag_9140, ''::varchar as tag_9152, ''::varchar as tag_9183, ''::varchar as routing_inst, ''::varchar as tag_9355, ''::varchar as tag_9416, ''::varchar as session_, ''::varchar as exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, ''::varchar as is_idx
    from ord_par_cancelled cc
    union all
    select tr.out_cl_ord_id, tr.orderID, tr.event_type, tr.event_date, tr.event_time, tr.orig_cl_ord_id, tr.event_qty, tr.event_price::varchar, tr.order_status, tr.cl_ord_id as street_cl_ord_id, ''::varchar as leaves_qty, tr.multi_leg_indicator, tr.number_of_legs, tr.leg_order_id, tr.leg_ratio
      , tr.osi_symbol, tr.base_symbol, tr.symbol, tr.security_type, tr.underlying_symbol, tr.put_call_stock, tr.expiration_date, tr.side
      , ''::varchar as tif, ''::varchar as good_till_date, ''::varchar as good_till_time, ''::varchar as filled_qty, ''::varchar as order_type, ''::varchar as limit_market_type, ''::varchar as order_price, tr.order_creation_date, tr.order_creation_time, ''::varchar as open_close, ''::varchar as is_reserve_size_order, ''::varchar as is_cross, ''::varchar as is_manual, ''::varchar as with_discretion_price, ''::varchar as trigger_time_of_managed_order, ''::varchar as iso_flag, ''::varchar as representative_order
      , ''::varchar as stop_price, ''::varchar as max_floor, ''::varchar as display_quantity, ''::varchar as capacity, ''::varchar as user_, ''::varchar as account_name, ''::varchar as fdid, ''::varchar as account_holder_type, ''::varchar as imid, ''::varchar as sender_type, ''::varchar as dept_type, ''::varchar as catid, ''::varchar as parent_catid, ''::varchar as on_behalf_of_comp_id, ''::varchar as sub_strategy, ''::varchar as exec_instruction, ''::varchar as discretion_offset
      , tr.executed_timestamp, ''::varchar as algo_start_time, ''::varchar as algo_end_time, ''::varchar as trading_session_id, ''::varchar as tag_9281, ''::varchar as tag_22017, ''::varchar as is_held, ''::varchar as is_directed, ''::varchar as routed_as_received, ''::varchar as ex_destination, ''::varchar as destination_type, tr.last_mkt, tr.mic_code, ''::varchar as sender_sub_id, ''::varchar as street_client_id, ''::varchar as clearing_firm, ''::varchar as street_on_behalf_of_comp_id, ''::varchar as routing_firm_id, ''::varchar as clearing_account, ''::varchar as exec_broker, ''::varchar as combined_ord_type
      , ''::varchar as tag_9016, ''::varchar as tag_9140, ''::varchar as tag_9152, ''::varchar as tag_9183, ''::varchar as routing_inst, ''::varchar as tag_9355, ''::varchar as tag_9416, ''::varchar as session_, ''::varchar as exch_origin_code
      , tr.exec_id, tr.tape_trade_id, ''::varchar as is_idx
    from trade tr
    union all
    select os.out_cl_ord_id, os.orderID, os.event_type, os.event_date, os.event_time, os.orig_cl_ord_id, os.event_qty, os.event_price::varchar, os.order_status, os.cl_ord_id as street_cl_ord_id, ''::varchar as leaves_qty, os.multi_leg_indicator, os.number_of_legs, os.leg_order_id, os.leg_ratio
      , os.osi_symbol, os.base_symbol, os.symbol, os.security_type, os.underlying_symbol, os.put_call_stock, os.expiration_date, os.side
      , os.tif, ''::varchar as good_till_date, ''::varchar as good_till_time, os.filled_qty, os.order_type, ''::varchar as limit_market_type, ''::varchar as order_price, ''::varchar as order_creation_date, ''::varchar as order_creation_time, os.open_close, ''::varchar as is_reserve_size_order, os.is_cross, ''::varchar as is_manual, ''::varchar as with_discretion_price, ''::varchar as trigger_time_of_managed_order, os.iso_flag, ''::varchar as representative_order
      , ''::varchar as stop_price, ''::varchar as max_floor, ''::varchar as display_quantity, ''::varchar as capacity, ''::varchar as user_, ''::varchar as account_name, ''::varchar as fdid, ''::varchar as account_holder_type, ''::varchar as imid, ''::varchar as sender_type, ''::varchar as dept_type, ''::varchar as catid, ''::varchar as parent_catid, ''::varchar as on_behalf_of_comp_id, os.sub_strategy, os.exec_instruction, ''::varchar as discretion_offset
      , os.executed_timestamp, os.algo_start_time, os.algo_end_time, os.trading_session_id, os.tag_9281, os.tag_22017, os.is_held, os.is_directed, os.routed_as_received, os.ex_destination, os.destination_type, os.last_mkt, os.mic_code, os.sender_sub_id, os.street_client_id, os.clearing_firm, os.street_on_behalf_of_comp_id, os.routing_firm_id, os.clearing_account, os.exec_broker, os.combined_ord_type
      , os.tag_9016, os.tag_9140, os.tag_9152, os.tag_9183, os.routing_inst, os.tag_9355, os.tag_9416, os.session_, os.exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, os.is_idx
    from ord_str_new os
    union all
    select os.out_cl_ord_id, os.orderID, os.event_type, os.event_date, os.event_time, os.orig_cl_ord_id, os.event_qty, os.event_price::varchar, os.order_status, os.cl_ord_id as street_cl_ord_id, os.leaves_qty, os.multi_leg_indicator, os.number_of_legs, os.leg_order_id, os.leg_ratio
      , os.osi_symbol, os.base_symbol, os.symbol, os.security_type, os.underlying_symbol, os.put_call_stock, os.expiration_date, os.side
      , os.tif, ''::varchar as good_till_date, ''::varchar as good_till_time, os.filled_qty, os.order_type, ''::varchar as limit_market_type, ''::varchar as order_price, ''::varchar as order_creation_date, ''::varchar as order_creation_time, os.open_close, ''::varchar as is_reserve_size_order, os.is_cross, ''::varchar as is_manual, ''::varchar as with_discretion_price, ''::varchar as trigger_time_of_managed_order, os.iso_flag, ''::varchar as representative_order
      , ''::varchar as stop_price, ''::varchar as max_floor, ''::varchar as display_quantity, ''::varchar as capacity, ''::varchar as user_, ''::varchar as account_name, ''::varchar as fdid, ''::varchar as account_holder_type, ''::varchar as imid, ''::varchar as sender_type, ''::varchar as dept_type, ''::varchar as catid, ''::varchar as parent_catid, ''::varchar as on_behalf_of_comp_id, os.sub_strategy, os.exec_instruction, ''::varchar as discretion_offset
      , os.executed_timestamp, os.algo_start_time, os.algo_end_time, os.trading_session_id, os.tag_9281, os.tag_22017, os.is_held, os.is_directed, os.routed_as_received, os.ex_destination, os.destination_type, os.last_mkt, os.mic_code, os.sender_sub_id, os.street_client_id, os.clearing_firm, os.street_on_behalf_of_comp_id, os.routing_firm_id, os.clearing_account, os.exec_broker, os.combined_ord_type
      , os.tag_9016, os.tag_9140, os.tag_9152, os.tag_9183, os.routing_inst, os.tag_9355, os.tag_9416, os.session_, os.exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, os.is_idx
    from ord_str_modify os
    union all
    select rc.out_cl_ord_id, rc.orderID, rc.event_type, rc.event_date, rc.event_time, rc.orig_cl_ord_id, rc.event_qty, rc.event_price::varchar, rc.order_status, rc.cl_ord_id as street_cl_ord_id, ''::varchar as leaves_qty, rc.multi_leg_indicator, rc.number_of_legs, rc.leg_order_id, rc.leg_ratio
      , rc.osi_symbol, rc.base_symbol, rc.symbol, rc.security_type, rc.underlying_symbol, rc.put_call_stock, rc.expiration_date, rc.side
      , ''::varchar as tif, ''::varchar as good_till_date, ''::varchar as good_till_time, ''::varchar as filled_qty, ''::varchar as order_type, ''::varchar as limit_market_type, ''::varchar as order_price, ''::varchar as order_creation_date, ''::varchar as order_creation_time, ''::varchar as open_close, ''::varchar as is_reserve_size_order, ''::varchar as is_cross, ''::varchar as is_manual, ''::varchar as with_discretion_price, ''::varchar as trigger_time_of_managed_order, ''::varchar as iso_flag, ''::varchar as representative_order
      , ''::varchar as stop_price, ''::varchar as max_floor, ''::varchar as display_quantity, ''::varchar as capacity, ''::varchar as user_, ''::varchar as account_name, ''::varchar as fdid, ''::varchar as account_holder_type, ''::varchar as imid, ''::varchar as sender_type, ''::varchar as dept_type, ''::varchar as catid, ''::varchar as parent_catid, ''::varchar as on_behalf_of_comp_id, ''::varchar as sub_strategy, ''::varchar as exec_instruction, ''::varchar as discretion_offset
      , ''::varchar as executed_timestamp, ''::varchar as algo_start_time, ''::varchar as algo_end_time, ''::varchar as trading_session_id, ''::varchar as tag_9281, ''::varchar as tag_22017, ''::varchar as is_held, ''::varchar as is_directed, ''::varchar as routed_as_received, rc.ex_destination, rc.destination_type, ''::varchar as last_mkt, ''::varchar as mic_code, rc.sender_sub_id, ''::varchar as street_client_id, ''::varchar as clearing_firm, rc.street_on_behalf_of_comp_id, rc.routing_firm_id, ''::varchar as clearing_account, ''::varchar as exec_broker, ''::varchar as combined_ord_type
      , ''::varchar as tag_9016, ''::varchar as tag_9140, ''::varchar as tag_9152, ''::varchar as tag_9183, ''::varchar as routing_inst, ''::varchar as tag_9355, ''::varchar as tag_9416, rc.session_, ''::varchar as exch_origin_code
      , ''::varchar as exec_id, ''::varchar as tape_trade_id, ''::varchar as is_idx
    from route_cancelled rc
  ) s
order by case when s.security_type = 'E' and s.multi_leg_indicator = 'Y' then 'O' else s.security_type end -- to be able to split file on Eq and Opt parts
  , out_cl_ord_id, orderid,street_cl_ord_id, event_time, orig_cl_ord_id
--order by 1,3,4,street_cl_ord_id


