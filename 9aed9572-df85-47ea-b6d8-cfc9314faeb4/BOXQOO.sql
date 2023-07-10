drop function if exists staging.get_timestamp_from_date_ts;
create or replace function staging.get_timestamp_from_date_ts(in_date_id int4 default null, in_ts text default null)
    returns timestamp
    language plpgsql
as
$fx$
begin
    return to_timestamp(in_date_id::text || in_ts, 'YYYYMMDDHH24:MI:SS.US');
exception
    when others then
        return null;
end;
$fx$;

select staging.get_timestamp_from_date_ts(20230506, '25:50:09.010453')
select :order_trade_date::text, :f_timestamp,
       to_timestamp(:order_trade_date::text || :f_timestamp, 'YYYYMMDDHH24:MI:SS.US')

SELECT co.cl_ord_id                                                                            AS orderid,
       co.payload -> 'OriginatorOrder',
       co.payload ->> 'IsFlex',
       co.crossing_side,
       case
           when is_q_time then staging.get_timestamp_from_date_ts(order_trade_date,
                                                                  q_time) end as boxqooannouncedtime
FROM (SELECT DISTINCT ON (cl.cl_ord_id) cl.order_id,
                                        cl.chain_id,
                                        cl.parent_order_id,
                                        cl.orig_order_id,
                                        cl.record_type,
                                        regexp_replace(cl.payload::text, '\\u0000'::text, ''::text,
                                                       'g'::text)::json AS payload,
                                        cl.db_create_time,
                                        cl.cl_ord_id,
                                        cl.crossing_side,
                                        cl.order_class,
                                        cl.secondary_order_id,
                                        cl.cross_order_id,
                                        big.payload                     AS big_payload,
                                        case
                                            when cl.route_destination = 'BOX QOO' and cl.payload ->> 'IsFlex' = 'Y'
                                                then true::boolean
                                            else false end as is_q_time,
                                        cl.order_trade_date::int,
                                        case
                                            when (cl.route_destination = 'BOX QOO' and cl.payload ->> 'IsFlex' = 'Y')
                                                then
                                                case
                                                    when cl.crossing_side = 'O'::bpchar
                                                        then cl.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                                                    when cl.crossing_side = 'C'::bpchar
                                                        then (select cl.payload #>> '{OriginatorOrder,OrderNotes}'
                                                              from blaze7.client_order co2
                                                              WHERE co2.cross_order_id = cl.cross_order_id
                                                                and co2.crossing_side = 'O'
                                                              order by cl.chain_id desc
                                                              limit 1)
                                                    end end             as q_time
      FROM blaze7.client_order cl
               LEFT JOIN LATERAL ( SELECT regexp_replace(co2.payload::text, '\\u0000'::text, ''::text,
                                                         'g'::text)::json AS payload
                                   FROM blaze7.client_order co2
                                   WHERE co2.order_id = cl.order_id
                                   ORDER BY co2.chain_id DESC
                                   LIMIT 1) big ON true
      WHERE true
        AND (cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
        and cl.route_destination = 'BOX QOO'
      ORDER BY cl.cl_ord_id, cl.chain_id DESC) co;
--------------------------------------------------------------------



-- blaze7.tordermisc1_edw source

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
       NULL::text                                                                         AS stoplimit,
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
               THEN co.payload ->> 'CustomerUserId'::text
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
           END::timestamp without time zone                                               AS calltime,
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
           END::timestamp without time zone                                               AS electronicordertime,
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
       case
           when is_q_time then staging.get_timestamp_from_date_ts(order_trade_date,
                                                                  q_time) end             as boxqooannouncedtime
   FROM ( SELECT DISTINCT ON (cl.cl_ord_id) cl.order_id,
                                        cl.chain_id,
                                        cl.parent_order_id,
                                        cl.orig_order_id,
                                        cl.record_type,
                                        regexp_replace(cl.payload::text, '\\u0000'::text, ''::text,
                                                       'g'::text)::json AS payload,
                                        cl.db_create_time,
                                        cl.cl_ord_id,
                                        cl.crossing_side,
                                        cl.order_class,
                                        cl.secondary_order_id,
                                        cl.cross_order_id,
                                        big.payload                     AS big_payload,
                                        case
                                            when cl.route_destination = 'BOX QOO' and cl.payload ->> 'IsFlex' = 'Y'
                                                then true::boolean
                                            else false end as is_q_time,
                                        cl.order_trade_date::int,
                                        case
                                            when (cl.route_destination = 'BOX QOO' and cl.payload ->> 'IsFlex' = 'Y')
                                                then
                                                case
                                                    when cl.crossing_side = 'O'::bpchar
                                                        then cl.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                                                    when cl.crossing_side = 'C'::bpchar
                                                        then (select cl.payload #>> '{OriginatorOrder,OrderNotes}'
                                                              from blaze7.client_order co2
                                                              WHERE co2.cross_order_id = cl.cross_order_id
                                                                and co2.crossing_side = 'O'
                                                              order by cl.chain_id desc
                                                              limit 1)
                                                    end end             as q_time
      FROM blaze7.client_order cl
               LEFT JOIN LATERAL ( SELECT regexp_replace(co2.payload::text, '\\u0000'::text, ''::text,
                                                         'g'::text)::json AS payload
                                   FROM blaze7.client_order co2
                                   WHERE co2.order_id = cl.order_id
                                   ORDER BY co2.chain_id DESC
                                   LIMIT 1) big ON true
      WHERE true
        AND (cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
      ORDER BY cl.cl_ord_id, cl.chain_id DESC) co;