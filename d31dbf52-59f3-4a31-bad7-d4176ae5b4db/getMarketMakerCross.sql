-- FUNCTION getMarketMakerCross(p_date IN DATE) RETURN REF_CURSOR IS
--   rs REF_CURSOR;
--   BEGIN
--     OPEN rs FOR
--
-- 	select
-- 	  case when cnt > 1
-- 		then rec
-- 		else 'No orders were found to be in violation'
-- 	  end
-- 	from (
-- 		select rec, COUNT(*) OVER() as cnt from (
-- 		select 'Trading Firm,Account,Capacity,Ord Status,Event Date,Event Time,Routed Time,Cl Ord ID,Side,Ord Qty,Ex Qty,Symbol,Expiration Day,Price,Ex Dest,Sub Strategy,Cross Ord Type,Free Text,IsMleg,LegRefID'
-- 		  as rec
-- 		  from dual
-- 		union all
select AC.TRADING_FIRM_ID,                                                      --||','||
       AC.ACCOUNT_NAME,                                                         --||','||
       CF.CUSTOMER_OR_FIRM_NAME,                                                --||','||
       case dfe.ORDER_STATUS
           when '2' then 'Filled'
           when '4' then 'Cancelled'
           when '3' then 'Done For Day'
           else dfe.ORDER_STATUS end,                                           --||','||--ord status
       to_char(CL.CREATE_TIME, 'MM/DD/YYYY'),                                   --||','|| -- Event Date
       TO_CHAR(dfe.EXEC_TIME, 'HH24:MI:SS:FF3'),                                --||','|| --Event Time  - final ER
       TO_CHAR(CL.CREATE_TIME, 'HH24:MI:SS:FF3'),                               --||','||
       CL.CLIENT_ORDER_ID,                                                      --||','||
       case CL.SIDE
           when '1' then 'Buy'
           when '2' then 'Sell'
           when '5' then 'Sell Short'
           when '6' then 'Sell short' end,                                      --||','||
       CL.ORDER_QTY,                                                            --||','||
       (select sum(LAST_QTY)
        from EXECUTION
        where ORDER_ID = CL.ORDER_ID
          and EXEC_TYPE in ('F', 'G')
          and IS_BUSTED = 'N'
          and ex.exec_date_id >= cl.create_date_id),                            --||','||
       I.DISPLAY_INSTRUMENT_ID,                                                 --||','||
       case I.INSTRUMENT_TYPE_ID
           when 'O' then to_char(oc.MATURITY_MONTH, 'FM00') || '/' || to_char(oc.MATURITY_DAY, 'FM00') || '/' ||
                         oc.MATURITY_YEAR end,                                  --||','||
       to_char(CL.PRICE, 'FM999990.0099'),                                      --||','||
       CL.EX_DESTINATION,                                                       --||','||
       CL.sub_strategy_desc,                                                    --||','||
       CO.CROSS_TYPE,                                                           --||','||
       dfe.TEXT_,                                                               --||','||
       case CL.MULTILEG_REPORTING_TYPE when '1' then 'N' when '2' then 'Y' end, --||','||
       CL.CO_CLIENT_LEG_REF_ID
           as rec

-- select cl.*
from dwh.client_order cl
         inner join dwh.cross_order co on (co.cross_order_id = cl.cross_order_id and co.cross_type in ('S', 'P'))
         inner join dwh.d_account ac on (ac.account_id = cl.account_id)
    --counter party
         inner join dwh.client_order cp on co.cross_order_id = cp.cross_order_id and cp.cross_order_id is not null and
                                           cp.is_originator = 'C' and cp.create_date_id <= cl.create_date_id
         inner join dwh.d_account cpa on (cpa.account_id = cp.account_id)
    --
         inner join dwh.d_instrument i on (cl.instrument_id = i.instrument_id)
         left join dwh.d_customer_or_firm cf
                   on cf.customer_or_firm_id = coalesce(cl.customer_or_firm_id, ac.opt_customer_or_firm)
         left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
         join dwh.d_option_series os on oc.option_series_id = os.option_series_id
         left join lateral (select *
                            from dwh.execution dfe
                            where dfe.order_id = cl.order_id
                              and exec_date_id = cl.create_date_id
                              and dfe.exec_date_id between 20231127 and 20231130
                            order by exec_id desc
                            limit 1) dfe on true
-- 		left join execution le on le.exec_id = dfe.last_exec_id

where cl.parent_order_id is null
--  and co.cross_type in ('S', 'P')
  and cl.multileg_reporting_type in ('1', '2')
  and coalesce(cp.customer_or_firm_id, cpa.opt_customer_or_firm) = '4'
  and cl.create_date_id between 20231127 and 20231130
  and cl.cross_order_id is not null
    and cl.client_order_id = '1_1g6231128'




create temp table so_cross_order as
select distinct cl.cross_order_id
from dwh.client_order cl
         inner join dwh.cross_order co on (co.cross_order_id = cl.cross_order_id and co.cross_type in ('S', 'P'))
         inner join dwh.d_account ac on (ac.account_id = cl.account_id)
    --counter party


where cl.parent_order_id is null
--  and co.cross_type in ('S', 'P')
  and cl.multileg_reporting_type in ('1', '2')
--   and coalesce(cp_customer_or_firm_id, cpa_opt_customer_or_firm) = '4'
  and cl.create_date_id between 20231127 and 20231201
  and cl.cross_order_id is not null


    select cp.customer_or_firm_id  as cp_customer_or_firm_id,
           da.opt_customer_or_firm as cpa_opt_customer_or_firm
    from dwh.client_order cp
             join dwh.d_account da using (account_id)
    where cp.cross_order_id in (select cross_order_id from so_cross_order)
      and cp.cross_order_id is not null
      and cp.is_originator = 'C'

----------------------------------------------------------------------------
select * from dash360.get_market_maker_cross(20231127, 20231201)
create or replace function dash360.get_market_maker_cross(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
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
               dfe.text_,
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
                 left join lateral (select text_, order_status, exec_time
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

$fx$
