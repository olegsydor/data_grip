/*select trading_firm_name,
       account_name,
       client_id_text,
       to_char(create_time, 'YYYY-MM-DD HH:MI:SS.MS'),
       client_order_id,
       instrument_name,
       exp_date,
       side,
       order_qty,
       price,
       is_mleg,
       target_strategy_name,
       exec_id::text,
       last_qty,
       last_px,
       ratio_qty,
       delta,
       trade_exchange_id,
       to_char(exec_time, 'YYYY-MM-DD HH:MI:SS.MS'),
       trade_liquidity_indicator,
       street_client_order_id,
       street_exec_id::text,
       qcc_delta,
       calc_delta,
       delta_diff,
       stock_qty_crossed,
       expected_stock_qty,
       stock_qty_diff,
       stock_exec_time::text,
       exec_time_diff::text,
       hedge_status,
       trade_alert_jsonb
from (select trading_firm_name,
             account_name,
             client_id_text,
             create_time,
             client_order_id,
             instrument_name,
             exp_date,
             side,
             order_qty,
             price,
             is_mleg,
             target_strategy_name,
             exec_id,
             last_qty,
             last_px,
             ratio_qty,
             delta,
             trade_exchange_id,
             exec_time,
             trade_liquidity_indicator,
             street_client_order_id,
             street_exec_id,
             qcc_delta,
             calc_delta,
             calc_delta - qcc_delta                                       delta_diff,
             stock_qty_crossed,
             stock_exec_time,
             (stock_exec_time - exec_time)                                exec_time_diff,
             calc_delta * order_qty_with_min_order_id                     expected_stock_qty,
             calc_delta * order_qty_with_min_order_id - stock_qty_crossed stock_qty_diff,
             case
                 when calc_delta * order_qty_with_min_order_id > 0 and stock_qty_crossed > 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed = 0 then 'Exact'
                 when calc_delta * order_qty_with_min_order_id > 0 and stock_qty_crossed > 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed > 0 then 'Under'
                 when calc_delta * order_qty_with_min_order_id > 0 and stock_qty_crossed = 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed > 0 then 'Under'
                 when calc_delta * order_qty_with_min_order_id > 0 and stock_qty_crossed > 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed < 0 then 'Over'
                 when calc_delta * order_qty_with_min_order_id > 0 and stock_qty_crossed < 0 then 'Wrong side'
                 when calc_delta * order_qty_with_min_order_id < 0 and stock_qty_crossed < 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed = 0 then 'Exact'
                 when calc_delta * order_qty_with_min_order_id < 0 and stock_qty_crossed < 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed > 0 then 'Over'
                 when calc_delta * order_qty_with_min_order_id < 0 and stock_qty_crossed < 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed < 0 then 'Under'
                 when calc_delta * order_qty_with_min_order_id < 0 and stock_qty_crossed = 0 and
                      calc_delta * order_qty_with_min_order_id - stock_qty_crossed < 0 then 'Under'
                 when calc_delta * order_qty_with_min_order_id < 0 and stock_qty_crossed > 0 then 'Wrong side'
                 end                                                      hedge_status,
             trade_alert_jsonb
      from (select dtf.trading_firm_name,
                   da.account_name,
                   custco.client_id_text,
                   custco.create_time,
                   custco.client_order_id,
                   di.instrument_name,
                   lpad(oc.maturity_month::text, 2, '0') || '/' ||
                   lpad(oc.maturity_day::text, 2, '0') || '/' ||
                   oc.maturity_year::text                                                                         exp_date,
                   CASE
                       WHEN custco.side = '1' THEN 'BUY'
                       ELSE 'SELL'
                       end                                                                                        side,
                   custco.order_qty,
                   custco.price,
                   CASE
                       WHEN (select count(co3.order_id)
                             from client_order co3
                                      join d_instrument di
                                           on co3.instrument_id = di.instrument_id and di.instrument_type_id = 'O'
                             where co3.is_originator = 'O'
                               and co3.create_date_id = :in_date_id
                               and co3.cross_order_id = custco.cross_order_id) > 1 THEN 'Y'
                       ELSE 'N'
                       end                                                                                        is_mleg,
                   dts.target_strategy_name,
                   ftr.exec_id,
                   ftr.last_qty,
                   ftr.last_px,
                   custco.ratio_qty,
                   tad.delta,
                   ftr.trade_exchange_id,
                   ftr.trade_record_time                                                                          exec_time,
                   ftr.trade_liquidity_indicator,
                   ftr.street_client_order_id,
                   stre.exec_id                                                                                   street_exec_id,
                   CASE
                       WHEN not exists (select last_qty
                                        from (select last_qty,
                                                     ROW_NUMBER() OVER (PARTITION BY e.order_id ORDER BY e.exec_id) AS rn
                                              from execution e
                                                       join client_order co on e.order_id = co.order_id
                                                       join d_instrument di on co.instrument_id = di.instrument_id
                                              where co.is_originator = 'O'
                                                and di.instrument_type_id = 'E'
                                                and e.exec_type = 'F'
                                                and e.exec_date_id = :in_date_id
                                                and co.create_date_id = :in_date_id
                                                and co.cross_order_id = custco.cross_order_id) t
                                        where t.rn = 1) then 0
                       ELSE
                           (select CASE
                                       WHEN co.side = '1' THEN co.ratio_qty
                                       ELSE -co.ratio_qty
                                       END
                            from client_order co
                                     join d_instrument di on co.instrument_id = di.instrument_id
                            where co.is_originator = 'O'
                              and di.instrument_type_id = 'E'
                              and co.cross_order_id = custco.cross_order_id
                              and co.create_date_id = :in_date_id) / (select min(co.ratio_qty)
                                                                      from client_order co
                                                                               join d_instrument di on co.instrument_id = di.instrument_id
                                                                      where co.is_originator = 'O'
                                                                        and di.instrument_type_id = 'O'
                                                                        and co.cross_order_id = custco.cross_order_id
                                                                        and co.create_date_id = :in_date_id
                                                                      group by di.instrument_type_id)
                       END                                                                                        qcc_delta,
                   (select exec_time
                    from (select exec_time,
                                 ROW_NUMBER() OVER (PARTITION BY e.order_id ORDER BY e.exec_id) AS rn
                          from execution e
                                   join client_order co on e.order_id = co.order_id
                                   join d_instrument di on co.instrument_id = di.instrument_id
                          where co.is_originator = 'O'
                            and di.instrument_type_id = 'E'
                            and e.exec_type = 'F'
                            and e.exec_date_id = :in_date_id
                            and co.create_date_id = :in_date_id
                            and co.cross_order_id = custco.cross_order_id))                                       stock_exec_time,
                   (select -1 * sum(
                           (case
                                when custco1.side = '1' then 1
                                else -1
                               end) * custco1.ratio_qty * tad1.delta) * dos1.contract_multiplier
                    from data_marts.f_qcc_trade_alert_details tad1
                             join lateral (select exec_id, stre.exec_date_id, stre.order_id, stre.exch_exec_id
                                           from execution stre
                                           where tad1.exec_id = stre.exec_id
                                             and tad1.date_id = stre.exec_date_id
                                             and not stre.is_parent_level
                                             and stre.exec_date_id = :in_date_id
                                           limit 1 ) stre1 on true
                             join flat_trade_record ftr1 on ftr1.street_order_id = stre1.order_id and
                                                            stre1.exch_exec_id = ftr1.secondary_exch_exec_id and
                                                            ftr1.orig_trade_record_id is null and
                                                            ftr1.date_id = :in_date_id
                             join client_order custco1
                                  on custco1.order_id = ftr1.order_id and custco1.create_date_id = ftr1.date_id
                             join d_option_contract doc1 on custco1.instrument_id = doc1.instrument_id
                             join d_option_series dos1 on dos1.option_series_id = doc1.option_series_id
                    where tad1.date_id = :in_date_id --and tad1.batch_id = l_batch_id
                      and custco1.cross_order_id = custco.cross_order_id
                    group by custco1.cross_order_id, dos1.contract_multiplier) / (select min(co.ratio_qty)
                                                                                  from client_order co
                                                                                           join d_instrument di on co.instrument_id = di.instrument_id
                                                                                  where co.is_originator = 'O'
                                                                                    and di.instrument_type_id = 'O'
                                                                                    and co.cross_order_id = custco.cross_order_id
                                                                                    and co.create_date_id = :in_date_id
                                                                                  group by di.instrument_type_id) calc_delta, -- Calculated Delta
                   CASE
                       WHEN not exists (select last_qty
                                        from (select last_qty,
                                                     ROW_NUMBER() OVER (PARTITION BY e.order_id ORDER BY e.exec_id) AS rn
                                              from execution e
                                                       join client_order co on e.order_id = co.order_id
                                                       join d_instrument di on co.instrument_id = di.instrument_id
                                              where co.is_originator = 'O'
                                                and di.instrument_type_id = 'E'
                                                and e.exec_type = 'F'
                                                and e.exec_date_id = :in_date_id
                                                and co.create_date_id = :in_date_id
                                                and co.cross_order_id = custco.cross_order_id) t
                                        where t.rn = 1) then 0
                       ELSE
                           (select last_qty
                            from (select (case
                                              when co.side = '1' then 1
                                              else -1
                                end) * last_qty                                                            last_qty,
                                         ROW_NUMBER() OVER (PARTITION BY e.order_id ORDER BY e.exec_id) AS rn
                                  from execution e
                                           join client_order co on e.order_id = co.order_id
                                           join d_instrument di on co.instrument_id = di.instrument_id
                                  where co.is_originator = 'O'
                                    and di.instrument_type_id = 'E'
                                    and e.exec_type = 'F'
                                    and e.exec_date_id = :in_date_id
                                    and co.create_date_id = :in_date_id
                                    and co.cross_order_id = custco.cross_order_id) t
                            where t.rn = 1) END                                                                   stock_qty_crossed,
                   (SELECT DISTINCT ON (co4.cross_order_id) co4.order_qty
                    FROM client_order co4
                             join d_instrument di4 on co4.instrument_id = di4.instrument_id
                    where co4.is_originator = 'O'
                      and co4.cross_order_id = custco.cross_order_id
                      and di4.instrument_type_id = 'O'
                      AND co4.create_date_id = :in_date_id
                    ORDER BY co4.cross_order_id, co4.ratio_qty asc)                                               order_qty_with_min_order_id,
                   tad.trade_alert_jsonb
            */
                select *
            from data_marts.f_qcc_trade_alert_details tad
