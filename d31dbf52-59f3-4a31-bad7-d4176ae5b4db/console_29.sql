
create or replace function dash360.report_fintech_eod_curvature_execution(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
declare
    l_row_cnt int4;
    l_load_id int4;
    l_step_id int4;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_fintech_eod_curvature_execution for interval ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===', 0, 'O')
    into l_step_id;

    return query
        select 'Correspondent,AcctNo,SubAcctNo,ContraAcctNo,TradeDate,TradeAt,SettleDate,Symbol,Side,Qty,Price,Commission,ECNFee,Description,ExecVenue,Capacity,TraderId,OrderId,ReferenceId,ExternalId';

    return query
        select array_to_string(ARRAY [
                                   'CURV',
                                   a.account_name,
                                   null,
                                   null,
                                   to_char(tr.trade_record_time, 'MM/dd/yyyy'),
                                   to_char(tr.trade_record_time, 'HH24:MI:SS.US'),
                                   --public.get_settle_date_by_instrument_type(tr.trade_recor_type_id)SettleDate,
                                   null,
                                   hsd.display_instrument_id,
                                   case
                                       when tr.side = '1' then 'Buy'
                                       when tr.side = '2' then 'Sell'
                                       when tr.side in ('5', '6') then 'Sell Short'
                                       end,
                                   tr.last_qty::text,
                                   tr.last_px::text,
                                   (coalesce(tr.tcce_account_dash_commission_amount, 0) * -1.0)::text,
                                   0.0::text,
                                   null,
                                   'DFIN',
                                   'Agency',
                                   tr.client_id,
                                   tr.client_order_id,
                                   null,
                                   null
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account a on (a.account_id = tr.account_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.trading_firm_id = 'curvature'
          and tr.instrument_type_id = 'E'
          and tr.is_busted = 'N'
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_fintech_eod_curvature_execution for interval ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$

