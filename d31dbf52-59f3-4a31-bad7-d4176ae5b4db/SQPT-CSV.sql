-- DROP FUNCTION dash360.report_fintech_eod_sqpt_slices(int4, int4);


CREATE OR REPLACE FUNCTION dash360.report_fintech_eod_sqpt_slices(in_start_date_id integer, in_end_date_id integer)
--  RETURNS TABLE(date text, "NewAckTime" text, "EndTime" text, "BrokerRootOrderID" bigint, "BrokerAlgoOrderID" bigint, "BrokerAlgoSubOrderID" bigint, "SubOrderID" character varying, "SubOrderVID" character varying, "ExchOrderID" character varying, "DestinationID" character varying, "OrderType" character varying, "TimeInForce" character varying, "LimitPrice" numeric, "OrderSize" integer, "Filled" numeric, "AverageFillPx" numeric, "MIC" character varying, "ParentOrderID" character varying)
    returns table
            (
                ret_row text
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
        select 'Date,NewAckTime,EndTime,BrokerRootOrderID,BrokerAlgoOrderID,BrokerAlgoSubOrderID,SubOrderID,SubOrderVID,ExchOrderID,DestinationID,OrderType,TimeInForce,LimitPrice,OrderSize,Filled,AverageFillPx,MIC,ParentOrderID';

    return query
        select array_to_string(array [
                                   to_char(cl.create_time, 'mm/dd/yyyy'), --               , -- as "Date",
                                   to_char(cl.create_time, 'yyyy-mm-dd"D"hh24:mi:ss.us'), -- as "NewAckTime",
                                   to_char(ex.exec_time, 'yyyy-mm-dd"D"hh24:mi:ss.us') , -- as "EndTime",
                                   cl.parent_order_id::text , -- as "BrokerRootOrderID",
                                   cl.parent_order_id::text , -- as "BrokerAlgoOrderID",
                                   cl.order_id::text , -- as "BrokerAlgoSubOrderID",
                                   cl.client_order_id , -- as "SubOrderID",
                                   null , -- as "SubOrderVID",
                                   cl.exch_order_id , -- as "ExchOrderID",
                                   cl.exchange_id , -- as "DestinationID",
                                   ot.order_type_name , -- as "OrderType",
                                   tif.tif_name , -- as "TimeInForce",
                                   cl.price::text , -- as "LimitPrice",
                                   cl.order_qty::text , -- as "OrderSize",
                                   ex.sum_last_qty::text , -- as "Filled",
                                   ex.avg_px::text , -- as "AverageFillPx",
                                   exc.mic_code , -- as "MIC",
                                   par.client_order_id -- as "ParentOrderID"
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




-- DROP FUNCTION dash360.report_fintech_eod_sqpt_orders(int4, int4);

create or replace function dash360.report_fintech_eod_sqpt_orders(in_start_date_id integer, in_end_date_id integer)
--  RETURNS TABLE(date text, "NewAckTime" text, "EndTime" text, "ParentOrderID" character varying, "BrokerRootOrderID" bigint, "BrokerAlgoOrderID" bigint, "SecurityType" text, "Algo" character varying, "Symbol" character varying, "Strike" numeric, "CallOrPut" text, "Expiration" text, "Side" text, "LegSide" text, "LegRatio" bigint, "LegProductType" text, "Size" integer, "Executed" numeric, "OrderType" character varying, "OrderPrice" numeric, "AverageFillPx" numeric, "Strategy" character varying, "DisplayQty" text)
    returns table
            (
                ret_row text
            )
 language plpgsql
as $function$
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
    select 'Date,NewAckTime,EndTime,ParentOrderID,BrokerRootOrderID,BrokerAlgoOrderID,SecurityType,Algo,Symbol,Strike,CallOrPut,Expiration,Side,LegSide,LegRatio,LegProductType,Size,Executed,OrderType,OrderPrice,AverageFillPx,Strategy,DisplayQty';

    return query
        select array_to_string(array [
                                   to_char(cl.create_time, 'mm/dd/yyyy') , -- as date,
                                   to_char(cl.create_time, 'yyyy-mm-dd"D"hh24:mi:ss.us') , -- as "NewAckTime",
                                   to_char(ex.exec_time, 'yyyy-mm-dd"D"hh24:mi:ss.us') , -- as "EndTime", -- ??
                                   cl.client_order_id , -- as "ParentOrderID",
                                   cl.order_id::text , -- as "BrokerRootOrderID",
                                   cl.order_id::text , -- as "BrokerAlgoOrderID",
                                   case
                                       when i.instrument_type_id = 'E' then 'Equity'
                                       when i.instrument_type_id = 'O' then 'Option'
                                       end , -- as "SecurityType",
                                   target_strategy_name , -- as "Algo",
                                   oc.opra_symbol , -- as "Symbol",
                                   oc.strike_price::text , -- as "Strike",
                                   case
                                       when oc.put_call = '0' then 'P'
                                       when oc.put_call = '1' then 'C'
                                       end , -- as "CallOrPut",
                                   to_char(OC.MATURITY_MONTH, 'FM00') || '/' || to_char(OC.MATURITY_DAY, 'FM00') ||
                                   '/' ||
                                   to_char(OC.MATURITY_YEAR, 'FM0000') , -- as "Expiration",
                                   case
                                       when cl.side = '1' then 'Buy'
                                       when cl.side in ('2', '5', '6') then 'Sell' end , -- as "Side",
                                   case
                                       when cl.side = '1' then 'Buy'
                                       when cl.side in ('2', '5', '6') then 'Sell' end , -- as "LegSide",
                                   cl.ratio_qty::text , -- as "LegRatio",
                                   null , -- as "LegProductType",
                                   cl.order_qty::text , -- as "Size",
                                   ex.sum_last_qty::text , -- as "Executed",
                                   ot.order_type_name , -- as "OrderType",
                                   cl.price::text , -- as "OrderPrice",
                                   ex.avg_px::text , -- as "AverageFillPx",
                                   dts.target_strategy_name , -- as "Strategy",
                                   null -- as "DisplayQty"
                                   ], ',', '')
        from dwh.client_order cl
                 inner join dwh.d_account ac on ac.account_id = cl.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
                 left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
                 left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
                 left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
                 left join dwh.d_target_strategy dts on (dts.target_strategy_id = cl.sub_strategy_id)
                 left join lateral (select sum(last_qty) over ()         as sum_last_qty,
                                           last_value(exec_time) over p  as exec_time,
                                           last_value(avg_px) over p     as avg_px
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

$function$
;


-- DROP FUNCTION dash360.report_fintech_eod_sqpt_fills(int4, int4);


create or replace function dash360.report_fintech_eod_sqpt_fills(in_start_date_id integer, in_end_date_id integer)
--      returns table("date" text, "tradetime" text, "brokerrootorderid" bigint, "suborderid" character varying, "subordervid" character varying, "mic" character varying, "fillqty" bigint, "fillpx" numeric, "execid" bigint, "exchexecid" character varying, "rootexecid" bigint, "nativeliquidityindicator" smallint, "normalizedliquidityindicator" character varying, "fee" numeric, "brokeralgoorderid" bigint, "brokeralgosuborderid" bigint, "parentorderid" character varying)
    returns table
            (
                ret_row text
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
        select 'Date,TradeTime,BrokerRootOrderID,SubOrderID,SubOrderVID,MIC,FillQty,FillPx,ExecID,ExchExecID,RootExecID,NativeLiquidityIndicator,NormalizedLiquidityIndicator,Fee,BrokerAlgoOrderID,BrokerAlgoSubOrderID,ParentOrderID';

    return query
        select array_to_string(array [
                                   to_char(cl.create_time, 'mm/dd/yyyy') , -- as "date",
                                   to_char(ex.exec_time, 'yyyy-mm-dd"D"hh24:mi:ss.us'), -- as "TradeTime",
                                   cl.parent_order_id::text , -- as "BrokerRootOrderID",
                                   cl.client_order_id::text , -- as "SubOrderID",
                                   null , -- as "SubOrderVID",
                                   exc.mic_code , -- as "MIC",
                                   ex.last_qty::text , -- as "FillQty",
                                   ex.last_px::text , -- as "FillPx",
                                   ex.exec_id::text , -- as "ExecID",
                                   ex.exch_exec_id , -- as "ExchExecID",
                                   ex.first_exec_id::text , -- as "RootExecID",
                                   li.liquidity_indicator_type_id::text , -- as "NativeLiquidityIndicator",
--               li.description                                     , -- as "NormalizedLiquidityIndicator",
                                   case
                                       when li.liquidity_indicator_type_id = 1 then 'ADDED'
                                       when li.liquidity_indicator_type_id = 2 then 'REMOVED'
                                       when li.liquidity_indicator_type_id = 3 then 'ROUTED'
                                       when li.liquidity_indicator_type_id = 4 then 'AUCTION'
                                       end , -- as "NormalizedLiquidityIndicator",
                                   null , -- as "Fee",
                                   cl.parent_order_id::text , -- as "BrokerAlgoOrderID",
                                   cl.order_id::text , -- as "BrokerAlgoSubOrderID",
                                   par.client_order_id -- as "ParentOrderID"
                                   ], ',', '')
        from dwh.client_order cl
                 join lateral (select first_value(exec_id) over (order by exec_id) as first_exec_id,
                                      last_qty,
                                      exec_id,
                                      last_px,
                                      exch_exec_id,
                                      exec_time
                               from dwh.execution ex
                               where ex.order_id = cl.order_id
                                 and exec_date_id >= cl.create_date_id
            ) ex on true
                 inner join dwh.d_account ac on ac.account_id = cl.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
                 left join lateral (select client_order_id
                                    from dwh.client_order par
                                    where par.order_id = cl.parent_order_id
                                    limit 1) par on true and cl.parent_order_id is not null
                 left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
                 left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
                 left join dwh.d_target_strategy dts on (dts.target_strategy_id = cl.sub_strategy_id)
                 left join lateral (select real_exchange_id, mic_code
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



select *
from dash360.report_fintech_eod_sqpt_slices(in_start_date_id := 20260601, in_end_date_id := 20260610);
select *
from dash360.report_fintech_eod_sqpt_orders(in_start_date_id := 20260601, in_end_date_id := 20260610);
select *
from dash360.report_fintech_eod_sqpt_fills(in_start_date_id := 20260601, in_end_date_id := 20260611);