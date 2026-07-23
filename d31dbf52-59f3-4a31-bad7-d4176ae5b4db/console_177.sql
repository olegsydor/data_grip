-- DEVREQ-8753
CREATE OR REPLACE FUNCTION dash360.report_fintech_venue_breakdown_by_symbol(in_start_date_id integer,
                                                                              in_end_date_id integer,
    in_trading_firm_ids varchar(9)[], in_account_ids int8[],
                                                                              in_instrument_type_id character DEFAULT 'O'::bpchar)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_today_date_id int := to_char(current_date, 'YYYYMMDD')::int4;
    l_is_today      bool;
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_int (fast version) for ' || in_start_date_id::text ||
                           '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;


    select par."Cl Ord ID" as "Parent Cl Ord ID",
		   str.status_date_id as "Date ID",
		   dtf.trading_firm_name as "Trading Firm",
		   da.account_name as "Account",
		   coalesce(cons_data.wave_type, case when co.dash_rfr_id is null then 'Route Away' end) as "Wave Type",
		   cons_data.preference_flag as "Preference Flag",
		   --null as "Routing Reason",
		   co.ex_destination as "Venue Routed",
		   case when str.side = '1' and str.order_price <= str.nbbo_ask_price and str.order_price <= str.exch_ask_price
					then true
				when str.side in ('2','5','6') and str.order_price >= str.nbbo_bid_price and str.order_price >= str.exch_bid_price
					then true
				else false
		   end as "Marketability",
	       case when str.side = '1' and str.nbbo_ask_price <= str.exch_ask_price
					then true
				when str.side in ('2','5','6') and str.nbbo_bid_price  >= str.exch_bid_price
					then true
				else false
		   end as "Venue on farside",
		   		 case when str.side = '1' then str.nbbo_ask_price-str.avg_px
			 when str.side in ('2','5','6') then str.avg_px-str.nbbo_bid_price
			 end as "Price Improvement in cents",
		   co.request_number as "Request Number",
		   count(str.order_id) over (partition by str.parent_order_id, wave_no order by str.parent_order_id) as "Child Orders intra-wave",
		   array_agg(str.exchange_id) over (partition by str.parent_order_id, wave_no order by str.parent_order_id)  as "Venues intra-wave",
		   co.liquidity_provider_id as "Liquidity Provider",
		   par.order_qty as "Parent Order Qty",str.order_qty as "Street Order Qty",str.order_price, str.avg_px,
		   str.nbbo_ask_price, str.nbbo_bid_price, str.exch_ask_price , str.exch_bid_price ,str.side, str.order_id, str.day_cum_qty as "Cum Qty"
	from os_surv_par par
	join data_marts.f_yield_capture str on par.order_id = str.parent_order_id and str.status_date_id = in_date_id
	join dwh.client_order co on co.order_id = str.order_id and co.create_date_id = in_date_id
	left join dwh.d_account da on da.account_id = str.account_id
	left join dwh.d_strategy_decision_reason_code dsdrc on dsdrc.strategy_decision_reason_code = co.strtg_decision_reason_code
	left join dwh.d_trading_firm dtf on dtf.trading_firm_unq_id = str.trading_firm_unq_id

	where true
	and par."Date ID" = in_date_id;


    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_int for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED=====', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;
