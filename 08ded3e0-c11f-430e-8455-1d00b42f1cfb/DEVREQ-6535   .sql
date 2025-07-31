select *
from dash360.report_billing_pfof_summary(
	in_start_date_id := 20250701,
	in_end_date_id := 20250729,
	in_billing_entities := array['OFPAGP'],
	in_company_codes := array['OFP0073']
);


create or replace function dash360.report_billing_pfof_summary(in_start_date_id integer,
                                                               in_end_date_id integer,
                                                               in_billing_entities character varying[],
                                                               in_company_codes character varying[])
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
