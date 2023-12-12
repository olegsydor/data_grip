create or replace function dash360.report_rps_wellsfarg_sweepx(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$

declare
--     l_date_id int4 := to_char(in_date, 'YYYYMMDD')::int4;
    l_account_ids int4[] := (select array_agg(account_id) from dwh.d_account where trading_firm_id = 'wellsfarg');

begin
    return query
        select 'Trade Date,Account,Routed Time,Cl Ord ID,Symbol,Expiration Day,Security Type,Ex Destination,Sub Strategy,Orig Side,Cross Limit Px,Cross Ord Qty,Cross Ord Type,Arrival BBO Qty,Arrival BBO Px,Sweep Ex Qty,Last Mkt';

    return query
        select to_char(cl.create_time, 'MM/DD/YYYY') || ',' ||
               ac.account_name || ',' ||
               to_char(str.process_time, 'HH24:MI:SS') || ',' ||
               cl.client_order_id || ',' ||
               i.display_instrument_id || ',' ||
               case
                   when i.instrument_type_id = 'O'
                       then concat_ws('/', oc.maturity_month::text, oc.maturity_day::text, substr(oc.maturity_year::text, 3))
                   else ''
                   end || ',' ||
               case i.instrument_type_id when 'O' then 'Option' else 'Equity' end || ',' ||
               exc.ex_destination_code_name || ',' ||
               cl.sub_strategy_desc || ',' ||
               case cl.side when '2' then 'Sell' when '5' then 'Sell Short' when '6' then 'Sell Short' else 'Buy' end || ',' ||
               to_char(cl.price, 'FM9999990.0000') || ',' ||
               cl.order_qty || ',' ||
               cro.cross_type || ',' ||
               str.order_qty || ',' ||
               to_char(str.price, 'FM9999990.0000') || ',' ||
               ex.last_qty::text || ',' ||
               exch.mic_code
        from dwh.client_order cl
                 inner join dwh.client_order str on (cl.order_id = str.parent_order_id)
                 inner join dwh.cross_order cro on (cro.cross_order_id = cl.cross_order_id)
                 inner join dwh.d_account ac on cl.account_id = ac.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                 inner join dwh.d_ex_destination_code exc on (exc.ex_destination_code = cl.ex_destination)
                 inner join dwh.d_exchange exch on (exch.exchange_id = str.exchange_id and exch.is_active)
--
                 left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 left join lateral (select coalesce(sum(last_qty), 0) as last_qty
                                    from execution ex
                                    where ex.order_id = str.order_id
                                      and ex.exec_type = 'f'
                                      and ex.exec_date_id >= str.create_date_id
                                    limit 1) ex on true
        where cl.parent_order_id is null
          and cl.multileg_reporting_type <> '3'
          and cl.create_date_id between in_start_date_id and in_end_date_id
          and cl.sub_strategy_desc = 'SWEEPX'
          and str.strtg_decision_reason_code = '77'
          and cl.account_id = any(l_account_ids);
end;

$function$
;

select * from dash360.report_rps_wellsfarg_sweepx(in_start_date_id := 20230323, in_end_date_id := 20230331)

select * from dwh.client_order cl
         inner join dwh.client_order str on (cl.order_id = str.parent_order_id)
where cl.parent_order_id is null
          and cl.multileg_reporting_type <> '3'
          and cl.create_date_id between :in_start_date_id and :in_end_date_id
          and cl.sub_strategy_desc = 'SWEEPX'
          and str.strtg_decision_reason_code = '77'
          and cl.account_id = any('{28549,20505,19993,38549,30213,64810,64809,12410,64808,12909}')