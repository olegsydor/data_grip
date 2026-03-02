-- GTC date_id
select coalesce(min(gtc.create_date_id), :l_date_begin_id)
--     into l_retention_date_id 20260225
from dwh.gtc_order_status gtc
where true
  and (gtc.close_date_id is null
    or gtc.close_date_id >= :l_date_end_id)
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else gtc.account_id = any (:in_account_ids) end
  and case
          when coalesce(:in_client_order_ids, '{}') = '{}' then true
          else gtc.client_order_id = any (:in_client_order_ids) end;
--
-- obo routes
drop table if exists t_route;
create temp table t_route as
select *
from (values ('D', 'New Order', 1),
             ('D', 'Order Route', 2),
             ('G', 'Order Modify', 1),
             ('G', 'Order Modify Route', 2))
         as t(trans_type, order_type_value, rn)
where true
  and case when :in_include_routes = 'Y' then true else rn = 1 end;


-- parent orders
drop table if exists t_base;
create temp table t_base as
select cl.*,
       di.symbol,
       di.symbol_suffix,
       di.instrument_type_id,
       di.last_trade_date,
       ac.cat_report_on_behalf_of,
       tf.trading_firm_name,
       tf.cat_imid          as tf_cat_imid,
       tf.cat_crd           as tf_cat_crd,
       orig.client_order_id as orig_client_order_id,
       orig.price           as orig_price,
       oc.opra_symbol,
       oc.strike_price,
       os.root_symbol,
       ui.symbol            as underlying_symbol,
       fmj.tag_58,
       case
           when di.instrument_type_id = 'E' then 'Stock'
           when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
           when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
           end              as pcv,
       dtif.tif_short_name  as tif,
       dot.order_type_name,
       case
           when tag_9281 in ('A', 'D', 'G') then 'ALL'
           when tag_22017 = 'A' then 'ALL'
           when tag_9281 in ('F', 'C') then 'REGPOST'
           when tag_22017 = 'B' then 'REGPOST'
           else 'REG' end   as trading_session,
    cof.customer_or_firm_name
from dwh.client_order cl
         join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
         join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         left join lateral (select client_order_id, price
                            from dwh.client_order orig
                            where orig.order_id = cl.orig_order_id
                              and orig.create_date_id <= cl.create_date_id
                              and orig.create_date_id >= :l_retention_date_id
                            limit 1) orig on cl.orig_order_id is not null
         left join dwh.d_option_contract oc on di.instrument_id = oc.instrument_id
         left join d_option_series os on os.option_series_id = oc.option_series_id
         left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
         left join dwh.d_fix_connection fc
                   on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
         left join dwh.d_time_in_force dtif on dtif.tif_id = cl.time_in_force_id
         left join lateral (select
--                                        fmj.fix_message ->> '5050'  as tag_5050,
--                                        fmj.fix_message ->> '50'    as tag_50,
--                                        fmj.fix_message ->> '109'   as tag_109,
--                                        fmj.fix_message ->> '9000'  as tag_9000,
fmj.fix_message ->> '58'    as tag_58,
--                                        fmj.fix_message ->> '17'    as tag_17,
--                                        fmj.fix_message ->> '52'    as tag_52,
--                                        fmj.fix_message ->> '9291'  as tag_9291,
fmj.fix_message ->> '9281'  as tag_9281,
fmj.fix_message ->> '22017' as tag_22017,
fmj.fix_message ->> '60'    as tag_60
                            from fix_capture.fix_message_json fmj
                            where cl.fix_message_id = fmj.fix_message_id
                              and fmj.date_id >= cl.create_date_id
                            limit 1) fmj on true
         left join dwh.d_order_type dot on dot.order_type_id = cl.order_type_id
 left join dwh.d_customer_or_firm cof on cof.customer_or_firm_id = cl.customer_or_firm_id
where cl.parent_order_id is null
  and cl.create_date_id between :l_date_begin_id and :l_date_end_id
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else cl.account_id = any (:in_account_ids) end
  and case
          when coalesce(:in_client_order_ids, '{}') = '{}' then true
          else cl.client_order_id = any (:in_client_order_ids) end
  and case when :in_instrument_type is null then true else di.instrument_type_id = :in_instrument_type end
  and case when :in_exclude_eos = 'N' then true else fc.is_high_frequency_trader = 'N' end
  and case when :in_fix_comp_ids = '{}' then true else coalesce(fc.fix_comp_id, '') = any (:in_fix_comp_ids) end
  and cl.trans_type <> 'F'
  and cl.trans_type in ('D', 'G')
  and cl.multileg_reporting_type in ('1', '2')
