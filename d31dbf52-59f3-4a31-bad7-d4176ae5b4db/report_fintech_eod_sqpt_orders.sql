select *
from dash360.report_fintech_eod_sqpt_orders(20260605, 20260605);
-- https://dashfinancial.atlassian.net/browse/DEVREQ-8392
CREATE or replace FUNCTION dash360.report_fintech_eod_sqpt_orders(in_start_date_id integer, in_end_date_id integer)
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
--            to_char(case when ex.exec_type = '4' then cl.order_cancel_time else ex.exec_time end,
--                    'yyyy-mm-dd"D"hh24:mi:ss.us')                                              as "EndTime", -- ??
               to_char(ex.exec_time, 'yyyy-mm-dd"D"hh24:mi:ss.us')                                as "EndTime", -- ??
               cl.client_order_id                                                                 as "ParentOrderID",
               cl.parent_order_id                                                                 as "BrokerRootOrderID",
               cl.order_id                                                                        as "BrokerAlgoOrderID",
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
                 inner join dwh.d_account ac on ac.account_id = cl.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
                 left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
                 left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
                 left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
--              left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
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
          and cl.parent_order_id is null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' COMPLETED ===', l_row_cnt, 'C')
    into l_step_id;

end;

$function$;


select cl.order_cancel_time, ex.*, cl.*
from dwh.client_order cl
         left join lateral (select sum(last_qty) over () as sum_last_qty,
                                   last_value(exec_type) over p                                           as exec_type,
                                   last_value(exec_time) over p                                           as exec_time,
                                   last_value(avg_px) over p                                              as avg_px,
                                   last_value(leaves_qty) over p                                          as leaves_qty
                            from dwh.execution ex
                            where ex.order_id = cl.order_id
                              and exec_date_id >= cl.create_date_id
                            window p as (partition by ex.order_id order by exec_time desc)
             limit 1
    ) ex on true
--                       left join lateral (select ee.exec_time
--                             from dwh.execution ee
--                             where ee.order_id = cl.order_id
--                               and ee.exec_date_id  = cl.create_date_id
--                               and ((exec_type = 'F' and ee.leaves_qty = 0)
--                                 or exec_type in ('3', '4', '5', '8', 'C'))
--                             order by ee.exec_id
--         ) ex on true
--                   join lateral (select ex.exec_id as exec_id,
--                                       ex.avg_px,
--                                       ex.leaves_qty,
--                                       ex.order_status,
--                                       ex.exec_type,
--                                       case when exec_type in ('3', '4', '5', '8', 'C') then ex.exec_time end as cancel_time
--                                from dwh.execution ex
--                                where cl.order_id = ex.order_id
--                                  and ex.order_status <> '3'
--                                  and ex.exec_date_id >= cl.create_date_id
--                                and ((ex.exec_type = 'F' and ex.leaves_qty = 0)
--                                  or ex.exec_type in ('3', '4', '5', '8', 'C'))
--                                order by ex.exec_time desc
--                                limit 1) ex on true
where cl.order_id = 464483241166558841;

select ex.* from dwh.client_order cl
    join dwh.execution ex on ex.order_id = cl.order_id
where cl.parent_order_id = 464483241166558841;

select * from dwh.d_exec_type;


select or from dwh.client_order;
select * from dwh.d_time_in_force;
select mi from dwh.d_exchange;
select *
from dash360.report_fintech_eod_sqpt_slices(20260610, 20260610);

