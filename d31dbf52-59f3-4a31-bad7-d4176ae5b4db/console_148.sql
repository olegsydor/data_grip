  select  coalesce(:in_date_begin, to_char(date_trunc('quarter', current_date - interval '3 month'),
                                                            'YYYYMMDD')::int4); -- :in_date_begin
    select coalesce(:in_date_end,
                                     to_char((date_trunc('quarter', current_date) - interval '1 day'), 'YYYYMMDD')::int4); -- :in_date_end


drop table if exists trash.tmp_fyc;
  create table if not exists trash.tmp_fyc
  as
  select yc.order_id,
         yc.client_order_id,
         yc.status_date_id                                                                     as date_id,
         yc.multileg_reporting_type,
         yc.instrument_type_id,
         yc.account_id,
         a.account_name,
         yc.client_id,
         yc.instrument_id,
         yc.routed_time                                                                        as parent_routed_time,
         yc.order_end_time,
         yc.side,
         yc.buy_or_sell,
         (case when yc.buy_or_sell = 'B' then 1 else -1 end)::int                              as side_multiplier,
         case when yc.day_order_qty < yc.order_qty then yc.day_order_qty else yc.order_qty end as parent_order_qty,
         yc.day_cum_qty                                                                        as parent_exec_qty,
--            sum(yc.day_cum_qty) over (partition by true)                                          as total_parent_exec_qty,
         yc.avg_px                                                                             as parent_avg_price,
         yc.avg_px * yc.day_cum_qty                                                            as principal_amount,
         yc.nbbo_bid_price                                                                     as parent_nbbo_bid_price,
         yc.nbbo_ask_price                                                                     as parent_nbbo_ask_price,
         yc.nbbo_bid_quantity                                                                  as parent_nbbo_bid_qty,
         yc.nbbo_ask_quantity                                                                  as parent_nbbo_ask_qty,
         case
             when yc.side = '1' then 10000 * (yc.order_price - yc.nbbo_ask_price) /
                                     coalesce(yc.nbbo_ask_price, 0, null)
             else null end                                                                     as buy_limit_vs_ask_bps,
         case
             when yc.side <> '1' then 10000 * (yc.order_price - yc.nbbo_bid_price) /
                                      coalesce(yc.nbbo_bid_price, 0, null)
             else null end                                                                     as sell_limit_vs_bid_bps,
         yc.is_marketable                                                                      as parent_is_marketable,
         yc.order_price                                                                        as parent_limit_price,
         (yc.nbbo_ask_price + yc.nbbo_bid_price) / 2                                              routing_time_mid_price,
         yc.nbbo_ask_price - yc.nbbo_bid_price                                                    routing_time_spread,
         yc.trading_firm_unq_id,
         yc.sub_strategy_id,
         yc.routing_table_id,
         yc.order_fix_message_id,
         yc.day_order_qty,
         yc.order_qty,
--          co.order_cancel_time,
         fmj.tag_9002,
         fmj.tag_9023,
         fmj.tag_9126,
         fmj.tag_9191,
         fmj.tag_9264
  into trash.tmp_fyc
  from data_marts.f_yield_capture yc
           join lateral (select account_name
                         from dwh.d_account a
                         where a.account_id = yc.account_id and a.is_active
                         limit 1) a on true
           left join dwh.d_target_strategy dts on dts.target_strategy_id = yc.sub_strategy_id


           left join lateral (select fix_message ->> '9264' as tag_9264,
                                     fix_message ->> '9023' as tag_9023,
                                     fix_message ->> '9002' as tag_9002,
                                     fix_message ->> '9126' as tag_9126,
                                     fix_message ->> '9191' as tag_9191
                              from fix_capture.fix_message_json fmj
                              where fmj.fix_message_id = yc.order_fix_message_id--co.fix_message_id
                                and fmj.date_id = yc.status_date_id
                                and fmj.date_id >= :in_date_begin
                                and fmj.date_id <= :in_date_end
                              limit 1) fmj on true

  where yc.parent_order_id is null
    and yc.status_date_id between :in_date_begin and :in_date_end
    and yc.instrument_type_id = 'E'
    and yc.multileg_reporting_type = '1'
  limit 0;
  --       and case when coalesce(in_account_ids, '{}') <> '{}' then yc.account_id = any (in_account_ids) else true end
--       and case
--               when coalesce(in_trading_firm_ids, '{}') <> '{}' then a.trading_firm_id = any (in_trading_firm_ids)
--               else true end
--       and case when coalesce(in_client_ids, '{}') <> '{}' then yc.client_id = any (in_client_ids) else true end
--       and case when in_sub_strategy <> '{}' then dts.target_strategy_name = any (in_sub_strategy) else true end
--       and case when l_instrument_id_arr <> '{}' then yc.instrument_id = any (l_instrument_id_arr) else true end;



