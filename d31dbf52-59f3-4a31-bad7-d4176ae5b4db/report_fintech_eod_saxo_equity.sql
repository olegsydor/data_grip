/*
select * from dash360.report_fintech_eod_saxo_equity(20240814, 20240815);
drop function if exists dash360.report_fintech_eod_saxo_equity;
create or replace function dash360.report_fintech_eod_saxo_equity(in_start_date_id integer default get_dateid(current_date),
                                                                  in_end_date_id integer default get_dateid(current_date))
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
    -- OS 20240815 https://dashfinancial.atlassian.net/browse/DEVREQ-4694
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_saxo_equity for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select 'Client ID,Client Account,Status,TDate,VDate,Client Buy/Sell,Amount,Price,Security Name,Security Code (ISIN),Security Code (SEDOL),Security Code (QUICK),Instrument Class,Trade Ccy,Settle Ccy,Gross Cons,Total Comm/Chrg,Net Cons,Trade Ref,Confirmation Narrative,Our Depot Name,Our Depot A/C No.,Our Depot Acc1,Our Nostro Name,Our Nostro A/C No.,Our Nostro Acc1,Principal/Agency,Broker/Cpty,Security Code (RIC),Security Code (Cusip),Net Cons Signed,Tax/Charges,Commissions,Place of Settlement,Client B/S,Price (4DP),Stamp,Levy,Other Fees,Settlement location,Entry date';


    return query
        select array_to_string(ARRAY [
                                   tr.client_id, -- as "Client ID",
                                   a.account_name , -- as "Client Account",
                                   'New'::varchar, -- as "Status",
                                   to_char(tr.trade_record_time, 'yyyyMMDD')::varchar, -- as "TDate",
                                   to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date,
                                                                                     tr.instrument_type_id),
                                           'yyyyMMDD')::varchar, -- as "VDate",
                                   case
                                       when tr.side = '1' then 'BUY'
                                       when tr.side in ('2', '5', '6') then 'SELL'
                                       end::varchar, -- as "Client Buy/Sell",
                                   tr.last_qty::text, -- as "Amount",
                                   tr.last_px::text, -- as "Price",
                                   i.display_instrument_id, -- as "Security Name",
                                   case when fmj.tag_22 = '4' then fmj.tag_48 end, -- as "Security Code (ISIN)",
                                   null::varchar, -- as "Security Code (SEDOL)",
                                   null::varchar, -- as "Security Code (QUICK)",
                                   null::varchar, -- as "Instrument Class",
                                   'USD'::varchar, -- as "Trade Ccy",
                                   'USD'::varchar, -- as "Settle Ccy",
                                   (case
                                        when tr.side = '1' then tr.principal_amount
                                        when tr.side in ('2', '5', '6') then tr.principal_amount * -1
                                       end)::text, -- as "Gross Cons",
                                   (case
                                        when tr.side = '1' then tr.tcce_account_dash_commission_amount
                                        when tr.side in ('2', '5', '6') then tr.tcce_account_dash_commission_amount * -1
                                       end)::text, -- as "Total Comm/Chrg",
                                   (case
                                        when tr.side = '1'
                                            then (tr.principal_amount + tr.tcce_account_dash_commission_amount)
                                        when tr.side in ('2', '5', '6')
                                            then (tr.principal_amount + tr.tcce_account_dash_commission_amount) * -1
                                       end)::text, -- as "Net Cons",
                                   null::varchar, -- as "Trade Ref",
                                   null::varchar, -- as "Confirmation Narrative",
                                   null::varchar, -- as "Our Depot Name",
                                   null::varchar, -- as "Our Depot A/C No.",
                                   null::varchar, -- as "Our Depot Acc1",
                                   null::varchar, -- as "Our Nostro Name",
                                   null::varchar, -- as "Our Nostro A/C No.",
                                   null::varchar, -- as "Our Nostro Acc1",
                                   'A'::varchar, -- as "Principal/Agency",
                                   'Dash Financial Technologies'::varchar, -- as "Broker/Cpty",
            --null, -- as "Security Code (RIC)",
                                   case
                                       when i.symbol_suffix is not null
                                           then concat(
                                               i.symbol,
                                               '.',
                                               replace(replace(
                                                               replace(replace(i.symbol_suffix, 'PR', 'P'), 'RTWI', 'R.W'),
                                                               'RT', 'R'), 'WI', 'W')
                                                )
                                       end::varchar, -- as "Security Code (RIC)",
                                   null::varchar, -- as "Security Code (Cusip)",
                                   (case
                                        when tr.side = '1' then (tr.principal_amount +
                                                                 coalesce(tr.tcce_account_dash_commission_amount,
                                                                          0.0015 * tr.last_qty)) * -1
                                        when tr.side in ('2', '5', '6') then (tr.principal_amount + coalesce(
                                                tr.tcce_account_dash_commission_amount, 0.0015 * tr.last_qty))
                                       end)::text, -- as "Net Cons Signed",
                                   '0.0', -- as "Tax/Charges",
                                   (case
                                        when tr.side = '1' then coalesce(tr.tcce_account_dash_commission_amount,
                                                                         0.0015 * tr.last_qty)
                                        when tr.side in ('2', '5', '6') then
                                            coalesce(tr.tcce_account_dash_commission_amount, 0.0015 * tr.last_qty) * -1
                                       end)::text, -- as "Commissions",
                                   null::varchar, -- as "Place of Settlement",
                                   case
                                       when tr.side = '1' then 'B'
                                       when tr.side in ('2', '5', '6') then 'S'
                                       end::varchar, -- as "Client B/S",
                                   round(tr.last_px, 4)::text, -- as "Price (4DP)",
                                   '0.0', -- as "Stamp",
                                   '0.0', -- as "Levy",
                                   '0.0', -- as "Other Fees",
                                   'DTC'::varchar, -- as "Settlement location",
                                   to_char(tr.trade_record_time, 'yyyyMMDD')::varchar -- as "Entry date"
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account a on (a.account_id = tr.account_id)
                 join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)
                 left join lateral (select fmo.fix_message ->> '22' as tag_22, fmo.fix_message ->> '48' as tag_48
                                    from fix_capture.fix_message_json fmo
                                    where (fmo.date_id = tr.date_id and fmo.fix_message_id = tr.order_fix_message_id)
                                    limit 1) fmj on true
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.trading_firm_id = 'saxo'
          and tr.instrument_type_id = 'E'
          and tr.is_busted = 'N'
          and i.symbol <> 'ZVZZT'
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_fintech_eod_saxo_equity for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$fx$
;
*/
dash360.report_compliance_order_blotter_reg(in_start_date_id, in_end_date_id, in_row_type, in_instrument_type, in_account_ids, in_client_order_ids, in_symbols)

