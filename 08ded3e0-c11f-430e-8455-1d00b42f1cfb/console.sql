select *
from dash360.report_billing_belved01_ecr(in_start_date_id := 20250303, in_end_date_id := 20250303);
create or replace
    function dash360.report_billing_belved01_ecr(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
declare
    l_load_id int8;
    l_step_id int;
    l_row_cnt integer;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_belved01_ecr STARTED===', 0, 'O')
    into l_step_id;

    drop table if exists t_base;
    create temp table t_base on commit drop as
    select
-- tcb.date,
tr.date_id,
tr.trade_record_id,
to_char(tr.trade_record_time, 'MM/DD/YYYY')                            as "Date",
to_char(tr.trade_record_time, 'HH24:MI:SS.MS')                         as "Exec Time",
tr.account_name                                                        as "Account",
tr.client_id                                                           as "Client ID",
tr.client_order_id                                                     as "Cl Ord ID",
tr.exch_exec_id                                                        as "Exec ID",
case
    when tr.instrument_type_id = 'E' then 'Equity'
    when tr.instrument_type_id = 'O' then 'Option'
    end                                                                as "Security Type",
tr.sub_strategy                                                        as "Sub Strategy",
coalesce(ex.exchange_name, tr.exchange_id)                             as "Exchange",
case when tr.instrument_type_id = 'O' then tcb.OSISeries else null end as "OSI Symbol",
tr.symbol                                                              as "Symbol",
to_char(tcb.expiration, 'MM/DD/YYYY')                                  as "Exp Date",
case
    when tr.side = '1' then 'Buy'
    when tr.side in ('2', '5', '6') then 'Sell'
    end                                                                as "Side",
tr.last_qty                                                            as "Exec Qty",
tr.last_px                                                             as "Exec Px",
case
    when tr.instrument_type_id = 'E' then tr.last_qty * tr.last_px
    when tr.instrument_type_id = 'O' then tr.last_qty * tr.last_px * 100
    end                                                                as "Principal Amount",
round((coalesce(tcb."LAST$", 0.0) + coalesce(tcb."LADR$", 0.0) + coalesce(tcb."MTF$", 0.0) + coalesce(tcb."ETF$", 0.0) +
       coalesce(tcb."LTF$", 0.0) + coalesce(tcb."TPF$", 0.0) + coalesce(tcb."CATTF$", 0.0))::numeric,
      8)                                                               as "Execution Cost",
round((coalesce(tcb."LAST$", 0.0) + coalesce(tcb."LADR$", 0.0) + coalesce(tcb."MTF$", 0.0) + coalesce(tcb."ETF$", 0.0) +
       coalesce(tcb."LTF$", 0.0) + coalesce(tcb."TPF$", 0.0) + coalesce(tcb."CATTF$", 0.0) / tr.last_qty)::numeric,
      8)                                                               as "Execution Cost/Unit",
round((coalesce(tcb."LAST$", 0.0) + coalesce(tcb."LADR$", 0.0))::numeric,
      8)                                                               as "DashCommission",
round((coalesce(tcb."MTF$", 0.0))::numeric, 8)                         as "Maker/Taker Fee",
round((coalesce(tcb."ETF$", 0.0) + coalesce(tcb."LTF$", 0.0))::numeric,
      8)                                                               as "Transaction Fee",
round((coalesce(tcb."TPF$", 0.0))::numeric, 8)                         as "Trade Processing Fee",
0.0                                                                    as "Royalty Fee",
--round((coalesce(tcb."TAF$", 0.0))::numeric, 8) as "FINRA Trade Activity Fee"
round((coalesce(tcb."CATTF$", 0.0))::numeric, 8)                       as "FINRA CAT Fees"
    from billing_data.tcustomer_billing_detail_all tcb
             join billing_data.fdw_dash_trade_record tr
                  on (tr.date_id between in_start_date_id and in_end_date_id and
                      tr.trading_firm_id in ('belvcaid', 'belved01', 'belved02') and tr.trade_record_id = tcb.report_id)
             left join billing.dash_exchange_names ex on (ex.exchange_id = tr.exchange_id and ex.is_active = '1')
    where true
      and tcb.date between in_start_date_id::text::date and in_end_date_id::text::date --convert(date, getdate()-day(getdate()-1)) and convert(date, getdate()-2)
      and tr.date_id between in_start_date_id and in_end_date_id
      and lower(tcb.billingentity) = 'belved01'
      and lower(tcb.company) in ('belvcaid', 'belved01', 'belved02')
      and tcb."FILLED QTY" > 0;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_belved01_ecr data is prepared', l_row_cnt, 'O')
    into l_step_id;
    create index on t_base (date_id, trade_record_id);

    return query
        select 'Date,Exec Time,Account,Client ID,Cl Ord ID,Exec ID,Security Type,Sub Strategy,Exchange,OSI Symbol,Symbol,Exp Date,Side,Exec Qty,Exec Px,Principal Amount,Execution Cost,Execution Cost/Unit,DashCommission,Maker/Taker Fee,Transaction Fee,Trade Processing Fee,Royalty Fee,FINRA CAT Fees';
    return query
        select array_to_string(ARRAY [
                                   "Date",
                                   "Exec Time",
                                   "Account",
                                   "Client ID",
                                   "Cl Ord ID",
                                   "Exec ID",
                                   "Security Type",
                                   "Sub Strategy",
                                   "Exchange",
                                   "OSI Symbol",
                                   "Symbol",
                                   "Exp Date",
                                   "Side",
                                   "Exec Qty"::text,
                                   to_char("Exec Px", 'FM999990.0099'),
                                   to_char("Principal Amount", 'FM999990.09999999'),
                                   to_char("Execution Cost", 'FM999990.09999999'),
                                   to_char("Execution Cost/Unit", 'FM999990.09999999'),
                                   to_char("DashCommission", 'FM999990.09999999'),
                                   to_char("Maker/Taker Fee", 'FM999990.09999999'),
                                   to_char("Transaction Fee", 'FM999990.09999999'),
                                   to_char("Trade Processing Fee", 'FM999990.09999999'),
                                   to_char("Royalty Fee", 'FM999990.09999999'),
                                   to_char("FINRA CAT Fees", 'FM999990.09999999')
                                   ], ',', '')
        from t_base tr
        order by tr.date_id, tr.trade_record_id;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_belved01_ecr COMPLETED===', l_row_cnt, 'C')
    into l_step_id;
end ;
$fn$;
---------------------------------------------------------------------------------------------------
select * from dash360.report_billing_wedbullofp_execution(in_start_date_id := 20250303, in_end_date_id := 20250304)
create or replace
    function dash360.report_billing_wedbullofp_execution(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
declare
    l_load_id int8;
    l_step_id int;
    l_row_cnt integer;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_billing_wedbullofp_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===', 0, 'O')
    into l_step_id;

    drop table if exists t_base;
    create temp table t_base on commit drop as
    select tcb."date",
           tcb.cl_ord_id                                            as order_id,
           tcb.report_id                                            as execution_id,
           tcb.osiseries                                            as symbol,
           tcb."B/S"                                                as side,
           tcb."FILLED QTY"                                         as contracts,
           tr.price_limit                                           as limit_price,
           case
               when tr.order_type = '1' then 'Market'
               when tr.order_type = '2' then 'Limit'
               when tr.order_type = '3' then 'Stop'
               when tr.order_type = '4' then 'Stop limit'
               when tr.order_type = '5' then 'Market on close'
               when tr.order_type = '7' then 'Limit or better'
               end                                                  as order_type,
           case when tcb.is_marketable = '1' then 'Y' else 'N' end  as is_marketable,
           tcb.premium                                              as avg_filled_price,
           case when tcb."LEG NUMBER" = '1/1' then 'N' else 'Y' end as is_complex,
           case
               when tcb.symbol = 'SPY' then 'SPY'
               when tcb.symbol in
                    ('VIX', 'VIXW', 'SPX', 'SPXW', 'SPXPM', 'OEX', 'XEO', 'RUT', 'RUTW', 'DJX', 'XSP', 'MRUT')
                   then 'Index'
               when tcb."LEG NUMBER" <> '1/1' then 'Complex'
               when tcb.penny = '1' then 'Penny'
               when tcb.penny = '0' then 'Non-Penny'
               end                                                  as pfof_type,
           tcb."FILLED QTY"                                         as executed_contracts,
           case
               when tcb."C/P" = 'S' then tcb."FILLED QTY" * tcb.premium
               when tcb."C/P" in ('C', 'P') then tcb."FILLED QTY" * tcb.premium * 100
               end                                                  as notional_value,
           tcb."PFOFTF"                                             as pfof_rate,
           tcb."PFOFTF$"                                            as estimated_payment
    from billing_data.tcustomer_billing_detail_all tcb
             left join billing_data.fdw_dash_trade_record tr
                       on (true and tr.trading_firm_id in ('OFP0032', 'OFP0132') and tr.trade_record_id = tcb.report_id)
    where true
      and tcb."date" between in_start_date_id::text::date and in_end_date_id::text::date
      and tcb.billingentity = 'WEDBULLOFP'
      and tcb.company in ('OFP0032', 'OFP0132')
      and tcb."C/P" in ('C', 'P')
      and tcb."FILLED QTY" > 0
      and tr.date_id between in_start_date_id and in_end_date_id;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_billing_wedbullofp_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' data is prepared', l_row_cnt, 'O')
    into l_step_id;
    create index on t_base ("date", execution_id);

    return query
        select 'order_id,execution_id,symbol,side,contracts,limit_price,order_type,is_marketable,avg_filled_price,is_complex,pfof_type,executed_contracts,notional_value,pfof_rate,estimated_payment';
    return query
        select array_to_string(ARRAY [
                                   order_id,
                                   execution_id::text,
                                   symbol,
                                   side,
                                   contracts::text,
                                   to_char(limit_price, 'FM999990.099999'),
                                   order_type,
                                   is_marketable,
                                   to_char(avg_filled_price, 'FM999990.099999'),
                                   is_complex,
                                   pfof_type,
                                   executed_contracts::text,
                                   to_char(notional_value, 'FM999990.09999999'),
                                   to_char(pfof_rate, 'FM999990.09999999'),
                                   to_char(estimated_payment, 'FM999990.09999999')
                                   ], ',', '')
        from t_base tr
        order by tr."date", tr.execution_id;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_billing_wedbullofp_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED===', l_row_cnt,
                           'C')
    into l_step_id;
