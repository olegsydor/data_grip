/*
CREATE OR REPLACE FUNCTION blaze7.f_tlegs_edw(in_start_date_id integer DEFAULT NULL::integer,
                                              in_end_date_id integer DEFAULT NULL::integer,
                                              in_last_mod_time timestamp without time zone DEFAULT NULL::timestamp without time zone)
    RETURNS TABLE
            (
                id                     text,
                orderid                varchar(100),
                legrefid               varchar,
                price                  text,
                legcount               text,
                legnumber              text,
                dashsecurityid         text,
                basecode               text,
                typecode               text,
                expirationdate         date,
                strike                 numeric,
                side                   text,
                ratio                  text,
                multiplier             text,
                quantity               text,
                filled                 text,
                invested               numeric,
                avgprice               text,
                stockquantity          text,
                stockopenquantity      text,
                stockfilled            text,
                stockcancelled         text,
                optionquantity         text,
                optionopenquantity     text,
                optionfilled           text,
                optioncancelled        text,
                mindatetime            text,
                maxdatetime            text,
                firstfilldatetime      text,
                lastfilldatetime       text,
                statuscode             text,
                timeinforcecode        text,
                openclose              text,
                systemid               text,
                orderidint             text,
                rootcode               text,
                prevfillquantity       text,
                stockprevfillquantity  text,
                optionprevfillquantity text,
                legorderid             text,
                "_order_id"            int8,
                "_chain_id"            int4,
                "_db_create_time"      timestamptz,
                "_last_mod_time"       timestamptz
            )
    LANGUAGE plpgsql
AS
$function$
declare
    declare
    l_date_begin    timestamptz;
    l_date_end      timestamptz;
    l_last_mod_time timestamptz;

begin
    l_date_begin := coalesce(in_start_date_id, 19900101)::text::timestamptz;
    l_date_end := coalesce(in_end_date_id::text::timestamp, l_date_begin + interval '1 day');
    l_last_mod_time := coalesce(in_last_mod_time, l_date_begin);

    raise notice '%, %, %', l_date_begin, l_date_end, l_last_mod_time;

    create temp table t_legs on commit drop
    as
    with base as (SELECT distinct on (co.cl_ord_id)
                      co.order_id,
                         co.chain_id,
                         co.parent_order_id,
                         co.orig_order_id,
                         co.record_type,
                         co.user_id,
                         co.entity_id,
                         co.payload  as payload,
                         co.db_create_time,
                         co.cross_order_id,
                         co.cl_ord_id,
                         co.orig_cl_ord_id,
                         co.crossing_side,
                         co.instrument_type,
                         co.order_class,
                         co.route_type,
                         leg.leg_ref_id,
                         leg.payload AS leg_payload,
                         CASE co.instrument_type
                             WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                             ELSE co.payload ->> 'DashSecurityId'::text
                             END     AS dashsecurityid,
                         max_rep.last_mod_time
                  FROM blaze7.client_order co
                           join lateral (select null
                                         from blaze7.client_order chn
                                         where co.order_id = chn.order_id
                                           and co.chain_id = chn.chain_id
                                         order by chn.chain_id desc
                                         limit 1) ch on true
                           LEFT JOIN blaze7.client_order_leg leg
                                     ON leg.order_id = co.order_id AND leg.chain_id = co.chain_id
                           LEFT JOIN LATERAL ( SELECT max(rep.db_create_time) AS last_mod_time
                                               FROM blaze7.order_report rep
                                               WHERE rep.order_id = co.order_id
                                                 AND rep.chain_id = co.chain_id
                                               LIMIT 1) max_rep ON true
                  WHERE co.record_type in ('0', '2')
                    and co.db_create_time >= l_date_begin
                    and co.db_create_time < l_date_end
                    and (co.db_create_time > l_last_mod_time
                      or max_rep.last_mod_time > l_last_mod_time)
                  order by co.cl_ord_id, co.chain_id desc)
    SELECT NULL::text                                                                       AS id,
           co.cl_ord_id                                                                     AS orderid,
           COALESCE(co.leg_ref_id, '0'::character varying)                                  AS legrefid,
           COALESCE(
                   CASE
                       WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
                       WHEN (co.leg_payload ->> 'LegPrice'::text) IS NOT NULL THEN co.leg_payload ->> 'LegPrice'::text
                       WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
                       WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
                       ELSE co.payload ->> 'Price'::text
                       END, '0'::text)                                                      AS price,
           COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                               AS legcount,
           CASE co.instrument_type
               WHEN 'M'::bpchar THEN co.leg_payload ->> 'LegSeqNumber'::text
               ELSE '1'::text
               END                                                                          AS legnumber,
           co.dashsecurityid,
           COALESCE("substring"(co.dashsecurityid, 'US:EQ:(.+)'::text),
                    "substring"(co.dashsecurityid, 'US:[FO|OP]{2}:(.+)_'::text))            AS basecode,
           CASE
               WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = 'EQ'::text THEN 'S'::text
               WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text])
                   THEN "substring"(co.dashsecurityid, '[0-9]{6}(.)'::text)
               ELSE NULL::text
               END                                                                          AS typecode,
           CASE
               WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text])
                   THEN to_date("substring"(co.dashsecurityid, '([0-9]{6})'::text), 'YYMMDD'::text)
               ELSE NULL::date
               END                                                                          AS expirationdate,
           CASE
               WHEN "substring"(co.dashsecurityid, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text])
                   THEN "substring"(co.dashsecurityid, '[0-9]{6}.(.+)$'::text)::numeric
               ELSE NULL::numeric
               END                                                                          AS strike,
           CASE
               WHEN co.instrument_type = 'M'::bpchar THEN co.leg_payload ->> 'LegSide'::text
               WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'::text
               WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'::text[]
               WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'::text[]
               ELSE NULL::text
               END                                                                          AS side,
           CASE co.instrument_type
               WHEN 'M'::bpchar THEN co.leg_payload ->> 'LegRatioQty'::text
               ELSE '1'::text
               END                                                                          AS ratio,
           COALESCE(
                   CASE co.instrument_type
                       WHEN 'M'::bpchar THEN co.leg_payload ->> 'ContractSize'::text
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
                            END)::numeric * ((SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 *
                                                     ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric / 10000.0
                                              FROM blaze7.order_report rep
                                              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                              ORDER BY rep.exec_id DESC
                                              LIMIT 1))
               WHEN co.instrument_type = 'M'::bpchar THEN
                       (COALESCE(co.leg_payload ->> 'ContractSize'::text, '1'::text)::integer *
                        CASE co.leg_payload ->> 'LegSide'::text
                            WHEN '1'::text THEN 1
                            ELSE '-1'::integer
                            END)::numeric * ((SELECT ((rep.payload ->> 'CumQty'::text)::bigint)::numeric / 10000.0 *
                                                     ((rep.payload ->> 'AvgPx'::text)::bigint)::numeric / 10000.0
                                              FROM blaze7.order_report rep
                                              WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                AND rep.leg_ref_id::text = co.leg_ref_id::text
                                              ORDER BY rep.exec_id DESC
                                              LIMIT 1))
               ELSE NULL::numeric
               END                                                                          AS invested,
           CASE co.instrument_type
               WHEN 'M'::bpchar THEN
                       CASE
                           WHEN (co.leg_payload ->> 'LegSide'::text) = '2'::text THEN '-1'::integer
                           ELSE 1
                           END * ((SELECT (rep.payload ->> 'AvgPx'::text)::bigint AS int8
                                   FROM blaze7.order_report rep
                                   WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                     AND rep.leg_ref_id::text = co.leg_ref_id::text
                                   ORDER BY rep.exec_id DESC
                                   LIMIT 1))
               ELSE
                       CASE
                           WHEN co.crossing_side IS NULL AND (co.payload ->> 'Side'::text) = '2'::text THEN '-1'::integer
                           WHEN co.crossing_side = 'O'::bpchar AND
                                (co.payload #>> '{OriginatorOrder,Side}'::text[]) = '2'::text THEN '-1'::integer
                           WHEN co.crossing_side = 'C'::bpchar AND (co.payload #>> '{ContraOrder,Side}'::text[]) = '2'::text
                               THEN '-1'::integer
                           ELSE 1
                           END * ((SELECT (rep.payload ->> 'AvgPx'::text)::bigint AS int8
                                   FROM blaze7.order_report rep
                                   WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                   ORDER BY rep.exec_id DESC
                                   LIMIT 1))
               END::text                                                                    AS avgprice,
           CASE
               WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text
                   THEN co.leg_payload ->> 'LegQty'::text
               ELSE NULL::text
               END                                                                          AS stockquantity,
           CASE
               WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'LeavesQty'::text
                                                           FROM blaze7.order_report rep
                                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                           ORDER BY rep.exec_id DESC
                                                           LIMIT 1)
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text
                   THEN (SELECT rep.payload ->> 'LeavesQty'::text
                         FROM blaze7.order_report rep
                         WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                           AND rep.leg_ref_id::text = co.leg_ref_id::text
                         ORDER BY rep.exec_id DESC
                         LIMIT 1)
               ELSE NULL::text
               END                                                                          AS stockopenquantity,
           CASE
               WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'CumQty'::text
                                                           FROM blaze7.order_report rep
                                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                           ORDER BY rep.exec_id DESC
                                                           LIMIT 1)
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text
                   THEN (SELECT rep.payload ->> 'CumQty'::text
                         FROM blaze7.order_report rep
                         WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                           AND rep.leg_ref_id::text = co.leg_ref_id::text
                         ORDER BY rep.exec_id DESC
                         LIMIT 1)
               ELSE NULL::text
               END                                                                          AS stockfilled,
           CASE
               WHEN co.instrument_type = 'E'::bpchar THEN (SELECT rep.payload ->> 'CanceledQty'::text
                                                           FROM blaze7.order_report rep
                                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                           ORDER BY rep.exec_id DESC
                                                           LIMIT 1)
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text
                   THEN (SELECT rep.payload ->> 'CanceledQty'::text
                         FROM blaze7.order_report rep
                         WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                           AND rep.leg_ref_id::text = co.leg_ref_id::text
                         ORDER BY rep.exec_id DESC
                         LIMIT 1)
               ELSE NULL::text
               END                                                                          AS stockcancelled,
           CASE
               WHEN co.instrument_type = 'O'::bpchar THEN co.payload ->> 'OrderQty'::text
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text
                   THEN co.leg_payload ->> 'LegQty'::text
               ELSE NULL::text
               END                                                                          AS optionquantity,
           CASE
               WHEN co.instrument_type = 'O'::bpchar THEN (SELECT rep.payload ->> 'LeavesQty'::text
                                                           FROM blaze7.order_report rep
                                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                           ORDER BY rep.exec_id DESC
                                                           LIMIT 1)
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text
                   THEN (SELECT rep.payload ->> 'LeavesQty'::text
                         FROM blaze7.order_report rep
                         WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                           AND rep.leg_ref_id::text = co.leg_ref_id::text
                         ORDER BY rep.exec_id DESC
                         LIMIT 1)
               ELSE NULL::text
               END                                                                          AS optionopenquantity,
           CASE
               WHEN co.instrument_type = 'O'::bpchar THEN (SELECT rep.payload ->> 'CumQty'::text
                                                           FROM blaze7.order_report rep
                                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                           ORDER BY rep.exec_id DESC
                                                           LIMIT 1)
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text
                   THEN (SELECT rep.payload ->> 'CumQty'::text
                         FROM blaze7.order_report rep
                         WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                           AND rep.leg_ref_id::text = co.leg_ref_id::text
                         ORDER BY rep.exec_id DESC
                         LIMIT 1)
               ELSE NULL::text
               END                                                                          AS optionfilled,
           CASE
               WHEN co.instrument_type = 'O'::bpchar THEN (SELECT rep.payload ->> 'CanceledQty'::text
                                                           FROM blaze7.order_report rep
                                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                           ORDER BY rep.exec_id DESC
                                                           LIMIT 1)
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text
                   THEN (SELECT rep.payload ->> 'CanceledQty'::text
                         FROM blaze7.order_report rep
                         WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                           AND rep.leg_ref_id::text = co.leg_ref_id::text
                         ORDER BY rep.exec_id DESC
                         LIMIT 1)
               ELSE NULL::text
               END                                                                          AS optioncancelled,
           CASE
               WHEN co.chain_id = 0 THEN co.payload ->> 'OrderCreationTime'::text
               ELSE (SELECT co2.payload ->> 'OrderCreationTime'::text
                     FROM blaze7.client_order co2
                     WHERE co2.cl_ord_id::text = co.cl_ord_id::text
                       AND co2.chain_id = 0)
               END                                                                          AS mindatetime,
           CASE co.instrument_type
               WHEN 'M'::bpchar THEN (SELECT rep.payload ->> 'TransactTime'::text
                                      FROM blaze7.order_report rep
                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                        AND rep.leg_ref_id::text = co.leg_ref_id::text
                                      ORDER BY rep.exec_id DESC
                                      LIMIT 1)
               ELSE (SELECT rep.payload ->> 'TransactTime'::text
                     FROM blaze7.order_report rep
                     WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                     ORDER BY rep.exec_id DESC
                     LIMIT 1)
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
                       AND rep.leg_ref_id::text = co.leg_ref_id::text
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
                       AND rep.leg_ref_id::text = co.leg_ref_id::text
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
                               WHEN co.instrument_type = 'M'::bpchar THEN rp.leg_ref_id::text = co.leg_ref_id::text
                               ELSE true
                         END
                     ORDER BY rp.exec_id DESC
                     LIMIT 1)
               END                                                                          AS statuscode,
           co.payload ->> 'TimeInForce'::text                                               AS timeinforcecode,
           CASE
               WHEN co.instrument_type = 'M'::bpchar THEN co.leg_payload ->> 'PositionEffect'::text
               WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'::text
               WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
               WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,PositionEffect}'::text[]
               ELSE NULL::text
               END                                                                          AS openclose,
           NULL::text                                                                       AS systemid,
           NULL::text                                                                       AS orderidint,
           COALESCE("substring"(co.dashsecurityid, 'US:EQ:(.+)'::text),
                    "substring"(co.dashsecurityid, 'US:[FO|OP]{2}:(.+)_'::text))            AS rootcode,
           CASE
               WHEN (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                           FROM blaze7.order_report rep
                                                                           WHERE rep.cl_ord_id::text =
                                                                                 (((SELECT co2.cl_ord_id
                                                                                    FROM blaze7.client_order co2
                                                                                    WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                                                                                    ORDER BY co2.chain_id DESC
                                                                                    LIMIT 1))::text)
                                                                             AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                                                                                 COALESCE(co.leg_ref_id, 'leg_ref_id'::character varying)::text
                                                                           ORDER BY rep.exec_id DESC
                                                                           LIMIT 1)
               ELSE NULL::text
               END                                                                          AS prevfillquantity,
           CASE
               WHEN co.instrument_type = 'E'::bpchar OR
                    co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'E'::text AND
                    (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                           FROM blaze7.order_report rep
                                                                           WHERE rep.cl_ord_id::text =
                                                                                 (((SELECT co2.cl_ord_id
                                                                                    FROM blaze7.client_order co2
                                                                                    WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                                                                                    ORDER BY co2.chain_id DESC
                                                                                    LIMIT 1))::text)
                                                                             AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                                                                                 COALESCE(co.leg_ref_id, 'leg_ref_id'::character varying)::text
                                                                           ORDER BY rep.exec_id DESC
                                                                           LIMIT 1)
               ELSE NULL::text
               END                                                                          AS stockprevfillquantity,
           CASE
               WHEN co.instrument_type = 'O'::bpchar OR
                    co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'LegInstrumentType'::text) = 'O'::text AND
                    (co.payload ->> 'OrigClOrdId'::text) IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                           FROM blaze7.order_report rep
                                                                           WHERE rep.cl_ord_id::text =
                                                                                 (((SELECT co2.cl_ord_id
                                                                                    FROM blaze7.client_order co2
                                                                                    WHERE co2.cl_ord_id::text = (co.payload ->> 'OrigClOrdId'::text)
                                                                                    ORDER BY co2.chain_id DESC
                                                                                    LIMIT 1))::text)
                                                                             AND COALESCE(rep.leg_ref_id, 'leg_ref_id'::character varying)::text =
                                                                                 COALESCE(co.leg_ref_id, 'leg_ref_id'::character varying)::text
                                                                           ORDER BY rep.exec_id DESC
                                                                           LIMIT 1)
               ELSE NULL::text
               END                                                                          AS optionprevfillquantity,
           CASE
               WHEN co.instrument_type = 'M'::bpchar AND (co.leg_payload ->> 'StitchedSingleOrderId'::text) IS NOT NULL
                   THEN ((SELECT co2.cl_ord_id
                          FROM blaze7.client_order co2
                          WHERE co2.order_id::text = (co.leg_payload ->> 'StitchedSingleOrderId'::text)
                            AND co2.chain_id = 0
                          LIMIT 1))::text
               ELSE NULL::text
               END                                                                          AS legorderid,
           co.order_id                                                                      AS _order_id,
           co.chain_id                                                                      AS _chain_id,
           co.db_create_time                                                                AS _db_create_time,
           co.last_mod_time
    FROM base co;


    return query
        select * from t_legs;

end;
$function$
;


-------------------------


CREATE OR REPLACE FUNCTION blaze7.f_torder_edw(in_start_date_id integer DEFAULT NULL::integer,
                                                in_end_date_id integer DEFAULT NULL::integer,
                                                in_last_mod_time timestamp without time zone DEFAULT NULL::timestamp without time zone)
    RETURNS TABLE
            (
                id                     text,
                systemid               text,
                systemorderid          character varying,
                systemordertypeid      character,
                orderid                character varying,
                parentorderid          character varying,
                cancelorderid          character varying,
                contraorderid          character varying,
                origorderid            character varying,
                replaceorderid         character varying,
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
                exchangeconnectionid   character,
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
                optionquantity         bigint,
                optionopenquantity     bigint,
                optionfilled           bigint,
                optioncancelled        bigint,
                invested               numeric,
                accountalias           text,
                account                text,
                subaccount             text,
                subaccount2            text,
                subaccount3            text,
                comment                text,
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
                optionprevfillquantity bigint,
                tradedate              bigint,
                _order_id              bigint,
                _chain_id              integer,
                _db_create_time        timestamp with time zone
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_date_begin    timestamptz;
    l_date_end      timestamptz;
    l_last_mod_time timestamptz;

begin
    l_date_begin := coalesce(in_start_date_id, 19900101)::text::timestamptz;
    l_date_end := coalesce(in_end_date_id::text::timestamp, l_date_begin + interval '1 day');
    l_last_mod_time := coalesce(in_last_mod_time, l_date_begin);

    raise notice '%, %, %', l_date_begin, l_date_end, l_last_mod_time;

    create temp table t_base on commit drop
    as
    select distinct on (cl_ord_id) *
    from blaze7.v_order_base2
    where db_create_time >= l_date_begin
      and db_create_time < l_date_end
      and case
              when in_last_mod_time is null then true
              else staging.get_max_db_create_time(order_id, db_create_time::date, chain_id) > l_last_mod_time end
    order by cl_ord_id, chain_id desc;

    raise notice 'temp table base created - %', clock_timestamp();

    analyze t_base;

    create temp table t_order on commit drop as
    SELECT NULL::text                                       AS id,
           NULL::text                                       AS systemid,
           co.cl_ord_id                                     AS systemorderid,
           CASE
               WHEN co.route_destination::text = 'VEGA'::text THEN 'VEGA'::bpchar
               WHEN co."HasStitchedOrders" = 'Y'::text THEN 'StitchedSingle'::bpchar
               WHEN COALESCE(co."IsStitched", co."OriginatorOrderIsStitched") = 'Y'::text THEN 'StitchedSpread'::bpchar
               WHEN co.order_class = 'I'::bpchar THEN 'G'::bpchar
               ELSE co.order_class
               END                                          AS systemordertypeid,
           co.cl_ord_id                    AS orderid,
           CASE
               WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                         FROM blaze7.client_order co2
                                                         WHERE co2.order_id = co.parent_order_id
                                                         ORDER BY co2.chain_id DESC
                                                         LIMIT 1)
               ELSE NULL::character varying
               END                                          AS parentorderid,
           co.orig_cl_ord_id               AS cancelorderid,
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
               END                                          AS contraorderid,
           CASE co.crossing_side
               WHEN 'C'::bpchar THEN (SELECT co2.cl_ord_id
                                      FROM blaze7.client_order co2
                                      WHERE co2.cross_order_id = co.cross_order_id
                                        AND co2.crossing_side = 'O'::bpchar
                                      ORDER BY co2.chain_id DESC
                                      LIMIT 1)
               ELSE (SELECT co2.cl_ord_id
                     FROM blaze7.client_order co2
                     WHERE co2.order_id = co."OriginatorOrderRefId"::bigint
                     ORDER BY co2.chain_id DESC
                     LIMIT 1)
               END                                          AS origorderid,
           (SELECT co2.cl_ord_id
            FROM blaze7.client_order co2
            WHERE co2.orig_cl_ord_id::text = co.cl_ord_id::text
              AND co2.record_type = '0'::bpchar
            ORDER BY co2.chain_id DESC
            LIMIT 1)                                        AS replaceorderid,
           CASE
               WHEN COALESCE(co."LinkedStageOrderId", co."OriginatorOrderLinkedStageOrderId",
                             co."ContraOrderLinkedStageOrderId") IS NOT NULL THEN 'T'::text
               ELSE (SELECT rp.payload ->> 'BlazeOrderStatus'::text
                     FROM blaze7.order_report rp
                     WHERE rp.cl_ord_id::text = co.cl_ord_id::text
                       AND rp.leg_ref_id IS NULL
                     ORDER BY rp.exec_id DESC
                     LIMIT 1)
               END                                          AS status,
           CASE
               WHEN co.chain_id = 0 THEN co."OrderCreationTime"
               ELSE (SELECT co2.payload ->> 'OrderCreationTime'::text
                     FROM blaze7.client_order co2
                     WHERE co2.cl_ord_id::text = co.cl_ord_id::text
                       AND co2.chain_id = 0)
               END                                          AS createdatetime,
           NULL::text                                       AS approveddatetime,
           NULL::text                                       AS dtclearbookdatetime,
           (SELECT rep.payload ->> 'TransactTime'::text
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
              AND CASE
                      WHEN co.instrument_type <> 'M'::bpchar THEN true
                      ELSE rep.leg_ref_id IS NOT NULL
                END
            ORDER BY rep.exec_id
            LIMIT 1)                                        AS firstfilldatetime,
           (SELECT rep.payload ->> 'TransactTime'::text
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              AND (rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]))
              AND CASE
                      WHEN co.instrument_type <> 'M'::bpchar THEN true
                      ELSE rep.leg_ref_id IS NOT NULL
                END
            ORDER BY rep.exec_id DESC
            LIMIT 1)                                        AS lastfilldatetime,
           (SELECT rep.payload ->> 'TransactTime'::text
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
            ORDER BY rep.exec_id DESC
            LIMIT 1)                                        AS updatedatetime,
           (SELECT rep.payload ->> 'TransactTime'::text
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              AND ((rep.payload ->> 'OrderStatus'::text) = ANY
                   (ARRAY ['2'::text, '3'::text, '4'::text, '8'::text, 'P'::text, 'l'::text, '5'::text]))
            ORDER BY rep.exec_id DESC
            LIMIT 1)                                        AS completeddatetime,
           NULL::text                                       AS writedatetime,
           CASE
               WHEN co.crossing_side = 'O'::bpchar THEN COALESCE(co."OriginatorOrderClearingDetailsCustomerUserId",
                                                                 co."InitiatorUserId")
               WHEN co.crossing_side = 'C'::bpchar THEN COALESCE(co."ContraOrderClearingDetailsCustomerUserId",
                                                                 co."InitiatorUserId")
               WHEN co.crossing_side IS NULL THEN COALESCE(co."ClearingDetailsCustomerUserId", co."InitiatorUserId")
               ELSE NULL::text
               END                                          AS userid,
           COALESCE(co."OwnerUserId", co."InitiatorUserId") AS ownerid,
           NULL::text                                       AS previousownerid,
           CASE
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsCustomerUserId"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsCustomerUserId"
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsCustomerUserId"
               ELSE NULL::text
               END                                          AS sendinguserid,
           NULL::text                                       AS executingbroker,
           CASE
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClientEntityId"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClientEntityId"
               WHEN co.crossing_side IS NULL THEN co."ClientEntityId"
               ELSE NULL::text
               END                                          AS companyid,
           co."DestinationEntityId"                         AS destinationcompanyid,
           NULL::text                                       AS introducingcompanyid,
           NULL::text                                       AS parentcompanyid,
           co.route_type                                    AS exchangeconnectionid,
           NULL::text                                       AS exchangeinfoid,
           NULL::text                                       AS exchangecomment,
           co."ProductDescription"                          AS contractdesc,
           NULL::text                                       AS strategytype,
           NULL::text                                       AS assetclass,
           COALESCE(co."NoLegs", '1'::text)                 AS legcount,
           COALESCE(
                   CASE
                       WHEN co.crossing_side IS NULL OR co.instrument_type <> 'M'::bpchar THEN co."Price"
                       WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'O'::bpchar
                           THEN co."OriginatorOrderPrice"
                       WHEN co.instrument_type = 'M'::bpchar AND co.crossing_side = 'C'::bpchar
                           THEN co."ContraOrderPrice"
                       WHEN co.instrument_type <> 'M'::bpchar THEN co."Price"
                       ELSE NULL::text
                       END, '0'::text)                      AS price,
           COALESCE(co."DashTargetVega", co."OrderQty")     AS quantity,
           (SELECT rep.payload ->> 'CumQty'::text
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
            ORDER BY rep.exec_id DESC
            LIMIT 1)                                        AS filled,
           (SELECT rep.payload ->> 'AvgPx'::text
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
              AND rep.leg_ref_id IS NULL
            ORDER BY rep.exec_id DESC
            LIMIT 1)                                        AS avgprice,
           CASE
               WHEN co.instrument_type = 'E'::bpchar THEN co."OrderQty"
               WHEN co."SpreadType" = '1'::text THEN (SELECT leg.payload ->> 'LegQty'::text
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
               END                                          AS stockquantity,
           CASE
               WHEN co."SpreadType" = '1'::text THEN (SELECT rep.payload ->> 'LeavesQty'::text
                                                      FROM blaze7.order_report rep
                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                        AND rep.leg_ref_id::text = (((SELECT leg.leg_ref_id
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
               END                                          AS stockopenquantity,
           CASE
               WHEN co."SpreadType" = '1'::text THEN (SELECT rep.payload ->> 'CumQty'::text
                                                      FROM blaze7.order_report rep
                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                        AND rep.leg_ref_id::text = (((SELECT leg.leg_ref_id
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
               END                                          AS stockfilled,
           CASE
               WHEN co."SpreadType" = '1'::text THEN (SELECT rep.payload ->> 'CanceledQty'::text
                                                      FROM blaze7.order_report rep
                                                      WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                        AND rep.leg_ref_id::text = (((SELECT leg.leg_ref_id
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
               END                                          AS stockcancelled,
           CASE co.instrument_type
               WHEN 'O'::bpchar THEN co."OrderQty"::bigint
               WHEN 'M'::bpchar THEN (SELECT sum((leg.payload ->> 'LegQty'::text)::integer) AS sum
                                      FROM blaze7.client_order_leg leg
                                      WHERE leg.order_id = co.order_id
                                        AND leg.chain_id = co.chain_id
                                        AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text)
               ELSE NULL::bigint
               END                                          AS optionquantity,
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
               END                                          AS optionopenquantity,
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
               END                                          AS optionfilled,
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
               END                                          AS optioncancelled,
           CASE
               WHEN co.instrument_type = ANY (ARRAY ['O'::bpchar, 'E'::bpchar]) THEN
                       (COALESCE(co."ContractSize"::integer, 1) *
                        CASE co."Side"
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
                                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                                             AND rep.leg_ref_id::text = leg.leg_ref_id::text
                                                           ORDER BY rep.exec_id DESC
                                                           LIMIT 1))) AS sum
                         FROM blaze7.client_order_leg leg
                         WHERE leg.order_id = co.order_id
                           AND leg.chain_id = co.chain_id)
               ELSE NULL::numeric
               END                                          AS invested,
           CASE
               WHEN co.crossing_side IS NULL THEN co."AccountAlias"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderAccountAlias"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderAccountAlias"
               ELSE NULL::text
               END                                          AS accountalias,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsAccount"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsAccount"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsAccount"
               ELSE NULL::text
               END                                          AS account,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsSubAcct1"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsSubAcct1"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsSubAcct1"
               ELSE NULL::text
               END                                          AS subaccount,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsSubAcct2"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsSubAcct2"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsSubAcct2"
               ELSE NULL::text
               END                                          AS subaccount2,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsSubAcct3"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsSubAcct3"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsSubAcct3"
               ELSE NULL::text
               END                                          AS subaccount3,
           co."OrderTextComment"                            AS comment,
           NULL::text                                       AS brokercomment,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsOptionRange"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsOptionRange"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsOptionRange"
               ELSE NULL::text
               END                                          AS forwhom,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsGiveUp"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsGiveUp"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsGiveUp"
               ELSE NULL::text
               END                                          AS giveupfirm,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsCMTA"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsCMTA"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsCMTA"
               ELSE NULL::text
               END                                          AS cmtafirm,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsMPID"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsMPID"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsMPID"
               ELSE NULL::text
               END                                          AS mpid,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsLocateId"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsLocateId"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsLocateId"
               ELSE NULL::text
               END                                          AS sstkclid,
           NULL::text                                       AS iscapstrategy,
           NULL::text                                       AS iscrosslate,
           NULL::text                                       AS isfbsamexoverrideprice,
           NULL::text                                       AS isfbsamexratiospread,
           CASE co."CrossingMechanism"
               WHEN 'Q'::text THEN '1'::text
               ELSE '0'::text
               END                                          AS isqcc,
           CASE
               WHEN COALESCE(co."LinkedStageOrderId", co."OriginatorOrderLinkedStageOrderId",
                             co."ContraOrderLinkedStageOrderId") IS NOT NULL THEN '1'::text
               ELSE NULL::text
               END                                          AS islinked,
           NULL::text                                       AS istargetedresplsmm,
           NULL::text                                       AS istargetedresponse,
           CASE
               WHEN co.cross_order_id IS NULL THEN '0'::text
               ELSE '1'::text
               END                                          AS isauctionorder,
           NULL::text                                       AS iseyedirect,
           NULL::text                                       AS ishidden,
           NULL::text                                       AS isior,
           CASE
               WHEN
                       CASE
                           WHEN co.crossing_side IS NULL THEN co."IsSolicited"
                           WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderIsSolicited"
                           WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderIsSolicited"
                           ELSE NULL::text
                           END = 'Y'::text THEN '1'::text
               ELSE '0'::text
               END                                          AS issolicited,
           NULL::text                                       AS isservercast,
           NULL::text                                       AS iscoveredcode,
           CASE
               WHEN co."ExecInst" = 'G'::text THEN '1'::text
               ELSE '0'::text
               END                                          AS isallornone,
           NULL::text                                       AS isdeltahedge,
           CASE
               WHEN
                       CASE
                           WHEN co.crossing_side IS NULL THEN co."NotHeld"
                           WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderNotHeld"
                           WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderNotHeld"
                           ELSE NULL::text
                           END = 'Y'::text THEN '1'::text
               ELSE '0'::text
               END                                          AS isnotheld,
           CASE
               WHEN co."SpreadType" = '1'::text THEN '1'::text
               ELSE '0'::text
               END                                          AS istiedtostock,
           NULL::text                                       AS istrytostop,
           NULL::text                                       AS delta,
           NULL::text                                       AS billingentity,
           co."OrderType"                                   AS pricequalifier,
           co."TimeInForce"                                 AS timeinforcecode,
           co."CboePARDestination"                          AS boothidoverride,
           NULL::text                                       AS isignorepreference,
           ((SELECT co2.cl_ord_id
             FROM blaze7.client_order co2
             WHERE co2.order_id = COALESCE(co."LinkedStageOrderId", co."OriginatorOrderLinkedStageOrderId",
                                           co."ContraOrderLinkedStageOrderId")::bigint
               AND co2.chain_id = 0))::text                 AS linkorderid,
           NULL::text                                       AS ltargetresponseid,
           NULL::text                                       AS satpid,
           NULL::text                                       AS scrossbadgeids,
           (SELECT COALESCE(rep.payload ->> 'ExternalReasonCode'::text,
                            rep.payload ->> 'InternalReasonCode'::text) AS "coalesce"
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
            ORDER BY rep.exec_id DESC
            LIMIT 1)                                        AS reasoncode,
           NULL::text                                       AS parentorderidint,
           NULL::text                                       AS cancelorderidint,
           NULL::text                                       AS contraorderidint,
           NULL::text                                       AS origorderidint,
           CASE
               WHEN co.crossing_side IS NULL THEN co."Generation"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderGeneration"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderGeneration"
               ELSE NULL::text
               END                                          AS generation,
           (SELECT rep.payload ->> 'NoChildren'::text
            FROM blaze7.order_report rep
            WHERE rep.cl_ord_id::text = co.cl_ord_id::text
            ORDER BY rep.exec_id DESC
            LIMIT 1)                                        AS childorders,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsSocGenCapacity"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsSocGenCapacity"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsSocGenCapacity"
               ELSE NULL::text
               END                                          AS capacity,
           CASE
               WHEN co.crossing_side IS NULL THEN co."ClearingDetailsSocGenPortfolio"
               WHEN co.crossing_side = 'O'::bpchar THEN co."OriginatorOrderClearingDetailsSocGenPortfolio"
               WHEN co.crossing_side = 'C'::bpchar THEN co."ContraOrderClearingDetailsSocGenPortfolio"
               ELSE NULL::text
               END                                          AS portfolio,
           co."ClassicRouteDestinationCode"                 AS exdestination,
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
               END                                          AS prevfillquantity,
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
               WHEN co."SpreadType" = '0'::text THEN NULL::text
               WHEN co."SpreadType" = '1'::text AND co.orig_order_id IS NOT NULL THEN (SELECT rep.payload ->> 'CumQty'::text
                                                                                       FROM blaze7.order_report rep
                                                                                       WHERE rep.cl_ord_id::text =
                                                                                             (((SELECT co2.cl_ord_id
                                                                                                FROM blaze7.client_order co2
                                                                                                WHERE co2.cl_ord_id::text = co.orig_cl_ord_id::text
                                                                                                ORDER BY co2.chain_id DESC
                                                                                                LIMIT 1))::text)
                                                                                         AND rep.leg_ref_id::text =
                                                                                             (((SELECT leg2.leg_ref_id
                                                                                                FROM blaze7.client_order_leg leg2
                                                                                                WHERE leg2.order_id = co.order_id
                                                                                                  AND (leg2.payload ->> 'LegInstrumentType'::text) = 'E'::text
                                                                                                LIMIT 1))::text)
                                                                                       ORDER BY rep.exec_id DESC
                                                                                       LIMIT 1)
               ELSE NULL::text
               END                                          AS stockprevfillquantity,
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
               END                                          AS optionprevfillquantity,
           (SELECT co2.order_trade_date
            FROM blaze7.client_order co2
            WHERE co2.cl_ord_id::text = co.cl_ord_id::text
              AND co2.chain_id = 0)                         AS tradedate,
           co.order_id                                      AS _order_id,
           co.chain_id                                      AS _chain_id,
           co.db_create_time                                AS _db_create_time
--    ,staging.get_max_db_create_time(co.order_id, co.db_create_time::date, co.chain_id) AS _last_mod_time
    from t_base as co;

    raise notice 'temp table t_order created - %', clock_timestamp();

    return query
        select * from t_order;

end;
$function$
;
*/