;
analyze t_base;
-- select * from t_base;

-- street orders
insert into t_base
select cl.*,
       di.symbol,
       di.symbol_suffix,
       di.instrument_type_id,
       di.last_trade_date,
       null            as cat_report_on_behalf_of,
       par.trading_firm_name,
       par.tf_cat_imid as tf_cat_imid,
       par.tf_cat_crd  as tf_cat_crd,
       par.orig_client_order_id,
       par.orig_price,
       par.opra_symbol,
       par.strike_price,
       par.root_symbol,
       par.underlying_symbol,
       par.tag_58,
       par.pcv,
       par.tif,
       par.order_type_name,
       par.trading_session,
       par.customer_or_firm_name
from t_base par
         join dwh.client_order cl on cl.parent_order_id = par.order_id
         left join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
where true
  and cl.create_date_id between :l_date_begin_id and :l_date_end_id
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else cl.account_id = any (:in_account_ids) end
  and cl.parent_order_id is not null
  and cl.trans_type in ('D', 'G')
  and cl.multileg_reporting_type in ('1', '2');

-- parent cancels
drop table if exists t_parent_cancels;
create temp table t_parent_cancels as
select cl.fix_connection_id,
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
       ex.exec_date_id,
       ex.exec_time,
       ex.cum_qty,
       ex.order_id,
       ex.account_id,
       di.symbol
from client_order cl
         inner join lateral (select ex.exec_date_id,
                                    ex.exec_time as exec_time,
                                    ex.cum_qty,
                                    ex.order_id,
                                    ex.account_id
                             from execution ex
                             where ex.order_id = cl.order_id
                               and ex.exec_date_id between :l_date_begin_id and :l_date_end_id
                               and ex.is_parent_level = true
                               and case
                                       when ex.exec_type = '4' then true
                                       when ex.order_status = '4' then true
                                       else false end) ex on true
         left join dwh.d_instrument di on cl.instrument_id = di.instrument_id
where true
  and case
          when cl.time_in_force_id in ('1', '6') then cl.create_date_id > :l_gtc_date_id
          else cl.create_date_id between :l_date_begin_id and :l_date_end_id end
  and cl.parent_order_id is null
  and cl.trans_type in ('D', 'G')
  and (cl.multileg_reporting_type in ('1', '2') or cl.sub_strategy_desc = 'VEGA')
  and coalesce(cl.time_in_force_id, '0') <> '3'
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else cl.account_id = any (:in_account_ids) end
  and case
          when coalesce(:in_client_order_ids, '{}') = '{}' then true
          else cl.client_order_id = any (:in_client_order_ids) end
  and case when :in_instrument_type is null then true else di.instrument_type_id = :in_instrument_type end
;
select * from t_parent_cancels;

-- street cancels

drop table if exists t_street_cancels;
create table t_street_cancels as
select cl.fix_connection_id,
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
       ex.exec_date_id,
       ex.exec_time,
       ex.cum_qty,
       ex.order_id,
       ex.account_id,
       di.symbol,
       di.instrument_type_id,
       di.symbol_suffix,
       di.last_trade_date
from client_order cl
    join t_base on t_base.order_id = cl.order_id
         inner join lateral (select ex.exec_date_id,
                                    ex.exec_time,
                                    ex.cum_qty,
                                    ex.order_id,
                                    ex.account_id
                             from execution ex
                             where ex.order_id = cl.order_id
                               and ex.exec_date_id between :l_date_begin_id and :l_date_end_id
                               and ex.exec_date_id = cl.create_date_id
                               and ex.is_parent_level = false
                               and case
                                       when ex.exec_type = '4' then true
                                       when ex.order_status = '4' then true
                                       else false end) ex on true
         left join dwh.d_instrument di on cl.instrument_id = di.instrument_id
where true
  and cl.create_date_id > :l_gtc_date_id
  and case
          when cl.time_in_force_id in ('1', '6') then cl.create_date_id > :l_gtc_date_id
          else cl.create_date_id between :l_date_begin_id and :l_date_end_id end
  and cl.parent_order_id is not null
  and cl.trans_type in ('D', 'G')
  and (cl.multileg_reporting_type in ('1', '2') or cl.sub_strategy_desc = 'VEGA');

