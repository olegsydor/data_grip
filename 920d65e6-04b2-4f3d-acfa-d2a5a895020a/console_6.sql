create temp table t_alias as
select co.cl_ord_id, account_alias
from blaze7.client_order co
         join lateral (select leg.order_id, leg.chain_id
                       from blaze7.client_order_leg leg
                       join blaze7.client_order cl on leg.order_id = cl.order_id and leg.chain_id = cl.chain_id
                       where true
                         and leg.payload ->> 'StitchedSingleOrderId' = co.order_id::text
                       and cl.db_create_time >= co.db_create_time
                       limit 1) leg on true
         join lateral (select cl.payload->> 'AccountAlias' as account_alias
                       from blaze7.client_order cl
                       where cl.order_id = leg.order_id and cl.chain_id = leg.chain_id
                       limit 1) cl on true
where co.payload ->> 'OrderClass' = 'F'
  and co.payload ->> 'HasStitchedOrders' = 'Y'
  and co.db_create_time::date = '2025-08-25'
  and co.cl_ord_id in ('f_0_3q250821', 'f_0_3m250821');



select order_id, payload->>'OrderClass', payload->>'HasStitchedOrders',*
from blaze7.client_order co
where co.cl_ord_id in ('f_0_3q250821','f_0_3m250821');


select payload->> 'StitchedSingleOrderId', *
from blaze7.client_order_leg
where payload->> 'StitchedSingleOrderId' is not null
and payload->> 'StitchedSingleOrderId' in ('813044674737471488', '813044804358242304')

select order_id, payload->>'OrderClass', payload->>'HasStitchedOrders', co.payload ->> 'AccountAlias', *
from blaze7.client_order co
where order_id in (813044874646388736, 813045540504731648)
/*
 if blaze7.client_order.order_class = 'F' and payload ->> 'HasStitchedOrders' = 'Y', then go to:
blaze7.client_order_leg find a leg that has payload.StitchedSingleOrderId = order_id of the order in p.1, if found, then:
go to blaze7.client_order -> payload -> AccountAlias (or OriginatorOrder.AccountAlias) for the order found on step 2
*/

create view blaze7.v_stitched_alias as
select co.cl_ord_id, account_alias
from blaze7.client_order co
         join lateral (select leg.order_id, leg.chain_id
                       from blaze7.client_order cl
                                join blaze7.client_order_leg leg
                                     on leg.order_id = cl.order_id and leg.chain_id = cl.chain_id
                       where true
                         and leg.payload ->> 'StitchedSingleOrderId' = co.order_id::text
                         and cl.db_create_time >= co.db_create_time
                         and cl.db_create_time >= current_date - '7 days'::interval
                       limit 1) leg on true
         join lateral (select CASE
                                  WHEN cl.crossing_side IS NULL THEN cl.payload ->> 'AccountAlias'::text
                                  WHEN cl.crossing_side = 'O'::bpchar
                                      THEN cl.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
                                  WHEN cl.crossing_side = 'C'::bpchar
                                      THEN cl.payload #>> '{ContraOrder,AccountAlias}'::text[]
                                  ELSE NULL::text
                                  END AS account_alias
                       from blaze7.client_order cl
                       where cl.order_id = leg.order_id
                         and cl.chain_id = leg.chain_id
                       limit 1) cl on true
where co.payload ->> 'OrderClass' = 'F'
  and co.payload ->> 'HasStitchedOrders' = 'Y'
  and co.db_create_time >= current_date - '7 days'::interval
  and co.db_create_time < current_date + '1 days'::interval
