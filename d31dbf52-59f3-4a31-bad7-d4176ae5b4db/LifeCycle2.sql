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
select cl.*, di.symbol, di.symbol_suffix, di.instrument_type_id, di.last_trade_date,
       ac.cat_report_on_behalf_of
from dwh.client_order cl
         join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         left join dwh.d_fix_connection fc
                   on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
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
select * from t_base;

-- street orders
insert into t_base
select cl.*, di.symbol, di.symbol_suffix, di.instrument_type_id, di.last_trade_date,
       null as cat_report_on_behalf_of
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
--order by cl.order_id, le.exec_time
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

select * from (select tr.order_type_value, tb.*, tr.rn
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
order by order_id, rn
