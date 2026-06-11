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
           coalesce(par.client_order_id, cl.client_order_id)                                  as "ParentOrderID",
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


/*
 date	30-03-26	order_create_time
NewAckTime	2026-03-30T17:43:48.921	order_create_time	When the slice was acknowledged/ sent
EndTime	2026-03-30T17:43:50.193	exec_time or order_cancel_time	Timestamp when each slice completed/ended : Last exec time if fully executed, otherwise cancellation time
BrokerRootOrderID	8I_tLGwKQWOxLbJ2eR9qKQA	parent order_id	Same as parent
BrokerAlgoOrderID	zYoKJTcZLAnyyURoEw4IrgA	parent order_id	Same as parent
BrokerAlgoSubOrderID	ZkRcecHpnCmVgW-1q7PVxAA	street order_id	Unique ID for by slice
SubOrderID	XSORCHCaDeFWDAAAAB-6SAA	child client_order_id	Child Cl Ord ID (unique by slice)
SubOrderVID	2	null	Sub-order Version ID - needed for replaces
ExchOrderID	4508002086551929	exch_order_id
DestinationID	ARCX	exchange_id
OrderType	Limit	order_type_name
TimeInForce	Day	tif_name
LimitPrice	9.06	price
OrderSize	1	order_qty
Filled	1	sum(last_qty)
AverageFillPx	9.06	avg_px
MIC	ARCO	exchange mic_code
ParentOrderID	CFOA20TCPR41002I81:1	parent client_order_id

 */
select exc from dwh.client_order;
select * from dwh.d_time_in_force

CREATE or replace FUNCTION dash360.report_fintech_eod_sqpt_slices(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                "date"              text,
                "NewAckTime"        text,
                "EndTime"           text,
                "ParentOrderID"     varchar(256),
                "BrokerRootOrderID" int8,
                "BrokerAlgoOrderID" int8,
                "BrokerAlgoSubOrderID" int8,
                "SubOrderID"      varchar(256),
                "SubOrderVID"      varchar(256),
                "ExchOrderID" varchar,
                "DestinationID" varchar,
                "OrderType"         varchar(255),
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
           coalesce(par.client_order_id, cl.client_order_id)                                  as "ParentOrderID",
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

$function$;
