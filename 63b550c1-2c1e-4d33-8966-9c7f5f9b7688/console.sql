SELECT NULL::text AS id,
    NULL::text AS systemid,
    co.cl_ord_id AS systemorderid,
        CASE
            WHEN co.route_destination::text = 'VEGA'::text THEN 'VEGA'::bpchar
            WHEN ("HasStitchedOrders") = 'Y'::text THEN 'StitchedSingle'::bpchar
            WHEN COALESCE("IsStitched", "OriginatorOrderIsStitched") = 'Y'::text THEN 'StitchedSpread'::bpchar
            WHEN co.order_class = 'I'::bpchar THEN 'G'::bpchar
            ELSE co.order_class
        END AS systemordertypeid,
    co.cl_ord_id AS orderid,
        CASE
            WHEN co.parent_order_id IS NOT NULL THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = co.parent_order_id
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE NULL::character varying
        END AS parentorderid,
    co.orig_cl_ord_id AS cancelorderid,
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
        CASE co.crossing_side
            WHEN 'C'::bpchar THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.cross_order_id = co.cross_order_id AND co2.crossing_side = 'O'::bpchar
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = (("OriginatorOrderRefId")::bigint)
              ORDER BY co2.chain_id DESC
             LIMIT 1)
        END AS origorderid,
    ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.orig_cl_ord_id::text = co.cl_ord_id::text AND co2.record_type = '0'::bpchar
          ORDER BY co2.chain_id DESC
         LIMIT 1) AS replaceorderid,
        CASE
            WHEN COALESCE("LinkedStageOrderId", "OriginatorOrderLinkedStageOrderId", "ContraOrderLinkedStageOrderId") IS NOT NULL THEN 'T'::text
            ELSE ( SELECT rp.payload ->> 'BlazeOrderStatus'::text
               FROM blaze7.order_report rp
              WHERE rp.cl_ord_id::text = co.cl_ord_id::text AND rp.leg_ref_id IS NULL
              ORDER BY rp.exec_id DESC
             LIMIT 1)
        END AS status,
        CASE
            WHEN co.chain_id = 0 THEN "OrderCreationTime"
            ELSE ( SELECT co2.payload ->> 'OrderCreationTime'::text
               FROM blaze7.client_order co2
              WHERE co2.cl_ord_id::text = co.cl_ord_id::text AND co2.chain_id = 0)
        END AS createdatetime,
    NULL::text AS approveddatetime,
    NULL::text AS dtclearbookdatetime,
    ( SELECT rep.payload ->> 'TransactTime'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar])) AND
                CASE
                    WHEN co.instrument_type <> 'M'::bpchar THEN true
                    ELSE rep.leg_ref_id IS NOT NULL
                END
          ORDER BY rep.exec_id
         LIMIT 1) AS firstfilldatetime,
    ( SELECT rep.payload ->> 'TransactTime'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar])) AND
                CASE
                    WHEN co.instrument_type <> 'M'::bpchar THEN true
                    ELSE rep.leg_ref_id IS NOT NULL
                END
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS lastfilldatetime,
    ( SELECT rep.payload ->> 'TransactTime'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS updatedatetime,
    ( SELECT rep.payload ->> 'TransactTime'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND ((rep.payload ->> 'OrderStatus'::text) = ANY (ARRAY['2'::text, '3'::text, '4'::text, '8'::text, 'P'::text, 'l'::text, '5'::text]))
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS completeddatetime,
    NULL::text AS writedatetime,
        CASE
            WHEN co.crossing_side = 'O'::bpchar THEN COALESCE("OriginatorOrderClearingDetailsCustomerUserId", "InitiatorUserId")
            WHEN co.crossing_side = 'C'::bpchar THEN COALESCE("ContraOrderClearingDetailsCustomerUserId", "InitiatorUserId")
            WHEN co.crossing_side IS NULL THEN COALESCE("ClearingDetailsCustomerUserId", "InitiatorUserId")
            ELSE NULL::text
        END AS userid,
    COALESCE("OwnerUserId", "InitiatorUserId") AS ownerid,
    NULL::text AS previousownerid,
        CASE
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsCustomerUserId"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsCustomerUserId"
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsCustomerUserId"
            ELSE NULL::text
        END AS sendinguserid,
    NULL::text AS executingbroker,
        CASE
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClientEntityId"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClientEntityId"
            WHEN co.crossing_side IS NULL THEN "ClientEntityId"
            ELSE NULL::text
        END AS companyid,
    "DestinationEntityId" AS destinationcompanyid,
    NULL::text AS introducingcompanyid,
    NULL::text AS parentcompanyid,
    co.route_type AS exchangeconnectionid,
    NULL::text AS exchangeinfoid,
    NULL::text AS exchangecomment,
    "ProductDescription" AS contractdesc,
    NULL::text AS strategytype,
    NULL::text AS assetclass,
    COALESCE("NoLegs", '1') AS legcount,
    COALESCE(
        CASE
            WHEN co.crossing_side IS NULL OR co.instrument_type <> 'M'::bpchar THEN "Price"
            WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'O'::bpchar THEN "OriginatorOrderPrice"
            WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'C'::bpchar THEN "ContraOrderPrice"
            WHEN co.instrument_type <> 'M'::bpchar THEN "Price"
            ELSE NULL::text
        END, '0'::text) AS price,
    COALESCE("DashTargetVega", "OrderQty") AS quantity,
    ( SELECT rep.payload ->> 'CumQty'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS filled,
    ( SELECT rep.payload ->> 'AvgPx'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id IS NULL
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS avgprice,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN "OrderQty"
            WHEN "SpreadType" = '1' THEN ( SELECT leg.payload ->> 'LegQty'::text
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
             LIMIT 1)
            WHEN co.route_destination::text = 'VEGA'::text THEN (( SELECT sum((leg.payload ->> 'LegQty'::text)::integer) AS sum
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text
            ELSE NULL::text
        END AS stockquantity,
        CASE
            WHEN "SpreadType" = '1'::text THEN ( SELECT rep.payload ->> 'LeavesQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = ((( SELECT leg.leg_ref_id
                       FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'LeavesQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockopenquantity,
        CASE
            WHEN "SpreadType" = '1'::text THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = ((( SELECT leg.leg_ref_id
                       FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.route_destination::text = 'VEGA'::text THEN (( SELECT sum(x.sm) AS sum
               FROM ( SELECT (rep.payload ->> 'CumQty'::text)::integer AS sm,
                        row_number() OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.leg_ref_id::text IN ( SELECT leg.leg_ref_id
                               FROM blaze7.client_order_leg leg
                              WHERE leg.order_id = rep.order_id AND leg.chain_id = rep.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))) x
              WHERE x.rn = 1))::text
            ELSE NULL::text
        END AS stockfilled,
        CASE
            WHEN "SpreadType" = '1'::text THEN ( SELECT rep.payload ->> 'CanceledQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = ((( SELECT leg.leg_ref_id
                       FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'CanceledQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockcancelled,
        CASE co.instrument_type
            WHEN 'O'::bpchar THEN "OrderQty"::bigint
            WHEN 'M'::bpchar THEN ( SELECT sum((leg.payload ->> 'LegQty'::text)::integer) AS sum
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text)
            ELSE NULL::bigint
        END AS optionquantity,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN ( SELECT sum(x.sm) AS sum
               FROM ( SELECT (rep.payload ->> 'LeavesQty'::text)::integer AS sm,
                        row_number() OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.leg_ref_id::text IN ( SELECT leg.leg_ref_id
                               FROM blaze7.client_order_leg leg
                              WHERE leg.order_id = rep.order_id AND leg.chain_id = rep.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
              WHERE x.rn = 1)
            WHEN 'O'::bpchar THEN (( SELECT (rep.payload ->> 'LeavesQty'::text)::integer AS int4
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))::bigint
            ELSE NULL::bigint
        END AS optionopenquantity,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN ( SELECT sum(x.sm) AS sum
               FROM ( SELECT (rep.payload ->> 'CumQty'::text)::integer AS sm,
                        row_number() OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.leg_ref_id::text IN ( SELECT leg.leg_ref_id
                               FROM blaze7.client_order_leg leg
                              WHERE leg.order_id = rep.order_id AND leg.chain_id = rep.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
              WHERE x.rn = 1)
            WHEN 'O'::bpchar THEN (( SELECT (rep.payload ->> 'CumQty'::text)::integer AS int4
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))::bigint
            ELSE NULL::bigint
        END AS optionfilled,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN ( SELECT sum(x.sm) AS sum
               FROM ( SELECT (rep.payload ->> 'CanceledQty'::text)::integer AS sm,
                        row_number() OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.leg_ref_id::text IN ( SELECT leg.leg_ref_id
                               FROM blaze7.client_order_leg leg
                              WHERE leg.order_id = rep.order_id AND leg.chain_id = rep.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
              WHERE x.rn = 1)
            WHEN 'O'::bpchar THEN (( SELECT (rep.payload ->> 'CanceledQty'::text)::integer AS int4
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))::bigint
            ELSE NULL::bigint
        END AS optioncancelled,
        CASE
            WHEN co.instrument_type = ANY (ARRAY['O'::bpchar, 'E'::bpchar]) THEN (COALESCE("ContractSize"::integer, 1) *
            CASE "Side"
                WHEN '1'::text THEN 1
                ELSE '-1'::integer
            END)::numeric * (( SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 * ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric / 10000.0
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))
            WHEN co.instrument_type = 'M'::bpchar THEN ( SELECT sum((COALESCE(leg.payload ->> 'ContractSize'::text, '1'::text)::integer *
                    CASE
                        WHEN (leg.payload ->> 'LegSide'::text) = '1'::text THEN 1
                        ELSE '-1'::integer
                    END)::numeric * (( SELECT COALESCE(0.00000001 * ((rep.payload ->> 'CumQty'::text)::bigint)::numeric * ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric, 0::numeric) AS "coalesce"
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = leg.leg_ref_id::text
                      ORDER BY rep.exec_id DESC
                     LIMIT 1))) AS sum
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id)
            ELSE NULL::numeric
        END AS invested,
         CASE
            WHEN co.crossing_side IS NULL THEN "AccountAlias"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderAccountAlias"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderAccountAlias"
            ELSE NULL::text
        END AS accountalias,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsAccount"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsAccount"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsAccount"
            ELSE NULL::text
        END AS account,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsSubAcct1"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsSubAcct1"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsSubAcct1"
            ELSE NULL::text
        END AS subaccount,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsSubAcct2"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsSubAcct2"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsSubAcct2"
            ELSE NULL::text
        END AS subaccount2,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsSubAcct3"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsSubAcct3"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsSubAcct3"
            ELSE NULL::text
        END AS subaccount3,
    co.payload ->> 'OrderTextComment'::text AS comment,
    NULL::text AS brokercomment,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetails,OptionRange"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsOptionRange"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsOptionRange"
            ELSE NULL::text
        END AS forwhom,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsGiveUp"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsGiveUp"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsGiveUp"
        END AS giveupfirm,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsCMTA"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsCMTA"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsCMTA"
        END AS cmtafirm,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsMPID"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsMPID"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsMPID"
        END AS mpid,
        CASE
            WHEN co.crossing_side IS NULL THEN "ClearingDetailsLocateId"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderClearingDetailsLocateId"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderClearingDetailsLocateId"
        END AS sstkclid,
    NULL::text AS iscapstrategy,
    NULL::text AS iscrosslate,
    NULL::text AS isfbsamexoverrideprice,
    NULL::text AS isfbsamexratiospread,
        CASE "CrossingMechanism"
            WHEN 'Q'::text THEN '1'::text
            ELSE '0'::text
        END AS isqcc,
        CASE
            WHEN COALESCE("LinkedStageOrderId", "OriginatorOrderLinkedStageOrderId", "ContraOrderLinkedStageOrderId") IS NOT NULL THEN '1'::text
            ELSE NULL::text
        END AS islinked,
    NULL::text AS istargetedresplsmm,
    NULL::text AS istargetedresponse,
        CASE
            WHEN co.cross_order_id IS NULL THEN '0'::text
            ELSE '1'::text
        END AS isauctionorder,
    NULL::text AS iseyedirect,
    NULL::text AS ishidden,
    NULL::text AS isior,
        CASE
            WHEN
            CASE
                WHEN co.crossing_side IS NULL THEN "IsSolicited"
                WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderIsSolicited"
                WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderIsSolicited"
                ELSE NULL::text
            END = 'Y'::text THEN '1'::text
            ELSE '0'::text
        END AS issolicited,
    NULL::text AS isservercast,
    NULL::text AS iscoveredcode,
        CASE
            WHEN "ExecInst" = 'G'::text THEN '1'::text
            ELSE '0'::text
        END AS isallornone,
    NULL::text AS isdeltahedge,
        CASE
            WHEN
            CASE
                WHEN co.crossing_side IS NULL THEN "NotHeld"
                WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderNotHeld"
                WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderNotHeld"
            END = 'Y'::text THEN '1'::text
            ELSE '0'::text
        END AS isnotheld,
        CASE
            WHEN "SpreadType" = '1'::text THEN '1'::text
            ELSE '0'::text
        END AS istiedtostock,
    NULL::text AS istrytostop,
    NULL::text AS delta,
    NULL::text AS billingentity,
    "OrderType" AS pricequalifier,
    "TimeInForce" AS timeinforcecode,
    "CboePARDestination" AS boothidoverride,
    NULL::text AS isignorepreference,
    (( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.order_id = COALESCE("LinkedStageOrderId", "OriginatorOrderLinkedStageOrderId", "ContraOrderLinkedStageOrderId")::bigint AND co2.chain_id = 0))::text AS linkorderid,
    NULL::text AS ltargetresponseid,
    NULL::text AS satpid,
    NULL::text AS scrossbadgeids,
    ( SELECT COALESCE(rep.payload ->> 'ExternalReasonCode'::text, rep.payload ->> 'InternalReasonCode'::text) AS "coalesce"
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS reasoncode,
    NULL::text AS parentorderidint,
    NULL::text AS cancelorderidint,
    NULL::text AS contraorderidint,
    NULL::text AS origorderidint,
        CASE
            WHEN co.crossing_side IS NULL THEN "Generation"
            WHEN co.crossing_side = 'O'::bpchar THEN "OriginatorOrderGeneration"
            WHEN co.crossing_side = 'C'::bpchar THEN "ContraOrderGeneration
            ELSE NULL::text
        END AS generation,
    ( SELECT rep.payload ->> 'NoChildren'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS childorders,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SocGenCapacity}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SocGenCapacity}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SocGenCapacity}'::text[]
            ELSE NULL::text
        END AS capacity,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SocGenPortfolio}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SocGenPortfolio}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SocGenPortfolio}'::text[]
            ELSE NULL::text
        END AS portfolio,
    co.payload ->> 'ClassicRouteDestinationCode'::text AS exdestination,
        CASE
            WHEN co.orig_order_id IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                      ORDER BY co2.chain_id DESC
                     LIMIT 1))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS prevfillquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN NULL::text
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                      ORDER BY co2.chain_id DESC
                     LIMIT 1))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN (co.payload ->> 'SpreadType'::text) = '0'::text THEN NULL::text
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text AND co.orig_order_id IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                      ORDER BY co2.chain_id DESC
                     LIMIT 1))::text) AND rep.leg_ref_id::text = ((( SELECT leg2.leg_ref_id
                       FROM blaze7.client_order_leg leg2
                      WHERE leg2.order_id = co.order_id AND (leg2.payload ->> 'LegInstrumentType'::text) = 'E'::text
                     LIMIT 1))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockprevfillquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN NULL::bigint
            WHEN co.instrument_type = 'O'::bpchar THEN (( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                      ORDER BY co2.chain_id DESC
                     LIMIT 1))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1))::bigint
            WHEN co.instrument_type = 'M'::bpchar AND co.orig_order_id IS NOT NULL THEN ( SELECT sum(a1.cumqty) AS sum
               FROM ( SELECT (rep.payload ->> 'CumQty'::text)::integer AS cumqty,
                        row_number() OVER (PARTITION BY rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                               FROM blaze7.client_order co2
                              WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                              ORDER BY co2.chain_id DESC
                             LIMIT 1))::text) AND (rep.leg_ref_id::text IN ( SELECT leg2.leg_ref_id
                               FROM blaze7.client_order_leg leg2
                              WHERE leg2.order_id = co.order_id AND (leg2.payload ->> 'LegInstrumentType'::text) = 'O'::text))) a1
              WHERE a1.rn = 1)
            ELSE NULL::bigint
        END AS optionprevfillquantity,
    ( SELECT co2.order_trade_date
           FROM blaze7.client_order co2
          WHERE co2.cl_ord_id::text = co.cl_ord_id::text AND co2.chain_id = 0) AS tradedate,

 */
    co.order_id AS _order_id,
    co.chain_id AS _chain_id,
    co.db_create_time AS _db_create_time,
    staging.get_max_db_create_time(co.order_id, co.db_create_time::date, co.chain_id) AS _last_mod_time
   FROM blaze7.v_order_base co
  WHERE co.rn = 1;



---
drop view blaze7.v_order_base;
create view blaze7.v_order_base as SELECT cl.order_id,
                cl.chain_id,
                cl.parent_order_id,
                cl.orig_order_id,
                cl.record_type,
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
                cl.payload ->> 'HasStitchedOrders'                                      as "HasStitchedOrders",
                cl.payload ->> 'IsStitched'                                             as "IsStitched",
                cl.payload #>> '{OriginatorOrder,IsStitched}'                           as "OriginatorOrderIsStitched",
                cl.payload ->> 'OriginatorOrderRefId'                                   as "OriginatorOrderRefId",
                cl.payload ->> 'LinkedStageOrderId'                                     as "LinkedStageOrderId",
                cl.payload #>> '{OriginatorOrder,LinkedStageOrderId}'                   as "OriginatorOrderLinkedStageOrderId",
                cl.payload #>> '{ContraOrder,LinkedStageOrderId}'                       as "ContraOrderLinkedStageOrderId",
                cl.payload ->> 'OrderCreationTime'                                      as "OrderCreationTime",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'       as "OriginatorOrderClearingDetailsCustomerUserId",
                cl.payload ->> 'InitiatorUserId'                                        as "InitiatorUserId",
                cl.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'           as "ContraOrderClearingDetailsCustomerUserId",
                cl.payload #>> '{ClearingDetails,CustomerUserId}'                       as "ClearingDetailsCustomerUserId",
                cl.payload ->> 'OwnerUserId'                                            as "OwnerUserId",
                cl.payload #>> '{OriginatorOrder,ClientEntityId}'                       as "OriginatorOrderClientEntityId",
                cl.payload #>> '{ContraOrder,ClientEntityId}'                           as "ContraOrderClientEntityId",
                cl.payload ->> 'ClientEntityId'                                         as "ClientEntityId",
                cl.payload ->> 'DestinationEntityId'                                    as "DestinationEntityId",
                cl.payload ->> 'ProductDescription'                                     as "ProductDescription",
                cl.payload ->> 'NoLegs'                                                 as "NoLegs",
                cl.payload ->> 'Price'                                                  as "Price",
                cl.payload #>> '{OriginatorOrder,Price}'                                as "OriginatorOrderPrice",
                cl.payload #>> '{ContraOrder,Price}'                                    as "ContraOrderPrice",
                cl.payload ->> 'DashTargetVega'                                         as "DashTargetVega",
                cl.payload ->> 'OrderQty'                                               as "OrderQty",
                cl.payload ->> 'SpreadType'                                             as "SpreadType",
                cl.payload ->> 'ContractSize'                                           as "ContractSize",
                cl.payload ->> 'Side'                                                   as "Side",
                cl.payload ->> 'AccountAlias'                                           as "AccountAlias",
                cl.payload #>> '{OriginatorOrder,AccountAlias}'                         as "OriginatorOrderAccountAlias",
                cl.payload #>> '{ContraOrder,AccountAlias}'                             as "ContraOrderAccountAlias",
                cl.payload #>> '{ClearingDetails,Account}'                              as "ClearingDetailsAccount",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,Account}'              as "OriginatorOrderClearingDetailsAccount",
                cl.payload #>> '{ContraOrder,ClearingDetails,Account}'                  as "ContraOrderClearingDetailsAccount",
                cl.payload #>> '{ClearingDetails,SubAcct1}'                             as "ClearingDetailsSubAcct1",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct1}'             as "OriginatorOrderClearingDetailsSubAcct1",
                cl.payload #>> '{ContraOrder,ClearingDetails,SubAcct1}'                 as "ContraOrderClearingDetailsSubAcct1",
                cl.payload #>> '{ClearingDetails,SubAcct2}'                             as "ClearingDetailsSubAcct2",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct2}'             as "OriginatorOrderClearingDetailsSubAcct2",
                cl.payload #>> '{ContraOrder,ClearingDetails,SubAcct2}'                 as "ContraOrderClearingDetailsSubAcct2",
                cl.payload #>> '{ClearingDetails,SubAcct3}'                             as "ClearingDetailsSubAcct3",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct3}'             as "OriginatorOrderClearingDetailsSubAcct3",
                cl.payload #>> '{ContraOrder,ClearingDetails,SubAcct3}'                 as "ContraOrderClearingDetailsSubAcct3",
                cl.payload ->> 'OrderTextComment'                                       as "OrderTextComment",
                cl.payload #>> '{ClearingDetails,OptionRange}'                          as "ClearingDetailsOptionRange",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'          as "OriginatorOrderClearingDetailsOptionRange",
                cl.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'              as "ContraOrderClearingDetailsOptionRange",
                cl.payload #>> '{ClearingDetails,GiveUp}'                               as "ClearingDetailsGiveUp",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'               as "OriginatorOrderClearingDetailsGiveUp",
                cl.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'                   as "ContraOrderClearingDetailsGiveUp",
                cl.payload #>> '{ClearingDetails,CMTA}'                                 as "ClearingDetailsCMTA",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'                 as "OriginatorOrderClearingDetailsCMTA",
                cl.payload #>> '{ContraOrder,ClearingDetails,CMTA}'                     as "ContraOrderClearingDetailsCMTA",
                cl.payload #>> '{ClearingDetails,MPID}'                                 as "ClearingDetailsMPID",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,MPID}'                 as "OriginatorOrderClearingDetailsMPID",
                cl.payload #>> '{ContraOrder,ClearingDetails,MPID}'                     as "ContraOrderClearingDetailsMPID",
                cl.payload #>> '{ClearingDetails,LocateId}'                             as "ClearingDetailsLocateId",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,LocateId}'             as "OriginatorOrderClearingDetailsLocateId",
                cl.payload #>> '{ContraOrder,ClearingDetails,LocateId}'                 as "ContraOrderClearingDetailsLocateId",
                cl.payload ->> 'CrossingMechanism'                                      as "CrossingMechanism",
                cl.payload #>> '{IsSolicited}'                                          as "IsSolicited",
                cl.payload #>> '{OriginatorOrder,IsSolicited}'                          as "OriginatorOrderIsSolicited",
                cl.payload #>> '{ContraOrder,IsSolicited}'                              as "ContraOrderIsSolicited",
                cl.payload ->> 'ExecInst'                                               as "ExecInst",
                cl.payload #>> '{NotHeld}'                                              as "NotHeld",
                cl.payload #>> '{OriginatorOrder,NotHeld}'                              as "OriginatorOrderNotHeld",
                cl.payload #>> '{ContraOrder,NotHeld}'                                  as "ContraOrderNotHeld",
                cl.payload ->> 'OrderType'                                              as "OrderType",
                cl.payload ->> 'TimeInForce'                                            as "TimeInForce",
                cl.payload ->> 'CboePARDestination'                                     as "CboePARDestination",
                cl.payload ->> 'Generation'                                             as "Generation",
                cl.payload #>> '{OriginatorOrder,Generation}'                           as "OriginatorOrderGeneration",
                cl.payload #>> '{ContraOrder,Generation}'                               as "ContraOrderGeneration",
                cl.payload #>> '{ClearingDetails,SocGenCapacity}'                       as "ClearingDetailsSocGenCapacity",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,SocGenCapacity}'       as "OriginatorOrderClearingDetailsSocGenCapacity",
                cl.payload #>> '{ContraOrder,ClearingDetails,SocGenCapacity}'           as "ContraOrderClearingDetailsSocGenCapacity",
                cl.payload #>> '{ClearingDetails,SocGenPortfolio}'                      as "ClearingDetailsSocGenPortfolio",
                cl.payload #>> '{OriginatorOrder,ClearingDetails,SocGenPortfolio}'      as "OriginatorOrderClearingDetailsSocGenPortfolio",
                cl.payload #>> '{ContraOrder,ClearingDetails,SocGenPortfolio}'          as "ContraOrderClearingDetailsSocGenPortfolio",
                cl.payload ->> 'ClassicRouteDestinationCode'                            as "ClassicRouteDestinationCode",
                row_number() OVER (PARTITION BY cl.cl_ord_id ORDER BY cl.chain_id DESC) AS rn
         FROM blaze7.client_order cl
          WHERE cl.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar])