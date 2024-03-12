create or replace function dash360.report_gtc_recon_ofp0038(in_instrument_type_id character varying default 'O'::character varying,
                                                            in_account_ids int4[] default '{}'::int4[],
                                                            in_start_date_id int4 default to_char(current_date, 'YYYYMMDD'::text)::int4,
                                                            in_end_date_id int4 default to_char(current_date, 'YYYYMMDD'::text)::int4)
    returns table
            (
                export_row text
            )
    language plpgsql
AS
$function$
    -- 2024-03-12 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-4139

DECLARE
    l_row_cnt         integer;
    l_is_current_date bool := false;
    l_load_id         integer;
    l_step_id         integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;


    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_recon_ofp0038 for ' || in_start_date_id::text || ' - ' ||
                           in_end_date_id::text || ' STARTED===', 0, 'O')
        into l_step_id;

    -- Check if the report is performing for the current date (it allows to improve performance)
    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    return query
        select 'CreateDate,ClOrdID,BuySell,Symbol,OpenQuantity,Price,ExpirationDate,TypeCode,Strike';

  return query
  select array_to_string(ARRAY [
    s.cl_ord_id::varchar, -- OrderID
    s.side::varchar, -- Side
    s.put_or_call, -- PutOrCall
    s.open_close, -- OpenClose
    s.qty::varchar, -- Qty
    s.symbol::varchar,-- Symbol
    s.suffix::varchar, -- Suffix
    s.expiration_date::varchar, -- ExpirationDate
    s.strike_price::varchar, -- StrikePrice
    s.limit_price::varchar, -- LimitPrice
    s.stop_price::varchar,-- StopPrice
    s.exec_inst::varchar              -- ExecInst
], '|', '')
  from
    (
      select --to_char(co.create_time, 'DD/MM/YYYY HH:MI:SS AM') as create_date
          co.client_order_id as cl_ord_id
        , co.side as side
        , oc.put_call as put_or_call
        , co.open_close as open_close
        , co.order_qty  as qty
        , i.symbol as symbol
        , i.symbol_suffix as suffix
        , coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), '')::varchar as expiration_date
        , oc.strike_price as strike_price
        , co.price as limit_price
        , co.stop_price as stop_price
        , co.exec_instruction as exec_inst
      from dwh.gtc_order_status gos
      join dwh.client_order co on gos.order_id = co.order_id and gos.create_date_id = co.create_date_id
        join dwh.d_instrument i          on co.instrument_id = i.instrument_id
        left join dwh.d_option_contract oc          on i.instrument_id = oc.instrument_id
      where true
              and (gos.close_date_id is null
-- the code below has been added to provide the same performance in the case we use the report for CURRENT date
           or (case
                when l_is_current_date then false
                else gos.close_date_id is not null and close_date_id > in_end_date_id end))
        and gos.create_date_id <= in_start_date_id
        and co.parent_order_id is null -- parent level
      and case when coalesce(in_account_ids, '{}') = '{}' then true else gos.account_id = any(in_account_ids) end
      and case when in_instrument_type_id is null then true else i.instrument_type_id = in_instrument_type_id end
        and co.time_in_force_id = '1'
        and gos.multileg_reporting_type in ('1','2')
        and co.trans_type <> 'F'
    ) s;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_recon_ofp0038 for ' || in_start_date_id::text || ' - ' ||
                           in_end_date_id::text || ' FINISHED===', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;


select *
from dash360.report_gtc_recon_ofp0038(in_instrument_type_id := 'O',
                                      in_account_ids := '{58091,19250, 61889, 52465,30150,11881,64998,20805}',
                                      in_start_date_id := 20240310,
                                      in_end_date_id := 20240312
     )