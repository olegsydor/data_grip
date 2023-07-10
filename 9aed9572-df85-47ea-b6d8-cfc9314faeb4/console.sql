SELECT
       co.cl_ord_id                                                                       AS orderid,
       co.route_destination,
       co.payload ->>'IsFlex'
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
                                        cl.route_destination
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
