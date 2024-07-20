/*select rep.payload ->> 'TransactTime'                                              as rep_payload_TransactTime,
       rep.payload ->> 'ChildExecRefId'                                            as rep_payload_ChildExecRefId,
       rep.payload ->> 'OriginatedBy'                                              as rep_payload_OriginatedBy,
       rep.payload ->> 'OrderReportSpecialType'                                    as rep_payload_OrderReportSpecialType,
       rep.payload ->> 'TradeLiquidityIndicator'                                   as rep_payload_TradeLiquidityIndicator,
       rep.payload ->> 'OrderReportSpecialType'                                    as rep_payload_OrderReportSpecialType,
       rep.payload ->> 'RouterExecId'                                              as rep_payload_RouterExecId,
       rep.payload ->> 'TransactQty'                                               as rep_payload_TransactQty,
       rep.payload ->> 'LastPx'                                                    as rep_payload_LastPx,
       rep.payload ->> 'LastPx2'                                                   as rep_payload_LastPx2,
       rep.payload ->> 'ManualBroker'                                              as rep_payload_ManualBroker,
       rep.payload ->> 'LeavesQty'                                                 as rep_payload_LeavesQty,
       (select rep.payload ->> 'NoChildren'
        from blaze7.order_report rep
        where rep.cl_ord_id::text = co.cl_ord_id::text
        order by rep.exec_id desc
        limit 1)                                                                   as last_child_order,
       rep.payload ->> 'InstrumentType'                                            as rep_payload_InstrumentType,
       rep.payload ->> 'OrderReportSpecialType'                                    as rep_payload_OrderReportSpecialType,
       rep.payload ->> 'RouterExecId'                                              as rep_payload_RouterExecId,
       --

       case
           when co.crossing_side is null then co.payload ->> 'Side'
           when co.crossing_side = 'O' then co.payload #>> '{OriginatorOrder,Side}'
           when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,Side}'
           end                                                                     as side,

       case
           when co.instrument_type = 'M' then leg_payload_PositionEffect
           when co.crossing_side IS NULL then co.payload ->> 'PositionEffect'
           when co.crossing_side = 'O' then co.payload #>> '{OriginatorOrder,PositionEffect}'
           when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,PositionEffect}'
           end                                                                     AS openclose,

       co.payload ->> 'OrderQty'                                                   as co_payload_OrderQty,
       co.payload ->> 'NoLegs'                                                     as co_payload_NoLegs,

       coalesce(
               case
                   when co.crossing_side is null then co.payload #>> '{ClearingDetails,GiveUp}'
                   when co.crossing_side = 'O' then co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'
                   when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'
                   end, rep.payload ->> 'ManualBroker')                            as exec_broker,

       case
           when co.crossing_side is null then co.payload #>> '{ClearingDetails,CMTA}'
           when co.crossing_side = 'O' then co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'
           when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'
           end                                                                     AS cmtafirm,
       co.payload ->> 'OriginatorOrderRefId'                                       as co_payload_OriginatorOrderRefId,
       coalesce(co.payload ->> 'OwnerUserName', co.payload ->> 'InitiatorUserName')          as contra_broker,
       case
           when co.instrument_type <> 'M'::bpchar then co.payload ->> 'Price'::text
           when leg_payload_LegPrice is not null then leg_payload_LegPrice
           when co.crossing_side = 'O'::bpchar then co.payload #>> '{OriginatorOrder,Price}'::text[]
           when co.crossing_side = 'C'::bpchar then co.payload #>> '{ContraOrder,Price}'::text[]
           ELSE co.payload ->> 'Price'::text
           end                                                                     AS order_price,

       co.payload ->> 'OriginatorOrderRefId'                                       as co_payload_OriginatorOrderRefId,
       co.payload ->> 'OrderTextComment'                                           as co_payload_OrderTextComment,
       co.payload ->> 'ProductDescription'                                         as co_payload_ProductDescription,
       co.payload ->> 'NoLegs'                                                     as co_payload_NoLegs,
       co.payload ->> 'DashSecurityId'                                             as co_payload_DashSecurityId,
       substring(co.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})')            as ds_id_1,    -- EQ\OP
       to_date(substring(co.payload ->> 'DashSecurityId', '([0-9]{6})'), 'YYMMDD') as ds_id_date, -- DATE
       substring(co.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$')                as ds_id_num,  -- PRICE
       substring(co.payload ->> 'DashSecurityId', 'US:EQ:(.+)')                    as ds_id_2,    -- EQ_SYMBOL
       substring(co.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_')           as ds_id_3,    -- OP_SYMBOL
       substring(co.payload ->> 'DashSecurityId', '[0-9]{6}(.)')                   as ds_id_4,    -- P/C
       case
           when co.crossing_side is null then co.payload ->> 'Generation'
           when co.crossing_side = 'O' then co.payload #>> '{OriginatorOrder,Generation}'
           when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,Generation}'
           end                                                                     as generation,
       (select co2.cl_ord_id
        from blaze7.client_order co2
        where co2.order_id = co.parent_order_id
          and co.parent_order_id is null
        order by co2.chain_id desc
        limit 1)                                                                   as parentorderid,
       (select co2.cl_ord_id
        from blaze7.client_order co2
        where co2.order_id = (co.payload ->> 'OriginatorOrderRefId')::bigint
        order by co2.chain_id desc
        limit 1)                                                              as orig_cl_ord_id,
       case co.crossing_side
           when 'C' then (select co2.cl_ord_id
                                  from blaze7.client_order co2
                                  where co2.cross_order_id = co.cross_order_id
                                    and co2.crossing_side = 'O'
                                  order by co2.chain_id desc
                                  limit 1)
           else (select co2.cl_ord_id
                 from blaze7.client_order co2
                 where co2.order_id = (co.payload ->> 'OriginatorOrderRefId'::text)::bigint
                 order by co2.chain_id desc
                 limit 1)
           end                                                                as orig_order_id
from blaze7.client_order co
         join blaze7.order_report rep on rep.order_id = co.order_id and co.chain_id = rep.chain_id
         left join lateral (
    select leg.payload ->> 'LegSide'                                                    as leg_payload_LegSide,
           leg.payload ->> 'PositionEffect'                                             as leg_payload_PositionEffect,
           leg.payload ->> 'LegInstrumentType'                                          as leg_payload_LegInstrumentType,
           leg.payload ->> 'LegQty'                                                     as leg_payload_LegQty,
           leg.payload ->> 'LegPrice'                                                   as leg_payload_LegPrice,
           leg.payload ->> 'LegSeqNumber'                                               as leg_payload_LegSeqNumber,
           leg.payload ->> 'DashSecurityId'                                             as leg_payload_DashSecurityId,
           substring(leg.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})')            as ds_id_1,    -- EQ\OP
           to_date(substring(leg.payload ->> 'DashSecurityId', '([0-9]{6})'), 'YYMMDD') as ds_id_date, -- DATE
           substring(leg.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$')                as ds_id_num,  -- PRICE
           substring(leg.payload ->> 'DashSecurityId', 'US:EQ:(.+)')                    as ds_id_2,    -- EQ_SYMBOL
           substring(leg.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_')           as ds_id_3,    -- OP_SYMBOL
           substring(leg.payload ->> 'DashSecurityId', '[0-9]{6}(.)')                   as ds_id_4     -- P/C
    from blaze7.client_order_leg leg
    where leg.order_id = co.order_id
      AND leg.chain_id = co.chain_id
      and leg.leg_ref_id = rep.leg_ref_id
    ) leg on true
where true
  and rep.multileg_reporting_type <> '3'
  AND co.record_type in ('0', '2')
  AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i')
  and co.order_id = 563653227707367424;


*/


