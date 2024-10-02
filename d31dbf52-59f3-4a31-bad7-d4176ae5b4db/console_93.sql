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

 select acd.side,
        acd.nbbo_bid_price,
        acd.nbbo_ask_price,
        auction_id,
        auction_date_id,
        acd.liquidity_provider_id,
        acd.order_id,
        fmj.message_type,
        *
 from data_marts.f_ats_cons_details acd
          join dwh.client_order cl on cl.order_id = acd.order_id and cl.create_date_id >= acd.auction_date_id
          join fix_capture.fix_message_json fmj on fmj.fix_message_id = cl.fix_message_id
 where acd.auction_date_id = 20240930
   and num_nonnulls(acd.nbbo_bid_price, acd.nbbo_ask_price) > 0
   and acd.liquidity_provider_id is not null
   and fmj.message_type = 's'
 and acd.auction_id = 7190003581231;


 select min(acd.auction_date_id)                                              as min_date_id,
        max(acd.auction_date_id)                                              as max_date_id,
        case
            when count(distinct acd.side) = 2 then 'both'
            else case when min(acd.side) = '1' then 'buy' else 'sell' end end as side,
        min(acd.nbbo_bid_price)                                               as bid,
        min(acd.nbbo_ask_price)                                               as ask,
--
-- select
        acd.auction_id,
        acd.auction_date_id,
        acd.liquidity_provider_id,
        acd.ofp_orig_order_id, -- to order_id ofp order
         *
--         array_agg(fmj.message_type) as message_type
 from data_marts.f_ats_cons_details acd
          join dwh.client_order cl on cl.order_id = acd.order_id and cl.create_date_id >= acd.auction_date_id --tf lpo
--           join fix_capture.fix_message_json fmj on fmj.fix_message_id = cl.fix_message_id
 where acd.auction_date_id between 20240930 and 20241001
--    and num_nonnulls(acd.nbbo_bid_price, acd.nbbo_ask_price) > 0
--    and acd.liquidity_provider_id is not null
--    and fmj.message_type = 's'
    and acd.auction_id = 290004016470
--  and is_lpo_parent
-- and cl.ex_destination = 'LIQPT'
--  and is_ats_or_cons = 'A'
 group by acd.auction_id, acd.auction_date_id, acd.liquidity_provider_id;
--  having count(distinct acd.side) = 1;