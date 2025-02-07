select * from dwh.d_account
where account_name = 'RBCSTP';

 dash360.report_compliance_order_blotter_reg_v2
create or replace function dash360.report_compliance_order_blotter_reg_v2(in_start_date_id integer default public.get_dateid(current_date),
                                                                          in_end_date_id integer default public.get_dateid(current_date),
                                                                          in_row_type text default null::text,
                                                                          in_instrument_type character default null::bpchar,
                                                                          in_account_ids integer[] default '{}'::integer[],
                                                                          in_client_order_ids character varying[] default '{}'::character varying[],
                                                                          in_order_ids bigint[] default '{}'::bigint[],
                                                                          in_symbols character varying[] default '{}'::character varying[])
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$function$
    -- 2024-08-15 OS https://dashfinancial.atlassian.net/browse/DEVREQ-4712
-- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
-- 2024-11-07 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5105 changing source from FYC to client_order
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_compliance_order_blotter_reg for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;


    return query
        select 'Parent Cl Ord ID,Row Type,Account,Creation Date,Event Date,Creation Time,Routed Time,Event Time,Order Status,Cl Ord ID,Orig Cl Ord ID,Side,Ord Qty,Ex Qty,Lvs Qty,Symbol,Expiration Day,Price,Avg Px,TIF,Ord Type,O/C,Security Type,Root Symbol,Client ID,Capacity,Sub Strategy,Ex Dest,Sending Firm,Event Type,Free Text,Reject Reason,Max Floor,Exec Broker,CMTA,Is Mleg,Is Cross,ATS Auction ID,Cross Ord Type,Fee Sensitivity,Handle Inst,Locate Broker,Leg ID,MPID,OCC Opt Data,Ord Capacity,OSI Symbol,Sub System,Session Eligibility,Sweep Style,Trading Firm';
    return query
        with order_ids_cte as (select co.create_date_id,
                                      co.order_id,
                                      di.instrument_type_id,
                                      di.display_instrument_id,
                                      po.multileg_reporting_type,
                                      po.time_in_force_id
                               from dwh.client_order po
                                        join dwh.client_order co on (co.create_date_id = po.create_date_id and
                                                                     (co.order_id = po.order_id or co.parent_order_id = po.order_id))
                                        join dwh.d_instrument di on di.instrument_id = po.instrument_id
                               where po.create_date_id between :in_start_date_id and :in_end_date_id
                                 and po.multileg_reporting_type in ('1', '2')
                                 and case
                                         when in_row_type is null then true
                                         when in_row_type = 'Parent' then co.parent_order_id is null
                                         when in_row_type = 'Child' then co.parent_order_id is not null
                                   end
                                 and case
                                         when in_instrument_type is null then true
                                         else di.instrument_type_id = in_instrument_type end
                                 and case
                                         when coalesce(in_account_ids, '{}') = '{}' then true
                                         else co.account_id = any (in_account_ids) end
                                 and case
                                         when coalesce(in_client_order_ids, '{}') = '{}' then true
                                         else po.client_order_id = any (in_client_order_ids) end
                                 and case
                                         when coalesce(in_symbols, '{}') = '{}' then true
                                         else di.symbol = any (in_symbols) end
                               and po.client_order_id in ('0180000122', '0180000123')
                               )
        select array_to_string(ARRAY [
--        co.order_id,
                                   coalesce(pyc.client_order_id, co.client_order_id) , -- as "Parent Cl Ord ID",
                                   case when co.parent_order_id is null then 'Parent' else 'Child' end , -- as "Row Type",
                                   a.account_name , -- as "Account",
                                   to_char(co.create_time, 'MM/DD/YYYY') , -- as "Creation Date",
                                   to_char(co.process_time, 'MM/DD/YYYY') , -- as "Event Date",
                                   to_char(co.create_time, 'HH24:MI:SS.US') , -- as "Creation Time",
                                   to_char(co.process_time, 'HH24:MI:SS.US') , -- as "Routed Time",
                                   to_char(lst_ex.exec_time, 'HH24:MI:SS.US') , -- as "Event Time",
                                   lst_ex.order_status_description , -- as "Order Status",
                                   co.client_order_id , -- as "Cl Ord ID",
                                   orig.client_order_id , -- as "Orig Cl Ord ID",
                                   case
                                       when co.side = '1' then 'Buy'
                                       when co.side in ('2', '5', '6') then 'Sell'
                                       else ''
                                       end , -- as "Side",
                                   co.order_qty::text , -- as "Ord Qty",
                                   coalesce(ftr.day_cum_qty, ftr_par.day_cum_qty, 0)::text , -- as "Ex Qty",
                                   coalesce(ftr.leaves_qty, ftr_par.leaves_qty)::text , -- as "Lvs Qty",
                                   hsd.display_instrument_id , -- as "Symbol",
                                   to_char(hsd.maturity_date, 'MM/DD/YYYY') , -- as "Expiration Day",
                                   round(co.price, 6)::text , -- as "Price",
                                   round(coalesce(ftr.avg_px, ftr_par.avg_px), 6)::text , -- as "Avg Px",
                                   tif.tif_name , -- as "TIF",
                                   ot.order_type_name , -- as "Ord Type",
                                   case
                                       when co.open_close = 'O' then 'Open'
                                       when co.open_close = 'C' then 'Close'
                                       else '' end , -- as "O/C",
                                   case
                                       when hsd.instrument_type_id = 'E' then 'Equity'
                                       when hsd.instrument_type_id = 'O' then 'Option'
                                       end , -- as "Security Type",
                                   hsd.underlying_symbol , -- as "Root Symbol",
                                   co.client_id_text , -- as "Client ID",
                                   cf.customer_or_firm_name , -- as "Capacity",
                                   dss.sub_strategy , -- as "Sub Strategy",
                                   coalesce(exd.ex_destination_desc, co.ex_destination) , -- as "Ex Dest",
                                   fc.fix_comp_id , -- as "Sending Firm",
                                   lst_ex.exec_type_description , -- as "Event Type",
                                   lst_ex.exec_text , -- as "Free Text",
                                   null::text , -- as "Reject Reason",
                                   co.max_floor::text , -- as "Max Floor",
                                   lst_ex.exec_broker , -- as "Exec Broker",
                                   co.clearing_firm_id , -- as "CMTA",
                                   case when oic.multileg_reporting_type = '1' then 'N' else 'Y' end , -- as "Is Mleg",
                                   case when co.cross_order_id is not null then 'Y' else 'N' end , -- as "Is Cross",
                                   coa.auction_id::text , -- as "ATS Auction ID", -- ??
                                   case
                                       when cro.cross_type = 'C' then 'Customer Match'
                                       when cro.cross_type in ('F', '2') then 'Facilitation'
                                       when cro.cross_type in ('P', '4') then 'Price Improvement Mechanism'
                                       when cro.cross_type = 'S' then 'Solicitation'
                                       when cro.cross_type = 'Q' then 'Qualified Contingent Cross'
                                       when cro.cross_type = '1' then 'Solicitation or Customer Match Order'
                                       else cro.cross_type
                                       end , -- as "Cross Ord Type",
                                   co.fee_sensitivity::text , -- as "Fee Sensitivity",
                                   co.handl_inst::varchar , -- as "Handle Inst",
                                   co.locate_broker , -- as "Locate Broker",
                                   co.co_client_leg_ref_id , -- as "Leg ID",
                                   a.broker_dealer_mpid , -- as "MPID",           --??
                                   co.occ_optional_data , -- as "OCC Opt Data",   --fix_message->>'10441'
                                   doc.order_capacity_name , -- as "Ord Capacity",
                                   hsd.opra_symbol , -- as "OSI Symbol",
                                   ds.sub_system_id , -- as "Sub System",
                                   co.session_eligibility::varchar , -- as "Session Eligibility",
                                   co.sweep_style::varchar , -- as "Sweep Style",

                                   tf.trading_firm_name -- as "Trading Firm"
                                   ], ',', '')
        from order_ids_cte oic
                 --                  join data_marts.f_yield_capture yc
