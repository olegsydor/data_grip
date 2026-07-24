/*
	Find all parents (parent_order_id = null)
	For each unique chain_order_id
	take latest order_id
	find the latest (by exec_id) report in order_report table where leg_ref_id = NULL using this order_id
	take payload -> OrderStatus
 */
select distinct on (co.order_id, co.chain_order_id) co.order_id,
                                                    co.chain_order_id as lifecycle_orderid,
                                                    (select case
                                                                when rep.payload ->> 'OrderStatus'::text = any
                                                                     (array ['2','4','P', '3']) and
                                                                     rep.payload ->> 'BlazeOrderStatus'::text != 't'
                                                                    then 'F'
                                                                else 'N' end as lifecycle_orderid_status
                                                     from blaze7.order_report rep
                                                     where rep.order_id = co.order_id
                                                       and leg_ref_id is null
                                                     order by rep.exec_id desc
                                                     limit 1)
from blaze7.client_order co
where true
  and co.parent_order_id is null
  and db_create_time between current_date and current_date + interval '1 day'