create or replace
    function dash360.report_billing_traimc_summary(in_start_date_id int4, in_end_date_id int4)
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

    select public.load_log(l_load_id, l_step_id, 'dash360.report_billing_traimc_summary STARTED===', 0, 'O')
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


select
	'TRAD' as "MPID",
	to_char(tcb."date", 'MM/dd/yyyy') as "Trade Date",
	tcb.billto_id as "Client ID",
	'TOTAL' as "Rate Category",
	(case when tcb."LEG NUMBER" = '1/1' then 'N' else 'Y' end) as "Spread",
	count(distinct tcb.cl_ord_id) as "EXEC ORDERS",
	sum(tcb."FILLED QTY") as "EXEC QUANTITY",
	sum(coalesce(tcb."PFOFTF$", 0.00)) as "PFOF"
from billing.billing_data.tcustomer_billing_detail_all tcb
where tcb."date" between :start_date_id#' and '#end_date_id#'
	and tcb.billingentity = 'TRAIMC'
	and tcb."FILLED QTY" > 0
group by "Trade Date", "Client ID", "Spread"
order by "Trade Date", "Client ID", "Spread";