insert into trash.pre_pre_fetch_equity_tca (order_id, client_order_id, date_id, multileg_reporting_type,
                                            instrument_type_id,
                                            trading_firm_unq_id, trading_firm_name, account_id, account_name, client_id,
                                            instrument_id, symbol, parent_routed_time, order_end_time,
                                            order_cancel_time,
                                            side, buy_or_sell, side_multiplier, parent_order_qty, parent_exec_qty,
                                            total_parent_exec_qty,
                                            parent_avg_price, principal_amount,
                                            target_strategy_id,
                                            algorithm, parent_nbbo_bid_price, parent_nbbo_ask_price,
                                            parent_nbbo_bid_qty,
                                            parent_nbbo_ask_qty, buy_limit_vs_ask_bps, sell_limit_vs_bid_bps,
                                            parent_is_marketable, parent_limit_price, routing_table_name,
                                            order_arrival_price,
                                            order_end_price, vwap_over_life, eligible_vwap_over_life, twap_over_life,
                                            eligible_twap_over_life, volume_over_life, eligible_volume_over_life,
                                            eligible_pwp_5pc, eligible_pwp_10pc, eligible_pwp_15pc, eligible_pwp_20pc,
                                            trade_count, eligible_trade_count, block_volume, eligible_qd_volume,
                                            eligible_ix_volume, avg_spread_over_life, day_high_price, day_low_price,
                                            open_px,
                                            close_px, prev_close_px, next_close_px, routing_time_mid_price,
                                            routing_time_spread, aggression_level, activ_symbol, day_order_qty,
                                            order_qty)
select yc.order_id,
       yc.client_order_id,
       yc.date_id,
       yc.multileg_reporting_type,
       yc.instrument_type_id,
       tf.trading_firm_unq_id,
       tf.trading_firm_name,
       yc.account_id,
       yc.account_name,
       yc.client_id,
       yc.instrument_id,
       i.symbol,
       yc.parent_routed_time,
       yc.order_end_time,
       co.order_cancel_time,
       yc.side,
       yc.buy_or_sell,
       yc.side_multiplier,
       yc.parent_order_qty,
       yc.parent_exec_qty,
       sum(yc.parent_exec_qty) over(),  -- yc.total_parent_exec_qty,
       yc.parent_avg_price,
       yc.principal_amount,
       ts.target_strategy_id,
       case
           when true
               then coalesce(fix_message ->> '9264', ts.target_strategy_desc)
           else ts.target_strategy_desc
           end                                                                as algorithm,
       yc.parent_nbbo_bid_price,
       yc.parent_nbbo_ask_price,
       yc.parent_nbbo_bid_qty,
       yc.parent_nbbo_ask_qty,
       yc.buy_limit_vs_ask_bps,
       yc.sell_limit_vs_bid_bps,
       yc.parent_is_marketable,
       yc.parent_limit_price,
       rt.routing_table_name,
       nullif(tca.order_arrival_price, 0)::float,
       nullif(tca.order_end_price, 0)::float,
       nullif(tca.vwap_over_life, 0)::float,
       nullif(tca.eligible_vwap_over_life, 0)::float,
       nullif(tca.twap_over_life, 0)::float,
       nullif(tca.eligible_twap_over_life, 0)::float,
       nullif(tca.volume_over_life, 0)::float,
       nullif(tca.eligible_volume_over_life, 0)::float,
       nullif(tca.pwp_5pc, 0)::float,
       nullif(tca.pwp_10pc, 0)::float,
       nullif(tca.pwp_15pc, 0)::float,
       nullif(tca.pwp_20pc, 0)::float,
       tca.trade_count,
       tca.eligible_trade_count,
       tca.block_volume,
       COALESCE((tca.eligible_volume_over_life_by_exchange ->> 'QD')::int, 0) as eligible_qd_volume,
       COALESCE((tca.eligible_volume_over_life_by_exchange ->> 'IX')::int, 0) as eligible_ix_volume,
       tca.wtd_avg_spread_arrival                                             as avg_spread_over_life,
       da.high                                                                as day_high_price,
       da.low                                                                 as day_low_price,
       da.open_price                                                          as open_px,
       da.close_price                                                         as close_px,
       prev.close_price                                                       as prev_close_px,
       nxt.close_price                                                        as next_close_px,
       yc.routing_time_mid_price,
       yc.routing_time_spread,
       coalesce(case target_strategy_desc
                    when 'POV' then public.get_message_tag_string(yc.order_fix_message_id, 9023,
                                                                  yc.date_id) --target_pov
                    when 'VOLUME  PARTICIPATION' then public.get_message_tag_string(yc.order_fix_message_id, 9023,
                                                                                    yc.date_id) --target_pov
                    when 'PHANTOM' then case public.get_message_tag_string(yc.order_fix_message_id, 9002,
                                                                           yc.date_id) --urgency
                                            when '1' then 'Low'
                                            when '2' then 'Medium'
                                            when '3' then 'High'
                        end
                    when 'VWAP' then case public.get_message_tag_string(yc.order_fix_message_id, 9002, yc.date_id)
                                         when '1' then 'Low'
                                         when '2' then 'Medium'
                                         when '3' then 'High'
                        end
                    when 'TWAP' then case public.get_message_tag_string(yc.order_fix_message_id, 9002, yc.date_id)
                                         when '1' then 'Low'
                                         when '2' then 'Medium'
                                         when '3' then 'High'
                        end
                    when 'CLOSE' then public.get_message_tag_string(yc.order_fix_message_id, 9126,
                                                                    yc.date_id) --close_aggression
                    when 'SENSOR  DARK' then 'Default  (PI  =  ' ||
                                             public.get_message_tag_string(yc.order_fix_message_id, 9191,
                                                                           yc.date_id)::text || ')'
                    else null
                    end, 'Default')                                           as aggression_level,
       i.activ_symbol,
       yc.day_order_qty,
       yc.order_qty
from trash.tmp_fyc yc
         join dwh.d_trading_firm tf on tf.trading_firm_unq_id = yc.trading_firm_unq_id
         join dwh.d_instrument i on i.instrument_id = yc.instrument_id and i.is_active
         left join dwh.d_target_strategy ts on ts.target_strategy_id = yc.sub_strategy_id and ts.is_active
         left join dwh.d_routing_table rt on rt.routing_table_id = yc.routing_table_id and rt.is_active = true
         left join eq_tca.algorithmic_order_analytic_v2 tca on tca.order_id = yc.order_id and tca.date_id = yc.date_id
         left join lateral (select *
                            from eq_tca.daily_analytic_v2 da
                            where da.symbol = i.activ_symbol
                              and da.date_id = yc.date_id
                              and da.date_id between :in_date_begin and :in_date_end
                            limit 100500) da on true
         left join lateral (select da.close_price as close_price
                            from eq_tca.daily_analytic_v2 da
                            where da.symbol = i.activ_symbol
                              and da.date_id < yc.date_id
                            order by date_id desc
                            limit 1) prev on true
         left join lateral (select da.close_price as close_price
                            from eq_tca.daily_analytic_v2 da
                            where da.symbol = i.activ_symbol
                              and da.date_id > yc.date_id
                            order by date_id
                            limit 1) nxt on true
         join LATERAL (select co.order_cancel_time, co.fix_message_id, co.create_date_id
                       from dwh.client_order co
                       where co.order_id = yc.order_id
                         and co.create_date_id = yc.date_id
                         and co.create_date_id between :in_date_begin and :in_date_end
                       limit 100500) co on true
         left join lateral (select fix_message
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = co.fix_message_id
                              and fmj.date_id = co.create_date_id
                              and fmj.date_id between :in_date_begin and :in_date_end
                            limit 1) fmj on true;


insert into trash.pre_fetch_equity_tca
with ftr as
         (select f.side,
                 f.order_id,
                 f.date_id,
                 f.side_multiplier,
                 f.last_qty,
                 f.dark_last_qty,
                 f.observed_spread_value,
                 f.last_qty * case
                                  when f.side = '1' then f.ask_price - efq_last_px
                                  else efq_last_px - f.bid_price end as dollars_saved_from_far,
                 case
                     when f.ask_price - f.bid_price <= 0 then 0
                     else f.last_qty * f.spread * (f.efq_last_px - execution_time_mid_price) /
                          half_spread end                               efq_dollars,
                 f.tcce_firm_execution_cost,
                 f.tcce_account_execution_cost,
                 f.tcce_maker_taker_fee_amount,
                 f.tcce_transaction_fee_amount,
                 f.tcce_trade_processing_fee_amount,
                 f.tcce_royalty_fee_amount,
                 f.clearing_fee_amout                                as clearing_fee_amout,
                 f.tcce_account_dash_commission_amount
          from (select ftr.order_id,
                       ftr.date_id,
                       ftr.last_qty,
                       case when real_exch_q.venue_type = 'ATS' then ftr.last_qty else 0 end  as dark_last_qty,
                       ftr.side,
                       ftr.ask_price,
                       ftr.bid_price,
                       case when ftr.side = '1' then 1 else -1 end                            as side_multiplier,
                       case
                           when ftr.last_px > ftr.ask_price then ftr.ask_price
                           when ftr.last_px < ftr.bid_price then ftr.bid_price
                           else ftr.last_px end                                                  efq_last_px,
                       0.5 * (ftr.ask_price - ftr.bid_price)                                  as half_spread,
                       (ftr.ask_price + ftr.bid_price) / 2                                    as execution_time_mid_price,
                       ftr.ask_price - ftr.bid_price                                          as spread,
                       ftr.last_qty * (ftr.ask_price - ftr.bid_price)                         as observed_spread_value,
                       ftr.last_qty * case
                                          when ftr.side = '1' then ftr.ask_price - (case
                                                                                        when ftr.last_px > ftr.ask_price
                                                                                            then ftr.ask_price
                                                                                        when ftr.last_px < ftr.bid_price
                                                                                            then ftr.bid_price
                                                                                        else ftr.last_px end)
                                          else (case
                                                    when ftr.last_px > ftr.ask_price then ftr.ask_price
                                                    when ftr.last_px < ftr.bid_price then ftr.bid_price
                                                    else ftr.last_px end) - ftr.bid_price end as dollars_saved_from_far,
                       case
                           when ftr.ask_price - ftr.bid_price <= 0 then 0
                           else ftr.last_qty * (ftr.ask_price - ftr.bid_price) * ((case
                                                                                       when ftr.last_px > ftr.ask_price
                                                                                           then ftr.ask_price
                                                                                       when ftr.last_px < ftr.bid_price
                                                                                           then ftr.bid_price
                                                                                       else ftr.last_px end) -
                                                                                  (ftr.ask_price + ftr.bid_price) / 2) /
                                (0.5 * (ftr.ask_price - ftr.bid_price)) end                      efq_dollars,
                       real_exch_q.venue_type,
                       real_exch.exchange_name,
                       --
                       ftr.tcce_firm_execution_cost,
                       ftr.tcce_account_execution_cost,
                       ftr.tcce_maker_taker_fee_amount,
                       ftr.tcce_transaction_fee_amount,
                       ftr.tcce_trade_processing_fee_amount,
                       ftr.tcce_royalty_fee_amount,
                       ftr.clearing_fee_amout                                                 as clearing_fee_amout,
                       ftr.tcce_account_dash_commission_amount
                --
                from dwh.flat_trade_record ftr
                         left join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                         left join dwh.d_exchange e on e.exchange_id = ftr.exchange_id and e.is_active
                         left join dwh.d_exchange real_exch
                                   on real_exch.exchange_id = e.real_exchange_id and real_exch.is_active
                         left join staging.real_exchange real_exch_q on real_exch_q.exchange_id = real_exch.exchange_id
                where ftr.is_busted = 'N'
                  and ftr.date_id between :in_date_begin and :in_date_end
                  and ftr.instrument_type_id = 'E'
                  and ftr.multileg_reporting_type = '1') f)
