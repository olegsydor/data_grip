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
       'UTC'                                                       as tag_5050,
       tag_17
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
                                   fmj.fix_message ->> '17'    as tag_17,
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
-- Street orders
insert into t_base
select coalesce(staging.last_orig_order(cl.order_id), cl.order_id) as first_order_id,
       cl.*,
       di.symbol,
       di.symbol_suffix,
       di.instrument_type_id,
       di.last_trade_date,
       null                                                        as cat_report_on_behalf_of,
       par.trading_firm_name,
       par.tf_cat_imid                                             as tf_cat_imid,
       par.tf_cat_crd                                              as tf_cat_crd,
       par.orig_client_order_id,
       par.orig_price,
       par.opra_symbol,
       par.strike_price,
       par.root_symbol,
       par.underlying_symbol,
       fmj.tag_58,
       fmj.tag_50,
       fmj.tag_109,
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
       to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                       as order_request_time,
       par.is_solicitation,
       to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                       as tag_5050,
       fmj.tag_17
from t_base par
         join dwh.client_order cl on cl.parent_order_id = par.order_id
         left join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         left join lateral (select fmj.fix_message ->> '5050'  as tag_5050,
                                   fmj.fix_message ->> '50'    as tag_50,
                                   fmj.fix_message ->> '109'   as tag_109,
                                   -- fmj.fix_message ->> '9000'  as tag_9000,
                                   fmj.fix_message ->> '58'    as tag_58,
                                   fmj.fix_message ->> '17'    as tag_17,
                                   -- fmj.fix_message ->> '52'    as tag_52,
                                   -- fmj.fix_message ->> '9291'  as tag_9291,
                                   fmj.fix_message ->> '9281'  as tag_9281,
                                   fmj.fix_message ->> '22017' as tag_22017,
                                   fmj.fix_message ->> '60'    as tag_60
                            from fix_capture.fix_message_json fmj
                            where cl.fix_message_id = fmj.fix_message_id
                              and fmj.date_id >= cl.create_date_id
                            limit 1) fmj on true
where true
  and cl.create_date_id between :l_date_begin_id and :l_date_end_id
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else cl.account_id = any (:in_account_ids) end
  and cl.parent_order_id is not null
  and cl.trans_type in ('D', 'G')
  and cl.multileg_reporting_type in ('1', '2');

-- executions
drop table if exists t_exs;
create temp table t_exs as
select b.first_order_id,
       b.order_id,
       -----
       b.orig_client_order_id,
       3                                                                                       as rn,
       b.co_client_leg_ref_id,
       b.client_order_id                                                                       as client_order_id,
       fmj.tag_17                                                                              as exec_id,
       b.trading_firm_name                                                                     as trading_firm_name,
       b.tf_cat_imid                                                                           as tf_cat_imid,
       b.tf_cat_crd                                                                            as tf_cat_crd,
