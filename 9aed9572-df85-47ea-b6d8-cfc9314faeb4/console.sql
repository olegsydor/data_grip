select
_db_create_time, _db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central' as _db_create_time,
* from blaze7.tprices_edw
where "_order_id" = 535802370555133952;


select
_db_create_time as "UTC",
_db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central' as _db_create_time,
_db_create_time at time zone 'US/Central' as _db_create_time
from blaze7.tprices_edw
where _db_create_time::date = '2023-07-18'
    and "_order_id" = 535822291003523072;


select to_char(boxqooannouncedtime, 'YYYY-MM-DD HH24:MI:SS.US'), *
from blaze7.tordermisc1_edw
where "_db_create_time"::date = '2023-07-18'
and "_order_id" = 535793635686367234;


select mx.*, *
FROM blaze7.tlegs_edw as x
left join lateral(SELECT rep.db_create_time as max_rep_time FROM blaze7.order_report rep WHERE rep.order_id = x._order_id AND rep.chain_id = x._chain_id order by rep.db_create_time desc limit 1) mx on true
where to_char(x._db_create_time, 'YYYYMMDD')::int = '20230718'::int
AND x._db_create_time >  '2023-07-18 06:15:15.237'::timestamp at time zone 'US/Central' at time zone 'UTC' - interval '10 minute'
and mx.max_rep_time >  '2023-07-18 06:15:15.237'::timestamp at time zone 'US/Central' at time zone 'UTC' - interval '10 minute';

select *
FROM blaze7.tlegs_edw as x
         left join lateral (SELECT rep.db_create_time as max_rep_time
                            FROM blaze7.order_report rep
                            WHERE rep.order_id = x._order_id
                              AND rep.chain_id = x._chain_id
                            order by rep.db_create_time desc
                            limit 1) mx on true
where to_char(x._db_create_time, 'YYYYMMDD')::int = '"+context.p_date_id+"'::int
  AND x._db_create_time > '"+context.max_processed_time_leg+"'::timestamp at time zone 'US/Central' at time zone
                          'UTC' - interval '10 minute'
  and mx.max_rep_time > '"+context.max_processed_time_leg+"'::timestamp at time zone 'US/Central' at time zone
                        'UTC' - interval '10 minute';


select *
FROM blaze7.torder_edw2 as x
where x._db_create_time >= '2023-07-18 00:00'::timestamptz
and x._db_create_time < '20230718'::date + interval '1 day'
AND x._last_mod_time::timestamp >  select '2023-07-18 06:15:15.237'::timestamp at time zone 'US/Central' at time zone 'UTC' - interval '10 minute'

except

