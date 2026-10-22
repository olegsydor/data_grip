select * from blaze7.v_lifecycle_order;


select * from (select --DISTINCT ON (co.order_id, co.chain_order_id)
                      co.order_id,
                      co.chain_order_id AS lifecycle_orderid,
                      lc.lifecycle_orderid_status,
                      lc.exec_id,
                      CASE
                          WHEN co.crossing_side IS NULL
                              THEN co.payload #>> '{SocGenRoutingChainId}'::text[]
                          WHEN co.crossing_side = 'O'::bpchar
                              THEN co.payload #>> '{OriginatorOrder,SocGenRoutingChainId}'::text[]
                          WHEN co.crossing_side = 'C'::bpchar
                              THEN co.payload #>> '{ContraOrder,SocGenRoutingChainId}'::text[]
                          ELSE NULL::text
                          END           AS routing_chain_id
               FROM blaze7.client_order co
                        JOIN LATERAL ( SELECT rep.exec_id,
                                              CASE
                                                  WHEN ((rep.payload ->> 'OrderStatus'::text) = ANY
                                                        (ARRAY ['2'::text, '4'::text, 'P'::text, '3'::text])) AND
                                                       (rep.payload ->> 'BlazeOrderStatus'::text) <> 't'::text THEN 'F'::text
                                                  ELSE 'N'::text
                                                  END AS lifecycle_orderid_status
                                       FROM blaze7.order_report rep
                                       WHERE rep.order_id = co.order_id
                                         AND rep.leg_ref_id IS NULL
                                         AND (rep.exec_type <> ALL ('{I,i}'::bpchar[]))
                                       ORDER BY rep.exec_id DESC
                                       LIMIT 1) lc ON true
               WHERE true
                 AND co.parent_order_id IS NULL
--   AND co.db_create_time >= CURRENT_DATE
--   AND co.db_create_time <= (CURRENT_DATE + '1 day'::interval)
              ) x
where routing_chain_id = 'jeffcross4'

select * from blaze7.client_order
where cl_ord_id in ('jeffcross4', 'jeffcrosscontra4')


SELECT DISTINCT ON (co.order_id, co.chain_order_id) co.order_id,
                                                    co.chain_order_id AS lifecycle_orderid,
                                                    lc.lifecycle_orderid_status,
                                                    lc.exec_id,
                                                    CASE
                                                        WHEN co.crossing_side IS NULL
                                                            THEN co.payload #>> '{SocGenRoutingChainId}'::text[]
                                                        WHEN co.crossing_side = 'O'::bpchar
                                                            THEN co.payload #>> '{OriginatorOrder,SocGenRoutingChainId}'::text[]
                                                        WHEN co.crossing_side = 'C'::bpchar
                                                            THEN co.payload #>> '{ContraOrder,SocGenRoutingChainId}'::text[]
                                                        ELSE NULL::text
                                                        END           AS routing_chain_id
FROM blaze7.client_order co
         JOIN LATERAL ( SELECT rep.exec_id,
                               CASE
                                   WHEN ((rep.payload ->> 'OrderStatus'::text) = ANY
                                         (ARRAY ['2'::text, '4'::text, 'P'::text, '3'::text])) AND
                                        (rep.payload ->> 'BlazeOrderStatus'::text) <> 't'::text THEN 'F'::text
                                   ELSE 'N'::text
                                   END AS lifecycle_orderid_status

                        select rep.payload ->> 'OrderStatus', rep.payload ->> 'BlazeOrderStatus', *
                        FROM blaze7.order_report rep
                        WHERE rep.order_id = 967404512232882176
                          AND rep.leg_ref_id IS NULL
                          AND (rep.exec_type <> ALL ('{I,i}'::bpchar[]))
                        ORDER BY rep.exec_id DESC
                        LIMIT 1) lc ON true
WHERE true
  AND co.parent_order_id IS NULL
  AND co.db_create_time >= CURRENT_DATE
  AND co.db_create_time <= (CURRENT_DATE + '1 day'::interval);


select rep.payload ->> 'OrderStatus', rep.payload ->> 'BlazeOrderStatus', *
                        FROM blaze7.order_report rep
                        WHERE rep.order_id in (967075637816737794, 967075637816737796)
                          AND rep.leg_ref_id IS NULL
                          AND (rep.exec_type <> ALL ('{I,i}'::bpchar[]))
                        ORDER BY rep.exec_id DESC