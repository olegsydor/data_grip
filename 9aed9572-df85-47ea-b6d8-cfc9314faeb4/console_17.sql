-- blaze7.treports_edw source
drop view blaze7.treports_edw;
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
       CASE
           WHEN x.order_class = 'F'::bpchar THEN x.payload ->> 'InitiatorUserId'::text
           WHEN x.crossing_side IS NULL THEN x.payload ->> 'ClientUserId'::text
           WHEN x.crossing_side = 'O'::bpchar THEN x.payload #>> '{OriginatorOrder,ClientUserId}'::text[]
           WHEN x.crossing_side = 'C'::bpchar THEN x.payload #>> '{ContraOrder,ClientUserId}'::text[]
           ELSE NULL::text
           END                                                                                AS userid,
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
           WHEN (x.rep_payload ->> 'OrderReportSpecialType'::text) = any (array ['M'::text, 'A'::text])
               THEN x.rep_payload ->> 'OrderReportSpecialType'
           else null::text
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
       x.rep_payload ->> 'ManualDoNotReportCAT'                                               as manualdonotreportcat,
       case
           when x.exec_type = any (array ['1', '2']) then x.rep_payload ->> 'LastFillTime'
           end                                                                                as lastfilltime,
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


-- blaze7.tordermisc1_edw source
drop VIEW blaze7.tordermisc1_edw;
CREATE OR REPLACE VIEW blaze7.tordermisc1_edw
AS
SELECT NULL::text                                                                         AS id,
       co.cl_ord_id                                                                       AS orderid,
       NULL::text                                                                         AS systemid,
       NULL::text                                                                         AS client,
       NULL::text                                                                         AS trader,
       NULL::text                                                                         AS isctboverridden,
       NULL::text                                                                         AS stockquantity,
       NULL::text                                                                         AS stockprice,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,Commission2}'::text[]
           WHEN co.crossing_side = 'O'::bpchar
               THEN co.payload #>> '{OriginatorOrder,ClearingDetails,Commission2}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,Commission2}'::text[]
           ELSE NULL::text
           END                                                                            AS acctcomm,
       NULL::text                                                                         AS issplitprice,
       NULL::text                                                                         AS post,
       NULL::text                                                                         AS station,
       co.payload ->> 'IsCboeSPXCombo'::text                                              AS isspxcombo,
       NULL::text                                                                         AS exttts,
       NULL::text                                                                         AS nocoa,
       NULL::text                                                                         AS branchcode,
       NULL::text                                                                         AS executionfirmoverride,
       NULL::text                                                                         AS execsequence,
       NULL::text                                                                         AS rejectorderid,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,FTID}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,FTID}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,FTID}'::text[]
           ELSE NULL::text
           END                                                                            AS ftid,
       co.payload ->> 'ExecInst'::text                                                    AS execinst,
       NULL::text                                                                         AS handling,
       COALESCE(co.secondary_order_id, co.order_id)                                       AS ultransaction64,
       NULL::text                                                                         AS isautoqctchild,
       NULL::text                                                                         AS autoqctorderid,
       co.payload ->> 'CrossingMechanism'::text                                           AS crossingtypeid,
       co.payload ->> 'StopPx'::text                                                      AS stoplimit,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'CATOrderId'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATOrderId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATOrderId}'::text[]
           ELSE NULL::text
           END                                                                            AS catid,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,DashAliasId}'::text[]
           WHEN co.crossing_side = 'O'::bpchar
               THEN co.payload #>> '{OriginatorOrder,ClearingDetails,DashAliasId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,DashAliasId}'::text[]
           ELSE NULL::text
           END                                                                            AS dashaliasid,
       co.payload #>> '{AlgoDetails,MinQty}'::text[]                                      AS minquantity,
       co.payload #>> '{AlgoDetails,MinQty}'::text[]                                      AS mindisplayqty,
       co.payload #>> '{AlgoDetails,DashMaxFloor}'::text[]                                AS maxdisplayqty,
       CASE
           WHEN co.crossing_side IS NULL AND
                (co.payload ->> 'InitiatorUserId'::text) <> (co.payload #>> '{ClearingDetails,CustomerUserId}'::text[])
               THEN co.payload #>> '{ClearingDetails,CustomerUserId}'::text[]
           WHEN co.crossing_side = 'O'::bpchar AND (co.payload ->> 'InitiatorUserId'::text) <> (co.payload #>>
                                                                                                '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[])
               THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar AND (co.payload ->> 'InitiatorUserId'::text) <>
                                                   (co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[])
               THEN co.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]
           ELSE NULL::text
           END                                                                            AS obouser,
       co.payload ->> 'StockFloorBroker'::text                                            AS stockfloorbroker,
       CASE
           WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,FDID}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,FDID}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,FDID}'::text[]
           ELSE NULL::text
           END                                                                            AS fdid,
       CASE
           WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,IMID}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,IMID}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,IMID}'::text[]
           ELSE NULL::text
           END                                                                            AS senderimid,
       CASE
           WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,AffiliateFlag}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,AffiliateFlag}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,AffiliateFlag}'::text[]
           ELSE NULL::text
           END                                                                            AS affiliateflag,
       CASE
           WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,AccountHolderType}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,CATDetails,AccountHolderType}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,AccountHolderType}'::text[]
           ELSE NULL::text
           END                                                                            AS accountholdertype,
       CASE
           WHEN co.crossing_side IS NULL THEN co.big_payload #>> '{CATDetails,BrokerDealer}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATDetails,BrokerDealer}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATDetails,BrokerDealer}'::text[]
           ELSE NULL::text
           END                                                                            AS brokerdealer,
       CASE
           WHEN co.crossing_side IS NULL AND co.orig_order_id IS NOT NULL
               THEN (SELECT co2.payload ->> 'OrderReceiveTime'::text
                     FROM blaze7.client_order co2
                     WHERE co2.cl_ord_id::text = co.cl_ord_id::text
                       AND co2.chain_id = 0
                     LIMIT 1)
           WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL THEN co.big_payload ->> 'OrderReceiveTime'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderReceiveTime}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderReceiveTime}'::text[]
           ELSE NULL::text
           END                                                                            AS receivetime,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.order_id = COALESCE(
                CASE
                    WHEN co.crossing_side IS NULL THEN co.payload ->> 'ResendOrderId'::text
                    WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ResendOrderId}'::text[]
                    WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ResendOrderId}'::text[]
                    ELSE NULL::text
                    END, '0'::text)::bigint
        ORDER BY co.chain_id DESC
        LIMIT 1)                                                                          AS resendparentid,
       COALESCE(co.payload ->> 'IsRepresentative'::text, co.payload #>> '{OriginatorOrder,IsRepresentative}'::text[],
                co.payload #>> '{ContraOrder,IsRepresentative}'::text[], 'N'::text)       AS representative,
       CASE co.order_class
           WHEN 'F'::bpchar THEN (SELECT co2.payload ->> 'ExtClOrdId'::text
                                  FROM blaze7.client_order co2
                                  WHERE co2.orig_order_id = co.order_id
                                    AND co2.record_type = '1'::bpchar
                                    AND co2.order_class = 'F'::bpchar
                                  ORDER BY co2.order_id
                                  LIMIT 1)
           ELSE NULL::text
           END                                                                            AS cxlclordid,
       co.payload ->> 'OrderExpireDate'::text                                             AS goodtilldate,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,ActionableId}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,ClearingDetails,ActionableId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,ActionableId}'::text[]
           ELSE NULL::text
           END                                                                            AS actionid,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,SocGenSalesTrader}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,ClearingDetails,SocGenSalesTrader}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>>
                                                    '{ContraOrder,ClearingDetails,SocGenSalesTrader}'::text[]
           ELSE NULL::text
           END                                                                            AS sales_traders,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'ExtClOrdId'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ExtClOrdId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ExtClOrdId}'::text[]
           ELSE NULL::text
           END                                                                            AS fixclordid,
       co.payload #>> '{AlgoDetails,DashOptionRefPrice}'::text[]                          AS optionrefprice,
       co.payload #>> '{AlgoDetails,DashStockRefPrice}'::text[]                           AS stockrefprice,
       COALESCE(((co.payload #>> '{AlgoDetails,DashWorkingDelta2}'::text[])::numeric) / 10000.0,
                (co.payload #>> '{AlgoDetails,DashWorkingDelta}'::text[])::numeric)::text AS workingdelta,
       co.parent_order_id                                                                 AS intparentorderid,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'CATParentOrderId'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,CATParentOrderId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,CATParentOrderId}'::text[]
           ELSE NULL::text
           END                                                                            AS catparentid,
       CASE
           WHEN co.order_class = 'F'::bpchar THEN co.payload ->> 'OrderSource'::text
           ELSE NULL::text
           END                                                                            AS ordersource,
       CASE
           WHEN co.order_class = 'O'::bpchar AND co.crossing_side IS NULL THEN co.payload ->> 'OrderRefId'::text
           WHEN co.order_class = 'O'::bpchar AND co.crossing_side = 'O'::bpchar
               THEN co.payload #>> '{OriginatorOrder,OrderRefId}'::text[]
           WHEN co.order_class = 'O'::bpchar AND co.crossing_side = 'C'::bpchar
               THEN co.payload #>> '{ContraOrder,OrderRefId}'::text[]
           ELSE NULL::text
           END                                                                            AS oboorderrefid,
       co.payload ->> 'OwnerEntityId'::text                                               AS ownercompanyid,
       co.payload ->> 'CrossId'::text                                                     AS systemcrossid,
       co.cross_order_id                                                                  AS transaction64crossorderid,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co.orig_order_id IS NULL
          AND co2.chain_id = 0
          AND co2.order_id = COALESCE(co.big_payload ->> 'RepresentativeOrderId'::text,
                                      co.big_payload #>> '{OriginatorOrder,RepresentativeOrderId}'::text[],
                                      co.big_payload #>> '{ContraOrder,RepresentativeOrderId}'::text[],
                                      '-1'::text)::bigint)                                AS representativeorderid,
       NULL::text                                                                         AS catupdate,
       CASE
           WHEN co.orig_order_id IS NOT NULL THEN '0'::text
           WHEN COALESCE(co.big_payload ->> 'HasRepresentedOrders'::text,
                         co.big_payload #>> '{OriginatorOrder,HasRepresentedOrders}'::text[],
                         co.big_payload #>> '{ContraOrder,HasRepresentedOrders}'::text[]) = 'Y'::text THEN '1'::text
           ELSE '0'::text
           END                                                                            AS hasrepresentedorder,
       co.payload #>> '{AlgoDetails,CBOESessionEligibility}'::text[]                      AS cboesessioneligibility,
       (co.payload #>> '{AlgoDetails,DashImpliedVolatility}'::text[])::numeric            AS impliedvolatility,
       ((co.payload ->> 'IsCabinet'::text))::character(1)::text                           AS cabinet,
       (co.payload ->> 'ParentCrossOrderId'::text)::bigint                                AS transaction64parentcrossorderid,
       CASE
           WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL THEN co.big_payload #>> '{OrderCallTime}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderCallTime}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderCallTime}'::text[]
           ELSE NULL::text
           END                                                                            AS calltime,
       CASE
           WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL
               THEN co.big_payload #>> '{CATDetails,CATElectronicOrderId}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,CATDetails,CATElectronicOrderId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar
               THEN co.payload #>> '{ContraOrder,CATDetails,CATElectronicOrderId}'::text[]
           ELSE NULL::text
           END                                                                            AS electronicorderid,
       CASE
           WHEN co.crossing_side IS NULL AND co.orig_order_id IS NULL
               THEN co.big_payload #>> '{CATDetails,CATElectronicOrderTime}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>>
                                                    '{OriginatorOrder,CATDetails,CATElectronicOrderTime}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>>
                                                    '{ContraOrder,CATDetails,CATElectronicOrderTime}'::text[]
           ELSE NULL::text
           END                                                                            AS electronicordertime,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,ClientInfo}'::text[]
           WHEN co.crossing_side = 'O'::bpchar
               THEN co.payload #>> '{OriginatorOrder,ClearingDetails,ClientInfo}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,ClientInfo}'::text[]
           ELSE NULL::text
           END                                                                            AS clientinfo,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{OrderEventTime}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderEventTime}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderEventTime}'::text[]
           ELSE NULL::text
           END                                                                            AS ordereventtime,
       co.order_id                                                                        AS _order_id,
       co.chain_id                                                                        AS _chain_id,
       co.db_create_time                                                                  AS _db_create_time,
       staging.get_max_db_create_time(co.order_id, co.db_create_time::date, co.chain_id)  AS _last_mod_time,
       CASE
           WHEN co.is_q_time THEN staging.get_timestamp_from_date_ts(co.order_trade_date, co.q_time)
           ELSE NULL::timestamp without time zone
           END                                                                            AS boxqooannouncedtime,
       CASE
           WHEN co.route_destination::text = 'BOX QOO'::text THEN co.payload #>> '{BoxQOOAnnouncedTime}'::text[]
           ELSE NULL::text
           END                                                                            AS boxqooannouncedtimev2,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{OrderNotes}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,OrderNotes}'::text[]
           ELSE NULL::text
           END                                                                            AS ordernotes,
       co.payload ->> 'CboeEquityBroker'::text                                            AS cboeequitybroker,
       co.order_trade_date_id,
       (co.payload ->> 'AutoRouteRuleId'::text)::integer                                  AS autorouteruleid,
       co.payload ->> 'AutoRouteRuleName'::text                                           AS autorouterulename,
       (co.payload ->> 'IsAutoAccepted'::text)::bpchar                                    AS isautoaccepted,
       (co.payload ->> 'IsAutoRouted'::text)::bpchar                                      AS isautorouted,
       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{NoLinkedOrders}'::text[]
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,NoLinkedOrders}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,NoLinkedOrders}'::text[]
           ELSE NULL::text
           END                                                                            AS numberoflinkedorders,
       (co.payload ->> 'IsTiedToCombo')::char                                             as IsTiedToCombo,
       (co.payload ->> 'IsMerged')::char                                                  as IsMerged,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.order_id = (co.payload ->> 'MergedOrderId')::int8
          and co.payload ->> 'MergedOrderId' is not null
          AND co2.chain_id = 0
        limit 1)                                                                          as MergedOrderId