CREATE or replace FUNCTION dash360.report_fintech_eod_sqpt_slices(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                "date"                 text,
                "NewAckTime"           text,
                "EndTime"              text,
                "BrokerRootOrderID"    int8,
                "BrokerAlgoOrderID"    int8,
                "BrokerAlgoSubOrderID" int8,
                "SubOrderID"           varchar(256),
                "SubOrderVID"          varchar(256),
                "ExchOrderID"          varchar,
                "DestinationID"        varchar,
                "OrderType"            varchar(255),
                "TimeInForce"          varchar(255),
                "LimitPrice"           numeric,
                "OrderSize"            int4,
                "Filled"               numeric,
                "AverageFillPx"        numeric,
                "MIC"                  varchar,
                "ParentOrderID"        varchar(256)
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
        select to_char(cl.create_time, 'dd-mm-yy')                   as date,
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
        from dwh.client_order cl
                 left join lateral (select *
                                    from dwh.client_order par
                                    where par.order_id = cl.parent_order_id
                                    limit 1) par on true and cl.parent_order_id is not null
                 inner join dwh.d_account ac on ac.account_id = cl.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
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

$function$;



select * from dwh.d_liquidity_indicator

CREATE or replace FUNCTION dash360.report_fintech_eod_sqpt_fills(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                "date"                 text,
                "NewAckTime"           text,
                "EndTime"              text,
                "BrokerRootOrderID"    int8,
                "BrokerAlgoOrderID"    int8,
                "BrokerAlgoSubOrderID" int8,
                "SubOrderID"           varchar(256),
                "SubOrderVID"          varchar(256),
                "ExchOrderID"          varchar,
                "DestinationID"        varchar,
                "OrderType"            varchar(255),
                "TimeInForce"          varchar(255),
                "LimitPrice"           numeric,
                "OrderSize"            int4,
                "Filled"               numeric,
                "AverageFillPx"        numeric,
                "MIC"                  varchar,
                "ParentOrderID"        varchar(256)
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
    l_msg := 'report_fintech_eod_sqpt_fills for ' || in_start_date_id::text || '-' || in_end_date_id::text;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg || ' STARTED ===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id = 'sqpt';

    return query
        select to_char(cl.create_time, 'dd-mm-yy')                   as date,
               to_char(ex.exec_time, 'yyyy-mm-dd"D"hh24:mi:ss.us') as "TradeTime",
               cl.parent_order_id                                    as "BrokerRootOrderID",
               cl.client_order_id                                    as "SubOrderID",
               null::varchar(256)                                    as "SubOrderVID",
               exc.mic_code                                          as "MIC",
               ex.last_qty as "FillQty",
               ex.last_px as "FillPx",
               ex.exec_id as "ExecID",
               ex.exch_exec_id as "ExchExecID",
               ex.first_exec_id as "RootExecID",
li.liquidity_indicator_type_id as "NativeLiquidityIndicator",
li.description as "NormalizedLiquidityIndicator",


               to_char(cl.create_time, 'yyyy-mm-dd"D"hh24:mi:ss.us') as "NewAckTime",
               to_char(ex.exec_time, 'yyyy-mm-dd"D"hh24:mi:ss.us')   as "EndTime",

               cl.parent_order_id                                    as "BrokerAlgoOrderID",
               cl.order_id                                           as "BrokerAlgoSubOrderID",
               cl.exch_order_id                                      as "ExchOrderID",
               cl.exchange_id                                        as "DestinationID",
               ot.order_type_name                                    as "OrderType",
               tif.tif_name                                          as "TimeInForce",
               cl.price                                              as "LimitPrice",
               cl.order_qty                                          as "OrderSize",
--                ex.sum_last_qty                                       as "Filled",
               ex.avg_px                                             as "AverageFillPx",

               par.client_order_id                                   as "ParentOrderID"
        from dwh.client_order cl
            join lateral(select
                             first_value(exec_id)   over (order by exec_id) as first_exec_id,
                             * from dwh.execution ex
                                    where ex.order_id = cl.order_id                                       and exec_date_id >= cl.create_date_id
                ) ex on true

                 inner join dwh.d_account ac on ac.account_id = cl.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
            left join lateral (select *
                                    from dwh.client_order par
                                    where par.order_id = cl.parent_order_id
                                    limit 1) par on true and cl.parent_order_id is not null

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
left join dwh.d_liquidity_indicator li
          on li.exchange_id = exc.real_exchange_id and li.is_active


        where true
          and cl.account_id = any (l_account_ids)
          and cl.create_date_id between in_start_date_id and in_end_date_id
          and cl.trans_type <> 'F'
          and cl.parent_order_id is not null;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' COMPLETED ===', l_row_cnt, 'C')
    into l_step_id;

end;

$function$;
