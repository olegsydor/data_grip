create view blaze7.v_away_trade as
SELECT
    -- TReport
    rep.payload ->> 'ManualExecutionTime'::text                                              AS manualexecutiontime,
    rep.payload ->> 'TransactTime'::text                                                     AS transactiondatetime,
    CASE
        WHEN rep.exec_type = ANY (ARRAY ['e'::bpchar, 'd'::bpchar]) THEN (SELECT CASE
                                                                                     WHEN rp.exec_type = '4'::bpchar AND
                                                                                          (rp.payload ->> 'OriginatedBy'::text) =
                                                                                          'E'::text THEN 'F'::bpchar
                                                                                     ELSE rp.exec_type
                                                                                     END AS exec_type
                                                                          FROM blaze7.order_report rp
                                                                          WHERE rp.exec_id::text = (rep.payload ->> 'ChildExecRefId'::text))
        WHEN rep.exec_type = '4'::bpchar AND (rep.payload ->> 'OriginatedBy'::text) = 'E'::text THEN 'F'::bpchar
        ELSE rep.exec_type
        END                                                                                  AS status,
    CASE
        WHEN co.order_class = 'F'::bpchar THEN co.payload ->> 'InitiatorUserId'::text
        WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientUserId'::text
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClientUserId}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClientUserId}'::text[]
        ELSE NULL::text
        END                                                                                  AS userid,
    rep.payload ->> 'LiquidityType'::text                                                    AS liquiditytype,
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
        END                                                                                  AS securitytype,
    NULL::text                                                                               AS handling,
    CASE
        WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegSeqNumber'::text
                                              FROM blaze7.client_order_leg leg
                                              WHERE leg.order_id = rep.order_id
                                                AND leg.chain_id = rep.chain_id
                                                AND leg.leg_ref_id::text = rep.leg_ref_id::text)
        ELSE '1'::text
        END                                                                                  AS legnumber,
    rep.cl_ord_id                                                                            AS orderid,
    rep.exec_id                                                                              as reportid,
    COALESCE(rep.payload ->> 'ChildExecRefId'::text, rep.exec_id::text)                      AS childreportid,
    CASE
        WHEN rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar, 'r'::bpchar]) THEN COALESCE(
                ((rep.payload ->> 'LastPx2'::text)::bigint)::numeric / 10000.0,
                ((rep.payload ->> 'LastPx'::text)::bigint)::numeric / 1.0)::text
        ELSE '0'::text
        END                                                                                  AS lastprice,
    rep.order_id,
    rep.chain_id,
    -------------- TOrder
    COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                                       AS legcount,
    CASE
        WHEN co.route_destination::text = 'VEGA'::text THEN 'VEGA'::bpchar
        WHEN (co.payload ->> 'HasStitchedOrders'::text) = 'Y'::text THEN 'StitchedSingle'::bpchar
        WHEN COALESCE(co.payload ->> 'IsStitched'::text, co.payload #>> '{OriginatorOrder,IsStitched}'::text[]) = 'Y'::text
            THEN 'StitchedSpread'::bpchar
        WHEN co.order_class = ANY (ARRAY ['I'::bpchar, 'X'::bpchar]) THEN 'G'::bpchar
        ELSE co.order_class
        END                                                                                  AS systemordertypeid,
    co.payload ->> 'TimeInForce'::text                                                       AS timeinforcecode,
    CASE
        WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,OptionRange}'::text[]
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'::text[]
        ELSE NULL::text
        END                                                                                  AS forwhom,
    CASE
        WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,GiveUp}'::text[]
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'::text[]
        ELSE NULL::text
        END                                                                                  AS giveupfirm,
    CASE
        WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'::text[]
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'::text[]
        ELSE NULL::text
        END                                                                                  AS cmtafirm,
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
        END                                                                                  AS origorderid,
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
        END                                                                                  AS contraorderid,
    CASE
        WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                  FROM blaze7.client_order co2
                                                  WHERE co2.order_id = co.parent_order_id
                                                  ORDER BY co2.chain_id DESC
                                                  LIMIT 1)
        ELSE NULL::character varying
        END                                                                                  AS parentorderid,
    (SELECT rep.payload ->> 'NoChildren'::text
     FROM blaze7.order_report rep
     WHERE rep.cl_ord_id::text = co.cl_ord_id::text
     ORDER BY rep.exec_id DESC
     LIMIT 1)                                                                                AS childorders,
    co.payload ->> 'OrderTextComment'::text                                                  AS comment,
    co.payload ->> 'ProductDescription'::text                                                AS contractdesc,
    CASE
        WHEN co.crossing_side IS NULL THEN co.payload ->> 'AccountAlias'::text
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,AccountAlias}'::text[]
        ELSE NULL::text
        END                                                                                  AS accountalias,
    CASE
        WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Generation}'::text[]
        ELSE NULL::text
        END                                                                                  AS generation,
    -- LEGS
    CASE co.instrument_type
        WHEN 'M'::bpchar THEN leg.payload ->> 'LegSeqNumber'::text
        ELSE '1'::text
        END                                                                                  AS leg_legnumber,
    CASE
        WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'LegSide'::text
        WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'::text
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'::text[]
        ELSE NULL::text
        END                                                                                  AS side,
    CASE
        WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'PositionEffect'::text
        WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'::text
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,PositionEffect}'::text[]
        ELSE NULL::text
        END                                                                                  AS openclose,
    CASE
        WHEN "substring"(
                     CASE co.instrument_type
                         WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                         ELSE co.payload ->> 'DashSecurityId'::text
                         END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text]) THEN to_date(
                "substring"(
                        CASE co.instrument_type
                            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                            ELSE co.payload ->> 'DashSecurityId'::text
                            END, '([0-9]{6})'::text), 'YYMMDD'::text)
        ELSE NULL::date
        END                                                                                  AS expirationdate,
    CASE
        WHEN "substring"(
                     CASE co.instrument_type
                         WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                         ELSE co.payload ->> 'DashSecurityId'::text
                         END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text]) THEN "substring"(
                CASE co.instrument_type
                    WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                    ELSE co.payload ->> 'DashSecurityId'::text
                    END, '[0-9]{6}.(.+)$'::text)::numeric
        ELSE NULL::numeric
        END                                                                                  AS strike,
    CASE
        WHEN co.instrument_type = 'O'::bpchar THEN co.payload ->> 'OrderQty'::text
        WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
            THEN leg.payload ->> 'LegQty'::text
        ELSE NULL::text
        END                                                                                  AS optionquantity,
    CASE
        WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
        WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
            THEN leg.payload ->> 'LegQty'::text
        ELSE NULL::text
        END                                                                                  AS stockquantity,
    COALESCE(co.payload ->> 'DashTargetVega'::text, co.payload ->> 'OrderQty'::text)         AS quantity,
    COALESCE(
            CASE
                WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
                WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
                WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
                WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
                ELSE co.payload ->> 'Price'::text
                END, '0'::text)                                                              AS price,
    COALESCE("substring"(
                     CASE co.instrument_type
                         WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                         ELSE co.payload ->> 'DashSecurityId'::text
                         END, 'US:EQ:(.+)'::text), "substring"(
                     CASE co.instrument_type
                         WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                         ELSE co.payload ->> 'DashSecurityId'::text
                         END, 'US:[FO|OP]{2}:(.+)_'::text))                                  AS basecode,
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
                         END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text]) THEN "substring"(
                CASE co.instrument_type
                    WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                    ELSE co.payload ->> 'DashSecurityId'::text
                    END, '[0-9]{6}(.)'::text)
        ELSE NULL::text
        END                                                                                  AS typecode,
    COALESCE("substring"(
                     CASE co.instrument_type
                         WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                         ELSE co.payload ->> 'DashSecurityId'::text
                         END, 'US:EQ:(.+)'::text), "substring"(
                     CASE co.instrument_type
                         WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                         ELSE co.payload ->> 'DashSecurityId'::text
                         END, 'US:[FO|OP]{2}:(.+)_'::text))                                  AS rootcode,
    -- TOrdermisc1                         
    CASE
        WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,DashAliasId}'::text[]
        WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,DashAliasId}'::text[]
        WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,DashAliasId}'::text[]
        ELSE NULL::text
        END                                                                                  AS dashaliasid
