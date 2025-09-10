CREATE or replace FUNCTION dash360.report_surveillance_socgen01_parent_order_count(in_start_date_id integer DEFAULT get_dateid((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date),
                                                                        in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                                        in_instrument_type character varying DEFAULT NULL::character varying)
    RETURNS TABLE
            (
                "row" text
            )
    LANGUAGE plpgsql
AS
$function$

declare
    row_cnt           int4;
    l_load_id         int;
    l_step_id         int;
    l_is_current_date bool := false;
    l_account_ids     int4[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen01_parent_order_count for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;
    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where true
      and trading_firm_id in ('socgen01', 'socgenpsc', 'socgeneqd', 'LPTF286');

    return query
        select 'Period,Account,Qty,Parent Order Count,Capacity';
    return query
        select to_char("StatusDate", 'YYYY-MM-DD')::text || ',' ||
               a.account_name::text || ',' ||
               sum(coalesce(hods."CumQty", 0))::text || ',' ||
               count(distinct hods."ClOrdID")::text || ',' ||
               cf.customer_or_firm_name::text
        from dwh.historic_order_details_storage hods
                 join dwh.d_account a on a.account_id = hods."AccountID"
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
        where hods."Status_Date_id" between in_start_date_id and in_end_date_id
          and case when in_instrument_type is null then true else hods."InstrumentType" = in_instrument_type end
          and hods."CustomerOrderID" is null
          and hods."AccountID" = any (l_account_ids)
        group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name;
    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen01_parent_order_count for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           row_cnt, 'O')
    into l_step_id;

end;
$function$
;

select *
from dash360.report_surveillance_socgen01_parent_order_count(20250908, 20250909);
