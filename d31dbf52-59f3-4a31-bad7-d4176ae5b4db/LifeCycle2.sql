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
select coalesce(staging.last_orig_order(cl.order_id), cl.order_id) as first_order_id,
       cl.*,
       di.symbol,
       di.symbol_suffix,
       di.instrument_type_id,
       di.last_trade_date,
       ac.cat_report_on_behalf_of,
       tf.trading_firm_name,
       tf.cat_imid                                                 as tf_cat_imid,
       tf.cat_crd                                                  as tf_cat_crd,
       orig.client_order_id                                        as orig_client_order_id,
       orig.price                                                  as orig_price,
       oc.opra_symbol,
       oc.strike_price,
       os.root_symbol,
       ui.symbol                                                   as underlying_symbol,
       fmj.tag_58,
       fmj.tag_50,
       fmj.tag_109,
       case
           when di.instrument_type_id = 'E' then 'Stock'
           when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
           when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
           end                                                     as pcv,
       dtif.tif_short_name                                         as tif,
       dot.order_type_name,
       case
           when tag_9281 in ('A', 'D', 'G') then 'ALL'
           when tag_22017 = 'A' then 'ALL'
           when tag_9281 in ('F', 'C') then 'REGPOST'
           when tag_22017 = 'B' then 'REGPOST'
           else 'REG' end                                          as trading_session,
       cof.customer_or_firm_name,
       ac.account_name,
       ac.account_holder_type,
       ac.cat_fdid,
       ac.crd_number,
       tf.cat_imid,
       ac.is_affiliate,
       case
           when ac.cat_fdid like coalesce(ac.crd_number, '') || ':' || coalesce(tf.cat_imid, '')
               then tf.cat_imid end                                as ac_imid,
       case
           when ac.cat_fdid like coalesce(ac.crd_number, '') || ':' || coalesce(tf.cat_imid, '')
               then ac.crd_number end                              as ac_number,
       fc.sender_sub_id,
       to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                       as order_request_time,
       case when cl.ex_destination = 'DASH' then 'Y' else 'N' end  as is_solicitation,
       to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                       as tag_5050
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
         left join lateral (select fmj.fix_message ->> '5050'  as tag_5050,
                                   fmj.fix_message ->> '50'    as tag_50,
                                   fmj.fix_message ->> '109'   as tag_109,
                                   -- fmj.fix_message ->> '9000'  as tag_9000,
                                   fmj.fix_message ->> '58'    as tag_58,
                                   -- fmj.fix_message ->> '17'    as tag_17,
                                   -- fmj.fix_message ->> '52'    as tag_52,
                                   -- fmj.fix_message ->> '9291'  as tag_9291,
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
select coalesce(staging.last_orig_order(cl.order_id), cl.order_id) as first_order_id,
       cl.*,
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
       par.tag_50,
       par.tag_109,
       par.pcv,
       par.tif,
       par.order_type_name,
       par.trading_session,
       par.customer_or_firm_name,
       par.account_name,
       par.account_holder_type,
       par.cat_fdid,
       par.crd_number,
       par.cat_imid,
       par.is_affiliate,
       par.ac_imid,
       par.ac_number,
       par.sender_sub_id,
       par.order_request_time,
       par.is_solicitation,
       par.tag_5050
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
select cl.*,
       ex.exec_date_id,
       ex.exec_time,
       ex.cum_qty,
       to_timestamp(left(nxt.nxt_tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC' as cancel_request_time
from t_base cl
         inner join lateral (select ex.exec_date_id,
                                    ex.exec_time as exec_time,
                                    ex.cum_qty
                             from execution ex
                             where ex.order_id = cl.order_id
                               and ex.exec_date_id between :l_date_begin_id and :l_date_end_id
                               and ex.is_parent_level = true
                               and case
                                       when ex.exec_type = '4' then true
                                       when ex.order_status = '4' then true
                                       else false end) ex on true
         left join lateral (select fmj.fix_message ->> '60' as nxt_tag_60
                            from dwh.client_order nxt
                                     join fix_capture.fix_message_json fmj
                                          on fmj.fix_message_id = nxt.fix_message_id and
                                             fmj.date_id = nxt.create_date_id
                            where nxt.create_date_id >= cl.create_date_id
                              and nxt.orig_order_id = cl.order_id
                              and nxt.create_date_id >= :l_date_begin_id
                              and nxt.create_date_id <= :l_date_end_id
                            limit 1) nxt on true
where true
  and cl.parent_order_id is null
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
     , trade_liquidity_indicator
     , exec_id
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
         , trade_liquidity_indicator
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
select b.first_order_id,
       b.order_id                                                                              as parent_order_id,
       -----
       b.orig_client_order_id,
       3                                                                                       as rn,
--                             b.leg_cl_ord_id, b.client_order_id,
       b.client_order_id                                                                       as client_order_id,
--                     ex.secondary_exch_exec_id                                      as exec_id,
       tag_17                                                                                  as exec_id,
       b.trading_firm_name                                                                     as trading_firm_name,
--                     b.cat_imid,
       b.tf_cat_imid                                                                           as tf_cat_imid,
--                     b.cat_crd,
       b.tf_cat_crd                                                                            as tf_cat_crd,
       case
           when ex.exec_type in ('A', '0', '5') then 'Order Ack'
           when ex.exec_type = '4' then 'Cancelled'
           else et.exec_type_description end                                                   as event_type,
       case
           when ex.exec_type in ('A', '0', '5', 's') then
               b.tag_5050
           when ex.exec_type = '4' then
               ex.exec_time::timestamp
           else
               to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'
           end                                                                                 as event_ts,
       b.client_order_id::text                                                                 as street_client_order_id,
       b.order_qty                                                                             as event_qty,
       b.price                                                                                 as event_price,
--        null::numeric                                                                           as net_price,
       b.orig_price                                                                            as net_price,
       b.multileg_reporting_type                                                               as multileg_indicator,
       b.no_legs::int4,
       b.co_client_leg_ref_id                                                                  as multileg_order_id,
       case
           when ex.exec_type in ('A', 'F', '5', 'W', '4') then 'false'
           else '' end                                                                         as manual_flag,
       case when ex.exec_type not in ('A', '0', '5') then ex.exec_text end                     as exec_text,
       os.order_status_description,
       b.opra_symbol,
       b.root_symbol,
       b.symbol,
       b.instrument_type_id,
       case
           when b.instrument_type_id = 'M' then (select underlying_symbol
                                                 from t_base
                                                 where t_base.multileg_order_id = b.order_id
                                                 limit 1)
           else b.underlying_symbol end                                                        as underlying_symbol,
       b.pcv,
       coalesce(b.last_trade_date, ex.exec_time)                                               as expiration_ts,
       b.side,
       b.tif,
       b.expire_time                                                                           as good_till_ts,
       ex.cum_qty                                                                              as cum_qty,
--        fmj.tag_14                                                                              as cum_qty,
       b.order_type_name,
       ex.exec_time                                                                            as order_creation_ts,
--        to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'      as order_creation_ts,
       b.open_close,
--           compliance.get_sor_trading_session(b.order_id, b.instrument_type_id, b.create_date_id)    as trading_session,
       case
           when fmj.tag_9281 in ('A', 'D', 'G') or fmj.tag_22017 = 'A' then 'ALL'
           when fmj.tag_9281 in ('F', 'C') or fmj.tag_22017 = 'B' then 'REGPOST'
           else 'REG' end                                                                      as trading_session,
       b.is_held                                                                               as is_held,
       case
           when b.cross_order_id is not null then 'Y'
           else 'N' end                                                                        as is_cross,
       b.fee_sensitivity,
       b.stop_price,
       b.max_floor,
       b.customer_or_firm_name,
--        b.par_tag_9000                                                                          as ex_destination,
       b.ex_destination                                                                        as ex_destination,
       b.ratio_qty,
       coalesce(fmj.tag_50, fmj.tag_109, b.account_name)                                       as user_,
       b.account_name                                                                          as account_name,
--        null                                                                                    as account_name,
       b.account_id                                                                            as account_id,
--        null::int                                                                               as account_id,
       b.account_holder_type,
       b.cat_fdid,
       b.ac_imid,
       b.ac_number,
--         ac.broker_dealer_mpid,
       b.sender_sub_id,

       -- Execution Details
       ex.last_mkt,
       exc.mic_code,
       ex.trade_liquidity_indicator,
       case when ex.exec_type = 'F' then ex.exec_time end                                      as trade_exec_time,
       ex.exec_type,
       case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then tf.cat_imid end   as cat_imid,
       case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then ac.crd_number end as crd_number,
       order_request_time,
--            cancel_request_time,
       strike_price,
       b.order_qty - coalesce(ex.cum_qty, 0)                                                   as remaining_qty,
       b.is_affiliate,
       null                                                                                    as solicitation
from t_base b
         left join dwh.d_account ac on b.account_id = ac.account_id and ac.is_active
         left join dwh.d_trading_firm tf on b.trading_firm_unq_id = tf.trading_firm_unq_id
         left join dwh.execution ex
                   on ex.order_id = b.order_id and ex.exec_date_id >= b.create_date_id
                       and ex.exec_type not in ('a', 'A', 'S', '0')
         left join lateral (select fmj.fix_message ->> '10061'          as tag_10061,
                                   coalesce(fmj.fix_message ->> '5050',
                                            fmj.fix_message ->> '5051') as tag_5050,

                                   fmj.fix_message ->> '50'             as tag_50,
                                   fmj.fix_message ->> '109'            as tag_109,
                                   fmj.fix_message ->> '17'             as tag_17,

                                   fmj.fix_message ->> '9281'           as tag_9281,
                                   fmj.fix_message ->> '22017'          as tag_22017
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = ex.fix_message_id
                              and fmj.date_id >= ex.exec_date_id
                            limit 1) fmj on true
         left join dwh.d_order_status os on ex.order_status = os.order_status
         join dwh.d_exec_type et on et.exec_type = ex.exec_type
         left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active;


select * from t_base;
select * from t_parent_cancels;
select * from t_street_cancels;
select * from t_ord_status;
select * from t_trade;
select * from t_route;


drop table if exists t_result;
create temp table if not exists t_result as
    -- Parent 'D'
select x.order_id                                                           as "OrderID",
       trading_firm_name                                                    as "Trading Firm Name",
       tf_cat_imid                                                          as "Trading Firm IMID",
       tf_cat_crd                                                           as "Trading Firm CRD",
       order_type_value                                                     as "Event Type",

       to_char(x.process_time, 'MM/DD/YYYY')                                as "Event Date",
       to_char(x.process_time, 'HH24:MI:SS:US')                             as "Event Time",
       x.client_order_id                                                    as "Client clOrderID",
       case
           when x.trans_type = 'G' and rn = 1 then null
           else x.client_order_id end                                       as "Street clOrderID",
       x.order_qty                                                          as "Event Qty",
       to_char(x.price, 'FM99999990D0099')                                  as "Event Price",
       to_char(x.orig_price, 'FM99999990D0099')                             as "Net Price",
       case
           when x.multileg_reporting_type <> '1' then 'Y'
           else 'N'
           end                                                              as "Multi Leg Indicator",
       no_legs                                                              as "Number of legs",
       multileg_order_id                                                    as "Leg Order ID",
       'false'                                                              as "Manual Flag",
       x.tag_58                                                             as "Free Text",
       -- Order Detail
       order_status_description                                             as "Order Status",
       null::text                                                           as "Original Client clOrderID",
       null::text                                                           as "Original Street clOrderID",
       opra_symbol                                                          as "OSI Symbol",
       root_symbol                                                          as "Base symbol",
       symbol                                                               as "Symbol",
       case instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           else coalesce(instrument_type_id, '') end                        as "Security Type",

       underlying_symbol                                                    as "Underlying Symbol",
       pcv                                                                  as "P/C/S",
       to_char(last_trade_date, 'MM/DD/YYYY')                               as "Expiration Date",
       to_char(last_trade_date, 'HH24:MI:SS.MS')                            as "Expiration Time",
       case
           when side = '1' then 'Buy'
           when side = '2' then 'Sell'
           when side in ('5', '6') then 'Sell Short'
           end                                                              as "Side",
       tif                                                                  as "TIF",
       to_char(coalesce(x.last_trade_date, x.expire_time), 'MM/DD/YYYY')    as "Good Till Date",
       to_char(coalesce(x.last_trade_date, x.expire_time), 'HH24:MI:SS.MS') as "Good Till Time",
       order_qty                                                            as "Order Qty",
       ls.filled_qty                                                        as "Filled Qty",
       order_type_name                                                      as "Order Type Code",
       to_char(price, 'FM99999990D0099')                                    as "Order Price",
       to_char(process_time, 'DD.MM.YYYY')                                  as "Order Creation Date",
       to_char(process_time, 'HH24:MI:SS.US')                               as "Order Creation Time",
       open_close                                                           as "Open/Close",
       trading_session::varchar                                             as "Trading Session",
       is_held                                                              as "Is Held",
       case
           when x.cross_order_id is not null then 'Y'
           else 'N' end                                                     as "Is Cross",
       fee_sensitivity                                                      as "Fee Sensitivity",
       to_char(stop_price, 'FM99999990D0099')                               as "Stop Price",
       max_floor                                                            as "Max Floor",
       customer_or_firm_name                                                as "Capacity",
       ex_destination                                                       as "ExDestination",
       ratio_qty                                                            as "Leg ratio",
       coalesce(x.tag_50, x.tag_109, x.account_name)                        as "User",

-- Account Details
       account_name                                                         as "Account Name",
       account_id                                                           as "Account ID",
       account_holder_type                                                  as "Account Holder Type",
       cat_fdid                                                             as "Account FDID",
       ac_imid                                                              as "Account IMID",
       ac_number                                                            as "Account CRD",
       sender_sub_id                                                        as "Sender Type",

       -- Execution Details
       last_mkt                                                             as "Last Mkt",
       null                                                                 as "MIC Code",
       trade_liquidity_indicator                                            as "Liquidity Indicator",
       exec_id                                                              as "ExecutionID",
       ac_imid                                                              as "CAT Reporting Firm IMID",
       null::text                                                           as "Request Date",
       null::text                                                           as "Request Time",
       to_char(strike_price, 'FM99999990D0099')                             as "Strike Price",
       case
           when order_type_value = 'New Order' then order_qty
           end
                                                                            as "Remaining Qty",
       is_affiliate                                                         as "Affiliated Flag",
       is_solicitation                                                      as "Solicitation Flag",
       'parent',
       x.order_id,
       x.rn,
       x.kind_of_type
from (select tr.order_type_value, tb.*, tr.rn, 'syntetic' as kind_of_type
      from t_base tb
               join t_route tr on tr.trans_type = tb.trans_type
      where tb.parent_order_id is null
        and tb.cat_report_on_behalf_of = 'N'
        and tb.trans_type = 'D'
      union all
      select case when tb.cat_report_on_behalf_of != 'N' then 'New' else 'Ack' end, tb.*, 3, 'natural' as kind_of_type
      from t_base tb
               left join t_route tr on tr.trans_type = tb.trans_type and tr.trans_type = 'N'
      where tb.parent_order_id is null
        and tb.trans_type = 'D'
--                  and tb.cat_report_on_behalf_of = 'N'
     ) x

         left join lateral
    (
    select ls.order_id,
           ls.order_status,
           ls.filled_qty,
           ls.last_mkt,
           ls.order_status_description,
           ls.trade_liquidity_indicator,
           ls.exec_id
    from t_ord_status ls
    where ls.order_id = x.order_id
    limit 1
    ) ls on true;


-- Parent 'G'
insert into t_result
select x.order_id                                                                         as "OrderID",
       trading_firm_name                                                                  as "Trading Firm Name",
       tf_cat_imid                                                                        as "Trading Firm IMID",
       tf_cat_crd                                                                         as "Trading Firm CRD",
       order_type_value                                                                   as "Event Type",

       to_char(x.process_time, 'MM/DD/YYYY')                                              as "Event Date",
       to_char(x.process_time, 'HH24:MI:SS:US')                                           as "Event Time",
       x.client_order_id                                                                  as "Client clOrderID",
       case
           when x.trans_type = 'G' and rn = 1 then null
           else x.client_order_id end                                                     as "Street clOrderID",
       x.order_qty                                                                        as "Event Qty",
       case when order_type_id in ('2', '4') then to_char(x.price, 'FM99999990D0099') end as "Event Price",
       to_char(x.orig_price, 'FM99999990D0099')                                           as "Net Price",
       case
           when x.multileg_reporting_type <> '1' then 'Y'
           else 'N'
           end                                                                            as "Multi Leg Indicator",
       no_legs                                                                            as "Number of legs",
       multileg_order_id                                                                  as "Leg Order ID",
       'false'                                                                            as "Manual Flag",
       x.tag_58                                                                           as "Free Text",
       -- Order Detail
       order_status_description                                                           as "Order Status",
       orig_client_order_id                                                               as "Original Client clOrderID",
       null                                                                               as "Original Street clOrderID",
       opra_symbol                                                                        as "OSI Symbol",
       root_symbol                                                                        as "Base symbol",
       symbol                                                                             as "Symbol",
       case instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           else coalesce(instrument_type_id, '') end                                      as "Security Type",

       underlying_symbol                                                                  as "Underlying Symbol",
       pcv                                                                                as "P/C/S",
       to_char(last_trade_date, 'MM/DD/YYYY')                                             as "Expiration Date",
       to_char(last_trade_date, 'HH24:MI:SS.MS')                                          as "Expiration Time",
       case
           when side = '1' then 'Buy'
           when side = '2' then 'Sell'
           when side in ('5', '6') then 'Sell Short'
           end                                                                            as "Side",
       tif                                                                                as "TIF",
       to_char(coalesce(x.last_trade_date, x.expire_time), 'MM/DD/YYYY')                  as "Good Till Date",
       to_char(coalesce(x.last_trade_date, x.expire_time), 'HH24:MI:SS.MS')               as "Good Till Time",
       order_qty                                                                          as "Order Qty",
       ls.filled_qty                                                                      as "Filled Qty",
       order_type_name                                                                    as "Order Type Code",
       case when order_type_id in ('2') then to_char(price, 'FM99999990D0099') end        as "Order Price",
       to_char(process_time, 'DD.MM.YYYY')                                                as "Order Creation Date",
       to_char(process_time, 'HH24:MI:SS.US')                                             as "Order Creation Time",
       open_close                                                                         as "Open/Close",
       trading_session::varchar                                                           as "Trading Session",
       is_held                                                                            as "Is Held",
       case
           when x.cross_order_id is not null then 'Y'
           else 'N' end                                                                   as "Is Cross",
       fee_sensitivity                                                                    as "Fee Sensitivity",
       to_char(stop_price, 'FM99999990D0099')                                             as "Stop Price",
       max_floor                                                                          as "Max Floor",
       customer_or_firm_name                                                              as "Capacity",
       ex_destination                                                                     as "ExDestination",
       ratio_qty                                                                          as "Leg ratio",
       coalesce(x.tag_50, x.tag_109, x.account_name)                                      as "User",

-- Account Details
       account_name                                                                       as "Account Name",
       account_id                                                                         as "Account ID",
       account_holder_type                                                                as "Account Holder Type",
       cat_fdid                                                                           as "Account FDID",
       ac_imid                                                                            as "Account IMID",
       ac_number                                                                          as "Account CRD",
       sender_sub_id                                                                      as "Sender Type",

       -- Execution Details
       last_mkt                                                                           as "Last Mkt",
       null                                                                               as "MIC Code",
       trade_liquidity_indicator                                                          as "Liquidity Indicator",
       exec_id                                                                            as "ExecutionID",
       ac_imid                                                                            as "CAT Reporting Firm IMID",
       to_char(order_request_time, 'DD.MM.YYYY')                                          as "Request Date",
       to_char(order_request_time, 'HH24:MI:SS.US')                                       as "Request Time",
       to_char(strike_price, 'FM99999990D0099')                                           as "Strike Price",
       case
           when order_type_value = 'New Order' then order_qty
           end
                                                                                          as "Remaining Qty",
       is_affiliate                                                                       as "Affiliated Flag",
       is_solicitation                                                                    as "Solicitation Flag",
       'parent modify',
       x.order_id,
       x.rn,
       x.kind_of_type
from (select tr.order_type_value, tb.*, tr.rn, 'syntetic' as kind_of_type
      from t_base tb
               join t_route tr on tr.trans_type = tb.trans_type
      where tb.parent_order_id is null
        and tb.cat_report_on_behalf_of = 'N'
        and tb.trans_type = 'G'
      union all
      select case when tb.cat_report_on_behalf_of != 'N' then 'Order Modify' else 'Ack' end,
             tb.*,
             3,
             'natural' as kind_of_type
      from t_base tb
               left join t_route tr on tr.trans_type = tb.trans_type and tr.trans_type = 'N'
      where tb.parent_order_id is null
        and tb.trans_type = 'G'
--                  and tb.cat_report_on_behalf_of = 'N'
     ) x

         left join lateral
    (
    select ls.order_id,
           ls.order_status,
           ls.filled_qty,
           ls.last_mkt,
           ls.order_status_description,
           ls.trade_liquidity_indicator,
           ls.exec_id
    from t_ord_status ls
    where ls.order_id = x.order_id
    limit 1
    ) ls on true;

insert into t_result
-- Parent cancels
select x.order_id                                                                         as "OrderID",
       trading_firm_name                                                                  as "Trading Firm Name",
       tf_cat_imid                                                                        as "Trading Firm IMID",
       tf_cat_crd                                                                         as "Trading Firm CRD",
       'Cancelled'                                                                        as "Event Type",
       to_char(x.create_time, 'MM/DD/YYYY')                                               as "Event Date",
       to_char(x.create_time, 'HH24:MI:SS:MS')                                            as "Event Time",
       x.client_order_id                                                                  as "Client clOrderID",
       x.client_order_id                                                                  as "Street clOrderID",
       x.order_qty                                                                        as "Event Qty",
       case when order_type_id in ('2', '4') then to_char(x.price, 'FM99999990D0099') end as "Event Price",
       to_char(x.orig_price, 'FM99999990D0099')                                           as "Net Price",
       case
           when x.multileg_reporting_type <> '1' then 'Y'
           else 'N'
           end                                                                            as "Multi Leg Indicator",
       no_legs                                                                            as "Number of legs",
       multileg_order_id                                                                  as "Leg Order ID",
       'false'                                                                            as "Manual Flag",
       x.tag_58                                                                           as "Free Text",
       -- Order Detail
       order_status_description                                                           as "Order Status",
       null                                                                               as "Original Client clOrderID",
       null                                                                               as "Original Street clOrderID",
       opra_symbol                                                                        as "OSI Symbol",
       root_symbol                                                                        as "Base symbol",
       symbol                                                                             as "Symbol",
       case instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           else coalesce(instrument_type_id, '') end                                      as "Security Type",

       underlying_symbol                                                                  as "Underlying Symbol",
       pcv                                                                                as "P/C/S",
       to_char(last_trade_date, 'MM/DD/YYYY')                                             as "Expiration Date",
       to_char(last_trade_date, 'HH24:MI:SS.MS')                                          as "Expiration Time",
       case
           when side = '1' then 'Buy'
           when side = '2' then 'Sell'
           when side in ('5', '6') then 'Sell Short'
           end                                                                            as "Side",
       tif                                                                                as "TIF",
       to_char(coalesce(x.last_trade_date, x.expire_time), 'MM/DD/YYYY')                  as "Good Till Date",
       to_char(coalesce(x.last_trade_date, x.expire_time), 'HH24:MI:SS.MS')               as "Good Till Time",
       order_qty                                                                          as "Order Qty",
       ls.filled_qty                                                                      as "Filled Qty",
       order_type_name                                                                    as "Order Type Code",
       case when order_type_id in ('2') then to_char(price, 'FM99999990D0099') end        as "Order Price",
       to_char(process_time, 'DD.MM.YYYY')                                                as "Order Creation Date",
       to_char(process_time, 'HH24:MI:SS.US')                                             as "Order Creation Time",
       open_close                                                                         as "Open/Close",
       trading_session::varchar                                                           as "Trading Session",
       is_held                                                                            as "Is Held",
       case
           when x.cross_order_id is not null then 'Y'
           else 'N' end                                                                   as "Is Cross",
       fee_sensitivity                                                                    as "Fee Sensitivity",
       to_char(stop_price, 'FM99999990D0099')                                             as "Stop Price",
       max_floor                                                                          as "Max Floor",
       customer_or_firm_name                                                              as "Capacity",
       ex_destination                                                                     as "ExDestination",
       ratio_qty                                                                          as "Leg ratio",
       coalesce(x.tag_50, x.tag_109, x.account_name)                                      as "User",

-- Account Details
       account_name                                                                       as "Account Name",
       account_id                                                                         as "Account ID",
       account_holder_type                                                                as "Account Holder Type",
       cat_fdid                                                                           as "Account FDID",
       ac_imid                                                                            as "Account IMID",
       ac_number                                                                          as "Account CRD",
       sender_sub_id                                                                      as "Sender Type",

       -- Execution Details
       last_mkt                                                                           as "Last Mkt",
       null                                                                               as "MIC Code",
       trade_liquidity_indicator                                                          as "Liquidity Indicator",
       exec_id                                                                            as "ExecutionID",
       ac_imid                                                                            as "CAT Reporting Firm IMID",
       to_char(cancel_request_time, 'DD.MM.YYYY')                                         as "Request Date",
       to_char(cancel_request_time, 'HH24:MI:SS.US')                                      as "Request Time",
       to_char(strike_price, 'FM99999990D0099')                                           as "Strike Price",
       null                                                                               as "Remaining Qty",
       is_affiliate                                                                       as "Affiliated Flag",
       is_solicitation                                                                    as "Solicitation Flag",
       'parent cancel',
       x.order_id,
       4,
       'natural'
from t_parent_cancels x

         left join lateral
    (
    select ls.order_id,
           ls.order_status,
           ls.filled_qty,
           ls.last_mkt,
           ls.order_status_description,
           ls.trade_liquidity_indicator,
           ls.exec_id
    from t_ord_status ls
    where ls.order_id = x.order_id
    limit 1
    ) ls on true;


insert into t_result
-- Street 'D'
select tb.parent_order_id                                                     as "OrderID",
       tb.trading_firm_name                                                   as "Trading Firm Name",
       tb.tf_cat_imid                                                         as "Trading Firm IMID",
       tb.tf_cat_crd                                                          as "Trading Firm CRD",
       'Order Route'                                                          as "Event Type",

       to_char(tb.process_time, 'MM/DD/YYYY')                                 as "Event Date",
       to_char(tb.process_time, 'HH24:MI:SS:US')                              as "Event Time",
       tb.client_order_id                                                     as "Client clOrderID",
       case
           when tb.trans_type = 'G' and rn = 1 then null
           else tb.client_order_id end                                        as "Street clOrderID",
       tb.order_qty                                                           as "Event Qty",
       to_char(tb.price, 'FM99999990D0099')                                   as "Event Price",
       to_char(tb.orig_price, 'FM99999990D0099')                              as "Net Price",
       case
           when tb.multileg_reporting_type <> '1' then 'Y'
           else 'N'
           end                                                                as "Multi Leg Indicator",
       tb.no_legs                                                             as "Number of legs",
       tb.multileg_order_id                                                   as "Leg Order ID",
       'false'                                                                as "Manual Flag",
       tb.tag_58                                                              as "Free Text",
       -- Order Detail
       ls.order_status_description                                            as "Order Status",
       null::text                                                             as "Original Client clOrderID",
       null::text                                                             as "Original Street clOrderID",
       tb.opra_symbol                                                         as "OSI Symbol",
       tb.root_symbol                                                         as "Base symbol",
       tb.symbol                                                              as "Symbol",
       case tb.instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           else coalesce(tb.instrument_type_id, '') end                       as "Security Type",

       underlying_symbol                                                      as "Underlying Symbol",
       pcv                                                                    as "P/C/S",
       to_char(last_trade_date, 'MM/DD/YYYY')                                 as "Expiration Date",
       to_char(last_trade_date, 'HH24:MI:SS.MS')                              as "Expiration Time",
       case
           when side = '1' then 'Buy'
           when side = '2' then 'Sell'
           when side in ('5', '6') then 'Sell Short'
           end                                                                as "Side",
       tif                                                                    as "TIF",
       to_char(coalesce(tb.last_trade_date, tb.expire_time), 'MM/DD/YYYY')    as "Good Till Date",
       to_char(coalesce(tb.last_trade_date, tb.expire_time), 'HH24:MI:SS.MS') as "Good Till Time",
       order_qty                                                              as "Order Qty",
       ls.filled_qty                                                          as "Filled Qty",
       order_type_name                                                        as "Order Type Code",
       to_char(price, 'FM99999990D0099')                                      as "Order Price",
       to_char(process_time, 'DD.MM.YYYY')                                    as "Order Creation Date",
       to_char(process_time, 'HH24:MI:SS.US')                                 as "Order Creation Time",
       open_close                                                             as "Open/Close",
       trading_session::varchar                                               as "Trading Session",
       is_held                                                                as "Is Held",
       case
           when tb.cross_order_id is not null then 'Y'
           else 'N' end                                                       as "Is Cross",
       fee_sensitivity                                                        as "Fee Sensitivity",
       to_char(stop_price, 'FM99999990D0099')                                 as "Stop Price",
       max_floor                                                              as "Max Floor",
       customer_or_firm_name                                                  as "Capacity",
       ex_destination                                                         as "ExDestination",
       ratio_qty                                                              as "Leg ratio",
       coalesce(tb.tag_50, tb.tag_109, tb.account_name)                       as "User",

-- Account Details
       account_name                                                           as "Account Name",
       account_id                                                             as "Account ID",
       account_holder_type                                                    as "Account Holder Type",
       cat_fdid                                                               as "Account FDID",
       ac_imid                                                                as "Account IMID",
       ac_number                                                              as "Account CRD",
       sender_sub_id                                                          as "Sender Type",

       -- Execution Details
       last_mkt                                                               as "Last Mkt",
       null                                                                   as "MIC Code",
       trade_liquidity_indicator                                              as "Liquidity Indicator",
       exec_id                                                                as "ExecutionID",
       ac_imid                                                                as "CAT Reporting Firm IMID",
       null::text                                                             as "Request Date",
       null::text                                                             as "Request Time",
       to_char(strike_price, 'FM99999990D0099')                               as "Strike Price",
       case
           when order_type_value = 'New Order' then order_qty
           end
                                                                              as "Remaining Qty",
       is_affiliate                                                           as "Affiliated Flag",
       is_solicitation                                                        as "Solicitation Flag",
       'parent',
       tb.order_id,
       5,
       'natural'
from t_base tb
         left join t_route tr on tr.trans_type = tb.trans_type and tr.trans_type = 'N'
         left join lateral
    (
    select ls.order_id,
           ls.order_status,
           ls.filled_qty,
           ls.last_mkt,
           ls.order_status_description,
           ls.trade_liquidity_indicator,
           ls.exec_id
    from t_ord_status ls
    where ls.order_id = tb.order_id
    limit 1
    ) ls on true
where tb.parent_order_id is not null
  and tb.trans_type = 'D'
;



insert into t_result
-- Street 'G'
select tb.parent_order_id                                                     as "OrderID",
       tb.trading_firm_name                                                   as "Trading Firm Name",
       tb.tf_cat_imid                                                         as "Trading Firm IMID",
       tb.tf_cat_crd                                                          as "Trading Firm CRD",
       'Order Route'                                                          as "Event Type",

       to_char(tb.process_time, 'MM/DD/YYYY')                                 as "Event Date",
       to_char(tb.process_time, 'HH24:MI:SS:US')                              as "Event Time",
       tb.client_order_id                                                     as "Client clOrderID",
       case
           when tb.trans_type = 'G' and rn = 1 then null
           else tb.client_order_id end                                        as "Street clOrderID",
       tb.order_qty                                                           as "Event Qty",
       to_char(tb.price, 'FM99999990D0099')                                   as "Event Price",
       to_char(tb.orig_price, 'FM99999990D0099')                              as "Net Price",
       case
           when tb.multileg_reporting_type <> '1' then 'Y'
           else 'N'
           end                                                                as "Multi Leg Indicator",
       tb.no_legs                                                             as "Number of legs",
       tb.multileg_order_id                                                   as "Leg Order ID",
       'false'                                                                as "Manual Flag",
       tb.tag_58                                                              as "Free Text",
       -- Order Detail
       ls.order_status_description                                            as "Order Status",
       null::text                                                             as "Original Client clOrderID",
       null::text                                                             as "Original Street clOrderID",
       tb.opra_symbol                                                         as "OSI Symbol",
       tb.root_symbol                                                         as "Base symbol",
       tb.symbol                                                              as "Symbol",
       case tb.instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           else coalesce(tb.instrument_type_id, '') end                       as "Security Type",

       underlying_symbol                                                      as "Underlying Symbol",
       pcv                                                                    as "P/C/S",
       to_char(last_trade_date, 'MM/DD/YYYY')                                 as "Expiration Date",
       to_char(last_trade_date, 'HH24:MI:SS.MS')                              as "Expiration Time",
       case
           when side = '1' then 'Buy'
           when side = '2' then 'Sell'
           when side in ('5', '6') then 'Sell Short'
           end                                                                as "Side",
       tif                                                                    as "TIF",
       to_char(coalesce(tb.last_trade_date, tb.expire_time), 'MM/DD/YYYY')    as "Good Till Date",
       to_char(coalesce(tb.last_trade_date, tb.expire_time), 'HH24:MI:SS.MS') as "Good Till Time",
       order_qty                                                              as "Order Qty",
       ls.filled_qty                                                          as "Filled Qty",
       order_type_name                                                        as "Order Type Code",
       to_char(price, 'FM99999990D0099')                                      as "Order Price",
       to_char(process_time, 'DD.MM.YYYY')                                    as "Order Creation Date",
       to_char(process_time, 'HH24:MI:SS.US')                                 as "Order Creation Time",
       open_close                                                             as "Open/Close",
       trading_session::varchar                                               as "Trading Session",
       is_held                                                                as "Is Held",
       case
           when tb.cross_order_id is not null then 'Y'
           else 'N' end                                                       as "Is Cross",
       fee_sensitivity                                                        as "Fee Sensitivity",
       to_char(stop_price, 'FM99999990D0099')                                 as "Stop Price",
       max_floor                                                              as "Max Floor",
       customer_or_firm_name                                                  as "Capacity",
       ex_destination                                                         as "ExDestination",
       ratio_qty                                                              as "Leg ratio",
       coalesce(tb.tag_50, tb.tag_109, tb.account_name)                       as "User",

-- Account Details
       account_name                                                           as "Account Name",
       account_id                                                             as "Account ID",
       account_holder_type                                                    as "Account Holder Type",
       cat_fdid                                                               as "Account FDID",
       ac_imid                                                                as "Account IMID",
       ac_number                                                              as "Account CRD",
       sender_sub_id                                                          as "Sender Type",

       -- Execution Details
       last_mkt                                                               as "Last Mkt",
       null                                                                   as "MIC Code",
       trade_liquidity_indicator                                              as "Liquidity Indicator",
       exec_id                                                                as "ExecutionID",
       ac_imid                                                                as "CAT Reporting Firm IMID",
       null::text                                                             as "Request Date",
       null::text                                                             as "Request Time",
       to_char(strike_price, 'FM99999990D0099')                               as "Strike Price",
       case
           when order_type_value = 'New Order' then order_qty
           end
                                                                              as "Remaining Qty",
       is_affiliate                                                           as "Affiliated Flag",
       is_solicitation                                                        as "Solicitation Flag",
       'parent',
       tb.order_id,
       6,
       'natural'
from t_base tb
         left join t_route tr on tr.trans_type = tb.trans_type and tr.trans_type = 'N'
         left join lateral
    (
    select ls.order_id,
           ls.order_status,
           ls.filled_qty,
           ls.last_mkt,
           ls.order_status_description,
           ls.trade_liquidity_indicator,
           ls.exec_id
    from t_ord_status ls
    where ls.order_id = tb.order_id
    limit 1
    ) ls on true
where tb.parent_order_id is not null
  and tb.trans_type = 'G'
;


-- Trades
select tb.parent_order_id                                                     as "OrderID",
       tb.trading_firm_name                                                   as "Trading Firm Name",
       tb.tf_cat_imid                                                         as "Trading Firm IMID",
       tb.tf_cat_crd                                                          as "Trading Firm CRD",
       'Order Route'                                                          as "Event Type",

       to_char(tb.process_time, 'MM/DD/YYYY')                                 as "Event Date",
       to_char(tb.process_time, 'HH24:MI:SS:US')                              as "Event Time",
       tb.client_order_id                                                     as "Client clOrderID",
       case
           when tb.trans_type = 'G' and rn = 1 then null
           else tb.client_order_id end                                        as "Street clOrderID",
       tb.order_qty                                                           as "Event Qty",
       to_char(tb.price, 'FM99999990D0099')                                   as "Event Price",
       to_char(tb.orig_price, 'FM99999990D0099')                              as "Net Price",
       case
           when tb.multileg_reporting_type <> '1' then 'Y'
           else 'N'
           end                                                                as "Multi Leg Indicator",
       tb.no_legs                                                             as "Number of legs",
       tb.multileg_order_id                                                   as "Leg Order ID",
       'false'                                                                as "Manual Flag",
       tb.tag_58                                                              as "Free Text",
       -- Order Detail
       ls.order_status_description                                            as "Order Status",
       null::text                                                             as "Original Client clOrderID",
       null::text                                                             as "Original Street clOrderID",
       tb.opra_symbol                                                         as "OSI Symbol",
       tb.root_symbol                                                         as "Base symbol",
       tb.symbol                                                              as "Symbol",
       case tb.instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           else coalesce(tb.instrument_type_id, '') end                       as "Security Type",

       underlying_symbol                                                      as "Underlying Symbol",
       pcv                                                                    as "P/C/S",
       to_char(last_trade_date, 'MM/DD/YYYY')                                 as "Expiration Date",
       to_char(last_trade_date, 'HH24:MI:SS.MS')                              as "Expiration Time",
       case
           when side = '1' then 'Buy'
           when side = '2' then 'Sell'
           when side in ('5', '6') then 'Sell Short'
           end                                                                as "Side",
       tif                                                                    as "TIF",
       to_char(coalesce(tb.last_trade_date, tb.expire_time), 'MM/DD/YYYY')    as "Good Till Date",
       to_char(coalesce(tb.last_trade_date, tb.expire_time), 'HH24:MI:SS.MS') as "Good Till Time",
       order_qty                                                              as "Order Qty",
       ls.filled_qty                                                          as "Filled Qty",
       order_type_name                                                        as "Order Type Code",
       to_char(price, 'FM99999990D0099')                                      as "Order Price",
       to_char(process_time, 'DD.MM.YYYY')                                    as "Order Creation Date",
       to_char(process_time, 'HH24:MI:SS.US')                                 as "Order Creation Time",
       open_close                                                             as "Open/Close",
       trading_session::varchar                                               as "Trading Session",
       is_held                                                                as "Is Held",
       case
           when tb.cross_order_id is not null then 'Y'
           else 'N' end                                                       as "Is Cross",
       fee_sensitivity                                                        as "Fee Sensitivity",
       to_char(stop_price, 'FM99999990D0099')                                 as "Stop Price",
       max_floor                                                              as "Max Floor",
       customer_or_firm_name                                                  as "Capacity",
       ex_destination                                                         as "ExDestination",
       ratio_qty                                                              as "Leg ratio",
       coalesce(tb.tag_50, tb.tag_109, tb.account_name)                       as "User",

-- Account Details
       account_name                                                           as "Account Name",
       account_id                                                             as "Account ID",
       account_holder_type                                                    as "Account Holder Type",
       cat_fdid                                                               as "Account FDID",
       ac_imid                                                                as "Account IMID",
       ac_number                                                              as "Account CRD",
       sender_sub_id                                                          as "Sender Type",

       -- Execution Details
       last_mkt                                                               as "Last Mkt",
       null                                                                   as "MIC Code",
       trade_liquidity_indicator                                              as "Liquidity Indicator",
       exec_id                                                                as "ExecutionID",
       ac_imid                                                                as "CAT Reporting Firm IMID",
       null::text                                                             as "Request Date",
       null::text                                                             as "Request Time",
       to_char(strike_price, 'FM99999990D0099')                               as "Strike Price",
       case
           when order_type_value = 'New Order' then order_qty
           end
                                                                              as "Remaining Qty",
       is_affiliate                                                           as "Affiliated Flag",
       is_solicitation                                                        as "Solicitation Flag",
       'parent',
       tb.order_id,
       6,
       'natural'
from t_trade tb
         left join t_route tr on tr.trans_type = tb.trans_type and tr.trans_type = 'N'
         left join lateral
    (
    select ls.order_id,
           ls.order_status,
           ls.filled_qty,
           ls.last_mkt,
           ls.order_status_description,
           ls.trade_liquidity_indicator,
           ls.exec_id
    from t_ord_status ls
    where ls.order_id = tb.order_id
    limit 1
    ) ls on true
where tb.parent_order_id is not null
  and tb.trans_type = 'G'
select *
-- into trash.so_obo_lifecycle
from t_result
order by order_id, rn;



