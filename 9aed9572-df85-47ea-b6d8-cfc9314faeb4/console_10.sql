CREATE OR REPLACE VIEW blaze7.torder_edw
AS
SELECT NULL::text                                                                           AS id,
       NULL::text                                                                           AS systemid,
       co.cl_ord_id                                                                         AS systemorderid,
       CASE
           WHEN co.route_destination::text = 'VEGA'::text THEN 'VEGA'::bpchar
           WHEN (co.payload ->> 'HasStitchedOrders'::text) = 'Y'::text THEN 'StitchedSingle'::bpchar
           WHEN COALESCE(co.payload ->> 'IsStitched'::text, co.payload #>> '{OriginatorOrder,IsStitched}'::text[]) = 'Y'::text
               THEN 'StitchedSpread'::bpchar
           WHEN co.order_class = 'I'::bpchar THEN 'G'::bpchar
           ELSE co.order_class
           END                                                                              AS systemordertypeid,
       co.cl_ord_id                                                                         AS orderid,
       CASE
           WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                     FROM blaze7.client_order co2
                                                     WHERE co2.order_id = co.parent_order_id
                                                     ORDER BY co2.chain_id DESC
                                                     LIMIT 1)
           ELSE NULL::character varying
           END                                                                              AS parentorderid,
       co.orig_cl_ord_id                                                                    AS cancelorderid,
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
           END                                                                              AS contraorderid,
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
           END                                                                              AS origorderid,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.orig_cl_ord_id::text = co.cl_ord_id::text
          AND co2.record_type = '0'::bpchar
        ORDER BY co2.chain_id DESC
        LIMIT 1)                                                                            AS replaceorderid,
       CASE
           WHEN COALESCE(co.payload ->> 'LinkedStageOrderId'::text,
                         co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[],
                         co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[]) IS NOT NULL THEN 'T'::text
           ELSE (SELECT rp.payload ->> 'BlazeOrderStatus'::text
                 FROM blaze7.order_report rp
                 WHERE rp.cl_ord_id::text = co.cl_ord_id::text
                   AND rp.leg_ref_id IS NULL
                 ORDER BY rp.exec_id DESC
                 LIMIT 1)
           END                                                                              AS status,
       CASE
           WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
           ELSE (SELECT co2.payload ->> 'OrderCreationTime'::text
                 FROM blaze7.client_order co2
                 WHERE co2.cl_ord_id::text = co.cl_ord_id::text
                   AND co2.chain_id = 0)
           END                                                                              AS createdatetime,
       NULL::text                                                                           AS approveddatetime,
       NULL::text                                                                           AS dtclearbookdatetime,
       (SELECT rep.payload ->> 'TransactTime'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
          AND CASE
                  WHEN co.instrument_type <> 'M'::bpchar THEN true
                  ELSE rep.leg_ref_id IS NOT NULL
            END
        ORDER BY rep.exec_id
        LIMIT 1)                                                                            AS firstfilldatetime,
       (SELECT rep.payload ->> 'TransactTime'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
          AND CASE
                  WHEN co.instrument_type <> 'M'::bpchar THEN true
                  ELSE rep.leg_ref_id IS NOT NULL
            END
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS lastfilldatetime,
       (SELECT rep.payload ->> 'TransactTime'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS updatedatetime,
       (SELECT CASE
                   WHEN (rep.payload ->> 'OrderStatus'::text) = ANY
                        (ARRAY ['2'::text, '3'::text, '4'::text, '8'::text, 'P'::text, 'l'::text, '5'::text])
                       THEN rep.payload ->> 'TransactTime'::text
                   ELSE NULL::text
                   END AS "case"
        FROM blaze7.order_report rep
        WHERE rep.leg_ref_id IS NULL
          AND rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS completeddatetime,
       NULL::text                                                                           AS writedatetime,
       CASE
           when co.order_class = 'F' then co.payload ->> 'InitiatorUserId'
           when co.crossing_side is null then co.payload ->> 'ClientUserId'
           when co.crossing_side = 'O' then co.payload #>> '{OriginatorOrder,ClientUserId}'
           when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,ClientUserId}'
           --             WHEN co.crossing_side = 'O'::bpchar THEN COALESCE(co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[], co.payload ->> 'InitiatorUserId'::text)
--             WHEN co.crossing_side = 'C'::bpchar THEN COALESCE(co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[], co.payload ->> 'InitiatorUserId'::text)
--             WHEN co.crossing_side IS NULL THEN COALESCE(co.payload #>> '{ClearingDetails,CustomerUserId}'::text[], co.payload ->> 'InitiatorUserId'::text)
--             ELSE NULL::text
           END                                                                              AS userid,
       COALESCE(co.payload ->> 'OwnerUserId'::text, co.payload ->> 'InitiatorUserId'::text) AS ownerid,
       NULL::text                                                                           AS previousownerid,
       CASE
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar
               THEN co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CustomerUserId}'::text[]
           ELSE NULL::text
           END                                                                              AS sendinguserid,
       NULL::text                                                                           AS executingbroker,
       CASE
           when co.order_class = 'F' then co.payload ->> 'InitiatorEntityId'
           when co.crossing_side is null then co.payload ->> 'ClientEntityId'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClientEntityId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClientEntityId}'::text[]
           END                                                                              AS companyid,
       co.payload ->> 'DestinationEntityId'::text                                           AS destinationcompanyid,
       NULL::text                                                                           AS introducingcompanyid,
       NULL::text                                                                           AS parentcompanyid,
       co.route_type                                                                        AS exchangeconnectionid,
       NULL::text                                                                           AS exchangeinfoid,
       NULL::text                                                                           AS exchangecomment,
       co.payload ->> 'ProductDescription'::text                                            AS contractdesc,
       NULL::text                                                                           AS strategytype,
       NULL::text                                                                           AS assetclass,
       COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                                   AS legcount,
       COALESCE(
               CASE
                   WHEN co.crossing_side IS NULL OR co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
                   WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
                   WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,Price}'::text[]
                   WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
                   ELSE NULL::text
                   END, '0'::text)                                                          AS price,
       COALESCE(co.payload ->> 'DashTargetVega'::text, co.payload ->> 'OrderQty'::text)     AS quantity,
       (SELECT rep.payload ->> 'CumQty'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS filled,
       (SELECT rep.payload ->> 'AvgPx'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          AND rep.leg_ref_id IS NULL
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS avgprice,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN (SELECT leg.payload ->> 'LegQty'::text
                                                                      FROM blaze7.client_order_leg leg
                                                                      WHERE leg.order_id = co.order_id
                                                                        AND leg.chain_id = co.chain_id
                                                                        AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
                                                                      LIMIT 1)
           WHEN co.route_destination::text = 'VEGA'::text
               THEN ((SELECT sum((leg.payload ->> 'LegQty'::text)::integer) AS sum
                      FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id
                        AND leg.chain_id = co.chain_id
                        AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text
           ELSE NULL::text
           END                                                                              AS stockquantity,
       CASE
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN (SELECT rep.payload ->> 'LeavesQty'::text
                                                                      FROM blaze7.order_report rep
                                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                        AND rep.leg_ref_id::text =
                                                                            (((SELECT leg.leg_ref_id
                                                                               FROM blaze7.client_order_leg leg
                                                                               WHERE leg.order_id = co.order_id
                                                                                 AND leg.chain_id = co.chain_id
                                                                                 AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text)
                                                                      ORDER BY rep.exec_id DESC
                                                                      LIMIT 1)
           WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'LeavesQty'::text
                                                       FROM blaze7.order_report rep
                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                       ORDER BY rep.exec_id DESC
                                                       LIMIT 1)
           ELSE NULL::text
           END                                                                              AS stockopenquantity,
       CASE
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                      FROM blaze7.order_report rep
                                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                        AND rep.leg_ref_id::text =
                                                                            (((SELECT leg.leg_ref_id
                                                                               FROM blaze7.client_order_leg leg
                                                                               WHERE leg.order_id = co.order_id
                                                                                 AND leg.chain_id = co.chain_id
                                                                                 AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text)
                                                                      ORDER BY rep.exec_id DESC
                                                                      LIMIT 1)
           WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'CumQty'::text
                                                       FROM blaze7.order_report rep
                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                       ORDER BY rep.exec_id DESC
                                                       LIMIT 1)
           WHEN co.route_destination::text = 'VEGA'::text THEN ((SELECT sum(x.sm) AS sum
                                                                 FROM (SELECT (rep.payload ->> 'CumQty'::text)::integer                                   AS sm,
                                                                              row_number()
                                                                              OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                                                       FROM blaze7.order_report rep
                                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                         AND (rep.leg_ref_id::text IN
                                                                              (SELECT leg.leg_ref_id
                                                                               FROM blaze7.client_order_leg leg
                                                                               WHERE leg.order_id = rep.order_id
                                                                                 AND leg.chain_id = rep.chain_id
                                                                                 AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))) x
                                                                 WHERE x.rn = 1))::text
           ELSE NULL::text
           END                                                                              AS stockfilled,
       CASE
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN (SELECT rep.payload ->> 'CanceledQty'::text
                                                                      FROM blaze7.order_report rep
                                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                        AND rep.leg_ref_id::text =
                                                                            (((SELECT leg.leg_ref_id
                                                                               FROM blaze7.client_order_leg leg
                                                                               WHERE leg.order_id = co.order_id
                                                                                 AND leg.chain_id = co.chain_id
                                                                                 AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text)
                                                                      ORDER BY rep.exec_id DESC
                                                                      LIMIT 1)
           WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'CanceledQty'::text
                                                       FROM blaze7.order_report rep
                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                       ORDER BY rep.exec_id DESC
                                                       LIMIT 1)
           ELSE NULL::text
           END                                                                              AS stockcancelled,
       CASE co.instrument_type
           WHEN 'O'::bpchar THEN (co.payload ->> 'OrderQty'::text)::bigint
           WHEN 'M'::bpchar THEN (SELECT sum((leg.payload ->> 'LegQty'::text)::integer) AS sum
                                  FROM blaze7.client_order_leg leg
                                  WHERE leg.order_id = co.order_id
                                    AND leg.chain_id = co.chain_id
                                    AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text)
           ELSE NULL::bigint
           END                                                                              AS optionquantity,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN (SELECT sum(x.sm) AS sum
                                  FROM (SELECT (rep.payload ->> 'LeavesQty'::text)::integer                                AS sm,
                                               row_number()
                                               OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                        FROM blaze7.order_report rep
                                        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                          AND (rep.leg_ref_id::text IN (SELECT leg.leg_ref_id
                                                                        FROM blaze7.client_order_leg leg
                                                                        WHERE leg.order_id = rep.order_id
                                                                          AND leg.chain_id = rep.chain_id
                                                                          AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
                                  WHERE x.rn = 1)
           WHEN 'O'::bpchar THEN ((SELECT (rep.payload ->> 'LeavesQty'::text)::integer AS int4
                                   FROM blaze7.order_report rep
                                   WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                   ORDER BY rep.exec_id DESC
                                   LIMIT 1))::bigint
           ELSE NULL::bigint
           END                                                                              AS optionopenquantity,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN (SELECT sum(x.sm) AS sum
                                  FROM (SELECT (rep.payload ->> 'CumQty'::text)::integer                                   AS sm,
                                               row_number()
                                               OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                        FROM blaze7.order_report rep
                                        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                          AND (rep.leg_ref_id::text IN (SELECT leg.leg_ref_id
                                                                        FROM blaze7.client_order_leg leg
                                                                        WHERE leg.order_id = rep.order_id
                                                                          AND leg.chain_id = rep.chain_id
                                                                          AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
                                  WHERE x.rn = 1)
           WHEN 'O'::bpchar THEN ((SELECT (rep.payload ->> 'CumQty'::text)::integer AS int4
                                   FROM blaze7.order_report rep
                                   WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                   ORDER BY rep.exec_id DESC
                                   LIMIT 1))::bigint
           ELSE NULL::bigint
           END                                                                              AS optionfilled,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN (SELECT sum(x.sm) AS sum
                                  FROM (SELECT (rep.payload ->> 'CanceledQty'::text)::integer                              AS sm,
                                               row_number()
                                               OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                        FROM blaze7.order_report rep
                                        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                          AND (rep.leg_ref_id::text IN (SELECT leg.leg_ref_id
                                                                        FROM blaze7.client_order_leg leg
                                                                        WHERE leg.order_id = rep.order_id
                                                                          AND leg.chain_id = rep.chain_id
                                                                          AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
                                  WHERE x.rn = 1)
           WHEN 'O'::bpchar THEN ((SELECT (rep.payload ->> 'CanceledQty'::text)::integer AS int4
                                   FROM blaze7.order_report rep
                                   WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                   ORDER BY rep.exec_id DESC
                                   LIMIT 1))::bigint
           ELSE NULL::bigint
           END                                                                              AS optioncancelled,
       CASE
           WHEN co.instrument_type = ANY (ARRAY ['O'::bpchar, 'E'::bpchar]) THEN
               (COALESCE((co.payload ->> 'ContractSize'::text)::integer, 1) *
                CASE co.payload ->> 'Side'::text
                    WHEN '1'::text THEN 1
                    ELSE '-1'::integer
                    END)::numeric *
               ((SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 *
                        ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric / 10000.0
                 FROM blaze7.order_report rep
                 WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                 ORDER BY rep.exec_id DESC
                 LIMIT 1))
           WHEN co.instrument_type = 'M'::bpchar
               THEN (SELECT sum((COALESCE(leg.payload ->> 'ContractSize'::text, '1'::text)::integer *
                                 CASE
                                     WHEN (leg.payload ->> 'LegSide'::text) = '1'::text THEN 1
                                     ELSE '-1'::integer
                                     END)::numeric * ((SELECT COALESCE(0.00000001 *
                                                                       ((rep.payload ->> 'CumQty'::text)::bigint)::numeric *
                                                                       ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric,
                                                                       0::numeric) AS "coalesce"
                                                       FROM blaze7.order_report rep
                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                         AND rep.leg_ref_id::text = leg.leg_ref_id::text
                                                       ORDER BY rep.exec_id DESC
                                                       LIMIT 1))) AS sum
                     FROM blaze7.client_order_leg leg
                     WHERE leg.order_id = co.order_id
                       AND leg.chain_id = co.chain_id)
           ELSE NULL::numeric
           END                                                                              AS invested,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'AccountAlias'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,AccountAlias}'::text[]
           ELSE NULL::text
           END                                                                              AS accountalias,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,Account}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,Account}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,Account}'::text[]
           ELSE NULL::text
           END                                                                              AS account,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct1}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct1}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct1}'::text[]
           ELSE NULL::text
           END                                                                              AS subaccount,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct2}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct2}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct2}'::text[]
           ELSE NULL::text
           END                                                                              AS subaccount2,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct3}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct3}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct3}'::text[]
           ELSE NULL::text
           END                                                                              AS subaccount3,
       co.payload ->> 'OrderTextComment'::text                                              AS comment,
       NULL::text                                                                           AS brokercomment,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,OptionRange}'::text[]
           WHEN co.crossing_side = 'O'::bpchar
               THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'::text[]
           ELSE NULL::text
           END                                                                              AS forwhom,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,GiveUp}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'::text[]
           ELSE NULL::text
           END                                                                              AS giveupfirm,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'::text[]
           ELSE NULL::text
           END                                                                              AS cmtafirm,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,MPID}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,MPID}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,MPID}'::text[]
           ELSE NULL::text
           END                                                                              AS mpid,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,LocateId}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,LocateId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,LocateId}'::text[]
           ELSE NULL::text
           END                                                                              AS sstkclid,
       NULL::text                                                                           AS iscapstrategy,
       NULL::text                                                                           AS iscrosslate,
       NULL::text                                                                           AS isfbsamexoverrideprice,
       NULL::text                                                                           AS isfbsamexratiospread,
       CASE co.payload ->> 'CrossingMechanism'::text
           WHEN 'Q'::text THEN '1'::text
           ELSE '0'::text
           END                                                                              AS isqcc,
       CASE
           WHEN COALESCE(co.payload ->> 'LinkedStageOrderId'::text,
                         co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[],
                         co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[]) IS NOT NULL THEN '1'::text
           ELSE NULL::text
           END                                                                              AS islinked,
       NULL::text                                                                           AS istargetedresplsmm,
       NULL::text                                                                           AS istargetedresponse,
       CASE
           WHEN co.cross_order_id IS NULL THEN '0'::text
           ELSE '1'::text
           END                                                                              AS isauctionorder,
       NULL::text                                                                           AS iseyedirect,
       NULL::text                                                                           AS ishidden,
       NULL::text                                                                           AS isior,
       CASE
           WHEN
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{IsSolicited}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,IsSolicited}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,IsSolicited}'::text[]
                   ELSE NULL::text
                   END = 'Y'::text THEN '1'::text
           ELSE '0'::text
           END                                                                              AS issolicited,
       NULL::text                                                                           AS isservercast,
       NULL::text                                                                           AS iscoveredcode,
       CASE
           WHEN (co.payload ->> 'ExecInst'::text) = 'G'::text THEN '1'::text
           ELSE '0'::text
           END                                                                              AS isallornone,
       NULL::text                                                                           AS isdeltahedge,
       CASE
           WHEN
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{NotHeld}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,NotHeld}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,NotHeld}'::text[]
                   ELSE NULL::text
                   END = 'Y'::text THEN '1'::text
           ELSE '0'::text
           END                                                                              AS isnotheld,
       CASE
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN '1'::text
           ELSE '0'::text
           END                                                                              AS istiedtostock,
       NULL::text                                                                           AS istrytostop,
       NULL::text                                                                           AS delta,
       NULL::text                                                                           AS billingentity,
       co.payload ->> 'OrderType'::text                                                     AS pricequalifier,
       co.payload ->> 'TimeInForce'::text                                                   AS timeinforcecode,
       co.payload ->> 'CboePARDestination'::text                                            AS boothidoverride,
       NULL::text                                                                           AS isignorepreference,
       ((SELECT co2.cl_ord_id
         FROM blaze7.client_order co2
         WHERE co2.order_id = COALESCE(co.payload ->> 'LinkedStageOrderId'::text,
                                       co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[],
                                       co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[])::bigint
           AND co2.chain_id = 0))::text                                                     AS linkorderid,
       NULL::text                                                                           AS ltargetresponseid,
       NULL::text                                                                           AS satpid,
       NULL::text                                                                           AS scrossbadgeids,
       (SELECT COALESCE(rep.payload ->> 'ExternalReasonCode'::text,
                        rep.payload ->> 'InternalReasonCode'::text) AS "coalesce"
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS reasoncode,
       NULL::text                                                                           AS parentorderidint,
       NULL::text                                                                           AS cancelorderidint,
       NULL::text                                                                           AS contraorderidint,
       NULL::text                                                                           AS origorderidint,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Generation}'::text[]
           ELSE NULL::text
           END                                                                              AS generation,
       (SELECT rep.payload ->> 'NoChildren'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS childorders,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SocGenCapacity}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,ClearingDetails,SocGenCapacity}'::text[]
           WHEN co.crossing_side = 'C'::bpchar
               THEN co.payload #>> '{ContraOrder,ClearingDetails,SocGenCapacity}'::text[]
           ELSE NULL::text
           END                                                                              AS capacity,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SocGenPortfolio}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,ClearingDetails,SocGenPortfolio}'::text[]
           WHEN co.crossing_side = 'C'::bpchar
               THEN co.payload #>> '{ContraOrder,ClearingDetails,SocGenPortfolio}'::text[]
           ELSE NULL::text
           END                                                                              AS portfolio,
       co.payload ->> 'ClassicRouteDestinationCode'::text                                   AS exdestination,
       CASE
           WHEN co.orig_order_id IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                   FROM blaze7.order_report rep
                                                   WHERE rep.cl_ord_id::text = (((SELECT co2.cl_ord_id
                                                                                  FROM blaze7.client_order co2
                                                                                  WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                                                                  ORDER BY co2.chain_id DESC
                                                                                  LIMIT 1))::text)
                                                   ORDER BY rep.exec_id DESC
                                                   LIMIT 1)
           ELSE NULL::text
           END                                                                              AS prevfillquantity,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN NULL::text
           WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'CumQty'::text
                                                       FROM blaze7.order_report rep
                                                       WHERE rep.cl_ord_id::text = (((SELECT co2.cl_ord_id
                                                                                      FROM blaze7.client_order co2
                                                                                      WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                                                                      ORDER BY co2.chain_id DESC
                                                                                      LIMIT 1))::text)
                                                       ORDER BY rep.exec_id DESC
                                                       LIMIT 1)
           WHEN (co.payload ->> 'SpreadType'::text) = '0'::text THEN NULL::text
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text AND co.orig_order_id IS NOT NULL
               THEN (SELECT rep.payload ->> 'CumQty'::text
                     FROM blaze7.order_report rep
                     WHERE rep.cl_ord_id::text = (((SELECT co2.cl_ord_id
                                                    FROM blaze7.client_order co2
                                                    WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                                    ORDER BY co2.chain_id DESC
                                                    LIMIT 1))::text)
                       AND rep.leg_ref_id::text = (((SELECT leg2.leg_ref_id
                                                     FROM blaze7.client_order_leg leg2
                                                     WHERE leg2.order_id = co.order_id
                                                       AND (leg2.payload ->> 'LegInstrumentType'::text) = 'E'::text
                                                     LIMIT 1))::text)
                     ORDER BY rep.exec_id DESC
                     LIMIT 1)
           ELSE NULL::text
           END                                                                              AS stockprevfillquantity,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN NULL::bigint
           WHEN co.instrument_type = 'O'::bpchar THEN ((SELECT rep.payload ->> 'CumQty'::text
                                                        FROM blaze7.order_report rep
                                                        WHERE rep.cl_ord_id::text = (((SELECT co2.cl_ord_id
                                                                                       FROM blaze7.client_order co2
                                                                                       WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                                                                       ORDER BY co2.chain_id DESC
                                                                                       LIMIT 1))::text)
                                                        ORDER BY rep.exec_id DESC
                                                        LIMIT 1))::bigint
           WHEN co.instrument_type = 'M'::bpchar AND co.orig_order_id IS NOT NULL THEN (SELECT sum(a1.cumqty) AS sum
                                                                                        FROM (SELECT (rep.payload ->> 'CumQty'::text)::integer                    AS cumqty,
                                                                                                     row_number()
                                                                                                     OVER (PARTITION BY rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                                                                              FROM blaze7.order_report rep
                                                                                              WHERE
                                                                                                  rep.cl_ord_id::text =
                                                                                                  (((SELECT co2.cl_ord_id
                                                                                                     FROM blaze7.client_order co2
                                                                                                     WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                                                                                     ORDER BY co2.chain_id DESC
                                                                                                     LIMIT 1))::text)
                                                                                                AND (
                                                                                                  rep.leg_ref_id::text IN
                                                                                                  (SELECT leg2.leg_ref_id
                                                                                                   FROM blaze7.client_order_leg leg2
                                                                                                   WHERE leg2.order_id = co.order_id
                                                                                                     AND (leg2.payload ->> 'LegInstrumentType'::text) = 'O'::text))) a1
                                                                                        WHERE a1.rn = 1)
           ELSE NULL::bigint
           END                                                                              AS optionprevfillquantity,
       (SELECT co2.order_trade_date
        FROM blaze7.client_order co2
        WHERE co2.cl_ord_id::text = co.cl_ord_id::text
          AND co2.chain_id = 0)                                                             AS tradedate,
       co.order_id                                                                          AS _order_id,
       co.chain_id                                                                          AS _chain_id,
       co.db_create_time                                                                    AS _db_create_time,
       orig.db_create_time                                                                  AS orig_db_create_time,
       rep_last_exec.db_create_time                                                         AS rep_db_create_time,
       co.order_trade_date                                                                  AS order_trade_date_id
FROM blaze7.client_order co
         JOIN LATERAL ( SELECT cl.order_id,
                               cl.chain_id
                        FROM blaze7.client_order cl
                        WHERE cl.cl_ord_id::text = co.cl_ord_id::text
                        ORDER BY cl.chain_id DESC
                        LIMIT 1) ch ON ch.order_id = co.order_id AND ch.chain_id = co.chain_id
         LEFT JOIN LATERAL ( SELECT orig_1.cl_ord_id,
                                    orig_1.db_create_time
                             FROM blaze7.client_order orig_1
                             WHERE orig_1.cl_ord_id::text = co.orig_cl_ord_id::text
                             ORDER BY orig_1.chain_id DESC
                             LIMIT 1) orig ON true
         LEFT JOIN LATERAL ( SELECT rep.payload ->> 'NoChildren'::text         AS "NoChildren",
                                    rep.payload ->> 'ExternalReasonCode'::text AS "ExternalReasonCode",
                                    rep.payload ->> 'InternalReasonCode'::text AS "InternalReasonCode",
                                    rep.payload ->> 'CumQty'::text             AS "CumQty",
                                    rep.payload ->> 'AvgPx'::text              AS "AvgPx",
                                    rep.payload ->> 'CanceledQty'::text        AS "CanceledQty",
                                    rep.payload ->> 'LeavesQty'::text          AS "LeavesQty",
                                    rep.payload ->> 'TransactTime'::text       AS "TransactTime",
                                    rep.db_create_time
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last_exec ON true
WHERE co.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]);
-- blaze7.treports_edw source
CREATE OR REPLACE VIEW blaze7.treports_edw
AS
SELECT NULL::text                                                                             AS id,
       CASE
           WHEN x.exec_type = ANY (ARRAY ['e'::bpchar, 'd'::bpchar]) THEN (SELECT CASE
                                                                                      WHEN
                                                                                          rp.exec_type = '4'::bpchar AND
                                                                                          (rp.payload ->> 'OriginatedBy'::text) =
                                                                                          'E'::text THEN 'F'::bpchar
                                                                                      ELSE rp.exec_type
                                                                                      END AS exec_type
                                                                           FROM blaze7.order_report rp
                                                                           WHERE rp.exec_id::text = (x.rep_payload ->> 'ChildExecRefId'::text))
           WHEN x.exec_type = '4'::bpchar AND (x.rep_payload ->> 'OriginatedBy'::text) = 'E'::text THEN 'F'::bpchar
           ELSE x.exec_type
           END                                                                                AS status,
       x.exec_id                                                                              AS reportid,
       x.cl_ord_id                                                                            AS orderid,
       CASE
           WHEN x.parent_order_id IS NOT NULL THEN (SELECT client_order.cl_ord_id
                                                    FROM blaze7.client_order
                                                    WHERE client_order.order_id = x.parent_order_id
                                                    LIMIT 1)
           ELSE NULL::character varying
           END                                                                                AS parentid,
       NULL::text                                                                             AS orderrecreationid,
       NULL::text                                                                             AS rawreportid,
       CASE
           WHEN (x.rep_payload ->> 'ChildExecRefId'::text) IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                                             FROM blaze7.client_order co2
                                                                             WHERE ((co2.order_id, co2.chain_id) =
                                                                                    (SELECT rep2.order_id,
                                                                                            rep2.chain_id
                                                                                     FROM blaze7.order_report rep2
                                                                                     WHERE rep2.exec_id::text = (x.rep_payload ->> 'ChildExecRefId'::text))))
           ELSE NULL::character varying
           END                                                                                AS childorderid,
       COALESCE(x.rep_payload ->> 'ChildExecRefId'::text, x.exec_id::text)                    AS childreportid,
       NULL::text                                                                             AS gatewaydatetime,
       NULL::text                                                                             AS orsdatetime,
       NULL::text                                                                             AS marketdatetime,
       CASE
           WHEN x.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegSeqNumber'::text
                                               FROM blaze7.client_order_leg leg
                                               WHERE leg.order_id = x.order_id
                                                 AND leg.chain_id = x.chain_id
                                                 AND leg.leg_ref_id::text = x.leg_ref_id::text)
           ELSE '1'::text
           END                                                                                AS legnumber,
       x.rep_payload ->> 'BustExecRefId'::text                                                AS tradecancelledreportid,
       x.rep_payload ->> 'TransactTime'::text                                                 AS transactiondatetime,
       x.rep_payload ->> 'TransactQty'::text                                                  AS lastshares,
       CASE
           WHEN x.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar, 'r'::bpchar]) THEN COALESCE(
                   ((x.rep_payload ->> 'LastPx2'::text)::bigint)::numeric / 10000.0,
                   ((x.rep_payload ->> 'LastPx'::text)::bigint)::numeric / 1.0)::text
           ELSE '0'::text
           END                                                                                AS lastprice,
       x.rep_payload ->> 'LeavesQty'::text                                                    AS leavesqty,
       x.rep_payload ->> 'CumQty'::text                                                       AS cumfilledqty,
       x.rep_payload ->> 'AvgPx'::text                                                        AS aveprice,
       x.rep_payload ->> 'ReplacedQty'::text                                                  AS quantityreplaced,
       NULL::text                                                                             AS handling,
       NULL::text                                                                             AS orderstatuslevel,
       NULL::text                                                                             AS systemorderstatus,
       NULL::text                                                                             AS waitingcancelqty,
       "left"(x.rep_payload ->> 'Text'::text, 127)                                            AS comment,
       CASE
           WHEN x.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar, 'r'::bpchar]) THEN x.rep_payload ->> 'LastMkt'::text
           ELSE NULL::text
           END                                                                                AS exdestination,
       NULL::text                                                                             AS excode,
       x.rep_payload ->> 'RouterExecId'::text                                                 AS exchangetransactionid,
       x.rep_payload ->> 'RouterOrderId'::text                                                AS exchangeorderid,
       NULL::text                                                                             AS executingfirm,
       x.rep_payload ->> 'ManualBroker'::text                                                 AS executingbroker,
       NULL::text                                                                             AS contrafirm,
       COALESCE(x.payload ->> 'OwnerUserName'::text, x.payload ->> 'InitiatorUserName'::text) AS contrabroker,
       NULL::text                                                                             AS sequence,
       NULL::text                                                                             AS timestampdelta,
       x.exec_id                                                                              AS transaction64reportid,
       x.order_id                                                                             AS order64id,
       NULL::text                                                                             AS rawreport64id,
       x.rep_payload ->> 'BustExecRefId'::text                                                AS tradecancelledreport64id,
       CASE
           WHEN x.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]) THEN x.rep_payload ->> 'TradeLiquidityIndicator'::text
           ELSE NULL::text
           END                                                                                AS liquidityindicator,
       NULL::text                                                                             AS reportstateid,
       CASE
           WHEN x.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegInstrumentType'::text
                                               FROM blaze7.client_order_leg leg
                                               WHERE leg.order_id = x.order_id
                                                 AND leg.chain_id = x.chain_id
                                                 AND leg.leg_ref_id::text = x.leg_ref_id::text)
           ELSE x.payload ->> 'InstrumentType'::text
           END                                                                                AS securitytype,
       CASE
           WHEN x.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegSide'::text
                                               FROM blaze7.client_order_leg leg
                                               WHERE leg.order_id = x.order_id
                                                 AND leg.chain_id = x.chain_id
                                                 AND leg.leg_ref_id::text = x.leg_ref_id::text)
           WHEN x.crossing_side IS NULL THEN x.payload ->> 'Side'::text
           WHEN x.crossing_side = 'O'::bpchar THEN x.payload #>> '{OriginatorOrder,Side}'::text[]
           WHEN x.crossing_side = 'C'::bpchar THEN x.payload #>> '{ContraOrder,Side}'::text[]
           ELSE NULL::text
           END                                                                                AS side,
       CASE
           WHEN "substring"(x.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = 'EQ'::text THEN 'S'::text
           WHEN "substring"(x.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text])
               THEN "substring"(x.dashsecurityid, '[0-9]{6}(.)'::text)
           ELSE NULL::text
           END                                                                                AS putorcall,
       CASE
           WHEN x.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'Symbol'::text
                                               FROM blaze7.client_order_leg leg
                                               WHERE leg.order_id = x.order_id
                                                 AND leg.chain_id = x.chain_id
                                                 AND leg.leg_ref_id::text = x.leg_ref_id::text)
           ELSE x.payload ->> 'Symbol'::text
           END                                                                                AS underlying,
       COALESCE("substring"(x.dashsecurityid, 'US:EQ:(.+)'::text),
                "substring"(x.dashsecurityid, 'US:[FO|OP]{2}:(.+)_'::text))                   AS rootcode,
       NULL::text                                                                             AS feedcode,
       x.dashsecurityid                                                                       AS securityid,
       CASE
           WHEN "substring"(x.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text])
               THEN to_date("substring"(x.dashsecurityid, '([0-9]{6})'::text), 'YYMMDD'::text)
           ELSE NULL::date
           END                                                                                AS maturitydate,
       CASE
           WHEN "substring"(x.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text])
               THEN "substring"(x.dashsecurityid, '[0-9]{6}.(.+)$'::text)::numeric
           ELSE NULL::numeric
           END                                                                                AS strikeprice,
       CASE
           WHEN x.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegRatioQty'::text
                                               FROM blaze7.client_order_leg leg
                                               WHERE leg.order_id = x.order_id
                                                 AND leg.chain_id = x.chain_id
                                                 AND leg.leg_ref_id::text = x.leg_ref_id::text)
           ELSE '1'::text
           END                                                                                AS ratio,
       CASE
           WHEN x.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'ContractSize'::text
                                               FROM blaze7.client_order_leg leg
                                               WHERE leg.order_id = x.order_id
                                                 AND leg.chain_id = x.chain_id
                                                 AND leg.leg_ref_id::text = x.leg_ref_id::text)
           ELSE COALESCE(x.payload ->> 'ContractSize'::text, '1'::text)
           END                                                                                AS multiplier,
       CASE
           WHEN x.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'PositionEffect'::text
                                               FROM blaze7.client_order_leg leg
                                               WHERE leg.order_id = x.order_id
                                                 AND leg.chain_id = x.chain_id
                                                 AND leg.leg_ref_id::text = x.leg_ref_id::text)
           WHEN x.crossing_side IS NULL THEN x.payload ->> 'PositionEffect'::text
           WHEN x.crossing_side = 'O'::bpchar THEN x.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
           WHEN x.crossing_side = 'C'::bpchar THEN x.payload #>> '{ContraOrder,PositionEffect}'::text[]
           ELSE NULL::text
           END                                                                                AS positioneffect,
       NULL::text                                                                             AS covereduncovered,
       COALESCE(
               CASE
                   WHEN x.leg_ref_id IS NULL THEN x.payload ->> 'Price'::text
                   ELSE COALESCE((SELECT leg.payload ->> 'LegPrice'::text
                                  FROM blaze7.client_order_leg leg
                                  WHERE leg.order_id = x.order_id
                                    AND leg.chain_id = x.chain_id
                                    AND leg.leg_ref_id::text = x.leg_ref_id::text),
                                 CASE
                                     WHEN x.leg_ref_id IS NOT NULL AND x.crossing_side IS NULL
                                         THEN x.payload ->> 'Price'::text
                                     WHEN x.leg_ref_id IS NOT NULL AND x.crossing_side = 'O'::bpchar
                                         THEN x.payload #>> '{OriginatorOrder,Price}'::text[]
                                     WHEN x.leg_ref_id IS NOT NULL AND x.crossing_side = 'C'::bpchar
                                         THEN x.payload #>> '{ContraOrder,Price}'::text[]
                                     ELSE NULL::text
                                     END)
                   END, '0'::text)                                                            AS price,
       NULL::text                                                                             AS refid,
       NULL::text                                                                             AS transaction64legid,
       NULL::text                                                                             AS prevtransactionid,
       NULL::text                                                                             AS systemid,
       NULL::text                                                                             AS orderidint,
       NULL::text                                                                             AS parentorderidint,
       CASE
           WHEN x.crossing_side IS NULL THEN x.payload ->> 'Generation'::text
           WHEN x.crossing_side = 'O'::bpchar THEN x.payload #>> '{OriginatorOrder,Generation}'::text[]
           WHEN x.crossing_side = 'C'::bpchar THEN x.payload #>> '{ContraOrder,Generation}'::text[]
           ELSE NULL::text
           END                                                                                AS generation,
       case
           when x.order_class = 'F' then x.payload ->> 'InitiatorUserId'
           when x.crossing_side is null then x.payload ->> 'ClientUserId'
           when x.crossing_side = 'O' then x.payload #>> '{OriginatorOrder,ClientUserId}'
           when x.crossing_side = 'C' then x.payload #>> '{ContraOrder,ClientUserId}'
           --             WHEN x.crossing_side IS NULL THEN COALESCE(x.payload ->> '{ClearingDetails,CustomerUserId}'::text, x.payload ->> 'InitiatorUserId'::text)
