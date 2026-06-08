select * from dash360.report_fintech_eod_sqpt_orders(20260605, 20260605)
-- https://dashfinancial.atlassian.net/browse/DEVREQ-8392
CREATE FUNCTION dash360.report_fintech_eod_sqpt_orders(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                "date"              text,
                "NewAckTime"        text,
                "EndTime"           text,
                "ParentOrderID"     varchar(256),
                "BrokerRootOrderID" int8,
                "BrokerAlgoOrderID" int8,
                "SecurityType"      bpchar(1),
                "Algo"              varchar(128),
                "Symbol"            varchar(30),
                "Strike"            numeric(12, 4),
                "CallOrPut"         bpchar(1),
                "Expiration"        text,
                "Side"              text,
                "LegSide"           text,
                "LegRatio"          int8,
                "Option"            text,
                "Size"              int4,
                "Executed"          numeric,
                "OrderType"         varchar(255),
                "OrderPrice"        numeric(12, 4),
                "AverageFillPx"     numeric,
                "Strategy"          varchar(128),
                "DisplayQty"        text
            )
    LANGUAGE plpgsql
AS
$function$
    -- SO 20260608 https://dashfinancial.atlassian.net/browse/DEVREQ-8392
declare
    l_account_ids int4[];
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_msg         text;
begin
    l_msg := 'report_fintech_eod_sqpt_orders for ' || in_start_date_id::text || '-' || in_end_date_id::text;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg || ' STARTED ===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id = 'sqpt';

    return query
    select to_char(cl.create_time, 'dd-mm-yy')                                                as date,
           to_char(cl.create_time, 'yyyy-mm-dd"D"hh24:mi:ss.us')                              as "NewAckTime",
           to_char(case when ex.exec_type = '4' then cl.order_cancel_time else ex.exec_time end,
                   'yyyy-mm-dd"D"hh24:mi:ss.us')                                              as "EndTime", -- ??
           coalesce(par.client_order_id, cl.client_order_id)                                  as "ParentOrderID",
           cl.parent_order_id                                                                 as "BrokerRootOrderID",
           cl.parent_order_id                                                                 as "BrokerAlgoOrderID",
           i.instrument_type_id                                                               as "SecurityType",
           target_strategy_name                                                               as "Algo",
           oc.opra_symbol                                                                     as "Symbol",
           oc.strike_price                                                                    as "Strike",
           oc.put_call                                                                        as "CallOrPut",
           to_char(OC.MATURITY_DAY, 'FM00') || '-' || to_char(OC.MATURITY_MONTH, 'FM00') || '-' ||
           to_char(OC.MATURITY_YEAR, 'FM0000')                                                as "Expiration",

           case when cl.side = '1' then 'Buy' when cl.side in ('2', '5', '6') then 'Sell' end as "Side",
           case when cl.side = '1' then 'Buy' when cl.side in ('2', '5', '6') then 'Sell' end as "LegSide",
           cl.ratio_qty                                                                       as "LegRatio",
           null                                                                               as "Option",  --??
           cl.order_qty                                                                       as "Size",
           ex.sum_last_qty                                                                    as "Executed",
           ot.order_type_name                                                                 as "OrderType",
           cl.price                                                                           as "OrderPrice",
           ex.avg_px                                                                          as "AverageFillPx",
           dts.target_strategy_name                                                           as "Strategy",
           null                                                                               as "DisplayQty"
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
             left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
             left join dwh.d_target_strategy dts on (dts.target_strategy_id = cl.sub_strategy_id)
             left join lateral (select *
                                from dwh.d_exchange exc
                                where exc.exchange_id = cl.exchange_id
                                  and exc.is_active
                                limit 1) exc on true
             left join lateral (select sum(last_qty) over p          as sum_last_qty,
                                       first_value(exec_type) over p as exec_type,
                                       first_value(exec_time) over p as exec_time,
                                       first_value(avg_px) over p    as avg_px
                                from dwh.execution ex
                                where ex.order_id = cl.order_id
                                  and exec_date_id >= cl.create_date_id
                                  and ex.exec_type not in ('a', 'A', 'S', '0')
                                window p as (partition by order_id order by exec_time desc)
                                limit 1) ex on true
    where true
          and cl.account_id = any (l_account_ids)
      and cl.create_date_id between in_start_date_id and in_end_date_id
      and cl.trans_type <> 'F'
      and cl.parent_order_id is null
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' COMPLETED ===', l_row_cnt, 'C')
    into l_step_id;

end;

$function$