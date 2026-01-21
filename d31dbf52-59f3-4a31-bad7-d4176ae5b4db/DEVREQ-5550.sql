select e.exec_type, co.client_order_id, os.order_status_description, et.exec_type_description, co.create_date_id, e.*
from dwh.execution e
left join dwh.client_order co on (co.create_date_id between 20260101 and 20260116 and co.order_id = e.order_id)
left join dwh.d_order_status os on (os.order_status = e.order_status)
left join dwh.d_exec_type et on (et.exec_type = e.exec_type)
where e.exec_date_id between 20260101 and 20260116
	and e.order_id in (411784692580724843, 411846449868391458)
order by e.order_id, e.exec_id;



select ex.*, ex1.*, gtc.close_date_id, *
from dwh.gtc_order_status gtc
                 join dwh.client_order cl
                      on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id --and cl.parent_order_id is null
                 join dwh.d_account ac on gtc.account_id = ac.account_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
                 inner join dwh.d_trading_firm tf on (tf.trading_firm_id = ac.trading_firm_id)
                 left join lateral (select ex.leaves_qty, exec_date_id, ex.order_status
                                     from dwh.execution ex
                                     where ex.order_id = gtc.order_id
                                       and ex.order_status in ('0', '1')
--                                        and ex.exec_type = 'y'
                                       and ex.exec_date_id >= gtc.create_date_id
                                       and ex.exec_date_id >= :in_start_date_id
                                       and ex.exec_date_id <= :in_end_date_id
                                     order by exec_id desc
                                     limit 1) ex on true
 left join lateral (select ex.leaves_qty
					from dwh.execution ex
					where gtc.order_id = ex.order_id
					  and ex.order_status <> '3'
					  and ex.exec_date_id >= gtc.create_date_id
                                       and ex.exec_date_id >= :in_start_date_id
                                       and ex.exec_date_id <= :in_end_date_id
					order by ex.exec_id desc
					limit 1) ex1 on true
where true
	and gtc.order_id in (411784692580724843, 411846449868391458)
-- and ex.exec_date_id between 20260101 and 20260116;

select * from dwh.get_cum_qty_from_orig_orders(in_order_id => 411846449868391458, in_date_id := 20260114)

select *
             FROM request_for_quote r
                         WHERE r.auction_id = 7590015056170
                           AND r.auction_date_id = 20260116
