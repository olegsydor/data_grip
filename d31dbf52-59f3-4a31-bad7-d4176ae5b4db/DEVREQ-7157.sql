-- DROP FUNCTION dash360.report_surveillance_socgen_parent_order_count(int4, int4, varchar);
select * from trash.report_surveillance_socgen_parent_order_count(20251001, 20251031);

select * from trash.report_surveillance_socgen_parent_order_count(20251001, 20251031);
CREATE or replace FUNCTION trash.report_surveillance_socgen_parent_order_count(in_start_date_id integer DEFAULT get_dateid((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date),
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
    row_cnt       int4;
    l_load_id     int;
    l_step_id     int;
    l_account_ids int4[];
    l_leg_count   int4 := 8;
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
      and trading_firm_id in ('socgenpsc', 'socgeneqd'); --'socgen01', 'LPTF286'

    drop table if exists t_legs_exceed;
    create temp table t_legs_exceed as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           count(*) - 1                        as count_legs_minus_1
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between in_start_date_id and in_end_date_id
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (l_account_ids)
      and hods."MultilegReportingType" = '2'
    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name, "ClOrdID"
    having count(distinct hods."DisplayInstrumentID") > l_leg_count;

    drop table if exists t_ordinary;
    create temp table t_ordinary as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           sum(coalesce(hods."CumQty", 0))     as cum_qty,
           count(distinct hods."ClOrdID")      as cnt
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between in_start_date_id and in_end_date_id
      and case when in_instrument_type is null then true else hods."InstrumentType" = in_instrument_type end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (l_account_ids)
    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name;

    return query
        select 'Period,Account,Capacity,Qty,Parent Order Count';

    return query
        select array_to_string(ARRAY [
                                   tor.status_date,
                                   tor.account_name,
                                   tor.customer_or_firm_name,
                                   tor.cum_qty::text,
                                   (tor.cnt + coalesce(tex.count_legs_minus_1, 0))::text
                                   ], ',', '')
        from t_ordinary tor
                 left join lateral (select count_legs_minus_1
                                    from t_legs_exceed tex
                                    where tex.status_date = tor.status_date
                                      and tex.account_name = tor.account_name
                                      and tex.customer_or_firm_name = tor.customer_or_firm_name
                                    limit 1) tex on true;
    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen01_parent_order_count for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           row_cnt, 'O')
    into l_step_id;

end;
$function$
;

select * from t_legs_exceed