-- blaze7.torder_edw source

SELECT rep.payload ->> 'TransactTime', leg_ref_id
FROM blaze7.order_report rep
WHERE rep.cl_ord_id = '3_10l230811'
  AND rep.exec_type in ('1', '2')
  and case when :instrument_type = 'M' then rep.leg_ref_id is not null else true end
order by rep.exec_id --desc
limit 1

select --first_value(rep.payload ->> 'TransactTime') over (partition by rep.cl_ord_id order by rep.exec_id rows between unbounded preceding and unbounded following) as fv,
       --last_value(rep.payload ->> 'TransactTime') over (partition by rep.cl_ord_id order by rep.exec_id rows between unbounded preceding and unbounded following) as lv,
       rep.payload ->> 'TransactTime',
       rep.payload ->> 'OrderStatus'
from blaze7.order_report rep
where cl_ord_id = '3_14s230811'
  and rep.exec_type in ('1', '2')
  and case when :instrument_type = 'M' then rep.leg_ref_id is not null else true end
window ex as ( partition by rep.cl_ord_id order by rep.exec_id rows between unbounded preceding and unbounded following
        )


select co.cl_ord_id, r.* from blaze7.client_order co
join lateral (select rep.payload ->> 'OrderStatus' as ord_status
              from blaze7.order_report rep where rep.cl_ord_id = co.cl_ord_id order by rep.exec_id limit 1) r on true
where r.ord_status not in ('2', '3', '4', '8', 'P', 'l', '5')



SELECT sum(x."LeavesQty")   as "sumLeavesQty",
       sum(x."CanceledQty") as "sumCanceledQty",
       sum(x."CumQty")      as "sumCumQty"
FROM (SELECT (rep.payload ->> 'LeavesQty'::text)::integer                                AS "LeavesQty",
             (rep.payload ->> 'CanceledQty'::text)::integer                              as "CanceledQty",
             (rep.payload ->> 'CumQty'::text)::integer                                   as "CumQty",
             row_number()
             OVER (PARTITION BY rep.cl_ord_id, rep.leg_ref_id ORDER BY rep.exec_id DESC) AS rn
      FROM blaze7.order_report rep
      WHERE rep.cl_ord_id::text = '3_0220427'
        AND (rep.leg_ref_id::text in (SELECT leg.leg_ref_id
                                      FROM blaze7.client_order_leg leg
                                      WHERE leg.order_id = rep.order_id
                                        AND leg.chain_id = rep.chain_id
                                        AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text))) x
WHERE x.rn = 1


