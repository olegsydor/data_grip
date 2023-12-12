-- CREATE OR REPLACE VIEW blaze7.torder_edw_test
-- AS
/*
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
           END                                                                              AS parentorderid,
       co.orig_cl_ord_id                                                                    AS cancelorderid,
       CASE co.crossing_side
           WHEN 'O'::bpchar THEN crs.cl_ord_id
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
           WHEN 'C'::bpchar THEN crs.cl_ord_id
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
           ELSE rep_last_exec_noleg."BlazeOrderStatus"
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
       fill_time."firstTransactTime"                                                        AS firstfilldatetime,
       fill_time."lastTransactTime"                                                         AS lastfilldatetime,
       rep_last_exec."TransactTime"                                                         AS updatedatetime,
       compl_time."TransactTime"                                                            AS completeddatetime,
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
       rep_last_exec."CumQty"                                                               AS filled,
       rep_last_exec_noleg."AvgPx"                                                          AS avgprice,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN cl_ord_leg_e."LegQty"::text
           WHEN co.route_destination::text = 'VEGA'::text THEN cl_ord_leg_e."sumLegQty"::text
           ELSE NULL::text
           END                                                                              AS stockquantity,
       CASE
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN (SELECT rep.payload ->> 'LeavesQty'::text
                                                                      FROM blaze7.order_report rep
                                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                        AND rep.leg_ref_id::text = cl_ord_leg_e.leg_ref_id
                                                                      ORDER BY rep.exec_id DESC
                                                                      LIMIT 1)
           WHEN co.instrument_type = 'E'::bpchar THEN rep_last_exec."LeavesQty"
           ELSE NULL::text
           END                                                                              AS stockopenquantity,
       CASE
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                      FROM blaze7.order_report rep
                                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                        AND rep.leg_ref_id::text = cl_ord_leg_e.leg_ref_id
                                                                      ORDER BY rep.exec_id DESC
                                                                      LIMIT 1)
           WHEN co.instrument_type = 'E'::bpchar THEN rep_last_exec."CumQty"
           WHEN co.route_destination::text = 'VEGA'::text THEN ((SELECT sum(x.sm) AS sum
                                                                 FROM (SELECT (rep.payload ->> 'CumQty'::text)::integer                                   AS sm,
                                                                              row_number()
                                                                              OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                                                       FROM blaze7.order_report rep
                                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                         AND rep.leg_ref_id = cl_ord_leg_e.leg_ref_id) x
                                                                 WHERE x.rn = 1))::text
           ELSE NULL::text
           END                                                                              AS stockfilled,
       CASE
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN (SELECT rep.payload ->> 'CanceledQty'::text
                                                                      FROM blaze7.order_report rep
                                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                                        AND rep.leg_ref_id::text = cl_ord_leg_e.leg_ref_id
                                                                      ORDER BY rep.exec_id DESC
                                                                      LIMIT 1)
           WHEN co.instrument_type = 'E'::bpchar THEN rep_last_exec."CanceledQty"
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
           WHEN 'M'::bpchar THEN opt_m."sumLeavesQty"
           WHEN 'O'::bpchar THEN rep_last_exec."LeavesQty"::bigint
           ELSE NULL::bigint
           END                                                                              AS optionopenquantity,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN opt_m."sumCumQty"
           WHEN 'O'::bpchar THEN rep_last_exec."CumQty"::bigint
           ELSE NULL::bigint
           END                                                                              AS optionfilled,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN opt_m."sumCanceledQty"
           WHEN 'O'::bpchar THEN rep_last_exec."CanceledQty"::bigint
           ELSE NULL::bigint
           END                                                                              AS optioncancelled,
       CASE
           WHEN co.instrument_type in ('O', 'E') THEN (COALESCE((co.payload ->> 'ContractSize'::text)::integer, 1) *
                                                       CASE co.payload ->> 'Side'
                                                           WHEN '1' THEN 1
                                                           ELSE -1 END)::numeric *
                                                      rep_last_exec."CumQty"::bigint::numeric / 10000.0 *
                                                      rep_last_exec."AvgPx"::text::bigint::numeric / 10000.0
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
       coalesce(rep_last_exec."ExternalReasonCode", rep_last_exec."InternalReasonCode")     AS reasoncode,
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
       rep_last_exec."NoChildren"                                                           AS childorders,
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
           WHEN co.orig_order_id IS NOT NULL THEN orig_rep."CumQty"
           ELSE NULL::text
           END                                                                              AS prevfillquantity,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN NULL::text
           WHEN co.instrument_type = 'E'::bpchar THEN orig_rep."CumQty"
           WHEN (co.payload ->> 'SpreadType'::text) = '0'::text THEN NULL::text
           WHEN (co.payload ->> 'SpreadType'::text) = '1'::text AND co.orig_order_id IS NOT NULL
               THEN (SELECT rep.payload ->> 'CumQty'::text
                     FROM blaze7.order_report rep
                     WHERE rep.cl_ord_id::text = orig.cl_ord_id
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
           WHEN co.instrument_type = 'O'::bpchar THEN orig_rep."CumQty"::bigint
           WHEN co.instrument_type = 'M'::bpchar AND co.orig_order_id IS NOT NULL THEN
               (SELECT sum(a1.cumqty) AS sum
                FROM (SELECT (rep.payload ->> 'CumQty'::text)::integer                    AS cumqty,
                             row_number()
                             OVER (PARTITION BY rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                      FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = orig.cl_ord_id
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
FROM blaze7.client_order co
     JOIN LATERAL ( SELECT cl.order_id,
            cl.chain_id
           FROM blaze7.client_order cl
          WHERE cl.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY cl.chain_id DESC
         LIMIT 1) ch ON ch.order_id = co.order_id AND ch.chain_id = co.chain_id

         left join lateral (SELECT rep.payload ->> 'NoChildren'         as "NoChildren",
                                   rep.payload ->> 'ExternalReasonCode' as "ExternalReasonCode",
                                   rep.payload ->> 'InternalReasonCode' as "InternalReasonCode",
                                   rep.payload ->> 'CumQty'             as "CumQty",
                                   rep.payload ->> 'AvgPx'              as "AvgPx",
                                   rep.payload ->> 'CanceledQty'        as "CanceledQty",
                                   rep.payload ->> 'LeavesQty'          as "LeavesQty",
                                   rep.payload ->> 'TransactTime'       as "TransactTime"
                            FROM blaze7.order_report rep
                            WHERE rep.cl_ord_id = co.cl_ord_id
                            ORDER BY rep.exec_id DESC
                            LIMIT 1) rep_last_exec on true
         left join lateral (SELECT orig.cl_ord_id
                            FROM blaze7.client_order orig
                            WHERE orig.cl_ord_id::text = co.orig_cl_ord_id::text
                            ORDER BY orig.chain_id DESC
                            LIMIT 1) orig on true
         left join lateral (SELECT crs.cl_ord_id
                            FROM blaze7.client_order crs
                            WHERE crs.cross_order_id = co.cross_order_id
                              AND case
                                      when co.crossing_side = 'O' then crs.crossing_side = 'C'
                                      when co.crossing_side = 'C' then crs.crossing_side = 'O' end
                            ORDER BY crs.chain_id DESC
                            LIMIT 1) crs on true
         left join lateral (SELECT rp.payload ->> 'BlazeOrderStatus' as "BlazeOrderStatus",
                                   rp.payload ->> 'AvgPx'            as "AvgPx"
                            FROM blaze7.order_report rp
                            WHERE rp.cl_ord_id = co.cl_ord_id
                              AND rp.leg_ref_id IS NULL
                            ORDER BY rp.exec_id DESC
                            LIMIT 1) rep_last_exec_noleg on true
         left join lateral (select first_value(rep.payload ->> 'TransactTime') over ex as "firstTransactTime",
                                   last_value(rep.payload ->> 'TransactTime') over ex  as "lastTransactTime"
                            from blaze7.order_report rep
                            where cl_ord_id = co.cl_ord_id
                              and rep.exec_type in ('1', '2')
                              and case when co.instrument_type = 'M' then rep.leg_ref_id is not null else true end
                            window ex as ( partition by rep.cl_ord_id order by rep.exec_id
                                    rows between unbounded preceding and unbounded following )
                            limit 1
    ) fill_time on true
         left join lateral ( SELECT rep.payload ->> 'TransactTime' as "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id = co.cl_ord_id
                               AND rep.payload ->> 'OrderStatus' in ('2', '3', '4', '8', 'P', 'l', '5')
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) compl_time on true

         left join lateral (SELECT leg.leg_ref_id, min((leg.payload ->> 'LegQty')::int) as "LegQty", sum((leg.payload ->> 'LegQty')::int) as "sumLegQty"
                            FROM blaze7.client_order_leg leg
                            WHERE leg.order_id = co.order_id
                              AND leg.chain_id = co.chain_id
                              AND leg.payload ->> 'LegInstrumentType' = 'E'
                            group by leg.leg_ref_id
                            LIMIT 1) cl_ord_leg_e on true

         left join lateral (SELECT sum(x."LeavesQty")   as "sumLeavesQty",
                                   sum(x."CanceledQty") as "sumCanceledQty",
                                   sum(x."CumQty")      as "sumCumQty"
                            FROM (SELECT (rep.payload ->> 'LeavesQty'::text)::integer                                AS "LeavesQty",
                                         (rep.payload ->> 'CanceledQty'::text)::integer                              as "CanceledQty",
                                         (rep.payload ->> 'CumQty'::text)::integer                                   as "CumQty",
                                         row_number()
                                         OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                                  FROM blaze7.order_report rep
                                  WHERE rep.cl_ord_id::text = co.cl_ord_id
                                    AND (rep.leg_ref_id::text in (SELECT leg.leg_ref_id
                                                                  FROM blaze7.client_order_leg leg
                                                                  WHERE leg.order_id = rep.order_id
                                                                    AND leg.chain_id = rep.chain_id
                                                                    AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
                            WHERE x.rn = 1) opt_m on true
         left join lateral (SELECT rep.payload ->> 'CumQty' as "CumQty"
                            FROM blaze7.order_report rep
                            WHERE rep.cl_ord_id = orig.cl_ord_id
                            ORDER BY rep.exec_id DESC
                            LIMIT 1) orig_rep on true
WHERE co.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar])
and db_create_time between to_timestamp(:date_id, 'YYYYMMDD')
  and to_timestamp(:date_id, 'YYYYMMDD') + interval '1 day';




-----------------------


-- blaze7.torder_edw4 source

CREATE OR REPLACE VIEW blaze7.torder_edw5
AS
    SELECT NULL::text AS id,
    NULL::text AS systemid,
    co.cl_ord_id AS systemorderid,
        CASE
            WHEN co.route_destination::text = 'VEGA'::text THEN 'VEGA'::bpchar
            WHEN (co.payload ->> 'HasStitchedOrders'::text) = 'Y'::text THEN 'StitchedSingle'::bpchar
            WHEN COALESCE(co.payload ->> 'IsStitched'::text, co.payload #>> '{OriginatorOrder,IsStitched}'::text[]) = 'Y'::text THEN 'StitchedSpread'::bpchar
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
            WHEN 'O'::bpchar THEN crs.cl_ord_id
            ELSE ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE ((co2.payload ->> 'OriginatorOrderRefId'::text)::bigint) = co.order_id AND co2.record_type = '0'::bpchar AND co2.chain_id = 0 AND co2.db_create_time >= co.db_create_time::date AND co2.db_create_time <= (co.db_create_time::date + '1 day'::interval)
              ORDER BY co2.chain_id DESC
             LIMIT 1)
        END AS contraorderid,
        CASE co.crossing_side
            WHEN 'C'::bpchar THEN crs.cl_ord_id
            ELSE ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId'::text)::bigint)
              ORDER BY co2.chain_id DESC
             LIMIT 1)
        END AS origorderid,
    ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.orig_cl_ord_id::text = co.cl_ord_id::text AND co2.record_type = '0'::bpchar
          ORDER BY co2.chain_id DESC
         LIMIT 1) AS replaceorderid,
        CASE
            WHEN COALESCE(co.payload ->> 'LinkedStageOrderId'::text, co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[], co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[]) IS NOT NULL THEN 'T'::text
            ELSE rep_last_exec_noleg."BlazeOrderStatus"
        END AS status,
        CASE
            WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
            ELSE ( SELECT co2.payload ->> 'OrderCreationTime'::text
               FROM blaze7.client_order co2
              WHERE co2.cl_ord_id::text = co.cl_ord_id::text AND co2.chain_id = 0)
        END AS createdatetime,
    NULL::text AS approveddatetime,
    NULL::text AS dtclearbookdatetime,
    fill_time."firstTransactTime" AS firstfilldatetime,
    fill_time."lastTransactTime" AS lastfilldatetime,
    rep_last_exec."TransactTime" AS updatedatetime,
    compl_time."TransactTime" AS completeddatetime,
    NULL::text AS writedatetime,
        CASE
            WHEN co.crossing_side = 'O'::bpchar THEN COALESCE(co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[], co.payload ->> 'InitiatorUserId'::text)
            WHEN co.crossing_side = 'C'::bpchar THEN COALESCE(co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[], co.payload ->> 'InitiatorUserId'::text)
            WHEN co.crossing_side IS NULL THEN COALESCE(co.payload #>> '{ClearingDetails,CustomerUserId}'::text[], co.payload ->> 'InitiatorUserId'::text)
            ELSE NULL::text
        END AS userid,
    COALESCE(co.payload ->> 'OwnerUserId'::text, co.payload ->> 'InitiatorUserId'::text) AS ownerid,
    NULL::text AS previousownerid,
        CASE
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CustomerUserId}'::text[]
            ELSE NULL::text
        END AS sendinguserid,
    NULL::text AS executingbroker,
        CASE
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClientEntityId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClientEntityId}'::text[]
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientEntityId'::text
            ELSE NULL::text
        END AS companyid,
    co.payload ->> 'DestinationEntityId'::text AS destinationcompanyid,
    NULL::text AS introducingcompanyid,
    NULL::text AS parentcompanyid,
    co.route_type AS exchangeconnectionid,
    NULL::text AS exchangeinfoid,
    NULL::text AS exchangecomment,
    co.payload ->> 'ProductDescription'::text AS contractdesc,
    NULL::text AS strategytype,
    NULL::text AS assetclass,
    COALESCE(co.payload ->> 'NoLegs'::text, '1'::text) AS legcount,
    COALESCE(
        CASE
            WHEN co.crossing_side IS NULL OR co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
            WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
            WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
            WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
            ELSE NULL::text
        END, '0'::text) AS price,
    COALESCE(co.payload ->> 'DashTargetVega'::text, co.payload ->> 'OrderQty'::text) AS quantity,
    rep_last_exec."CumQty" AS filled,
    rep_last_exec_noleg."AvgPx" AS avgprice,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN ( SELECT leg.payload ->> 'LegQty'::text
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
             LIMIT 1)
            WHEN co.route_destination::text = 'VEGA'::text THEN (( SELECT sum((leg.payload ->> 'LegQty'::text)::integer) AS sum
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text))::text
            ELSE NULL::text
        END AS stockquantity,
        CASE
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN ( SELECT rep.payload ->> 'LeavesQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = cl_ord_leg_e.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'E'::bpchar THEN rep_last_exec."LeavesQty"
            ELSE NULL::text
        END AS stockopenquantity,
        CASE
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = cl_ord_leg_e.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'E'::bpchar THEN rep_last_exec."CumQty"
            WHEN co.route_destination::text = 'VEGA'::text THEN (( SELECT sum(x.sm) AS sum
               FROM ( SELECT (rep.payload ->> 'CumQty'::text)::integer AS sm,
                        row_number() OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = cl_ord_leg_e.leg_ref_id::text) x
              WHERE x.rn = 1))::text
            ELSE NULL::text
        END AS stockfilled,
        CASE
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN ( SELECT rep.payload ->> 'CanceledQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = cl_ord_leg_e.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'E'::bpchar THEN rep_last_exec."CanceledQty"
            ELSE NULL::text
        END AS stockcancelled,
        CASE co.instrument_type
            WHEN 'O'::bpchar THEN (co.payload ->> 'OrderQty'::text)::bigint
            WHEN 'M'::bpchar THEN ( SELECT sum((leg.payload ->> 'LegQty'::text)::integer) AS sum
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text)
            ELSE NULL::bigint
        END AS optionquantity,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN opt_m."sumLeavesQty"
            WHEN 'O'::bpchar THEN rep_last_exec."LeavesQty"::bigint
            ELSE NULL::bigint
        END AS optionopenquantity,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN opt_m."sumCumQty"
            WHEN 'O'::bpchar THEN rep_last_exec."CumQty"::bigint
            ELSE NULL::bigint
        END AS optionfilled,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN opt_m."sumCanceledQty"
            WHEN 'O'::bpchar THEN rep_last_exec."CanceledQty"::bigint
            ELSE NULL::bigint
        END AS optioncancelled,
        CASE
            WHEN co.instrument_type = ANY (ARRAY['O'::bpchar, 'E'::bpchar]) THEN (COALESCE((co.payload ->> 'ContractSize'::text)::integer, 1) *
            CASE co.payload ->> 'Side'::text
                WHEN '1'::text THEN 1
                ELSE '-1'::integer
            END)::numeric * rep_last_exec."CumQty"::bigint::numeric / 10000.0 * rep_last_exec."AvgPx"::bigint::numeric / 10000.0
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
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'AccountAlias'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,AccountAlias}'::text[]
            ELSE NULL::text
        END AS accountalias,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,Account}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,Account}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,Account}'::text[]
            ELSE NULL::text
        END AS account,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct1}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct1}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct1}'::text[]
            ELSE NULL::text
        END AS subaccount,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct2}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct2}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct2}'::text[]
            ELSE NULL::text
        END AS subaccount2,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SubAcct3}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SubAcct3}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SubAcct3}'::text[]
            ELSE NULL::text
        END AS subaccount3,
    co.payload ->> 'OrderTextComment'::text AS comment,
    NULL::text AS brokercomment,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,OptionRange}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'::text[]
            ELSE NULL::text
        END AS forwhom,
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
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,MPID}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,MPID}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,MPID}'::text[]
            ELSE NULL::text
        END AS mpid,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,LocateId}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,LocateId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,LocateId}'::text[]
            ELSE NULL::text
        END AS sstkclid,
    NULL::text AS iscapstrategy,
    NULL::text AS iscrosslate,
    NULL::text AS isfbsamexoverrideprice,
    NULL::text AS isfbsamexratiospread,
        CASE co.payload ->> 'CrossingMechanism'::text
            WHEN 'Q'::text THEN '1'::text
            ELSE '0'::text
        END AS isqcc,
        CASE
            WHEN COALESCE(co.payload ->> 'LinkedStageOrderId'::text, co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[], co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[]) IS NOT NULL THEN '1'::text
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
                WHEN co.crossing_side IS NULL THEN co.payload #>> '{IsSolicited}'::text[]
                WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,IsSolicited}'::text[]
                WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,IsSolicited}'::text[]
                ELSE NULL::text
            END = 'Y'::text THEN '1'::text
            ELSE '0'::text
        END AS issolicited,
    NULL::text AS isservercast,
    NULL::text AS iscoveredcode,
        CASE
            WHEN (co.payload ->> 'ExecInst'::text) = 'G'::text THEN '1'::text
            ELSE '0'::text
        END AS isallornone,
    NULL::text AS isdeltahedge,
        CASE
            WHEN
            CASE
                WHEN co.crossing_side IS NULL THEN co.payload #>> '{NotHeld}'::text[]
                WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,NotHeld}'::text[]
                WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,NotHeld}'::text[]
                ELSE NULL::text
            END = 'Y'::text THEN '1'::text
            ELSE '0'::text
        END AS isnotheld,
        CASE
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN '1'::text
            ELSE '0'::text
        END AS istiedtostock,
    NULL::text AS istrytostop,
    NULL::text AS delta,
    NULL::text AS billingentity,
    co.payload ->> 'OrderType'::text AS pricequalifier,
    co.payload ->> 'TimeInForce'::text AS timeinforcecode,
    co.payload ->> 'CboePARDestination'::text AS boothidoverride,
    NULL::text AS isignorepreference,
    (( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.order_id = COALESCE(co.payload ->> 'LinkedStageOrderId'::text, co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[], co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[])::bigint AND co2.chain_id = 0))::text AS linkorderid,
    NULL::text AS ltargetresponseid,
    NULL::text AS satpid,
    NULL::text AS scrossbadgeids,
    COALESCE(rep_last_exec."ExternalReasonCode", rep_last_exec."InternalReasonCode") AS reasoncode,
    NULL::text AS parentorderidint,
    NULL::text AS cancelorderidint,
    NULL::text AS contraorderidint,
    NULL::text AS origorderidint,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Generation}'::text[]
            ELSE NULL::text
        END AS generation,
    rep_last_exec."NoChildren" AS childorders,
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
            WHEN co.orig_order_id IS NOT NULL THEN orig_rep."CumQty"
            ELSE NULL::text
        END AS prevfillquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN NULL::text
            WHEN co.instrument_type = 'E'::bpchar THEN orig_rep."CumQty"
            WHEN (co.payload ->> 'SpreadType'::text) = '0'::text THEN NULL::text
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text AND co.orig_order_id IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = orig.cl_ord_id::text AND rep.leg_ref_id::text = ((( SELECT leg2.leg_ref_id
                       FROM blaze7.client_order_leg leg2
                      WHERE leg2.order_id = co.order_id AND (leg2.payload ->> 'LegInstrumentType'::text) = 'E'::text
                     LIMIT 1))::text)
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockprevfillquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN NULL::bigint
            WHEN co.instrument_type = 'O'::bpchar THEN orig_rep."CumQty"::bigint
            WHEN co.instrument_type = 'M'::bpchar AND co.orig_order_id IS NOT NULL THEN ( SELECT sum(a1.cumqty) AS sum
               FROM ( SELECT (rep.payload ->> 'CumQty'::text)::integer AS cumqty,
                        row_number() OVER (PARTITION BY rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                       FROM blaze7.order_report rep
                      WHERE rep.cl_ord_id::text = orig.cl_ord_id::text AND (rep.leg_ref_id::text IN ( SELECT leg2.leg_ref_id
                               FROM blaze7.client_order_leg leg2
                              WHERE leg2.order_id = co.order_id AND (leg2.payload ->> 'LegInstrumentType'::text) = 'O'::text))) a1
              WHERE a1.rn = 1)
            ELSE NULL::bigint
        END AS optionprevfillquantity,
    ( SELECT co2.order_trade_date
           FROM blaze7.client_order co2
          WHERE co2.cl_ord_id::text = co.cl_ord_id::text AND co2.chain_id = 0) AS tradedate,
    co.order_id AS _order_id,
    co.chain_id AS _chain_id,
    co.db_create_time AS _db_create_time,
    orig.db_create_time as orig_db_create_time,
    rep_last_exec.db_create_time as rep_db_create_time
   FROM blaze7.client_order co
     JOIN LATERAL ( SELECT cl.order_id,
            cl.chain_id
           FROM blaze7.client_order cl
          WHERE cl.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY cl.chain_id DESC
         LIMIT 1) ch ON ch.order_id = co.order_id AND ch.chain_id = co.chain_id
     LEFT JOIN LATERAL ( SELECT rep.payload ->> 'NoChildren'::text AS "NoChildren",
            rep.payload ->> 'ExternalReasonCode'::text AS "ExternalReasonCode",
            rep.payload ->> 'InternalReasonCode'::text AS "InternalReasonCode",
            rep.payload ->> 'CumQty'::text AS "CumQty",
            rep.payload ->> 'AvgPx'::text AS "AvgPx",
            rep.payload ->> 'CanceledQty'::text AS "CanceledQty",
            rep.payload ->> 'LeavesQty'::text AS "LeavesQty",
            rep.payload ->> 'TransactTime'::text AS "TransactTime",
            rep.db_create_time
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) rep_last_exec ON true
     LEFT JOIN LATERAL ( SELECT orig_1.cl_ord_id,
                                orig_1.db_create_time
           FROM blaze7.client_order orig_1
          WHERE orig_1.cl_ord_id::text = co.orig_cl_ord_id::text
          ORDER BY orig_1.chain_id DESC
         LIMIT 1) orig ON true
     LEFT JOIN LATERAL ( SELECT crs_1.cl_ord_id
           FROM blaze7.client_order crs_1
          WHERE crs_1.cross_order_id = co.cross_order_id AND
                CASE
                    WHEN co.crossing_side = 'O'::bpchar THEN crs_1.crossing_side = 'C'::bpchar
                    WHEN co.crossing_side = 'C'::bpchar THEN crs_1.crossing_side = 'O'::bpchar
                    ELSE NULL::boolean
                END
          ORDER BY crs_1.chain_id DESC
         LIMIT 1) crs ON true
     LEFT JOIN LATERAL ( SELECT rp.payload ->> 'BlazeOrderStatus'::text AS "BlazeOrderStatus",
            rp.payload ->> 'AvgPx'::text AS "AvgPx"
           FROM blaze7.order_report rp
          WHERE rp.cl_ord_id::text = co.cl_ord_id::text AND rp.leg_ref_id IS NULL
          ORDER BY rp.exec_id DESC
         LIMIT 1) rep_last_exec_noleg ON true
     LEFT JOIN LATERAL ( SELECT first_value(rep.payload ->> 'TransactTime'::text) OVER ex AS "firstTransactTime",
            last_value(rep.payload ->> 'TransactTime'::text) OVER ex AS "lastTransactTime"
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar])) AND
                CASE
                    WHEN co.instrument_type = 'M'::bpchar THEN rep.leg_ref_id IS NOT NULL
                    ELSE true
                END
          WINDOW ex AS (PARTITION BY rep.cl_ord_id ORDER BY rep.exec_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
         LIMIT 1) fill_time ON true
     LEFT JOIN LATERAL ( SELECT rep.payload ->> 'TransactTime'::text AS "TransactTime"
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND ((rep.payload ->> 'OrderStatus'::text) = ANY (ARRAY['2'::text, '3'::text, '4'::text, '8'::text, 'P'::text, 'l'::text, '5'::text]))
          ORDER BY rep.exec_id DESC
         LIMIT 1) compl_time ON true
     LEFT JOIN LATERAL ( SELECT leg.leg_ref_id
           FROM blaze7.client_order_leg leg
          WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
         LIMIT 1) cl_ord_leg_e ON true
     LEFT JOIN LATERAL ( SELECT sum(x."LeavesQty") AS "sumLeavesQty",
            sum(x."CanceledQty") AS "sumCanceledQty",
            sum(x."CumQty") AS "sumCumQty"
           FROM ( SELECT (rep.payload ->> 'LeavesQty'::text)::integer AS "LeavesQty",
                    (rep.payload ->> 'CanceledQty'::text)::integer AS "CanceledQty",
                    (rep.payload ->> 'CumQty'::text)::integer AS "CumQty",
                    row_number() OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
                   FROM blaze7.order_report rep
                  WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.leg_ref_id::text IN ( SELECT leg.leg_ref_id
                           FROM blaze7.client_order_leg leg
                          WHERE leg.order_id = rep.order_id AND leg.chain_id = rep.chain_id AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
          WHERE x.rn = 1) opt_m ON true
     LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text AS "CumQty"
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = orig.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) orig_rep ON true
  WHERE co.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar]);


--------------------------


-- blaze7.tlegs_edw source

CREATE OR REPLACE VIEW blaze7.tlegs_edw
AS SELECT NULL::text AS id,
    co.cl_ord_id AS orderid,
    COALESCE(co.leg_ref_id, '0'::character varying) AS legrefid,
    COALESCE(
        CASE
            WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
            WHEN (co.leg_payload ->> 'LegPrice'::text) IS NOT NULL THEN co.leg_payload ->> 'LegPrice'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
            ELSE co.payload ->> 'Price'::text
        END, '0'::text) AS price,
    COALESCE(co.payload ->> 'NoLegs'::text, '1'::text) AS legcount,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN co.leg_payload ->> 'LegSeqNumber'::text
            ELSE '1'::text
        END AS legnumber,
    co.dashsecurityid,
    COALESCE("substring"(co.dashsecurityid, 'US:EQ:(.+)'::text), "substring"(co.dashsecurityid, 'US:[FO|OP]{2}:(.+)_'::text)) AS basecode,
        CASE
            WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = 'EQ'::text THEN 'S'::text
            WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN "substring"(co.dashsecurityid, '[0-9]{6}(.)'::text)
            ELSE NULL::text
        END AS typecode,
        CASE
            WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN to_date("substring"(co.dashsecurityid, '([0-9]{6})'::text), 'YYMMDD'::text)
            ELSE NULL::date
        END AS expirationdate,
        CASE
            WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN "substring"(co.dashsecurityid, '[0-9]{6}.(.+)$'::text)::numeric
            ELSE NULL::numeric
        END AS strike,
        CASE
            WHEN co.instrument_type = 'M'::bpchar THEN co.leg_payload ->> 'LegSide'::text
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'::text[]
            ELSE NULL::text
        END AS side,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN co.leg_payload ->> 'LegRatioQty'::text
            ELSE '1'::text
        END AS ratio,
    COALESCE(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN co.leg_payload ->> 'ContractSize'::text
            ELSE co.payload ->> 'ContractSize'::text
        END, '1'::text) AS multiplier,
    COALESCE(co.payload ->> 'DashTargetVega'::text, co.payload ->> 'OrderQty'::text) AS quantity,
    ( SELECT rep.payload ->> 'CumQty'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id IS NULL
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS filled,
        CASE
            WHEN co.instrument_type = ANY (ARRAY['O'::bpchar, 'E'::bpchar]) THEN (COALESCE((co.payload ->> 'ContractSize'::text)::integer, 1) *
            CASE co.payload ->> 'Side'::text
                WHEN '1'::text THEN 1
                ELSE '-1'::integer
            END)::numeric * (( SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 * ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric / 10000.0
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))
            WHEN co.instrument_type = 'M'::bpchar THEN (COALESCE(co.leg_payload ->> 'ContractSize'::text, '1'::text)::integer *
            CASE co.leg_payload ->> 'LegSide'::text
                WHEN '1'::text THEN 1
                ELSE '-1'::integer
            END)::numeric * (( SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 * ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric / 10000.0
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))
            ELSE NULL::numeric
        END AS invested,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN
            CASE
                WHEN (co.leg_payload ->> 'LegSide'::text) = '2'::text THEN '-1'::integer
                ELSE 1
            END * (( SELECT (rep.payload ->> 'AvgPx'::text)::bigint AS int8
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))
            ELSE
            CASE
                WHEN co.crossing_side IS NULL AND (co.payload ->> 'Side'::text) = '2'::text THEN '-1'::integer
                WHEN co.crossing_side = 'O'::bpchar AND (co.payload #>> '{OriginatorOrder,Side}'::text[]) = '2'::text THEN '-1'::integer
                WHEN co.crossing_side = 'C'::bpchar AND (co.payload #>> '{ContraOrder,Side}'::text[]) = '2'::text THEN '-1'::integer
                ELSE 1
            END * (( SELECT (rep.payload ->> 'AvgPx'::text)::bigint AS int8
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1))
        END::text AS avgprice,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text THEN co.leg_payload ->> 'LegQty'::text
            ELSE NULL::text
        END AS stockquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'LeavesQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text THEN ( SELECT rep.payload ->> 'LeavesQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockopenquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockfilled,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'CanceledQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text THEN ( SELECT rep.payload ->> 'CanceledQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockcancelled,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN co.payload ->> 'OrderQty'::text
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text THEN co.leg_payload ->> 'LegQty'::text
            ELSE NULL::text
        END AS optionquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN ( SELECT rep.payload ->> 'LeavesQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text THEN ( SELECT rep.payload ->> 'LeavesQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS optionopenquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS optionfilled,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN ( SELECT rep.payload ->> 'CanceledQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text THEN ( SELECT rep.payload ->> 'CanceledQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS optioncancelled,
        CASE
            WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
            ELSE ( SELECT co2.payload ->> 'OrderCreationTime'::text
               FROM blaze7.client_order co2
              WHERE co2.cl_ord_id::text = co.cl_ord_id::text AND co2.chain_id = 0)
        END AS mindatetime,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
        END AS maxdatetime,
        CASE
            WHEN co.instrument_type <> 'M'::bpchar THEN ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
              ORDER BY rep.exec_id
             LIMIT 1)
            ELSE ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
              ORDER BY rep.exec_id
             LIMIT 1)
        END AS firstfilldatetime,
        CASE
            WHEN co.instrument_type <> 'M'::bpchar THEN ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = co.leg_ref_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
              ORDER BY rep.exec_id DESC
             LIMIT 1)
        END AS lastfilldatetime,
        CASE
            WHEN COALESCE(co.payload ->> 'LinkedStageOrderId'::text, co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[], co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[]) IS NOT NULL THEN 'T'::text
            ELSE ( SELECT rp.payload ->> 'BlazeOrderStatus'::text
               FROM blaze7.order_report rp
              WHERE rp.cl_ord_id::text = co.cl_ord_id::text AND
                    CASE
                        WHEN co.instrument_type = 'M'::bpchar THEN rp.leg_ref_id::text = co.leg_ref_id::text
                        ELSE true
                    END
              ORDER BY rp.exec_id DESC
             LIMIT 1)
        END AS statuscode,
    co.payload ->> 'TimeInForce'::text AS timeinforcecode,
        CASE
            WHEN co.instrument_type = 'M'::bpchar THEN co.leg_payload ->> 'PositionEffect'::text
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,PositionEffect}'::text[]
            ELSE NULL::text
        END AS openclose,
    NULL::text AS systemid,
    NULL::text AS orderidint,
    COALESCE("substring"(co.dashsecurityid, 'US:EQ:(.+)'::text), "substring"(co.dashsecurityid, 'US:[FO|OP]{2}:(.+)_'::text)) AS rootcode,
        CASE
            WHEN (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                      ORDER BY co2.chain_id DESC
                     LIMIT 1))::text) AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text = COALESCE(co.leg_ref_id, 'leg_ref_id'::character varying)::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS prevfillquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar OR co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text AND (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                      ORDER BY co2.chain_id DESC
                     LIMIT 1))::text) AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text = COALESCE(co.leg_ref_id, 'leg_ref_id'::character varying)::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockprevfillquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar OR co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text AND (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = ((( SELECT co2.cl_ord_id
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                      ORDER BY co2.chain_id DESC
                     LIMIT 1))::text) AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text = COALESCE(co.leg_ref_id, 'leg_ref_id'::character varying)::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS optionprevfillquantity,
        CASE
            WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'StitchedSingleOrderId'::text) IS NOT NULL THEN (( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id::text = (co.leg_payload ->> 'StitchedSingleOrderId'::text) AND co2.chain_id = 0
             LIMIT 1))::text
            ELSE NULL::text
        END AS legorderid,
    co.order_id AS _order_id,
    co.chain_id AS _chain_id,
    co.db_create_time AS _db_create_time,
    max_rep._last_mod_time
   FROM ( SELECT co_1.order_id,
            co_1.chain_id,
            co_1.parent_order_id,
            co_1.orig_order_id,
            co_1.record_type,
            co_1.user_id,
            co_1.entity_id,
            co_1.payload,
            co_1.db_create_time,
            co_1.cross_order_id,
            co_1.cl_ord_id,
            co_1.orig_cl_ord_id,
            co_1.crossing_side,
            co_1.instrument_type,
            co_1.order_class,
            co_1.route_type,
            leg.leg_ref_id,
            regexp_replace(leg.payload::text, '\\u0000'::text, ''::text, 'g'::text)::json AS leg_payload,
                CASE co_1.instrument_type
                    WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                    ELSE co_1.payload ->> 'DashSecurityId'::text
                END AS dashsecurityid
           FROM ( SELECT row_number() OVER (PARTITION BY client_order.cl_ord_id ORDER BY client_order.chain_id DESC) AS rn,
                    client_order.order_id,
                    client_order.chain_id,
                    client_order.parent_order_id,
                    client_order.orig_order_id,
                    client_order.record_type,
                    client_order.user_id,
                    client_order.entity_id,
                    regexp_replace(client_order.payload::text, '\\u0000'::text, ''::text, 'g'::text)::json AS payload,
                    client_order.db_create_time,
                    client_order.cross_order_id,
                    client_order.cl_ord_id,
                    client_order.orig_cl_ord_id,
                    client_order.crossing_side,
                    client_order.instrument_type,
                    client_order.order_class,
                    client_order.route_type
                   FROM blaze7.client_order
                  WHERE client_order.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar])) co_1
             LEFT JOIN blaze7.client_order_leg leg ON leg.order_id = co_1.order_id AND leg.chain_id = co_1.chain_id
          WHERE co_1.rn = 1) co
     LEFT JOIN LATERAL ( SELECT max(rep.db_create_time) AS _last_mod_time
           FROM blaze7.order_report rep
          WHERE rep.order_id = co.order_id AND rep.chain_id = co.chain_id
         LIMIT 1) max_rep ON true;

*/

