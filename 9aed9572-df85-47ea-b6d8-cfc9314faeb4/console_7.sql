create index if not exists client_order_order_trade_date_idx on blaze7.client_order using btree (order_trade_date);

drop view if exists blaze7.torder_edw;
create or replace view blaze7.torder_edw
as
select null::text as id,
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
            ELSE ( SELECT rp.payload ->> 'BlazeOrderStatus'::text
               FROM blaze7.order_report rp
              WHERE rp.cl_ord_id::text = co.cl_ord_id::text AND rp.leg_ref_id IS NULL
              ORDER BY rp.exec_id DESC
             LIMIT 1)
        END AS status,
        CASE
            WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
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
    ( SELECT
                CASE
                    WHEN (rep.payload ->> 'OrderStatus'::text) = ANY (ARRAY['2'::text, '3'::text, '4'::text, '8'::text, 'P'::text, 'l'::text, '5'::text]) THEN rep.payload ->> 'TransactTime'::text
                    ELSE NULL::text
                END AS "case"
           FROM blaze7.order_report rep
          WHERE rep.leg_ref_id IS NULL AND rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS completeddatetime,
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
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN ( SELECT rep.payload ->> 'CumQty'::text
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
            WHEN (co.payload ->> 'SpreadType'::text) = '1'::text THEN ( SELECT rep.payload ->> 'CanceledQty'::text
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
            WHEN 'O'::bpchar THEN (co.payload ->> 'OrderQty'::text)::bigint
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
            WHEN co.instrument_type = ANY (ARRAY['O'::bpchar, 'E'::bpchar]) THEN (COALESCE((co.payload ->> 'ContractSize'::text)::integer, 1) *
            CASE co.payload ->> 'Side'::text
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
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Generation}'::text[]
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
    co.order_id AS _order_id,
    co.chain_id AS _chain_id,
    co.db_create_time AS _db_create_time,
    orig.db_create_time AS orig_db_create_time,
    rep_last_exec.db_create_time AS rep_db_create_time,
    co.order_trade_date as order_trade_date_id
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
  WHERE co.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar]);


drop VIEW blaze7.tlegs_edw;
CREATE OR REPLACE VIEW blaze7.tlegs_edw
AS SELECT NULL::text AS id,
    co.cl_ord_id AS orderid,
    COALESCE(leg.leg_ref_id, '0'::character varying) AS legrefid,
    COALESCE(
        CASE
            WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
            WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
            ELSE co.payload ->> 'Price'::text
        END, '0'::text) AS price,
    COALESCE(co.payload ->> 'NoLegs'::text, '1'::text) AS legcount,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'LegSeqNumber'::text
            ELSE '1'::text
        END AS legnumber,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END AS dashsecurityid,
    COALESCE("substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:EQ:(.+)'::text), "substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:[FO|OP]{2}:(.+)_'::text)) AS basecode,
        CASE
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = 'EQ'::text THEN 'S'::text
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, '[0-9]{6}(.)'::text)
            ELSE NULL::text
        END AS typecode,
        CASE
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN to_date("substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, '([0-9]{6})'::text), 'YYMMDD'::text)
            ELSE NULL::date
        END AS expirationdate,
        CASE
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, '[0-9]{6}.(.+)$'::text)::numeric
            ELSE NULL::numeric
        END AS strike,
        CASE
            WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'LegSide'::text
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'::text[]
            ELSE NULL::text
        END AS side,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'LegRatioQty'::text
            ELSE '1'::text
        END AS ratio,
    COALESCE(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'ContractSize'::text
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
            END)::numeric * rep_last."CumQty"::bigint::numeric / 10000.0 * rep_last."AvgPx"::bigint::numeric / 10000.0
            WHEN co.instrument_type = 'M'::bpchar THEN (COALESCE(leg.payload ->> 'ContractSize'::text, '1'::text)::integer *
            CASE leg.payload ->> 'LegSide'::text
                WHEN '1'::text THEN 1
                ELSE '-1'::integer
            END)::numeric * rep_last_exec."CumQty"::bigint::numeric / 10000.0 * rep_last_exec."AvgPx"::bigint::numeric / 10000.0
            ELSE NULL::numeric
        END AS invested,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN
            CASE
                WHEN (leg.payload ->> 'LegSide'::text) = '2'::text THEN '-1'::integer
                ELSE 1
            END * rep_last_exec."AvgPx"::bigint
            ELSE
            CASE
                WHEN co.crossing_side IS NULL AND (co.payload ->> 'Side'::text) = '2'::text THEN '-1'::integer
                WHEN co.crossing_side = 'O'::bpchar AND (co.payload #>> '{OriginatorOrder,Side}'::text[]) = '2'::text THEN '-1'::integer
                WHEN co.crossing_side = 'C'::bpchar AND (co.payload #>> '{ContraOrder,Side}'::text[]) = '2'::text THEN '-1'::integer
                ELSE 1
            END * rep_last."AvgPx"::bigint
        END::text AS avgprice,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text THEN leg.payload ->> 'LegQty'::text
            ELSE NULL::text
        END AS stockquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN rep_last."LeavesQty"
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text THEN rep_last_exec."LeavesQty"
            ELSE NULL::text
        END AS stockopenquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text THEN rep_last_exec."CumQty"
            ELSE NULL::text
        END AS stockfilled,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN rep_last."CanceledQty"
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text THEN rep_last_exec."CanceledQty"
            ELSE NULL::text
        END AS stockcancelled,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN co.payload ->> 'OrderQty'::text
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text THEN leg.payload ->> 'LegQty'::text
            ELSE NULL::text
        END AS optionquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN rep_last."LeavesQty"
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text THEN rep_last_exec."LeavesQty"
            ELSE NULL::text
        END AS optionopenquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN rep_last."CumQty"
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text THEN rep_last_exec."CumQty"
            ELSE NULL::text
        END AS optionfilled,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN rep_last."CanceledQty"
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text THEN rep_last_exec."CanceledQty"
            ELSE NULL::text
        END AS optioncancelled,
        CASE
            WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
            ELSE f_chain."OrderCreationTime"
        END AS mindatetime,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN rep_last_exec."TransactTime"
            ELSE rep_last."TransactTime"
        END AS maxdatetime,
        CASE
            WHEN co.instrument_type <> 'M'::bpchar THEN ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
              ORDER BY rep.exec_id
             LIMIT 1)
            ELSE ( SELECT rep.payload ->> 'TransactTime'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = leg.leg_ref_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
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
              WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND rep.leg_ref_id::text = leg.leg_ref_id::text AND (rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
              ORDER BY rep.exec_id DESC
             LIMIT 1)
        END AS lastfilldatetime,
        CASE
            WHEN COALESCE(co.payload ->> 'LinkedStageOrderId'::text, co.payload #>> '{OriginatorOrder,LinkedStageOrderId}'::text[], co.payload #>> '{ContraOrder,LinkedStageOrderId}'::text[]) IS NOT NULL THEN 'T'::text
            ELSE ( SELECT rp.payload ->> 'BlazeOrderStatus'::text
               FROM blaze7.order_report rp
              WHERE rp.cl_ord_id::text = co.cl_ord_id::text AND
                    CASE
                        WHEN co.instrument_type = 'M'::bpchar THEN rp.leg_ref_id::text = leg.leg_ref_id::text
                        ELSE true
                    END
              ORDER BY rp.exec_id DESC
             LIMIT 1)
        END AS statuscode,
    co.payload ->> 'TimeInForce'::text AS timeinforcecode,
        CASE
            WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'PositionEffect'::text
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,PositionEffect}'::text[]
            ELSE NULL::text
        END AS openclose,
    NULL::text AS systemid,
    NULL::text AS orderidint,
    COALESCE("substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:EQ:(.+)'::text), "substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:[FO|OP]{2}:(.+)_'::text)) AS rootcode,
        CASE
            WHEN (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = orig.cl_ord_id::text AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text = COALESCE(leg.leg_ref_id, 'leg_ref_id'::character varying)::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS prevfillquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar OR co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text AND (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = orig.cl_ord_id::text AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text = COALESCE(leg.leg_ref_id, 'leg_ref_id'::character varying)::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS stockprevfillquantity,
        CASE
            WHEN co.instrument_type = 'O'::bpchar OR co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text AND (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN ( SELECT rep.payload ->> 'CumQty'::text
               FROM blaze7.order_report rep
              WHERE rep.cl_ord_id::text = orig.cl_ord_id::text AND NOT rep.leg_ref_id::text IS DISTINCT FROM leg.leg_ref_id::text
              ORDER BY rep.exec_id DESC
             LIMIT 1)
            ELSE NULL::text
        END AS optionprevfillquantity,
        CASE
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'StitchedSingleOrderId'::text) IS NOT NULL THEN (( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = ((leg.payload ->> 'StitchedSingleOrderId'::text)::bigint) AND co2.chain_id = 0
             LIMIT 1))::text
            ELSE NULL::text
        END AS legorderid,
    co.order_id AS _order_id,
    co.chain_id AS _chain_id,
    co.db_create_time AS _db_create_time,
    max_rep._last_mod_time,
    co.order_trade_date as order_trade_date_id
   FROM blaze7.client_order co
     JOIN LATERAL ( SELECT cl.order_id,
            cl.chain_id
           FROM blaze7.client_order cl
          WHERE cl.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY cl.chain_id DESC
         LIMIT 1) ch ON ch.order_id = co.order_id AND ch.chain_id = co.chain_id
     LEFT JOIN blaze7.client_order_leg leg ON leg.order_id = co.order_id AND leg.chain_id = co.chain_id
     LEFT JOIN LATERAL ( SELECT rep.db_create_time AS _last_mod_time
           FROM blaze7.order_report rep
          WHERE rep.order_id = co.order_id AND rep.chain_id = co.chain_id
          ORDER BY rep.db_create_time DESC
         LIMIT 1) max_rep ON true
     LEFT JOIN LATERAL ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
          ORDER BY co2.chain_id DESC
         LIMIT 1) orig ON true
     LEFT JOIN LATERAL ( SELECT co2.payload ->> 'OrderCreationTime'::text AS "OrderCreationTime"
           FROM blaze7.client_order co2
          WHERE co2.cl_ord_id::text = co.cl_ord_id::text AND co2.chain_id = 0) f_chain ON true
     LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text AS "CumQty",
            rep.payload ->> 'AvgPx'::text AS "AvgPx",
            rep.payload ->> 'LeavesQty'::text AS "LeavesQty",
            rep.payload ->> 'CanceledQty'::text AS "CanceledQty",
            rep.payload ->> 'TransactTime'::text AS "TransactTime"
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text AND COALESCE(rep.leg_ref_id::text, 'leg_ref_id'::text) = COALESCE(leg.leg_ref_id::text, 'leg_ref_id'::text)
          ORDER BY rep.exec_id DESC
         LIMIT 1) rep_last_exec ON true
     LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text AS "CumQty",
            rep.payload ->> 'AvgPx'::text AS "AvgPx",
            rep.payload ->> 'LeavesQty'::text AS "LeavesQty",
            rep.payload ->> 'CanceledQty'::text AS "CanceledQty",
            rep.payload ->> 'TransactTime'::text AS "TransactTime"
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) rep_last ON true
  WHERE co.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar]);


drop VIEW blaze7.tordermisc1_edw;
CREATE OR REPLACE VIEW blaze7.tordermisc1_edw
AS SELECT NULL::text AS id,
    co.cl_ord_id AS orderid,
    NULL::text AS systemid,
    NULL::text AS client,
    NULL::text AS trader,
    NULL::text AS isctboverridden,
    NULL::text AS stockquantity,
    NULL::text AS stockprice,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,Commission2}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,Commission2}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,Commission2}'::text[]
            ELSE NULL::text
        END AS acctcomm,
    NULL::text AS issplitprice,
    NULL::text AS post,
    NULL::text AS station,
    co.payload ->> 'IsCboeSPXCombo'::text AS isspxcombo,
    NULL::text AS exttts,
    NULL::text AS nocoa,
    NULL::text AS branchcode,
    NULL::text AS executionfirmoverride,
    NULL::text AS execsequence,
    NULL::text AS rejectorderid,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,FTID}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,FTID}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,FTID}'::text[]
            ELSE NULL::text
        END AS ftid,
    co.payload ->> 'ExecInst'::text AS execinst,
    NULL::text AS handling,
    COALESCE(co.secondary_order_id, co.order_id) AS ultransaction64,
    NULL::text AS isautoqctchild,
    NULL::text AS autoqctorderid,
    co.payload ->> 'CrossingMechanism'::text AS crossingtypeid,
    NULL::text AS stoplimit,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'CATOrderId'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATOrderId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATOrderId}'::text[]
            ELSE NULL::text
        END AS catid,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,DashAliasId}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,DashAliasId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,DashAliasId}'::text[]
            ELSE NULL::text
        END AS dashaliasid,
    co.payload #>> '{AlgoDetails,MinQty}'::text[] AS minquantity,
    co.payload #>> '{AlgoDetails,MinQty}'::text[] AS mindisplayqty,
    co.payload #>> '{AlgoDetails,DashMaxFloor}'::text[] AS maxdisplayqty,
        CASE
            WHEN co.crossing_side IS NULL AND (co.payload ->> 'InitiatorUserId'::text) <> (co.payload #>> '{ClearingDetails,CustomerUserId}'::text[]) THEN co.payload ->> 'CustomerUserId'::text
            WHEN co.crossing_side = 'O'::bpchar AND (co.payload ->> 'InitiatorUserId'::text) <> (co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]) THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar AND (co.payload ->> 'InitiatorUserId'::text) <> (co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]) THEN co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]
            ELSE NULL::text
        END AS obouser,
    co.payload ->> 'StockFloorBroker'::text AS stockfloorbroker,
        CASE
            WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,FDID}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,FDID}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,FDID}'::text[]
            ELSE NULL::text
        END AS fdid,
        CASE
            WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,IMID}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,IMID}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,IMID}'::text[]
            ELSE NULL::text
        END AS senderimid,
        CASE
            WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,AffiliateFlag}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,AffiliateFlag}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,AffiliateFlag}'::text[]
            ELSE NULL::text
        END AS affiliateflag,
        CASE
            WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,AccountHolderType}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,AccountHolderType}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,AccountHolderType}'::text[]
            ELSE NULL::text
        END AS accountholdertype,
        CASE
            WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,BrokerDealer}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,BrokerDealer}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,BrokerDealer}'::text[]
            ELSE NULL::text
        END AS brokerdealer,
        CASE
            WHEN co.crossing_side IS NULL AND co.orig_order_id IS NOT NULL THEN ( SELECT co2.payload ->> 'OrderReceiveTime'::text
               FROM blaze7.client_order co2
              WHERE co2.cl_ord_id::text = co.cl_ord_id::text AND co2.chain_id = 0
             LIMIT 1)
            WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL THEN co.big_payload ->> 'OrderReceiveTime'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderReceiveTime}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderReceiveTime}'::text[]
            ELSE NULL::text
        END AS receivetime,
    ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.order_id = COALESCE(
                CASE
                    WHEN co.crossing_side IS NULL THEN co.payload ->> 'ResendOrderId'::text
                    WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ResendOrderId}'::text[]
                    WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ResendOrderId}'::text[]
                    ELSE NULL::text
                END, '0'::text)::bigint
          ORDER BY co.chain_id DESC
         LIMIT 1) AS resendparentid,
    COALESCE(co.payload ->> 'IsRepresentative'::text, co.payload #>> '{OriginatorOrder,IsRepresentative}'::text[], co.payload #>> '{ContraOrder,IsRepresentative}'::text[], 'N'::text) AS representative,
        CASE co.order_class
            WHEN 'F'::bpchar THEN ( SELECT co2.payload ->> 'ExtClOrdId'::text
               FROM blaze7.client_order co2
              WHERE co2.orig_order_id = co.order_id AND co2.record_type = '1'::bpchar AND co2.order_class = 'F'::bpchar
              ORDER BY co2.order_id
             LIMIT 1)
            ELSE NULL::text
        END AS cxlclordid,
    co.payload ->> 'OrderExpireDate'::text AS goodtilldate,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,ActionableId}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,ActionableId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,ActionableId}'::text[]
            ELSE NULL::text
        END AS actionid,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SocGenSalesTrader}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,SocGenSalesTrader}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,SocGenSalesTrader}'::text[]
            ELSE NULL::text
        END AS sales_traders,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'ExtClOrdId'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ExtClOrdId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ExtClOrdId}'::text[]
            ELSE NULL::text
        END AS fixclordid,
    co.payload #>> '{AlgoDetails,DashOptionRefPrice}'::text[] AS optionrefprice,
    co.payload #>> '{AlgoDetails,DashStockRefPrice}'::text[] AS stockrefprice,
    COALESCE(((co.payload #>> '{AlgoDetails,DashWorkingDelta2}'::text[])::numeric) / 10000.0, (co.payload #>> '{AlgoDetails,DashWorkingDelta}'::text[])::numeric)::text AS workingdelta,
    co.parent_order_id AS intparentorderid,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'CATParentOrderId'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATParentOrderId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATParentOrderId}'::text[]
            ELSE NULL::text
        END AS catparentid,
        CASE
            WHEN co.order_class = 'F'::bpchar THEN co.payload ->> 'OrderSource'::text
            ELSE NULL::text
        END AS ordersource,
        CASE
            WHEN co.order_class = 'O'::bpchar AND co.crossing_side IS NULL THEN co.payload ->> 'OrderRefId'::text
            WHEN co.order_class = 'O'::bpchar AND co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderRefId}'::text[]
            WHEN co.order_class = 'O'::bpchar AND co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderRefId}'::text[]
            ELSE NULL::text
        END AS oboorderrefid,
    co.payload ->> 'OwnerEntityId'::text AS ownercompanyid,
    co.payload ->> 'CrossId'::text AS systemcrossid,
    co.cross_order_id AS transaction64crossorderid,
    ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co.orig_order_id IS NULL AND co2.chain_id = 0 AND co2.order_id = COALESCE(co.big_payload ->> 'RepresentativeOrderId'::text, co.big_payload #>> '{OriginatorOrder,RepresentativeOrderId}'::text[], co.big_payload #>> '{ContraOrder,RepresentativeOrderId}'::text[], '-1'::text)::bigint) AS representativeorderid,
    NULL::text AS catupdate,
        CASE
            WHEN co.orig_order_id IS NOT NULL THEN '0'::text
            WHEN COALESCE(co.big_payload ->> 'HasRepresentedOrders'::text, co.big_payload #>> '{OriginatorOrder,HasRepresentedOrders}'::text[], co.big_payload #>> '{ContraOrder,HasRepresentedOrders}'::text[]) = 'Y'::text THEN '1'::text
            ELSE '0'::text
        END AS hasrepresentedorder,
    co.payload #>> '{AlgoDetails,CBOESessionEligibility}'::text[] AS cboesessioneligibility,
    (co.payload #>> '{AlgoDetails,DashImpliedVolatility}'::text[])::numeric AS impliedvolatility,
    ((co.payload ->> 'IsCabinet'::text))::character(1)::text AS cabinet,
    (co.payload ->> 'ParentCrossOrderId'::text)::bigint AS transaction64parentcrossorderid,
        CASE
            WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL THEN co.big_payload #>> '{OrderCallTime}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderCallTime}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderCallTime}'::text[]
            ELSE NULL::text
        END::timestamp without time zone AS calltime,
        CASE
            WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL THEN co.big_payload #>> '{CATDetails,CATElectronicOrderId}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,CATElectronicOrderId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,CATElectronicOrderId}'::text[]
            ELSE NULL::text
        END AS electronicorderid,
        CASE
            WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL THEN co.big_payload #>> '{CATDetails,CATElectronicOrderTime}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,CATElectronicOrderTime}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,CATElectronicOrderTime}'::text[]
            ELSE NULL::text
        END::timestamp without time zone AS electronicordertime,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,ClientInfo}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,ClientInfo}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,ClientInfo}'::text[]
            ELSE NULL::text
        END AS clientinfo,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{OrderEventTime}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderEventTime}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderEventTime}'::text[]
            ELSE NULL::text
        END AS ordereventtime,
    co.order_id AS _order_id,
    co.chain_id AS _chain_id,
    co.db_create_time AS _db_create_time,
    staging.get_max_db_create_time(co.order_id, co.db_create_time::date, co.chain_id) AS _last_mod_time,
        CASE
            WHEN co.is_q_time THEN staging.get_timestamp_from_date_ts(co.order_trade_date, co.q_time)
            ELSE NULL::timestamp without time zone
        END AS boxqooannouncedtime,
        CASE
            WHEN co.route_destination::text = 'BOX QOO'::text THEN co.payload #>> '{BoxQOOAnnouncedTime}'::text[]
            ELSE NULL::text
        END AS boxqooannouncedtimev2,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{OrderNotes}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderNotes}'::text[]
            ELSE NULL::text
        END AS ordernotes,
    co.payload ->> 'CboeEquityBroker'::text AS cboeequitybroker,
    co.order_trade_date_id
   FROM ( SELECT DISTINCT ON (cl.cl_ord_id) cl.order_id,
            cl.chain_id,
            cl.parent_order_id,
            cl.orig_order_id,
            cl.record_type,
            cl.payload,
            cl.db_create_time,
            cl.cl_ord_id,
            cl.crossing_side,
            cl.order_class,
            cl.secondary_order_id,
            cl.cross_order_id,
            cl.route_destination,
            big.payload AS big_payload,
                CASE
                    WHEN cl.route_destination::text = 'BOX QOO'::text AND (cl.payload ->> 'IsFlex'::text) = 'Y'::text THEN true
                    ELSE false
                END AS is_q_time,
            cl.order_trade_date::integer AS order_trade_date,
                CASE
                    WHEN cl.route_destination::text = 'BOX QOO'::text AND (cl.payload ->> 'IsFlex'::text) = 'Y'::text THEN
                    CASE
                        WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                        WHEN cl.crossing_side = 'C'::bpchar THEN ( SELECT co2.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                           FROM blaze7.client_order co2
                          WHERE co2.cross_order_id = cl.cross_order_id AND co2.crossing_side = 'O'::bpchar
                          ORDER BY co2.chain_id DESC
                         LIMIT 1)
                        ELSE NULL::text
                    END
                    ELSE NULL::text
                END AS q_time,
              cl.order_trade_date as order_trade_date_id
           FROM blaze7.client_order cl
             LEFT JOIN LATERAL ( SELECT co2.payload
                   FROM blaze7.client_order co2
                  WHERE co2.order_id = cl.order_id
                  ORDER BY co2.chain_id DESC
                 LIMIT 1) big ON true
          WHERE true AND (cl.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar]))
          ORDER BY cl.cl_ord_id, cl.chain_id DESC) co;