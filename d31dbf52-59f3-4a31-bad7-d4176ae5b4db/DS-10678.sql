select symbol, date_id, count(*)
from eq_tca.daily_analytic_v2
group by symbol, date_id
having count(*) > 1;



select * from trash.so_report_equity_tca_init_v2(20251001, 20251231)

CREATE OR REPLACE FUNCTION trash.so_report_equity_tca_init_v2(in_date_begin integer, in_date_end integer,
                                                             in_trading_firm_ids text[] DEFAULT '{}'::text[],
                                                             in_client_ids text[] DEFAULT '{}'::text[],
                                                             in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                             in_sub_strategy character varying[] DEFAULT '{}'::character varying[],
                                                             in_custom_configuration_algo boolean DEFAULT false,
                                                             in_symbols character varying[] DEFAULT '{}'::character varying[])
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
-- SO 20240523  https://dashfinancial.atlassian.net/browse/DEVREQ-4264  add  coalesce  to  account\trading  firm  input  parameters
-- PD 20241031  https://dashfinancial.atlassian.net/browse/DS-8997  added  in_symbol
-- SO 20251104 https://dashfinancial.atlassian.net/browse/DS-10678 performance improvement
declare
    l_step_id               int4;
    l_load_id               int4;
    l_row_cnt               int4;
    l_instrument_id_arr     int[];
    l_total_parent_exec_qty int8;
