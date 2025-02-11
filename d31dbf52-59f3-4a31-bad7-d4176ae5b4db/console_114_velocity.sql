select di.* from dwh.flat_trade_record ftr
         join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
    where true
        and ftr.date_id = 20220208
and display_instrument_id = 'TTCF 210917P00020000'


select * from dwh.d_option_contract
where opra_symbol = 'TTCF 210917P00020000'

select * from dwh.d_option_series
where root_symbol = 'TTCF 210917P00020000'



        select tr.trade_record_id::bigint,
               tr.orig_trade_record_id::bigint,
               tr.trade_record_time,
               tr.exec_id::bigint,
               tr.order_id::bigint,
               tr.street_order_id::bigint,
               tr.client_order_id,
               tr.street_client_order_id,
               tf.trading_firm_name,
               acc.account_name,
               tr.side,
               tr.open_close,
               tr.last_qty,
               tr.last_px,
               lm.last_mkt_name                            as last_mkt,
               tr.trade_liquidity_indicator,
               li.description                              as trade_liquidity_indicator_text,
               tr.ex_destination,
               tr.sub_strategy,
               cf.customer_or_firm_name,
               tr.exec_broker,
               tr.cmta,
               tr.client_id,
               tr.multileg_reporting_type,
               tr.is_cross_order,
               tr.exch_exec_id,
               tr.secondary_exch_exec_id,
               tr.fix_comp_id,
               tr.tcce_account_dash_commission_amount,
               tr.tcce_account_execution_cost,
               tr.tcce_firm_dash_commission_amount,
               tr.tcce_firm_execution_cost,
               tr.tcce_mss_fee_amount,
               tr.tcce_maker_taker_fee_amount,
               tr.tcce_occ_fee_amount,
               tr.tcce_option_regulatory_fee_amount,
               tr.tcce_royalty_fee_amount,
               tr.tcce_sec_fee_amount,
               tr.tcce_transaction_fee_amount,
               tr.tcce_trade_Processing_Fee_Amount,
               i.instrument_type_id                        as sec_type,
               i.symbol,
               i.display_instrument_id,
               i.last_trade_date,
               coalesce(e.real_exchange_id, e.exchange_id) as real_exchange_id,
               e.exchange_name,
               real_exch.exchange_name                     as real_exchange_name,
               tr.principal_amount,
               tr.ask_price                                as execution_time_ask_price,
               tr.bid_price                                as execution_time_bid_price,
               tr.ask_qty                                  as execution_time_ask_qty,
               tr.bid_qty                                  as execution_time_bid_qty,
               tr.routing_time_ask_price,
               tr.routing_time_bid_price,
               tr.routing_time_ask_qty,
               tr.routing_time_bid_qty,
               tr.trade_record_reason,
               tr.fee_sensitivity,
               tr.optional_data,
               oc.opra_symbol,
               tr.compliance_id,
               oc.put_call                                 as put_call,
               oc.strike_price                             as strike_px
        from dwh.flat_trade_record tr
                 inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
                 inner join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)
                 left join dwh.d_exchange e on (tr.exchange_id = e.exchange_id and e.is_active = true)
                 left join dwh.d_exchange real_exch
                           on (real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and
                               real_exch.is_active = true)
                 inner join dwh.d_trading_firm tf on (acc.trading_firm_id = tf.trading_firm_id and tf.is_active)
                 left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 left join dwh.d_liquidity_indicator li
                           on (tr.trade_liquidity_indicator = li.trade_liquidity_indicator and
                               real_exch.exchange_id = li.exchange_id and li.is_active)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = opt_customer_firm and cf.is_active)
                 left join dwh.d_last_market lm on (lm.last_mkt = tr.last_mkt and lm.is_active)
        where tr.date_id between :in_start_date_id and :in_end_date_id -- in_start_date_id, in_end_date_i
          and i.symbol not in
              ('ZVZZT', 'ZWZZT', 'CBO', 'CBX', 'IBO', 'IGZ', 'ZBZX', 'ZTEST', 'ZTST', 'ZZZ', 'ZZK', 'ZVV')
          and tr.is_busted = 'N'
          and acc.account_id = any ('{54657,63783,64663,64880,64881,64983,64984,65121,65122,67947,68347,68349,68388,68475,68476,68578,68579,68848,70037,70262,70268,71372,73518,73527,70036,72054,63782,64662,64980,64981,68348,68350,70749}')


select array_agg(d_account.account_id) from dwh.d_account
    where d_account.trading_firm_id in ('OFP0045', 'OFP0054', 'velcap01', 'velocltam', 'veloclear')
and is_active