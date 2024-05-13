select systemorderid, systemordertypeid, status, userid, exchangeconnectionid, legcount, price, quantity, filled, stockfilled, optionfilled, order_id, order_trade_date_id
from trash.so_sync_test_data
where order_trade_date_id between 20240506 and 20240507 and src ='EDW'
except
select systemorderid, systemordertypeid, status, userid, exchangeconnectionid, legcount, round(price::bigint/10000.0, 4) as price, quantity, filled, stockfilled, optionfilled, order_id, order_trade_date_id
from trash.so_sync_test_data
where order_trade_date_id between 20240506 and 20240507 and src ='PG';


SELECT
		torder.systemorderid,
		torder.systemordertypeid,
		torder.status,
		torder.userid::int,
		torder.exchangeconnectionid,
		torder.legcount::int,
		round(torder.price::numeric / 10000.0, 2) as price, --
		torder.quantity::int,
		torder.filled::int,
		torder.stockfilled::int,
		torder.optionfilled::int,
		torder."_order_id" AS order_id
		, torder.order_trade_date_id
	FROM staging.torder_edw AS torder
	where true
--	and torder.order_trade_date_id between :p_date_id and public.get_dateid(public.get_business_date(:p_date_id::text::date, 1))
	and torder."_order_id" = 320934078549344256
