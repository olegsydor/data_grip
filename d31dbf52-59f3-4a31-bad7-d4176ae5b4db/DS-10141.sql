---working place
select * from dwh.client_order
    where client_order.order_id = 100000021238170475


--
    l_date_begin_id := coalesce(in_date_begin_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_date_end_id := coalesce(in_date_end_id, to_char(current_date, 'YYYYMMDD')::int4);

    return query
--     select 'OrderID,exec_id,Trading Firm Name,Trading Firm IMID,Trading Firm CRD,Event Type,Event Date,Event Time,Orig clOrderID,Street clOrderID,Event Qty,Event Price,Net Price,Multi Leg Indicator,Number of legs,Leg Order ID,Manual Flag,Free Text,Order Status,OSI Symbol,Base symbol,Symbol,Security Type,Underlying Symbol,Expiration Date,Expiration Time,Side,TIF,Good Till Date,Good Till Time,Order Qty,Filled Qty,Order Type Code,Order Price,Order Creation Date,Order Creation Time,Open/Close,Trading Session,Is Held,Is Cross,Fee Sensitivity,Stop Price,Max Floor,Capacity,ExDestination,Leg ratio,User,Account Name,Account ID,Account Holder Type,Account FDID,Account IMID,Account CRD,Sender type,Last Mkt,MIC Code,Liquidity Indicator,ExecutionID,CAT Reporting Firm IMID';
        select 'OrderID|exec_id|Trading Firm Name|Event Type|Event Date|Event Time|Orig clOrderID|Street clOrderID|Event Qty|Event Price|Executed Timestamp|Multi Leg Indicator|Number of legs|Leg Order ID|Free Text|Order Status|OSI Symbol|Base symbol|Symbol|Security Type|Underlying Symbol|P/C/V|Expiration Date|Side|TIF|Good Till Date|Good Till Time|Order Qty|Filled Qty|Order Type Code|Order Price|Order Creation Date|Order Creation Time|Open/Close|Trading Session|Is Held|Is Cross|Stop Price|Max Floor|Capacity|ExDestination|Leg ratio|User|Account Name|Account ID|Last Mkt|MIC Code|Liquidity Indicator';

create temp table t_base as
select coalesce(staging.last_orig_order(cl.order_id), cl.order_id) as first_order,
       orig.client_order_id                                        as orig_client_order_id,
       cl.client_order_id,
       cl.co_client_leg_ref_id                                     as leg_cl_ord_id,
       cl.trans_type,
       cl.order_id,
       cl.fix_message_id,
       cl.create_date_id,
       cl.order_qty,
       cl.price,
--                              mleg.price                                                                            as net_price,
       cl.multileg_reporting_type,
       cl.instrument_id,
       cl.time_in_force_id,
       cl.expire_time,
       cl.create_time,
       case
           when cl.multileg_reporting_type = '3' then (select count(*)
                                                       from dwh.client_order cli
                                                       where cli.multileg_order_id = cl.order_id)
           else mleg.no_legs end                                   as no_legs,
       cl.multileg_order_id,
       cl.side,
       cl.order_type_id,
       cl.open_close,
       cl.exec_instruction,
       cl.cross_order_id,
       cl.fee_sensitivity,
       cl.stop_price,
       cl.max_floor,
       cl.ex_destination,
       cl.ratio_qty,
       cl.customer_or_firm_id,
       oc.opra_symbol,
       di.symbol,
       case
           when di.instrument_type_id = 'E' then 'Stock'
           when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
           when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
           else ''
           end                                                     as pcv,
       di.instrument_type_id,
       coalesce(di.last_trade_date, cl.expire_time)                as last_trade_date,
       tf.trading_firm_name,
       tf.cat_imid,
       tf.cat_crd,
       dos.root_symbol,
       ui.symbol                                                   as underlying_symbol,
       dtif.tif_short_name                                         as tif,
       dot.order_type_name,
       cof.customer_or_firm_name,
       fmj.tag_9000                                                as par_tag_9000,
       fmj.tag_50                                                  as par_tag_50,
       fmj.tag_109                                                 as par_tag_109,
       to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                       as par_tag_5050,
--                             to_timestamp(fmj.tag_10061, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
--                             'UTC'                                                       as par_tag_10061,
--                             coalesce(
--                             orig.process_time, to_timestamp(fmj.tag_10061, 'YYYYMMDD-HH24:MI:SS:US'))::timestamp at time zone 'UTC'         as par_tag_10061,
       staging.last_orig_order_process_time(in_order_id := cl.order_id)::timestamp
           at time zone 'UTC'                                      as par_tag_10061,
       cl.process_time,
       ac.account_name,
       ac.account_id,
       ac.account_holder_type,
       ac.cat_fdid                                                 as ac_fdid,
       case
           when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
               then tf.cat_imid end                                as ac_imid,
       case
           when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
               then ac.crd_number end                              as ac_number,
--         ac.broker_dealer_mpid,
       fc.sender_sub_id,
       fmj.tag_58                                                  as exec_text,
       fmj.tag_17                                                  as exec_id,
       fmj.tag_52                                                  as par_tag_52
--                              , *
-- Execution Details
from dwh.client_order cl
         left join dwh.client_order orig
                   on orig.order_id = cl.orig_order_id and
                      orig.create_date_id >= cl.create_date_id
                       and orig.create_date_id >= :l_retention_date_id
         left join dwh.client_order mleg
                   on (mleg.order_id = cl.multileg_order_id and
                       mleg.create_date_id >= cl.create_date_id
                       and mleg.create_date_id >= :l_retention_date_id)
         join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id

         left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
         left join dwh.d_option_series dos on oc.option_series_id = dos.option_series_id
         left join dwh.d_instrument ui on ui.instrument_id = dos.underlying_instrument_id
         left join dwh.d_time_in_force dtif on dtif.tif_id = cl.time_in_force_id
         left join dwh.d_order_type dot on dot.order_type_id = cl.order_type_id
         left join dwh.d_customer_or_firm cof on cof.customer_or_firm_id = cl.customer_or_firm_id
         left join dwh.d_fix_connection fc
                   on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
         left join lateral (select coalesce(fmj.fix_message ->> '10061',
                                            fmj.fix_message ->> '60') as tag_10061,
                                   fmj.fix_message ->> '5050'         as tag_5050,
                                   fmj.fix_message ->> '50'           as tag_50,
                                   fmj.fix_message ->> '109'          as tag_109,
                                   fmj.fix_message ->> '9000'         as tag_9000,
                                   fmj.fix_message ->> '58'           as tag_58,
                                   fmj.fix_message ->> '17'           as tag_17,
                                   fmj.fix_message ->> '52'           as tag_52
                            from fix_capture.fix_message_json fmj
                            where cl.fix_message_id = fmj.fix_message_id
                              and fmj.date_id >= cl.create_date_id
                            limit 1) fmj on true
where cl.parent_order_id is null
  and cl.create_date_id between :l_date_begin_id and :l_date_end_id
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else cl.account_id = any (:in_account_ids) end
  and cl.trans_type <> 'F'


drop table t_exs;
create temp table t_exs as
select b.first_order,
       b.orig_client_order_id,
       3                                                                                  as rn,
--                             b.leg_cl_ord_id, b.client_order_id,
       b.client_order_id                                                                  as client_order_id,
--                     ex.secondary_exch_exec_id                                      as exec_id,
       tag_17                                                                             as exec_id,
--                     b.trading_firm_name,
       null                                                                               as trading_firm_name,
--                     b.cat_imid,
       null                                                                               as cat_imid,
--                     b.cat_crd,
       null                                                                               as cat_crd,
       case
           when ex.exec_type in ('A', '0', '5') then 'Order Ack'
           when ex.exec_type = '4' then 'Cancelled'
           else et.exec_type_description end                                              as event_type,
       case
           when ex.exec_type in ('A', '0', '5', 's') then
--                                        coalesce(b.par_tag_5050, to_timestamp(b.par_tag_52, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC')
               b.par_tag_5050
           when ex.exec_type = '4' then
               ex.exec_time::timestamp
           else
               to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'
           end                                                                            as event_ts,
       b.client_order_id                                                                  as street_client_order_id,
       b.order_qty,
       b.price,
       b.multileg_reporting_type                                                          as multileg_indicator,
       b.no_legs,
       b.leg_cl_ord_id                                                                    as multileg_order_id,
       case
           when ex.exec_type in ('A', 'F', '5', 'W', '4') then 'false'
           else '?' end                                                                   as manual_flag,
       case when ex.exec_type not in ('A', '0', '5') then ex.exec_text end                as exec_text,
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
           else b.underlying_symbol end                                                   as underlying_symbol,
       b.pcv,
       coalesce(b.last_trade_date, ex.exec_time)                                          as expiration_ts,
       b.side,
       b.tif,
       b.expire_time                                                                      as good_till_ts,
--                     ex.cum_qty,
       fmj.tag_14                                                                         as cum_qty,
       b.order_type_name,
--                            b.create_time                                                   as order_creation_ts,
       to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC' as order_creation_ts,
       b.open_close,
       compliance.get_eq_sor_trading_session(b.order_id, b.create_date_id),
       case
           when b.exec_instruction like '1%' then 'NH'
           when b.exec_instruction like '5%' then 'H'
--                                else 'NH'
           end as held,
       case
           when b.cross_order_id is not null then 'Y'
           else 'N' end as is_cross,
       b.fee_sensitivity,
       b.stop_price,
       b.max_floor,
       b.customer_or_firm_name,
       b.par_tag_9000                                                                     as ex_destination,
       b.ratio_qty,
       coalesce(fmj.tag_50, tag_109, b.account_name)                                      as user_,
--                     b.account_name,
       null                                                                               as account_name,
--                     b.account_id,
       null::int                                                                          as account_id,
       b.account_holder_type,
       b.ac_fdid,
       b.ac_imid,
       b.ac_number,
--         ac.broker_dealer_mpid,
       b.sender_sub_id,

       -- Execution Details
       ex.last_mkt,
       exc.mic_code,
       ex.trade_liquidity_indicator,
       case when ex.exec_type = 'F' then ex.exec_time end                                 as trade_exec_time,
       ex.exec_type
from t_base b
         left join dwh.execution ex
                   on ex.order_id = b.order_id and ex.exec_date_id >= b.create_date_id
                       and ex.exec_type not in ('a', 'A', 'S', '0')
         left join lateral (select fmj.fix_message ->> '10061'          as tag_10061,
                                   coalesce(fmj.fix_message ->> '5050',
                                            fmj.fix_message ->> '5051') as tag_5050,
--                                                         fmj.fix_message ->> '52'             as tag_52,
                                   fmj.fix_message ->> '50'             as tag_50,
                                   fmj.fix_message ->> '109'            as tag_109,
                                   fmj.fix_message ->> '9000'           as tag_9000,
                                   fmj.fix_message ->> '17'             as tag_17,
                                   fmj.fix_message ->> '14'             as tag_14
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = ex.fix_message_id
                              and fmj.date_id >= ex.exec_date_id
                            limit 1) fmj on true
         left join dwh.d_order_status os on ex.order_status = os.order_status
         join dwh.d_exec_type et on et.exec_type = ex.exec_type
         left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active;

insert into t_exs
        with ord_type as (select *
                          from (values ('D', 'New Order', 1),
                                       ('D', 'Order Route', 2),
                                       ('G', 'Order Modify', 1),
                                       ('G', 'Order Modify Route', 2))
                                   as t(trans_type, order_type_value, rn))
select b.first_order,
                            b.orig_client_order_id,
                            ot.rn,
--                             case
--                                 when ot.order_type_value = 'New Order' and b.leg_cl_ord_id is null
--                                 then null
--                                 else coalesce(b.leg_cl_ord_id, b.client_order_id)
--                                 end                                                             as client_order_id,
                            b.client_order_id                                                   as client_order_id,
                            b.exec_id                                                           as exec_id,
                            case
                                when ot.order_type_value = 'New Order'
                                    then b.trading_firm_name end                                as trading_firm_name,
                            case
                                when ot.order_type_value = 'New Order'
                                    then b.cat_imid end                                         as cat_imid,
                            case
                                when ot.order_type_value = 'New Order'
                                    then b.cat_crd end                                          as cat_crd,

                            ot.order_type_value                                                 as event_type,

--                            case
--                                when ot.rn in (1, 2) then b.par_tag_10061
--                                else b.par_tag_5050 end                                         as event_ts,
                            case
	                             when ot.order_type_value  = 'Cancelled' then b.create_time
                                else coalesce(b.par_tag_5050, b.par_tag_10061) end              as event_ts,
                            case
                                when ot.trans_type = 'G' and rn = 1 then null
                                else b.client_order_id end                                      as street_client_order_id,
                            b.order_qty                                                         as event_qty,
                            b.price                                                             as event_price,
--                             b.net_price,
                            b.multileg_reporting_type                                           as multileg_indicator,
                            b.no_legs,
--                            b.multileg_order_id,
                            b.leg_cl_ord_id                                                     as multileg_order_id,
                            case
                                when ot.rn = 1 then 'true'
                                else 'false' end                                                as manual_flag,
                            case
                                when ot.order_type_value != 'New Order'
                                    then b.exec_text end                                        as exec_text,
                            os.order_status_description,-- et.exec_type_description, ex.order_status,
                            b.opra_symbol,
                            b.root_symbol,
                            b.symbol,
                            b.instrument_type_id,
                            case
                                when b.instrument_type_id = 'M' then (select underlying_symbol
                                                                      from t_base
                                                                      where t_base.multileg_order_id = b.order_id
                                                                      limit 1)
                                else b.underlying_symbol end                                    as underlying_symbol,
                            b.pcv,
--                             case
--                                 when ot.order_type_value != 'New Order'
--                                     then b.last_trade_date end                                  as expiration_ts,
                            b.last_trade_date                                                   as expiration_ts,
                            b.side,
                            b.tif,
                            b.expire_time                                                       as good_till_ts,
                            case
                                when ot.order_type_value != 'New Order'
                                    then ex.cum_qty::text end                                   as cum_qty,
--                     ex.cum_qty,
                            b.order_type_name,
--                            b.create_time                                                       as order_creation_ts,
                            coalesce(b.par_tag_5050, b.par_tag_10061)                           as order_creation_ts,
                            b.open_close,
                            compliance.get_eq_sor_trading_session(b.order_id, b.create_date_id) as trading_session,
                            case
                                when b.exec_instruction like '1%' then 'NH'
                                when b.exec_instruction like '5%' then 'H'
--                                else 'NH'
                                end                                                             as is_held,
                            case
                                when b.cross_order_id is not null then 'Y'
                                else 'N' end                                                    as is_cross,
                            b.fee_sensitivity,
                            b.stop_price,
                            b.max_floor,
                            b.customer_or_firm_name,
                            case
                                when ot.rn = 1 then ''
                                else b.par_tag_9000 end                                         as ex_destination,
                            b.ratio_qty,
                            coalesce(b.par_tag_50, b.par_tag_109, b.account_name)               as user_,
----
                            case
                                when ot.order_type_value = 'New Order'
                                    then b.account_name end                                     as account_name,
                            case
                                when ot.order_type_value = 'New Order'
                                    then b.account_id end                                       as account_id,
                            b.account_holder_type,
                            b.ac_fdid,
                            b.ac_imid,
                            b.ac_number,
--         ac.broker_dealer_mpid,
                            b.sender_sub_id,

                            -- Execution Details
                            case when ot.trans_type = 'D' then ex.last_mkt end                  as last_mkt,
                            case when ot.trans_type = 'D' then exc.mic_code end                 as mic_code,
                            case when ot.trans_type = 'D' then ex.trade_liquidity_indicator end as trade_liquidity_indicator,
                            null::timestamp                                                     as trade_exec_time,
                            et.exec_type
                     from t_base b
                              join ord_type ot using (trans_type)
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
                           where ex.order_id = b.order_id
                             and ex.exec_date_id >= b.create_date_id
                           order by exec_id desc
                           limit 1
                         ) ex on true
                              left join dwh.d_order_status os on ex.order_status = os.order_status
                              left join dwh.d_exec_type et on et.exec_type = ex.exec_type
                              left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active


select * from t_exs