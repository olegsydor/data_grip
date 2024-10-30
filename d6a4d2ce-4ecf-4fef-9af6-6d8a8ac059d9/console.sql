SELECT rep.payload ->> 'ManualExecutionTime'::text                                              AS manualexecutiontime,
       rep.payload ->> 'TransactTime'::text                                                     AS transactiondatetime,
       rep.payload ->> 'BustReason'::text                                                       AS bustreason,
       CASE
           WHEN rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]) THEN rep.payload ->> 'TradeLiquidityIndicator'::text
           END                                                                                  AS liquidityindicator,
       NULL::text                                                                               AS exchangemappedorderid,
       CASE
           WHEN (rep.payload ->> 'OrderReportSpecialType'::text) = 'M'::text THEN 'M'::text
           ELSE NULL::text
           END                                                                                  AS orderreportspecialtype,
       rep.payload ->> 'RouterExecId'::text                                                     AS exchangetransactionid,
       CASE
           WHEN rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar, 'r'::bpchar]) THEN rep.payload ->> 'LastMkt'::text
           ELSE NULL::text
           END                                                                                  AS exdestination,
       rep.payload ->> 'TransactQty'::text                                                      AS lastshares,
       rep.payload ->> 'ManualBroker'::text                                                     AS executingbroker,
       COALESCE(co.payload ->> 'OwnerUserName'::text, co.payload ->> 'InitiatorUserName'::text) AS contrabroker,
       NULL::text                                                                               AS exchangemappedorderid,
       rep.payload ->> 'LeavesQty'::text                                                        AS leavesqty,
       CASE
           WHEN co.parent_order_id IS NOT NULL THEN (SELECT client_order.cl_ord_id
                                                     FROM blaze7.client_order
                                                     WHERE client_order.order_id = co.parent_order_id
                                                     LIMIT 1)
           END                                                                                  AS parentid,
       CASE
           WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegInstrumentType'::text
                                                 FROM blaze7.client_order_leg leg
                                                 WHERE leg.order_id = rep.order_id
                                                   AND leg.chain_id = rep.chain_id
                                                   AND leg.leg_ref_id::text = rep.leg_ref_id::text)
           ELSE co.payload ->> 'InstrumentType'::text
           END                                                                                  AS securitytype, --- USE FROM LEG???
       NULL::text                                                                               AS handling,
       CASE
           WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegSeqNumber'::text
                                                 FROM blaze7.client_order_leg leg
                                                 WHERE leg.order_id = rep.order_id
                                                   AND leg.chain_id = rep.chain_id
                                                   AND leg.leg_ref_id::text = rep.leg_ref_id::text)
           ELSE '1'::text
           END                                                                                  AS legnumber,
       rep.cl_ord_id AS orderid,
       rep.exec_id as reportid,
COALESCE(rep.payload ->> 'ChildExecRefId'::text, rep.exec_id::text) AS childreportid,
       rep.order_id,
       rep.chain_id,
       -------------- TOrder
       COALESCE(co.payload ->> 'NoLegs'::text, '1'::text) AS legcount,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,GiveUp}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'::text[]
            ELSE NULL::text
        END AS giveupfirm,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'::text[]
            ELSE NULL::text
        END AS cmtafirm,
        CASE co.crossing_side
            WHEN 'C'::bpchar THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.cross_order_id = co.cross_order_id AND co2.crossing_side = 'O'::bpchar
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId'::text)::bigint)
              ORDER BY co2.chain_id DESC
             LIMIT 1)
        END AS origorderid,
            CASE co.crossing_side
            WHEN 'O'::bpchar THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.cross_order_id = co.cross_order_id AND co2.crossing_side = 'C'::bpchar
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE ((co2.payload ->> 'OriginatorOrderRefId'::text)::bigint) = co.order_id AND co2.record_type = '0'::bpchar AND co2.chain_id = 0 AND co2.db_create_time >= co.db_create_time::date AND co2.db_create_time <= (co.db_create_time::date + '1 day'::interval)
              ORDER BY co2.chain_id DESC
             LIMIT 1)
        END AS contraorderid,
           CASE
            WHEN co.parent_order_id IS NOT NULL THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = co.parent_order_id
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE NULL::character varying
        END AS parentorderid,
    ( SELECT rep.payload ->> 'NoChildren'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS childorders,
co.payload ->> 'OrderTextComment'::text AS comment,
co.payload ->> 'ProductDescription'::text AS contractdesc,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'AccountAlias'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,AccountAlias}'::text[]
            ELSE NULL::text
        END AS accountalias,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Generation}'::text[]
            ELSE NULL::text
        END AS generation,
    --------------------------------------------------
       rep.leg_ref_id,
       rep.payload,
       rep.db_create_time,
       rep.exec_type,
       co.parent_order_id,
       co.crossing_side,
       co.order_class,
       regexp_replace(co.payload::text, '\\u0000'::text, ''::text, 'g'::text)::json             AS payload,
       co.cl_ord_id,
       CASE
           WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'DashSecurityId'::text, *
                                                 FROM blaze7.client_order_leg leg
                                                 WHERE leg.order_id = co.order_id
                                                   AND leg.chain_id = co.chain_id
                                                   AND leg.leg_ref_id::text = rep.leg_ref_id::text)
           ELSE regexp_replace(co.payload::text, '\\u0000'::text, ''::text, 'g'::text)::json ->> 'DashSecurityId'::text
           END                                                                                  AS dashsecurityid,
       co.order_trade_date
FROM blaze7.order_report rep
         JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
WHERE rep.multileg_reporting_type <> '3'::bpchar
  AND (co.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
  AND (rep.exec_type::text <> ALL (ARRAY ['f'::text, 'w'::text, 'W'::text, 'g'::text, 'G'::text, 'I'::text, 'i'::text]))