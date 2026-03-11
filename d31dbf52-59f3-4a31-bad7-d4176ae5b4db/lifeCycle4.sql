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


-- parent orders
drop table if exists t_base;
create temp table t_base as
select order_id                                                                              as first_order_id,
       cl.*,
       di.symbol,
       di.symbol_suffix,
       di.instrument_type_id,
       di.last_trade_date,
       ac.cat_report_on_behalf_of,
       tf.trading_firm_name,
       tf.cat_imid                                                                           as tf_cat_imid,
       tf.cat_crd                                                                            as tf_cat_crd,
       orig.client_order_id                                                                  as orig_client_order_id,
       orig.price                                                                            as orig_price,
       oc.opra_symbol,
       oc.strike_price,
       os.root_symbol,
       ui.symbol                                                                             as underlying_symbol,
       fmj.tag_58,
       fmj.tag_50,
       fmj.tag_109,
       case
           when di.instrument_type_id = 'E' then 'Stock'
           when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
           when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
           end                                                                               as pcv,
       dtif.tif_short_name                                                                   as tif,
       dot.order_type_name,
       case
           when tag_9281 in ('A', 'D', 'G') then 'ALL'
           when tag_22017 = 'A' then 'ALL'
           when tag_9281 in ('F', 'C') then 'REGPOST'
           when tag_22017 = 'B' then 'REGPOST'
           else 'REG' end                                                                    as trading_session,
       cof.customer_or_firm_name,
       ac.account_name,
       case when ac.is_broker_dealer is distinct from 'Y' then ac.account_holder_type end    as account_holder_type,
       case when ac.is_broker_dealer is distinct from 'Y' then ac.cat_fdid end               as ac_fdid,
       ac.crd_number,
       tf.cat_imid,
       ac.is_affiliate,
       case when ac.is_broker_dealer is not distinct from 'Y' then ac.broker_dealer_mpid end as ac_imid,
       ac.crd_number                                                                         as ac_number,
       case when ac.is_broker_dealer is not distinct from 'Y' then 'F' end                   as sender_type,
       fc.sender_sub_id,
       to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                                                 as order_request_time,
       case when cl.ex_destination = 'DASH' then 'Y' else 'N' end                            as is_solicitation,
       to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                                                 as tag_5050,
       tag_17,
       ex.*
from dwh.client_order cl
         join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
         join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         left join lateral
    ( select ex.exec_id,
             ex.order_status,
             ex.exec_type,
             ex.cum_qty,
             ex.exec_time,
             ex.last_mkt,
             ex.trade_liquidity_indicator,
             ex.exec_text,
             ex.exchange_id as ex_exchange_id,
             ex.secondary_exch_exec_id
      from dwh.execution ex
      where ex.order_id = cl.order_id
        and ex.exec_date_id >= cl.create_date_id
      order by exec_id desc
      limit 1
    ) ex on true
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
select cl.parent_order_id                                                                    as first_order_id,
       cl.*,
       di.symbol,
       di.symbol_suffix,
       di.instrument_type_id,
       di.last_trade_date,
       ac.cat_report_on_behalf_of,
       tf.trading_firm_name,
       tf.cat_imid                                                                           as tf_cat_imid,
       tf.cat_crd                                                                            as tf_cat_crd,
       orig.client_order_id                                                                  as orig_client_order_id,
       orig.price                                                                            as orig_price,
       oc.opra_symbol,
       oc.strike_price,
       os.root_symbol,
       ui.symbol                                                                             as underlying_symbol,
       fmj.tag_58,
       fmj.tag_50,
       fmj.tag_109,
       case
           when di.instrument_type_id = 'E' then 'Stock'
           when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
           when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
           end                                                                               as pcv,
       dtif.tif_short_name                                                                   as tif,
       dot.order_type_name,
       case
           when tag_9281 in ('A', 'D', 'G') then 'ALL'
           when tag_22017 = 'A' then 'ALL'
           when tag_9281 in ('F', 'C') then 'REGPOST'
           when tag_22017 = 'B' then 'REGPOST'
           else 'REG' end                                                                    as trading_session,
       cof.customer_or_firm_name,
       ac.account_name,
       case when ac.is_broker_dealer is distinct from 'Y' then ac.account_holder_type end    as account_holder_type,
       case when ac.is_broker_dealer is distinct from 'Y' then ac.cat_fdid end               as ac_fdid,
       ac.crd_number,
       tf.cat_imid,
       ac.is_affiliate,
       case when ac.is_broker_dealer is not distinct from 'Y' then ac.broker_dealer_mpid end as ac_imid,
       ac.crd_number                                                                         as ac_number,
       case when ac.is_broker_dealer is not distinct from 'Y' then 'F' end                   as sender_type,
       fc.sender_sub_id,
       to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                                                 as order_request_time,
       case when cl.ex_destination = 'DASH' then 'Y' else 'N' end                            as is_solicitation,
       to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
       'UTC'                                                                                 as tag_5050,
       fmj.tag_17,
       ex.*
from t_base par
         join dwh.client_order cl on cl.parent_order_id = par.order_id
         join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
         join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         left join lateral
    ( select ex.exec_id,
             ex.order_status,
             ex.exec_type,
             ex.cum_qty,
             ex.exec_time,
             ex.last_mkt,
             ex.trade_liquidity_indicator,
             ex.exec_text,
             ex.exchange_id as ex_exchange_id,
             ex.secondary_exch_exec_id
      from dwh.execution ex
      where ex.order_id = cl.order_id
        and ex.exec_date_id >= cl.create_date_id
      order by exec_id desc
      limit 1
    ) ex on true
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
where cl.parent_order_id is not null
  and cl.create_date_id between :l_date_begin_id and :l_date_end_id;


select * from t_base;

