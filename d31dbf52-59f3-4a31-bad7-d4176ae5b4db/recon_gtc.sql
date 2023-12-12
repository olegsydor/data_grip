create function dash360.report_gtc_recon(in_instrument_type_id character varying default 'O'::character varying,
                                                    in_account_ids int4[] default '{}'::int4[])
    returns table
            (
    "CreateDate"     text,
    "ClOrdID"        varchar(256),
    "LegRefID"       varchar(30),
    "BuySell"        text,
    "Symbol"         varchar(10),
    "OpenQuantity"   varchar,
    "Price"          varchar,
    "ExpirationDate" text,
    "TypeCode"       text,
    "Strike"         varchar,
    "StopPx"         text,
    "Order_Quantity" integer,
    "ProductType"    bpchar
            )
    language plpgsql
as
$function$
declare
    l_row_cnt          integer;
    l_load_id          integer;
    l_step_id          integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_recon STARTED===', 0, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, left(' account_ids = ' || in_account_ids::text, 200), 0,
                           'O')
    into l_step_id;

    return query
    select to_char(co.create_time, 'DD/MM/YYYY HH:MI:SS AM')                                     as "CreateDate",
           co.client_order_id                                                                    as "ClOrdID",
           co.co_client_leg_ref_id                                                               as "LegRefID",
           case
               when co.side in ('1', '3')
                   then 'BUY'
               else 'SELL'
               end                                                                               as "BuySell",
           i.symbol                                                                              as "Symbol",
           (co.order_qty -
            coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id),
                     0))::varchar                                                                as "OpenQuantity",
           coalesce(co.price, co.stop_price)::varchar                                            as "Price",
           coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), to_char(co.expire_time, 'YYYYMMDD')) as "ExpirationDate",
           case
               when oc.put_call = '0' then 'P'
               when oc.put_call = '1' then 'C'
               end                                                                               as "TypeCode",
           oc.strike_price::varchar                                                              as "Strike",
           fmj.t99                                                                               as "StopPx",
           order_qty                                                                             as "Order_Quantity",
           case
               when co_client_leg_ref_id is not null then 'MLEG'
               when i.instrument_type_id = 'O' then 'OPT'
               when i.instrument_type_id = 'E' then 'EQ'
--	        when i.instrument_type_id = 'M' then 'MLEG'
               else i.instrument_type_id end                                                     as "ProductType"
    from dwh.gtc_order_status gos
             join dwh.client_order co on gos.order_id = co.order_id and gos.create_date_id = co.create_date_id
             join dwh.d_instrument i on co.instrument_id = i.instrument_id and i.instrument_type_id = 'O'
             left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
             left join lateral (select fix_message ->> '99' as t99
                                from fix_capture.fix_message_json fmj
                                where fmj.date_id = co.create_date_id
                                  and fmj.fix_message_id = co.fix_message_id
                                limit 1) fmj on true
    where true
      and co.parent_order_id is null
--       and case when coalesce(in_account_ids, '{}') = '{}' then true else gos.account_id = any(in_account_ids) end
--       and case when in_instrument_type_id is null then true else i.instrument_type_id = in_instrument_type_id end
      and gos.account_id = any('{14765,53948,26573,19265}')
      and gos.close_date_id is null
      and co.multileg_reporting_type <> '3';

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_recon COMPLETED===', coalesce(l_row_cnt, 0),
                           'O')
    into l_step_id;

END;
$function$
;


select * from dash360.report_gtc_recon(in_instrument_type_id := 'O',
                                                    in_account_ids := '{14765,53948,26573,19265}')



CREATE or replace FUNCTION dwh.get_cum_qty_from_orig_orders(in_order_id bigint, in_date_id integer)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$

declare
  l_cum_qty bigint;

begin

    if (select orig_order_id
        from dwh.client_order
        where order_id = in_order_id
          and create_date_id = in_date_id) is null then

        select sum(tr.last_qty)
        into l_cum_qty
        from dwh.flat_trade_record tr
        where tr.order_id = in_order_id
          and tr.date_id >= in_date_id
          and tr.is_busted = 'N';
        return l_cum_qty;
    end if;

   with recursive orig as(

        select order_id, orig_order_id, 1 as level
          , create_date_id
        from dwh.client_order
        where order_id = in_order_id
        and create_date_id = in_date_id

        union all

        select e.order_id, e.orig_order_id, r.level + 1
          , e.create_date_id
        from orig r
        join client_order e on e.order_id = r.orig_order_id

    )
  select sum(coalesce(tr.last_qty, 0))::bigint as cum_qty
    --, r.*
  into l_cum_qty
  from orig r
    left join lateral
      (
        select tr.order_id , sum(tr.last_qty) as last_qty
        from dwh.flat_trade_record tr
        where tr.order_id = r.order_id
          and tr.date_id >= r.create_date_id
          and tr.is_busted = 'N'
--           and tr.date_id >= l_gtc_date_id
        group by tr.order_id
      ) tr on true
  where tr.last_qty is not null;

  return l_cum_qty;

end;
$function$
;

s