--------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW blaze7.tlegs_edw3
AS

SELECT NULL::text                                                                                   AS id,
       co.cl_ord_id                                                                                 AS orderid,
       COALESCE(leg.leg_ref_id, '0'::character varying)                                             AS legrefid,
       COALESCE(
               CASE
                   WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
                   WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
                   WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
                   ELSE co.payload ->> 'Price'::text
                   END, '0'::text)                                                                  AS price,
       COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                                           AS legcount,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN leg.payload ->> 'LegSeqNumber'::text
           ELSE '1'::text
           END                                                                                      AS legnumber,
       case co.instrument_type
           when 'M' then leg.payload ->> 'DashSecurityId'
           else co.payload ->> 'DashSecurityId' end                                                 as dashsecurityid,
       COALESCE(
               "substring"(case co.instrument_type
                               when 'M' then leg.payload ->> 'DashSecurityId'
                               else co.payload ->> 'DashSecurityId' end, 'US:EQ:(.+)'),
               "substring"(case co.instrument_type
                               when 'M' then leg.payload ->> 'DashSecurityId'
                               else co.payload ->> 'DashSecurityId' end, 'US:[FO|OP]{2}:(.+)_')
           )                                                                                        AS basecode,
       CASE
           WHEN "substring"(case co.instrument_type
                                when 'M' then leg.payload ->> 'DashSecurityId'
                                else co.payload ->> 'DashSecurityId' end, 'US:([FO|OP|EQ]{2})'::text) = 'EQ'::text
               THEN 'S'::text
           WHEN "substring"(case co.instrument_type
                                when 'M' then leg.payload ->> 'DashSecurityId'
                                else co.payload ->> 'DashSecurityId' end, 'US:([FO|OP|EQ]{2})'::text) = ANY
                (ARRAY ['FO'::text, 'OP'::text]) THEN "substring"(case co.instrument_type
                                                                      when 'M' then leg.payload ->> 'DashSecurityId'
                                                                      else co.payload ->> 'DashSecurityId' end,
                                                                  '[0-9]{6}(.)'::text)
           ELSE NULL::text
           END                                                                                      AS typecode,
       CASE
           WHEN "substring"(case co.instrument_type
                                when 'M' then leg.payload ->> 'DashSecurityId'
                                else co.payload ->> 'DashSecurityId' end, 'US:([FO|OP|EQ]{2})'::text) = ANY
                (ARRAY ['FO'::text, 'OP'::text]) THEN to_date("substring"(case co.instrument_type
                                                                              when 'M'
                                                                                  then leg.payload ->> 'DashSecurityId'
                                                                              else co.payload ->> 'DashSecurityId' end,
                                                                          '([0-9]{6})'::text), 'YYMMDD'::text)
           ELSE NULL::date
           END                                                                                      AS expirationdate,
       CASE
           WHEN "substring"(case co.instrument_type
                                when 'M' then leg.payload ->> 'DashSecurityId'
                                else co.payload ->> 'DashSecurityId' end, 'US:([FO|OP|EQ]{2})'::text) = ANY
                (ARRAY ['FO'::text, 'OP'::text]) THEN "substring"(case co.instrument_type
                                                                      when 'M' then leg.payload ->> 'DashSecurityId'
                                                                      else co.payload ->> 'DashSecurityId' end,
                                                                  '[0-9]{6}.(.+)$'::text)::numeric
           ELSE NULL::numeric
           END                                                                                      AS strike,
       CASE
           WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'LegSide'::text
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'::text[]
           ELSE NULL::text
           END                                                                                      AS side,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN leg.payload ->> 'LegRatioQty'::text
           ELSE '1'::text
           END                                                                                      AS ratio,
       COALESCE(
               CASE co.instrument_type
                   WHEN 'M'::bpchar THEN leg.payload ->> 'ContractSize'::text
                   ELSE co.payload ->> 'ContractSize'::text
                   END, '1'::text)                                                                  AS multiplier,
       COALESCE(co.payload ->> 'DashTargetVega'::text, co.payload ->> 'OrderQty'::text)             AS quantity,
       (SELECT rep.payload ->> 'CumQty'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          AND rep.leg_ref_id IS NULL
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                                    AS filled,
       CASE
           WHEN co.instrument_type = ANY (ARRAY ['O'::bpchar, 'E'::bpchar]) THEN
                               (COALESCE((co.payload ->> 'ContractSize'::text)::integer, 1) *
                                CASE co.payload ->> 'Side'::text
                                    WHEN '1'::text THEN 1
                                    ELSE '-1'::integer END)::numeric *
                               rep_last."CumQty"::bigint::numeric / 10000.0 * rep_last."AvgPx"::bigint::numeric /
                               10000.0
           WHEN co.instrument_type = 'M'::bpchar THEN
                               (COALESCE(leg.payload ->> 'ContractSize'::text, '1'::text)::integer *
                                CASE leg.payload ->> 'LegSide'::text
                                    WHEN '1'::text THEN 1
                                    ELSE '-1'::integer END)::numeric *
                               rep_last_exec."CumQty"::bigint::numeric / 10000.0 *
                               rep_last_exec."AvgPx"::bigint::numeric / 10000.0
           ELSE NULL::numeric
           END                                                                                      AS invested,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN
                   CASE
                       WHEN (leg.payload ->> 'LegSide'::text) = '2'::text THEN '-1'::integer
                       ELSE 1
                       END * rep_last_exec."AvgPx"::bigint
           ELSE
                   CASE
                       WHEN co.crossing_side IS NULL AND (co.payload ->> 'Side'::text) = '2'::text THEN '-1'::integer
                       WHEN co.crossing_side = 'O'::bpchar AND (co.payload #>> '{OriginatorOrder,Side}'::text[]) = '2'::text
                           THEN '-1'::integer
                       WHEN co.crossing_side = 'C'::bpchar AND (co.payload #>> '{ContraOrder,Side}'::text[]) = '2'::text
                           THEN '-1'::integer
                       ELSE 1
                       END * rep_last."AvgPx"::bigint
           END::text                                                                                AS avgprice,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               THEN leg.payload ->> 'LegQty'::text
           ELSE NULL::text
           END                                                                                      AS stockquantity,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN rep_last."LeavesQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               THEN rep_last_exec."LeavesQty"
           ELSE NULL::text
           END                                                                                      AS stockopenquantity,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'CumQty'::text
                                                       FROM blaze7.order_report rep
                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                       ORDER BY rep.exec_id DESC
                                                       LIMIT 1)
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               THEN rep_last_exec."CumQty"
           ELSE NULL::text
           END                                                                                      AS stockfilled,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN rep_last."CanceledQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               then rep_last_exec."CanceledQty"
           ELSE NULL::text
           END                                                                                      AS stockcancelled,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN co.payload ->> 'OrderQty'::text
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN leg.payload ->> 'LegQty'::text
           ELSE NULL::text
           END                                                                                      AS optionquantity,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN rep_last."LeavesQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN rep_last_exec."LeavesQty"
           ELSE NULL::text
           END                                                                                      AS optionopenquantity,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN rep_last."CumQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN rep_last_exec."CumQty"
           ELSE NULL::text
           END                                                                                      AS optionfilled,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN rep_last."CanceledQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN rep_last_exec."CanceledQty"
           ELSE NULL::text
           END                                                                                      AS optioncancelled,
       CASE
           WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
           ELSE f_chain."OrderCreationTime"
           END                                                                                      AS mindatetime,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN rep_last_exec."TransactTime"
           ELSE rep_last."TransactTime"
           END                                                                                      AS maxdatetime,
       CASE
           WHEN co.instrument_type <> 'M'::bpchar THEN (SELECT rep.payload ->> 'TransactTime'::text
                                                        FROM blaze7.order_report rep
                                                        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                          AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
                                                        ORDER BY rep.exec_id
                                                        LIMIT 1)
           ELSE (SELECT rep.payload ->> 'TransactTime'::text
                 FROM blaze7.order_report rep
                 WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                   AND rep.leg_ref_id::text = leg.leg_ref_id::text
                   AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
                 ORDER BY rep.exec_id
                 LIMIT 1)
           END                                                                                      AS firstfilldatetime,
       CASE
           WHEN co.instrument_type <> 'M'::bpchar THEN (SELECT rep.payload ->> 'TransactTime'::text
                                                        FROM blaze7.order_report rep
                                                        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                          AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
                                                        ORDER BY rep.exec_id DESC
                                                        LIMIT 1)
           ELSE (SELECT rep.payload ->> 'TransactTime'::text
                 FROM blaze7.order_report rep
                 WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                   AND rep.leg_ref_id::text = leg.leg_ref_id::text
                   AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
                 ORDER BY rep.exec_id DESC
                 LIMIT 1)
           END                                                                                      AS lastfilldatetime,
       CASE
           WHEN COALESCE(co.payload ->> 'LinkedStageOrderId'::text,
                         co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[],
                         co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[]) IS NOT NULL THEN 'T'::text
           ELSE (SELECT rp.payload ->> 'BlazeOrderStatus'::text
                 FROM blaze7.order_report rp
                 WHERE rp.cl_ord_id::text = co.cl_ord_id::text
                   AND CASE
                           WHEN co.instrument_type = 'M'::bpchar THEN rp.leg_ref_id::text = leg.leg_ref_id::text
                           ELSE true
                     END
                 ORDER BY rp.exec_id DESC
                 LIMIT 1)
           END                                                                                      AS statuscode,
       co.payload ->> 'TimeInForce'::text                                                           AS timeinforcecode,
       CASE
           WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'PositionEffect'::text
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,PositionEffect}'::text[]
           ELSE NULL::text
           END                                                                                      AS openclose,
       NULL::text                                                                                   AS systemid,
       NULL::text                                                                                   AS orderidint,
       COALESCE("substring"(case co.instrument_type
                                when 'M' then leg.payload ->> 'DashSecurityId'
                                else co.payload ->> 'DashSecurityId' end, 'US:EQ:(.+)'::text), "substring"(
                        case co.instrument_type
                            when 'M' then leg.payload ->> 'DashSecurityId'
                            else co.payload ->> 'DashSecurityId' end, 'US:[FO|OP]{2}:(.+)_'::text)) AS rootcode,
       CASE
           WHEN (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                       FROM blaze7.order_report rep
                                                                       WHERE rep.cl_ord_id::text = orig.cl_ord_id
                                                                         AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                                                                             COALESCE(leg.leg_ref_id, 'leg_ref_id'::character varying)::text
                                                                       ORDER BY rep.exec_id DESC
                                                                       LIMIT 1)
           ELSE NULL::text
           END                                                                                      AS prevfillquantity,
       CASE
           WHEN co.instrument_type = 'E'::bpchar OR
                co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text AND
                (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN
               (SELECT rep.payload ->> 'CumQty'::text
                FROM blaze7.order_report rep
                WHERE rep.cl_ord_id::text = orig.cl_ord_id
                  AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                      COALESCE(leg.leg_ref_id, 'leg_ref_id'::character varying)::text
                ORDER BY rep.exec_id DESC
                LIMIT 1)
           ELSE NULL::text
           END                                                                                      AS stockprevfillquantity,
select CASE
           WHEN co.instrument_type = 'O'::bpchar OR
                co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text AND
                (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                       FROM blaze7.order_report rep
                                                                       WHERE rep.cl_ord_id::text =
                                                                             (((SELECT co2.cl_ord_id
                                                                                FROM blaze7.client_order co2
                                                                                WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                                                                                ORDER BY co2.chain_id DESC
                                                                                LIMIT 1))::text)
                                                                         AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                                                                             COALESCE(leg.leg_ref_id, 'leg_ref_id'::character varying)::text
                                                                       ORDER BY rep.exec_id DESC
                                                                       LIMIT 1)
           ELSE NULL::text
           END           AS optionprevfillquantity,

       CASE
           WHEN co.instrument_type = 'O'::bpchar OR
                (co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text AND
                 (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL)
               THEN
               (SELECT rep.payload ->> 'CumQty'::text
                FROM blaze7.order_report rep
                WHERE rep.cl_ord_id::text = orig.cl_ord_id
                  AND rep.leg_ref_id is not distinct from leg.leg_ref_id
                ORDER BY rep.exec_id DESC
                LIMIT 1)
           ELSE NULL::text
           END           AS optionprevfillquantity,
       CASE
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'StitchedSingleOrderId'::text) IS NOT NULL THEN
               ((SELECT co2.cl_ord_id
                 FROM blaze7.client_order co2
                 WHERE co2.order_id = (leg.payload ->> 'StitchedSingleOrderId')::int8
                   AND co2.chain_id = 0
                 LIMIT 1))::text
           ELSE NULL::text
           END           AS legorderid,
       co.order_id       AS _order_id,
       co.chain_id       AS _chain_id,
       co.db_create_time AS _db_create_time,
       max_rep._last_mod_time
FROM blaze7.client_order co
         join lateral ( select cl.order_id,
                               cl.chain_id
                        from blaze7.client_order cl
                        where cl.cl_ord_id::text = co.cl_ord_id::text
                        order by cl.chain_id desc
                        limit 1) ch
              on ch.order_id = co.order_id and ch.chain_id = co.chain_id
         left join blaze7.client_order_leg leg on leg.order_id = co.order_id and leg.chain_id = co.chain_id
         left join lateral ( select rep.db_create_time as _last_mod_time
                             from blaze7.order_report rep
                             where rep.order_id = co.order_id
                               and rep.chain_id = co.chain_id
                             order by db_create_time desc
                             limit 1) max_rep on true
         left join lateral ( SELECT co2.cl_ord_id
                             FROM blaze7.client_order co2
                             WHERE co2.cl_ord_id = co.payload ->> 'OrigClOrdId'
                             ORDER BY co2.chain_id DESC
                             LIMIT 1) orig on true
         left join lateral ( SELECT co2.payload ->> 'OrderCreationTime'::text as "OrderCreationTime"
                             FROM blaze7.client_order co2
                             WHERE co2.cl_ord_id::text = co.cl_ord_id::text
                               AND co2.chain_id = 0) f_chain on true
         left join lateral ( SELECT rep.payload ->> 'CumQty'       as "CumQty",
                                    rep.payload ->> 'AvgPx'        as "AvgPx",
                                    rep.payload ->> 'LeavesQty'    as "LeavesQty",
                                    rep.payload ->> 'CanceledQty'  as "CanceledQty",
                                    rep.payload ->> 'TransactTime' as "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                               AND coalesce(rep.leg_ref_id::text, 'leg_ref_id') =
                                   coalesce(leg.leg_ref_id::text, 'leg_ref_id')
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last_exec on true
         left join lateral ( SELECT rep.payload ->> 'CumQty'       as "CumQty",
                                    rep.payload ->> 'AvgPx'        as "AvgPx",
                                    rep.payload ->> 'LeavesQty'    as "LeavesQty",
                                    rep.payload ->> 'CanceledQty'  as "CanceledQty",
                                    rep.payload ->> 'TransactTime' as "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last on true
WHERE co.record_type in ('0', '2')
  and co.cl_ord_id = '3_559230815';

and co.db_create_time between to_timestamp(:date_id, 'YYYYMMDD')
  and to_timestamp(:date_id, 'YYYYMMDD') + interval '1 day';

-- 2383154
select *
 into staging.so_leg1
FROM blaze7.tlegs_edw3 as x
where x._db_create_time between to_timestamp(:date_id, 'YYYYMMDD')
  and to_timestamp(:date_id, 'YYYYMMDD') + interval '1 day';-- 2383154
select *
-- into staging.so_leg1
FROM blaze7.tlegs_edw3 as x
where x._db_create_time between to_timestamp(:date_id, 'YYYYMMDD')
  and to_timestamp(:date_id, 'YYYYMMDD') + interval '1 day';

select *
into staging.so_leg2
FROM blaze7.tlegs_edw2 as x
where x._db_create_time between to_timestamp(:date_id, 'YYYYMMDD')
  and to_timestamp(:date_id, 'YYYYMMDD') + interval '1 day';

select 'new', id, orderid, legrefid, price, legcount, legnumber, dashsecurityid, basecode, typecode, expirationdate, strike, side, ratio, multiplier, quantity, filled, invested, avgprice, stockquantity, stockopenquantity, stockfilled, stockcancelled, optionquantity, optionopenquantity, optionfilled, optioncancelled, mindatetime, maxdatetime, firstfilldatetime, lastfilldatetime, statuscode, timeinforcecode, openclose, systemid, orderidint, rootcode, prevfillquantity, stockprevfillquantity, optionprevfillquantity, legorderid, "_order_id", "_chain_id", "_db_create_time", "_last_mod_time"
    from staging.so_leg1
    where orderid = 'f_3_20t230815'
union all
select 'old', id, orderid, legrefid, price, legcount, legnumber, dashsecurityid, basecode, typecode, expirationdate, strike, side, ratio, multiplier, quantity, filled, invested, avgprice, stockquantity, stockopenquantity, stockfilled, stockcancelled, optionquantity, optionopenquantity, optionfilled, optioncancelled, mindatetime, maxdatetime, firstfilldatetime, lastfilldatetime, statuscode, timeinforcecode, openclose, systemid, orderidint, rootcode, prevfillquantity, stockprevfillquantity, optionprevfillquantity, legorderid, "_order_id", "_chain_id", "_db_create_time", "_last_mod_time"
from staging.so_leg2
where orderid = 'f_3_20t230815'