select tp.order_id,
       tp.client_order_id,
       tp.date_id,
       tp.multileg_reporting_type,
       tp.instrument_type_id,
       tp.trading_firm_unq_id,
       tp.trading_firm_name,
       tp.account_id,
       tp.account_name,
       tp.client_id,
       tp.instrument_id,
       tp.symbol,
       tp.parent_routed_time,
       tp.order_end_time,
       tp.order_cancel_time,
       tp.side,
       tp.buy_or_sell,
       tp.side_multiplier,
       tp.parent_order_qty,
       tp.parent_exec_qty,
       tp.total_parent_exec_qty,
       tp.parent_avg_price,
       tp.principal_amount,
       tp.target_strategy_id,
       tp.algorithm,
       tp.parent_nbbo_bid_price,
       tp.parent_nbbo_ask_price,
       tp.parent_nbbo_bid_qty,
       tp.parent_nbbo_ask_qty,
       tp.buy_limit_vs_ask_bps,
       tp.sell_limit_vs_bid_bps,
       tp.parent_is_marketable,
       tp.parent_limit_price,
       tp.routing_table_name,
       tp.order_arrival_price,
       tp.order_end_price,
       tp.vwap_over_life,
       tp.eligible_vwap_over_life,
       tp.twap_over_life,
       tp.eligible_twap_over_life,
       tp.volume_over_life,
       tp.eligible_volume_over_life,
       tp.eligible_pwp_5pc,
       tp.eligible_pwp_10pc,
       tp.eligible_pwp_15pc,
       tp.eligible_pwp_20pc,
       tp.trade_count,
       tp.eligible_trade_count,
       tp.block_volume,
       tp.eligible_qd_volume,
       tp.eligible_ix_volume,
       tp.avg_spread_over_life,
       tp.day_high_price,
       tp.day_low_price,
       tp.open_px,
       tp.close_px,
       tp.prev_close_px,
       tp.next_close_px,
       tr.trades_count,
       tr.avg_exec_qty,
       dea.as 5d_avg_spread_bpsas  avg_bid_ask_spread_5d_bps,
       tp.routing_time_mid_price,
       tp.routing_time_spread,
       tr.efq_dollars,
       tr.observed_spread_value,
       tr.spread_saving,
       tr.dark_shares_executed,
       dea.scale_market_cap_id,
       case
           when (case when tp.day_order_qty < tp.order_qty then tp.day_order_qty else tp.order_qty end) /
                dea.average_volume_22day::float = 0 then 0
           when (case when tp.day_order_qty < tp.order_qty then tp.day_order_qty else tp.order_qty end) /
                dea.average_volume_22day::float between 0.0000001 and 0.01 then 1
           when (case when tp.day_order_qty < tp.order_qty then tp.day_order_qty else tp.order_qty end) /
                dea.average_volume_22day::float between 0.0099999 and 0.05 then 2
           when (case when tp.day_order_qty < tp.order_qty then tp.day_order_qty else tp.order_qty end) /
                dea.average_volume_22day::float between 0.0499999 and 0.1 then 3
           when (case when tp.day_order_qty < tp.order_qty then tp.day_order_qty else tp.order_qty end) /
                dea.average_volume_22day::float between 0.0999999 and 0.25 then 4
           when (case when tp.day_order_qty < tp.order_qty then tp.day_order_qty else tp.order_qty end) /
                dea.average_volume_22day::float between 0.2499999 and 0.5 then 5
           when (case when tp.day_order_qty < tp.order_qty then tp.day_order_qty else tp.order_qty end) /
                dea.average_volume_22day::float between 0.4999999 and 1 then 6
           else 9::float
           end     as          adv_pct,
       dea.sector,
       --todo:  decode  FIX  tag  values  to  proper  description
       tp.aggression_level,
       tr.net_fees_rebates_amount,
       tr.clearing_amount,
       tr.commission_amount,
       ---
       tr.last_qty as          last_qty
