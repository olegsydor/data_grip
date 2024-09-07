update trash.so_fix_execution_column_text_
set new_script = $insert$
CREATE OR REPLACE FUNCTION dash360.get_market_maker_cross(in_start_date_id integer, in_end_date_id integer)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
begin
    create temp table t_cross_order on commit drop as
    select distinct cl.cross_order_id
    from dwh.client_order cl
             inner join dwh.cross_order co
                        on (co.cross_order_id = cl.cross_order_id and co.cross_type in ('S', 'P'))
    where cl.parent_order_id is null
      and cl.multileg_reporting_type in ('1', '2')
      and cl.create_date_id between in_start_date_id and in_end_date_id
      and cl.cross_order_id is not null;

    return query
        select 'Trading Firm,Account,Capacity,Ord Status,Event Date,Event Time,Routed Time,Cl Ord ID,Side,Ord Qty,Ex Qty,Symbol,Expiration Day,Price,Ex Dest,Sub Strategy,Cross Ord Type,Free Text,IsMleg,LegRefID';

    return query
        select array_to_string(ARRAY [ac.trading_firm_id,
               ac.account_name,
               cf.customer_or_firm_name,
               case dfe.order_status
                   when '2' then 'Filled'
                   when '4' then 'Cancelled'
                   when '3' then 'Done For Day'
                   else dfe.ORDER_STATUS end,
               to_char(cl.create_time, 'MM/DD/YYYY'),
               to_char(dfe.exec_time, 'HH24:MI:SS:FF3'),
               to_char(cl.create_time, 'HH24:MI:SS:FF3'),
               cl.client_order_id,
               case cl.side
                   when '1' then 'Buy'
                   when '2' then 'Sell'
                   when '5' then 'Sell Short'
                   when '6' then 'Sell short' end,
               cl.order_qty::text,
               (select sum(last_qty)::text
                from execution
                where order_id = cl.order_id
                  and exec_type in ('F', 'G')
                  and is_busted = 'N'
                  and exec_date_id >= cl.create_date_id),
               i.display_instrument_id,
               case i.instrument_type_id
                   when 'O' then to_char(oc.maturity_month, 'FM00') || '/' || to_char(oc.maturity_day, 'FM00') || '/' ||
                                 oc.maturity_year end,
               to_char(CL.PRICE, 'FM999990.0099'),
               cl.ex_destination,
               cl.sub_strategy_desc,
               co.cross_type,
               dfe.exec_text,
               case cl.multileg_reporting_type when '1' then 'N' when '2' then 'Y' end,
               cl.co_client_leg_ref_id
], ',', '')
-- select cl.*
        from dwh.client_order cl
                 inner join dwh.cross_order co
                            on (co.cross_order_id = cl.cross_order_id and co.cross_type in ('S', 'P'))
                 inner join dwh.d_account ac on (ac.account_id = cl.account_id)
            --counter party
                 inner join dwh.client_order cp
                            on (co.cross_order_id = cp.cross_order_id and cp.cross_order_id is not null and
                                cp.is_originator = 'C' and cp.create_date_id <= cl.create_date_id
                                and cp.cross_order_id in (select cross_order_id from t_cross_order))
                 inner join dwh.d_account cpa on (cpa.account_id = cp.account_id)
            --
                 inner join dwh.d_instrument i on (cl.instrument_id = i.instrument_id)
                 left join dwh.d_customer_or_firm cf
                           on cf.customer_or_firm_id = coalesce(cl.customer_or_firm_id, ac.opt_customer_or_firm)
                 left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
                 join dwh.d_option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select exec_text, order_status, exec_time
                                    from dwh.execution dfe
                                    where dfe.order_id = cl.order_id
                                      and exec_date_id = cl.create_date_id
                                      and dfe.exec_date_id between in_start_date_id and in_end_date_id
                                    order by exec_id desc
                                    limit 1) dfe on true
        where cl.parent_order_id is null
--  and co.cross_type in ('S', 'P')
          and cl.multileg_reporting_type in ('1', '2')
          and coalesce(cp.customer_or_firm_id, cpa.opt_customer_or_firm) = '4'
          and cl.create_date_id between in_start_date_id and in_end_date_id
          and cl.cross_order_id is not null;
end;

$function$
;
$insert$
where true
and routine_schema = 'dash360'
  and routine_name = 'get_parent_orders_trade_activity'
and new_script is null;