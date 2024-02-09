-- DROP FUNCTION dash_reporting.get_jefferies(timestamp);

se
select * from dash360.report_rps_trade_details(20240131, 20240201);
select * from dash360.report_rps_trade_details(in_start_date_id := 20240131, in_end_date_id := 20240201, in_instrument_type_id := 'E');

drop function dash360.report_rps_trade_details;
create function dash360.report_rps_trade_details(in_start_date_id int4, in_end_date_id int4,
                                                 in_account_ids integer[],
                                                 in_instrument_type_id char(1) default null::char(1))
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$function$
declare
    l_load_id int;
    l_step_id int;
    row_cnt   int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_rps_trade_details for interval ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

-- Start
    return query
        select
            'Date,Account,Client ID,Cl Ord ID,Parent Ord ID,Ex Destination,ExecID,Ord Type,Price,Transact Time,Last Px,Last Qty,Side,Symbol,Time In Force,Exec Broker,Open Close,Bid Px,Offer Px,Bid Size,Offer Size,' ||
            'OCC Fee,ORF Fee,SEC Fee,Maker/Taker Fee,Transaction Fee,Trade Processing Fee,Royalty Fee,DASH Commission,Exec Type,Security Type,Expiration Date,Put Or Call,Strike Price,Capacity,Clearing Firm,' ||
            'NBBO Bid Px,NBBO Ask Px,NBBO Bid Size,NBBO Ask Size,Liquidity Ind,Leg Ref ID,Penny,Underlying Product';


    return query
        select array_to_string(array [
                                   to_char(ftr.order_process_time at time zone 'America/New_York', 'MM/DD/YYYY') , -- Date
                                   ac.account_name , -- Account
                                   ftr.client_id , -- Client ID
                                   ftr.street_client_order_id , -- Cl Ord ID
                                   ftr.client_order_id , -- Parent Ord Id
                                   case exc.mic_code when 'XPHL' then 'XPHO' else exc.mic_code end, -- Ex Destination
                                   ftr.secondary_exch_exec_id , -- ExecID
                                   case cl.order_type_id
                                       when '1' then 'Market'
                                       when '2' then 'Limit'
                                       else cl.order_type_id end , -- Ord Type
                                   coalesce(staging.trailing_dot(ftr.order_price), '') , -- Price
                                   to_char(ex.exec_time at time zone 'America/New_York', 'HH24:MI:SS.FF3') , -- Transact Time
                                   coalesce(staging.trailing_dot(ftr.last_px), '') , -- Last Px
                                   coalesce(staging.trailing_dot(ftr.last_qty), '') , -- Last Qty
                                   case ftr.SIDE
                                       when '1' then 'Buy'
                                       when '2' then 'Sell'
                                       when '5' then 'Sell Short'
                                       else ftr.side::text end , -- Side
                                   case ftr.instrument_type_id
                                       when 'E' then i.symbol
                                       when 'O' then dos.root_symbol end , -- Symbol
                                   tif.tif_name , -- Time In Force
                                   'DASH' , -- Exec Broker
                                   case ftr.open_close when 'O' then 'Open' when 'C' then 'Close' else '' end , -- Open Close

            -------------------------------Market Data----------------------------------------------
                                   to_char(md.bid_price, 'FM999990.0099'), -- Bid Px
                                   to_char(md.ask_price, 'FM999990.0099'), -- Offer Px
                                   md.bid_quantity::text , -- Bid Size
                                   md.ask_quantity::text , -- Offer Size

                                   to_char(round(ftr.tcce_occ_fee_amount, 4), 'FM999990.0000'), -- OCC Fee
                                   to_char(round(ftr.tcce_option_regulatory_fee_amount, 4), 'FM999990.0000'), -- ORF Fee
                                   to_char(round(ftr.tcce_sec_fee_amount, 4), 'FM999990.0000'), -- SEC Fee
                                   to_char(round(ftr.tcce_maker_taker_fee_amount, 4), 'FM999990.0000'), -- Maker/Taker Fee
                                   to_char(round(ftr.tcce_transaction_fee_amount, 4), 'FM999990.0000'), -- Transaction Fee
                                   to_char(round(ftr.tcce_trade_processing_fee_amount, 4),
                                           'FM999990.0000'), -- Trade Processing Fee
                                   to_char(round(ftr.tcce_royalty_fee_amount, 4), 'FM999990.0000'), -- Royalty Fee
                                   to_char(round(ftr.tcce_account_dash_commission_amount, 4), 'FM999990.0000'), -- DASH Commission
                                   case ex.order_status
                                       when '1' then 'Partially Filled'
                                       when '2' then 'Filled' end , -- Exec Type
                                   case ftr.instrument_type_id
                                       when 'E' then 'Equity'
                                       when 'O' then 'Option' end , -- Exec Type
                                   case ex.order_status
                                       when '1' then 'Partially Filled'
                                       when '2' then 'Filled' end , -- Security Type
                                   case
                                       when ftr.instrument_type_id = 'O'
                                           then
                                           to_char(doc.maturity_month, 'FM00') || '/' ||
                                           to_char(doc.maturity_day, 'FM00') || '/' || doc.maturity_year
                                       end , -- Expiration Date
                                   case doc.put_call when '0' then 'P' when '1' then 'C' else '' end , -- Put Or Call
                                   trim_scale(doc.strike_price)::text , -- Strike Price
                                   ocf.customer_or_firm_name , -- Capacity
                                   cl.clearing_firm_id , -- Clearing Firm
            ----------------------------------NBBO---------------------------------------------------
                                   to_char(ftr.routing_time_bid_price, 'FM999990.0099'), -- NBBO Bid Px
                                   to_char(ftr.routing_time_ask_price, 'FM999990.0099'), -- NBBO Ask Px
                                   ftr.routing_time_bid_qty::text , -- NBBO Bid Size
                                   ftr.routing_time_ask_qty::text, -- NBBO Ask Size


                                   ftr.trade_liquidity_indicator , -- Liquidity Ind
                                   cl.co_client_leg_ref_id, -- Leg Ref ID
                                   case
                                       when i.instrument_type_id = 'O'
                                           then case dos.min_tick_increment when 0.05 then 'N' else 'Y' end
                                       end , -- Penny
                                   case
                                       when coalesce(ui.instrument_type_id, i.instrument_type_id) = 'E'
                                           then 'Equity'
                                       when ui.instrument_type_id = 'I' then 'Index'
                                       end -- Underlying Product
                                   ], ',', '')
        from dwh.flat_trade_record ftr
                 inner join dwh.d_account ac on (ftr.account_id = ac.account_id and ac.is_active)
                 left join dwh.d_customer_or_firm ocf
                           on (ocf.customer_or_firm_id = ftr.opt_customer_firm and ocf.is_active)
                 inner join lateral (select order_status, exec_time
                                     from dwh.execution ex
                                     where ftr.exec_id = ex.exec_id
                                       and ex.order_id = ftr.order_id
                                       and ex.exec_date_id = ftr.date_id
                                     limit 1
            ) ex on true
                 inner join lateral (select co_client_leg_ref_id, clearing_firm_id, time_in_force_id, order_type_id
                                     from dwh.client_order cl
                                     where cl.order_id = ftr.order_id
                                       and cl.create_date_id = to_char(ftr.order_process_time, 'YYYYMMDD')::int
                                     limit 1
            ) cl on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_qty as ask_quantity,
                                           ls.bid_qty as bid_quantity
                                    from dwh.get_routing_market_data(
                                                 in_transaction_id => coalesce(ftr.street_transaction_id, ftr.transaction_id),
                                                 in_exchange_id=>ftr.exchange_id,
                                                 in_multileg_reporting_type=>ftr.multileg_reporting_type,
                                                 in_instrument_id =>ftr.instrument_id,
                                                 in_date_id => public.get_dateid(coalesce(ftr.street_order_process_time, ftr.order_process_time) ::date)) ls
                                    limit 1
            ) md on true
                 inner join dwh.d_time_in_force tif on (tif.tif_id = cl.time_in_force_id and tif.is_active)
                 inner join dwh.d_instrument i on (ftr.instrument_id = i.instrument_id and i.is_active)
                 inner join dwh.d_exchange exc on (exc.exchange_id = ftr.exchange_id and exc.is_active)
                 left join dwh.d_option_contract doc on (doc.instrument_id = ftr.instrument_id and doc.is_active)
                 left join dwh.d_option_series dos on (dos.option_series_id = doc.option_series_id and dos.is_active)
                 left join dwh.d_instrument ui on (ui.instrument_id = dos.underlying_instrument_id and ui.is_active)
        where ftr.multileg_reporting_type in ('1', '2')
          and ftr.date_id between in_start_date_id and in_end_date_id
          and ftr.is_busted <> 'Y'
          and case when coalesce(in_account_ids, '{}') = '{}' then true else ac.account_id = any (in_account_ids) end
          and case when in_instrument_type_id is null then true else ftr.instrument_type_id = in_instrument_type_id end;


    get diagnostics row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_rps_trade_details for interval ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED===',
                           row_cnt, 'O')
    into l_step_id;