from trash.pre_pre_fetch_equity_tca as tp
         --ftr  join
         left join lateral
    (
    select count(*)                                                                                     as trades_count,
           avg(ftr.last_qty)                                                                            as avg_exec_qty,
           sum(side_multiplier * efq_dollars) / sum(observed_spread_value)                              as eq,
           sum(side_multiplier * efq_dollars)                                                           as efq_dollars,
           sum(observed_spread_value)                                                                   as observed_spread_value,
           sum(dollars_saved_from_far)                                                                  as spread_saving,
           sum(dark_last_qty)                                                                           as dark_shares_executed,
           --
           --sum(coalesce(tcce_maker_taker_fee_amount,  0.0)  +  coalesce(tcce_transaction_fee_amount,  0.0)  +  coalesce(tcce_trade_processing_fee_amount,  0.0)  +  coalesce(tcce_royalty_fee_amount,  0.0))  as  net_fees_rebates_amount,
           --sum(tcce_account_execution_cost)  as  net_fees_rebates_amount,
           sum(coalesce(tcce_maker_taker_fee_amount, 0.0) +
               coalesce(tcce_transaction_fee_amount, 0.0))                                              as net_fees_rebates_amount,
           sum(clearing_fee_amout)                                                                      as clearing_amount,
           sum(tcce_account_dash_commission_amount)                                                     as commission_amount,
           --
           sum(last_qty)                                                                                as last_qty
    from ftr
    where ftr.order_id = tp.order_id
      and ftr.date_id = tp.date_id
    limit 1
    ) tr on 1 = 1
    --dea  join
         left join lateral
    (
    select dea.activ_symbol,
           dea.date_id                           as activ_analytic_date,
           mc.scale_market_cap,
           dea.sector,
           dea.scale_market_cap_id,
           dea.average_volume_22day,
           dea.as 5d_avg_bid_ask_spread ,
           dea.as 5d_avg_bid_ask_spread_pctas  * 100 as as 5d_avg_spread_bpsas 
    from data_marts.f_daily_equity_analytics dea
             left join data_marts.d_scale_market_cap mc on mc.scale_market_cap_id = dea.scale_market_cap_id
    where date_id between :in_date_begin and :in_date_end
      and date_id = tp.date_id
      and dea.activ_symbol = tp.activ_symbol
    limit 1
    ) dea on 1 = 1;



create table if not exists trash.pre_fetch_equity_tca_venue as
select yc.order_id,
       yc.day_order_qty,
       yc.exchange_id,
       coalesce(re.exchange_name, e.exchange_name)    as exchange_name,
       re.venue_type,
       ot.hierarchy_1                                 as order_type,
       yc.trading_firm_unq_id,
       --ftr.order_id,
       ftr.street_order_qty,
       ftr.date_id,
       ftr.last_qty,
       case
           when ftr.side = '1' then 1
           else -1
           end                                        as side_multiplier,
       case
           when ftr.last_px > ftr.ask_price then ftr.ask_price
           when ftr.last_px < ftr.bid_price then ftr.bid_price
           else ftr.last_px
           end                                           efq_last_px,
       ftr.last_qty * (ftr.ask_price - ftr.bid_price) as observed_spread_value,
       ftr.last_qty * case
                          when ftr.side = '1' then ftr.ask_price - (case
                                                                        when ftr.last_px > ftr.ask_price
                                                                            then ftr.ask_price
                                                                        when ftr.last_px < ftr.bid_price
                                                                            then ftr.bid_price
                                                                        else ftr.last_px end)
                          else (case
                                    when ftr.last_px > ftr.ask_price then ftr.ask_price
                                    when ftr.last_px < ftr.bid_price then ftr.bid_price
                                    else ftr.last_px end) - ftr.bid_price
           end                                        as dollars_saved_from_far,
       case
           when ftr.ask_price - ftr.bid_price <= 0 then 0
           else ftr.last_qty * (ftr.ask_price - ftr.bid_price) * ((case
                                                                       when ftr.last_px > ftr.ask_price
                                                                           then ftr.ask_price
                                                                       when ftr.last_px < ftr.bid_price
                                                                           then ftr.bid_price
                                                                       else ftr.last_px end) -
                                                                  (ftr.ask_price + ftr.bid_price) / 2) /
                (0.5 * (ftr.ask_price - ftr.bid_price))
           end                                           efq_dollars,
       case
           when ftr.side = '1' and (rev.p10ms_bid + rev.p10ms_ask) > (ftr.bid_price + ftr.ask_price) then 0
           when ftr.side <> '1' and (rev.p10ms_bid + rev.p10ms_ask) < (ftr.bid_price + ftr.ask_price) then 0
           when ftr.side = '1' and (rev.p10ms_bid + rev.p10ms_ask) <= (ftr.bid_price + ftr.ask_price) then 1
           when ftr.side <> '1' and (rev.p10ms_bid + rev.p10ms_ask) >= (ftr.bid_price + ftr.ask_price) then 1
           end                                        as midpont_stability,
       --
       ftr.tcce_firm_execution_cost                   as net_fees_rebates_amount,
       ftr.clearing_fee_amout                         as clearing_amount,
       ftr.tcce_account_dash_commission_amount        as commission_amount,
       --
       row_number() over (partition by yc.order_id)   as rn
from data_marts.f_yield_capture yc
         left join dwh.flat_trade_record ftr
                   on (ftr.street_order_id = yc.order_id and ftr.date_id between :in_date_begin and :in_date_end)
         left join dwh.d_exchange e on (e.exchange_id = yc.exchange_id and e.is_active)
         left join staging.real_exchange re on re.exchange_id = e.real_exchange_id and e.is_active
         left join eq_tca.order_type_mapping ot on ot.order_type_unq_id = yc.order_type_mapping_id
         join dwh.d_account a on a.account_id = yc.account_id
         left join eq_tca.eq_rev_ft rev on (rev.trade_record_id = ftr.trade_record_id and
                                            num_nulls(p0ms_bid, p0ms_ask, p10ms_bid, p10ms_ask) = 0 and
                                            rev.date_id between :in_date_begin and :in_date_end)
         left join dwh.d_target_strategy dts on dts.target_strategy_id = yc.sub_strategy_id
         join trash.tmp_fyc par on par.order_id = yc.parent_order_id
