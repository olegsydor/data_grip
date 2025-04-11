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
		sum(o."CumQty") as "Qty",
		count(distinct o."ClOrdID") as "Parent Order Count"
	from dwh.historic_order_details_storage o
	join dwh.d_account a on (a.account_id = o."AccountID")
	join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
	left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = o."CustomerOrFirm")
	where "Status_Date_id" >= :l_start_quarter_date_id and "Status_Date_id" < :l_date_id
		and o."InstrumentType" = 'O'
		and o."CustomerOrderID" is null
	group by "Period", "Account", "Capacity", "Trading Firm";



-- 	union all

    select cl.create_date_id::text::date      as "Period",
           tf.trading_firm_name::varchar      as "Trading Firm",
           a.account_name::varchar            as "Account",
           cf.customer_or_firm_name::varchar  as "Capacity",
           sum(ex.cum_qty)                    as "Qty",
           count(distinct cl.client_order_id) as "Parent Order Count"
    from dwh.client_order cl
             join dwh.d_account a on (a.account_id = cl.account_id and a.is_active)
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id and tf.is_active)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = cl.customer_or_firm_id)
             left join lateral (select sum(ex.last_qty) as cum_qty
                                from dwh.execution ex
                                where ex.order_id = cl.order_id
                                  and ex.exec_date_id >= cl.create_date_id
                                  and ex.exec_type in ('F', 'G')
                                  and ex.is_busted = 'N'
                                limit 1) ex on true
    where true
      and cl.create_date_id >= :l_start_quarter_date_id
      and cl.create_date_id < :l_date_id
      and di.instrument_type_id = 'O'
      and cl.parent_order_id is null
    group by "Period", "Account", "Capacity", "Trading Firm";