select co_main.order_id                                                            as order_id,
       co_main.chain_id                                                            as chain_id,
--------------
       rep.exec_type                                                               as exec_type,
       rep.payload ->> 'TransactTime'                                              AS trade_record_time,
       to_char((rep.payload ->> 'TransactTime')::timestamp, 'YYYYMMDD')::int4      AS date_id,
       'LPEDW'                                                                     as subsystem_id,
       co.cl_ord_id,
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'LegSide'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'
           END                                                                     AS side,
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'PositionEffect'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'
           WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,PositionEffect}'
           WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,PositionEffect}'
           END                                                                     AS openclose,
       coalesce(case when rep.exec_type in ('1', '2') then rep.payload ->> 'TradeLiquidityIndicator' end, 'R')  as liquidityindicator,
       null::text                                                                  as secondary_order_id,
       '0'                                                                         as exch_exec_id,
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
           ELSE rep.payload ->> 'RouterExecId' END                                 as secondary_exch_exec_id,

       (rep.payload ->> 'TransactQty')::int8                                       AS lastshares,
       case
           when rep.exec_type in ('1', '2', 'r')
               then round(coalesce(((rep.payload ->> 'LastPx2')::bigint)::numeric / 10000.0,
                                   ((rep.payload ->> 'LastPx')::bigint)::numeric) / 10000.0, 8)
           else '0'::numeric
           end                                                                     as last_px,

       rp.ex_destination                                                           as ex_destination,
       case
           when coalesce(leg.dash_sec_eq_op, co.dash_sec_eq_op) in ('FO', 'OP')
               then coalesce(leg.dash_sec_date, co.dash_sec_date) end              as expiration_date,
       case
           when coalesce(leg.dash_sec_eq_op, co.dash_sec_eq_op) in ('FO', 'OP')
               then (coalesce(leg.dash_sec_price, co.dash_sec_price))::numeric end as strike,
       case
           when co.instrument_type = 'O' then co.payload ->> 'OrderQty'
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'O'
               then leg.payload ->> 'LegQty' end                                   as opt_qty,
       case
           when co.instrument_type = 'E' then co.payload ->> 'OrderQty'
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
               then leg.payload ->> 'LegQty'
           end                                                                     as eq_qty,
       case
           when co.instrument_type = 'E' then rep_last."LeavesQty"
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
               then rep_last_exec."LeavesQty"
           end                                                                     as eq_leaves_qty,
       -- order_qty is as same as street_order_qty
       case
           when (coalesce(co.payload ->> 'NoLegs', '1'))::int > 1 then 2
           else 1 end                                                              as multileg_reporting_type,
       coalesce(case
                    when co.crossing_side is null then co.payload #>> '{ClearingDetails,GiveUp}'
                    when co.crossing_side = 'O'
                        then co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'
                    when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'
                    else null::text
                    end, rep.payload ->>
                         'ManualBroker')                                           as exec_broker,

       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'
           WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'
           WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'
           END                                                                     AS cmtafirm,
       co.crossing_side,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.cross_order_id = co.cross_order_id
          AND co2.crossing_side = 'O'
        ORDER BY co2.chain_id DESC
        LIMIT 1)                                                                   as cross_cl_ord_id,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId')::bigint)
        ORDER BY co2.chain_id DESC
        LIMIT 1)                                                                   as orig_cl_ord_id,
       -- street_is_cross_order is as same as is_cross_order
       COALESCE(co.payload ->> 'OwnerUserName', co.payload ->>
                                                'InitiatorUserName')               as contra_broker,