select * from t_street_cancels;

drop table if exists t_ord_status;
create temp table t_ord_status as
    -- explain
select cl.order_id
     , cl.parent_order_id
     , cl.create_date_id
     , cl.time_in_force_id
     , cl.symbol
     , cl.order_qty
     , le.order_status
     , case
           when cl.parent_order_id is null
               then tr.filled_qty
           else le.filled_qty
    end as filled_qty
     , le.max_cum_qty
     , le.last_mkt
     , dos.order_status_description
from t_base cl
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
         , row_number() over (order by e.exec_time desc, e.exec_id desc) as rn
         , sum(e.last_qty) over (partition by e.order_id)                as filled_qty
         , max(e.cum_qty) over (partition by e.order_id)                 as max_cum_qty
    --, max(e.last_mkt) over (partition by e.order_id) as max_last_mkt -- looks like it is wrong as each trade can have last_mkt
    --, last_value(e.last_mkt) over (partition by e.order_id order by e.exec_time, e.exec_id) as max_last_mkt -- Oh, last_mkt usually is on PARENT level trades
    from dwh.execution e
    where e.order_id = cl.order_id
      and e.exec_date_id between :l_date_begin_id and :l_date_end_id -- last status as for 12/23, but including GTH
      and e.exec_type not in ('A') --,'3') -- remove DoneForDay if we need
    ) le on rn = 1 --last status
         left join lateral
    ( -- for parent orders only
    select tr.order_id, sum(tr.last_qty) as filled_qty
    from dwh.flat_trade_record tr
    where tr.date_id between :l_date_begin_id and :l_date_end_id
      and cl.parent_order_id is null
      and cl.order_id = tr.order_id
      and tr.is_busted = 'N'
    group by tr.order_id
    ) tr on true
         left join lateral (select order_status_description
                            from dwh.d_order_status dos
                            where le.order_status = dos.order_status
                              and dos.is_active
                            limit 1) dos on true
;

drop table if exists t_trade;
create temp table if not exists t_trade as
select case
           when tf.trading_firm_id = 'ctctrad01' then
               replace(tr.client_order_id, '|', '-') || '_' || tr.fix_comp_id
           when tr.sub_strategy = 'VEGA'
               then replace(tr.client_order_id, '|', '-') || '_' || coalesce(tr.leg_ref_id, '0')
           else replace(tr.client_order_id, '|', '-')
    end                                                                 as orderID
     , 'Trade'                                                          as event_type
     , to_char(tr.trade_record_time, 'YYYYMMDD')                        as event_date
     , to_char(tr.trade_record_time, 'HH24:MI:SS.US')                   as event_time
     , null::varchar                                                    as orig_cl_ord_id
     , tr.last_qty                                                      as event_qty
     , tr.last_px                                                       as event_price
     , case when cl.multileg_reporting_type = '2' then 'Y' else 'N' end as multi_leg_indicator
     , ml.no_legs                                                       as number_of_legs
     , cl.co_client_leg_ref_id                                          as leg_order_id
     , cl.ratio_qty::varchar                                            as leg_ratio
     , null                                                             as order_status  --  ???????????? status
     , oc.opra_symbol                                                   as osi_symbol
     , i.symbol                                                         as base_symbol
     , i.symbol || coalesce(' ' || i.symbol_suffix, '')                 as symbol
     , i.instrument_type_id                                             as security_type -- missed in EOS
     , ui.symbol                                                        as underlying_symbol
     , case oc.put_call
           when '0' then 'P'
           when '1' then 'C'
           else 'S'
    end                                                                 as put_call_stock
     , to_char(i.last_trade_date, 'YYYYMMDD')                           as expiration_date
     , case
           when cl.side in ('1', '3') then 'B'
           when i.instrument_type_id = 'O' and cl.side not in ('1', '3') then 'S'
           when cl.side = '2' then 'SL'
           when cl.side = '5' then 'SS'
           when cl.side = '6' then 'SX'
           else 'B'
    end                                                                 as side
     , tr.secondary_order_id                                            as cl_ord_id
     , to_char(cl.create_time, 'YYYYMMDD')::varchar                     as order_creation_date
     , to_char(cl.create_time, 'HH24:MI:SS.MS')::varchar                as order_creation_time
     , to_char(tr.trade_record_time, 'HH24:MI:SS.US')                   as executed_timestamp
     , tr.secondary_exch_exec_id                                        as exec_id       --coalesce(, tr.exch_exec_id)
     , 'N/A'::varchar                                                   as tape_trade_id
     , tr.last_mkt
     , dex.mic_code                                                     as mic_code
     --, coalesce( (compliance.get_sor_first_orig(in_order_id => tr.order_id, in_date_id => to_char(tr.order_process_time, 'YYYYMMDD')::integer)).out_cl_ord_id, tr.client_order_id ) as out_cl_ord_id
     , case
           when cl.trans_type = 'G' then coalesce((compliance.get_sor_first_orig(in_order_id => cl.order_id,
                                                                                 in_date_id => cl.create_date_id)).out_cl_ord_id,
                                                  cl.client_order_id)
           else cl.client_order_id end                                  as out_cl_ord_id
