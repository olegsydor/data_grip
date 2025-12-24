-- DROP FUNCTION dash360.get_active_parent_gtc_orders(_int4, int4, int4, _varchar);

create function dash360.report_fintech_fis_open_order(
    in_start_date_id integer default to_char(current_date, 'YYYYMMDD'::text)::integer,
    in_end_date_id integer default to_char(current_date, 'YYYYMMDD'::text)::integer,
    in_trading_firm_ids character varying[] default '{}'::character varying[],
    in_account_ids integer[] default null::integer[],
    in_instrument_types char default null)
    returns table
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS $function$
    -- 2025-12-23 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-7269
declare
    row_cnt           int4;
    l_load_id         int;
    l_step_id         int;
    l_is_current_date bool := false;
    l_account_ids     int4[];
begin

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_fis_open_order for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
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
-- raise notice 'l_account_ids - %', l_account_ids;
    return query
        select 'ORDER DATE,ROUTED_ORDER_REF,TYPE,BUY/SELL,CALL/PUT,OPEN/CLOSING,CONTRACTS,SYMBOL,EXPIRY,STRIKE,LIMIT,STOP LIMIT,EXPIRY_TYPE,BROKER_ORDER_ID,SENDER_SUB_ID,EXPIRE_DATE';

    return query
        select array_to_string(ARRAY [
               gtc.create_date_id::text,                                                              -- as "ORDER DATE",
               cl.client_order_id,                                                                    -- as "ROUTED_ORDER_REF",
               case di.instrument_type_id when 'E' then 'Equity' when 'O' then 'Option' end,          -- as "TYPE",
               case
                   when cl.side = '1' then 'Buy'
                   when cl.side in ('2', '5', '6') then 'Sell' end,                                   -- as "BUY/SELL",
               case oc.put_call when '0' then 'PUP' when '1' then 'CALL' end,                         -- as "CALL/PUT",
               case cl.open_close when 'O' then 'OPEN' when 'C' then 'CLOSE' end,                     -- as "OPEN/CLOSING",
               cl.order_qty::text,                                                                    -- as "CONTRACTS",
               di.symbol,                                                                             -- as "SYMBOL",
               concat_ws('', oc.maturity_year::text, oc.maturity_month::text, oc.maturity_day::text), -- as "EXPIRY",
               oc.strike_price::text,                                                                 -- as "STRIKE",
               cl.price::text,                                                                        -- as "LIMIT",
               cl.stop_price::text,                                                                   -- as "STOP LIMIT",
               tif.tif_short_name,                                                                    -- as "EXPIRY_TYPE",
               null,                                                                                  -- as "BROKER_ORDER_ID",
               null,                                                                                  -- as "SENDER_SUB_ID",
               null                                                                                   -- as EXPIRE_DATE
            ], ',', '')
        from dwh.gtc_order_status gtc
                 join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
                 left join dwh.d_time_in_force tif
                           on cl.time_in_force_id = tif.tif_id
        where cl.parent_order_id is null
          and gtc.create_date_id <= in_start_date_id
          and (gtc.close_date_id is null
            -- the code below has been added to provide the same performance in the case we use the report for CURRENT date
            or (case
                    when l_is_current_date then false
                    else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
          -- end of
          and cl.trans_type in ('D', 'G')
          and cl.time_in_force_id in ('1', '6')
          and cl.multileg_reporting_type in ('1', '2')
          and case when l_account_ids = '{}' then true else gtc.account_id = any (l_account_ids) end
        and case when in_instrument_types is null then true else di.instrument_type_id = in_instrument_types end
        order by gtc.order_id;
    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_fis_open_order for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           row_cnt, 'O')
    into l_step_id;

   end;
$function$
;

select *
from dash360.report_fintech_fis_open_order(in_start_date_id := 20251223, in_end_date_id := 20251223,
                                           in_trading_firm_ids := '{OFP0001}');


select * from dwh.gtc_order_status gtc
    join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
join dwh.d_account ac on ac.account_id = gtc.account_id
where gtc.close_date_id is null
and ac.trading_firm_id = 'OFP0001'
           and cl.trans_type in ('D', 'G')
           and cl.multileg_reporting_type in ('1', '2')
and cl.parent_order_id is null