FROM (SELECT DISTINCT ON (cl.cl_ord_id) cl.order_id,
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
                                        big.payload                  AS big_payload,
                                        CASE
                                            WHEN cl.route_destination::text = 'BOX QOO'::text AND
                                                 (cl.payload ->> 'IsFlex'::text) = 'Y'::text THEN true
                                            ELSE false
                                            END                      AS is_q_time,
                                        cl.order_trade_date::integer AS order_trade_date,
                                        CASE
                                            WHEN cl.route_destination::text = 'BOX QOO'::text AND
                                                 (cl.payload ->> 'IsFlex'::text) = 'Y'::text THEN
                                                CASE
                                                    WHEN cl.crossing_side = 'O'::bpchar
                                                        THEN cl.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                                                    WHEN cl.crossing_side = 'C'::bpchar
                                                        THEN (SELECT co2.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                                                              FROM blaze7.client_order co2
                                                              WHERE co2.cross_order_id = cl.cross_order_id
                                                                AND co2.crossing_side = 'O'::bpchar
                                                              ORDER BY co2.chain_id DESC
                                                              LIMIT 1)
                                                    ELSE NULL::text
                                                    END
                                            ELSE NULL::text
                                            END                      AS q_time,
                                        cl.order_trade_date          AS order_trade_date_id
      FROM blaze7.client_order cl
               LEFT JOIN LATERAL ( SELECT co2.payload
                                   FROM blaze7.client_order co2
                                   WHERE co2.order_id = cl.order_id
                                   ORDER BY co2.chain_id DESC
                                   LIMIT 1) big ON true
      WHERE true
        AND (cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
      ORDER BY cl.cl_ord_id, cl.chain_id DESC) co;


-- blaze7.tlegs_edw source
drop VIEW blaze7.tlegs_edw;
CREATE OR REPLACE VIEW blaze7.tlegs_edw
AS
SELECT NULL::text                                                                       AS id,
       co.cl_ord_id                                                                     AS orderid,
       COALESCE(leg.leg_ref_id, '0'::character varying)                                 AS legrefid,
       COALESCE(
               CASE
                   WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
                   WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
                   WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
                   WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
                   ELSE co.payload ->> 'Price'::text
                   END, '0'::text)                                                      AS price,
       COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                               AS legcount,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN leg.payload ->> 'LegSeqNumber'::text
           ELSE '1'::text
           END                                                                          AS legnumber,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
           ELSE co.payload ->> 'DashSecurityId'::text
           END                                                                          AS dashsecurityid,
       COALESCE("substring"(
                        CASE co.instrument_type
                            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                            ELSE co.payload ->> 'DashSecurityId'::text
                            END, 'US:EQ:(.+)'::text), "substring"(
                        CASE co.instrument_type
                            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                            ELSE co.payload ->> 'DashSecurityId'::text
                            END, 'US:[FO|OP]{2}:(.+)_'::text))                          AS basecode,
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
           END                                                                          AS typecode,
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
           END                                                                          AS expirationdate,
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
           END                                                                          AS strike,
       CASE
           WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'LegSide'::text
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'::text[]
           ELSE NULL::text
           END                                                                          AS side,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN leg.payload ->> 'LegRatioQty'::text
           ELSE '1'::text
           END                                                                          AS ratio,
       COALESCE(
               CASE co.instrument_type
                   WHEN 'M'::bpchar THEN leg.payload ->> 'ContractSize'::text
                   ELSE co.payload ->> 'ContractSize'::text
                   END, '1'::text)                                                      AS multiplier,
       COALESCE(co.payload ->> 'DashTargetVega'::text, co.payload ->> 'OrderQty'::text) AS quantity,
       (SELECT rep.payload ->> 'CumQty'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          AND rep.leg_ref_id IS NULL
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                        AS filled,
       CASE
           WHEN co.instrument_type = ANY (ARRAY ['O'::bpchar, 'E'::bpchar]) THEN
               (COALESCE((co.payload ->> 'ContractSize'::text)::integer, 1) *
                CASE co.payload ->> 'Side'::text
                    WHEN '1'::text THEN 1
                    ELSE '-1'::integer
                    END)::numeric * rep_last."CumQty"::bigint::numeric / 10000.0 * rep_last."AvgPx"::bigint::numeric /
               10000.0
           WHEN co.instrument_type = 'M'::bpchar THEN
               (COALESCE(leg.payload ->> 'ContractSize'::text, '1'::text)::integer *
                CASE leg.payload ->> 'LegSide'::text
                    WHEN '1'::text THEN 1
                    ELSE '-1'::integer
                    END)::numeric * rep_last_exec."CumQty"::bigint::numeric / 10000.0 *
               rep_last_exec."AvgPx"::bigint::numeric / 10000.0
           ELSE NULL::numeric
           END                                                                          AS invested,
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
           END::text                                                                    AS avgprice,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               THEN leg.payload ->> 'LegQty'::text
           ELSE NULL::text
           END                                                                          AS stockquantity,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN rep_last."LeavesQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               THEN rep_last_exec."LeavesQty"
           ELSE NULL::text
           END                                                                          AS stockopenquantity,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'CumQty'::text
                                                       FROM blaze7.order_report rep
                                                       WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                       ORDER BY rep.exec_id DESC
                                                       LIMIT 1)
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               THEN rep_last_exec."CumQty"
           ELSE NULL::text
           END                                                                          AS stockfilled,
       CASE
           WHEN co.instrument_type = 'E'::bpchar THEN rep_last."CanceledQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text
               THEN rep_last_exec."CanceledQty"
           ELSE NULL::text
           END                                                                          AS stockcancelled,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN co.payload ->> 'OrderQty'::text
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN leg.payload ->> 'LegQty'::text
           ELSE NULL::text
           END                                                                          AS optionquantity,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN rep_last."LeavesQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN rep_last_exec."LeavesQty"
           ELSE NULL::text
           END                                                                          AS optionopenquantity,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN rep_last."CumQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN rep_last_exec."CumQty"
           ELSE NULL::text
           END                                                                          AS optionfilled,
       CASE
           WHEN co.instrument_type = 'O'::bpchar THEN rep_last."CanceledQty"
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text
               THEN rep_last_exec."CanceledQty"
           ELSE NULL::text
           END                                                                          AS optioncancelled,
       CASE
           WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
           ELSE f_chain."OrderCreationTime"
           END                                                                          AS mindatetime,
       CASE co.instrument_type
           WHEN 'M'::bpchar THEN rep_last_exec."TransactTime"
           ELSE rep_last."TransactTime"
           END                                                                          AS maxdatetime,
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
           END                                                                          AS firstfilldatetime,
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
           END                                                                          AS lastfilldatetime,
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
           END                                                                          AS statuscode,
       co.payload ->> 'TimeInForce'::text                                               AS timeinforcecode,
       CASE
           WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'PositionEffect'::text
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,PositionEffect}'::text[]
           ELSE NULL::text
           END                                                                          AS openclose,
       NULL::text                                                                       AS systemid,
       NULL::text                                                                       AS orderidint,
       COALESCE("substring"(
                        CASE co.instrument_type
                            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                            ELSE co.payload ->> 'DashSecurityId'::text
                            END, 'US:EQ:(.+)'::text), "substring"(
                        CASE co.instrument_type
                            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                            ELSE co.payload ->> 'DashSecurityId'::text
                            END, 'US:[FO|OP]{2}:(.+)_'::text))                          AS rootcode,
       CASE
           WHEN (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                       FROM blaze7.order_report rep
                                                                       WHERE rep.cl_ord_id::text = orig.cl_ord_id::text
                                                                         AND
                                                                           COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                                                                           COALESCE(leg.leg_ref_id, 'leg_ref_id'::character varying)::text
                                                                       ORDER BY rep.exec_id DESC
                                                                       LIMIT 1)
           ELSE NULL::text
           END                                                                          AS prevfillquantity,
       CASE
           WHEN co.instrument_type = 'E'::bpchar OR
                co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text AND
                (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                       FROM blaze7.order_report rep
                                                                       WHERE rep.cl_ord_id::text = orig.cl_ord_id::text
                                                                         AND
                                                                           COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                                                                           COALESCE(leg.leg_ref_id, 'leg_ref_id'::character varying)::text
                                                                       ORDER BY rep.exec_id DESC
                                                                       LIMIT 1)
           ELSE NULL::text
           END                                                                          AS stockprevfillquantity,
       CASE
           WHEN co.instrument_type = 'O'::bpchar OR
                co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text AND
                (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                       FROM blaze7.order_report rep
                                                                       WHERE rep.cl_ord_id::text = orig.cl_ord_id::text
                                                                         AND NOT rep.leg_ref_id::text IS DISTINCT FROM leg.leg_ref_id::text
                                                                       ORDER BY rep.exec_id DESC
                                                                       LIMIT 1)
           ELSE NULL::text
           END                                                                          AS optionprevfillquantity,
       CASE
           WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'StitchedSingleOrderId'::text) IS NOT NULL
               THEN ((SELECT co2.cl_ord_id
                      FROM blaze7.client_order co2
                      WHERE co2.order_id = ((leg.payload ->> 'StitchedSingleOrderId'::text)::bigint)
                        AND co2.chain_id = 0
                      LIMIT 1))::text
           ELSE NULL::text
           END                                                                          AS legorderid,
       co.order_id                                                                      AS _order_id,
       co.chain_id                                                                      AS _chain_id,
       co.db_create_time                                                                AS _db_create_time,
       max_rep._last_mod_time,
       co.order_trade_date                                                              AS order_trade_date_id,
       leg.payload ->> 'IsComboLeg'                                                     as IsComboLeg
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
                             WHERE rep.order_id = co.order_id
                               AND rep.chain_id = co.chain_id
                             ORDER BY rep.db_create_time DESC
                             LIMIT 1) max_rep ON true
         LEFT JOIN LATERAL ( SELECT co2.cl_ord_id
                             FROM blaze7.client_order co2
                             WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                             ORDER BY co2.chain_id DESC
                             LIMIT 1) orig ON true
         LEFT JOIN LATERAL ( SELECT co2.payload ->> 'OrderCreationTime'::text AS "OrderCreationTime"
                             FROM blaze7.client_order co2
                             WHERE co2.cl_ord_id::text = co.cl_ord_id::text
                               AND co2.chain_id = 0) f_chain ON true
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
WHERE co.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]);



SELECT count(1)
FROM blaze7.treports_edw as x
where to_char(x._db_create_time, 'YYYYMMDD')::int = 20250414