where yc.status_date_id between :in_date_begin and :in_date_end
  and yc.instrument_type_id = 'E'
  and yc.multileg_reporting_type = '1'
  and yc.exchange_id is not null;


select * from trash.pre_fetch_equity_tca_venue


select 1 = any(:in_step);

  create or replace function trash.tca_report_q_step_by_step(in_date_begin int4, in_date_end int4, in_step int4[])
      returns int4
      language plpgsql
  as
  $$
  declare
      l_row_cnt int4;
  begin
      if 1 = any (in_step) then
          insert into trash.tmp_fyc
          select yc.order_id,
                 yc.client_order_id,
                 yc.status_date_id                                        as date_id,
                 yc.multileg_reporting_type,
                 yc.instrument_type_id,
                 yc.account_id,
                 a.account_name,
                 yc.client_id,
                 yc.instrument_id,
                 yc.routed_time                                           as parent_routed_time,
                 yc.order_end_time,
                 yc.side,
                 yc.buy_or_sell,
                 (case when yc.buy_or_sell = 'B' then 1 else -1 end)::int as side_multiplier,
                 case
                     when yc.day_order_qty < yc.order_qty then yc.day_order_qty
                     else yc.order_qty end                                as parent_order_qty,
                 yc.day_cum_qty                                           as parent_exec_qty,
--            sum(yc.day_cum_qty) over (partition by true)                                          as total_parent_exec_qty,
                 yc.avg_px                                                as parent_avg_price,
                 yc.avg_px * yc.day_cum_qty                               as principal_amount,
                 yc.nbbo_bid_price                                        as parent_nbbo_bid_price,
                 yc.nbbo_ask_price                                        as parent_nbbo_ask_price,
                 yc.nbbo_bid_quantity                                     as parent_nbbo_bid_qty,
                 yc.nbbo_ask_quantity                                     as parent_nbbo_ask_qty,
                 case
                     when yc.side = '1' then 10000 * (yc.order_price - yc.nbbo_ask_price) /
                                             coalesce(yc.nbbo_ask_price, 0, null)
                     else null end                                        as buy_limit_vs_ask_bps,
                 case
                     when yc.side <> '1' then 10000 * (yc.order_price - yc.nbbo_bid_price) /
                                              coalesce(yc.nbbo_bid_price, 0, null)
                     else null end                                        as sell_limit_vs_bid_bps,
                 yc.is_marketable                                         as parent_is_marketable,
                 yc.order_price                                           as parent_limit_price,
                 (yc.nbbo_ask_price + yc.nbbo_bid_price) / 2                 routing_time_mid_price,
                 yc.nbbo_ask_price - yc.nbbo_bid_price                       routing_time_spread,
                 yc.trading_firm_unq_id,
                 yc.sub_strategy_id,
                 yc.routing_table_id,
                 yc.order_fix_message_id,
                 yc.day_order_qty,
                 yc.order_qty,
