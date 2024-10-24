select * from dash360.report_fintech_needham_equity(in_start_date_id := 20241022, in_end_date_id:= 20241022)

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
    l_batch_id    text := 'NEEDC';


begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_needham_equity for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account da
             join dwh.d_trading_firm tf on tf.trading_firm_id = da.trading_firm_id
    where tf.trading_firm_id = 'wallstacc'
      and da.is_active;

    -- header
    return query
        select array_to_string(ARRAY [
                                   '*PANDS', -- as heading_literal,
                                   rpad(l_batch_id, 6), -- as batch_id, --Should we hardcode?
                                   lpad('', 48), -- as filler,
                                   to_char(current_date, 'MM/DD/YYYY'), -- as processing_date,
                                   lpad('', 13) -- as filler2
                                   ], '', '');


    create temp table t_rec
        on commit drop
    as
    select tr.trade_record_id,
           case
               when tr.side = '1' then 'B'
               when tr.side in ('2', '5', '6') then 'S' end as side,
           tr.last_qty,
           1                                                as record_num,
           tr.last_px,
           array_to_string(ARRAY [
                               case
                                   when tr.side = '1' then 'B'
                                   when tr.side in ('2', '5', '6') then 'S' end, -- as buy_sell, [1]
                               'NCO', -- as correspondent_office [2-4]
                               '896673', -- as customer_account_num, --Should we hardcode? [5-10]
                               '1', -- as account_type, --Should we hardcode? [11]
--                                rpad(tr.exchange_id, 4), -- as exchange_mnemonic, [12-15]
                               rpad('', 4), -- as exchange_mnemonic, [12-15]
                               lpad('', 2), -- as filler1, [16-17]
                               lpad(case when tr.instrument_type_id = 'E' then di.symbol else 'OPTION' end,
                                    9), -- as cusip_symbol, --Use Symbol? We don't provide CUISP [18-26]
                               '8', -- as market, [27]
                               '1', -- as blotter, [28]
                               lpad(tr.last_qty::text, 8, '0'), -- as quantity, [29-36]
                               lpad(floor(tr.last_px)::text, 4, '0'), -- as price_whole_number, --Need whole number [37-40]
                               to_char(round(10000000 * (last_px - floor(last_px))), 'FM0000000'), -- as price_decimal, --Need decimal [41-47]
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
                               ], '', '')                   as ret_row
    from dwh.flat_trade_record tr
             join dwh.d_instrument di on (di.instrument_id = tr.instrument_id)
    where tr.date_id between in_start_date_id and in_end_date_id
      and tr.is_busted = 'N'
      and tr.account_id = any (l_account_ids);

    insert into t_rec
    select tr.trade_record_id,
           case
               when tr.side = '1' then 'B'
               when tr.side in ('2', '5', '6') then 'S' end as side,
           tr.last_qty,
           3                                                as record_num,
           tr.last_px,
           array_to_string(ARRAY [
                               case
                                   when tr.side = '1' then 'B'
                                   when tr.side in ('2', '5', '6') then 'S' end, -- as buy_sell, [1]
                               'NCO', -- as correspondent_office [2-4]
                               '896673', -- as customer_account_num, --Should we hardcode? [5-10]
                               '1', -- as account_type, --Should we hardcode? [11]
--                                rpad(tr.exchange_id, 4), -- as exchange_mnemonic, [12-15]
                               rpad('', 4), -- as exchange_mnemonic, [12-15]
                               lpad('', 2), -- as filler1, [16-17]
                               lpad(case when tr.instrument_type_id = 'E' then di.symbol else 'OPTION' end,
                                    9), -- as cusip_symbol, --Use Symbol? We don't provide CUISP [18-26]
                               '8', -- as market, [27]
                               '1', -- as blotter, [28]
                               to_char(tr.trade_record_time, 'MMDDYY'), -- as trade_date, [29-34]
                               to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date,
                                                                                 tr.instrument_type_id),
                                       'MMDDYY'), -- as settlement_date, [35-40]
                               ' ', -- as order_accum_code, [41]
                               ' ', -- as blank, [42]
                               ' ', -- as standard_instruction_override, [43]
                               ' ', -- as blotter_override, [44]
                               ' ', -- as special_confirm_print, [45]
                               ' ', -- as multiple_round, [46]
                               ' ', -- as cns_override, [47]
                               ' ', -- as transfer_override, [48]
                               lpad('', 3), -- as execution_time_milli_seconds, [49-51]
                               lpad('', 2), -- as filler2, [52-53]
                               lpad('', 3), -- as x2nd_rr_override, [54-56]
                               lpad('', 2), -- as x2nd_rr_percentage, [57-58]
                               lpad('', 3), -- as x3rd_rr_override, [59-61]
                               lpad('', 2), -- as x3rd_rr_percentage, [62-63]
                               lpad('', 10), -- as trading_account,[64-73]
                               lpad('', 4), -- as execution_time_hhmm,[74-77]
                               '3', -- as control_field, [78]
                               lpad('', 2) -- as execution_time_ss [79-80]
                               ], '', '')                   as ret_row
    from dwh.flat_trade_record tr
             join dwh.d_instrument di on (di.instrument_id = tr.instrument_id)
    where tr.date_id between in_start_date_id and in_end_date_id
      and tr.is_busted = 'N'
      and tr.account_id = any (l_account_ids);

    return query
        select t_rec.ret_row
        from t_rec
        order by trade_record_id, record_num;

    get diagnostics l_row_cnt = row_count;

    return query
        select array_to_string(ARRAY [
                                   '*TRAIL', -- as TRAILER IDENTIFIER [1-6]
                                   lpad(l_batch_id, 6), -- as batch_id, --Should we hardcode? [7-11]
                                   lpad('', 4), -- as filler, [12-15]
                                   lpad(l_row_cnt::text, 7, '0'), -- RECORD COUNT [16-22]
                                   lpad('', 3), -- as filler, [23-25]
                                   lpad((select sum(last_qty)::text from t_rec where side = 'B'), 17,
                                        '0'), -- as Total Buy Quantity [26-42]
                                   lpad('', 3), -- as filler, [43-45]
                                   lpad((select sum(last_qty)::text from t_rec where side = 'S'), 17,
                                        '0'), -- as Total Sell Quantity [46-62]
                                   lpad('', 18) -- as filler, [63-80]
                                   ], '', '');

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_needham_equity for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' completed====', l_row_cnt, 'E')
    into l_step_id;
