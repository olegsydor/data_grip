select *
from dash360.report_ecr(start_date_id := 20260101, end_date_id := 20261231,
                        trading_firm_ids := '{"barclay05","barclay04","barclay06","barclay09","barclay07"}',
                        instrument_type_id := 'O', client_id := null,
                        p_demo_mode := 'N', p_row_limit := null, p_commission_display_mode := '1', p_group_by := 'S',
                        in_only_sub_dollar := 'A');


select ecr."Date"                          as "Date"
     , ecr."Account"                       as "Account"
     , ecr."wbAccount"                     as "wbAccount"
     , null::varchar                       as "ClOrdID"
     , ecr."ClientID"                      as "ClientID"
     , null::char                          as "SecurityType"
     , ecr."SubStrategy"                   as "SubStrategy"
     , null::varchar                       as "OSISymbol"
     , null::varchar                       as "Symbol"
     , null::char                          as "Side"
     , ecr."ContraBroker"                  as "ContraBroker"
     , sum(ecr."ExecQty")::bigint          as "ExecQty"
     , sum(ecr."AvgPx")                    as "AvgPx"
     , sum(ecr."PrincipalAmount")          as "PrincipalAmount"
     , sum(ecr."ExecCost")                 as "ExecCost"
     , sum(ecr."DashCommissionAmount")     as "DashCommissionAmount"
     , sum(ecr."MakerTakerFeeAmount")      as "MakerTakerFeeAmount"
     , sum(ecr."TransactionFeeAmount")     as "TransactionFeeAmount"
     , sum(ecr."TradeProcessingFeeAmount") as "TradeProcessingFeeAmount"
     , sum(ecr."RoyaltyFeeAmount")         as "RoyaltyFeeAmount"
     , null::smallint                      as "MaturityYear"
     , null::smallint                      as "MaturityMonth"
     , null::smallint                      as "MaturityDay"
     , ecr."ClientAlgoAlias"
