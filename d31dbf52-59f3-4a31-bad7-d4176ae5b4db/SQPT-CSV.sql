-- DROP FUNCTION dash360.report_fintech_eod_sqpt_slices(int4, int4);

CREATE OR REPLACE FUNCTION dash360.report_fintech_eod_sqpt_slices(in_start_date_id integer, in_end_date_id integer)
--  RETURNS TABLE(date text, "NewAckTime" text, "EndTime" text, "BrokerRootOrderID" bigint, "BrokerAlgoOrderID" bigint, "BrokerAlgoSubOrderID" bigint, "SubOrderID" character varying, "SubOrderVID" character varying, "ExchOrderID" character varying, "DestinationID" character varying, "OrderType" character varying, "TimeInForce" character varying, "LimitPrice" numeric, "OrderSize" integer, "Filled" numeric, "AverageFillPx" numeric, "MIC" character varying, "ParentOrderID" character varying)
 returns table (ret_row text)
    LANGUAGE plpgsql
AS $function$
    -- SO 20260608 https://dashfinancial.atlassian.net/browse/DEVREQ-8392
declare
    l_account_ids int4[];
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_msg         text;
begin
    l_msg := 'report_fintech_eod_sqpt_slices for ' || in_start_date_id::text || '-' || in_end_date_id::text;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg || ' STARTED ===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id = 'sqpt';

    return query
        select
            array_to_string(array [
            to_char(cl.create_time, 'mm/dd/yyyy'), --                as "Date",
               to_char(cl.create_time, 'yyyy-mm-dd"D"hh24:mi:ss.us') as "NewAckTime",
               to_char(ex.exec_time, 'yyyy-mm-dd"D"hh24:mi:ss.us')   as "EndTime",
               cl.parent_order_id                                    as "BrokerRootOrderID",
               cl.parent_order_id                                    as "BrokerAlgoOrderID",
               cl.order_id                                           as "BrokerAlgoSubOrderID",
               cl.client_order_id                                    as "SubOrderID",
               null::varchar(256)                                    as "SubOrderVID",
               cl.exch_order_id                                      as "ExchOrderID",
               cl.exchange_id                                        as "DestinationID",
               ot.order_type_name                                    as "OrderType",
               tif.tif_name                                          as "TimeInForce",
               cl.price                                              as "LimitPrice",
               cl.order_qty                                          as "OrderSize",
               ex.sum_last_qty                                       as "Filled",
               ex.avg_px                                             as "AverageFillPx",
               exc.mic_code                                          as "MIC",
               par.client_order_id                                   as "ParentOrderID"
                ], ',', '')
        from dwh.client_order cl
                 left join lateral (select *
                                    from dwh.client_order par
                                    where par.order_id = cl.parent_order_id
                                    limit 1) par on true and cl.parent_order_id is not null
                 inner join dwh.d_account ac on ac.account_id = cl.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
                 left join lateral (select po.sub_strategy_desc
                                    from dwh.client_order po
                                    where po.order_id = cl.parent_order_id
                                      and po.create_date_id <= cl.create_date_id
                                    limit 1) po on true
            --              left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
--              left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
                 left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
                 left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
                 left join dwh.d_target_strategy dts on (dts.target_strategy_id = cl.sub_strategy_id)
                 left join lateral (select *
                                    from dwh.d_exchange exc
                                    where exc.exchange_id = cl.exchange_id
                                      and exc.is_active
                                    limit 1) exc on true
                 left join lateral (select sum(last_qty) over ()         as sum_last_qty,
                                           last_value(exec_type) over p  as exec_type,
                                           last_value(exec_time) over p  as exec_time,
                                           last_value(avg_px) over p     as avg_px,
                                           last_value(leaves_qty) over p as leaves_qty
                                    from dwh.execution ex
                                    where ex.order_id = cl.order_id
                                      and exec_date_id >= cl.create_date_id
                                    window p as (partition by ex.order_id order by exec_time desc)
                                    limit 1
            ) ex on true
        where true
          and cl.account_id = any (l_account_ids)
          and cl.create_date_id between in_start_date_id and in_end_date_id
          and cl.trans_type <> 'F'
          and cl.parent_order_id is not null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' COMPLETED ===', l_row_cnt, 'C')
    into l_step_id;

end;

$function$
;
