create or replace function dash360.report_billing_tra_e_execution(in_start_date_id integer,
                                                                  in_end_date_id integer)
    returns table
            (
                "Trade Date"      text,
                "Client Order ID" varchar(150),
                "Quantity"        int8,
                "Executed Price"  numeric,
                "Access Fee"      numeric,
                "Symbol"          varchar(100)

            )
    language plpgsql
AS
$fx$
-- 20260226 SO https://dashfinancial.atlassian.net/browse/DEVREQ-7746
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_billing_tra_e_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;


    return query
        select to_char(tcb."date", 'yyyy-MM-dd')                                              as "Trade Date",
               tcb.cl_ord_id                                                                  as "Client Order ID",
               sum(tcb."FILLED QTY")                                                          as "Quantity",
               round(sum(tcb.premium * tcb."FILLED QTY") / sum(tcb."FILLED QTY"), 6)::numeric as "Executed Price",
               sum(coalesce(tcb."OIRGPMT$", 0.0))::numeric                                    as "Access Fee",
               tcb.symbol                                                                     as "Symbol"
        from billing.billing_data.tcustomer_billing_detail_all tcb
        where tcb.date_id between in_start_date_id and in_end_date_id
          and tcb.billingentity = 'TRA_E'
          and tcb."C/P" = 'S'
          and tcb."FILLED QTY" > 0
        group by "Trade Date", "Client Order ID", "Symbol"
        order by "Trade Date", "Client Order ID", "Symbol";

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_billing_tra_e_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;

select *
from dash360.report_billing_tra_e_execution(20260420, 20260421);



-- CSV
-- DROP FUNCTION dash360.report_billing_tra_e_data(int4, int4);

CREATE OR REPLACE FUNCTION dash360.report_billing_tra_e_data(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
-- 20260226 SO https://dashfinancial.atlassian.net/browse/DEVREQ-7746
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_billing_tra_e_data for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;


    return query
        select array_to_string(ARRAY [
                                   to_char(tcb."date", 'yyyy-MM-dd') ,            -- as "Trade Date",
                                   tcb.cl_ord_id ,                           -- as "Client Order ID",
                                   sum(tcb."FILLED QTY")::text ,                    -- as "Quantity",
                                   round(sum(tcb.premium * tcb."FILLED QTY") / sum(tcb."FILLED QTY"),
                                         6)::text ,                           -- as "Executed Price",
                                   sum(coalesce(tcb."OIRGPMT$", 0.0))::text ,     -- as "Access Fee",
                                   tcb.symbol                                          -- as "Symbol"
                                   ], ',', '')
        from billing_data.tcustomer_billing_detail_all tcb
        where tcb.date_id between in_start_date_id and in_end_date_id
          and tcb.billingentity = 'TRA_E'
          and tcb."C/P" = 'S'
          and tcb."FILLED QTY" > 0
        group by tcb."date", tcb.cl_ord_id, tcb.symbol
        order by to_char(tcb."date", 'yyyy-MM-dd'), tcb.cl_ord_id, tcb.symbol;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_billing_tra_e_data for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'C')
    into l_step_id;
end;
$function$
;

select *
from dash360.report_billing_tra_e_data(20260422, 20260422);



