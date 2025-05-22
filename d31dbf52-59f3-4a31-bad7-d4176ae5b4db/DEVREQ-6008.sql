-- DROP FUNCTION dash360.report_fintech_adh_parent_order_count_review(int4, int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.report_fintech_adh_parent_order_count_review(in_start_date_id integer, in_end_date_id integer, in_instrument_type_id character DEFAULT 'O'::bpchar)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
declare
    l_today_date_id int := to_char(current_date, 'YYYYMMDD')::int4;
    l_is_today      bool;
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_int for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    select into l_is_today case
                               when to_char(current_date, 'YYYYMMDD')::int4 between in_start_date_id and in_end_date_id
                                   then true
                               else false end;


    drop table if exists t_report;
    create temp table t_report as
    select o."StatusDate"::date               as "Period",
           tf.trading_firm_name::varchar      as "Trading Firm",
           a.account_name::varchar            as "Account",
           cf.customer_or_firm_name::varchar  as "Capacity",
           sum(coalesce(o."CumQty", 0))::int8 as "Qty",
           count(distinct o."ClOrdID")        as "Parent Order Count"
    from dwh.historic_order_details_storage o
             join dwh.d_account a on (a.account_id = o."AccountID")
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = o."CustomerOrFirm")
    where true
      and "Status_Date_id" >= in_start_date_id
      and case
              when l_is_today then "Status_Date_id" < in_end_date_id
              else "Status_Date_id" <= in_end_date_id end
      and case when in_instrument_type_id is null then true else o."InstrumentType" = in_instrument_type_id end
      and o."CustomerOrderID" is null
    group by "Period", "Account", "Capacity", "Trading Firm";

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_int for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' data set for previous days calculated', l_row_cnt, 'O')
    into l_step_id;

    if l_is_today then
        insert into t_report ("Period", "Trading Firm", "Account", "Capacity", "Qty", "Parent Order Count")
        select co.create_time::date                as "Period",
               tf.trading_firm_name::varchar       as "Trading Firm",
               a.account_name::varchar             as "Account",
               cf.customer_or_firm_name::varchar   as "Capacity",
               sum(coalesce(exg.cum_qty, 0))::int8 as "Qty",
               count(distinct co.client_order_id)  as "Parent Order Count"
        from dwh.client_order co
                 join dwh.d_instrument i on (i.instrument_id = co.instrument_id)
                 join dwh.d_account a on (a.account_id = co.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 left join dwh.d_customer_or_firm cf
                           on (cf.customer_or_firm_id = coalesce(co.customer_or_firm_id, a.opt_customer_or_firm))
                 left join lateral
            (
            select sum(ex.last_qty) as cum_qty
            from dwh.execution ex
            where ex.order_id = co.order_id
              and ex.exec_date_id = l_today_date_id
              and ex.exec_type in ('F', 'G')
              and ex.is_busted = 'N'
            ) exg on true
        where true
          and co.create_date_id = l_today_date_id
          and co.parent_order_id is null
          and case when in_instrument_type_id is null then true else i.instrument_type_id = in_instrument_type_id end
        group by "Period", "Account", "Capacity", "Trading Firm";
        get diagnostics l_row_cnt = row_count;

        select public.load_log(l_load_id, l_step_id,
                               'report_fintech_adh_parent_order_count_int for ' || in_start_date_id::text || '-' ||
                               in_end_date_id::text || ' data set for current day calculated', l_row_cnt, 'O')
        into l_step_id;

    end if;

    return query
        select 'Period,Trading Firm,Account,Capacity,Qty,Parent Order Count';
    return query
        select array_to_string(ARRAY [
                                   to_char("Period", 'mm/dd/yy'),
                                   "Trading Firm",
                                   "Account",
                                   "Capacity",
                                   "Qty"::text,
                                   "Parent Order Count"::text
                                   ], ',', '')
        from t_report;
        get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_int for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED=====', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;