create or replace function dash360.report_compliance_order_blotter_reg(in_start_date_id integer default get_dateid(current_date),
                                                            in_end_date_id integer default get_dateid(current_date),
                                                            in_row_type text default null,
                                                            in_instrument_type character default null,
                                                            in_account_ids integer[] default '{}'::integer[],
                                                            in_client_order_ids character varying[] default '{}'::character varying[],
                                                            in_symbols character varying[] default '{}'::character varying[])
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
-- OS 20240815 https://dashfinancial.atlassian.net/browse/DEVREQ-4712
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_compliance_order_blotter_reg for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;


    return query
        select 'Parent Cl Ord ID,Row Type,Account,Creation Date,Event Date,Creation Time,Routed Time,Event Time,Order Status,Cl Ord ID,Orig Cl Ord ID,Side,Ord Qty,Ex Qty,Lvs Qty,Symbol,Expiration Day,Price,Avg Px,TIF,Ord Type,O/C,Security Type,Root Symbol,Client ID,Capacity,Sub Strategy,Ex Dest,Sending Firm,Event Type,Free Text,Reject Reason,Max Floor,Exec Broker,CMTA,Is Mleg,Is Cross,ATS Auction ID,Cross Ord Type,Fee Sensitivity,Handle Inst,Locate Broker,Leg ID,MPID,OCC Opt Data,Ord Capacity,OSI Symbol,Sub System,Session Eligibility,Sweep Style,Trading Firm';
    return query
        with order_ids_cte as (select co.create_date_id, co.order_id
                               from dwh.client_order po
                                        join dwh.client_order co on (co.create_date_id = po.create_date_id and
                                                                     (co.order_id = po.order_id or co.parent_order_id = po.order_id))
                                        join dwh.historic_security_definition_all hsd
                                             on (hsd.instrument_id = po.instrument_id)
                               where po.create_date_id between in_start_date_id and in_end_date_id
                                 and po.multileg_reporting_type in ('1', '2')
                                 and case
                                         when in_row_type is null then true
                                         when in_row_type = 'Parent' then co.parent_order_id is null
                                         when in_row_type = 'Child' then co.parent_order_id is not null
                                   end
                                 and case
                                         when in_instrument_type is null then true
                                         else hsd.instrument_type_id = in_instrument_type end
                                 and case
                                         when coalesce(in_account_ids, '{}') = '{}' then true
                                         else co.account_id = any (in_account_ids) end
                                 and case
                                         when coalesce(in_client_order_ids, '{}') = '{}' then true
                                         else po.client_order_id = any (in_client_order_ids) end
                                 and case
                                         when coalesce(in_symbols, '{}') = '{}' then true
                                         else hsd.symbol = any (in_symbols) end)
         select array_to_string(ARRAY [
                                   coalesce(pyc.client_order_id, yc.client_order_id), -- as "Parent Cl Ord ID",
                                   case when yc.parent_order_id is null then 'Parent' else 'Child' end, -- as "Row Type",
                                   a.account_name, -- as "Account",
                                   to_char(co.create_time, 'MM/DD/YYYY'), -- as "Creation Date",
                                   to_char(yc.routed_time, 'MM/DD/YYYY'), -- as "Event Date",
                                   to_char(co.create_time, 'HH24:MI:SS.US'), -- as "Creation Time",
                                   to_char(yc.routed_time, 'HH24:MI:SS.US'), -- as "Routed Time",
                                   to_char(yc.exec_time, 'HH24:MI:SS.US'), -- as "Event Time",
                                   lst_ex.order_status_description, -- as "Order Status",
                                   yc.client_order_id, -- as "Cl Ord ID",
                                   orig.client_order_id, -- as "Orig Cl Ord ID",
                                   case
                                       when yc.side = '1' then 'Buy'
                                       when yc.side in ('2', '5', '6') then 'Sell'
                                       else ''
                                       end, -- as "Side",
                                   yc.order_qty::text, -- as "Ord Qty",
                                   yc.day_cum_qty::text, -- as "Ex Qty",
                                   yc.day_leaves_qty::text, -- as "Lvs Qty",
                                   hsd.display_instrument_id, -- as "Symbol",
                                   to_char(hsd.maturity_date, 'MM/DD/YYYY'), -- as "Expiration Day",
                                   round(yc.order_price, 6)::text, -- as "Price",
                                   round(yc.avg_px, 6)::text, -- as "Avg Px",
                                   tif.tif_name, -- as "TIF",
                                   ot.order_type_name, -- as "Ord Type",
                                   case
                                       when co.open_close = 'O' then 'Open'
                                       when co.open_close = 'C' then 'Close'
                                       else '' end, -- as "O/C",
                                   case
                                       when hsd.instrument_type_id = 'E' then 'Equity'
                                       when hsd.instrument_type_id = 'O' then 'Option'
                                       end, -- as "Security Type",
                                   hsd.underlying_symbol, -- as "Root Symbol",
                                   yc.client_id, -- as "Client ID",
                                   cf.customer_or_firm_name, -- as "Capacity",
                                   dss.sub_strategy, -- as "Sub Strategy",
                                   coalesce(exd.ex_destination_desc, co.ex_destination), -- as "Ex Dest",
                                   fc.fix_comp_id, -- as "Sending Firm",
                                   lst_ex.exec_type_description, -- as "Event Type",
                                   lst_ex.text_, -- as "Free Text",
                                   null::text, -- as "Reject Reason",
                                   co.max_floor::text, -- as "Max Floor",
                                   lst_ex.exec_broker, -- as "Exec Broker",
                                   co.clearing_firm_id, -- as "CMTA",
                                   case when yc.multileg_reporting_type = '1' then 'N' else 'Y' end, -- as "Is Mleg",
                                   case when yc.cross_order_id is not null then 'Y' else 'N' end, -- as "Is Cross",
                                   coa.auction_id::text, -- as "ATS Auction ID", -- ??
                                   case
                                       when cro.cross_type = 'C' then 'Customer Match'
                                       when cro.cross_type in ('F', '2') then 'Facilitation'
                                       when cro.cross_type in ('P', '4') then 'Price Improvement Mechanism'
                                       when cro.cross_type = 'S' then 'Solicitation'
                                       when cro.cross_type = 'Q' then 'Qualified Contingent Cross'
                                       when cro.cross_type = '1' then 'Solicitation or Customer Match Order'
                                       else cro.cross_type
                                       end, -- as "Cross Ord Type",
                                   co.fee_sensitivity::text, -- as "Fee Sensitivity",
            --coalesce(fm_ex.tag_21, fm_co.tag_21)                                , -- as "Handle Inst",
                                   co.handl_inst::varchar, -- as "Handle Inst",
                                   co.locate_broker, -- as "Locate Broker",
                                   co.co_client_leg_ref_id, -- as "Leg ID",
                                   a.broker_dealer_mpid, -- as "MPID",           --??
                                   co.occ_optional_data, -- as "OCC Opt Data", --fix_message->>'10441'
                                   doc.order_capacity_name, -- as "Ord Capacity",
                                   hsd.opra_symbol, -- as "OSI Symbol",
                                   ds.sub_system_id, -- as "Sub System",
                                   co.session_eligibility::varchar, -- as "Session Eligibility",
                                   co.sweep_style::varchar, -- as "Sweep Style",
                                   tf.trading_firm_name -- as "Trading Firm"
                                    ], ',', '')
        from order_ids_cte oic
                 join data_marts.f_yield_capture yc
                      on (yc.status_date_id between in_start_date_id and in_end_date_id and
                          yc.status_date_id = oic.create_date_id and yc.order_id = oic.order_id)
                 left join data_marts.f_yield_capture pyc
                           on (pyc.status_date_id between in_start_date_id and in_end_date_id and
                               pyc.status_date_id = yc.status_date_id and pyc.order_id = yc.parent_order_id)
                 join dwh.d_account a on (a.account_id = yc.account_id)
                 join dwh.client_order co on (co.create_date_id between in_start_date_id and in_end_date_id and
                                              co.create_date_id = yc.status_date_id and co.order_id = yc.order_id)
                 left join dwh.client_order orig on (orig.create_date_id between in_start_date_id and in_end_date_id and
                                                     orig.create_date_id = yc.status_date_id and
                                                     orig.order_id = co.orig_order_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = yc.time_in_force_id
                 left join dwh.d_order_type ot on ot.order_type_id = yc.order_type_id
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
                 left join data_marts.d_sub_strategy dss on yc.sub_strategy_id = dss.sub_strategy_id
                 left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                        coalesce(exd.exchange_id, '') = coalesce(yc.exchange_id, '') and
                                                        exd.instrument_type_id = yc.instrument_type_id and
                                                        exd.is_active)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
                 left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
                 left join lateral
            (
            select os.order_status_description, ex.text_, ex.fix_message_id, exec_type_description, exec_broker
            from dwh.execution ex
                     left join dwh.d_order_status os on (os.order_status = ex.order_status and os.is_active)
                     left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
            where ex.order_id = yc.order_id
              and ex.exec_date_id between in_start_date_id and in_end_date_id
              and ex.exec_date_id = yc.status_date_id
              and ex.order_status <> '3'
            order by ex.exec_id desc
            limit 1
            ) lst_ex on true
                 left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id --and fc.is_active
                 left join dwh.client_order2auction coa
                           on coa.create_date_id between in_start_date_id and in_end_date_id and
                              coa.create_date_id = co.create_date_id and coa.order_id = co.order_id
                 left join dwh.d_order_capacity doc on doc.order_capacity_id = co.eq_order_capacity
                 left join dwh.d_sub_system ds on ds.sub_system_unq_id = co.sub_system_unq_id --and ds.is_active
                 left join dwh.cross_order cro on cro.cross_order_id = yc.cross_order_id
        where yc.status_date_id between in_start_date_id and in_end_date_id
          and yc.multileg_reporting_type in ('1', '2')
        order by yc.status_date_id, coalesce(yc.parent_order_id, yc.order_id), yc.order_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_compliance_order_blotter_reg for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;

select *
from dash360.report_compliance_order_blotter_reg(
	in_start_date_id => 20240501,
	in_end_date_id => 20240531,
	--in_row_type => null, -> 'Parent', 'Child'
	--in_instrument_type => null, -> 'E', 'O'
	in_account_ids => '{68871}'
	--in_client_order_ids => array['1_84240523','1_80240523','1_81240523','1_d9240523']
	--in_symbols => array[]
);
'1_2f240501','1_2t240501',
