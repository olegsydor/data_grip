create or replace function dash360.report_billing_fidofp_summary(in_start_date_id integer,
                                                      in_end_date_id integer)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fx$
-- 20260226 SO https://dashfinancial.atlassian.net/browse/DEVREQ-7745
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_billing_fidofp_summary for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    return query
        select 'Date,Single/Marketable Filled Qty,Single/Marketable PFOFTF$,Single/Non-Marketable Filled Qty,Single/Non-Marketable PFOFTF$,Multi-Leg Filled Qty,Multi-Leg PFOFTF$,Fee-Eligible Index Filled Qty,Fee-Eligible Index PFOFTF$,Total Filled Qty,Total PFOFTF$,Total Exchange Fees,Net Rebate';

    return query
        with cte_agg as (select tcb."date",
                                tcb.is_marketable,
                                (case when tcb."LEG NUMBER" = '1/1' then 0 else 1 end) as is_multileg,
                                (case
                                     when tcb.symbol in
                                          ('VIX', 'VIXW', 'SPX', 'SPXW', 'SPXPM', 'OEX', 'XEO', 'RUT', 'RUTW', 'DJX',
                                           'XSP', 'MXEF', 'NDX', 'NDXP', 'NANOS', 'SPIKE') then 1
                                     else 0 end)                                       as is_single_list,
                                sum(tcb."FILLED QTY")                                  as filled_qty,
                                round(sum(coalesce(tcb."PFOFTF$", 0.0))::numeric, 2)   as "PFOFTF$",
                                round(sum(coalesce(tcb."ETF$", 0.0) + coalesce(tcb."MTF$", 0.0) +
                                          coalesce(tcb."LTF$", 0.0) + coalesce(tcb."TPF$", 0.0) +
                                          coalesce(tcb."SRCTF$", 0.0))::numeric, 2)    as exchange_fees
                         from billing_data.tcustomer_billing_detail_all tcb
                         where tcb."date" between in_start_date_id::text::date and in_end_date_id::text::date
                           and tcb.billingentity = 'FIDOFP'
                           and tcb."C/P" in ('C', 'P')
                           and tcb."FILLED QTY" > 0
                         group by "date", is_marketable, is_multileg, is_single_list)

        select array_to_string(ARRAY [
                                   to_char("date", 'MM/dd/yyyy'), --                                                        as "Date",
                                   sum(case
                                           when is_multileg = '0' and is_marketable = '1' and is_single_list = '0'
                                               then filled_qty
                                           else 0 end)::text, --                                                            as "Single/Marketable Filled Qty",
                                   sum(case
                                           when is_multileg = '0' and is_marketable = '1' and is_single_list = '0'
                                               then "PFOFTF$"
                                           else 0.0 end)::text, --                                                          as "Single/Marketable PFOFTF$",
                                   sum(case
                                           when is_multileg = '0' and is_marketable = '0' and is_single_list = '0'
                                               then filled_qty
                                           else 0 end)::text, --                                                            as "Single/Non-Marketable Filled Qty",
                                   sum(case
                                           when is_multileg = '0' and is_marketable = '0' and is_single_list = '0'
                                               then "PFOFTF$"
                                           else 0.0 end)::text, --                                                          as "Single/Non-Marketable PFOFTF$",
                                   sum(case
                                           when is_multileg = '1' and is_single_list = '0' then filled_qty
                                           else 0 end)::text, --                                                            as "Multi-Leg Filled Qty",
                                   sum(case
                                           when is_multileg = '1' and is_single_list = '0' then "PFOFTF$"
                                           else 0 end)::text, --                                                            as "Multi-Leg PFOFTF$",
                                   sum(case when is_single_list = '1' then filled_qty else 0 end)::text, --                 as "Fee-Eligible Index Filled Qty",
                                   sum(case when is_single_list = '1' then "PFOFTF$" else 0 end)::text, --                  as "Fee-Eligible Index PFOFTF$",
                                   sum(filled_qty)::text, --                                                                as "Total Filled Qty",
                                   sum("PFOFTF$")::text, --                                                                 as "Total PFOFTF$",
                                   sum(exchange_fees)::text, --                                                             as "Total Exchange Fees",
                                   sum("PFOFTF$" + exchange_fees)::text --                                                  as "Net Rebate"
                                   ], ',', '')
        from cte_agg
        group by "date"
        order by "date";
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_billing_fidofp_summary for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;


select * from dash360.report_billing_fidofp_summary(20260223, 20260226)