--                      join lateral (select exec_id, stre.exec_date_id, stre.order_id, stre.exch_exec_id
--                                    from execution stre
--                                    where tad.exec_id = stre.exec_id
--                                      and tad.date_id = stre.exec_date_id
--                                      and not stre.is_parent_level
--                                      and stre.exec_date_id = :in_date_id
--                                    limit 1 ) stre on true
--                      join flat_trade_record ftr
--                           on ftr.street_order_id = stre.order_id and stre.exch_exec_id = ftr.secondary_exch_exec_id and
--                              ftr.orig_trade_record_id is null and ftr.date_id = :in_date_id
--                      join client_order custco on custco.order_id = ftr.order_id and custco.create_date_id = ftr.date_id
--                      join d_account da on custco.account_id = da.account_id
--                      join d_trading_firm dtf on ftr.trading_firm_unq_id = dtf.trading_firm_unq_id
--                      join d_instrument di
--                           on ftr.instrument_id = di.instrument_id and ftr.instrument_type_id = di.instrument_type_id
--                      join d_option_contract oc on custco.instrument_id = oc.instrument_id
--                      join d_target_strategy dts on custco.sub_strategy_id = dts.target_strategy_id
            where tad.date_id = :in_date_id --and tad.batch_id = l_batch_id
              and exists (select order_qty
                          from client_order co
                                   join d_instrument di on co.instrument_id = di.instrument_id
                          where co.is_originator = 'O'
                            and di.instrument_type_id = 'E'
                            and co.cross_order_id = custco.cross_order_id
                            and co.create_date_id = :in_date_id)


              and tad.delta is not null)) res
where res.hedge_status = 'Wrong side'
   or (res.hedge_status = 'Over' and abs(delta_diff) > 10)
   or (res.hedge_status = 'Under' and abs(delta_diff) > 5)
   or (exec_time_diff > INTERVAL '60 seconds');