end ;
$fn$;
-------------------------------------------------------

select *
from dash360.report_billing_xfa_ecr(in_start_date_id := 20250110, in_end_date_id := 20250110);
create --or replace
    function dash360.report_billing_xfa_ecr(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
declare
    l_load_id int8;
    l_step_id int;
    l_row_cnt integer;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_xfa_ecr STARTED===', 0, 'O')
    into l_step_id;

    drop table if exists t_base;
    create temp table t_base
        on commit drop
    as
    select date                                                                                 as clear_date,
           to_char(tcb."date", 'MM/dd/yyyy')                                                    as "Date",
           tcb.billingentity                                                                    as "Billing Entity",
           tcb.account                                                                          as "Account",
           tcb."USER"                                                                           as "Client ID",
           tcb.cl_ord_id                                                                        as "Cl Ord ID",
           tcb.report_id                                                                        as "Report ID",
           tcb."SECURITY TYPE"                                                                  as "Sec Type",
           case
               when lower(tcb."connection") like lower(concat(tcb.exchange, ' dash%')) then 'DMA'
               when lower(tcb."connection") like '%blaze%' then tcb."connection"
               else coalesce(substring(tcb."connection" from '.+?(?= |\+|-)'), tcb."connection")
               end                                                                              as "Sub Strategy",
           tcb."CMTA FIRM"                                                                      as "CMTA",
           tcb.giveup                                                                           as "Exec Broker",
           tcb."range"                                                                          as "Cust/Firm",
           tcb.exchange                                                                         as "Exchange",
           tcb."SYMBOL TYPE"                                                                    as "Symbol Type",
           --tcb.osiseries as "OSI Symbol",
           case
               when tcb."C/P" = 'S' then tcb.symbol
               when tcb."C/P" in ('C', 'P') then
                   concat(
                           rpad(tcb.symbol, 6, ' '),
                           to_char(tcb.expiration, 'yyMMdd'),
                           tcb."C/P",
                           lpad((tcb.strike * 1000)::int::varchar, 8, '0')
                   )
               end                                                                              as "OSI Symbol",
           tcb.symbol                                                                           as "Symbol",
           to_char(tcb.expiration, 'MM/dd/yyyy')                                                as "Expiration",
           initcap(tcb."B/S")                                                                   as "Side",
           tcb."FILLED QTY"                                                                     as "Last Qty",
           tcb.premium                                                                          as "Last Px",
           tcb."FILLED QTY" * tcb.premium * (case when tcb."C/P" = 'S' then 1.0 else 100.0 end) as "Principal Amount",
           round((coalesce(tcb."LADR$", 0.0) + coalesce(tcb."LAST$", 0.0) + coalesce(tcb."MTF$", 0.0) +
                  coalesce(tcb."ETF$", 0.0) + coalesce(tcb."TPF$", 0.0))::numeric, 6)           as "Execution Cost",
           round((coalesce(tcb."LADR$", 0.0) + coalesce(tcb."LAST$", 0.0))::numeric, 6)         as "Commission",
           round(coalesce(tcb."MTF$", 0.0)::numeric, 6)                                         as "Maker/Taker Fee",
           round(coalesce(tcb."ETF$", 0.0)::numeric, 6)                                         as "Transaction Fee",
           round(coalesce(tcb."TPF$", 0.0)::numeric, 6)                                         as "Trade Processing Fee",
           round(0.0, 6)                                                                        as "Royalty Fee",
           tcb.subaccount3                                                                      as "Sub Acct 3"
    from billing.billing_data.tcustomer_billing_detail_all tcb
    where true
      and tcb."date" between in_start_date_id::text::date and in_end_date_id::text::date
      and tcb.billingentity in ('FSS', 'FXF', 'FXI', 'FXN', 'XAX', 'XCF', 'XFALP', 'XFC', 'xfa', 'xfachi')
      and (
        tcb."connection" not in ('Stage', 'ManualRoute', 'BrokerPointRouting') or
        (tcb.account = '5CG00007' and tcb."connection" = 'Stage')
        )
      and tcb."FILLED QTY" > 0;
    --and tcb.lp_dash = 'DASH'


    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_xfa_ecr data is prepared',
                           l_row_cnt, 'O')
    into l_step_id;
    create index on t_base (clear_date, "Report ID");

    return query
        select 'Date,Billing Entity,Account,Client ID,Cl Ord ID,Report ID,Sec Type,Sub Strategy,CMTA,Exec Broker,Cust/Firm,Exchange,Symbol Type,OSI Symbol,Symbol,Expiration,Side,Last Qty,Last Px,Principal Amount,Execution Cost,Commission,Maker/Taker Fee,Transaction Fee,Trade Processing Fee,Royalty Fee,Sub Acct 3';
    return query
        select array_to_string(ARRAY [
                                   "Date",
                                   "Billing Entity",
                                   "Account",
                                   "Client ID",
                                   "Cl Ord ID",
                                   "Report ID"::text,
                                   "Sec Type",
                                   "Sub Strategy",
                                   "CMTA",
                                   "Exec Broker",
                                   "Cust/Firm",
                                   "Exchange",
                                   "Symbol Type",
                                   "OSI Symbol",
                                   "Symbol",
                                   "Expiration",
                                   "Side",
                                   "Last Qty"::text,
                                   to_char("Last Px", 'FM999990.009999'),
                                   to_char("Principal Amount", 'FM999990.09999999'),
                                   to_char("Execution Cost", 'FM999990.09999999'),
                                   to_char("Commission", 'FM999990.09999999'),
                                   to_char("Maker/Taker Fee", 'FM999990.09999999'),
                                   to_char("Transaction Fee", 'FM999990.09999999'),
                                   to_char("Trade Processing Fee", 'FM999990.09999999'),
                                   to_char("Royalty Fee", 'FM999990.09999999'),
                                   "Sub Acct 3"
                                   ], ',', '')
        from t_base tcb
        order by tcb.clear_date, tcb."Report ID";

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_xfa_ecr COMPLETED===', l_row_cnt,
                           'C')
    into l_step_id;
end ;
$fn$;