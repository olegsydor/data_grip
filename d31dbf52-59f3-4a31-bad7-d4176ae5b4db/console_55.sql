select * from dash360.report_surveillance_first_trade_date_accounts(20240322, 20240322);
create or replace function dash360.report_surveillance_first_trade_date_accounts(in_start_date_id int4,
                                                                                 in_end_date_id int4
)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
    -- If in_end_date_id = today, we need to calculate first trade date by ourselves.
    -- You can take a look at this dwh.upd_account_first_last_trade_date function for reference.
    -- We may need to change tables to something like dwh.flat_trade_record or dwh.execution instead of using the historic tables.
    -- else, we can use the first_trade_date field
DECLARE
    l_row_cnt int4;
    l_load_id int4;
    l_step_id int4;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_surveillance_first_trade_date_accounts STARTED===', 0,
                           'B')
    into l_step_id;

    return query
        select 'Trading Firm ID,Trading Firm Name,Business Model,Account ID,Account Name,Broker/Dealer,Account Holder Type,First Trade Date';

    return query
        select array_to_string(ARRAY [
                                   tf.trading_firm_id, -- as "Trading Firm ID",
                                   tf.trading_firm_name, -- as "Trading Firm Name",
                                   case
                                       when tf.trading_firm_side = '1' then 'Buy Side'
                                       when tf.trading_firm_side = '2' then 'Sell Side'
                                       end, -- as "Business Model",
                                   a.account_id::text, -- as "Account ID",
                                   a.account_name, -- as "Account Name",
                                   a.broker_dealer_mpid, -- as "Broker/Dealer",
                                   a.account_holder_type, -- as "Account Holder Type",
                                   to_char(a.first_trade_date, 'MM/dd/yyyy') -- as "First Trade Date"
                                   ], ',', '')
        from dwh.d_account a
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
        where a.first_trade_date between in_start_date_id::text::date and in_end_date_id::text::date
        order by tf.trading_firm_id, a.account_name;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_surveillance_first_trade_date_accounts FINISHED===',
                           coalesce(l_row_cnt, 0), 'E')
    into l_step_id;
end;
$fx$;

select first_trade_date, * from dwh.d_account
where first_trade_date is not null
-------------------------------------------------------------

select * from dash360.report_fintech_eod_olmission_7u(20240322, 20240322);
create or replace function dash360.report_fintech_eod_olmission_7u(in_start_date_id int4,
                                                        in_end_date_id int4
)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
DECLARE
    l_row_cnt int4;
    l_load_id int4;
    l_step_id int4;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_eod_olmission_7u STARTED===', 0,
                           'B')
    into l_step_id;

    return query
        select 'ACCOUNT,SYMBOL,SIDE,QUANTITY,PRICE,BROKER,EXPYEAR,EXPMONTH,EXPDAY,PUTCALL,STRIKEPRICE,EXCHOUR,EXCMIN,EXCSEC,OPEN_CLOSE';

    return query
        select array_to_string(ARRAY [
                                   a.account_name, -- as "ACCOUNT",
                                   hsd.symbol, --  as "SYMBOL",
                                   case
                                       when tr.side = '1' then 'B'
                                       when tr.side in ('2', '5', '6') then 'S' end, --  as "SIDE",
                                   tr.last_qty::text, --  as "QUANTITY",
                                   round(tr.last_px, 6)::text, --  as "PRICE",
                                   '0792', --  as "BROKER", --tr.exec_broker
                                   trim(right(hsd.maturity_year::text, 2)::text), --  as "EXPYEAR",
                                   hsd.maturity_month::text , -- as "EXPMONTH",
                                   hsd.maturity_day::text, --  as "EXPDAY",
                                   case
                                       when hsd.put_call = '0' then 'P'
                                       when hsd.put_call = '1' then 'C'
                                       end, --  as "PUTCALL",
                                   hsd.strike_px::text, --  as "STRIKEPRICE",
                                   to_char(tr.trade_record_time, 'hh24'), --  as "EXCHOUR",
                                   to_char(tr.trade_record_time, 'mi'), --  as "EXCMIN",
                                   to_char(tr.trade_record_time, 'ss'), --  as "EXCSEC",
                                   tr.open_close --  as "OPEN_CLOSE"
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account a on (a.account_id = tr.account_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.instrument_type_id = 'O'
          and a.account_name in ('AV2L1209', '7JXT1209')
          and tr.exchange_id in ('PHLXFB', 'PHLXML', 'PHLXWX', 'PHLXDH', 'PHLX', 'NSDQO', 'NQBXO', 'BATO')
          and tr.is_busted = 'N'
        order by a.account_name, hsd.symbol,
                 case when tr.side = '1' then 'B' when tr.side in ('2', '5', '6') then 'S' end;--"ACCOUNT", "SYMBOL", "SIDE";

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_eod_olmission_7u FINISHED===',
                           coalesce(l_row_cnt, 0), 'E')
    into l_step_id;
end;
$fx$;