--        coalesce(comp.CompanyCode, u.Login) as client_id,
       CASE
           WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
           WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
           ELSE co.payload ->> 'Price'::text
           END                                                                     AS order_price,
       '???'                                                                       as order_process_time,
       '???'                                                                       as remarks,
       null                                                                        as street_client_order_id,
       'LPEDWCOMPID'                                                               as fix_comp_id,
       rep.payload ->> 'LeavesQty'                                                 as leaves_qty,
       CASE co.instrument_type
           WHEN 'M' THEN leg.payload ->> 'LegSeqNumber'
           ELSE '1'
           END                                                                     AS leg_ref_id,

       CASE co.crossing_side
           WHEN 'C'::bpchar THEN (SELECT co2.cl_ord_id
                                  FROM blaze7.client_order co2
                                  WHERE co2.cross_order_id = co.cross_order_id
                                    AND co2.crossing_side = 'O'::bpchar
                                  ORDER BY co2.chain_id DESC
                                  LIMIT 1)
           ELSE (SELECT co2.cl_ord_id
                 FROM blaze7.client_order co2
                 WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId'::text)::bigint)
                 ORDER BY co2.chain_id DESC
                 LIMIT 1)
           END                                                                     as orig_order_id,
       CASE co.crossing_side
           WHEN 'O'::bpchar THEN (SELECT co2.cl_ord_id
                                  FROM blaze7.client_order co2
                                  WHERE co2.cross_order_id = co.cross_order_id
                                    AND co2.crossing_side = 'C'::bpchar
                                  ORDER BY co2.chain_id DESC
                                  LIMIT 1)
           ELSE (SELECT co2.cl_ord_id
                 FROM blaze7.client_order co2
                 WHERE ((co2.payload ->> 'OriginatorOrderRefId'::text)::bigint) = co.order_id
                   AND co2.record_type = '0'::bpchar
                   AND co2.chain_id = 0
                   AND co2.db_create_time >= co.db_create_time::date
                   AND co2.db_create_time <= (co.db_create_time::date + '1 day'::interval)
                 ORDER BY co2.chain_id DESC
                 LIMIT 1)
           END                                                                     as contra_order_id,
       CASE
           WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                     FROM blaze7.client_order co2
                                                     WHERE co2.order_id = co.parent_order_id
                                                     ORDER BY co2.chain_id DESC
                                                     LIMIT 1)
           ELSE NULL::character varying
           END                                                                     as parent_order_id,
       (SELECT rep.payload ->> 'NoChildren'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        limit 1)                                                                      last_child_order,
       co.payload ->> 'OrderTextComment'                                           as rep_comment,
       case when co.parent_order_id is null then 'Y' else 'N' end                  as is_parent,

       regexp_replace(
               COALESCE(leg.dash_sec_eq_symbol, co.dash_sec_eq_symbol, leg.dash_sec_op_symbol, co.dash_sec_op_symbol),
               '\.|-', '/',
               'g')                                                                as symbol,
       round((case
                  when coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) in ('FO', 'OP')
                      THEN coalesce(co.dash_sec_price, leg.dash_sec_price)::numeric END)::numeric,
             6)                                                                    AS strike_price,

       CASE
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = 'EQ' THEN 'S'
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) in ('FO', 'OP')
               THEN left(coalesce(co.dash_sec_eq_symbol, leg.dash_sec_eq_symbol), 1)
           END                                                                     as type_code,

       -- will be transformed into maturity_year\month\day
       CASE
           WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegInstrumentType'::text
                                                 FROM blaze7.client_order_leg leg
                                                 WHERE leg.order_id = rep.order_id
                                                   AND leg.chain_id = rep.chain_id
                                                   AND leg.leg_ref_id::text = rep.leg_ref_id::text)
           ELSE rep.payload ->> 'InstrumentType'::text
           END                                                                     AS securitytype,

       (SELECT rep.payload ->> 'NoChildren'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                   as child_orders,
-- ISNULL(CASE WHEN r.OrderReportSpecialType = 'M' then lt.ID ELSE r.[Handling] END,0) [Handling]
       0                                                                           as secondary_order_id2,
-- expiration_date,
-- strike_price,
-- tl.[RootCode]
       coalesce(co.dash_sec_eq_symbol, leg.dash_sec_eq_symbol, co.dash_sec_op_symbol,
                leg.dash_sec_op_symbol)                                            AS rootcode,
-- tl.BaseCode
       coalesce(co.dash_sec_eq_symbol, leg.dash_sec_eq_symbol, co.dash_sec_op_symbol,
                leg.dash_sec_op_symbol)                                            AS basecode,
-- tl.TypeCode = ct.type_code
       CASE
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = 'EQ' THEN 'S'
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = ANY (ARRAY ['FO', 'OP'])
               THEN coalesce(co.dash_sec_pc, leg.dash_sec_pc)
           END                                                                     AS typecode,
       regexp_replace(coalesce(leg.dash_sec_eq_symbol, leg.dash_sec_op_symbol), '\.|-',
                      '')                                                          as display_instrument_id_2,
-- ContractDesc
       coalesce(co.payload ->> 'ProductDescription', '')::text                     as ord_ContractDesc,
       COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                          as legcount,
       CASE
           WHEN (rep.payload ->> 'OrderReportSpecialType'::text) = 'M'::text THEN 'M'::text
           ELSE NULL::text
           END                                                                     AS orderreportspecialtype,

       co.dash_sec_eq_op                                                           as dash_sec_2,
       co.dash_sec_date                                                            as dase_sec_date,
       co.dash_sec_price                                                           as dash_sec_num,
       co.dash_sec_eq_symbol                                                       as dash_sec_eq,
       co.dash_sec_op_symbol                                                       as dase_sec_op,

       leg.dash_sec_eq_op                                                          as leg_dash_sec_2,
       leg.dash_sec_date                                                           as leg_dase_sec_date,
       leg.dash_sec_price                                                          as leg_dash_sec_num,
       leg.dash_sec_eq_symbol                                                      as leg_dash_sec_eq,
       leg.dash_sec_op_symbol                                                      as leg_dase_sec_op,
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
           ELSE rep.payload ->> 'RouterExecId' END                                 as ExchangeTransactionID,
       co.generation,
       clordid_to_guid(rep.cl_ord_id)                                              as orderid,
       co.parentorderid                                                            as parentorderid,
       rep.db_create_time,
       co.payload ->> 'DashSecurityId' as co_dash_security_id,
       leg.payload ->> 'DashSecurityId' as leg_dash_security_id,
-- for join to LForWhom
       case
           when co.crossing_side is null
               THEN co.payload #>> '{ClearingDetails,OptionRange}'
           WHEN co.crossing_side = 'O'
               THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'
           WHEN co.crossing_side = 'C'
               THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'
           ELSE NULL::text
           END as option_range,
-- for join to staging.TCompany
       (CASE
            WHEN co.order_class = 'F' THEN co.payload ->> 'InitiatorEntityId'
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientEntityId'
            WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,ClientEntityId}'
            WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,ClientEntityId}'
           END)::int4 as client_entity_id,
       rep.payload ->> 'LiquidityType' as rep_liquidity_type
