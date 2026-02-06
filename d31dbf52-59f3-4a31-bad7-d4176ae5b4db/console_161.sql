-- DROP FUNCTION dash360.get_active_parent_gtc_orders(_int4, int4, int4, _varchar);

CREATE OR REPLACE FUNCTION dash360.report_gtc_impacted_active(in_start_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                              in_end_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer)
 RETURNS TABLE(account_name character varying, creation_date timestamp without time zone, ord_status character varying, sec_type character, side character, symbol character varying, ex_dest character varying, ord_qty integer, ex_qty numeric, ord_type character, price numeric, avg_px numeric, lvs_qty bigint, is_mleg text, leg_id character varying, open_close character, dash_id character varying, cl_ord_id character varying, orig_cl_ord_id character varying, occ_data text, osi_symbol character varying, client_id character varying, subsystem character varying, strike_px numeric, put_call character, exp_year smallint, exp_month smallint, exp_day smallint, order_id bigint, sender_comp_id character varying)
 LANGUAGE plpgsql
AS $function$
    -- 2026-02-06 SO: https://dashfinancial.atlassian.net/browse/DS-11064
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
                           'report_gtc_impacted_active for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;
  select to_char(to_date(:maturity_year::text ||:maturity_day::text || :maturity_month::text, 'YYYYMMDD'), 'DD Mon YYYY')

    return query
        select ac.account_name              as "Account",
               cl.create_time::date               as "Creation Date",
               case di.instrument_type_id when 'E' then 'Equity' when 'O' then 'Option' end as "Sec Type",
               case cl.side when '1' then 'Buy'
                   when '2' then 'Sell' when '5' then 'Sell Short' when '6' then 'Sell Short' end                      as "Side",
               cl.order_qty                 as "Ord Qty",
               di.symbol                    as "Symbol",
               oc.strike_price              as "Strike Px",
               case oc.put_call when '1' then 'C' when '2' then 'P' end                 as put_call,
               to_char(to_date(oc.maturity_year::text ||oc.maturity_day::text || oc.maturity_month::text, 'YYYYMMDD'), 'DD Mon YYYY')             as exp_day,
               dex.ex_destination_code_name as ex_dest,
               cl.order_type_id             as ord_type,
               cl.price                     as price,
               exl.ex_qty,
               ex.avg_px                    as avg_px,
               ex.leaves_qty                as lvs_qty,
               case
                   when cl.multileg_reporting_type = '1' then 'N'
                   when cl.multileg_reporting_type = '2'
                       then 'Y' end         as is_mleg,
               cl.co_client_leg_ref_id		as leg_id,
               cl.open_close                as open_close,
               oc.opra_symbol               as osi_symbol,
               cl.client_order_id           as cl_ord_id,
               cl.client_id_text            as client_id,
               fc.fix_comp_id               as sender_comp_id

        from dwh.gtc_order_status gtc
                 join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 inner join dwh.d_account ac on (cl.account_id = ac.account_id)
                 join lateral (select ex.exec_id as exec_id,
                                      ex.avg_px,
                                      ex.leaves_qty,
                                      ex.order_status
                               from dwh.execution ex
                               where gtc.order_id = ex.order_id
                                 and ex.order_status <> '3'
                                 and ex.exec_date_id >= gtc.create_date_id
                               order by ex.exec_time desc
                               limit 1) ex on true
                 inner join dwh.d_order_status ors on ors.order_status = ex.order_status
                 left join lateral (select sum(ex.last_qty) as ex_qty
                                    from dwh.execution ex
                                    where ex.exec_date_id >= gtc.create_date_id
                                      and ex.order_id = cl.order_id
                                      and ex.exec_type in ('F', 'G')
                                      and ex.is_busted = 'N'
                                    limit 1) exl on true

                 left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
--                  left join dwh.d_sub_system ss on ss.sub_system_unq_id = cl.sub_system_unq_id
                 left join dwh.d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id
                 left join dwh.d_ex_destination_code dex on dex.ex_destination_code = cl.ex_destination and dex.is_active

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
--           and case when coalesce(in_account_ids, '{}') = '{}' then true else gtc.account_id = any (in_account_ids) end
--           and case when l_account_ids = '{}' then true else gtc.account_id = any (l_account_ids) end
    order by gtc.order_id;
    get diagnostics row_cnt = row_count;


    select public.load_log(l_load_id, l_step_id,
                           'get_active_parent_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           row_cnt, 'O')
    into l_step_id;

   end;
$function$
;