end;
$function$
;


select ftr.account_id, ftr.instrument_type_id, ftr.*
from dwh.flat_trade_record ftr
                 inner join dwh.d_account ac on (ftr.account_id = ac.account_id and ac.is_active)
                 left join dwh.d_customer_or_firm ocf
                           on (ocf.customer_or_firm_id = ftr.opt_customer_firm and ocf.is_active)
                 inner join lateral (select order_status, exec_time
                                     from dwh.execution ex
                                     where ftr.exec_id = ex.exec_id
                                       and ex.order_id = ftr.order_id
                                       and ex.exec_date_id = ftr.date_id
                                     limit 1
            ) ex on true
                 inner join lateral (select co_client_leg_ref_id, clearing_firm_id, time_in_force_id, order_type_id
                                     from dwh.client_order cl
                                     where cl.order_id = ftr.order_id
                                       and cl.create_date_id = to_char(ftr.order_process_time, 'YYYYMMDD')::int
                                     limit 1
            ) cl on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_qty as ask_quantity,
                                           ls.bid_qty as bid_quantity
                                    from dwh.get_routing_market_data(
                                                 in_transaction_id => coalesce(ftr.street_transaction_id, ftr.transaction_id),
                                                 in_exchange_id=>ftr.exchange_id,
                                                 in_multileg_reporting_type=>ftr.multileg_reporting_type,
                                                 in_instrument_id =>ftr.instrument_id,
                                                 in_date_id => public.get_dateid(coalesce(ftr.street_order_process_time, ftr.order_process_time) ::date)) ls
                                    limit 1
            ) md on true
                 inner join dwh.d_time_in_force tif on (tif.tif_id = cl.time_in_force_id and tif.is_active)
                 inner join dwh.d_instrument i on (ftr.instrument_id = i.instrument_id and i.is_active)
                 inner join dwh.d_exchange exc on (exc.exchange_id = ftr.exchange_id and exc.is_active)
                 left join dwh.d_option_contract doc on (doc.instrument_id = ftr.instrument_id and doc.is_active)
                 left join dwh.d_option_series dos on (dos.option_series_id = doc.option_series_id and dos.is_active)
                 left join dwh.d_instrument ui on (ui.instrument_id = dos.underlying_instrument_id and ui.is_active)
        where ftr.multileg_reporting_type in ('1', '2')
          and ftr.date_id between :in_start_date_id and :in_end_date_id