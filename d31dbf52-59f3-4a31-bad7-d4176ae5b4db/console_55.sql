select * from dash360.report_surveillance_first_trade_date_accounts(20240327, 20240327);
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

declare
    l_row_cnt         int4;
    l_load_id         int4;
    l_step_id         int4;
    l_start_date      date := in_start_date_id::text::date;
    l_end_date        date := in_end_date_id::text::date;
    l_current_date_id int4 := to_char(current_date, 'YYYYMMDD')::int4;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_surveillance_first_trade_date_accounts STARTED===', 0,
                           'B')
    into l_step_id;


    create temp table t_account on commit drop
    as
    select tf.trading_firm_id,
           tf.trading_firm_name,
           tf.trading_firm_side,
           a.account_id,
           a.account_name,
           a.broker_dealer_mpid,
           a.account_holder_type,
           a.first_trade_date
    from dwh.d_account a
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
    where a.first_trade_date between l_start_date and l_end_date;
--     raise notice 'Old - %', clock_timestamp();

    if current_date between l_start_date and l_end_date then
        insert into t_account
        select distinct on (a.account_id) tf.trading_firm_id,
                                          tf.trading_firm_name,
                                          tf.trading_firm_side,
                                          a.account_id,
                                          a.account_name,
                                          a.broker_dealer_mpid,
                                          a.account_holder_type,
                                          current_date
        from dwh.d_account a
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 join dwh.client_order cl on (cl.create_date_id = l_current_date_id and cl.account_id = a.account_id)
        where a.first_trade_date is null
          and a.is_active
          and not exists (select null from t_account ta where ta.account_id = a.account_id);
    end if;
--     raise notice 'New - %', clock_timestamp();

    return query
        select 'Trading Firm ID,Trading Firm Name,Business Model,Account ID,Account Name,Broker/Dealer,Account Holder Type,First Trade Date';

    return query
        select array_to_string(ARRAY [
                                   ta.trading_firm_id, -- as "Trading Firm ID",
                                   ta.trading_firm_name, -- as "Trading Firm Name",
                                   case
                                       when ta.trading_firm_side = '1' then 'Buy Side'
                                       when ta.trading_firm_side = '2' then 'Sell Side'
                                       end, -- as "Business Model",
                                   ta.account_id::text, -- as "Account ID",
                                   ta.account_name, -- as "Account Name",
                                   ta.broker_dealer_mpid, -- as "Broker/Dealer",
                                   ta.account_holder_type, -- as "Account Holder Type",
                                   to_char(ta.first_trade_date, 'MM/dd/yyyy') -- as "First Trade Date"
                                   ], ',', '')
        from t_account ta
        order by ta.trading_firm_id, ta.account_name;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_surveillance_first_trade_date_accounts FINISHED===',
                           coalesce(l_row_cnt, 0), 'E')
    into l_step_id;
end;
$fx$;

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


select first_trade_date, * from

                               dwh.d_account
where first_trade_date is not null
;


select distinct on (a.account_id) *
from dwh.d_account a
         join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
    join dwh.flat_trade_record ftr
                            on
                                ftr.date_id = :in_start_date_id
                              and ftr.account_id = a.account_id
                              and ftr.is_busted = 'N'
where true
  and a.first_trade_date is null
    and case when :in_start_date_id != to_char(current_date, 'YYYYMMDD')::int4 then a.first_trade_date = :in_start_date else true end
and case when :in_start_date_id != to_char(current_date, 'YYYYMMDD')::int4 then true else (a.first_trade_date is null and td.first_trade_date is not null) end
order by tf.trading_firm_id, a.account_name;



    create temp table t_account on commit drop
    as