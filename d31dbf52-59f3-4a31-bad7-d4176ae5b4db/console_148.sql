select coalesce(:in_date_begin, to_char(date_trunc('quarter', current_date - interval '3 month'),
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
                       where a.account_id = yc.account_id
                         and a.is_active
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
       sum(yc.parent_exec_qty) over (), -- yc.total_parent_exec_qty,
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
       dea.as 5d_avg_spread_bpsas  avg_bid_ask_spread_5d_bps, tp.routing_time_mid_price,
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
           end     as adv_pct,
       dea.sector,
       --todo:  decode  FIX  tag  values  to  proper  description
       tp.aggression_level,
       tr.net_fees_rebates_amount,
       tr.clearing_amount,
       tr.commission_amount,
       ---
       tr.last_qty as last_qty
from trash.pre_pre_fetch_equity_tca as tp
         --ftr  join
         left join lateral
    (
    select count(*)                                                        as trades_count,
           avg(ftr.last_qty)                                               as avg_exec_qty,
           sum(side_multiplier * efq_dollars) / sum(observed_spread_value) as eq,
           sum(side_multiplier * efq_dollars)                              as efq_dollars,
           sum(observed_spread_value)                                      as observed_spread_value,
           sum(dollars_saved_from_far)                                     as spread_saving,
           sum(dark_last_qty)                                              as dark_shares_executed,
           --
           --sum(coalesce(tcce_maker_taker_fee_amount,  0.0)  +  coalesce(tcce_transaction_fee_amount,  0.0)  +  coalesce(tcce_trade_processing_fee_amount,  0.0)  +  coalesce(tcce_royalty_fee_amount,  0.0))  as  net_fees_rebates_amount,
           --sum(tcce_account_execution_cost)  as  net_fees_rebates_amount,
           sum(coalesce(tcce_maker_taker_fee_amount, 0.0) +
               coalesce(tcce_transaction_fee_amount, 0.0))                 as net_fees_rebates_amount,
           sum(clearing_fee_amout)                                         as clearing_amount,
           sum(tcce_account_dash_commission_amount)                        as commission_amount,
           --
           sum(last_qty)                                                   as last_qty
    from ftr
    where ftr.order_id = tp.order_id
      and ftr.date_id = tp.date_id
    limit 1
    ) tr on 1 = 1
    --dea  join
         left join lateral
    (
    select dea.activ_symbol,
           dea.date_id as activ_analytic_date,
           mc.scale_market_cap,
           dea.sector,
           dea.scale_market_cap_id,
           dea.average_volume_22day,
           dea.as 5d_avg_bid_ask_spread , dea.as 5d_avg_bid_ask_spread_pctas  * 100 as as 5 d_avg_spread_bpsas
from data_marts.f_daily_equity_analytics dea
    left join data_marts.d_scale_market_cap mc
on mc.scale_market_cap_id = dea.scale_market_cap_id
where date_id between :in_date_begin
  and :in_date_end
  and date_id = tp.date_id
  and dea.activ_symbol = tp.activ_symbol
limit 1 ) dea
on 1 = 1;



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


select *
from trash.pre_fetch_equity_tca_venue

create or replace function trash.tca_report_q_step_by_step(in_date_begin int4, in_date_end int4, in_step int4[])
    returns int4
    language plpgsql
as
$$
declare
    declare
    l_step_id int4;
    l_load_id int4;
    l_row_cnt int4;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'report_equity_tca step-by-step  STARTED  ====', 0, 'O')
    into l_step_id;

    if 1 = any (in_step) then
        select public.load_log(l_load_id, l_step_id, 'step 1  STARTED  ====', 0, 'O')
        into l_step_id;
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
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, 'step 1  COMPLETED  ====', l_row_cnt, 'O')
        into l_step_id;
    end if;


    if 2 = any (in_step) then
        select public.load_log(l_load_id, l_step_id, 'step 2  STARTED  ====', 0, 'O')
        into l_step_id;

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
               sum(yc.parent_exec_qty) over ()                                        as total_parent_exec_qty,
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
        select public.load_log(l_load_id, l_step_id, 'step 2  COMPLETED  ====', l_row_cnt, 'O')
        into l_step_id;
    end if;

    if 3 = any (in_step) then
        select public.load_log(l_load_id, l_step_id, 'step 3  STARTED  ====', 0, 'O')
        into l_step_id;
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
                                  half_spread end                            as efq_dollars,
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
                               case when real_exch_q.venue_type = 'ATS' then ftr.last_qty else 0 end as dark_last_qty,
                               ftr.side,
                               ftr.ask_price,
                               ftr.bid_price,
                               case when ftr.side = '1' then 1 else -1 end                           as side_multiplier,
                               case
                                   when ftr.last_px > ftr.ask_price then ftr.ask_price
                                   when ftr.last_px < ftr.bid_price then ftr.bid_price
                                   else ftr.last_px end                                                 efq_last_px,
                               0.5 * (ftr.ask_price - ftr.bid_price)                                 as half_spread,
                               (ftr.ask_price + ftr.bid_price) / 2                                   as execution_time_mid_price,
                               ftr.ask_price - ftr.bid_price                                         as spread,
                               ftr.last_qty * (ftr.ask_price - ftr.bid_price)                        as observed_spread_value,
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
                                                            else ftr.last_px end) -
                                                       ftr.bid_price end                             as dollars_saved_from_far,
                               case
                                   when ftr.ask_price - ftr.bid_price <= 0 then 0
                                   else ftr.last_qty * (ftr.ask_price - ftr.bid_price) * ((case
                                                                                               when ftr.last_px > ftr.ask_price
                                                                                                   then ftr.ask_price
                                                                                               when ftr.last_px < ftr.bid_price
                                                                                                   then ftr.bid_price
                                                                                               else ftr.last_px end) -
                                                                                          (ftr.ask_price + ftr.bid_price) /
                                                                                          2) /
                                        (0.5 * (ftr.ask_price - ftr.bid_price)) end                     efq_dollars,
                               real_exch_q.venue_type,
                               real_exch.exchange_name,
                               --
                               ftr.tcce_firm_execution_cost,
                               ftr.tcce_account_execution_cost,
                               ftr.tcce_maker_taker_fee_amount,
                               ftr.tcce_transaction_fee_amount,
                               ftr.tcce_trade_processing_fee_amount,
                               ftr.tcce_royalty_fee_amount,
                               ftr.clearing_fee_amout                                                as clearing_fee_amout,
                               ftr.tcce_account_dash_commission_amount
                        --
                        from dwh.flat_trade_record ftr
                                 left join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                                 left join dwh.d_exchange e on e.exchange_id = ftr.exchange_id and e.is_active
                                 left join dwh.d_exchange real_exch
                                           on real_exch.exchange_id = e.real_exchange_id and real_exch.is_active
                                 left join staging.real_exchange real_exch_q
                                           on real_exch_q.exchange_id = real_exch.exchange_id
                        where ftr.is_busted = 'N'
                          and ftr.date_id between in_date_begin and in_date_end
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
               dea."5d_avg_spread_bps" avg_bid_ask_spread_5d_bps,
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
            select count(*)                                                        as trades_count,
                   avg(ftr.last_qty)                                               as avg_exec_qty,
                   sum(side_multiplier * efq_dollars) / sum(observed_spread_value) as eq,
                   sum(side_multiplier * efq_dollars)                              as efq_dollars,
                   sum(observed_spread_value)                                      as observed_spread_value,
                   sum(dollars_saved_from_far)                                     as spread_saving,
                   sum(dark_last_qty)                                              as dark_shares_executed,
                   --
                   --sum(coalesce(tcce_maker_taker_fee_amount,  0.0)  +  coalesce(tcce_transaction_fee_amount,  0.0)  +  coalesce(tcce_trade_processing_fee_amount,  0.0)  +  coalesce(tcce_royalty_fee_amount,  0.0))  as  net_fees_rebates_amount,
                   --sum(tcce_account_execution_cost)  as  net_fees_rebates_amount,
                   sum(coalesce(tcce_maker_taker_fee_amount, 0.0) +
                       coalesce(tcce_transaction_fee_amount, 0.0))                 as net_fees_rebates_amount,
                   sum(clearing_fee_amout)                                         as clearing_amount,
                   sum(tcce_account_dash_commission_amount)                        as commission_amount,
                   --
                   sum(last_qty)                                                   as last_qty
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
                   dea."5d_avg_bid_ask_spread",
                   dea."5d_avg_bid_ask_spread_pct" * 100 as "5d_avg_spread_bps"
            from data_marts.f_daily_equity_analytics dea
                     left join data_marts.d_scale_market_cap mc on mc.scale_market_cap_id = dea.scale_market_cap_id
            where date_id between in_date_begin and in_date_end
              and date_id = tp.date_id
              and dea.activ_symbol = tp.activ_symbol
            limit 1
            ) dea on true;
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, 'step 3  COMPLETED  ====', l_row_cnt, 'O')
        into l_step_id;
    end if;

    if 4 = any (in_step) then
        select public.load_log(l_load_id, l_step_id, 'step 4  STARTED  ====', 0, 'O')
        into l_step_id;

        insert into trash.pre_fetch_equity_tca_venue
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
                 join trash.tmp_fyc par on par.order_id = yc.parent_order_id
                 left join dwh.flat_trade_record ftr on (ftr.street_order_id = yc.order_id and
                                                         ftr.date_id between in_date_begin and in_date_end)
                 left join dwh.d_exchange e on (e.exchange_id = yc.exchange_id and e.is_active)
                 left join staging.real_exchange re on re.exchange_id = e.real_exchange_id and e.is_active
                 left join eq_tca.order_type_mapping ot on ot.order_type_unq_id = yc.order_type_mapping_id
                 join dwh.d_account a on a.account_id = yc.account_id
                 left join eq_tca.eq_rev_ft rev on (rev.trade_record_id = ftr.trade_record_id and
                                                    num_nulls(p0ms_bid, p0ms_ask, p10ms_bid, p10ms_ask) = 0 and
                                                    rev.date_id between in_date_begin and in_date_end)
                 left join dwh.d_target_strategy dts on dts.target_strategy_id = yc.sub_strategy_id

        where yc.status_date_id between in_date_begin and in_date_end
          and yc.instrument_type_id = 'E'
          and yc.multileg_reporting_type = '1'
          and yc.exchange_id is not null;

        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, 'step 4  COMPLETED  ====', l_row_cnt, 'O')
        into l_step_id;
    end if;


    return l_row_cnt;
