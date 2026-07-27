-- DEVREQ-8753

select *
from dash360.report_fintech_venue_breakdown_by_symbol(in_start_date_id := 20260723, in_end_date_id := 20260723);

create or replace function dash360.report_fintech_venue_breakdown_by_symbol(in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                                            in_end_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                                            in_trading_firm_ids varchar(9)[] default '{davinci01}'::varchar(9)[],
                                                                            in_account_ids int8[] default null::int8[],
                                                                            in_instrument_type_id character default 'E'::bpchar
)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids int8[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_venue_breakdown_by_symbol for ' || in_start_date_id::text ||
                           '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

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
                  when coalesce(in_account_ids, '{}') <> '{}'::int8[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    return query
        select 'Trade Date,Sec Type,Symbol,Venue,Order Qty,Fill Qty,Fill Rate';

    return query
        select array_to_string(array [
                                   to_char(cl.create_time, 'YYYY/MM/DD'), -- Trade Date
                                   di.instrument_type_id, -- Security Type
                                   display_instrument_id, -- Symbol
                                   exc.exchange_name, -- Venue
                                   to_char(sum(cl.order_qty), 'FM9999999'),-- Order Qty
                                   to_char(sum(sum_last_qty), 'FM9999999'),-- Last Qty
                                   to_char(round(100.0 * sum(sum_last_qty) / sum(cl.order_qty), 2), 'FM990.00%')
                                   ], ',', '')
        from dwh.client_order cl
                 join lateral (select sum(last_qty) as sum_last_qty
                               from dwh.execution ex
                               where ex.order_id = cl.order_id
                                 and not ex.is_parent_level
                                 and ex.exec_date_id between in_start_date_id and in_end_date_id
                               limit 1) ex on true
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
        where true
          and cl.parent_order_id is not null
          and cl.create_date_id between in_start_date_id and in_end_date_id
          and case when in_instrument_type_id is null then true else di.instrument_type_id = in_instrument_type_id end
          and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
        group by create_time, di.instrument_type_id, display_instrument_id, exc.exchange_name;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_venue_breakdown_by_symbol for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED=====', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;

select to_char(round(100.0 * 500 / 500, 2), '990.99%')

;

select array_agg(account_id)
from dwh.d_account
where true
  and trading_firm_id = ANY (:in_trading_firm_ids)
;


select to_char(cl.create_time, 'YYYY/MM/DD'),  -- Trade Date
       di.instrument_type_id,                  -- Security Type
       display_instrument_id,                  -- Symbol
       exc.exchange_name,                      -- Venue
       to_char(sum(cl.order_qty), 'FM9999999'),-- Order Qty
       to_char(sum(ex.sum_last_qty), 'FM9999999'),-- Last Qty
       to_char(round(100.0 * sum(sum_last_qty) / sum(cl.order_qty), 2), 'FM990.00%')
from dwh.client_order cl
        join lateral (select sum(last_qty) as sum_last_qty
                               from dwh.execution ex
                               where ex.order_id = cl.order_id
                                 and not ex.is_parent_level
                                 and ex.exec_date_id between :in_start_date_id and :in_end_date_id
                               limit 1) ex on true
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id
         join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
where true
  and cl.parent_order_id is not null
  and cl.create_date_id between :in_start_date_id and :in_end_date_id
  and case when :in_instrument_type_id is null then true else di.instrument_type_id = :in_instrument_type_id end
  and case when :l_account_ids = '{}' then true else cl.account_id = any (:l_account_ids) end
group by create_time, di.instrument_type_id, display_instrument_id, exc.exchange_name;