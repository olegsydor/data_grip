
-- DROP FUNCTION dash360.report_fintech_adh_parent_order_count_review(int4, int4, bpchar);

create function dash360.report_compliance_avg_parent_order_count(in_date_id integer,
                                                                 in_trading_firm_ids character varying[] default '{}'::character varying[],
                                                                           in_account_ids int4[] default '{}'::int4[] )
 returns table(ret_row text)
 language plpgsql
as $function$
declare
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
      l_account_ids     int4[];
    l_message text;
    l_start_date date := date_trunc('month', in_date_id::text::date)::date;
    l_end_date date := (date_trunc('month', in_date_id::text::date + '1 month'::interval) - '1 day'::interval)::date;
    l_start_date_id int4 := to_char(l_start_date, 'YYYYMMDD');
    l_end_date_id int4 := to_char(l_end_date, 'YYYYMMDD');
begin


l_message = 'report_compliance_avg_parent_order_count for' || l_start_date_id::text || '-' || l_end_date_id::text;


    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           l_message || ' STARTED ===', 0, 'O')
    into l_step_id;


        if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
           and case when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[] then trading_firm_id = ANY (in_trading_firm_ids) else true end
           and case when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids) else true end;
    end if;

select extract(dow from x.dt), dt from (select generate_series(:l_start_date, :l_end_date, '1 day')::date as dt) x
where  extract(dow from x.dt) between 1 and 5


    drop table if exists t_report;
    create temp table t_report as
    select hods."StatusDate"::date               as "Period",
           tf.trading_firm_name::varchar      as "Trading Firm",
           a.account_name::varchar            as "Account",
           cf.customer_or_firm_name::varchar  as "Capacity",
           count(distinct hods."ClOrdID")        as "Parent Order Count"
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on (a.account_id = hods."AccountID")
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where true
      and "Status_Date_id" >= in_start_date_id
      and case
              when l_is_today then "Status_Date_id" < in_end_date_id
              else "Status_Date_id" <= in_end_date_id end
      and case when in_instrument_type_id is null then true else hods."InstrumentType" = in_instrument_type_id end
      and hods."CustomerOrderID" is null
    and hods."AccountID" = any(l_account_ids)
    group by "Period", "Account", "Capacity", "Trading Firm";

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           l_message || ' data set for previous days calculated', l_row_cnt, 'O')
    into l_step_id;



    return query
        select 'Period,Trading Firm,Account,Capacity,Qty,Parent Order Count';
    return query
        select array_to_string(ARRAY [
                                   to_char("Period", 'mm/dd/yy'),
                                   "Trading Firm",
                                   "Account",
                                   "Capacity",
                                   "Parent Order Count"::text
                                   ], ',', '')
        from t_report;
        get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           l_message || ' COMPLETED=====', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;