from blaze7.client_order co_main
         join lateral (select *,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end  as dash_sec_eq_op,
                              case
                                  when co.instrument_type <> 'M' then to_date(
                                          "substring"(co.payload ->> 'DashSecurityId', '([0-9]{6})'),
                                          'YYMMDD') end                                                            as dash_sec_date,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end      as dash_sec_price,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end          as dash_sec_eq_symbol,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as dash_sec_op_symbol,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', '[0-9]{6}(.)') end         as dash_sec_pc,
                              CASE
                                  WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
                                  WHEN co.crossing_side = 'O'::bpchar
                                      THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
                                  WHEN co.crossing_side = 'C'::bpchar
                                      THEN co.payload #>> '{ContraOrder,Generation}'::text[]
                                  END                                                                              AS generation,
                              case
                                  when co.parent_order_id is null then (SELECT co2.cl_ord_id
                                                                        FROM blaze7.client_order co2
                                                                        WHERE co2.order_id = co.parent_order_id
                                                                        ORDER BY co2.chain_id DESC
                                                                        LIMIT 1) end                               as parentorderid
                       from blaze7.client_order co
                       where co.order_id = co_main.order_id
                         AND co.chain_id = co_main.chain_id
                       limit 1) co on true
         join blaze7.order_report rep on rep.order_id = co.order_id and co.chain_id = rep.chain_id
         left join lateral (select leg.payload,
                                   leg.leg_ref_id,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end  as dash_sec_eq_op,
                                   case
                                       when co.instrument_type = 'M' then to_date(
                                               "substring"(leg.payload ->> 'DashSecurityId', '([0-9]{6})'),
                                               'YYMMDD') end                                                             as dash_sec_date,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end      as dash_sec_price,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end          as dash_sec_eq_symbol,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as dash_sec_op_symbol,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', '[0-9]{6}(.)') end         as dash_sec_pc
                            from blaze7.client_order_leg leg
                            where leg.order_id = co.order_id
                              AND leg.chain_id = co.chain_id
                              and leg.leg_ref_id = rep.leg_ref_id) leg on true

         left join lateral (select regexp_replace(rep.payload ->> 'LastMkt', 'DIRECT-| Printer', '', 'g') as ex_destination
                            from blaze7.order_report rp
                            where rp.exec_id = rep.exec_id
                            limit 1) rp on true


         LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text       AS "CumQty",
                                    rep.payload ->> 'AvgPx'::text        AS "AvgPx",
                                    rep.payload ->> 'LeavesQty'::text    AS "LeavesQty",
                                    rep.payload ->> 'CanceledQty'::text  AS "CanceledQty",
                                    rep.payload ->> 'TransactTime'::text AS "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                               AND COALESCE(rep.leg_ref_id::text, 'leg_ref_id'::text) =
                                   COALESCE(leg.leg_ref_id::text, 'leg_ref_id'::text)
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last_exec ON true
         LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text       AS "CumQty",
                                    rep.payload ->> 'AvgPx'::text        AS "AvgPx",
                                    rep.payload ->> 'LeavesQty'::text    AS "LeavesQty",
                                    rep.payload ->> 'CanceledQty'::text  AS "CanceledQty",
                                    rep.payload ->> 'TransactTime'::text AS "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last ON true

where true
  and rep.multileg_reporting_type <> '3'
  AND co_main.record_type in ('0', '2')
  AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i')
  and co_main.order_id = 563653227707367424;