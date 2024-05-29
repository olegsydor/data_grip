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

select *
from
    dash360.report_venue_new(trading_firm_ids := null,--'{"OFP0032","OFP0022","OFP0015"}',
                             account_ids := '{66297, 29609, 25349}',
                             instrument_type_id := 'O', start_status_date_id := 20240523,
                             end_status_date_id := 20240523);

select *
from
data_marts.query_yield_cap_main_report_best_ioc( trading_firm_ids  := null,--'{"OFP0032","OFP0022","OFP0015"}',
 start_status_date := 20240523::text::date, end_status_date := 20240523::text::date);


select * from dash360.report_risk_limit_usage(p_account_ids  := '{66297, 29609, 25349}', p_trading_firm_ids:= '{"OFP0032","OFP0022","OFP0015"}'
 )

select *
from dash360.get_active_child_gtc_orders(in_account_ids := '{66297, 29609, 25349}', in_start_date_id := 20240528,
                                         in_end_date_id := 20240528
--                                          in_trading_firm_ids := '{"OFP0032","OFP0022","OFP0015"}'
     )

select *
from data_marts.dash360_reports_accounts_activity(--trading_firm_ids := '{"OFP0032","OFP0022","OFP0015"}',
--                                                   account_ids := '{66297, 29609, 25349}',
                                                  start_status_date_id := 20240523, end_status_date_id := 20240523)

CREATE OR REPLACE FUNCTION dash360.dash360_report_tca_summary(trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                              account_ids bigint[] DEFAULT '{}'::bigint[],
                                                              instrument_type_id character varying DEFAULT NULL::character varying(1),
                                                              start_status_date_id integer DEFAULT NULL::integer,
                                                              end_status_date_id integer DEFAULT NULL::integer,
                                                              start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                              end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                              is_demo character DEFAULT 'N'::bpchar,
                                                              client_id character varying DEFAULT NULL::character varying(1))
    RETURNS TABLE
            (
                date_id                       integer,
                account_name                  character varying,
                parent_client_order_id        character varying,
                start_time                    timestamp without time zone,
                end_time                      timestamp without time zone,
                duration                      numeric,
                parent_order_id               bigint,
                symbol                        character varying,
                side                          integer,
                shares                        integer,
                avg_price                     numeric,
                sub_strategy                  text,
                order_start_price             numeric,
                vwap                          numeric,
                volume_during_time            bigint,
                execution_cost                numeric,
                commission_amount             numeric,
                maker_taker_fee               numeric,
                transaction_fee               numeric,
                principal_amount              numeric,
                compliance_id                 text,
                arrival_last_pl               numeric,
                percentage_arrival_last_pl    numeric,
                vwap_pl                       numeric,
                percentage_vwap_pl            numeric,
                percentage_volume_during_time numeric,
                execution_cost_unit           numeric,
                commission_amount_unit        numeric,
                maker_taker_fee_unit          numeric,
                transaction_fee_unit          numeric
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- 20240528 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4264 added coalesce(trading_firm\account, '{})
DECLARE
    select_stmt     text;
    sql_params      text;
    client_id_param text;
    row_cnt         integer;
    date_id         varchar(8);
    l_loop_id       int;

begin
    select ' '
               ||
           case when coalesce(trading_firm_ids, '{}') <> '{}' then ' and  acc.trading_firm_id=any($3)' else ' end
               || case when coalesce(account_ids, '{}') <> '{}' then ' and acc.account_id=any($4)' else ' end
               || case when instrument_type_id is not null then ' and i.instrument_type_id=$5 ' else ' end
               || case
                      when start_status_date is not null and end_status_date is not null
                          then ' and tr.trade_record_time between $6 and $7 '
                      else ' end
    into sql_params;

    select ' '
               || case when client_id is not null then 'and upper(tr.client_id) = $9' else ' end
    into client_id_param;

    select_stmt = '
select tca.date_id ,
       acc.account_name,
       tca.parent_client_order_id,
       tca.start_time,
       tca.end_time,
       tca.duration as duration,
       tca.parent_order_id,
       i.display_instrument_id as symbol,
       tca.side,
       tca.volume as shares,
       tca.avg_px as avg_price,
/*       upper(coalesce(bsn.bloomberg_strategy_name, tr.sub_strategy)) as sub_strategy,*/
       tr.sub_strategy::text as sub_strategy,
       tca.order_start_price, /*tr.bid_price, tr.ask_price, */
       tca.vwap,
       tca.volume_during_time,
	   sum(tr.tcce_firm_dash_commission_amount + tr.tcce_maker_taker_fee_amount + tr.tcce_transaction_fee_amount + tr.tcce_royalty_fee_amount) as execution_cost,
       sum(tr.tcce_firm_dash_commission_amount) as commission_amount,
       sum(tr.tcce_maker_taker_fee_amount) as maker_taker_fee,
       sum(tr.tcce_transaction_fee_amount) as transaction_fee,
	   sum(tr.principal_amount) as principal_amount,
	   max(tr.compliance_id) as compliance_id
from tca.order_tca tca
inner join dwh.flat_trade_record tr on (tca.parent_order_id = tr.order_id and tca.date_id = tr.date_id and coalesce(tca.last_trade_time, tca.end_time) >= tr.trade_record_time ' ||
                  client_id_param || ')
inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
/*left join fix_capture.fix_message_json fm on (tr.order_fix_message_id=fm.fix_message_id and fm.date_id >= $1 and fm.date_id <= $2 )
left join dwh.D_BLOOMBERG_STRATEGY_NAME bsn on (acc.trading_firm_id = bsn.trading_firm_id and tr.sub_strategy = bsn.original_sub_strategy and coalesce((fm.fix_message->>'9150')::int, -1) = coalesce(bsn.aggression_level, -1))*/
inner join dwh.d_instrument i on (tr.instrument_id = i.instrument_id and i.instrument_type_id = $5 and i.is_active)
where tr.date_id >= $1 and tr.date_id <= $2
      --and acc.account_id in ({2})
	  and tr.multileg_reporting_type = '1'
	  and tr.is_busted='N'
      and i.symbol not in ('ZVZZT', 'ZWZZT', 'CBO', 'CBX', 'IBO', 'IGZ', 'ZBZX', 'ZTEST', 'ZTST', 'ZZZ', 'ZZK', 'ZVV')
	 ' || sql_params || '
group by tr.account_id, acc.account_name, tca.date_id , tca.parent_client_order_id, tca.start_time, tca.end_time, tca.duration, tca.parent_order_id,i.display_instrument_id, tca.side, tca.volume, tca.avg_px , tr.sub_strategy, /* coalesce (bsn.bloomberg_strategy_name, tr.sub_strategy),*/
       tca.order_start_price, tca.vwap, tca.volume_during_time
order by parent_order_id
limit 1000';

    RETURN QUERY
        execute select_stmt using start_status_date_id, end_status_date_id, trading_firm_ids, account_ids, instrument_type_id, start_status_date, end_status_date, is_demo, client_id;

end;
$function$
;
