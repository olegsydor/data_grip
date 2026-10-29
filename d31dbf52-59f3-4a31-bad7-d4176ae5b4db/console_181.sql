-- DROP FUNCTION dash360.report_surveillance_qcc_reporting(int4, int4, _varchar);

CREATE OR REPLACE FUNCTION dash360.report_surveillance_qcc_reporting(in_start_date_id integer, in_end_date_id integer,
                                                                     in_exchange_ids character varying[])
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2024-12-17 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5301
    -- 2026-10-29 OS https://dashfinancial.atlassian.net/browse/DS-12255 Revise QCC report to correctly pick up QCC-related crosses
declare
    l_load_id     int;
    l_step_id     int;
    l_row_cnt     int;
    l_account_ids int4[];

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_qcc_reporting for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' for exchange_ids ' ||
                           coalesce(in_exchange_ids::text, '{}'::text) ||
                           ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select 'Trade Date,Executing Firm Name,Underlying Stock Symbol,Underlying Stock Quantity,Underlying Stock Trade Time,Underlying Stock Trade Price,Underlying Stock Executing Exchange,Option Symbol,Option Trade Quantity,Option Trade Time,Option Trade Price,Option Executing Exchange,Delta';

    return query
        with cte_tr as (select tr.date_id,
                               po.cross_order_id,
                               tr.order_id,
                               max(tr.trade_record_time)                                  as trade_record_time,
                               tf.trading_firm_name,
                               ac.account_name,
                               di.display_instrument_id,
                               tr.instrument_type_id,
                               tr.exchange_id,
                               sum(tr.last_qty)                                           as total_qty,
                               round(sum(tr.last_qty * tr.last_px) / sum(tr.last_qty), 4) as avg_px
                        from dwh.flat_trade_record tr
                                 inner join fix_capture.fix_message_json fm
                                            on (fm.fix_message_id = tr.order_fix_message_id and fm.date_id = tr.date_id)
                                 join dwh.d_account ac on (ac.account_id = tr.account_id)
                                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = ac.trading_firm_unq_id)
                                 left join dwh.client_order po
                                           on (po.create_date_id = tr.date_id and po.order_id = tr.order_id)
                                 left join dwh.d_instrument di on di.instrument_id = tr.instrument_id
                        where tr.date_id between :in_start_date_id and :in_end_date_id
                          and tr.is_busted = 'N'
                          and tr.is_cross_order = 'Y'
                          and fm.fix_message->>'9202'='Q'
                          and tr.street_cross_type = 'Q'
                          and tr.cross_is_originator = 'O'
                          and case
                                  when coalesce(:in_exchange_ids, '{}') = '{}' then true
                                  else tr.exchange_id = any (:in_exchange_ids) end
                        group by tr.date_id, po.cross_order_id, tr.order_id, tf.trading_firm_name, ac.account_name,
                                 di.display_instrument_id, tr.instrument_type_id, tr.exchange_id)
        select array_to_string(ARRAY [
                                   to_char(cte.trade_record_time, 'MM/dd/yyyy') , --as "Trade Date",
                                   'Dash Financial Technologies' , --as "Executing Firm Name",
                                   cte.display_instrument_id , --as "Underlying Stock Symbol",
                                   cte.total_qty::text , --as "Underlying Stock Quantity",
                                   to_char(cte.trade_record_time, 'HH:MI:SS AM') , --as "Underlying Stock Trade Time",
                                   cte.avg_px::text , --as "Underlying Stock Trade Price",
                                   cte.exchange_id , --as "Underlying Stock Executing Exchange",
                                   o.display_instrument_id , --as "Option Symbol",
                                   o.total_qty::text , --as "Option Trade Quantity",
                                   to_char(o.trade_record_time, 'HH:MI:SS AM') , --as "Option Trade Time",
                                   o.avg_px::text , --as "Option Trade Price ",
                                   o.exchange_id , --as "Option Executing Exchange",
                                   round(cte.total_qty::numeric / min(o.total_qty::numeric)
                                                                  over (partition by o.date_id, o.cross_order_id, o.instrument_type_id),
                                         2)::text --as "Delta"
                                   ], ',', '')
        from cte_tr as cte
                 join cte_tr as o
                      on (o.date_id = cte.date_id and o.cross_order_id = cte.cross_order_id and
                          o.instrument_type_id = 'O')
        where cte.instrument_type_id = 'E'
        order by cte.date_id, cte.cross_order_id, cte.order_id, o.order_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_qcc_reporting for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || 'for exchange_ids ' || coalesce(in_exchange_ids::text, '{}'::text) ||
                           ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;



select regexp_replace(COALESCE(:basecode, ''::text), '\.|-'::text, ''::text,
                                       'g'::text)


split_part(symbol, '.', 2)



-- DROP FUNCTION dash360.get_repeating_tags(int8, int4, varchar, bpchar);

CREATE OR REPLACE FUNCTION trash.get_repeating_tags(in_fix_message_id bigint, in_date_id integer,
                                                    in_client_order_id character varying,
                                                    in_cross_is_originator character)
    RETURNS TABLE
            (
                tag_10707 text,
                tag_10609 text
            )
    LANGUAGE plpgsql
AS
$function$
    -- SO 20261016 https://dashfinancial.atlassian.net/browse/DS-12193 aux func to get the correct value of 2 tags of fix_message regarding passed input parameters
begin
    if in_cross_is_originator = 'N' then
        return query
            select fmj.fix_message_jsonb ->> '10707', fmj.fix_message_jsonb ->> '10609'
            from staging.fix_message_json fmj
            where fmj.date_id = in_date_id
              and fmj.fix_message_id = in_fix_message_id;
    else
        select matched.obj ->> '10707' as tag_10707,
               matched.obj ->> '10609' as tag_10609
        --select coalesce(matched.obj ->> '10707', fmj.fix_message_jsonb ->> '10707') as tag_10707,
--       coalesce(matched.obj ->> '10609', fmj.fix_message_jsonb ->> '10609') as tag_10609
        from staging.fix_message_json fmj
                 left join lateral (
            select g.obj
            from jsonb_array_elements(
                         case
                             when fmj.fix_message_jsonb ? '552' then fmj.fix_message_jsonb -> '552'
                             else jsonb_build_array(fmj.fix_message_jsonb)
                             end
                 ) as g(obj)
            where not (fmj.fix_message_jsonb ? '552')
               or (
                g.obj ->> '11' = in_client_order_id
                    and g.obj ->> '10009' = in_cross_is_originator
                )
            ) matched on true
        where fmj.date_id = in_date_id
          and fmj.fix_message_id = in_fix_message_id
        limit 1;
    end if;
end;
$function$
;
