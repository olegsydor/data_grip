select
            CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'LegSeqNumber'::text
            ELSE '1'::text
        END AS legnumber,
    leg.*
FROM blaze7.order_report rep
         JOIN LATERAL ( SELECT co_1.order_id,
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
                               co_1.creation_date_id,
                               co_1.order_request_type,
                               co_1.secondary_order_id,
                               co_1.chain_order_id,
                               co_1.order_trade_date,
                               co_1.route_destination,
                               co_1.underlying_request_type
                        FROM blaze7.client_order co_1
                        WHERE co_1.order_id = rep.order_id
                          AND co_1.chain_id = rep.chain_id
                          AND co_1.order_trade_date >= to_char(rep.db_create_time, 'YYYYMMDD'::text)::integer
                        LIMIT 1) co ON true
         LEFT JOIN blaze7.client_order_leg leg ON leg.order_id = co.order_id aND leg.chain_id = co.chain_id and coalesce(rep.leg_ref_id, '0') = leg.leg_ref_id
WHERE rep.multileg_reporting_type <> '3'::bpchar
  AND (co.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
  AND (rep.exec_type::text <> ALL (ARRAY ['f'::text, 'w'::text, 'W'::text, 'g'::text, 'G'::text, 'I'::text, 'i'::text]))
  and rep.exec_id = 'jj7sog9g0000';

select * from blaze7.order_report;

select * from blaze7.client_order_leg
where order_id = 549891100882501632