--             WHEN x.crossing_side = 'O'::bpchar THEN COALESCE(x.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[], x.payload ->> 'InitiatorUserId'::text)
--             WHEN x.crossing_side = 'C'::bpchar THEN COALESCE(x.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[], x.payload ->> 'InitiatorUserId'::text)
--             ELSE NULL::text
           end                                                                                as userid,
       COALESCE(x.rep_payload ->> 'NoChildren'::text, '0'::text)                              AS childorders,
       (x.rep_payload ->> 'ManualBrokerCommission'::text)::bigint                             AS brokercommission,
       x.rep_payload ->> 'LinkedExecRefId'::text                                              AS linkedreportid,
       NULL::text                                                                             AS counterclientcategory,
       NULL::text                                                                             AS countercmta,
       NULL::text                                                                             AS sidetradeid,
       NULL::text                                                                             AS exchangemappedorderid,
       x.rep_payload ->> 'SentToBroker'::text                                                 AS senttobroker,
       x.rep_payload ->> 'ManualReceiveTime'::text                                            AS transmitdatetime,
       x.parent_order_id                                                                      AS intparentorderid,
       x.rep_payload ->> 'ManualExecutionTime'::text                                          AS manualexecutiontime,
       x.rep_payload ->> 'LiquidityType'::text                                                AS liquiditytype,
       CASE
           WHEN (x.rep_payload ->> 'OrderReportSpecialType'::text) = 'M'::text THEN 'M'::text
           ELSE NULL::text
           END                                                                                AS orderreportspecialtype,
       x.rep_payload ->> 'NyseTOApproveTime'::text                                            AS nysetoapprovetime,
       x.rep_payload ->> 'NyseTOExecutionTime'::text                                          AS nysetoexecutiontime,
       x.order_trade_date                                                                     AS tradedate,
       x.rep_payload ->> 'ManualCallTime'::text                                               AS calltime,
       COALESCE((x.rep_payload ->> 'ManualClientCommission'::text)::bigint,
                CASE
                    WHEN x.crossing_side IS NULL THEN (x.payload #>> '{ClearingDetails,Commission2}'::text[])::bigint
                    WHEN x.crossing_side = 'O'::bpchar
                        THEN (x.payload #>> '{OriginatorOrder,ClearingDetails,Commission2}'::text[])::bigint
                    WHEN x.crossing_side = 'C'::bpchar
                        THEN (x.payload #>> '{ContraOrder,ClearingDetails,Commission2}'::text[])::bigint
                    ELSE NULL::bigint
                    END)                                                                      AS clientcommission,
       x.rep_payload ->> 'BustReason'::text                                                   AS bustreason,
       x.order_id                                                                             AS _order_id,
       x.chain_id                                                                             AS _chain_id,
       x.db_create_time                                                                       AS _db_create_time
FROM (SELECT rep.exec_id,
             rep.order_id,
             rep.chain_id,
             rep.leg_ref_id,
             regexp_replace(rep.payload::text, '\\u0000'::text, ''::text, 'g'::text)::json AS rep_payload,
             rep.db_create_time,
             rep.exec_type,
             co.parent_order_id,
             co.crossing_side,
             co.order_class,
             regexp_replace(co.payload::text, '\\u0000'::text, ''::text, 'g'::text)::json  AS payload,
             co.cl_ord_id,
             CASE
                 WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'DashSecurityId'::text
                                                       FROM blaze7.client_order_leg leg
                                                       WHERE leg.order_id = co.order_id
                                                         AND leg.chain_id = co.chain_id
                                                         AND leg.leg_ref_id::text = rep.leg_ref_id::text)
                 ELSE regexp_replace(co.payload::text, '\\u0000'::text, ''::text, 'g'::text)::json ->> 'DashSecurityId'::text
                 END                                                                       AS dashsecurityid,
             co.order_trade_date
      FROM blaze7.order_report rep
               JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
      WHERE rep.multileg_reporting_type <> '3'::bpchar
        AND (co.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
        AND (rep.exec_type::text <> ALL
             (ARRAY ['f'::text, 'w'::text, 'W'::text, 'g'::text, 'G'::text, 'I'::text, 'i'::text]))) x;