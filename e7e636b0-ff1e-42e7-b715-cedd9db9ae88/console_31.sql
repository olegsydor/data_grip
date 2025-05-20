select * from dash360.report_fintech_adh_occ_portfolio_cboe_hanweck(20250516, 20250516)

CREATE OR REPLACE FUNCTION dash360.report_fintech_adh_occ_portfolio_cboe_hanweck(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2025-05-20 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-6115
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_occ_portfolio_cboe_hanweck for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;


    return query
        select 'Date, PortfolioId,SubPortfolioId,Symbols,Expiration,Strike,PutCall,InstType,PositionType,Exchange,Quantity,PosSettleDate,Cash,ClientInfo';

    return query
        select array_to_string(ARRAY [
                                   to_char(tr.trade_record_time, 'MM/dd/yyyy'),-- as "Date",
                                   case
                                       when ac.trading_firm_id = 'bgcfin07' then 'A1'
                                       when ac.trading_firm_id = 'jonestrad' then 'A10'
                                       when ac.trading_firm_id = 'keplersui' then 'A11'
                                       when ac.trading_firm_id = 'mpsglobal' then 'A12'
                                       when ac.trading_firm_id = 'needham' then 'A13'
                                       when ac.trading_firm_id = 'murchinsn' then 'A14'
                                       when ac.trading_firm_id = 'cornerstn' then 'A15'
                                       when ac.trading_firm_id = 'rpdfund01' then 'A16'
                                       when ac.trading_firm_id = 'xfasf' then 'A17'
                                       when ac.trading_firm_id = 'bernstein' then 'A18'
                                       when ac.trading_firm_id = 'casey01' then 'A19'
                                       when ac.trading_firm_id = 'bnplon' then 'A2'
                                       when ac.trading_firm_id = 'rfaboxqoo' then 'A20'
                                       when ac.trading_firm_id = 'bearccm' then 'A21'
                                       when ac.trading_firm_id = 'gbwealth' then 'A22'
                                       when ac.trading_firm_id = 'odeoncap' then 'A23'
                                       when ac.trading_firm_id = 'olmission' then 'A24'
                                       when ac.trading_firm_id = 'pumacap' then 'A25'
                                       when ac.trading_firm_id = 'dashnewed' then 'A26'
                                       when ac.trading_firm_id = 'tourmal01' then 'A27'
                                       when ac.trading_firm_id = 'cicmarch' then 'A28'
                                       when ac.trading_firm_id = 'monness' then 'A29'
                                       when ac.trading_firm_id = 'clearst' then 'A3'
                                       when ac.trading_firm_id = 'baycrest' then 'A30'
                                       when ac.trading_firm_id = 'seaport' then 'A31'
                                       when ac.trading_firm_id = 'cowen01' then 'A4'
                                       when ac.trading_firm_id = 'elevation' then 'A5'
                                       when ac.trading_firm_id = 'isigroup' then 'A6'
                                       when ac.trading_firm_id = 'Guggen' then 'A7'
                                       when ac.trading_firm_id = 'imc02' then 'A8'
                                       when ac.trading_firm_id = 'janest03' then 'A9'
                                       else ac.trading_firm_id
                                       end,-- as "PortfolioId",
                                   null,-- as "SubPortfolioId",
                                   os.root_symbol,-- as "Symbols",
                                   to_char(oc.maturity_month, 'FM00') || to_char(oc.maturity_day, 'FM00') ||
                                   to_char(oc.maturity_year, 'FM0000'),-- as "Expiration",
                                   oc.strike_price::text,-- as "Strike",
                                   case when oc.put_call = '0' then 'P' when oc.put_call = '1' then 'C' end,-- as "PutCall",
                                   di.instrument_type_id,-- as "InstType",
                                   'O',-- as "PositionType",
                                   null,-- as "Exchange",
                                   sum(tr.last_qty * (case when tr.side = '1' then 1.0 else -1.0 end))::text,-- as "Quantity",
                                   null,-- as "PosSettleDate",
                                   null,-- as "Cash",
                                   null -- as "ClientInfo"
                                   ], ',', '')
        from genesis2.trade_record tr
                 join genesis2.account ac on (ac.account_id = tr.account_id)
                 join genesis2.instrument di on (di.instrument_id = tr.instrument_id)
                 join genesis2.option_contract oc on (oc.instrument_id = tr.instrument_id)
                 join genesis2.option_series os on (os.option_series_id = oc.option_series_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and di.instrument_type_id = 'O'
          and tr.is_busted = 'N'
          and coalesce(tr.is_billed, 'N') != 'R' --Unreported
          and ac.opt_report_to_mpid = 'MLCB'     --PTA Trades
        group by to_char(tr.trade_record_time, 'MM/dd/yyyy'), ac.trading_firm_id, os.root_symbol, oc.maturity_month,
                 oc.maturity_day,
                 oc.maturity_year, oc.strike_price, oc.put_call, di.instrument_type_id
        order by to_char(tr.trade_record_time, 'MM/dd/yyyy'), ac.trading_firm_id, os.root_symbol, oc.maturity_month,
                 oc.maturity_day,
                 oc.maturity_year, oc.strike_price, oc.put_call, di.instrument_type_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_laniakea_allocation for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;

