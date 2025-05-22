select *
from dash360.report_compliance_avg_parent_order_count(in_start_date_id := 20250303, in_end_date_id := 20250315
    , in_trading_firm_ids := '{alpaca,caerus}'
    , in_account_ids := '{71912, 72420, 72917}'
     , in_instrument_type_id := null
     );

select *
from dash360.report_compliance_avg_parent_order_count(
        in_trading_firm_ids := '{OFP0058,OFP0077,t3trade01}',
        in_instrument_type_id := null
     );




-- drop function dash360.report_compliance_avg_parent_order_count

create or replace function dash360.report_compliance_avg_parent_order_count(in_start_date_id int4 default null,
                                                                            in_end_date_id int4 default null,
                                                                            in_trading_firm_ids character varying[] default '{}'::character varying[],
                                                                            in_account_ids int4[] default '{}'::int4[],
                                                                            in_instrument_type_id character DEFAULT 'O'::bpchar)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
    -- https://dashfinancial.atlassian.net/browse/DEVREQ-6008
declare
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
    l_account_ids   int4[];
    l_message       text;
    l_start_date    date := case
                                when in_start_date_id is not null then in_start_date_id::text::date
                                else date_trunc('month', current_date - '1 month'::interval)::date end;
    l_end_date      date := case
                                when in_end_date_id is not null then in_end_date_id::text::date
                                else (date_trunc('month', current_date) - '1 day'::interval)::date end;
    l_start_date_id int4 := to_char(l_start_date, 'YYYYMMDD');
    l_end_date_id   int4 := to_char(l_end_date, 'YYYYMMDD');
    l_all_days      int4;
begin
    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    l_message =
            'report_compliance_avg_parent_order_count, ' ||
            case when in_account_ids = '{}' then '' else 'accounts-' || left(array_to_string(in_account_ids::int4[], ',', '')::text, 50) end ||
            case
                when in_trading_firm_ids = '{}' then ''
                else 'trading_firm-' || left(array_to_string(in_trading_firm_ids::varchar[], ',', '')::text, 50) end ||
            ' for ' || l_start_date_id::text || '-' || l_end_date_id::text ||
            ' ';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           l_message || 'STARTED ===', 0, 'O')
    into l_step_id;

    select count(*)
    into l_all_days
    from (select generate_series(l_start_date, l_end_date, '1 day')::date as dt) x
    where extract(dow from x.dt) between 1 and 5
      and not exists (select null from public.holiday_calendar hc where hc.holiday_date = x.dt and hc.is_active);

    drop table if exists t_report;
    create temp table t_report as
    select to_char(hods."StatusDate", 'Month') as "Month",
           to_char(hods."StatusDate", 'YYYY')  as "Year",
           count(distinct "StatusDate")        as "Actually Trading Days",
           tf.trading_firm_name::varchar       as "Firm",
           a.account_name::varchar             as "Account",
           cf.customer_or_firm_name::varchar   as "Capacity",
           count(distinct hods."ClOrdID")      as "Parent Order Count"
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on (a.account_id = hods."AccountID")
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where true
      and "Status_Date_id" >= l_start_date_id
      and "Status_Date_id" <= l_end_date_id
      and case when in_instrument_type_id is null then true else hods."InstrumentType" = in_instrument_type_id end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (l_account_ids) -- '{54612,54613,54690,54691,62093,62577,72945,73094}'
    group by to_char(hods."StatusDate", 'Month'), to_char(hods."StatusDate", 'YYYY'), a.account_name,
             cf.customer_or_firm_name, tf.trading_firm_name;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           l_message || ' data set calculated', l_row_cnt, 'O')
    into l_step_id;

    return query
        select 'Firm,Account,Capacity,Year,Month,Calendar Trading Days,Actually Trading Days,Total Orders';
    return query
        select array_to_string(ARRAY [
                                   "Firm",
                                   "Account",
                                   "Capacity",
                                   "Year",
                                   trim("Month"),
                                   l_all_days::text,
                                   "Actually Trading Days"::text,
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

select * from t_report
select trim(to_char(:"Period", 'Month')) May;

select to_char(to_date(:proforma_invoice_date, 'DD/MM/YYYY'), 'Month')

    select to_date(:proforma_invoice_date, 'DD/MM/YYYY')
select array_to_string('{1, 2, 3}'::int4[], ',', '');

select 'report_compliance_avg_parent_order_count, ' ||
            case when :in_account_ids = '{}' then '' else 'accounts-' || left(array_to_string(:in_account_ids::int4[], ',', '')::text, 50) end ||
            case
                when :in_trading_firm_ids = '{}' then ''
                else ', trading_firm-' || left(array_to_string(:in_trading_firm_ids::varchar[], ',', '')::text, 50) end ||
            ' for ' || :l_start_date_id::text || '-' || :l_end_date_id::text ||
            ' ';