end;

$$;



create index on trash.pre_fetch_equity_tca (side);
create index on trash.pre_fetch_equity_tca (scale_market_cap_id);
create index on trash.pre_fetch_equity_tca (sector);
create index on trash.pre_fetch_equity_tca (adv_pct);
create index on trash.pre_fetch_equity_tca (algorithm);
create index on trash.pre_fetch_equity_tca (date_id);
create index on trash.pre_fetch_equity_tca (symbol);
create index on trash.pre_fetch_equity_tca (aggression_level);
create index on trash.pre_fetch_equity_tca (account_name);
create index on trash.pre_fetch_equity_tca (client_id);

----
-- DROP FUNCTION dash360.report_equity_tca_v2(int4);

CREATE FUNCTION trash.report_equity_tca_v2(in_group_by integer)
 RETURNS TABLE(group_name integer, grouped_by text, order_count bigint, shares_ordered bigint, avg_shares_per_order numeric, child_executions numeric, shares_executed bigint, principal_amount numeric, total_shares_executed_pct double precision, avg_exec_qty numeric, total_volume_participation_pct double precision, marketable_volume_participation_pct double precision, dark_volume_participation_pct double precision, prev_close_px_bps double precision, open_px_bps double precision, arrival_px_px_bps double precision, eligible_pwp_5pc_bps double precision, eligible_pwp_10pc_bps double precision, eligible_pwp_15pc_bps double precision, eligible_pwp_20pc_bps double precision, twap_over_life_bps double precision, eligible_twap_over_life_bps double precision, vwap_over_life_bps double precision, eligible_vwap_over_life_bps double precision, last_px_bps double precision, close_px_bps double precision, prev_close_px_value numeric, open_px_value numeric, arrival_px_px_value double precision, eligible_pwp_5pc_value double precision, eligible_pwp_10pc_value double precision, eligible_pwp_15pc_value double precision, eligible_pwp_20pc_value double precision, twap_over_life_value double precision, eligible_twap_over_life_value double precision, vwap_over_life_value double precision, eligible_vwap_over_life_value double precision, last_px_value double precision, close_px_value numeric, spread_5d_bps numeric, observed_spread numeric, efq numeric, spread_saving numeric, spread_saving_bps numeric, spread_saving_mils numeric, orders_with_limit_pct double precision, orders_with_limit_not_marketable_pct double precision, buy_limit_vs_ask_bps numeric, sell_limit_vs_bid_bps numeric, net_fees_rebates_mils numeric, commission_mils numeric, total_costs_mils numeric, net_fees_rebates_amount numeric, commission_amount numeric, total_costs_amount numeric)
 LANGUAGE plpgsql
