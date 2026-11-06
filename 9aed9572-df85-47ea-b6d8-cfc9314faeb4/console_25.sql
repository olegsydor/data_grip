create temp table t_new as
select * from blaze7.so_tordermisc1_edw
where order_trade_date_id = 20261106;


create temp table t_old as
select * from blaze7.tordermisc1_edw
where order_trade_date_id = 20261106;


select order_id, chain_id, parent_order_id, orig_order_id, record_type, db_create_time, cl_ord_id, crossing_side, order_class, secondary_order_id, cross_order_id, route_destination from t_01
except
select order_id, chain_id, parent_order_id, orig_order_id, record_type, db_create_time, cl_ord_id, crossing_side, order_class, secondary_order_id, cross_order_id, route_destination from t_02
create temp table t_01 as
select co.order_id,
       co.chain_id,
       co.parent_order_id,
       co.orig_order_id,
       co.record_type,
       co.payload,
       co.db_create_time,
       co.cl_ord_id,
       co.crossing_side,
       co.order_class,
       co.secondary_order_id,
       co.cross_order_id,
       co.route_destination
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
                                        cl.order_trade_date          AS order_trade_date_id,
                                        CASE
                                            WHEN cl.crossing_side IS NULL AND cl.orig_order_id IS NOT NULL AND
                                                 cl.route_type = 'S'::bpchar
                                                THEN (SELECT co2.payload ->> 'OrderReceiveTime'::text
                                                      FROM blaze7.client_order co2
                                                      WHERE co2.cl_ord_id::text = cl.cl_ord_id::text
                                                      ORDER BY co2.chain_id DESC
                                                      LIMIT 1)
                                            WHEN cl.crossing_side IS NULL AND cl.orig_order_id IS NOT NULL
                                                THEN (SELECT co2.payload ->> 'OrderReceiveTime'::text
                                                      FROM blaze7.client_order co2
                                                      WHERE co2.cl_ord_id::text = cl.cl_ord_id::text
                                                        AND co2.chain_id = 0
                                                      LIMIT 1)
                                            WHEN cl.crossing_side IS NULL AND cl.orig_order_id IS NULL
                                                THEN big.payload ->> 'OrderReceiveTime'::text
                                            WHEN cl.crossing_side = 'O'::bpchar
                                                THEN cl.payload #>> '{OriginatorOrder,OrderReceiveTime}'::text[]
                                            WHEN cl.crossing_side = 'C'::bpchar
                                                THEN cl.payload #>> '{ContraOrder,OrderReceiveTime}'::text[]
                                            ELSE NULL::text
                                            END                      AS receivetime
      FROM blaze7.client_order cl
               LEFT JOIN LATERAL ( SELECT co2.payload
                                   FROM blaze7.client_order co2
                                   WHERE co2.order_id = cl.order_id
                                   ORDER BY co2.chain_id DESC
                                   LIMIT 1) big ON true
      WHERE true
        AND (cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
      ORDER BY cl.cl_ord_id, cl.chain_id DESC) co
where co.cl_ord_id = '3_83q261106';

create temp table t_02 as
select cl.order_id,
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
            cl.route_destination
FROM blaze7.client_order cl
     JOIN LATERAL ( SELECT lst_1.payload AS big_payload,
                CASE
                    WHEN lst_1.route_destination::text = 'BOX QOO'::text AND (lst_1.payload ->> 'IsFlex'::text) = 'Y'::text THEN true
                    ELSE false
                END AS is_q_time,
                CASE
                    WHEN lst_1.route_destination::text = 'BOX QOO'::text AND (lst_1.payload ->> 'IsFlex'::text) = 'Y'::text THEN
                    CASE
                        WHEN lst_1.crossing_side = 'O'::bpchar THEN lst_1.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                        WHEN lst_1.crossing_side = 'C'::bpchar THEN ( SELECT co2.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                           FROM blaze7.client_order co2
                          WHERE co2.cross_order_id = lst_1.cross_order_id AND co2.crossing_side = 'O'::bpchar
                          ORDER BY co2.chain_id DESC
                         LIMIT 1)
                        ELSE NULL::text
                    END
                    ELSE NULL::text
                END AS q_time,
            lst_1.order_trade_date AS order_trade_date_id,
                CASE
                    WHEN lst_1.crossing_side IS NULL AND lst_1.orig_order_id IS NOT NULL AND lst_1.route_type = 'S'::bpchar THEN ( SELECT co2.payload ->> 'OrderReceiveTime'::text
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = lst_1.cl_ord_id::text
                      ORDER BY co2.chain_id DESC
                     LIMIT 1)
                    WHEN lst_1.crossing_side IS NULL AND lst_1.orig_order_id IS NOT NULL THEN ( SELECT co2.payload ->> 'OrderReceiveTime'::text
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = lst_1.cl_ord_id::text AND co2.chain_id = 0
                     LIMIT 1)
                    WHEN lst_1.crossing_side IS NULL AND cl.orig_order_id IS NULL THEN lst_1.payload ->> 'OrderReceiveTime'::text
                    WHEN lst_1.crossing_side = 'O'::bpchar THEN lst_1.payload #>> '{OriginatorOrder,OrderReceiveTime}'::text[]
                    WHEN lst_1.crossing_side = 'C'::bpchar THEN lst_1.payload #>> '{ContraOrder,OrderReceiveTime}'::text[]
                    ELSE NULL::text
                END AS receivetime,
            lst_1.cl_ord_id,
            lst_1.chain_id
           FROM blaze7.client_order lst_1
          WHERE lst_1.cl_ord_id::text = cl.cl_ord_id::text
          ORDER BY lst_1.chain_id DESC
         LIMIT 1) lst ON true AND lst.cl_ord_id::text = cl.cl_ord_id::text AND lst.chain_id = cl.chain_id
     left JOIN LATERAL ( SELECT rep_1.db_create_time
           FROM blaze7.order_report rep_1
          WHERE rep_1.order_id = cl.order_id AND rep_1.chain_id = cl.chain_id
         LIMIT 1) rep ON true
     LEFT JOIN LATERAL ( SELECT org_1.db_create_time
           FROM blaze7.client_order org_1
          WHERE org_1.orig_order_id IS NOT NULL AND org_1.orig_order_id = cl.order_id AND org_1.db_create_time >= cl.db_create_time
         LIMIT 1) org ON true
  WHERE true AND (cl.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar]))
and cl.cl_ord_id = '3_83q261106';