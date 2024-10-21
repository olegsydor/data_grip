create or replace function dash360.report_fintech_needham_equity(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
    -- 20241021 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4881
declare
    l_row_cnt     int;
    l_load_id     int;
    l_step_id     int;
    l_account_ids int4[];


begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_needham_equity for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
--     into l_account_ids
    from dwh.d_account da
    join dwh.d_trading_firm tf on tf.trading_firm_id = da.trading_firm_id
    where tf.trading_firm_id = 'wallstacc'
    and da.is_active;

    -- header
    return query
        select array_to_string(ARRAY [
                                   '*PANDS', -- as heading_literal,
                                   lpad('123456', 6), -- as batch_id, --Should we hardcode?
                                   lpad('', 48), -- as filler,
                                   to_char(current_date, 'MM/DD/YYYY'), -- as processing_date,
                                   lpad('', 13) -- as filler2
                                   ], '', '');


   end;
$fx$

s
select
	case when tr.side = '1' then 'B' when tr.side in ('2','5','6') then 'S' end, -- as buy_sell, [1]
	'NCO', -- as correspondent_office [2-4]
 	'8966731', -- as customer_account_num, --Should we hardcode? [5-10]
	'?', -- as account_type, --Should we hardcode? [11]
	rpad(tr.exchange_id, 4), -- as exchange_mnemonic, [12-15]
	lpad('', 2), -- as filler1, [16-17]
	lpad(case when tr.instrument_type_id = 'E' then di.symbol else 'OPTION' end, 9), -- as cusip_symbol, --Use Symbol? We don't provide CUISP [18-26]
	'8', -- as market, [27]
	'1', -- as blotter, [28]
	tr.last_qty as quantity,
	tr.last_px as price_whole_number, --Need whole number
	tr.last_px as price_decimal, --Need decimal
	null as price_code,
	'9' as settlement_date_code,
	null as step_in_step_out_code,
	'DFIN' as executing_broker,
	'0161' as contra_broker,
	'Y' as clearance_only_flag,
	null as compression_flag,
	null as cross_trade_generate_code,
	null as legend_code_1,
	null as legend_code_2,
	null as confirm_comparison,
	null as commission_or_concession_sales_credit1,
	'A' as execution_account_type,
	null as filler2,
	null as commission_or_concession_sales_credit2,
	null as rr_override,
	'1' as control_field,
	null as filler3
from dwh.flat_trade_record tr
join dwh.d_instrument di on (di.instrument_id = tr.instrument_id)
where tr.date_id = 20241007
	and tr.is_busted = 'N'
and tr.account_id = any(:l_account_ids)