select *
FROM blaze7.torder_edw as x
where x._db_create_time >= '20230718'::date
and x._db_create_time < '''20230718'::date + interval '1 day'
AND x._last_mod_time::timestamp >  '2023-07-18 06:15:15.237'::timestamp at time zone 'US/Central' at time zone 'UTC' - interval '10 minute';





-----------------------------
create view blaze7.torder_edw2
as
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
       (SELECT rep.payload ->> 'TransactTime'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          AND ((rep.payload ->> 'OrderStatus'::text) = ANY
               (ARRAY ['2'::text, '3'::text, '4'::text, '8'::text, 'P'::text, 'l'::text, '5'::text]))
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                            AS completeddatetime,
       NULL::text                                                                           AS writedatetime,
       CASE
           WHEN co.crossing_side = 'O'::bpchar THEN COALESCE(
                       co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[],
                       co.payload ->> 'InitiatorUserId'::text)
           WHEN co.crossing_side = 'C'::bpchar THEN COALESCE(
                       co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[],
                       co.payload ->> 'InitiatorUserId'::text)
           WHEN co.crossing_side IS NULL THEN COALESCE(co.payload #>> '{ClearingDetails,CustomerUserId}'::text[],
                                                       co.payload ->> 'InitiatorUserId'::text)
           ELSE NULL::text
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
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClientEntityId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClientEntityId}'::text[]
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientEntityId'::text
           ELSE NULL::text
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
                        END)::numeric * ((SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 *
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
                                                       WHERE rep.leg_ref_id::text = leg.leg_ref_id::text
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
                                                                                              WHERE rep.cl_ord_id::text =
                                                                                                    (((SELECT co2.cl_ord_id
                                                                                                       FROM blaze7.client_order co2
                                                                                                       WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                                                                                       ORDER BY co2.chain_id DESC
                                                                                                       LIMIT 1))::text)
                                                                                                AND (rep.leg_ref_id::text IN
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
       staging.get_max_db_create_time(co.order_id, co.db_create_time::date, co.chain_id)    AS _last_mod_time
into staging.so_tmp
FROM (SELECT cl.order_id,
             cl.chain_id,
             cl.parent_order_id,
             cl.orig_order_id,
             cl.record_type,
             cl.payload,
             cl.db_create_time,
             cl.cross_order_id,
             cl.cl_ord_id,
             cl.orig_cl_ord_id,
             cl.crossing_side,
             cl.instrument_type,
             cl.order_class,
             cl.route_type,
             cl.route_destination,
             cl.order_trade_date,
             row_number() over (partition by cl.cl_ord_id order by cl.chain_id desc) as rn
      FROM blaze7.client_order cl
      WHERE cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar])
      and cl.db_create_time > to_timestamp(:in_date_id::text, 'YYYYMMDD')
      and cl.db_create_time > to_timestamp(:in_date_id::text, 'YYYYMMDD') + interval '1 day'
) co
where rn = 1
limit 1;
---------------

select * from blaze7.torder_edw(20230718)
create or replace function blaze7.torder_edw(in_start_date_id int4 default null,
                                  in_end_date_id int4 default null,
                                  in_last_mod_time timestamp default null)
    returns table
            (
                id                     text,
                systemid               text,
                systemorderid          varchar(100),
                systemordertypeid      bpchar,
                orderid                varchar(100),
                parentorderid          varchar,
                cancelorderid          varchar(100),
                contraorderid          varchar(100),
                origorderid            varchar(100),
                replaceorderid         varchar(100),
                status                 text,
                createdatetime         text,
                approveddatetime       text,
                dtclearbookdatetime    text,
                firstfilldatetime      text,
                lastfilldatetime       text,
                updatedatetime         text,
                completeddatetime      text,
                writedatetime          text,
                userid                 text,
                ownerid                text,
                previousownerid        text,
                sendinguserid          text,
                executingbroker        text,
                companyid              text,
                destinationcompanyid   text,
                introducingcompanyid   text,
                parentcompanyid        text,
                exchangeconnectionid   bpchar,
                exchangeinfoid         text,
                exchangecomment        text,
                contractdesc           text,
                strategytype           text,
                assetclass             text,
                legcount               text,
                price                  text,
                quantity               text,
                filled                 text,
                avgprice               text,
                stockquantity          text,
                stockopenquantity      text,
                stockfilled            text,
                stockcancelled         text,
                optionquantity         int8,
                optionopenquantity     int8,
                optionfilled           int8,
                optioncancelled        int8,
                invested               numeric,
                accountalias           text,
                account                text,
                subaccount             text,
                subaccount2            text,
                subaccount3            text,
                "comment"              text,
                brokercomment          text,
                forwhom                text,
                giveupfirm             text,
                cmtafirm               text,
                mpid                   text,
                sstkclid               text,
                iscapstrategy          text,
                iscrosslate            text,
                isfbsamexoverrideprice text,
                isfbsamexratiospread   text,
                isqcc                  text,
                islinked               text,
                istargetedresplsmm     text,
                istargetedresponse     text,
                isauctionorder         text,
                iseyedirect            text,
                ishidden               text,
                isior                  text,
                issolicited            text,
                isservercast           text,
                iscoveredcode          text,
                isallornone            text,
                isdeltahedge           text,
                isnotheld              text,
                istiedtostock          text,
                istrytostop            text,
                delta                  text,
                billingentity          text,
                pricequalifier         text,
                timeinforcecode        text,
                boothidoverride        text,
                isignorepreference     text,
                linkorderid            text,
                ltargetresponseid      text,
                satpid                 text,
                scrossbadgeids         text,
                reasoncode             text,
                parentorderidint       text,
                cancelorderidint       text,
                contraorderidint       text,
                origorderidint         text,
                generation             text,
                childorders            text,
                capacity               text,
                portfolio              text,
                exdestination          text,
                prevfillquantity       text,
                stockprevfillquantity  text,
                optionprevfillquantity int8,
                tradedate              int8,
                "_order_id"            int8,
                "_chain_id"            int4,
                "_db_create_time"      timestamptz,
                "_last_mod_time"       timestamptz
            )
    language plpgsql
as
$fx$
declare
    l_date_begin    timestamp;
    l_date_end      timestamp;
    l_last_mod_time timestamp;

begin
    l_date_begin := coalesce(in_start_date_id, 19900101)::text::timestamp;
    l_date_end := coalesce(in_end_date_id::text::timestamp, l_date_begin + interval '1 day');
    l_last_mod_time := coalesce(in_last_mod_time, l_date_begin);
raise notice '%, %, %', l_date_begin, l_date_end, l_last_mod_time;
    return query
        SELECT NULL::text                                                                           AS id,
               NULL::text                                                                           AS systemid,
               co.cl_ord_id                                                                         AS systemorderid,
               CASE
                   WHEN co.route_destination::text = 'VEGA'::text THEN 'VEGA'::bpchar
                   WHEN (co.payload ->> 'HasStitchedOrders'::text) = 'Y'::text THEN 'StitchedSingle'::bpchar
                   WHEN COALESCE(co.payload ->> 'IsStitched'::text,
                                 co.payload #>> '{OriginatorOrder,IsStitched}'::text[]) = 'Y'::text
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
               (SELECT rep.payload ->> 'TransactTime'::text
                FROM blaze7.order_report rep
                WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                  AND ((rep.payload ->> 'OrderStatus'::text) = ANY
                       (ARRAY ['2'::text, '3'::text, '4'::text, '8'::text, 'P'::text, 'l'::text, '5'::text]))
                ORDER BY rep.exec_id DESC
                LIMIT 1)                                                                            AS completeddatetime,
               NULL::text                                                                           AS writedatetime,
               CASE
                   WHEN co.crossing_side = 'O'::bpchar THEN COALESCE(
                               co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[],
                               co.payload ->> 'InitiatorUserId'::text)
                   WHEN co.crossing_side = 'C'::bpchar THEN COALESCE(
                               co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[],
                               co.payload ->> 'InitiatorUserId'::text)
                   WHEN co.crossing_side IS NULL THEN COALESCE(
                               co.payload #>> '{ClearingDetails,CustomerUserId}'::text[],
                               co.payload ->> 'InitiatorUserId'::text)
                   ELSE NULL::text
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
                   WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClientEntityId}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClientEntityId}'::text[]
                   WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientEntityId'::text
                   ELSE NULL::text
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
                           WHEN co.crossing_side IS NULL OR co.instrument_type <> 'M'::bpchar
                               THEN co.payload ->> 'Price'::text
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
                                END)::numeric * ((SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 *
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
                                                               WHERE rep.leg_ref_id::text = leg.leg_ref_id::text
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
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,Account}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,ClearingDetails,Account}'::text[]
                   ELSE NULL::text
                   END                                                                              AS account,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct1}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct1}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct1}'::text[]
                   ELSE NULL::text
                   END                                                                              AS subaccount,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct2}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct2}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct2}'::text[]
                   ELSE NULL::text
                   END                                                                              AS subaccount2,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct3}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct3}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct3}'::text[]
                   ELSE NULL::text
                   END                                                                              AS subaccount3,
               co.payload ->> 'OrderTextComment'::text                                              AS comment,
               NULL::text                                                                           AS brokercomment,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,OptionRange}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'::text[]
                   ELSE NULL::text
                   END                                                                              AS forwhom,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,GiveUp}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'::text[]
                   ELSE NULL::text
                   END                                                                              AS giveupfirm,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'::text[]
                   ELSE NULL::text
                   END                                                                              AS cmtafirm,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,MPID}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,MPID}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,MPID}'::text[]
                   ELSE NULL::text
                   END                                                                              AS mpid,
               CASE
                   WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,LocateId}'::text[]
                   WHEN co.crossing_side = 'O'::bpchar
                       THEN co.payload #>> '{OriginatorOrder,ClearingDetails,LocateId}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar
                       THEN co.payload #>> '{ContraOrder,ClearingDetails,LocateId}'::text[]
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
                               WHEN co.crossing_side = 'O'::bpchar
                                   THEN co.payload #>> '{OriginatorOrder,IsSolicited}'::text[]
                               WHEN co.crossing_side = 'C'::bpchar
                                   THEN co.payload #>> '{ContraOrder,IsSolicited}'::text[]
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
                               WHEN co.crossing_side = 'O'::bpchar
                                   THEN co.payload #>> '{OriginatorOrder,NotHeld}'::text[]
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
                   WHEN co.instrument_type = 'M'::bpchar AND co.orig_order_id IS NOT NULL
                       THEN (SELECT sum(a1.cumqty) AS sum
                             FROM (SELECT (rep.payload ->> 'CumQty'::text)::integer                    AS cumqty,
                                          row_number()
                                          OVER (PARTITION BY rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                   FROM blaze7.order_report rep
                                   WHERE rep.cl_ord_id::text =
                                         (((SELECT co2.cl_ord_id
                                            FROM blaze7.client_order co2
                                            WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                            ORDER BY co2.chain_id DESC
                                            LIMIT 1))::text)
                                     AND (rep.leg_ref_id::text IN
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
               staging.get_max_db_create_time(co.order_id, co.db_create_time::date, co.chain_id)    AS _last_mod_time
        from (SELECT cl.order_id,
                     cl.chain_id,
                     cl.parent_order_id,
                     cl.orig_order_id,
                     cl.record_type,
                     cl.payload,
                     cl.db_create_time,
                     cl.cross_order_id,
                     cl.cl_ord_id,
                     cl.orig_cl_ord_id,
                     cl.crossing_side,
                     cl.instrument_type,
                     cl.order_class,
                     cl.route_type,
                     cl.route_destination,
                     cl.order_trade_date,
                     row_number() over (partition by cl.cl_ord_id order by cl.chain_id desc) as rn
              FROM blaze7.client_order cl
              WHERE cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar])
                and cl.db_create_time > :l_date_begin
                and cl.db_create_time < :l_date_end
                and staging.get_max_db_create_time(cl.order_id, cl.db_create_time::date, cl.chain_id) > :l_last_mod_time
              ) co
        where co.rn = 1;
end;
$fx$
2023-07-18 00:00:00, 2023-07-19 00:00:00, 2023-07-18 00:00:00