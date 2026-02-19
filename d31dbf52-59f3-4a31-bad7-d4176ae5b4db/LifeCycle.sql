select *
from trash.report_obo_compliance_xls_with_clordid(in_date_begin_id := 20260106, in_date_end_id := 20260106,
                                                  in_include_routes := 'Y', in_include_acks := 'Y',
                                                  in_client_order_ids := '{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}');

drop table if exists t_sdn_tmp_SOR_fix_message_event_20221223_exam_parent_ord;
create temp table t_sdn_tmp_SOR_fix_message_event_20221223_exam_parent_ord as
select di.symbol, di.symbol_suffix, di.instrument_type_id, oc.opra_symbol, os.root_symbol, ui.symbol as underlying_symbol
  , di.last_trade_date , oc.put_call, oc.strike_price
  , fc.fix_comp_id, fc.is_high_frequency_trader
  , ac.trading_firm_id, ac.cat_suppress as ac_cat_suppress, ac.account_name, ac.account_holder_type, tf.cat_imid , tf.cat_suppress as tf_cat_suppress
  , so.cpar_cnt, so.cross_cnt, ml.no_legs as ml_no_legs
  , tif.tif_short_name
  , cl.*
from dwh.client_order cl
  inner join dwh.d_instrument di on cl.instrument_id = di.instrument_id
  left join dwh.d_option_contract oc on di.instrument_id = oc.instrument_id
  left join d_option_series os on os.option_series_id  = oc.option_series_id
  left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
  inner join d_account ac on ac.account_id = cl.account_id
  inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
  inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
  left join lateral
    ( select str.parent_order_id,
      --count(*) filter (where str.cross_order_id is null) single_cnt,
      count(*) filter (where str.exchange_id = 'C1PAR') cpar_cnt,
      count(*) filter (where str.cross_order_id is not null) cross_cnt
      from client_order str
      where str.trans_type <> 'F'
      and str.parent_order_id is not null
      and str.create_date_id = 20260106 --in_date_id
      and str.parent_order_id = cl.order_id
      group by str.parent_order_id
      limit 1
    ) so on true
  left join lateral
    (
      select ml.order_id , ml.client_order_id , ml.fix_message_id
        , ml.no_legs
      from client_order ml
      where cl.multileg_reporting_type = '2'
        and ml.order_id = cl.multileg_order_id
        and ml.multileg_reporting_type = '3'
        and ml.create_date_id = 20260106
      limit 1
    ) ml on true
  left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
where cl.create_date_id = 20260106
--   and di.symbol in ('PRGO','AAPL','GOOG','MSFT','NVDA','SPY','TSLA')
  and cl.trans_type <> 'F'
  and cl.parent_order_id is null
  and cl.multileg_reporting_type in ('1','2')
  and cl.trans_type <> 'F'
and cl.client_order_id = any('{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}');

