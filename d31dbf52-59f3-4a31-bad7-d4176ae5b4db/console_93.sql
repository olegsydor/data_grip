 select
	dm.auction_id,
	dm.order_id,
	dm.liquidity_provider_id,
	dm.account_id,
	cl.process_time as transact_time,
	dm.order_qty,
	dm.order_price,
	dm.client_order_id,
	cl.fix_message_id,
	dm.multileg_reporting_type,
	i.display_instrument_id2 display_instrument_id,
	dm.instrument_type_id,
	dm.instrument_id,
	dm.side,
	cl.transaction_id,
	cl.customer_or_firm_id,
	ebr.opt_exec_broker,
	cl.clearing_firm_id,
    cl.step_up_price,
    cl.step_up_price_type,
    dm.resp_match_qty,
    dm.resp_avg_match_px,
	dm.order_status,
	dm.text_ as reason,
	dm.*
from data_marts.f_ats_cons_details dm
inner join dwh.client_order cl on 	dm.order_id = cl.order_id
inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
left join dwh.d_opt_exec_broker ebr on ebr.opt_exec_broker_id = cl.opt_exec_broker_id
where is_ats_or_cons = 'A'
	and cl.parent_order_id is null
	and cl.multileg_reporting_type in ('1',	'2')
    and dm.liquidity_provider_id is not null
    and dm.auction_id = :in_auction_id
    and cl.create_date_id = :l_order_date_id
    and dm.auction_date_id>= :l_order_date_id
	and case when l_ofp_orig_order_id is null then true else dm.ofp_orig_order_id = l_ofp_orig_order_id end
	and case when l_auction_date_id is null then true else dm.auction_date_id = l_auction_date_id end;

-- request
SELECT x.* FROM data_marts.f_rfq_details x
where x.auction_date_id = 20240930
and auction_id = 290003977001;

select acd.side, acd.nbbo_bid_price, acd.nbbo_ask_price, auction_id, auction_date_id, liquidity_provider_id from data_marts.f_ats_cons_details acd
where acd.auction_date_id = 20240930
  and num_nonnulls(acd.nbbo_bid_price, acd.nbbo_ask_price) > 0;