AS $function$
begin
	-- Created by PD 2022/05/25
	-- 2022-02-06 PD added round(,15) to spread_5d_bps, principal_amount
	-- 2022-06-21 PD added round(,15) to prev_close_px_value
	-- 2023-08-17 PD added round(,15) to buy_limit_vs_ask_bps
	-- 2024-02-02 PD https://dashfinancial.atlassian.net/browse/DS-7922 removed clearing fields
	-- 2024-10-16 PD https://dashfinancial.atlassian.net/browse/DS-9019 removed myltiplying for net_fees_rebates_mils,
	-- 2024-10-28 PD https://dashfinancial.atlassian.net/browse/DS-9019 removed for spread_saving_mils, total_costs_mils
	-- 2025-09-10 PD https://dashfinancial.atlassian.net/browse/DS-10431 added in_group_by 14
	-- 2025-11-11 PD https://dashfinancial.atlassian.net/browse/DS-10657 added symbol and date_id to in_group_by 14
	return query
	select
		in_group_by as gb,
		case in_group_by
			when 1 then 'all'::text
			when 2 then o.side::text
		  	when 3 then o.scale_market_cap_id::text
			when 4 then o.sector::text
			when 5 then o.adv_pct::text
			when 6 then o.algorithm::text
			when 7 then o.date_id::text
			when 8 then (o.date_id / 100)::text
			when 9 then (o.algorithm || ' | ' || o.symbol)::text
			when 10 then (o.algorithm || ' | ' || coalesce(o.aggression_level, null, 'Default'))::text
			when 11 then o.symbol::text
			when 12 then o.account_name::text
			when 13 then o.client_id::text
			when 14 then client_order_id || ' | ' || o.algorithm::text || ' | ' || o.symbol::text || ' | ' || o.date_id::text
			else 'all'
		end as grouped_by,