from dwh.flat_trade_record tr
         join t_base on t_base.order_id = tr.order_id
         left join d_account ac on ac.account_id = tr.account_id
         inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
         inner join d_instrument i on tr.instrument_id = i.instrument_id
         left join lateral
    (select oc.option_series_id, oc.opra_symbol, oc.put_call
     from d_option_contract oc
     where oc.instrument_id = tr.instrument_id
     limit 1) oc on true
         left join d_option_series os on os.option_series_id = oc.option_series_id
         left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
         inner join lateral
    (
    select cl.multileg_reporting_type,
           co_client_leg_ref_id,
           fix_connection_id,
           order_id,
           multileg_order_id,
           trans_type,
           client_order_id,
           side,
           ratio_qty,
           create_time,
           create_date_id
    from dwh.client_order cl
    where cl.order_id = tr.order_id
      and cl.create_date_id between to_char(tr.order_process_time, 'YYYYMMDD')::integer and :l_date_end_id
    limit 1
    ) cl on true
         inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
         left join lateral
    (select str.parent_order_id,
            count(*) filter (where str.exchange_id = 'C1PAR')      cpar_cnt,
            count(*) filter (where str.cross_order_id is not null) cross_cnt
     from client_order str
     where str.trans_type <> 'F'
       and str.parent_order_id is not null
       and str.create_date_id between :l_date_begin_id and :l_date_end_id
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
      and ml.create_date_id between :l_date_begin_id and :l_date_end_id
    limit 1
    ) ml on true
         left join d_exchange dex on tr.exchange_id = dex.exchange_id and dex.is_active = true
where tr.date_id between :l_date_begin_id and :l_date_end_id
  and tr.is_busted = 'N';


select * from t_base;
select * from t_parent_cancels;
select * from t_street_cancels;
select * from t_ord_status;
select * from t_trade;
select * from t_route;