--                 co.order_cancel_time,
                 fmj.tag_9002,
                 fmj.tag_9023,
                 fmj.tag_9126,
                 fmj.tag_9191,
                 fmj.tag_9264
          from data_marts.f_yield_capture yc
                   join lateral (select account_name
                                 from dwh.d_account a
                                 where a.account_id = yc.account_id
                                   and a.is_active
                                 limit 1) a on true
                   left join dwh.d_target_strategy dts on dts.target_strategy_id = yc.sub_strategy_id

              --                   join LATERAL (select order_cancel_time
--                                 from dwh.client_order co
--                                 where co.order_id = yc.order_id
--                                   and co.create_date_id = yc.status_date_id
--                                   and co.create_date_id between in_date_begin and in_date_end
--                                 limit 1) co on true
                   left join lateral (select fix_message ->> '9264' as tag_9264,
                                             fix_message ->> '9023' as tag_9023,
                                             fix_message ->> '9002' as tag_9002,
                                             fix_message ->> '9126' as tag_9126,
                                             fix_message ->> '9191' as tag_9191
                                      from fix_capture.fix_message_json fmj
                                      where fmj.fix_message_id = yc.order_fix_message_id--co.fix_message_id
                                        and fmj.date_id = yc.status_date_id
                                        and fmj.date_id >= in_date_begin
                                        and fmj.date_id <= in_date_end
                                      limit 1) fmj on true

          where yc.parent_order_id is null
            and yc.status_date_id between in_date_begin and in_date_end
            and yc.instrument_type_id = 'E'
            and yc.multileg_reporting_type = '1';
      end if;
      get diagnostics l_row_cnt = row_count;

      if 2 = any (in_step) then
          insert into trash.pre_pre_fetch_equity_tca (order_id, client_order_id, date_id, multileg_reporting_type,
                                                      instrument_type_id,
                                                      trading_firm_unq_id, trading_firm_name, account_id, account_name,
                                                      client_id,
                                                      instrument_id, symbol, parent_routed_time, order_end_time,
                                                      order_cancel_time,
                                                      side, buy_or_sell, side_multiplier, parent_order_qty,
                                                      parent_exec_qty,
                                                      total_parent_exec_qty,
                                                      parent_avg_price, principal_amount,
                                                      target_strategy_id,
                                                      algorithm, parent_nbbo_bid_price, parent_nbbo_ask_price,
                                                      parent_nbbo_bid_qty,
                                                      parent_nbbo_ask_qty, buy_limit_vs_ask_bps, sell_limit_vs_bid_bps,
                                                      parent_is_marketable, parent_limit_price, routing_table_name,
                                                      order_arrival_price,
                                                      order_end_price, vwap_over_life, eligible_vwap_over_life,
                                                      twap_over_life,
                                                      eligible_twap_over_life, volume_over_life,
                                                      eligible_volume_over_life,
                                                      eligible_pwp_5pc, eligible_pwp_10pc, eligible_pwp_15pc,
                                                      eligible_pwp_20pc,
                                                      trade_count, eligible_trade_count, block_volume,
                                                      eligible_qd_volume,
                                                      eligible_ix_volume, avg_spread_over_life, day_high_price,
                                                      day_low_price,
                                                      open_px,
                                                      close_px, prev_close_px, next_close_px, routing_time_mid_price,
                                                      routing_time_spread, aggression_level, activ_symbol,
                                                      day_order_qty,
                                                      order_qty)
          select yc.order_id,
                 yc.client_order_id,
                 yc.date_id,
                 yc.multileg_reporting_type,
                 yc.instrument_type_id,
                 tf.trading_firm_unq_id,
                 tf.trading_firm_name,
                 yc.account_id,
                 yc.account_name,
                 yc.client_id,
                 yc.instrument_id,
                 i.symbol,
                 yc.parent_routed_time,
                 yc.order_end_time,
                 co.order_cancel_time,
                 yc.side,
                 yc.buy_or_sell,
                 yc.side_multiplier,
                 yc.parent_order_qty,
                 yc.parent_exec_qty,
                 sum(yc.parent_exec_qty) over () as total_parent_exec_qty,
                 yc.parent_avg_price,
                 yc.principal_amount,
                 ts.target_strategy_id,
                 case
                     when true
                         then coalesce(fix_message ->> '9264', ts.target_strategy_desc)
                     else ts.target_strategy_desc
                     end                                                                as algorithm,
                 yc.parent_nbbo_bid_price,
                 yc.parent_nbbo_ask_price,
                 yc.parent_nbbo_bid_qty,
                 yc.parent_nbbo_ask_qty,
                 yc.buy_limit_vs_ask_bps,
                 yc.sell_limit_vs_bid_bps,
                 yc.parent_is_marketable,
                 yc.parent_limit_price,
                 rt.routing_table_name,
                 nullif(tca.order_arrival_price, 0)::float,
                 nullif(tca.order_end_price, 0)::float,
                 nullif(tca.vwap_over_life, 0)::float,
                 nullif(tca.eligible_vwap_over_life, 0)::float,
                 nullif(tca.twap_over_life, 0)::float,
                 nullif(tca.eligible_twap_over_life, 0)::float,
                 nullif(tca.volume_over_life, 0)::float,
                 nullif(tca.eligible_volume_over_life, 0)::float,
                 nullif(tca.pwp_5pc, 0)::float,
                 nullif(tca.pwp_10pc, 0)::float,
                 nullif(tca.pwp_15pc, 0)::float,
                 nullif(tca.pwp_20pc, 0)::float,
                 tca.trade_count,
                 tca.eligible_trade_count,
                 tca.block_volume,
                 COALESCE((tca.eligible_volume_over_life_by_exchange ->> 'QD')::int, 0) as eligible_qd_volume,
                 COALESCE((tca.eligible_volume_over_life_by_exchange ->> 'IX')::int, 0) as eligible_ix_volume,
                 tca.wtd_avg_spread_arrival                                             as avg_spread_over_life,
                 da.high                                                                as day_high_price,
                 da.low                                                                 as day_low_price,
                 da.open_price                                                          as open_px,
                 da.close_price                                                         as close_px,
                 prev.close_price                                                       as prev_close_px,
                 nxt.close_price                                                        as next_close_px,
                 yc.routing_time_mid_price,
                 yc.routing_time_spread,
                 coalesce(case target_strategy_desc
                              when 'POV' then public.get_message_tag_string(yc.order_fix_message_id, 9023,
                                                                            yc.date_id) --target_pov
                              when 'VOLUME  PARTICIPATION' then public.get_message_tag_string(yc.order_fix_message_id,
                                                                                              9023,
                                                                                              yc.date_id) --target_pov
                              when 'PHANTOM' then case public.get_message_tag_string(yc.order_fix_message_id, 9002,
                                                                                     yc.date_id) --urgency
                                                      when '1' then 'Low'
                                                      when '2' then 'Medium'
                                                      when '3' then 'High'
                                  end
                              when 'VWAP' then case public.get_message_tag_string(yc.order_fix_message_id, 9002,
                                                                                  yc.date_id)
                                                   when '1' then 'Low'
                                                   when '2' then 'Medium'
                                                   when '3' then 'High'
                                  end
                              when 'TWAP' then case public.get_message_tag_string(yc.order_fix_message_id, 9002,
                                                                                  yc.date_id)
                                                   when '1' then 'Low'
                                                   when '2' then 'Medium'
                                                   when '3' then 'High'
                                  end
                              when 'CLOSE' then public.get_message_tag_string(yc.order_fix_message_id, 9126,
                                                                              yc.date_id) --close_aggression
                              when 'SENSOR  DARK' then 'Default  (PI  =  ' ||
                                                       public.get_message_tag_string(yc.order_fix_message_id, 9191,
                                                                                     yc.date_id)::text || ')'
                              else null
                              end, 'Default')                                           as aggression_level,
                 i.activ_symbol,
                 yc.day_order_qty,
                 yc.order_qty
          from trash.tmp_fyc yc
                   join dwh.d_trading_firm tf on tf.trading_firm_unq_id = yc.trading_firm_unq_id
                   join dwh.d_instrument i on i.instrument_id = yc.instrument_id and i.is_active
                   left join dwh.d_target_strategy ts on ts.target_strategy_id = yc.sub_strategy_id and ts.is_active
                   left join dwh.d_routing_table rt on rt.routing_table_id = yc.routing_table_id and rt.is_active = true
                   left join eq_tca.algorithmic_order_analytic_v2 tca
                             on tca.order_id = yc.order_id and tca.date_id = yc.date_id
                   left join lateral (select *
                                      from eq_tca.daily_analytic_v2 da
                                      where da.symbol = i.activ_symbol
                                        and da.date_id = yc.date_id
                                        and da.date_id between in_date_begin and in_date_end
                                      limit 100500) da on true
                   left join lateral (select da.close_price as close_price
                                      from eq_tca.daily_analytic_v2 da
                                      where da.symbol = i.activ_symbol
                                        and da.date_id < yc.date_id
                                      order by date_id desc
                                      limit 1) prev on true
                   left join lateral (select da.close_price as close_price
                                      from eq_tca.daily_analytic_v2 da
                                      where da.symbol = i.activ_symbol
                                        and da.date_id > yc.date_id
                                      order by date_id
                                      limit 1) nxt on true
                   join LATERAL (select co.order_cancel_time, co.fix_message_id, co.create_date_id
                                 from dwh.client_order co
                                 where co.order_id = yc.order_id
                                   and co.create_date_id = yc.date_id
                                   and co.create_date_id between in_date_begin and in_date_end
                                 limit 100500) co on true
                   left join lateral (select fix_message
                                      from fix_capture.fix_message_json fmj
                                      where fmj.fix_message_id = co.fix_message_id
                                        and fmj.date_id = co.create_date_id
                                        and fmj.date_id between in_date_begin and in_date_end
                                      limit 1) fmj on true;
          get diagnostics l_row_cnt = row_count;
          return l_row_cnt;
      end if;
  end;

  $$



