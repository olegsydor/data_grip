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