end;
$fx$;


-------------------------


-- DROP FUNCTION dash360.report_fintech_needham_equity(int4, int4);

create or replace function dash360.report_fintech_pershing_ps_trade_file(in_start_date_id integer, in_end_date_id integer,
                                                              in_trading_firm_ids text[] default '{}'::text[],
                                                              in_account_ids int4[] default '{}'::int4[])
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
    -- 20241021 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4881
    -- 20241023 SO add account_ids and trading_firm_ids as input parameters
declare
    l_row_cnt             int;
    l_load_id             int;
    l_step_id             int;
    l_account_ids         int4[];
    l_batch_id            text     := 'NEEDC';
    l_instrument_type_ids bpchar[] := '{"E"}';


begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_needham_equity for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account da
             join dwh.d_trading_firm tf on tf.trading_firm_id = da.trading_firm_id
    where true
      and case when coalesce(in_account_ids, '{}') = '{}' then true else da.account_id = any (in_account_ids) end
      and case
              when coalesce(in_trading_firm_ids, '{}') = '{}' then true
              else tf.trading_firm_id = any (in_trading_firm_ids) end;

    -- header
    return query
        select array_to_string(ARRAY [
                                   '*PANDS', -- as heading_literal,
                                   rpad(l_batch_id, 6), -- as batch_id, --Should we hardcode?
                                   lpad('', 48), -- as filler,
                                   to_char(current_date, 'MM/DD/YYYY'), -- as processing_date,
                                   lpad('', 13) -- as filler2
                                   ], '', '');


    create temp table t_rec
         on commit drop
    as
    select tr.trade_record_id,
           case
               when tr.side = '1' then 'B'
               when tr.side in ('2', '5', '6') then 'S' end as side,
           tr.last_qty,
           1                                                as record_num,
           array_to_string(ARRAY [
                               case
                                   when tr.side = '1' then 'B'
                                   when tr.side in ('2', '5', '6') then 'S' end, -- as buy_sell, [1]
                               'NCO', -- as correspondent_office [2-4]
                               '896673', -- as customer_account_num, --Should we hardcode? [5-10]
                               '1', -- as account_type, --Should we hardcode? [11]
--                                rpad(tr.exchange_id, 4), -- as exchange_mnemonic, [12-15]
                               rpad('', 4), -- as exchange_mnemonic, [12-15]
                               lpad('', 2), -- as filler1, [16-17]
                               lpad(case when tr.instrument_type_id = 'E' then di.symbol else 'OPTION' end,
                                    9), -- as cusip_symbol, --Use Symbol? We don't provide CUISP [18-26]
                               '8', -- as market, [27]
                               '1', -- as blotter, [28]
                               lpad(tr.last_qty::text, 8, '0'), -- as quantity, [29-36]
                               lpad(floor(tr.last_px)::text, 4, '0'), -- as price_whole_number, --Need whole number [37-40]
                               to_char(round(10000000 * (last_px - floor(last_px))), 'FM0000000'), -- as price_decimal, --Need decimal [41-47]
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
                               ], '', '')                   as ret_row
    from dwh.flat_trade_record tr
             join dwh.d_instrument di on (di.instrument_id = tr.instrument_id)
    where tr.date_id between in_start_date_id and in_end_date_id
      and tr.is_busted = 'N'
      and di.instrument_type_id = any(l_instrument_type_ids)
      and tr.account_id = any (l_account_ids);

    insert into t_rec
    select tr.trade_record_id,
           case
               when tr.side = '1' then 'B'
               when tr.side in ('2', '5', '6') then 'S' end as side,
           tr.last_qty,
           3                                                as record_num,
           array_to_string(ARRAY [
                               case
                                   when tr.side = '1' then 'B'
                                   when tr.side in ('2', '5', '6') then 'S' end, -- as buy_sell, [1]
                               'NCO', -- as correspondent_office [2-4]
                               '896673', -- as customer_account_num, --Should we hardcode? [5-10]
                               '1', -- as account_type, --Should we hardcode? [11]
--                                rpad(tr.exchange_id, 4), -- as exchange_mnemonic, [12-15]
                               rpad('', 4), -- as exchange_mnemonic, [12-15]
                               lpad('', 2), -- as filler1, [16-17]
                               lpad(case when tr.instrument_type_id = 'E' then di.symbol else 'OPTION' end,
                                    9), -- as cusip_symbol, --Use Symbol? We don't provide CUISP [18-26]
                               '8', -- as market, [27]
                               '1', -- as blotter, [28]
                               to_char(tr.trade_record_time, 'MMDDYY'), -- as trade_date, [29-34]
                               to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date,
                                                                                 tr.instrument_type_id),
                                       'MMDDYY'), -- as settlement_date, [35-40]
                               ' ', -- as order_accum_code, [41]
                               ' ', -- as blank, [42]
                               ' ', -- as standard_instruction_override, [43]
                               ' ', -- as blotter_override, [44]
                               ' ', -- as special_confirm_print, [45]
                               ' ', -- as multiple_round, [46]
                               ' ', -- as cns_override, [47]
                               ' ', -- as transfer_override, [48]
                               lpad('', 3), -- as execution_time_milli_seconds, [49-51]
                               lpad('', 2), -- as filler2, [52-53]
                               lpad('', 3), -- as x2nd_rr_override, [54-56]
                               lpad('', 2), -- as x2nd_rr_percentage, [57-58]
                               lpad('', 3), -- as x3rd_rr_override, [59-61]
                               lpad('', 2), -- as x3rd_rr_percentage, [62-63]
                               lpad('', 10), -- as trading_account,[64-73]
                               lpad('', 4), -- as execution_time_hhmm,[74-77]
                               '3', -- as control_field, [78]
                               lpad('', 2) -- as execution_time_ss [79-80]
                               ], '', '')                   as ret_row
    from dwh.flat_trade_record tr
             join dwh.d_instrument di on (di.instrument_id = tr.instrument_id)
    where tr.date_id between in_start_date_id and in_end_date_id
      and di.instrument_type_id = any(l_instrument_type_ids)
      and tr.is_busted = 'N'
      and tr.account_id = any (l_account_ids);

    return query
        select t_rec.ret_row
        from t_rec
        order by trade_record_id, record_num;

    get diagnostics l_row_cnt = row_count;

    return query
        select array_to_string(ARRAY [
                                   '*TRAIL', -- as TRAILER IDENTIFIER [1-6]
                                   lpad(l_batch_id, 6), -- as batch_id, --Should we hardcode? [7-11]
                                   lpad('', 4), -- as filler, [12-15]
                                   lpad(l_row_cnt::text, 7, '0'), -- RECORD COUNT [16-22]
                                   lpad('', 3), -- as filler, [23-25]
                                   lpad((select sum(last_qty)::text from t_rec where side = 'B'), 17,
                                        '0'), -- as Total Buy Quantity [26-42]
                                   lpad('', 3), -- as filler, [43-45]
                                   lpad((select sum(last_qty)::text from t_rec where side = 'S'), 17,
                                        '0'), -- as Total Sell Quantity [46-62]
                                   lpad('', 18) -- as filler, [63-80]
                                   ], '', '');

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_needham_equity for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' completed====', l_row_cnt, 'E')
    into l_step_id;
end;
$function$
;
select * from dash360.report_fintech_pershing_ps_trade_file(in_start_date_id := 20241023, in_end_date_id:= 20241023, in_trading_firm_ids := '{wallstacc}');
select * from dash360.report_fintech_pershing_ps_trade_file(in_start_date_id := 20241022, in_end_date_id:= 20241022, in_account_ids := '{15826, 69422}');


drop table t_rec;


select * from t_rec