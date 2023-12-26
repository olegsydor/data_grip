create or replace VIEW blaze7.tlegs_edw
as SELECT NULL::text AS id,
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
--    co.db_create_time AS _db_create_time,
   bos.db_create_time AS _db_create_time,
    max_rep._last_mod_time
   FROM blaze7.client_order bos
            join lateral ( SELECT co_1.order_id,
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
                                  regexp_replace(leg.payload::text, '\\u0000'::text, ''::text,
                                                 'g'::text)::json AS leg_payload,
                                  CASE co_1.instrument_type
                                      WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                                      ELSE co_1.payload ->> 'DashSecurityId'::text
                                      END                         AS dashsecurityid
                           FROM (SELECT row_number()
                                        OVER (PARTITION BY client_order.cl_ord_id ORDER BY client_order.chain_id DESC) AS rn,
                                        client_order.order_id,
                                        client_order.chain_id,
                                        client_order.parent_order_id,
                                        client_order.orig_order_id,
                                        client_order.record_type,
                                        client_order.user_id,
                                        client_order.entity_id,
                                        regexp_replace(client_order.payload::text, '\\u0000'::text, ''::text,
                                                       'g'::text)::json                                                AS payload,
                                        client_order.db_create_time,
                                        client_order.cross_order_id,
                                        client_order.cl_ord_id,
                                        client_order.orig_cl_ord_id,
                                        client_order.crossing_side,
                                        client_order.instrument_type,
                                        client_order.order_class,
                                        client_order.route_type
                                 FROM blaze7.client_order
                                 WHERE client_order.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar])
                                   and client_order.order_id = bos.order_id) co_1
                                    LEFT JOIN blaze7.client_order_leg leg
                                              ON leg.order_id = co_1.order_id AND leg.chain_id = co_1.chain_id
                           WHERE co_1.rn = 1) co on true

            LEFT JOIN LATERAL ( SELECT max(rep.db_create_time) AS _last_mod_time
                                FROM blaze7.order_report rep
                                WHERE rep.order_id = co.order_id
                                  AND rep.chain_id = co.chain_id
                                LIMIT 1) max_rep ON true