begin
    --  Created  by  PD  on  2022/05/25  to  test
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'report_equity_tca  STARTED  ====', 0, 'O')
    into l_step_id;

    case
        when cardinality(in_symbols) = 0
            then l_instrument_id_arr := '{}';
        else l_instrument_id_arr := (select array_agg(instrument_id)
                                     from dwh.d_instrument di
                                     where di.symbol = any (in_symbols));
        end case;

    drop table if exists tmp_fyc;
    create temp table if not exists tmp_fyc
       on commit drop
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
           yc.order_qty
    from data_marts.f_yield_capture yc
             join dwh.d_account a on a.account_id = yc.account_id and a.is_active
             left join dwh.d_target_strategy dts on dts.target_strategy_id = yc.sub_strategy_id
    where yc.parent_order_id is null
      and yc.status_date_id between in_date_begin and in_date_end
      and yc.instrument_type_id = 'E'
      and yc.multileg_reporting_type = '1'
      and case when coalesce(in_account_ids, '{}') <> '{}' then yc.account_id = any (in_account_ids) else true end
      and case
              when coalesce(in_trading_firm_ids, '{}') <> '{}' then a.trading_firm_id = any (in_trading_firm_ids)
              else true end
      and case when coalesce(in_client_ids, '{}') <> '{}' then yc.client_id = any (in_client_ids) else true end
      and case when in_sub_strategy <> '{}' then dts.target_strategy_name = any (in_sub_strategy) else true end
      and case when l_instrument_id_arr <> '{}' then yc.instrument_id = any (l_instrument_id_arr) else true end;


    get diagnostics l_row_cnt = row_count;

    analyze tmp_fyc;

    select public.load_log(l_load_id, l_step_id, 'tmp_fyc created', l_row_cnt, 'I')
    into l_step_id;

    drop table if exists pre_pre_fetch_equity_tca;
    create temp table if not exists pre_pre_fetch_equity_tca
    (
        order_id                  int8           null,
        client_order_id           varchar(256)   null,
        date_id                   int4           null,
        multileg_reporting_type   bpchar(1)      null,
        instrument_type_id        bpchar(1)      null,
        trading_firm_unq_id       int4           null,
        trading_firm_name         varchar(60)    null,
        account_id                int8           null,
        account_name              varchar(30)    null,
        client_id                 varchar(255)   null,
        instrument_id             int4           null,
        symbol                    varchar(10)    null,
        parent_routed_time        timestamp      null,
        order_end_time            timestamp      null,
        order_cancel_time         timestamp(3)   null,
        side                      bpchar(1)      null,
        buy_or_sell               bpchar(1)      null,
        side_multiplier           int4           null,
        parent_order_qty          int4           null,
        parent_exec_qty           int4           null,
-- 		total_parent_exec_qty  		int8  null,
        parent_avg_price          numeric        null,
        principal_amount          numeric        null,
        target_strategy_id        int4           null,
        algorithm                 varchar(128)   null,
        parent_nbbo_bid_price     numeric(12, 4) null,
        parent_nbbo_ask_price     numeric(12, 4) null,
        parent_nbbo_bid_qty       int4           null,
        parent_nbbo_ask_qty       int4           null,
        buy_limit_vs_ask_bps      numeric        null,
        sell_limit_vs_bid_bps     numeric        null,
        parent_is_marketable      bpchar(1)      null,
        parent_limit_price        numeric(12, 4) null,
        routing_table_name        varchar(30)    null,
        order_arrival_price       float8         null,
        order_end_price           float8         null,
        vwap_over_life            float8         null,
        eligible_vwap_over_life   float8         null,
        twap_over_life            float8         null,
        eligible_twap_over_life   float8         null,
        volume_over_life          float8         null,
        eligible_volume_over_life float8         null,
        eligible_pwp_5pc          float8         null,
        eligible_pwp_10pc         float8         null,
        eligible_pwp_15pc         float8         null,
        eligible_pwp_20pc         float8         null,
        trade_count               int4           null,
        eligible_trade_count      int4           null,
        block_volume              int4           null,
        eligible_qd_volume        int4           null,
        eligible_ix_volume        int4           null,
        avg_spread_over_life      numeric        null,
        day_high_price            numeric        null,
        day_low_price             numeric        null,
        open_px                   numeric        null,
        close_px                  numeric        null,
        prev_close_px             numeric        null,
        next_close_px             numeric        null,
        routing_time_mid_price    numeric        null,
        routing_time_spread       numeric        null,
        aggression_level          text           null,
        activ_symbol              varchar(30)    null,
        day_order_qty             int4           null,
        order_qty                 int4           null
    );

    insert into pre_pre_fetch_equity_tca (order_id, client_order_id, date_id, multileg_reporting_type,
                                          instrument_type_id, trading_firm_unq_id, trading_firm_name, account_id,
                                          account_name, client_id, instrument_id, symbol, parent_routed_time,
                                          order_end_time, order_cancel_time, side, buy_or_sell, side_multiplier,
                                          parent_order_qty, parent_exec_qty,
--                                           total_parent_exec_qty,
                                          parent_avg_price,
                                          principal_amount, target_strategy_id, algorithm, parent_nbbo_bid_price,
                                          parent_nbbo_ask_price, parent_nbbo_bid_qty, parent_nbbo_ask_qty,
                                          buy_limit_vs_ask_bps, sell_limit_vs_bid_bps, parent_is_marketable,
                                          parent_limit_price, routing_table_name, order_arrival_price, order_end_price,
                                          vwap_over_life, eligible_vwap_over_life, twap_over_life,
                                          eligible_twap_over_life, volume_over_life, eligible_volume_over_life,
                                          eligible_pwp_5pc, eligible_pwp_10pc, eligible_pwp_15pc, eligible_pwp_20pc,
                                          trade_count, eligible_trade_count, block_volume, eligible_qd_volume,
                                          eligible_ix_volume, avg_spread_over_life, day_high_price, day_low_price,
                                          open_px, close_px, prev_close_px, next_close_px, routing_time_mid_price,
                                          routing_time_spread, aggression_level, activ_symbol, day_order_qty, order_qty)
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
--            yc.total_parent_exec_qty,
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
    from tmp_fyc yc
             join dwh.d_trading_firm tf on tf.trading_firm_unq_id = yc.trading_firm_unq_id
             join dwh.d_instrument i on i.instrument_id = yc.instrument_id and i.is_active
             left join dwh.d_target_strategy ts on ts.target_strategy_id = yc.sub_strategy_id and ts.is_active
             left join dwh.d_routing_table rt on rt.routing_table_id = yc.routing_table_id and rt.is_active
             left join eq_tca.algorithmic_order_analytic_v2 tca
                       on tca.order_id = yc.order_id and tca.date_id = yc.date_id
             left join lateral (select *
                                from eq_tca.daily_analytic_v2 da
                                where da.symbol = i.activ_symbol
                                  and da.date_id = yc.date_id
                                  and da.date_id between in_date_begin and in_date_end
                                limit 1) da on true
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
                             and co.create_date_id between in_date_begin and in_date_end
                           limit 1) co on true
             left join lateral (select fix_message
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = co.fix_message_id
                                  and fmj.date_id = co.create_date_id
                                  and fmj.date_id between in_date_begin and in_date_end
                                limit 1) fmj on true;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'pre_pre_table filled  out', l_row_cnt, 'I')
    into l_step_id;


    select sum(parent_exec_qty)
    into l_total_parent_exec_qty
    from tmp_fyc;
        select public.load_log(l_load_id, l_step_id, 'total_parent_exec_qty calculated', l_row_cnt, 'I')
    into l_step_id;

        create temp table if not exists pre_fetch_equity_tca
    (
        order_id                  int8,
        client_order_id           varchar(256),
        date_id                   int4,
        multileg_reporting_type   bpchar(1),
        instrument_type_id        bpchar(1),
        trading_firm_unq_id       int4,
        trading_firm_name         varchar(60),
        account_id                int8,
        account_name              varchar(30),
        client_id                 varchar(255),
        instrument_id             int4,
        symbol                    varchar(10),
        parent_routed_time        timestamp,
        order_end_time            timestamp,
        order_cancel_time         timestamp(3),
        side                      bpchar(1),
        buy_or_sell               bpchar(1),
        side_multiplier           int4,
        parent_order_qty          int4,
        parent_exec_qty           int4,
        total_parent_exec_qty     int8,
        parent_avg_price          numeric,
        principal_amount          numeric,
        target_strategy_id        int4,
        algorithm                 varchar(128),
        parent_nbbo_bid_price     numeric(12, 4),
        parent_nbbo_ask_price     numeric(12, 4),
        parent_nbbo_bid_qty       int4,
        parent_nbbo_ask_qty       int4,
        buy_limit_vs_ask_bps      numeric,
        sell_limit_vs_bid_bps     numeric,
        parent_is_marketable      bpchar(1),
        parent_limit_price        numeric(12, 4),
        routing_table_name        varchar(30),
        order_arrival_price       float8,
        order_end_price           float8,
        vwap_over_life            float8,
        eligible_vwap_over_life   float8,
        twap_over_life            float8,
        eligible_twap_over_life   float8,
        volume_over_life          float8,
        eligible_volume_over_life float8,
        eligible_pwp_5pc          float8,
        eligible_pwp_10pc         float8,
        eligible_pwp_15pc         float8,
        eligible_pwp_20pc         float8,
        trade_count               int4,
        eligible_trade_count      int4,
        block_volume              int4,
        eligible_qd_volume        int4,
        eligible_ix_volume        int4,
        avg_spread_over_life      numeric,
        day_high_price            numeric,
        day_low_price             numeric,
        open_px                   numeric,
        close_px                  numeric,
        prev_close_px             numeric,
        next_close_px             numeric,
        trades_count              int8,
        avg_exec_qty              numeric,
        avg_bid_ask_spread_5d_bps numeric,
        routing_time_mid_price    numeric,
        routing_time_spread       numeric,
        efq_dollars               numeric,
        observed_spread_value     numeric,
        spread_saving             numeric,
        dark_shares_executed      int8,
        scale_market_cap_id       int4,
        adv_pct                   float8,
        sector                    varchar(100),
        aggression_level          text,
        net_fees_rebates_amount   numeric,
        clearing_amount           numeric,
        commission_amount         numeric,
        last_qty                  int4
    );

    truncate table pre_fetch_equity_tca;
    analyze pre_fetch_equity_tca;

    insert into pre_fetch_equity_tca
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
                                      else efq_last_px - f.bid_price end                                           as dollars_saved_from_far,
                     case
                         when f.ask_price - f.bid_price <= 0 then 0
                         else f.last_qty * f.spread * (f.efq_last_px - execution_time_mid_price) /
                              half_spread end                                                                      as efq_dollars,
                     f.tcce_firm_execution_cost,
                     f.tcce_account_execution_cost,
                     f.tcce_maker_taker_fee_amount,
                     f.tcce_transaction_fee_amount,
                     f.tcce_trade_processing_fee_amount,
                     f.tcce_royalty_fee_amount,
                     f.clearing_fee_amout                                                                          as clearing_fee_amout,
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
                                                        else ftr.last_px end) -
                                                   ftr.bid_price end                              as dollars_saved_from_far,
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
                             left join staging.real_exchange real_exch_q
                                       on real_exch_q.exchange_id = real_exch.exchange_id
                    where ftr.is_busted = 'N'
                      and ftr.date_id between in_date_begin and in_date_end
                      and case
                              when coalesce(in_trading_firm_ids, '{}') <> '{}'
                                  then ftr.trading_firm_id = any (in_trading_firm_ids)
                              else true end
                      and case
                              when coalesce(in_client_ids, '{}') <> '{}' then ftr.client_id = any (in_client_ids)
                              else true end
                      and case when in_sub_strategy <> '{}' then ftr.sub_strategy = any (in_sub_strategy) else true end
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
           l_total_parent_exec_qty,
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
    from pre_pre_fetch_equity_tca as tp
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
        ) tr on true
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

    select public.load_log(l_load_id, l_step_id, 'pre_fetch_equity_tca calculated', l_row_cnt, 'I')
    into l_step_id;

    --  VENUE

    create temp table if not exists pre_fetch_equity_tca_venue as
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
                       on (ftr.street_order_id = yc.order_id and ftr.date_id between in_date_begin and in_date_end)
             left join dwh.d_exchange e on (e.exchange_id = yc.exchange_id and e.is_active)
             left join staging.real_exchange re on re.exchange_id = e.real_exchange_id and e.is_active
             left join eq_tca.order_type_mapping ot on ot.order_type_unq_id = yc.order_type_mapping_id
             join dwh.d_account a on a.account_id = yc.account_id
             left join eq_tca.eq_rev_ft rev on (rev.trade_record_id = ftr.trade_record_id and
                                                num_nulls(p0ms_bid, p0ms_ask, p10ms_bid, p10ms_ask) = 0 and
                                                rev.date_id between in_date_begin and in_date_end)
             left join dwh.d_target_strategy dts on dts.target_strategy_id = yc.sub_strategy_id
             join tmp_fyc par on par.order_id = yc.parent_order_id
    where yc.status_date_id between in_date_begin and in_date_end
      and yc.instrument_type_id = 'E'
      and case
              when coalesce(in_trading_firm_ids, '{}') <> '{}' then a.trading_firm_id = any (in_trading_firm_ids)
              else true end
      and case when coalesce(in_account_ids, '{}') <> '{}' then a.account_id = any (in_account_ids) else true end
      and yc.multileg_reporting_type = '1'
      and yc.exchange_id is not null
      and case when in_client_ids <> '{}' then yc.client_id = any (in_client_ids) else true end;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'pre_fetch_equity_tca_venue calculated',
                           l_row_cnt, 'I')
    into l_step_id;

    return 1;

exception
    when others then
        raise notice 'error:  %', sqlerrm;
        return -1;

end;
$function$
;
