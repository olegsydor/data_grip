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


    create temp table t_rec
        on commit drop
    as
    select tr.trade_record_id,
           1 as record_num,
           array_to_string(ARRAY [
                               case
                                   when tr.side = '1' then 'B'
                                   when tr.side in ('2', '5', '6') then 'S' end, -- as buy_sell, [1]
                               'NCO', -- as correspondent_office [2-4]
                               '8966731', -- as customer_account_num, --Should we hardcode? [5-10]
                               '?', -- as account_type, --Should we hardcode? [11]
                               rpad(tr.exchange_id, 4), -- as exchange_mnemonic, [12-15]
                               lpad('', 2), -- as filler1, [16-17]
                               lpad(case when tr.instrument_type_id = 'E' then di.symbol else 'OPTION' end,
                                    9), -- as cusip_symbol, --Use Symbol? We don't provide CUISP [18-26]
                               '8', -- as market, [27]
                               '1', -- as blotter, [28]
                               lpad(tr.last_qty::text, 8, '0'), -- as quantity, [29-36]
                               lpad(floor(tr.last_px)::text, 4, '0'), -- as price_whole_number, --Need whole number [37-40]
                               case
                                   when tr.last_px - floor(tr.last_px) < 0
                                       then (10000000 * (tr.last_px - floor(tr.last_px)))::text
                                   else '.' || to_char(10000 * (tr.last_px - floor(tr.last_px)), 'FM0000??')
                                   end, -- as price_decimal, --Need decimal [41-47]
                               ' ', -- as price_code, [48]
                               '9', -- as settlement_date_code, [49]
                               ' ', -- as step_in_step_out_code, [50]
                               'DFIN', -- as executing_broker, [51-54]
                               '0161', -- as contra_broker, [55-58]
                               'Y', -- as clearance_only_flag,[59]
                               ' ', -- as compression_flag, [60]
                               ' ', -- as cross_trade_generate_code, [61]
                               ' ', -- as legend_code_1, [62]
                               ' ', -- as legend_code_2, [63]
                               ' ', -- as confirm_comparison, [64]
                               ' ', -- as commission_or_concession_sales_credit1, [65]
                               'A', -- as execution_account_type, [66]
                               ' ', -- as filler2, [67]
                               rpad('', 7), -- as commission_or_concession_sales_credit2, [68-74]
                               rpad('', 3), -- as rr_override, [75-77]
                               '1', -- as control_field, [78]
                               rpad('', 2) -- as filler3 [79-80]
                               ], '', '')
    from dwh.flat_trade_record tr
             join dwh.d_instrument di on (di.instrument_id = tr.instrument_id)
    where tr.date_id between in_start_date_id and in_end_date_id
      and tr.is_busted = 'N'
      and tr.account_id = any (l_account_ids);



   end;
$fx$;


select
	case when tr.side = '1' then 'B' when tr.side in ('2','5','6') then 'S' end as buy_sell,
	'NCO8966731' as correspondent_office,
	'?' as customer_account_num, ----Should we hardcode?
	'?' as account_type, --Should we hardcode?
	tr.exchange_id as exchange_mnemonic,
	null as filler1,
	(case when tr.instrument_type_id = 'E' then hsd.symbol else 'OPTION' end) as cusip_symbol, --Use Symbol? We don't provide CUISP
	'8' as market,
	'1' as blotter,
	to_char(tr.trade_record_time, 'MMddyyyy') as trade_date,
	to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date, tr.instrument_type_id), 'MMddyyyy') as settlement_date,
	null as order_accum_code,
	null as blank,
	null as standard_instruction_override,
	null as blotter_override,
	null as special_confirm_print,
	null as multiple_round,
	null as cns_override,
	null as transfer_override,
	null as execution_time_milli_seconds,
	null as filler2,
	null as x2nd_rr_override,
	null as x2nd_rr_percentage,
	null as x3rd_rr_override,
	null as x3rd_rr_percentage,
	null as trading_account,
	null as execution_time_hhmm,
	'3' as control_field,
	null as execution_time_ss
from dwh.flat_trade_record tr
join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
where tr.date_id = 20241007
	and tr.is_busted = 'N'