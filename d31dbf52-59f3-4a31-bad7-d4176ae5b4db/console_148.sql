insert into trash.pre_pre_fetch_equity_tca (order_id, client_order_id, date_id, multileg_reporting_type,
                                            instrument_type_id,
                                            trading_firm_unq_id, trading_firm_name, account_id, account_name, client_id,
                                            instrument_id, symbol, parent_routed_time, order_end_time,
                                            order_cancel_time,
                                            side, buy_or_sell, side_multiplier, parent_order_qty, parent_exec_qty,
                                            total_parent_exec_qty, parent_avg_price, principal_amount,
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
       yc.total_parent_exec_qty,
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
                              and da.date_id between 20250701 and 20250930
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
         join LATERAL (select *
                       from dwh.client_order co
                       where co.order_id = yc.order_id
                         and co.create_date_id = yc.date_id
                         and co.create_date_id between 20250701 and 20250930
                       limit 100500) co on true
         left join lateral (select fix_message
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = co.fix_message_id
                              and fmj.date_id = co.create_date_id
                              and fmj.date_id between 20250701 and 20250930
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
                  and ftr.date_id between 20250701 and 20250930
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
    where date_id between 20250701 and 20250930
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
                   on (ftr.street_order_id = yc.order_id and ftr.date_id between 20250701 and 20250930)
         left join dwh.d_exchange e on (e.exchange_id = yc.exchange_id and e.is_active)
         left join staging.real_exchange re on re.exchange_id = e.real_exchange_id and e.is_active
         left join eq_tca.order_type_mapping ot on ot.order_type_unq_id = yc.order_type_mapping_id
         join dwh.d_account a on a.account_id = yc.account_id
         left join eq_tca.eq_rev_ft rev on (rev.trade_record_id = ftr.trade_record_id and
                                            num_nulls(p0ms_bid, p0ms_ask, p10ms_bid, p10ms_ask) = 0 and
                                            rev.date_id between 20250701 and 20250930)
         left join dwh.d_target_strategy dts on dts.target_strategy_id = yc.sub_strategy_id
         join trash.tmp_fyc par on par.order_id = yc.parent_order_id
where yc.status_date_id between 20250701 and 20250930
  and yc.instrument_type_id = 'E'
  and yc.multileg_reporting_type = '1'
  and yc.exchange_id is not null;


select * from trash.pre_fetch_equity_tca_venue


create function trash.dash360_report_trades_v4(in_date_id int4)
    returns table
            (
                tradingfirm            varchar,
                account                varchar,
                street_cl_ord_id       varchar,
                cl_ord_id              varchar,
                "date"                 text,
                "time"                 text,
                sec_type               text,
                ex_dest                varchar,
                sub_strategy           varchar,
                fee_sensitivity        int2,
                status                 varchar,
                side                   text,
                o_c                    text,
                symbol                 varchar,
                last_qty               int4,
                last_px                numeric,
                leaves_qty             int4,
                last_mkt               varchar,
                exchange_name          varchar,
                mic_code               varchar,
                bid_qty                text,
                bid_px                 text,
                ask_px                 text,
                ask_qty                int4,
                exec_bid_qty           int4,
                exec_bid_px            text,
                exec_ask_px            text,
                exec_ask_qty           int4,
                liquidity_ind          varchar,
                liq_ind_description    varchar,
                cust_firm              varchar,
                exec_broker            varchar,
                cmta                   varchar,
                client_id              varchar,
                expiration             text,
                root_symbol            varchar,
                dash_exec_id           int8,
                exch_exec_id           varchar,
                secondary_exch_exec_id varchar,
                is_mleg                text,
                is_cross               bpchar,
                sending_firm           varchar,
                principal_amount       numeric,
                maker_taker_fee        numeric,
                maker_taker_fee_unit   text,
                transaction_fee        text,
                trade_processing_fee   text,
                royalty_fee            text,
                option_regulatory_fee  text,
                occ_fee                text,
                sec_fee                text,
                commission             numeric,
                execution_cost         numeric,
                execution_cost_unit    text
            )
    language plpgsql
as
$$
declare

begin
    return query
        select "Trading Firm"           as tradingfirm,
               "Account"                as account,
               "Street Cl Ord ID"       as street_cl_ord_id,
               "Cl Ord ID"              as cl_ord_id,
               "Date"                   as date,
               "Time"                   as time,
               "Sec Type"               as sec_type,
               "Ex Dest"                as ex_dest,
               "Sub Strategy"           as sub_strategy,
               "Fee Sensitivity"        as fee_sensitivity,
               "Status"                 as status,
               "Side"                   as side,
               "O/C"                    as o_c,
               "Symbol"                 as symbol,
               "Last Qty"               as last_qty,
               "Last Px"                as last_px,
               "Leaves Qty"             as leaves_qty,
               "Last Mkt"               as last_mkt,
               "Exchange Name"          as exchange_name,
               "MIC Code"               as mic_code,
               "Bid Qty"                as bid_qty,
               "Bid Px"                 as bid_px,
               "Ask Px"                 as ask_px,
               "Ask Qty"                as ask_qty,
               "Exec Bid Qty"           as exec_bid_qty,
               "Exec Bid Px"            as exec_bid_px,
               "Exec Ask Px"            as exec_ask_px,
               "Exec Ask Qty"           as exec_ask_qty,
               "Liquidity Ind"          as liquidity_ind,
               "Liq Ind Description"    as liq_ind_description,
               "Cust/Firm"              as cust_firm,
               "Exec Broker"            as exec_broker,
               "CMTA"                   as cmta,
               "Client ID"              as client_id,
               "Expiration"             as expiration,
               "Root Symbol"            as root_symbol,
               "Dash Exec ID"           as dash_exec_id,
               "Exch Exec ID"           as exch_exec_id,
               "Secondary Exch Exec ID" as secondary_exch_exec_id,
               "Is Mleg"                as is_mleg,
               "Is Cross"               as is_cross,
               "Sending Firm"           as sending_firm,
               "Principal Amount"       as principal_amount,
               "Maker/Taker Fee"        as maker_taker_fee,
               "Maker/Taker Fee/Unit"   as maker_taker_fee_unit,
               "Transaction Fee"        as transaction_fee,
               "Trade Processing Fee"   as trade_processing_fee,
               "Royalty Fee"            as royalty_fee,
               "Option Regulatory Fee"  as option_regulatory_fee,
               "OCC Fee"                as occ_fee,
               "SEC Fee"                as sec_fee,
               "Commission"             as commission,
               "Execution Cost"         as execution_cost,
               "Execution Cost/Unit"    as execution_cost_unit
        from trash.dash360_report_trades_v3(
                in_start_date_id := in_date_id, in_end_date_id := in_date_id,
                in_trading_firm_ids := '{LPTF355,xfaamex,xfachi,xfachi440,xfasf}'
             );
end;
$$;


