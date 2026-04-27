-- https://dashfinancial.atlassian.net/browse/DEVREQ-8133
-- https://dashfinancial.atlassian.net/browse/DS-11455

create or replace function dash360.report_tradestation_execution(in_start_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                                 in_end_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                                 in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids integer[];
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_tradestation_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where true
      and case
              when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                  then trading_firm_id = ANY (in_trading_firm_ids)
              else true end;
    return query
        select 'Trade Date,Client Order ID,Quantity,Executed Price,Access Fee,Symbol';

    return query
        select array_to_string(ARRAY [
                                   to_char(tr.order_process_time, 'YYYY-MM-DD'), -- Trade date
                                   tr.client_order_id::text, -- Client Order ID
                                   tr.last_qty::text, -- Quantity
                                   to_char(tr.last_px, 'LFM99999990D009999'), -- Executed Price
                                   to_char(coalesce(tr.tcce_maker_taker_fee_amount, 0) +
                                           coalesce(tr.tcce_trade_processing_fee_amount, 0) +
                                           coalesce(tr.tcce_transaction_fee_amount, 0),
                                           'FM99999999990.09999999'), -- Access Fee
                                   di.symbol -- Symbol
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_instrument di on di.instrument_id = tr.instrument_id
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.account_id = any (l_account_ids)
          and tr.instrument_type_id = 'E'
          and tr.is_busted = 'N'
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_tradestation_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;

select *
from dash360.report_tradestation_execution(in_start_date_id := 20260423, in_end_date_id := 20260423,
                                           in_trading_firm_ids := '{tradstat}');

select * from dwh.d_trading_firm
where trading_firm_name ilike '%Trade%'
and trading_firm_name ilike '%Station%' -- tradstat