--        ex.exec_type,
--        et.exec_type_description,
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
       b.orig_price                                                                            as net_price,
       b.multileg_reporting_type                                                               as multileg_indicator,
       b.no_legs,
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

       b.order_type_name,
       ex.exec_time                                                                            as order_creation_ts,
       b.open_close,
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
       b.ex_destination                                                                        as ex_destination,
       b.ratio_qty,
       coalesce(fmj.tag_50, fmj.tag_109, b.account_name)                                       as user_,
       b.account_name                                                                          as account_name,
       b.account_id                                                                            as account_id,
       b.account_holder_type,
       b.cat_fdid,
       b.ac_imid,
       b.ac_number,
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
       to_timestamp(left(nxt.nxt_tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                                                   as cancel_request_time,
       strike_price,
       b.order_qty - coalesce(ex.cum_qty, 0)                                                   as remaining_qty,
       b.is_affiliate,
       null                                                                                    as solicitation
from t_base b
         join dwh.execution ex
              on ex.order_id = b.order_id and ex.exec_date_id >= b.create_date_id
--                   and ex.exec_type not in ('a', 'A', 'S', '0')
         left join dwh.d_account ac on b.account_id = ac.account_id and ac.is_active
         left join dwh.d_trading_firm tf on b.trading_firm_unq_id = tf.trading_firm_unq_id

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
         left join lateral (select fmj.fix_message ->> '60' as nxt_tag_60
                            from dwh.client_order nxt
                                     join fix_capture.fix_message_json fmj
                                          on fmj.fix_message_id = nxt.fix_message_id and
                                             fmj.date_id = nxt.create_date_id
                            where nxt.create_date_id >= b.create_date_id
                              and nxt.orig_order_id = b.order_id
                              and nxt.create_date_id >= :l_date_begin_id
                              and nxt.create_date_id <= :l_date_end_id
                            limit 1) nxt on (ex.exec_type = '4' or ex.order_status = '4')
         left join dwh.d_order_status os on ex.order_status = os.order_status
         join dwh.d_exec_type et on et.exec_type = ex.exec_type
         left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active;


select * from t_exs;
select * from t_base;


drop table if exists t_result;
create temp table if not exists t_result as
    -- Orders
select x.first_order_id,
       x.order_id                                                           as "OrderID",
       x.orig_client_order_id,
       x.rn,
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
       co_client_leg_ref_id                                                 as "Leg Order ID",
       'false'                                                              as "Manual Flag",
       x.tag_58                                                             as "Free Text",
       -- Order Detail
       order_status_description                                             as "Order Status",
       case
           when order_type_value = 'New Order' then ''
           else orig_client_order_id end                                    as "Original Client clOrderID",
       case
           when order_type_value = 'Order Route'
               then orig_client_order_id end                                as "Original Street clOrderID",
       opra_symbol                                                          as "OSI Symbol",
       root_symbol                                                          as "Base symbol",
       symbol                                                               as "Symbol",
       case x.instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           else x.instrument_type_id end                                    as "Security Type",

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
       ex.cum_qty                                                           as "Filled Qty",
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
       ex.last_mkt                                                          as "Last Mkt",
       null                                                                 as "MIC Code",
       trade_liquidity_indicator                                            as "Liquidity Indicator",
       tag_17                                                               as "ExecutionID",
       ac_imid                                                              as "CAT Reporting Firm IMID",
       null::text                                                           as "Request Date",
       null::text                                                           as "Request Time",
       to_char(strike_price, 'FM99999990D0099')                             as "Strike Price",
       case
           when order_type_value = 'New Order' then order_qty
           end                                                              as "Remaining Qty",
       is_affiliate                                                         as "Affiliated Flag",
       is_solicitation                                                      as "Solicitation Flag"
from (select tr.order_type_value, tb.*, tr.rn, 'syntetic' as kind_of_type
      from t_base tb
               join t_route tr on tr.trans_type = tb.trans_type
      where tb.parent_order_id is null
        and tb.cat_report_on_behalf_of = 'N'
      union all
      select case when tb.cat_report_on_behalf_of != 'N' then 'New' else 'Ack' end, tb.*, 3, 'natural' as kind_of_type
      from t_base tb
               left join t_route tr on tr.trans_type = tb.trans_type and tr.trans_type = 'N'
      where tb.parent_order_id is null) x
         left join lateral
    ( select ex.exec_id,
             ex.order_status,
             ex.exec_type,
             ex.cum_qty,
             ex.exec_time,
             ex.last_mkt,
             ex.trade_liquidity_indicator,
             ex.exec_text,
             ex.exchange_id,
             ex.secondary_exch_exec_id
      from dwh.execution ex
      where ex.order_id = x.order_id
        and ex.exec_date_id >= x.create_date_id
      order by exec_id desc
      limit 1
    ) ex on true
         left join dwh.d_order_status os on ex.order_status = os.order_status
         left join dwh.d_exec_type et on et.exec_type = ex.exec_type
         left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active;


insert into t_result
-- executions
select first_order_id,
       order_id                                                      as "OrderID",
       orig_client_order_id,
       rn,
       trading_firm_name                                             as "Trading Firm Name",
       tf_cat_imid                                                   as "Trading Firm IMID",
       tf_cat_crd                                                    as "Trading Firm CRD",
       event_type                                                    as "Event Type",
       to_char(event_ts, 'MM/DD/YYYY')                               as "Event Date",
       case
           when event_type = 'Cancelled' then coalesce(to_char(event_ts, 'HH24:MI:SS:MS'), '')
           else coalesce(to_char(event_ts, 'HH24:MI:SS:US'), '') end as "Event Time",
       client_order_id                                               as "Client clOrderID",
       street_client_order_id                                        as "Street clOrderID",
       event_qty                                                     as "Event Qty",
       to_char(event_price, 'FM99999990D0099')                       as "Event Price",
       to_char(net_price, 'FM99999990D0099')                         as "Net Price",
       case
           when multileg_indicator <> '1' then 'Y'
           else 'N'
           end                                                       as "Multi Leg Indicator",
       no_legs                                                       as "Number of legs",
       co_client_leg_ref_id                                          as "Leg Order ID",
       manual_flag                                                   as "Manual Flag",
       exec_text                                                     as "Free Text",
       -- Order Detail
       order_status_description                                      as "Order Status",
       case
           when event_type = 'New Order' then ''
           else orig_client_order_id end                             as "Original Client clOrderID",
       case
           when event_type = 'Order Route'
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
       to_char(expiration_ts, 'MM/DD/YYYY')                          as "Expiration Date",
       to_char(expiration_ts, 'HH24:MI:SS.MS')                       as "Expiration Time",
       case
           when side = '1' then 'Buy'
           when side = '2' then 'Sell'
           when side in ('5', '6') then 'Sell Short'
           end                                                       as "Side",
       tif                                                           as "TIF",
       to_char(good_till_ts, 'MM/DD/YYYY')                           as "Good Till Date",
       to_char(good_till_ts, 'HH24:MI:SS.MS')                        as "Good Till Time",
       event_qty                                                     as "Order Qty",
       cum_qty                                                       as "Filled Qty",
       order_type_name                                               as "Order Type Code",
       to_char(event_price, 'FM99999990D0099')                       as "Order Price",
       to_char(order_creation_ts, 'DD.MM.YYYY')                      as "Order Creation Date",
       to_char(order_creation_ts, 'HH24:MI:SS.US')                   as "Order Creation Time",
       open_close                                                    as "Open/Close",
       trading_session::varchar                                      as "Trading Session",
       is_held                                                       as "Is Held",
       is_cross                                                      as "Is Cross",
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
       cat_fdid                                                      as "Account FDID",
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
from t_exs x
where case when exec_type in ('A', '0', '5', 'b') and event_ts is null then false else true end
  and case when :in_include_acks = 'Y' then true else exec_type not in ('A', '0', '5') end



select * from t_result
order by first_order_id, "OrderID", orig_client_order_id  nulls first, rn

select "OrderID",
       "Trading Firm Name",
       "Trading Firm IMID",
       "Trading Firm CRD",
       "Event Type",
       "Event Date",
       "Event Time",
       "Client clOrderID",
       "Street clOrderID",
       "Event Qty",
       "Event Price",
       "Net Price",
       "Multi Leg Indicator",
       "Number of legs",
       "Leg Order ID",
       "Manual Flag",
       "Free Text",
       "Order Status",
       "Original Client clOrderID",
       "Original Street clOrderID",
       "OSI Symbol",
       "Base symbol",
       "Symbol",
       "Security Type",
       "Underlying Symbol",
       "P/C/S",
       "Expiration Date",
       "Expiration Time",
       "Side",
       "TIF",
       "Good Till Date",
       "Good Till Time",
       "Order Qty",
       "Filled Qty",
       "Order Type Code",
       "Order Price",
       "Order Creation Date",
       "Order Creation Time",
       "Open/Close",
       "Trading Session",
       "Is Held",
       "Is Cross",
       "Fee Sensitivity",
       "Stop Price",
       "Max Floor",
       "Capacity",
       "ExDestination",
       "Leg ratio",
       "User",
       "Account Name",
       "Account ID",
       "Account Holder Type",
       "Account FDID",
       "Account IMID",
       "Account CRD",
       "Sender Type",
       "Last Mkt",
       "MIC Code",
       "Liquidity Indicator",
       "ExecutionID",
       "CAT Reporting Firm IMID",
       "Request Date",
       "Request Time",
       "Strike Price",
       "Remaining Qty",
       "Affiliated Flag",
       "Solicitation Flag"
, first_order_id, orig_client_order_id , rn
into trash.so_obo_lifecycle
from t_result
order by first_order_id, "OrderID", orig_client_order_id nulls first, rn

select "OrderID",
       "Trading Firm Name",
       "Trading Firm IMID",
       "Trading Firm CRD",
       "Event Type",
       "Event Date",
       "Event Time",
       "Client clOrderID",
       "Street clOrderID",
       "Event Qty",
       "Event Price",
       "Net Price",
       "Multi Leg Indicator",
       "Number of legs",
       "Leg Order ID",
       "Manual Flag",
       "Free Text",
       "Order Status",
       "Original Client clOrderID",
       "Original Street clOrderID",
       "OSI Symbol",
       "Base symbol",
       "Symbol",
       "Security Type",
       "Underlying Symbol",
       "P/C/S",
       "Expiration Date",
       "Expiration Time",
       "Side",
       "TIF",
       "Good Till Date",
       "Good Till Time",
       "Order Qty",
       "Filled Qty",
       "Order Type Code",
       "Order Price",
       "Order Creation Date",
       "Order Creation Time",
       "Open/Close",
       "Trading Session",
       "Is Held",
       "Is Cross",
       "Fee Sensitivity",
       "Stop Price",
       "Max Floor",
       "Capacity",
       "ExDestination",
       "Leg ratio",
       "User",
       "Account Name",
       "Account ID",
       "Account Holder Type",
       "Account FDID",
       "Account IMID",
       "Account CRD",
       "Sender Type",
       "Last Mkt",
       "MIC Code",
       "Liquidity Indicator",
       "ExecutionID",
       "CAT Reporting Firm IMID",
       "Request Date",
       "Request Time",
       "Strike Price",
       "Remaining Qty",
       "Affiliated Flag",
       "Solicitation Flag"
from trash.so_obo_lifecycle
order by first_order_id, "OrderID", orig_client_order_id nulls first, rn