--                       on (yc.status_date_id between in_start_date_id and in_end_date_id and
--                           yc.status_date_id = oic.create_date_id and yc.order_id = oic.order_id)
--                  left join data_marts.f_yield_capture pyc
--                            on (pyc.status_date_id between in_start_date_id and in_end_date_id and
--                                pyc.status_date_id = yc.status_date_id and pyc.order_id = yc.parent_order_id)

                 join dwh.client_order co on
            co.create_date_id = oic.create_date_id and co.order_id = oic.order_id and
            co.create_date_id between :in_start_date_id and :in_end_date_id
                 left join dwh.client_order pyc on
            pyc.create_date_id between :in_start_date_id and :in_end_date_id and
            pyc.create_date_id = co.create_date_id and pyc.order_id = co.parent_order_id
                 join dwh.d_account a on (a.account_id = co.account_id)
            --                  join dwh.client_order co on (co.create_date_id between in_start_date_id and in_end_date_id and
--                                               co.create_date_id = yc.status_date_id and co.order_id = yc.order_id)
                 left join lateral (select orig.client_order_id
                                    from dwh.client_order orig
                                    where orig.create_date_id between in_start_date_id and in_end_date_id
                                      and orig.create_date_id = co.create_date_id
                                      and orig.order_id = co.orig_order_id
                                    limit 1) orig on true
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = oic.time_in_force_id
                 left join dwh.d_order_type ot on ot.order_type_id = co.order_type_id
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = co.instrument_id)
                 left join data_marts.d_sub_strategy dss on co.sub_strategy_id = dss.sub_strategy_id
                 left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                        coalesce(exd.exchange_id, '') =
                                                        coalesce(co.exchange_id, '') and
                                                        exd.instrument_type_id =
                                                        oic.instrument_type_id and
                                                        exd.is_active)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
                 left join dwh.d_exchange ex on (ex.exchange_unq_id = co.exchange_unq_id)
                 left join lateral
            (
            select os.order_status_description,
                   ex.exec_text,
                   ex.fix_message_id,
                   exec_type_description,
                   exec_broker,
                   exec_time,
                   avg_px,
                   cum_qty
            from dwh.execution ex
                     left join dwh.d_order_status os on (os.order_status = ex.order_status and os.is_active)
                     left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
            where ex.order_id = co.order_id
              and ex.exec_date_id between in_start_date_id and in_end_date_id
              and ex.exec_date_id = co.create_date_id
              and ex.order_status <> '3'
            order by ex.exec_id desc
            limit 1
            ) lst_ex on true
                 left join lateral (
            select sum(last_qty)       as                                         day_cum_qty,
                   sum(ftr.last_qty * ftr.last_px) / nullif(sum(ftr.last_qty), 0) avg_px,
                   min(ftr.leaves_qty) as                                         leaves_qty
            from flat_trade_record ftr
            where true
              and ftr.date_id = co.create_date_id
              and ftr.date_id between in_start_date_id and in_end_date_id
              and ftr.street_order_id = co.order_id
              and ftr.is_busted = 'N'
              and co.parent_order_id is not null
            ) ftr on true
                 left join lateral (
            select sum(last_qty)       as                                         day_cum_qty,
                   sum(ftr.last_qty * ftr.last_px) / nullif(sum(ftr.last_qty), 0) avg_px,
                   min(ftr.leaves_qty) as                                         leaves_qty
            from flat_trade_record ftr
            where true
              and ftr.date_id = co.create_date_id
              and ftr.date_id between in_start_date_id and in_end_date_id
              and ftr.order_id = co.order_id
              and ftr.is_busted = 'N'
              and co.parent_order_id is null
            ) ftr_par on true
                 left join dwh.d_fix_connection fc on
            fc.fix_connection_id = co.fix_connection_id --and fc.is_active
                 left join dwh.client_order2auction coa
                           on coa.create_date_id between in_start_date_id and in_end_date_id and
                              coa.create_date_id = co.create_date_id and coa.order_id = co.order_id
                 left join dwh.d_order_capacity doc on doc.order_capacity_id = co.eq_order_capacity
                 left join dwh.d_sub_system ds on
            ds.sub_system_unq_id = co.sub_system_unq_id --and ds.is_active
                 left join dwh.cross_order cro on
            cro.cross_order_id = co.cross_order_id and co.cross_order_id is not null
        where co.create_date_id between in_start_date_id and in_end_date_id
          and co.multileg_reporting_type in ('1', '2')
        and co.trans_type <>'F'
        order by co.create_date_id, coalesce(co.parent_order_id, co.order_id), co.order_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_compliance_order_blotter_reg for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;


