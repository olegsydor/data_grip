select *
FROM (SELECT rep.exec_id,
             mdr.payload AS mdr_payload,
             rep.leg_ref_id,
             rep.payload AS rep_payload,
             rep.exec_type,
             co.order_id,
             co.chain_id,
             co.payload  AS co_payload,
             mdr.db_create_time,
             co.cl_ord_id,
             co.crossing_side,
             co.route_type,
             CASE
                 WHEN rep.leg_ref_id IS NULL THEN co.instrument_type::text
                 ELSE (SELECT leg.payload ->> 'LegInstrumentType'::text
                       FROM blaze7.client_order_leg leg
                       WHERE leg.order_id = co.order_id
                         AND leg.chain_id = co.chain_id
                         AND leg.leg_ref_id::text = rep.leg_ref_id::text)
                 END     AS act_instrument_type
      FROM blaze7.order_report rep
--                JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
               JOIN lateral (select * from blaze7.client_order co where co.order_id = rep.order_id AND co.chain_id = rep.chain_id limit 1) co on true
               JOIN lateral(select * from blaze7.market_data_report mdr where true
                                                 and  case
                                                   when co.order_class <> 'O' then mdr.exec_id::text = rep.exec_id::text
                                                   when co.order_class = 'O'::bpchar
                                                       then (rep.payload ->> 'ExecRefId'::text) = mdr.exec_id::text
                                                   else false end limit 1) mdr on true
      ) v
where db_create_time::date = '2026-07-31'
AND exec_id::text >= 'q0onk7hk0g00';

select *
FROM ( SELECT rep.exec_id,
            mdr.payload AS mdr_payload,
            rep.leg_ref_id,
            rep.payload AS rep_payload,
            rep.exec_type,
            co.order_id,
            co.chain_id,
            co.payload AS co_payload,
            mdr.db_create_time,
            co.cl_ord_id,
            co.crossing_side,
            co.route_type,
                CASE
                    WHEN rep.leg_ref_id IS NULL THEN co.instrument_type::text
                    ELSE ( SELECT leg.payload ->> 'LegInstrumentType'::text
                       FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND leg.leg_ref_id::text = rep.leg_ref_id::text)
                END AS act_instrument_type
           FROM blaze7.market_data_report mdr
             JOIN blaze7.order_report rep ON rep.exec_id::text = mdr.exec_id::text
             JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
          WHERE co.order_class <> 'O'::bpchar AND rep.exec_id::text >= 'q0onk7hk0g00'::text
        UNION ALL
         SELECT rep.exec_id,
            mdr.payload AS mdr_payload,
            rep.leg_ref_id,
            rep.payload AS rep_payload,
            rep.exec_type,
            co.order_id,
            co.chain_id,
            co.payload AS co_payload,
            mdr.db_create_time,
            co.cl_ord_id,
            co.crossing_side,
            co.route_type,
                CASE
                    WHEN rep.leg_ref_id IS NULL THEN co.instrument_type::text
                    ELSE ( SELECT leg.payload ->> 'LegInstrumentType'::text
                       FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND leg.leg_ref_id::text = rep.leg_ref_id::text)
                END AS act_instrument_type
           FROM blaze7.market_data_report mdr
             JOIN blaze7.order_report rep ON (rep.payload ->> 'ExecRefId'::text) = mdr.exec_id::text
             JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
          WHERE co.order_class = 'O'::bpchar AND rep.exec_id::text >= 'q0onk7hk0g00'::text) v
where db_create_time::date = '2026-07-31'
AND exec_id::text >= 'q0onk7hk0g00';