from (SELECT "Date"
           , case
                 when $7 = 'Y' then acc.ACCOUNT_DEMO_MNEMONIC
                 else coalesce(ano.overriden_account_name, acc.ACCOUNT_NAME) end                              as "Account"
           , case
                 when acc.trading_firm_id in ('wallach', 'wbetetf') and left(acc.account_name, 2) = 'WB' and
                      (substring(acc.account_name from 3) ~ '^[0-9\.]+$') = true
                     then substring(acc.account_name from 3)
                 else acc.account_name
        end                                                                                                   as "wbAccount"
           , "ClOrdID"
           , case when $7 = 'Y' then '' else "ClientID" end                                                   as "ClientID"
           , "SecurityType"
--, "SubStrategy"
           , COALESCE(replace(ed.EX_DESTINATION_CODE_NAME, 'LiquidPoint', 'DASH'),
                      L1."SubStrategy")::varchar                                                              as "SubStrategy"
           , OC.OPRA_SYMBOL                                                                                   AS "OSISymbol"
           , "Symbol"
           , "Side"
           , "ContraBroker"
           , "ExecQty"
--,  (ROUND("PrincipalAmount"/NULLIF("ExecQty",0),4) )::numeric as "AvgPx"
           , "AvgPx"
           , "PrincipalAmount"
           , case $9
                 when '1' then coalesce("MakerTakerFeeAmount", 0.0) + coalesce("TransactionFeeAmount", 0.0) +
                               coalesce("TradeProcessingFeeAmount", 0.0) + coalesce("RoyaltyFeeAmount", 0.0)
                 else "ExecCost"
        end                                                                                                   as "ExecCost"
           , case $9
                 when '1' then 0.0
                 else "DashCommissionAmount"
        end                                                                                                   as "DashCommissionAmount"
           , "MakerTakerFeeAmount"
           , "TransactionFeeAmount"
           , "TradeProcessingFeeAmount"
           , "RoyaltyFeeAmount"
           , OC.MATURITY_YEAR                                                                                 as "MaturityYear"
           , OC.MATURITY_MONTH                                                                                as "MaturityMonth"
           , OC.MATURITY_DAY                                                                                  as "MaturityDay"
           , tag_9310                                                                                         as "ClientAlgoAlias"
      FROM (select ft.order_id
                 , ft.client_order_id                                                               as "ClOrdID"
                 , ft.SIDE                                                                          as "Side"
                 , ft.INSTRUMENT_ID
                 , ft.trade_record_time::date                                                       as "Date"
                 , ft.ACCOUNT_ID
                 , ft.TRADING_FIRM_ID
                 , coalesce(cno.overriden_client_name, ft.CLIENT_ID)                                as "ClientID"
                 , i.INSTRUMENT_TYPE_ID                                                             as "SecurityType"
                 , I.DISPLAY_INSTRUMENT_ID                                                          AS "Symbol"
--, ft.sub_strategy       as "SubStrategy"
                 , upper(coalesce(bsn.bloomberg_strategy_name, ft.sub_strategy))::character varying as "SubStrategy"
                 , ft.ex_destination
                 , ft.contra_broker                                                                 AS "ContraBroker"
                 , sum(last_qty)                                                                    as "ExecQty"
                 , ROUND(sum(last_qty * last_px) / NULLIF(sum(last_qty), 0), 4)::numeric            as "AvgPx"
                 , 0                                                                                as BUSTED_EXEC_QTY
                 , sum(ft.principal_amount)                                                         as "PrincipalAmount"
                 , sum(ft.tcce_account_execution_cost)                                              as "ExecCost"
                 , sum(ft.tcce_account_dash_commission_amount)                                      as "DashCommissionAmount"
                 , sum(ft.tcce_maker_taker_fee_amount)                                              AS "MakerTakerFeeAmount"
--                ,case when ft.trading_firm_id in(select etrf.trading_firm_id from staging.edw_trading_firm_all_in etrf)
--         then sum(ft.tcce_admin_maker_taker_fee_amount) else sum(ft.tcce_maker_taker_fee_amount)
--         end AS  "MakerTakerFeeAmount"
                 , sum(ft.tcce_transaction_fee_amount)                                              AS "TransactionFeeAmount"
--                ,case when ft.trading_firm_id in(select etrf.trading_firm_id from staging.edw_trading_firm_all_in etrf)
--         then sum(ft.tcce_admin_transaction_fee_amount) else sum(ft.tcce_transaction_fee_amount)
--         end AS "TransactionFeeAmount"
                 , sum(ft.tcce_trade_processing_fee_amount)                                         AS "TradeProcessingFeeAmount"
                 , sum(ft.tcce_royalty_fee_amount)                                                  AS "RoyaltyFeeAmount"
                 , tag_9310::varchar                                                                as tag_9310
            from dwh.flat_trade_record ft
                     inner join dwh.d_instrument i on (ft.instrument_id = i.instrument_id)
                     left join lateral (select fix_message_jsonb ->> '9310' as tag_9310
                                        from fix_capture.fix_message_json fmj
                                        where fmj.date_id between $1 and $2
                                          and fmj.fix_message_id = ft.order_fix_message_id
                                        limit 1) fmj on true
                     left join dwh.d_client_name_override cno on (ft.trading_firm_id = cno.trading_firm_id and
                                                                  coalesce(ft.client_id, '-1') =
                                                                  coalesce(cno.original_client_name, '-1'))
                     left join dwh.client_order fm
                               on (ft.order_id = fm.order_id and fm.create_date_id between $1 and $2)
                     left join dwh.d_bloomberg_strategy_name bsn on (ft.trading_firm_id = bsn.trading_firm_id and
                                                                     ft.sub_strategy = bsn.original_sub_strategy and
                                                                     coalesce(fm.aggression_level, -1) =
                                                                     coalesce(bsn.aggression_level, -1))
            where date_id between $1 and $2
              and ft.trading_firm_id = any ($3)
              and i.instrument_type_id = $5
              and is_busted = 'N'
--and ft.order_id is not null
            group by ft.order_id,
                     ft.client_order_id,
                     ft.SIDE,
                     ft.INSTRUMENT_ID,
                     ft.trade_record_time::date,
                     ft.ACCOUNT_ID,
                     ft.TRADING_FIRM_ID,
                     coalesce(cno.overriden_client_name, ft.CLIENT_ID),
                     I.DISPLAY_INSTRUMENT_ID,
                     i.INSTRUMENT_TYPE_ID,
                     ft.sub_strategy,
                     ft.ex_destination,
                     bsn.bloomberg_strategy_name,
                     "ContraBroker",
                     tag_9310) L1
               left join dwh.d_option_contract oc on (L1.instrument_id = oc.instrument_id)
               inner join dwh.d_account acc on (L1.account_id = acc.account_id)
               left join dwh.d_account_name_override ano on (acc.account_id = ano.account_id)
               left join dwh.d_ex_destination_code ed
                         on COALESCE(L1."SubStrategy", 'DMA') = 'DMA' and ed.is_active = true AND
                            ed.ex_destination_code = L1.ex_destination
      order by "Date", "Symbol"
      limit $8) ecr
group by ecr."Account", ecr."wbAccount", ecr."ClientID", ecr."Date", ecr."SubStrategy", ecr."ContraBroker",
         ecr."ClientAlgoAlias"

select count(*)
 from dwh.flat_trade_record ft
                     inner join dwh.d_instrument i on (ft.instrument_id = i.instrument_id)
                     left join lateral (select fix_message_jsonb ->> '9310' as tag_9310
                                        from fix_capture.fix_message_json fmj
                                        where fmj.date_id between 20260101 and 20260523
                                          and fmj.fix_message_id = ft.order_fix_message_id
                                        limit 1) fmj on true
                     left join dwh.d_client_name_override cno on (ft.trading_firm_id = cno.trading_firm_id and
                                                                  coalesce(ft.client_id, '-1') =
                                                                  coalesce(cno.original_client_name, '-1'))
                     left join dwh.client_order fm
                               on (ft.order_id = fm.order_id and fm.create_date_id between 20260101 and 20260523)
                     left join dwh.d_bloomberg_strategy_name bsn on (ft.trading_firm_id = bsn.trading_firm_id and
                                                                     ft.sub_strategy = bsn.original_sub_strategy and
                                                                     coalesce(fm.aggression_level, -1) =
                                                                     coalesce(bsn.aggression_level, -1))
            where date_id between 20260101 and 20260523
              and ft.trading_firm_id = any ('{"barclay05","barclay04","barclay06","barclay09","barclay07"}')
              and i.instrument_type_id = 'O'
              and is_busted = 'N'