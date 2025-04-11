create --or replace
    function dash360.report_billing_traimc_summary(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
declare
    l_load_id       int8;
    l_step_id       int;
    l_row_cnt       integer;
    l_start_date_id date := in_start_date_id::text::date;
    l_end_date_id   date := in_end_date_id::text::date;
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_traimc_summary STARTED===', 0, 'O')
    into l_step_id;

    drop table if exists t_base;
    create temp table t_base on commit drop as
    select 'TRAD'                                                   as "MPID",
           to_char(tcb."date", 'MM/dd/yyyy')                        as "Trade Date",
           tcb.billto_id                                            as "Client ID",
           'TOTAL'                                                  as "Rate Category",
           case when tcb."LEG NUMBER" = '1/1' then 'N' else 'Y' end as "Spread",
           count(distinct tcb.cl_ord_id)                            as "EXEC ORDERS",
           sum(tcb."FILLED QTY")                                    as "EXEC QUANTITY",
           sum(coalesce(tcb."PFOFTF$", 0.00))                       as "PFOF"
    from billing.billing_data.tcustomer_billing_detail_all tcb
    where tcb."date" between l_start_date_id and l_end_date_id
      and tcb.billingentity = 'TRAIMC'
      and tcb."FILLED QTY" > 0
    group by "Trade Date", "Client ID", "Spread";

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_traimc_summary data is prepared', l_row_cnt,
                           'O')
    into l_step_id;
    create index on t_base ("Trade Date", "Client ID", "Spread");

    return query
        select 'MPID,Trade Date,Client ID,Rate Category,Spread,EXEC ORDERS,EXEC QUANTITY,PFOF';
    return query
        select array_to_string(ARRAY [
                                   "MPID",
                                   "Trade Date",
                                   "Client ID"::text,
                                   "Rate Category",
                                   "Spread",
                                   "EXEC ORDERS"::text,
                                   "EXEC QUANTITY"::text,
                                   "PFOF"::text
                                   ], ',', '')
        from t_base tr
        order by tr."Trade Date", tr."Client ID", tr."Spread";

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_traimc_summary COMPLETED===', l_row_cnt, 'C')
    into l_step_id;
end ;
$fn$;

select * from dash360.report_billing_traimc_summary(in_start_date_id := 20250407, in_end_date_id := 20250409);



-----------------------------
select * from dash360.report_billing_traimc_data(in_start_date_id := 20250407, in_end_date_id := 20250409);

