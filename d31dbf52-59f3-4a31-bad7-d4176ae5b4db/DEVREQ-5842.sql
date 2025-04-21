-- DROP FUNCTION fintech_reports.adh_parent_order_count_qtd(int4);
select * from dash360.report_fintech_adh_parent_order_count_int(20250101, 20250331, 'O');

create or replace function dash360.report_fintech_adh_parent_order_count_int(in_start_date_id int4, in_end_date_id int4,
                                                                             in_instrument_type_id char default 'O')
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
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



--------------------------
select *
from dash360.report_fintech_adh_parent_order_count_excess_legs_int(20250101, 20250331);


-- DROP FUNCTION fintech_reports.adh_parent_order_count_excess_legs_qtd(int4);

create
    or replace
    function dash360.report_fintech_adh_parent_order_count_excess_legs_int(in_start_date_id int4,
                                                                           in_end_date_id int4,
                                                                           in_instrument_type_id char default null)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
declare
    l_today_date_id int := to_char(current_date, 'YYYYMMDD')::int4;
    l_is_today      bool;
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
    l_leg_num       int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_excess_legs_int for ' || in_start_date_id::text ||
                           '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    select into l_is_today case
                               when to_char(current_date, 'YYYYMMDD')::int4 between in_start_date_id and in_end_date_id
                                   then true
                               else false end;
    l_leg_num := 8;

    drop table if exists t_report;
    create temp table t_report as
    select hods."StatusDate"::date                    as "Period",
           tf.trading_firm_name::varchar              as "Trading Firm",
           a.account_name::varchar                    as "Account",
           cf.customer_or_firm_name::varchar          as "Capacity",
           hods."ClOrdID"                             as "ClOrdID",
           sum(coalesce(hods."CumQty", 0))            as "Qty",
           1                                          as "Parent Order Count",
           count(distinct hods."DisplayInstrumentID") as "Leg Count"
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" >= in_start_date_id
      and case
              when l_is_today then hods."Status_Date_id" < in_end_date_id
              else hods."Status_Date_id" <= in_end_date_id end
      and hods."CustomerOrderID" is null
      and hods."MultilegReportingType" = '2'
      and case when in_instrument_type_id is null then true else hods."InstrumentType" = in_instrument_type_id end
    group by "Period", "Account", "Capacity", "Trading Firm", "ClOrdID"
    having count(distinct hods."DisplayInstrumentID") > l_leg_num;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_excess_legs_int for ' || in_start_date_id::text ||
                           '-' ||
                           in_end_date_id::text || ' data set for previous days calculated', l_row_cnt, 'O')
    into l_step_id;
    if l_is_today then

        insert into t_report ("Period", "Trading Firm", "Account", "Capacity", "ClOrdID", "Qty", "Parent Order Count",
                              "Leg Count")
        select co.create_time::date                    as "Period",
               tf.trading_firm_name                    as "Trading Firm",
               a.account_name                          as "Account",
               cf.customer_or_firm_name                as "Capacity",
               co.client_order_id                      as "ClOrdID",
               sum(coalesce(exg.cum_qty, 0))           as "Qty",
               1                                       as "Parent Order Count",
               count(distinct i.display_instrument_id) as "Leg Count"
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
        where co.create_date_id = l_today_date_id
          and co.parent_order_id is null
          and co.multileg_reporting_type = '2'
          and case when in_instrument_type_id is null then true else i.instrument_type_id = in_instrument_type_id end
        group by "Period", "Account", "Capacity", "Trading Firm", "ClOrdID"
        having count(distinct i.display_instrument_id) > l_leg_num;
        get diagnostics l_row_cnt = row_count;

        select public.load_log(l_load_id, l_step_id,
                               'report_fintech_adh_parent_order_count_excess_legs_int for ' || in_start_date_id::text ||
                               '-' ||
                               in_end_date_id::text || ' data set for current day calculated', l_row_cnt, 'O')
        into l_step_id;
    end if;

    return query
        select array_to_string(ARRAY [
                                   to_char(p."Period", 'mm/dd/yy'),
                                   p."Trading Firm",
                                   p."Account",
                                   p."Capacity",
                                   sum(p."Qty")::text,
                                   sum(p."Parent Order Count")::text
                                   ], ',', '')
        from t_report p
        group by p."Period", p."Trading Firm", p."Account", p."Capacity"
        order by p."Period", p."Trading Firm", p."Account", p."Capacity";

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_parent_order_count_excess_legs_int for ' || in_start_date_id::text ||
                           '-' ||
                           in_end_date_id::text || ' COMPLETED=====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;