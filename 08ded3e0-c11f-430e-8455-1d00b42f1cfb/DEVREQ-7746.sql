create function dash360.report_billing_ofp0067_execution(in_start_date_id integer,
                                                         in_end_date_id integer)
    returns table
            (
                ret_row text
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
                           'report_billing_ofp0067_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    return query
        select 'order_id,execution_id,symbol,side,contracts,limit_price,order_type,is_marketable,avg_filled_price,is_complex,pfof_type,executed_contracts,notional_value,pfof_rate,estimated_payment';

    return query
        select array_to_string(ARRAY [
                                   tcb.cl_ord_id, --                                              as order_id,
                                   tcb.report_id::text, --                                        as execution_id,
                                   tcb.osiseries, --                                              as symbol,
                                   tcb."B/S", --                                                  as side,
                                   tcb."FILLED QTY"::text, --                                     as contracts,
                                   tr.price_limit::text, --                                       as limit_price,
                                   case
                                       when tr.order_type = '1' then 'Market'
                                       when tr.order_type = '2' then 'Limit'
                                       when tr.order_type = '3' then 'Stop'
                                       when tr.order_type = '4' then 'Stop limit'
                                       when tr.order_type = '5' then 'Market on close'
                                       when tr.order_type = '7' then 'Limit or better'
                                       end, --                                                    as order_type,
                                   case when tcb.is_marketable = '1' then 'Y' else 'N' end,--     as is_marketable,
                                   tcb.premium::text, --                                          as avg_filled_price,
                                   case when tcb."LEG NUMBER" = '1/1' then 'N' else 'Y' end, --   as is_complex,
                                   case
                                       when tcb.symbol = 'SPY' then 'SPY'
                                       when tcb.symbol in
                                            ('VIX', 'VIXW', 'SPX', 'SPXW', 'SPXPM', 'OEX', 'XEO', 'RUT', 'RUTW', 'DJX',
                                             'XSP', 'MRUT')
                                           then 'Index'
                                       when tcb."LEG NUMBER" <> '1/1' then 'Complex'
                                       when tcb.penny = '1' then 'Penny'
                                       when tcb.penny = '0' then 'Non-Penny'
                                       end, --                                                    as pfof_type,
                                   tcb."FILLED QTY"::text, --                                     as executed_contracts,
                                   (case
                                        when tcb."C/P" = 'S' then tcb."FILLED QTY" * tcb.premium
                                        when tcb."C/P" in ('C', 'P') then tcb."FILLED QTY" * tcb.premium * 100
                                       end)::text, --                                             as notional_value,
                                   tcb."PFOFTF"::text, --                                         as pfof_rate,
                                   tcb."PFOFTF$"::text --                                         as estimated_payment
                                   ], ',', '')
        from billing.billing_data.tcustomer_billing_detail_all tcb
                 left join billing.billing_data.fdw_dash_trade_record tr
                           on (tr.date_id between in_start_date_id and in_end_date_id and
                               tr.trading_firm_id in ('OFP0067') and tr.trade_record_id = tcb.report_id)
        where tcb."date" between in_start_date_id::text::date and in_end_date_id::text::date
          and tcb.billingentity = 'OFP0067'
          and tcb."C/P" in ('C', 'P')
          and tcb."FILLED QTY" > 0
        order by tcb."date", tcb.report_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_billing_ofp0067_execution for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;


select * from dash360.report_billing_ofp0067_execution(20260223, 20260226)