drop table if exists t_result;
create temp table if not exists t_result as
select parent_order_id                          as "OrderID",
       trading_firm_name                        as "Trading Firm Name",
       tf_cat_imid                              as "Trading Firm IMID",
       tf_cat_crd                               as "Trading Firm CRD",
       order_type_value                         as "Event Type",

       to_char(x.process_time, 'MM/DD/YYYY')    as "Event Date",
       to_char(x.process_time, 'HH24:MI:SS:US') as "Event Time",
               x.client_order_id                                               as "Client clOrderID",
               case
               when x.trans_type = 'G' and rn = 1 then null
               else x.client_order_id end                             as "Street clOrderID",
               x.order_qty                                                     as "Event Qty",
               to_char(x.price, 'FM99999990D0099')                       as "Event Price",
               to_char(x.orig_price, 'FM99999990D0099')                         as "Net Price",
               case
                   when x.multileg_reporting_type <> '1' then 'Y'
                   else 'N'
                   end, -- as "Multi Leg Indicator",
               no_legs                                                       as "Number of legs",
               multileg_order_id                                             as "Leg Order ID",
               case
               when x.rn = 1 then 'true'
               else 'false' end                                    as "Manual Flag",
               x.tag_58                                                     as "Free Text",
               -- Order Detail
               order_status_description                                      as "Order Status",
               case
                   when order_type_value = 'New Order' then ''
                   else orig_client_order_id end                             as "Original Client clOrderID",
               case
                   when order_type_value = 'Order Route'
                       then orig_client_order_id end                         as "Original Street clOrderID",
               opra_symbol                                                   as "OSI Symbol",
               root_symbol                                                   as "Base symbol",
               symbol                                                        as "Symbol",
               case instrument_type_id
                   when 'O' then 'Option'
                   when 'E' then 'Equity'
                   else coalesce(instrument_type_id, '') end                 as "Security Type",

               underlying_symbol                                             as "Underlying Symbol",
               pcv                                                           as "P/C/S",
               to_char(last_trade_date, 'MM/DD/YYYY')                        as "Expiration Date",
               to_char(last_trade_date, 'HH24:MI:SS.MS')                     as "Expiration Time",
               case
                   when side = '1' then 'Buy'
                   when side = '2' then 'Sell'
                   when side in ('5', '6') then 'Sell Short'
                   end                                                       as "Side",
               tif                                                           as "TIF",
               to_char(coalesce(x.last_trade_date, x.expire_time), 'MM/DD/YYYY')                           as "Good Till Date",
               to_char(coalesce(x.last_trade_date, x.expire_time), 'HH24:MI:SS.MS')                        as "Good Till Time",
               order_qty                                                     as "Order Qty",
               ls.filled_qty                                                 as "Filled Qty",
               order_type_name                                               as "Order Type Code",
               to_char(price, 'FM99999990D0099')                       as "Order Price",
               to_char(process_time, 'DD.MM.YYYY')                      as "Order Creation Date",
               to_char(process_time, 'HH24:MI:SS.US')                   as "Order Creation Time",
               open_close                                                    as "Open/Close",
               trading_session::varchar                                      as "Trading Session",
               is_held                                                       as "Is Held",
                case
               when x.cross_order_id is not null then 'Y'
               else 'N' end                                                      as "Is Cross",
               fee_sensitivity                                               as "Fee Sensitivity",
               to_char(stop_price, 'FM99999990D0099')                        as "Stop Price",
               max_floor                                                     as "Max Floor",
               customer_or_firm_name                                         as "Capacity",
               ex_destination                                                as "ExDestination",
               ratio_qty                                                     as "Leg ratio",
               user_                                                         as "User",

-- Account Details
               account_name                                                  as "Account Name",
               account_id                                                    as "Account ID",
               account_holder_type                                           as "Account Holder Type",
               ac_fdid                                                       as "Account FDID",
               ac_imid::text                                                 as "Account IMID",
               ac_number                                                     as "Account CRD",
               sender_sub_id                                                 as "Sender Type",

               -- Execution Details
               last_mkt                                                      as "Last Mkt",
               mic_code                                                      as "MIC Code",
               trade_liquidity_indicator                                     as "Liquidity Indicator",
               exec_id                                                       as "ExecutionID",
               ac_imid                                                       as "CAT Reporting Firm IMID",
               to_char(case
                           when event_type = 'Cancelled' then cancel_request_time
                           when event_type ilike '%modify%' then order_request_time
                           end, 'DD.MM.YYYY')                                as "Request Date",
               to_char(case
                           when event_type = 'Cancelled' then cancel_request_time
                           when event_type ilike '%modify%' then order_request_time
                           end, 'HH24:MI:SS.US')                             as "Request Time",
               to_char(strike_price, 'FM99999990D0099')                      as "Strike Price",
               case
                   when event_type = 'New Order' then event_qty
                   when event_type = 'Trade' then remaining_qty end
                                                                             as "Remaining Qty",
               is_affiliate                                                  as "Affiliated Flag",
               solicitation                                                  as "Solicitation Flag"
from
    (select tr.order_type_value, tb.*, tr.rn
               from t_base tb
                        join t_route tr on tr.trans_type = tb.trans_type
               where tb.parent_order_id is null
                 and tb.cat_report_on_behalf_of = 'N'
               union all
               select case when tb.cat_report_on_behalf_of != 'N' then 'New' else 'Ack' end, tb.*, 3
               from t_base tb
                        left join t_route tr on tr.trans_type = tb.trans_type and tr.trans_type = 'N'
               where tb.parent_order_id is null
--                  and tb.cat_report_on_behalf_of = 'N'
               ) x

    left join lateral
          (
          select ls.order_id, ls.order_status, ls.filled_qty, ls.last_mkt, ls.order_status_description
          from t_ord_status ls
          where ls.order_id = x.order_id
          limit 1
          ) ls on true
order by order_id, rn
