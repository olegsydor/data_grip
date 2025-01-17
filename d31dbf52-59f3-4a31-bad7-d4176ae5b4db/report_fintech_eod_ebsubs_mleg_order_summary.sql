select * from dash360.report_fintech_eod_ebsubs_mleg_order_summary(20241201, 20241231);
create function dash360.report_fintech_eod_ebsubs_mleg_fillpx_exceeds_farside(in_start_date_id integer default public.get_dateid(current_date),
                                                                              in_end_date_id integer default public.get_dateid(current_date))
    returns table
            (
                "Create Date"                  text,
                "Client Order ID"              varchar(256),
                "Symbol"                       varchar,
                "Leg Count"                    text,
                "Order Qty"                    int4,
                "Order Px"                     numeric,
                "Exec Qty"                     int8,
                "Exec Px"                      numeric,
                "Min Farside Imp NBBO"         numeric,
                "$ Improvement vs Imp Farside" numeric
            )
    language plpgsql
as
$function$
    -- 2025-01-17 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5079
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_ebsubs_mleg_fillpx_exceeds_farside for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        with cte_my as (select my.create_date_id,
                               my.client_order_id,
                               my.symbol,
                               my.side,
                               max(my.create_time)                      as create_time,
                               max(my.nbbo_ask_px_client)               as nbbo_ask_px_client,
                               max(my.nbbo_bid_px_client)               as nbbo_bid_px_client,
                               max(option_leg_count)                    as option_leg_count,
                               max(my.client_order_option_contract_qty) as order_qty,
                               max(my.price)                            as price,
                               sum(my.street_fill_option_contract_qty)  as street_total_fill_qty,
                               max(my.avg_px)                           as fill_px
                        from data_marts.mleg_yc my
                        where my.create_date_id between in_start_date_id and in_end_date_id
                          and my.trading_firm_id = 'ebsubs'
                          and my.multileg_reporting_type = '3'
                          and my.target_strategy_name = 'SENSOR'
                          and my.street_fill_option_contract_qty > 0     --is_filled
                          and my.client_order_marketability_ratio >= 1.0 --is_marketable
                        group by my.create_date_id, my.client_order_id, my.symbol, my.side)
        select to_char(my.create_time, 'yyyy-MM-dd')                                     as "Create Date",
               my.client_order_id                                                        as "Client Order ID",
               my.symbol                                                                 as "Symbol",
               concat(coalesce(my.option_leg_count, 0), ' Leg Spread')                   as "Leg Count",
               my.order_qty                                                              as "Order Qty",
               round(my.price, 4)                                                        as "Order Px",
               my.street_total_fill_qty                                                  as "Exec Qty",
               round(my.fill_px, 4)                                                      as "Exec Px",
               round(my.nbbo_ask_px_client, 4)                                           as "Min Farside Imp NBBO",
               round((my.nbbo_ask_px_client - my.fill_px) * my.street_total_fill_qty,
                     4)                                                                  as "$ Improvement vs Imp Farside"
        from cte_my as my
        where (my.price > my.nbbo_bid_px_client and my.fill_px > my.nbbo_ask_px_client)
        order by my.create_time, my.client_order_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_ebsubs_mleg_fillpx_exceeds_farside for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;


with cte_my as (
	select
		my.create_date_id,
		my.client_order_id,
		my.symbol,
		my.side,
		max(my.create_time) as create_time,
		max(my.nbbo_ask_px_client) as nbbo_ask_px_client,
		max(my.nbbo_bid_px_client) as nbbo_bid_px_client,
		max(option_leg_count) as option_leg_count,
		max(my.client_order_option_contract_qty) as order_qty,
		max(my.price) as price,
		sum(my.street_fill_option_contract_qty) as street_total_fill_qty,
		max(my.avg_px) as fill_px
	from data_marts.mleg_yc my
	where my.create_date_id between 20241201 and 20241231
		and my.trading_firm_id = 'ebsubs'
		and my.multileg_reporting_type = '3'
		and my.target_strategy_name = 'SENSOR'
		and my.street_fill_option_contract_qty > 0 --is_filled
		and my.client_order_marketability_ratio >= 1.0 --is_marketable
		--and (my.price > my.nbbo_bid_px_client and my.avg_px > my.nbbo_ask_px_client) --is_fillpx_exceeds_implied_farside_nbbo
	group by my.create_date_id, my.client_order_id, my.symbol, my.side
)
select
	to_char(my.create_time, 'yyyy-MM-dd') as "Create Date",
	my.client_order_id as "Client Order ID",
	my.symbol as "Symbol",
	concat(coalesce(my.option_leg_count, 0), ' Leg Spread') as "Leg Count",
	my.order_qty as "Order Qty",
	round(my.price, 4) as "Order Px",
	my.street_total_fill_qty as "Exec Qty",
	round(my.fill_px, 4) as "Exec Px",
	round(my.nbbo_ask_px_client, 4) as "Min Farside Imp NBBO",
	round((my.nbbo_ask_px_client - my.fill_px) * my.street_total_fill_qty, 4) as "$ Improvement vs Imp Farside"
	--round(abs(abs(my.nbbo_ask_px_client) - abs(my.fill_px)) * my.street_total_fill_qty, 4) as "$ Improvement vs Imp Farside (new)"
from cte_my as my
where (my.price > my.nbbo_bid_px_client and my.fill_px > my.nbbo_ask_px_client) --is_fillpx_exceeds_implied_farside_nbbo
order by my.create_time, my.client_order_id;