CREATE TABLE trash.pre_pre_fetch_equity_tca (
	order_id int8 NULL,
	client_order_id varchar(256) NULL,
	date_id int4 NULL,
	multileg_reporting_type bpchar(1) NULL,
	instrument_type_id bpchar(1) NULL,
	trading_firm_unq_id int4 NULL,
	trading_firm_name varchar(60) NULL,
	account_id int8 NULL,
	account_name varchar(30) NULL,
	client_id varchar(255) NULL,
	instrument_id int4 NULL,
	symbol varchar(10) NULL,
	parent_routed_time timestamp NULL,
	order_end_time timestamp NULL,
	order_cancel_time timestamp(3) NULL,
	side bpchar(1) NULL,
	buy_or_sell bpchar(1) NULL,
	side_multiplier int4 NULL,
	parent_order_qty int4 NULL,
	parent_exec_qty int4 NULL,
	total_parent_exec_qty int8 NULL,
	parent_avg_price numeric NULL,
	principal_amount numeric NULL,
	target_strategy_id int4 NULL,
	algorithm varchar(128) NULL,
	parent_nbbo_bid_price numeric(12, 4) NULL,
	parent_nbbo_ask_price numeric(12, 4) NULL,
	parent_nbbo_bid_qty int4 NULL,
	parent_nbbo_ask_qty int4 NULL,
	buy_limit_vs_ask_bps numeric NULL,
	sell_limit_vs_bid_bps numeric NULL,
	parent_is_marketable bpchar(1) NULL,
	parent_limit_price numeric(12, 4) NULL,
	routing_table_name varchar(30) NULL,
	order_arrival_price float8 NULL,
	order_end_price float8 NULL,
	vwap_over_life float8 NULL,
	eligible_vwap_over_life float8 NULL,
	twap_over_life float8 NULL,
	eligible_twap_over_life float8 NULL,
	volume_over_life float8 NULL,
	eligible_volume_over_life float8 NULL,
	eligible_pwp_5pc float8 NULL,
	eligible_pwp_10pc float8 NULL,
	eligible_pwp_15pc float8 NULL,
	eligible_pwp_20pc float8 NULL,
	trade_count int4 NULL,
	eligible_trade_count int4 NULL,
	block_volume int4 NULL,
	eligible_qd_volume int4 NULL,
	eligible_ix_volume int4 NULL,
	avg_spread_over_life numeric NULL,
	day_high_price numeric NULL,
	day_low_price numeric NULL,
	open_px numeric NULL,
	close_px numeric NULL,
	prev_close_px numeric NULL,
	next_close_px numeric NULL,
	routing_time_mid_price numeric NULL,
	routing_time_spread numeric NULL,
	aggression_level text NULL,
	activ_symbol varchar(30) NULL,
	day_order_qty int4 NULL,
	order_qty int4 NULL
);