select *
into temp table t3
from dash360.report_compliance_order_blotter_reg_v2(in_start_date_id := 20230131, in_end_date_id := 20230131,
                                                    in_client_order_ids := '{"0180000043"}');
with b as (select *
           from t3
           except
           select *
           from t1)
select distinct * from b;


select *
into temp table t01
from dash360.report_compliance_order_blotter_reg_v2(in_account_ids := '{63030}', in_start_date_id := 20230103, in_end_date_id := 20230103,
                                                    in_client_order_ids := '{"0180000017"}');

select * from t01


select *
into temp table t_os
from dash360.report_compliance_order_blotter_reg(in_start_date_id := 20230103, in_end_date_id := 20230103,
                                                          in_client_order_ids := '{"0180000122", "0180000123"}');

select * from t_os


select cl.trading_firm_id, ac.trading_firm_id, tf.trading_firm_id, * from dwh.client_order cl
join dwh.d_account ac on ac.account_id = cl.account_id
join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
where create_date_id = 20250206;


select * from dash_reporting.imc_base
         join dwh.gtc_order_status gtc on gtc.order_id = imc_base.order_id
where order_daily = 'G'
and (gtc.close_date_id is null
or gtc.close_date_id >= 2025026)

select current_date - '2024-04-03';

select * from dwh.gtc_order_status gtc
where true
and (gtc.close_date_id is null
or gtc.close_date_id >= 20250206);

select min(cl.create_date_id)
into l_retention_date_id
from dwh.client_order cl
         join dwh.gtc_order_status gtc on gtc.order_id = cl.order_id and gtc.create_date_id = cl.create_date_id
         inner join dwh.d_fix_connection fc
                    on (fc.fix_connection_id = cl.fix_connection_id and fc.fix_comp_id <> 'IMCCONS')
         inner join lateral (select 1
                             from dwh.d_trading_firm tf
                             where tf.trading_firm_id = cl.trading_firm_id
                               and tf.is_eligible4consolidator = 'Y'
                             limit 1) tf on true
where true
    and gtc.close_date_id is null
   or gtc.close_date_id >= in_date_id;


call trash.imc_report_making(20250206)