--------------------------------------------------
FROM blaze7.order_report rep
         JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
         LEFT JOIN blaze7.client_order_leg leg ON leg.order_id = co.order_id AND leg.chain_id = co.chain_id
WHERE rep.multileg_reporting_type <> '3'::bpchar
  AND (co.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
  AND (rep.exec_type::text <> ALL (ARRAY ['f'::text, 'w'::text, 'W'::text, 'g'::text, 'G'::text, 'I'::text, 'i'::text]));

SELECT manualexecutiontime,
       transactiondatetime,
       status,
       userid,
       liquiditytype,
       liquidityindicator,
       exchangemappedorderid,
       orderreportspecialtype,
       exchangetransactionid,
       exdestination,
       lastshares,
       executingbroker,
       contrabroker,
       leavesqty,
       parentid,
       securitytype,
       handling,
       legnumber,
       orderid,
       reportid,
       childreportid,
       lastprice,
       order_id,
       chain_id,
       legcount,
       systemordertypeid,
       timeinforcecode,
       forwhom,
       giveupfirm,
       cmtafirm,
       origorderid,
       contraorderid,
       parentorderid,
       childorders,
       comment,
       contractdesc,
       accountalias,
       generation,
       side,
       openclose,
       expirationdate,
       strike,
       optionquantity,
       stockquantity,
       quantity,
       price,
       basecode,
       typecode,
       rootcode,
       dashaliasid
FROM blaze7.v_away_trade
WHERE ((reportid > 'jj4rji9s0000'))