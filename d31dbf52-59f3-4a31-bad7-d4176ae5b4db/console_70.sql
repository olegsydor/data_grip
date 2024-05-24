select *
from dash360.report_fintech_adh_execution_xls(in_start_date_id := 20240523, in_end_date_id := 20240523,
                                              in_instrument_type := 'E', in_account_ids := null,--'{8112,9880, 14861}',
                                              in_trading_firm_ids := '{"baml"}');

select *
from
    dash360.report_fintech_adh_order_xls(in_start_date_id := 20240523, in_end_date_id := 20240523,
                                         in_instrument_type := 'E', in_account_ids := '{8112,9880, 14861}',
                                         in_trading_firm_ids := null--'{"baml"}'
    );


    dash360.report_gtc_recon(in_instrument_type_id := 'O', in_account_ids := '{26384,20138,68927}',
                             in_start_date_id := 20240523, in_end_date_id := 20240523,
                             in_trading_firm_ids := null--'{"bnparibas","eroom01","eroom01"}'
    );

select *
from
    dash360.report_obo_compliance_xls(in_date_begin_id := 20240523, in_date_end_id := 20240523,
                                      in_instrument_type := 'E', in_account_ids := '{1183,2927,2928}',
                                      in_trading_firm_ids := '{"mangrove","eroom01","eroom01"}'
                                      );
select *
from
    dash360.report_rps_lpeod_compliance(in_start_date_id := 20240523, in_end_date_id := 20240523,
                                        in_account_ids := '{26384,20138,68927}', in_trading_firm_ids := null);


select *
from
    dash360.report_rps_lpeod_exch_fees(in_start_date_id := 20240523, in_end_date_id := 20240523,
                                       in_account_ids := '{26384,20138,68927}',
                                       in_trading_firm_ids := null--'{"mangrove","eroom01","eroom01"}'
                                        );
select *
from
dash360.report_rps_lpeod_fills(in_start_date_id := 20240523, in_end_date_id := 20240523,
                                       in_account_ids := '{26384,20138,68927}',
                                       in_trading_firm_ids := '{"mangrove","eroom01","eroom01"}'
                                        );

select * from
dash360.report_rps_s3(in_start_date_id := 20240523, in_end_date_id := 20240523,
                                       in_account_ids := '{26384}',
                                       in_trading_firm_ids := null--'{"mangrove","eroom01","eroom01"}'
                                        );

select * from
dash360.report_rps_trade_details(in_start_date_id := 20240523, in_end_date_id := 20240523,
                                       in_account_ids := '{26384}',
                                       in_trading_firm_ids := '{"mangrove","eroom01","eroom01"}'
                                        );

select * from
dash360.report_equity_tca_init_v2(in_date_begin := 20240523, in_date_end := 20240523, in_trading_firm_ids := null, in_account_ids := '{26384}')

select * from pre_fetch_equity_tca_venue
select gos.account_id, count(*)
from dwh.gtc_order_status gos
         join dwh.client_order co on gos.order_id = co.order_id and gos.create_date_id = co.create_date_id
         join dwh.d_instrument i on co.instrument_id = i.instrument_id
where true
  and gos.create_date_id <= :in_start_date_id
  and co.parent_order_id is null
  and gos.close_date_id is null
  and co.multileg_reporting_type <> '3'
group by gos.account_id
order by 2;

      select account_id
        from dwh.d_account ac
        where ac.trading_firm_id in ('aostb01', 'vision01') and false
          and (ac.account_id = any (:p_account_ids) or ac.trading_firm_id = any (:p_trading_firm_ids));

select distinct cl.account_id
 from dwh.client_order cl

  where CL.CREATE_date_id between :in_start_date_id and :in_end_date_id
          and CL.MULTILEG_REPORTING_TYPE in ('1', '2')

          and CL.TRANS_TYPE <> 'F'
          and CL.PARENT_ORDER_ID is not null
limit 30