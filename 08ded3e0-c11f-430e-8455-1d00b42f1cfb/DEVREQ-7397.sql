select * from dash360.report_billing_tickrs_ecr(in_start_date_id := 20260106,
                                                             in_end_date_id := 20260106);

create or replace function dash360.report_billing_tickrs_ecr(in_start_date_id integer,
                                                             in_end_date_id integer)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
-- 20260107 SO https://dashfinancial.atlassian.net/browse/DEVREQ-7397
declare
    l_load_id    int;
    l_row_cnt    int;
    l_step_id    int;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_billing_tickrs_ecr for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    return query
        select 'Billing Entity,User,Exchange,Symbol,Expiration,Strike,C/P,OSI Symbol,Multiplier,B/S,Qty,Price,Date,Giveup,CMTA,Range,Account,Single/Complex,Security Type,Electronic,Sub Strategy,ClOrdID,SOR Order ID,ReportID,Dash Exec ID,Exch Exec ID,Liquidity Flag,Commission Rate,Commission Total,Exchange Transaction Fee Rate,Exchange Transaction Fee Total,Surcharge Transaction Fee Rate,Surcharge Transaction Fee Total,Trade Processing Fee Rate,Trade Processing Fee Total,Pass Through Exchange Fees Rate,Pass Through Exchange Fees Total,FINRA CAT Fees Rate,FINRA CAT Fees Total,PFOF Transaction Fee Rate,PFOF Transaction Fee Total,Execution Cost Total,Exchange Fee Total';

    return query
        select array_to_string(ARRAY [
                                   tcb.billingentity , -- as "Billing Entity",
                                   tcb."USER" , -- as "User",
                                   tcb.exchange , -- as "Exchange",
                                   tcb.symbol , -- as "Symbol",
                                   tcb.expiration::text , -- as "Expiration",
                                   tcb.strike::text , -- as "Strike",
                                   tcb."C/P" , -- as "C/P",
                                   tcb.osiseries , -- as "OSI Symbol",
                                   tr.contract_multiplier::text , -- as "Multiplier",
                                   tcb."B/S" , -- as "B/S",
                                   tcb."FILLED QTY"::text , -- as "Qty",
                                   tcb.premium::text , -- as "Price",
                                   tcb."date"::text , -- as "Date",
                                   tcb.giveup , -- as "Giveup",
                                   tcb."CMTA FIRM" , -- as "CMTA",
                                   tcb."range" , -- as "Range",
                                   tcb.account , -- as "Account",
                                   case
                                       when tcb."LEG NUMBER" = '1/1' then 'Single-Leg'
                                       else 'Complex'
                                       end , -- as "Single/Complex",
                                   case
                                       when tcb."C/P" = 'S' then 'Equity'
                                       when tcb."C/P" in ('C', 'P') then 'Option'
                                       end , -- as "Security Type",
                                   tcb.electronic , -- as "Electronic",
                                   case
                                       when tcb."connection" ilike concat(tcb.exchange, ' dash%') then 'DMA'
                                       when tcb."connection" ilike '%blaze%' then tcb."connection"
                                       --when tcb.electronic = 'MANUAL' then 'BROKERPOINT'
                                       else coalesce(substring(tcb."connection" from '.+?(?= |\+|-)'), tcb."connection")
                                       end , -- as "Sub Strategy",
                                   tcb.cl_ord_id , -- as "ClOrdID",
                                   tr.exch_order_id , -- as "SOR Order ID",
                                   tcb.report_id::text , -- as "ReportID",
                                   tr.exch_exec_id , -- as "Dash Exec ID",
                                   tcb.street_exec_id , -- as "Exch Exec ID",
                                   tcb.liquidityflag , -- as "Liquidity Flag",
                                   coalesce(tcb."LADR", 0.0)::text , -- as "Commission Rate",
                                   coalesce(tcb."LADR$", 0.0)::text , -- as "Commission Total",
                                   coalesce(tcb."ETF", 0.0)::text , -- as "Exchange Transaction Fee Rate",
                                   coalesce(tcb."ETF$", 0.0)::text , -- as "Exchange Transaction Fee Total",
                                   coalesce(tcb."SRCTF", 0.0)::text , -- as "Surcharge Transaction Fee Rate",
                                   coalesce(tcb."SRCTF$", 0.0)::text , -- as "Surcharge Transaction Fee Total",
                                   coalesce(tcb."TPF", 0.0)::text , -- as "Trade Processing Fee Rate",
                                   coalesce(tcb."TPF$", 0.0)::text , -- as "Trade Processing Fee Total",
                                   coalesce(tcb."PSTF", 0.0)::text , -- as "Pass Through Exchange Fees Rate",
                                   coalesce(tcb."PSTF$", 0.0)::text , -- as "Pass Through Exchange Fees Total",
                                   coalesce(tcb."CATTF", 0.0)::text , -- as "FINRA CAT Fees Rate",
                                   coalesce(tcb."CATTF$", 0.0)::text , -- as "FINRA CAT Fees Total",
                                   coalesce(tcb."PFOFTF", 0.0)::text , -- as "PFOF Transaction Fee Rate",
                                   coalesce(tcb."PFOFTF$", 0.0)::text , -- as "PFOF Transaction Fee Total",
                                   (coalesce(tcb."LADR$", 0.0) + coalesce(tcb."ETF$", 0.0) +
                                   coalesce(tcb."SRCTF$", 0.0) +
                                   coalesce(tcb."TPF$", 0.0) + coalesce(tcb."PSTF$", 0.0) +
                                   coalesce(tcb."CATTF$", 0.0) +
                                   coalesce(tcb."PFOFTF$", 0.0))::text , -- as "Execution Cost Total",
                                   (coalesce(tcb."ETF$", 0.0) + coalesce(tcb."SRCTF$", 0.0) + coalesce(tcb."TPF$", 0.0) +
                                   coalesce(tcb."PSTF$", 0.0))::text -- as "Exchange Fee Total"
                                   ], ',', '')
        from billing.billing_data.tcustomer_billing_detail_all tcb
                 left join billing.billing_data.fdw_dash_trade_record tr
                           on (tr.date_id between in_start_date_id and in_end_date_id
                               and tr.trading_firm_id in ('OFP0063', 'tickrs') and tr.trade_record_id = tcb.report_id)
        where tcb."date" between in_start_date_id::text::date and in_end_date_id::text::date
          and tcb.billingentity in ('TICKROFP', 'tickrs')
          and tcb."connection" <> 'DMA-BLAZE'
          and tcb."FILLED QTY" > 0
        order by tcb."date", tcb.cl_ord_id, tcb.osiseries, tcb.report_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_billing_tickrs_ecr for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;



