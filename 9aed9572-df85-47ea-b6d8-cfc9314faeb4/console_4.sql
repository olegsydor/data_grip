select * from blaze7.client_order cl
join lateral (
    (select co_1.order_id,
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
            regexp_replace(leg.payload::text, '\\u0000', '', 'g')::json AS leg_payload,
            case co_1.instrument_type
                when 'M'::bpchar then leg.payload ->> 'DashSecurityId'::text
                else co_1.payload ->> 'DashSecurityId'::text
                end                                                     as dashsecurityid
     from (select row_number() over (partition by cl.cl_ord_id order by cl.chain_id desc) as rn,
                  cl.order_id,
                  cl.chain_id,
                  cl.parent_order_id,
                  cl.orig_order_id,
                  cl.record_type,
                  cl.user_id,
                  cl.entity_id,
                  regexp_replace(cl.payload::text, '\\u0000', '', 'g')::json              AS payload,
                  cl.db_create_time,
                  cl.cross_order_id,
                  cl.cl_ord_id,
                  cl.orig_cl_ord_id,
                  cl.crossing_side,
                  cl.instrument_type,
                  cl.order_class,
                  cl.route_type
           from blaze7.client_order cl
           where cl.record_type in ('0', '2')) co_1
              left join blaze7.client_order_leg leg on leg.order_id = co_1.order_id and leg.chain_id = co_1.chain_id
     where co_1.rn = 1
     ) co
left join lateral ( select max(rep.db_create_time) as _last_mod_time
                    from blaze7.order_report rep
                    where rep.order_id = co.order_id
                      and rep.chain_id = co.chain_id
                    limit 1) max_rep on true )