--		in_group_by as t1,
		count(o.order_id) order_count,
		sum(o.parent_order_qty) as shares_ordered,
		avg(o.parent_order_qty) as avg_shares_per_order,
--		--executions
		sum(o.trades_count) child_executions,
		sum(o.parent_exec_qty) as shares_executed,
		round(sum(o.principal_amount),15) principal_amount,
		sum(o.parent_exec_qty) / nullif(max(o.total_parent_exec_qty), 0)::float total_shares_executed_pct,
		avg(o.avg_exec_qty) avg_exec_qty,
--		--participation
		avg(o.parent_exec_qty / nullif(o.volume_over_life,  0))::float as total_volume_participation_pct,
		avg(o.parent_exec_qty / nullif(o.eligible_volume_over_life, 0))::float as marketable_volume_participation_pct,
		sum(o.dark_shares_executed) / nullif(sum(o.parent_exec_qty), 0)::float as dark_volume_participation_pct, --???????

		--performance _bps
		(10000 * sum(o.side_multiplier * (o.prev_close_px * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.prev_close_px * o.parent_exec_qty), 0))::float						as prev_close_px_bps,
		(10000 * sum(o.side_multiplier * (o.open_px * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.open_px * o.parent_exec_qty), 0))::float									as open_px_bps,
		(10000 * sum(o.side_multiplier * (o.order_arrival_price * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.order_arrival_price * o.parent_exec_qty), 0))::float			as arrival_px_px_bps,
		(10000 * sum(o.side_multiplier * (o.eligible_pwp_5pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.eligible_pwp_5pc * o.parent_exec_qty), 0))::float				as eligible_pwp_5pc_bps,
		(10000 * sum(o.side_multiplier * (o.eligible_pwp_10pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.eligible_pwp_10pc * o.parent_exec_qty), 0))::float				as eligible_pwp_10pc_bps,
		(10000 * sum(o.side_multiplier * (o.eligible_pwp_15pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.eligible_pwp_15pc * o.parent_exec_qty), 0))::float				as eligible_pwp_15pc_bps,
		(10000 * sum(o.side_multiplier * (o.eligible_pwp_20pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.eligible_pwp_20pc * o.parent_exec_qty), 0))::float				as eligible_pwp_20pc_bps,
		(10000 * sum(o.side_multiplier * (o.twap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.twap_over_life * o.parent_exec_qty), 0))::float					as twap_over_life_bps,
		(10000 * sum(o.side_multiplier * (o.eligible_twap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.eligible_twap_over_life * o.parent_exec_qty), 0))::float 	as eligible_twap_over_life_bps,
		(10000 * sum(o.side_multiplier * (o.vwap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.vwap_over_life * o.parent_exec_qty), 0))::float					as vwap_over_life_bps,
		(10000 * sum(o.side_multiplier * (o.eligible_vwap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.eligible_vwap_over_life * o.parent_exec_qty), 0))::float 	as eligible_vwap_over_life_bps,
		(10000 * sum(o.side_multiplier * (o.order_end_price * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.order_end_price * o.parent_exec_qty), 0))::float					as last_px_bps,
		(10000 * sum(o.side_multiplier * (o.close_px * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) / nullif(sum(o.close_px * o.parent_exec_qty), 0))::float								as close_px_bps,

		--performance _value
		round(sum(o.side_multiplier * (o.prev_close_px * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)),15) 			as prev_close_px_value,
		round(sum(o.side_multiplier * (o.open_px * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)),15) 				as open_px_value,
		sum(o.side_multiplier * (o.order_arrival_price * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 		as arrival_px_px_value,
		sum(o.side_multiplier * (o.eligible_pwp_5pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 			as eligible_pwp_5pc_value,
		sum(o.side_multiplier * (o.eligible_pwp_10pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 		as eligible_pwp_10pc_value,
		sum(o.side_multiplier * (o.eligible_pwp_15pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 		as eligible_pwp_15pc_value,
		sum(o.side_multiplier * (o.eligible_pwp_20pc * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 		as eligible_pwp_20pc_value,
		sum(o.side_multiplier * (o.twap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 			as twap_over_life_value,
		sum(o.side_multiplier * (o.eligible_twap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 	as eligible_twap_over_life_value,
		sum(o.side_multiplier * (o.vwap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 			as vwap_over_life_value,
		sum(o.side_multiplier * (o.eligible_vwap_over_life * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 	as eligible_vwap_over_life_value,
		sum(o.side_multiplier * (o.order_end_price * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 			as last_px_value,
		sum(o.side_multiplier * (o.close_px * o.parent_exec_qty - o.parent_avg_price * o.parent_exec_qty)) 					as close_px_value,

		--spread
		round(sum(o.avg_bid_ask_spread_5d_bps * o.principal_amount) / nullif(sum(o.principal_amount), 0),15)						as spread_5d_bps,
		10000 * sum(o.principal_amount * o.routing_time_spread / nullif(o.routing_time_mid_price, 0)) / nullif(sum(o.principal_amount), 0) 	as observed_spread,
		sum(o.efq_dollars) / nullif(sum(o.observed_spread_value), 0)													as efq,
		sum(o.spread_saving) 																							as spread_saving,
		10000 * sum(o.spread_saving) / nullif(sum(o.principal_amount), 0)												as spread_saving_bps,
		sum(o.spread_saving) / nullif(sum(o.parent_exec_qty), 0)												as spread_saving_mils,

		--limit price
		sum(case when o.parent_limit_price is not null then 1 else 0 end) / count(*)::float 																								as orders_with_limit_pct,
		sum(case when o.parent_limit_price is not null and o.parent_is_marketable = 'N' then 1 else 0 end) / count(*)::float 																as orders_with_limit_not_marketable_pct,
		round(sum(case when o.side = '1' then o.buy_limit_vs_ask_bps * o.parent_order_qty else 0 end) / nullif(sum(case when o.side = '1' then o.parent_order_qty else 0 end), 0), 15) 	    as buy_limit_vs_ask_bps,
		round(sum(case when o.side <> '1' then o.sell_limit_vs_bid_bps * o.parent_order_qty else 0 end) / nullif(sum(case when o.side <> '1' then o.parent_order_qty else 0 end), 0),15) 	as sell_limit_vs_bid_bps,

		-- costs
		sum(o.net_fees_rebates_amount) / nullif(sum(o.last_qty), 0)					as net_fees_rebates_mils,
		sum(o.commission_amount) / nullif(sum(o.last_qty), 0) 						as commission_mils,
		(coalesce(sum(o.net_fees_rebates_amount), 0) +
				coalesce(sum(o.commission_amount), 0)) / nullif(sum(o.last_qty), 0)			as total_costs_mils,

		-- costs amounts
		sum(o.net_fees_rebates_amount)														as net_fees_rebates_amount,
		sum(o.commission_amount)							 								as commission_amount,
		coalesce(sum(o.net_fees_rebates_amount), 0) +
		coalesce(sum(o.commission_amount), 0)											 	as total_costs_amount

	from trash.pre_fetch_equity_tca o
	group by grouped_by;
end
$function$
;


-- DROP FUNCTION trash.report_equity_tca_venue(int4);

CREATE OR REPLACE FUNCTION trash.report_equity_tca_venue(in_group_by integer DEFAULT 1)
 RETURNS TABLE(gb integer, grouped_by text, n_orders bigint, n_shares_orders bigint, avg_order_size numeric, n_executions bigint, n_shares_executions bigint, avg_execution_size numeric, perc_total_shares_executed numeric, executed_shares_to_ordered numeric, midpont_stability numeric, saved_from_far_side_of_spread numeric, perc_eq numeric, net_fees_rebates_mils numeric, clearing_mils numeric, commission_mils numeric, total_costs_mils numeric, net_fees_rebates_amount numeric, clearing_amount numeric, commission_amount numeric, total_costs_amount numeric)
 LANGUAGE plpgsql
AS $function$
begin
	-- O. Sydor 2021-04-27
	-- https://dashfinancial.atlassian.net/browse/DS-3381
	-- SY 20210928: Several nillif have been added to avoid divisor equal to 0
	-- PD 20241016: https://dashfinancial.atlassian.net/browse/DS-9019 removed multiplying by 1000 for net_fees_rebates_mils and commission_mils
	-- PD 20241028: https://dashfinancial.atlassian.net/browse/DS-9019 removed multiplying by 1000 for total_costs_mils and clearing_mils
    return query
    select
            in_group_by 																										as gb,
            case in_group_by
                when 1 then smt.exchange_name::text -- Venue
                when 2 then smt.venue_type::text -- VenueType
                when 3 then smt.order_type::text -- OrderType
                when 4 then (smt.order_type || ' | ' || smt.exchange_name)::text -- OrderVenue
                else 'all'
            end as grouped_by,
        sum(case when rn = 1 then 1 else 0 end) 																				as n_orders,
        sum(case when rn = 1 then day_order_qty else 0 end) 																	as n_shares_orders,
        round(sum(case when rn = 1 then day_order_qty else 0 end) / nullif(sum(case when rn = 1 then 1 else 0 end), 0.00), 0) 	as avg_order_size,
    count(last_qty) 																											as n_executions,
    sum(last_qty) 																												as n_shares_executions,
    sum(last_qty) / nullif(count(last_qty), 0.00) 																				as avg_execution_size,
    sum(last_qty) * 1.00 / nullif(sum(sum(last_qty)) over () ,0)																			as perc_total_shares_executed,
    sum(last_qty) * 1.00 / nullif(sum(case when rn = 1 then day_order_qty else 0 end),0) 													as executed_shares_to_ordered,
    avg(smt.midpont_stability) 																									as midpont_stability,
    sum(dollars_saved_from_far) 																								as saved_from_far_side_of_spread,
    sum(side_multiplier * efq_dollars) / nullif(sum(observed_spread_value) ,0)															as perc_eq,
		-- costs
	sum(smt.net_fees_rebates_amount) / nullif(sum(smt.last_qty), 0)														as net_fees_rebates_mils,
	sum(smt.clearing_amount) / nullif(count(smt.last_qty), 0)															as clearing_mils,
	sum(smt.commission_amount) / nullif(sum(smt.last_qty), 0) 															as commission_mils,
	(coalesce(sum(smt.net_fees_rebates_amount), 0) +
			coalesce(sum(smt.clearing_amount), 0) +
			coalesce(sum(smt.commission_amount), 0)) / nullif(sum(smt.last_qty), 0)												as total_costs_mils	,
		-- costs amounts
	sum(smt.net_fees_rebates_amount)																							as net_fees_rebates_amount,
	sum(smt.clearing_amount)																									as clearing_amount,
	sum(smt.commission_amount)								 																	as commission_amount,
	coalesce(sum(smt.net_fees_rebates_amount), 0) +
	coalesce(sum(smt.clearing_amount), 0) +
	coalesce(sum(smt.commission_amount), 0)													 									as total_costs_amount

    from trash.pre_fetch_equity_tca_venue smt
    group by grouped_by;
end;
$function$
;



-- DROP FUNCTION dash_reporting.report_equity_tca_quick_gen(int4, int4);

CREATE OR REPLACE FUNCTION trash.report_equity_tca_quick_gen(in_date_begin integer, in_date_end integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
    l_date_id_begin int4 := coalesce(in_date_begin, to_char(date_trunc('quarter', current_date - interval '3 month'),
                                                            'YYYYMMDD')::int4);
    l_date_id_end   int4 := coalesce(in_date_end,
                                     to_char((date_trunc('quarter', current_date) - interval '1 day'), 'YYYYMMD')::int4);
    l_step_id       int4;
    l_load_id       int4;
    l_row_cnt       int4;
    ret_row_cnt     int4 := 0;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'report_equity_tca_quick generation STARTED ====', 0, 'O')
    into l_step_id;

--     perform dash360.report_equity_tca_init_v2(l_date_id_begin, l_date_id_end);
--    perform trash.report_equity_tca_init_v2_temp(l_date_id_begin, l_date_id_end, in_sub_strategy=>'{0,13,15,1,2,4,5,99,83,84,12}');
    --     row_cnt = (select count(*) from pre_fetch_equity_tca);
--     raise notice 'pre_fetch - % rows', row_cnt;

    delete
    from dash_reporting.eq_tca_quick
    where date_id_report_begin = l_date_id_begin
      and date_id_report_end = l_date_id_end;

    delete
    from dash_reporting.eq_tca_venue_quick
    where date_id_report_begin = l_date_id_begin
      and date_id_report_end = l_date_id_end;

    for each_group in 1..13
        loop
            insert into dash_reporting.eq_tca_quick(group_name, grouped_by, order_count, shares_ordered,
                                                    avg_shares_per_order, child_executions, shares_executed,
                                                    principal_amount, total_shares_executed_pct, avg_exec_qty,
                                                    total_volume_participation_pct, marketable_volume_participation_pct,
                                                    dark_volume_participation_pct, prev_close_px_bps, open_px_bps,
                                                    arrival_px_px_bps, eligible_pwp_5pc_bps, eligible_pwp_10pc_bps,
                                                    eligible_pwp_15pc_bps, eligible_pwp_20pc_bps, twap_over_life_bps,
                                                    eligible_twap_over_life_bps, vwap_over_life_bps,
                                                    eligible_vwap_over_life_bps, last_px_bps, close_px_bps,
                                                    prev_close_px_value, open_px_value, arrival_px_px_value,
                                                    eligible_pwp_5pc_value, eligible_pwp_10pc_value,
                                                    eligible_pwp_15pc_value, eligible_pwp_20pc_value,
                                                    twap_over_life_value, eligible_twap_over_life_value,
                                                    vwap_over_life_value, eligible_vwap_over_life_value, last_px_value,
                                                    close_px_value, spread_5d_bps, observed_spread, efq, spread_saving,
                                                    spread_saving_bps, spread_saving_mils, orders_with_limit_pct,
                                                    orders_with_limit_not_marketable_pct, buy_limit_vs_ask_bps,
                                                    sell_limit_vs_bid_bps, net_fees_rebates_mils,
                                                    commission_mils, total_costs_mils, net_fees_rebates_amount,
                                                    commission_amount, total_costs_amount,
                                                    date_id_report_begin, date_id_report_end, group_by)
            select group_name,
                   grouped_by,
                   order_count,
                   shares_ordered,
                   avg_shares_per_order,
                   child_executions,
                   shares_executed,
                   principal_amount,
                   total_shares_executed_pct,
                   avg_exec_qty,
                   total_volume_participation_pct,
                   marketable_volume_participation_pct,
                   dark_volume_participation_pct,
                   prev_close_px_bps,
                   open_px_bps,
                   arrival_px_px_bps,
                   eligible_pwp_5pc_bps,
                   eligible_pwp_10pc_bps,
                   eligible_pwp_15pc_bps,
                   eligible_pwp_20pc_bps,
                   twap_over_life_bps,
                   eligible_twap_over_life_bps,
                   vwap_over_life_bps,
                   eligible_vwap_over_life_bps,
                   last_px_bps,
                   close_px_bps,
                   prev_close_px_value,
                   open_px_value,
                   arrival_px_px_value,
                   eligible_pwp_5pc_value,
                   eligible_pwp_10pc_value,
                   eligible_pwp_15pc_value,
                   eligible_pwp_20pc_value,
                   twap_over_life_value,
                   eligible_twap_over_life_value,
                   vwap_over_life_value,
                   eligible_vwap_over_life_value,
                   last_px_value,
                   close_px_value,
                   spread_5d_bps,
                   observed_spread,
                   efq,
                   spread_saving,
                   spread_saving_bps,
                   spread_saving_mils,
                   orders_with_limit_pct,
                   orders_with_limit_not_marketable_pct,
                   buy_limit_vs_ask_bps,
                   sell_limit_vs_bid_bps,
                   net_fees_rebates_mils,
                   commission_mils,
                   total_costs_mils,
                   net_fees_rebates_amount,
                   commission_amount,
                   total_costs_amount,
                   l_date_id_begin,
                   l_date_id_end,
                   each_group
            from trash.report_equity_tca_v2(each_group);
            get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'report_equity_tca_quick generated ' || each_group::text, 0, 'O')
    into l_step_id;

            ret_row_cnt := ret_row_cnt + l_row_cnt;

        end loop;

    for each_group in 1..4
        loop
            insert into dash_reporting.eq_tca_venue_quick(gb, grouped_by, n_orders, n_shares_orders, avg_order_size,
            											  n_executions, n_shares_executions, avg_execution_size,
            											  perc_total_shares_executed, executed_shares_to_ordered,
            											  midpont_stability, saved_from_far_side_of_spread, perc_eq,
            											  net_fees_rebates_mils, clearing_mils, commission_mils,
            											  total_costs_mils, net_fees_rebates_amount, clearing_amount,
            											  commission_amount, total_costs_amount, date_id_report_begin,
            											  date_id_report_end, each_group)
            select gb,
            	   grouped_by,
            	   n_orders,
            	   n_shares_orders,
            	   avg_order_size,
            	   n_executions,
            	   n_shares_executions,
            	   avg_execution_size,
            	   perc_total_shares_executed,
            	   executed_shares_to_ordered,
            	   midpont_stability,
            	   saved_from_far_side_of_spread,
            	   perc_eq,
            	   net_fees_rebates_mils,
            	   clearing_mils,
            	   commission_mils,
            	   total_costs_mils,
            	   net_fees_rebates_amount,
            	   clearing_amount,
            	   commission_amount,
            	   total_costs_amount,
                   l_date_id_begin,
                   l_date_id_end,
                   each_group
            from trash.report_equity_tca_venue(each_group);
    select public.load_log(l_load_id, l_step_id, 'report_equity_tca_quick generated ' || each_group::text, 0, 'O')
    into l_step_id;

        end loop;




    select public.load_log(l_load_id, l_step_id,
                           'report_equity_tca_quick for date ' || l_date_id_begin::text || ' - ' ||
                           l_date_id_end::text || ' FINISHED ====', ret_row_cnt, 'I')
    into l_step_id;

exception
    when others then
        raise notice 'error: %', sqlerrm;
end;
$function$
;
select * from trash.report_equity_tca_quick_gen(20260101, 20260331)

select *
-- delete
from dash_reporting.eq_tca_quick
where date_id_report_begin = 20260101
and date_id_report_end = 20260331;

select *
-- delete
from dash_reporting.eq_tca_venue_quick
where date_id_report_begin = 20260101
and date_id_report_end = 20260331

