

drop function dash360.report_gtc_cancel_request;
create function dash360.report_gtc_cancel_request(in_start_date_id integer default get_dateid(current_date),
                                                  in_end_date_id integer default get_dateid(current_date))
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
-- OS 20240819 https://dashfinancial.atlassian.net/browse/DEVREQ-4695
declare

    l_load_id         int;
    l_step_id         int;
    l_row_cnt         int;
    l_is_current_date bool := false;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_gtc_cancel_request for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    return query
        select 'CreateDate,TradingFirm,Account,ClOrdID,Side,InstrumentType,DisplaySymbol,Symbol,ExpirationDate,CallPut,Strike,OpenQty,Price,TIF';
    return query
        select array_to_string(ARRAY [
                                   to_char(cl.create_time, 'MM/DD/YYYY'), -- "CreateDate", --HH:MI:SS AM
                                   tf.trading_firm_name, -- "TradingFirm",
                                   ac.account_name, -- "Account",
                                   cl.client_order_id, -- "ClOrdID",
                                   case
                                       when cl.side = '1' then 'BUY'
                                       when cl.side in ('2', '5', '6') then 'SELL'
                                       end, -- "Side",
                                   case when di.instrument_type_id = 'E' then 'Equity' else 'Option' end, -- "InstrumentType",
                                   di.display_instrument_id, -- "DisplaySymbol",
                                   di.symbol, -- "Symbol",
                                   lpad(oc.maturity_month::text, 2, '0') || '/' ||
                                   lpad(oc.maturity_day::text, 2, '0') || '/' ||
                                   oc.maturity_year::text, -- "ExpirationDate",
                                   case oc.put_call when '0' then 'P' when '1' then 'C' end, -- "CallPut",
                                   oc.strike_price::text, -- "Strike",
                                   ex.leaves_qty::text, -- "OpenQty",
                                   cl.price::text, -- "Price",
                                   tif.tif_short_name -- "TIF"
                                   ], ',', '')
        from dwh.gtc_order_status gtc
                 join dwh.client_order cl
                      on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id --and cl.parent_order_id is null
                 join dwh.d_account ac on gtc.account_id = ac.account_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
                 inner join dwh.d_trading_firm tf on (tf.trading_firm_id = ac.trading_firm_id)
                 inner join lateral (select ex.leaves_qty
                                     from dwh.execution ex
                                     where ex.order_id = gtc.order_id
                                       and ex.order_status in ('0', '1')
                                       and ex.exec_type = 'y'
                                       and ex.exec_date_id >= gtc.create_date_id
                                       and ex.exec_date_id >= in_start_date_id
                                       and ex.exec_date_id <= in_end_date_id
                                     order by exec_id desc
                                     limit 1) ex on true
                 left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id and oc.is_active)
                 left join dwh.d_time_in_force tif on (tif.tif_id = cl.time_in_force_id)
        where cl.parent_order_id is null
          and cl.trans_type in ('D', 'G')
          and gtc.time_in_force_id in ('1', '6')
          and cl.multileg_reporting_type in ('1', '2')
          and gtc.create_date_id <= in_start_date_id
          and (gtc.close_date_id is null
            or (case
                    when l_is_current_date then false
                    else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
          and not exists (select null
                          from dwh.execution ex
                          where ex.order_id = cl.order_id
                            and ex.exec_date_id >= in_start_date_id
                            and ex.exec_date_id <= in_end_date_id
                            and ex.order_status in ('2', '4', '8')
                            and (ex.text_ <> 'Instrument expiration' or ex.text_ is null))
        order by gtc.create_date_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_gtc_cancel_request for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;


select * from dash360.report_gtc_ofp0031_open_order(20240801, 20240820)

drop function dash360.report_gtc_ofp0031_open_order;
create function dash360.report_gtc_ofp0031_open_order(in_start_date_id integer default get_dateid(current_date),
                                                      in_end_date_id integer default get_dateid(current_date))
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
-- OS 20240820 https://dashfinancial.atlassian.net/browse/DEVREQ-4698
declare

    l_load_id         int;
    l_step_id         int;
    l_row_cnt         int;
    l_is_current_date bool := false;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_gtc_ofp0031_open_order for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    return query
        select 'Record Number,OrderId,ClOrdId,OrderQty,LeavesQty,Security Type,Symbol,MaturityMonthYear,Option Strike Price,Call/Put,OrdType,Price,StopPx,ExecInst,Open/Close';

    return query
        select array_to_string(ARRAY [
                                   (row_number() over (order by cl.create_time))::text, -- "Record Number",
                                   cl.order_id::text, -- "OrderId",
                                   cl.client_order_id, -- "ClOrdId",
                                   case
                                       when cl.side = '1' then 'B'
                                       when cl.side in ('2', '5', '6') then 'S'
                                       end, -- "Order Side",
                                   cl.order_qty::text, -- "OrderQty",
                                   ex.leaves_qty::text, -- "LeavesQty",
                                   case
                                       when di.instrument_type_id = 'E' then 'E'
                                       when di.instrument_type_id = 'O' then 'O'
                                       end, -- "Security Type",
                                   di.symbol, -- "Symbol",
                                   lpad(oc.maturity_year::text, 4, '0') || lpad(oc.maturity_month::text, 2, '0'), -- "MaturityMonthYear",
                                   oc.strike_price::text, -- "Option Strike Price",
                                   case
                                       when oc.put_call = '0' then 'P'
                                       when oc.put_call = '1' then 'C'
                                       else ' ' end, -- "Call/Put",
                                   ot.order_type_short_name, -- "OrdType",
                                   cl.price::text, -- "Price",
                                   cl.stop_price::text, -- "StopPx",
                                   cl.exec_instruction, -- "ExecInst",
                                   cl.open_close -- "Open/Close"
                                   ], ',', '')
        from dwh.gtc_order_status gtc
                 join dwh.client_order cl
                      on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id --and cl.parent_order_id is null
                 join dwh.d_account ac on gtc.account_id = ac.account_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
                 left join dwh.d_order_type ot on (ot.order_type_id = cl.order_type_id)
                 inner join dwh.d_trading_firm tf on (tf.trading_firm_id = ac.trading_firm_id)
                 inner join lateral (select ex.leaves_qty
                                     from dwh.execution ex
                                     where ex.order_id = gtc.order_id
                                       and ex.order_status <> '3'
                                       and ex.exec_date_id >= gtc.create_date_id
                                       and ex.exec_date_id >= in_start_date_id
                                       and ex.exec_date_id <= in_end_date_id
                                     order by exec_id desc
                                     limit 1) ex on true
                 left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id and oc.is_active)
                 left join dwh.d_time_in_force tif on (tif.tif_id = cl.time_in_force_id)
        where cl.parent_order_id is null
--           and ac.trading_firm_id = 'OFP0031'
          and cl.trans_type in ('D', 'G')
          and gtc.time_in_force_id in ('1', '6')
          and cl.multileg_reporting_type in ('1', '2')
          and gtc.create_date_id <= in_start_date_id
          and (gtc.close_date_id is null
            or (case
                    when l_is_current_date then false
                    else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
          and not exists (select null
                          from dwh.execution ex
                          where ex.order_id = cl.order_id
                            and ex.exec_date_id >= in_start_date_id
                            and ex.exec_date_id <= in_end_date_id
                            and ex.order_status in ('2', '4', '8')
                            and (ex.text_ <> 'Instrument expiration' or ex.text_ is null));


    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_gtc_ofp0031_open_order for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$fx$;

select to_char(123356789, 'FM9999999999')