select tcb.billingentity            as "Billing Entity",
       tcb."USER"                   as "User",
       tcb.exchange                 as "Exchange",
       tcb.symbol                   as "Symbol",
       tcb.expiration               as "Expiration",
       tcb.strike                   as "Strike",
       tcb."C/P"                    as "C/P",
       tcb.osiseries                as "OSI Symbol",
       tr.contract_multiplier       as "Multiplier",
       tcb."B/S"                    as "B/S",
       tcb."FILLED QTY"             as "Qty",
       tcb.premium                  as "Price",
       tcb."date"                   as "Date",
       tcb.giveup                   as "Giveup",
       tcb."CMTA FIRM"              as "CMTA",
       tcb."range"                  as "Range",
       tcb.account                  as "Account",
       case
           when tcb."LEG NUMBER" = '1/1' then 'Single-Leg'
           else 'Complex'
           end                      as "Single/Complex",
       case
           when tcb."C/P" = 'S' then 'Equity'
           when tcb."C/P" in ('C', 'P') then 'Option'
           end                      as "Security Type",
       tcb.electronic               as "Electronic",
       case
           when lower(tcb."connection") like lower(concat(tcb.exchange, ' dash%')) then 'DMA'
           when lower(tcb."connection") like '%blaze%' then tcb."connection"
           --when tcb.electronic = 'MANUAL' then 'BROKERPOINT'
           else coalesce(substring(tcb."connection" from '.+?(?= |\+|-)'), tcb."connection")
           end                      as "Sub Strategy",
       tcb.cl_ord_id                as "ClOrdID",
       tr.exch_order_id             as "SOR Order ID",
       tcb.report_id                as "ReportID",
       tr.exch_exec_id              as "Dash Exec ID",
       tcb.street_exec_id           as "Exch Exec ID",
       tcb.liquidityflag            as "Liquidity Flag",
       coalesce(tcb."LADR", 0.0)    as "Commission Rate",
       coalesce(tcb."LADR$", 0.0)   as "Commission Total",
       coalesce(tcb."ETF", 0.0)     as "Exchange Transaction Fee Rate",
       coalesce(tcb."ETF$", 0.0)    as "Exchange Transaction Fee Total",
       coalesce(tcb."SRCTF", 0.0)   as "Surcharge Transaction Fee Rate",
       coalesce(tcb."SRCTF$", 0.0)  as "Surcharge Transaction Fee Total",
       coalesce(tcb."TPF", 0.0)     as "Trade Processing Fee Rate",
       coalesce(tcb."TPF$", 0.0)    as "Trade Processing Fee Total",
       coalesce(tcb."PSTF", 0.0)    as "Pass Through Exchange Fees Rate",
       coalesce(tcb."PSTF$", 0.0)   as "Pass Through Exchange Fees Total",
       coalesce(tcb."CATTF", 0.0)   as "FINRA CAT Fees Rate",
       coalesce(tcb."CATTF$", 0.0)  as "FINRA CAT Fees Total",
       coalesce(tcb."PFOFTF", 0.0)  as "PFOF Transaction Fee Rate",
       coalesce(tcb."PFOFTF$", 0.0) as "PFOF Transaction Fee Total",
       coalesce(tcb."LADR$", 0.0) + coalesce(tcb."ETF$", 0.0) + coalesce(tcb."SRCTF$", 0.0) +
       coalesce(tcb."TPF$", 0.0) + coalesce(tcb."PSTF$", 0.0) + coalesce(tcb."CATTF$", 0.0) +
       coalesce(tcb."PFOFTF$", 0.0) as "Execution Cost Total",
       coalesce(tcb."ETF$", 0.0) + coalesce(tcb."SRCTF$", 0.0) + coalesce(tcb."TPF$", 0.0) +
       coalesce(tcb."PSTF$", 0.0)   as "Exchange Fee Total"
from billing.billing_data.tcustomer_billing_detail_all tcb
         left join billing.billing_data.fdw_dash_trade_record tr
                   on (tr.date_id between :in_start_date_id and :in_end_date_id and tr.trading_firm_id in ('OFP0063', 'tickrs') and tr.trade_record_id = tcb.report_id)
where tcb."date" between :in_start_date_id::text::date and :in_end_date_id::text::date
  and tcb.billingentity in ('TICKROFP', 'tickrs')
  and tcb."connection" <> 'DMA-BLAZE'
  and tcb."FILLED QTY" > 0
order by tcb."date", tcb.cl_ord_id, tcb.osiseries, tcb.report_id;

