	select
		o."StatusDate"::date as "Period",
		tf.trading_firm_name::varchar as "Trading Firm",
		a.account_name::varchar as "Account",
		cf.customer_or_firm_name::varchar as "Capacity",
		sum(coalesce(o."CumQty", 0))::int8 as "Qty",
		count(distinct o."ClOrdID") as "Parent Order Count"
	from dwh.historic_order_details_storage o
	join dwh.d_account a on (a.account_id = o."AccountID")
	join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
	left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = o."CustomerOrFirm")
	where "Status_Date_id" >= :l_start_quarter_date_id and "Status_Date_id" < :l_date_id
		and o."InstrumentType" = 'O'
		and o."CustomerOrderID" is null
	group by "Period", "Account", "Capacity", "Trading Firm";



	select
		o."StatusDate"::date as "Period",
		tf.trading_firm_name::varchar as "Trading Firm",
		a.account_name::varchar as "Account",
		cf.customer_or_firm_name::varchar as "Capacity",
		o."CumQty" as "Qty",
		o."ClOrdID" as "Parent Order Count"
	from dwh.historic_order_details_storage o
	join dwh.d_account a on (a.account_id = o."AccountID")
	join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
	left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = o."CustomerOrFirm")
	where "Status_Date_id" >= :l_start_quarter_date_id and "Status_Date_id" < :l_date_id
		and o."InstrumentType" = 'O'
		and o."CustomerOrderID" is null
and "ClOrdID" = 'CE7-598143-83wdb'
	and "StatusDate" = '2025-04-07'
	union all
select cl.create_time::date as "Period",
tf.trading_firm_name::varchar as "Trading Firm",
		a.account_name::varchar as "Account",
		cf.customer_or_firm_name::varchar as "Capacity",
		cl.order_qty as "Qty",
		cl.client_order_id as "Parent Order Count"
from dwh.client_order cl
join dwh.d_account a on (a.account_id = cl.account_id)
	join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
	left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = cl.customer_or_firm_id)
where client_order_id = 'CE7-598143-83wdb'
	and create_time::date = '2025-04-07';