create or replace
    function dash360.report_billing_traimc_data(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
declare
    l_load_id       int8;
    l_step_id       int;
    l_row_cnt       integer;
    l_start_date_id date := in_start_date_id::text::date;
    l_end_date_id   date := in_end_date_id::text::date;
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_traimc_data STARTED===', 0, 'O')
    into l_step_id;

    drop table if exists t_base;
    create temp table t_base on commit drop as
    select to_char(tcb."date", 'MM/dd/yyyy')                                        as "Trade Date",
           'TRAD'                                                                   as "MPID",
           'TOTAL'                                                                  as "Rate Category",
           lf.exchangecode                                                          as "Exch",
           tcb."B/S"                                                                as "B/S",
           tcb."C/P"                                                                as "P/C",
           tcb."FILLED QTY"::text                                                   as "QTY",
           tcb.symbol                                                               as "Class",
           tcb.symbol                                                               as "Sym",
           to_char(tcb.date, 'MM')                                                  as "Mo",
           to_char(tcb.date, 'YY')                                                  as "Yr",
           tcb.strike::text                                                         as "Strike",
           tcb.premium::text                                                        as "Price",
           tcb.open_close                                                           as "O/C",
           ''                                                                       as "optional_data",
           tcb.cl_ord_id                                                            as "client_order_ID",
           tcb."CMTA FIRM"                                                          as "CMTA",
           tcb.giveup                                                               as "Ex Firm",
           tcb.billto_id::text                                                      as "Client ID",
           tcb.account                                                              as "Account",
           tcb."SYMBOL TYPE"                                                        as "Product",
           case when tcb.penny::integer = 1 then 'Y' else 'N' end                   as "Penny",
           case when tcb."LEG NUMBER" = '1/1' then 'N' else 'Y' end                 as "Spread",
           tcb."ORDER TYPE"                                                         as "Route",
           tcb.liquidityflag                                                        as "Liquidity",
           to_char(coalesce(round("LADR"::numeric, 6), 0.00), 'FM999990.009999')    as "LADR",
           to_char(coalesce(round("LADR$"::numeric, 6), 0.00), 'FM999990.009999')   as "LADR$",
           to_char(coalesce(round("ETF"::numeric, 6), 0.00), 'FM999990.009999')     as "ETF",
           to_char(coalesce(round("ETF$"::numeric, 6), 0.00), 'FM999990.009999')    as "ETF$",
           to_char(coalesce(round("MTF"::numeric, 6), 0.00), 'FM999990.009999')     as "MTF",
           to_char(coalesce(round("MTF$"::numeric, 6), 0.00), 'FM999990.009999')    as "MTF$",
           to_char(coalesce(round("LTF"::numeric, 6), 0.00), 'FM999990.009999')     as "LTF",
           to_char(coalesce(round("LTF$"::numeric, 6), 0.00), 'FM999990.009999')    as "LTF$",
           to_char(coalesce(round("SRCTF"::numeric, 6), 0.00), 'FM999990.009999')   as "SRCTF",
           to_char(coalesce(round("SRCTF$"::numeric, 6), 0.00), 'FM999990.009999')  as "SRCTF$",
           to_char(coalesce(round("PFOFTF"::numeric, 6), 0.00), 'FM999990.009999')  as "PFOFTF",
           to_char(coalesce(round("PFOFTF$"::numeric, 6), 0.00), 'FM999990.009999') as "PFOFTF$",
           to_char(round((coalesce("LADR$"::numeric, 0.00) + coalesce("ETF$"::numeric, 0.00) +
                          coalesce("MTF$"::numeric, 0.00) +
                          coalesce("LTF$"::numeric, 0.00) +
                          coalesce("SRCTF$"::numeric, 0.00) + coalesce("PFOFTF$"::numeric, 0.00)), 6),
                   'FM999990.009999')                                               as "Total Charges",
           tcb.osiseries                                                            as "OSISeries",
           tcb."LINK EXCH"                                                          as "AwayExchange",
           tcb.report_id::text                                                      as "ReportID",
           tcb."range"                                                              as "Range"
    from billing.billing_data.tcustomer_billing_detail_all tcb
             left outer join billing.billing.l_filterexchange lf on (tcb.exchange = lf.exchangedesc)
    where tcb."date" BETWEEN l_start_date_id AND l_end_date_id
      and billingentity = 'TRAIMC';
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_traimc_data data is prepared', l_row_cnt,
                           'O')
    into l_step_id;
    create index on t_base ("Trade Date", "ReportID");

    return query
--         select 'Trade Date,MPID,Rate Category,Exch,B/S,P/C,QTY,Class,Sym,Mo,Yr,Strike,Price,O/C,Optional_data,client_order_ID,CMTA,Ex Firm,Client ID,Account,Product,Penny,Spread,Route,Liquidity,LADR,LADR$,ETF,ETF$,MTF,MTF$,LTF,LTF$,SRCTF,SRCTF$,PFOFTF,PFOFTF$,Total Charges,OSISeries,AwayExchange,ReportID,Range';
        select 'Trade Date,MPID,Rate Category,Exch,B/S,P/C,QTY,Class,Sym,Mo,Yr,Strike,Price,O/C,Optional Data,Client Order ID,CMTA,Ex Firm,Client ID,Account,Product,Penny,Spread,Route,Liquidity,LADR,LADR$,ETF,ETF$,MTF,MTF$,LTF,LTF$,SRCTF,SRCTF$,PFOFTF,PFOFTF$,Total Charges,OSISeries,AwayExchange,ReportID,Range';

    return query
        select array_to_string(ARRAY [
                                   "Trade Date",
                                   "MPID",
                                   "Rate Category",
                                   "Exch",
                                   "B/S",
                                   "P/C",
                                   "QTY",
                                   "Class",
                                   "Sym",
                                   "Mo",
                                   "Yr",
                                   "Strike",
                                   "Price",
                                   "O/C",
                                   "optional_data",
                                   "client_order_ID",
                                   "CMTA",
                                   "Ex Firm",
                                   "Client ID",
                                   "Account",
                                   "Product",
                                   "Penny",
                                   "Spread",
                                   "Route",
                                   "Liquidity",
                                   "LADR",
                                   "LADR$",
                                   "ETF",
                                   "ETF$",
                                   "MTF",
                                   "MTF$",
                                   "LTF",
                                   "LTF$",
                                   "SRCTF",
                                   "SRCTF$",
                                   "PFOFTF",
                                   "PFOFTF$",
                                   "Total Charges",
                                   "OSISeries",
                                   "AwayExchange",
                                   "ReportID",
                                   "Range"
                                   ], ',', '')
        from t_base tr
        order by "Trade Date", "ReportID";

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_traimc_data COMPLETED===', l_row_cnt, 'C')
    into l_step_id;
end ;
$fn$;
