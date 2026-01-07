create or replace function dash360.report_billing_tickrs_ecr(in_start_date_id integer,
                                                               in_end_date_id integer)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
-- 20240931 SO https://dashfinancial.atlassian.net/browse/DEVREQ-6535
declare
    l_load_id    int;
    l_row_cnt    int;
    l_step_id    int;
    l_start_date date := in_start_date_id::text::date;
    l_end_date   date := in_end_date_id::text::date;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_billing_pfof_summary for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    return query
        select 'Trade Date,Sec Type,Exec Qty,PFOF Transaction Fee';

    return query
        select array_to_string(ARRAY [
                                   to_char(tcb."date", 'MM/dd/yyyy'), -- as "Trade Date",
                                   tcb."SECURITY TYPE", -- as "Sec Type",
                                   sum(tcb."FILLED QTY")::text, -- as "Exec Qty",
                                   to_char(round(sum(coalesce(tcb."PFOFTF$", 0.0))::numeric, 4),
                                           'FM999990.0099') -- as "PFOF Transaction Fee"
                                   ], ',', '')
        from billing.billing_data.tcustomer_billing_detail_all tcb
        where tcb."date" between l_start_date and l_end_date
          and case
                  when coalesce(in_billing_entities, '{}') = '{}' then true
                  else tcb.billingentity = any (in_billing_entities) end
          and case when coalesce(in_company_codes, '{}') = '{}' then true else tcb.company = any (in_company_codes) end
          and tcb."FILLED QTY" > 0
        group by tcb."date", tcb."SECURITY TYPE"
        order by tcb."date", tcb."SECURITY TYPE";
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_billing_pfof_summary for ' || l_start_date || '-' ||
                           l_end_date::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$

dash360.report_billing_tickrs_ecr(in_start_date_id, in_end_date_id)


select
	tcb.billingentity as "Billing Entity",
	tcb."USER" as "User",
	tcb.exchange as "Exchange",
	tcb.symbol as "Symbol",
	tcb.expiration as "Expiration",
	tcb.strike as "Strike",
	tcb."C/P" as "C/P",
	tcb.osiseries as "OSI Symbol",
	tr.contract_multiplier as "Multiplier",
	tcb."B/S" as "B/S",
	tcb."FILLED QTY" as "Qty",
	tcb.premium as "Price",
	tcb."date" as "Date",
	tcb.giveup as "Giveup",
	tcb."CMTA FIRM" as "CMTA",
	tcb."range" as "Range",
	tcb.account as "Account",
	case
		when tcb."LEG NUMBER" = '1/1' then 'Single-Leg'
		else 'Complex'
	end as "Single/Complex",
	case
		when tcb."C/P" = 'S' then 'Equity'
		when tcb."C/P" in ('C','P') then 'Option'
	end as "Security Type",
	tcb.electronic as "Electronic",
	case
		when lower(tcb."connection") like lower(concat(tcb.exchange, ' dash%')) then 'DMA'
		when lower(tcb."connection") like '%blaze%' then tcb."connection"
		--when tcb.electronic = 'MANUAL' then 'BROKERPOINT'
		else coalesce(substring(tcb."connection" from '.+?(?= |\+|-)'), tcb."connection")
	end as "Sub Strategy",
	tcb.cl_ord_id as "ClOrdID",
	tr.exch_order_id as "SOR Order ID",
	tcb.report_id as "ReportID",
	tr.exch_exec_id as "Dash Exec ID",
	tcb.street_exec_id as "Exch Exec ID",
	tcb.liquidityflag as "Liquidity Flag",
	coalesce(tcb."LADR",0.0) as "Commission Rate",
	coalesce(tcb."LADR$",0.0) as "Commission Total",
	coalesce(tcb."ETF",0.0) as "Exchange Transaction Fee Rate",
	coalesce(tcb."ETF$",0.0) as "Exchange Transaction Fee Total",
	coalesce(tcb."SRCTF",0.0) as "Surcharge Transaction Fee Rate",
	coalesce(tcb."SRCTF$",0.0) as "Surcharge Transaction Fee Total",
	coalesce(tcb."TPF",0.0) as "Trade Processing Fee Rate",
	coalesce(tcb."TPF$",0.0) as "Trade Processing Fee Total",
	coalesce(tcb."PSTF",0.0) as "Pass Through Exchange Fees Rate",
	coalesce(tcb."PSTF$",0.0) as "Pass Through Exchange Fees Total",
	coalesce(tcb."CATTF",0.0) as "FINRA CAT Fees Rate",
	coalesce(tcb."CATTF$",0.0) as "FINRA CAT Fees Total",
	coalesce(tcb."PFOFTF",0.0) as "PFOF Transaction Fee Rate",
	coalesce(tcb."PFOFTF$",0.0) as "PFOF Transaction Fee Total",
	coalesce(tcb."LADR$",0.0)+coalesce(tcb."ETF$",0.0)+coalesce(tcb."SRCTF$",0.0)+coalesce(tcb."TPF$",0.0)+coalesce(tcb."PSTF$",0.0)+coalesce(tcb."CATTF$",0.0)+coalesce(tcb."PFOFTF$",0.0) as "Execution Cost Total",
	coalesce(tcb."ETF$",0.0)+coalesce(tcb."SRCTF$",0.0)+coalesce(tcb."TPF$",0.0)+coalesce(tcb."PSTF$",0.0) as "Exchange Fee Total"
from billing.billing_data.tcustomer_billing_detail_all tcb
left join billing.billing_data.fdw_dash_trade_record tr on (tr.date_id between {0} and {1} and tr.trading_firm_id in ('OFP0063', 'tickrs') and tr.trade_record_id = tcb.report_id)
where tcb."date" between '{0}' and '{1}'
	and tcb.billingentity in ('TICKROFP','tickrs')
	and tcb."connection" <> 'DMA-BLAZE'
	and tcb."FILLED QTY" > 0
order by tcb."date", tcb.cl_ord_id, tcb.osiseries, tcb.report_id;