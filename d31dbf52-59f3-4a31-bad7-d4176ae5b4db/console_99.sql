-- old version
create temp table t_old as
with order_ids_cte as (select co.create_date_id, co.order_id
                       from dwh.client_order po
                                join dwh.client_order co on (co.create_date_id = po.create_date_id and
                                                             (co.order_id = po.order_id or co.parent_order_id = po.order_id))
                                join dwh.historic_security_definition_all hsd
                                     on (hsd.instrument_id = po.instrument_id)
                       where po.create_date_id between :in_start_date_id and :in_end_date_id
                         and po.multileg_reporting_type in ('1', '2')
                         and case
                                 when :in_row_type is null then true
                                 when :in_row_type = 'Parent' then co.parent_order_id is null
                                 when :in_row_type = 'Child' then co.parent_order_id is not null
                           end
                         and case
                                 when :in_instrument_type is null then true
                                 else hsd.instrument_type_id = :in_instrument_type end
                         and case
                                 when coalesce(:in_account_ids, '{}') = '{}' then true
                                 else co.account_id = any (:in_account_ids) end
                         and case
                                 when coalesce(:in_client_order_ids, '{}') = '{}' then true
                                 else po.client_order_id = any (:in_client_order_ids) end
                         and case
                                 when coalesce(:in_symbols, '{}') = '{}' then true
                                 else hsd.symbol = any (:in_symbols) end)
select --array_to_string(ARRAY [
       oic.order_id,
       coalesce(pyc.client_order_id, yc.client_order_id)                   as "Parent Cl Ord ID",
       case when yc.parent_order_id is null then 'Parent' else 'Child' end as "Row Type",
       a.account_name                                                      as "Account",
       to_char(co.create_time, 'MM/DD/YYYY')                               as "Creation Date",
       to_char(yc.routed_time, 'MM/DD/YYYY')                               as "Event Date",
       to_char(co.create_time, 'HH24:MI:SS.US')                            as "Creation Time",
       to_char(yc.routed_time, 'HH24:MI:SS.US')                            as "Routed Time",
       to_char(yc.exec_time, 'HH24:MI:SS.US')                              as "Event Time",
       lst_ex.order_status_description                                     as "Order Status",
       yc.client_order_id                                                  as "Cl Ord ID",
       orig.client_order_id                                                as "Orig Cl Ord ID",
       case
           when yc.side = '1' then 'Buy'
           when yc.side in ('2', '5', '6') then 'Sell'
           else ''
           end                                                             as "Side",
       yc.order_qty::text                                                  as "Ord Qty",
       yc.day_cum_qty::text                                                as "Ex Qty",
       yc.day_leaves_qty::text                                             as "Lvs Qty",
       hsd.display_instrument_id                                           as "Symbol",
       to_char(hsd.maturity_date, 'MM/DD/YYYY')                            as "Expiration Day",
       round(yc.order_price, 6)::text                                      as "Price",
       round(yc.avg_px, 6)::text                                           as "Avg Px",
       tif.tif_name                                                        as "TIF",
       ot.order_type_name                                                  as "Ord Type",
       case
           when co.open_close = 'O' then 'Open'
           when co.open_close = 'C' then 'Close'
           else '' end                                                     as "O/C",
       case
           when hsd.instrument_type_id = 'E' then 'Equity'
           when hsd.instrument_type_id = 'O' then 'Option'
           end                                                             as "Security Type",
       hsd.underlying_symbol                                               as "Root Symbol",
       yc.client_id                                                        as "Client ID",
       cf.customer_or_firm_name                                            as "Capacity",
       dss.sub_strategy                                                    as "Sub Strategy",
       coalesce(exd.ex_destination_desc, co.ex_destination)                as "Ex Dest",
       fc.fix_comp_id                                                      as "Sending Firm",
       lst_ex.exec_type_description                                        as "Event Type",
       lst_ex.exec_text                                                    as "Free Text",
       null::text                                                          as "Reject Reason",
       co.max_floor::text                                                  as "Max Floor",
       lst_ex.exec_broker                                                  as "Exec Broker",
       co.clearing_firm_id                                                 as "CMTA",
       case when yc.multileg_reporting_type = '1' then 'N' else 'Y' end    as "Is Mleg",
       case when yc.cross_order_id is not null then 'Y' else 'N' end       as "Is Cross",
       coa.auction_id::text                                                as "ATS Auction ID", -- ??
       case
           when cro.cross_type = 'C' then 'Customer Match'
           when cro.cross_type in ('F', '2') then 'Facilitation'
           when cro.cross_type in ('P', '4') then 'Price Improvement Mechanism'
           when cro.cross_type = 'S' then 'Solicitation'
           when cro.cross_type = 'Q' then 'Qualified Contingent Cross'
           when cro.cross_type = '1' then 'Solicitation or Customer Match Order'
           else cro.cross_type
           end                                                             as "Cross Ord Type",
       co.fee_sensitivity::text                                            as "Fee Sensitivity",
       --coalesce(fm_ex.tag_21, fm_co.tag_21)                                ,as  "Handle Inst",
       co.handl_inst::varchar                                              as "Handle Inst",
       co.locate_broker                                                    as "Locate Broker",
       co.co_client_leg_ref_id                                             as "Leg ID",
       a.broker_dealer_mpid                                                as "MPID",           --??
       co.occ_optional_data                                                as "OCC Opt Data",   --fix_message->>'10441'
       doc.order_capacity_name                                             as "Ord Capacity",
       hsd.opra_symbol                                                     as "OSI Symbol",
       ds.sub_system_id                                                    as "Sub System",
       co.session_eligibility::varchar                                     as "Session Eligibility",
       co.sweep_style::varchar                                             as "Sweep Style",
       tf.trading_firm_name                                                as "Trading Firm"
--                                     ], ',', '')
from order_ids_cte oic
         join data_marts.f_yield_capture yc
              on (yc.status_date_id between :in_start_date_id and :in_end_date_id and
                  yc.status_date_id = oic.create_date_id and yc.order_id = oic.order_id)
         left join data_marts.f_yield_capture pyc
                   on (pyc.status_date_id between :in_start_date_id and :in_end_date_id and
                       pyc.status_date_id = yc.status_date_id and pyc.order_id = yc.parent_order_id)
         join dwh.d_account a on (a.account_id = yc.account_id)
         join dwh.client_order co on (co.create_date_id between :in_start_date_id and :in_end_date_id and
                                      co.create_date_id = yc.status_date_id and co.order_id = yc.order_id)
         left join dwh.client_order orig on (orig.create_date_id between :in_start_date_id and :in_end_date_id and
                                             orig.create_date_id = yc.status_date_id and
                                             orig.order_id = co.orig_order_id)
         join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
         left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = yc.time_in_force_id
         left join dwh.d_order_type ot on ot.order_type_id = yc.order_type_id
         join dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
         left join data_marts.d_sub_strategy dss on yc.sub_strategy_id = dss.sub_strategy_id
         left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                coalesce(exd.exchange_id, '') = coalesce(yc.exchange_id, '') and
                                                exd.instrument_type_id = yc.instrument_type_id and
                                                exd.is_active)
         left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
         left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
         left join lateral
    (
    select os.order_status_description, ex.exec_text, ex.fix_message_id, exec_type_description, exec_broker
    from dwh.execution ex
             left join dwh.d_order_status os on (os.order_status = ex.order_status and os.is_active)
             left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
    where ex.order_id = yc.order_id
      and ex.exec_date_id between :in_start_date_id and :in_end_date_id
      and ex.exec_date_id = yc.status_date_id
      and ex.order_status <> '3'
    order by ex.exec_id desc
    limit 1
    ) lst_ex on true
         left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id --and fc.is_active
         left join dwh.client_order2auction coa
                   on coa.create_date_id between :in_start_date_id and :in_end_date_id and
                      coa.create_date_id = co.create_date_id and coa.order_id = co.order_id
         left join dwh.d_order_capacity doc on doc.order_capacity_id = co.eq_order_capacity
         left join dwh.d_sub_system ds on ds.sub_system_unq_id = co.sub_system_unq_id --and ds.is_active
         left join dwh.cross_order cro on cro.cross_order_id = yc.cross_order_id
where yc.status_date_id between :in_start_date_id and :in_end_date_id
  and yc.multileg_reporting_type in ('1', '2');



select * from t_old
where true
and order_id in (10619764231,10619764244,10619764245,10619764255,10619764270,10619764288,10619764578)


-- new version
create temp table t_new as
with order_ids_cte as (select co.create_date_id,
                              co.order_id,
                              di.instrument_type_id,
                              di.display_instrument_id,
                              po.multileg_reporting_type,
                              po.time_in_force_id
                       from dwh.client_order po
                                join dwh.client_order co on (co.create_date_id = po.create_date_id and
                                                             (co.order_id = po.order_id or co.parent_order_id = po.order_id))
                           --                                         join dwh.historic_security_definition_all hsd
--                                              on (hsd.instrument_id = po.instrument_id)
                                join dwh.d_instrument di on di.instrument_id = po.instrument_id
                       where po.create_date_id between :in_start_date_id and :in_end_date_id
                         and po.multileg_reporting_type in ('1', '2')
                         and case
                                 when :in_row_type is null then true
                                 when :in_row_type = 'Parent' then co.parent_order_id is null
                                 when :in_row_type = 'Child' then co.parent_order_id is not null
                           end
                         and case
                                 when :in_instrument_type is null then true
                                 else di.instrument_type_id = :in_instrument_type end
                         and case
                                 when coalesce(:in_account_ids, '{}') = '{}' then true
                                 else co.account_id = any (:in_account_ids) end
                         and case
                                 when coalesce(:in_client_order_ids, '{}') = '{}' then true
                                 else po.client_order_id = any (:in_client_order_ids) end
                         and case
                                 when coalesce(:in_symbols, '{}') = '{}' then true
                                 else di.symbol = any (:in_symbols) end)
select array_to_string(ARRAY [
--        co.order_id,
       coalesce(pyc.client_order_id, co.client_order_id)                   , -- as "Parent Cl Ord ID",
       case when co.parent_order_id is null then 'Parent' else 'Child' end , -- as "Row Type",
       a.account_name                                                      , -- as "Account",
       to_char(co.create_time, 'MM/DD/YYYY')                               , -- as "Creation Date",
       to_char(co.process_time, 'MM/DD/YYYY')                              , -- as "Event Date",
       to_char(co.create_time, 'HH24:MI:SS.US')                            , -- as "Creation Time",
       to_char(co.process_time, 'HH24:MI:SS.US')                           , -- as "Routed Time",
       to_char(lst_ex.exec_time, 'HH24:MI:SS.US')                          , -- as "Event Time",
       lst_ex.order_status_description                                     , -- as "Order Status",
       co.client_order_id                                                  , -- as "Cl Ord ID",
       orig.client_order_id                                                , -- as "Orig Cl Ord ID",
       case
           when co.side = '1' then 'Buy'
           when co.side in ('2', '5', '6') then 'Sell'
           else ''
           end                                                             , -- as "Side",
       co.order_qty::text                                                  , -- as "Ord Qty",
       coalesce(ftr.day_cum_qty, ftr_par.day_cum_qty, 0)::text             , -- as "Ex Qty",
--        ftr.leaves_qty::text                                                , -- as "Lvs Qty",
       coalesce(ftr.leaves_qty, ftr_par.leaves_qty)::text                  , -- as "Lvs Qty",
       hsd.display_instrument_id                                           , -- as "Symbol",
       to_char(hsd.maturity_date, 'MM/DD/YYYY')                            , -- as "Expiration Day",
       round(co.price, 6)::text                                            , -- as "Price",
       round(coalesce(ftr.avg_px, ftr_par.avg_px), 6)::text                , -- as "Avg Px",
       tif.tif_name                                                        , -- as "TIF",
       ot.order_type_name                                                  , -- as "Ord Type",
       case
           when co.open_close = 'O' then 'Open'
           when co.open_close = 'C' then 'Close'
           else '' end                                                     , -- as "O/C",
       case
           when hsd.instrument_type_id = 'E' then 'Equity'
           when hsd.instrument_type_id = 'O' then 'Option'
           end                                                             , -- as "Security Type",
       hsd.underlying_symbol                                               , -- as "Root Symbol",
       co.client_id_text                                                   , -- as "Client ID",
       cf.customer_or_firm_name                                            , -- as "Capacity",
       dss.sub_strategy                                                    , -- as "Sub Strategy",
       coalesce(exd.ex_destination_desc, co.ex_destination)                , -- as "Ex Dest",
       fc.fix_comp_id                                                      , -- as "Sending Firm",
       lst_ex.exec_type_description                                        , -- as "Event Type",
       lst_ex.exec_text                                                    , -- as "Free Text",
       null::text                                                          , -- as "Reject Reason",
       co.max_floor::text                                                  , -- as "Max Floor",
       lst_ex.exec_broker                                                  , -- as "Exec Broker",
       co.clearing_firm_id                                                 , -- as "CMTA",
       case when oic.multileg_reporting_type = '1' then 'N' else 'Y' end   , -- as "Is Mleg",
       case when co.cross_order_id is not null then 'Y' else 'N' end       , -- as "Is Cross",
       coa.auction_id::text                                                , -- as "ATS Auction ID", -- ??
       case
           when cro.cross_type = 'C' then 'Customer Match'
           when cro.cross_type in ('F', '2') then 'Facilitation'
           when cro.cross_type in ('P', '4') then 'Price Improvement Mechanism'
           when cro.cross_type = 'S' then 'Solicitation'
           when cro.cross_type = 'Q' then 'Qualified Contingent Cross'
           when cro.cross_type = '1' then 'Solicitation or Customer Match Order'
           else cro.cross_type
           end                                                             , -- as "Cross Ord Type",
       co.fee_sensitivity::text                                            , -- as "Fee Sensitivity",
       --coalesce(fm_ex.tag_21, fm_co.tag_21)                                ,as  "Handle Inst",
       co.handl_inst::varchar                                              , -- as "Handle Inst",
       co.locate_broker                                                    , -- as "Locate Broker",
       co.co_client_leg_ref_id                                             , -- as "Leg ID",
       a.broker_dealer_mpid                                                , -- as "MPID",           --??
       co.occ_optional_data                                                , -- as "OCC Opt Data",   --fix_message->>'10441'
       doc.order_capacity_name                                             , -- as "Ord Capacity",
       hsd.opra_symbol                                                     , -- as "OSI Symbol",
       ds.sub_system_id                                                    , -- as "Sub System",
       co.session_eligibility::varchar                                     , -- as "Session Eligibility",
       co.sweep_style::varchar                                             , -- as "Sweep Style",

       tf.trading_firm_name                                                 -- as "Trading Firm"
                                    ], ',', '')
from order_ids_cte oic
         --                  join data_marts.f_yield_capture yc
--                       on (yc.status_date_id between :in_start_date_id and :in_end_date_id and
--                           yc.status_date_id = oic.create_date_id and yc.order_id = oic.order_id)
--                  left join data_marts.f_yield_capture pyc
--                            on (pyc.status_date_id between :in_start_date_id and :in_end_date_id and
--                                pyc.status_date_id = yc.status_date_id and pyc.order_id = yc.parent_order_id)

         join dwh.client_order co on co.create_date_id = oic.create_date_id and co.order_id = oic.order_id and
                                     co.create_date_id between :in_start_date_id and :in_end_date_id
         left join dwh.client_order pyc on pyc.create_date_id between :in_start_date_id and :in_end_date_id and
                                           pyc.create_date_id = co.create_date_id and pyc.order_id = co.parent_order_id
         join dwh.d_account a on (a.account_id = co.account_id)
    --                  join dwh.client_order co on (co.create_date_id between :in_start_date_id and :in_end_date_id and
--                                               co.create_date_id = yc.status_date_id and co.order_id = yc.order_id)
         left join lateral (select orig.client_order_id
                            from dwh.client_order orig
                            where orig.create_date_id between :in_start_date_id and :in_end_date_id
                              and orig.create_date_id = co.create_date_id
                              and orig.order_id = co.orig_order_id
                            limit 1) orig on true
         join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
         left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = oic.time_in_force_id
         left join dwh.d_order_type ot on ot.order_type_id = co.order_type_id
         join dwh.historic_security_definition_all hsd on (hsd.instrument_id = co.instrument_id)
         left join data_marts.d_sub_strategy dss on co.sub_strategy_id = dss.sub_strategy_id
         left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                coalesce(exd.exchange_id, '') = coalesce(co.exchange_id, '') and
                                                exd.instrument_type_id = oic.instrument_type_id and
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
      and ex.exec_date_id between :in_start_date_id and :in_end_date_id
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
      and ftr.date_id between :in_start_date_id and :in_end_date_id
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
      and ftr.date_id between :in_start_date_id and :in_end_date_id
      and ftr.order_id = co.order_id
      and ftr.is_busted = 'N'
      and co.parent_order_id is null
    ) ftr_par on true

         left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id --and fc.is_active
         left join dwh.client_order2auction coa
                   on coa.create_date_id between :in_start_date_id and :in_end_date_id and
                      coa.create_date_id = co.create_date_id and coa.order_id = co.order_id
         left join dwh.d_order_capacity doc on doc.order_capacity_id = co.eq_order_capacity
         left join dwh.d_sub_system ds on ds.sub_system_unq_id = co.sub_system_unq_id --and ds.is_active
         left join dwh.cross_order cro on cro.cross_order_id = co.cross_order_id and co.cross_order_id is not null
where co.create_date_id between :in_start_date_id and :in_end_date_id
  and co.multileg_reporting_type in ('1', '2');

--         order by yc.status_date_id, coalesce(yc.parent_order_id, yc.order_id), yc.order_id;


with b as (select 'old',
                  order_id,
                  "Parent Cl Ord ID",
                  "Row Type",
                  "Account",
                  "Creation Date",
                  "Event Date",
                  "Creation Time",
                  "Routed Time",
                  "Event Time",
                  "Order Status",
                  "Cl Ord ID",
                  "Orig Cl Ord ID",
                  "Side",
                  "Ord Qty",
                  "Ex Qty",
                  "Lvs Qty",
                  "Symbol",
                  "Expiration Day",
                  "Price",
                  "Avg Px",
                  "TIF",
                  "Ord Type",
                  "O/C",
                  "Security Type",
                  "Root Symbol",
                  "Client ID",
                  "Capacity",
                  "Sub Strategy",
                  "Ex Dest",
                  "Sending Firm",
                  "Event Type",
                  "Free Text",
                  "Reject Reason",
                  "Max Floor",
                  "Exec Broker",
                  "CMTA",
                  "Is Mleg",
                  "Is Cross",
                  "ATS Auction ID",
                  "Cross Ord Type",
                  "Fee Sensitivity",
                  "Handle Inst",
                  "Locate Broker",
                  "Leg ID",
                  "MPID",
                  "OCC Opt Data",
                  "Ord Capacity",
                  "OSI Symbol",
                  "Sub System",
                  "Session Eligibility",
                  "Sweep Style",
                  "Trading Firm"
           from t_old
-- where order_id in (10619784785,10619788313,10619782066)
--               union all
           except
           select 'old',
                  order_id,
                  "Parent Cl Ord ID",
                  "Row Type",
                  "Account",
                  "Creation Date",
                  "Event Date",
                  "Creation Time",
                  "Routed Time",
                  "Event Time",
                  "Order Status",
                  "Cl Ord ID",
                  "Orig Cl Ord ID",
                  "Side",
                  "Ord Qty",
                  "Ex Qty",
                  "Lvs Qty",
                  "Symbol",
                  "Expiration Day",
                  "Price",
                  "Avg Px",
                  "TIF",
                  "Ord Type",
                  "O/C",
                  "Security Type",
                  "Root Symbol",
                  "Client ID",
                  "Capacity",
                  "Sub Strategy",
                  "Ex Dest",
                  "Sending Firm",
                  "Event Type",
                  "Free Text",
                  "Reject Reason",
                  "Max Floor",
                  "Exec Broker",
                  "CMTA",
                  "Is Mleg",
                  "Is Cross",
                  "ATS Auction ID",
                  "Cross Ord Type",
                  "Fee Sensitivity",
                  "Handle Inst",
                  "Locate Broker",
                  "Leg ID",
                  "MPID",
                  "OCC Opt Data",
                  "Ord Capacity",
                  "OSI Symbol",
                  "Sub System",
                  "Session Eligibility",
                  "Sweep Style",
                  "Trading Firm"
           from t_new
where order_id in (10619784785,10619788313,10619782066)
                      )
select *
from b
order by 2, 1;


select order_qty, time_in_force_id, * from dwh.client_order
where order_id in (10619802252, 10619764211)
and create_date_id = 20230103

select * from dwh.execution
where order_id = 10619802252
and exec_date_id = 20230103;

select
    sum(last_qty)             as                                day_cum_qty,
       ft.date_id                as                                trade_date_id,
       sum(ft.last_qty * ft.last_px) / nullif(sum(ft.last_qty), 0) day_avg_px,
       max(ft.trade_record_time) as                                exec_time,
       min(ft.leaves_qty)        as                                leaves_qty
from flat_trade_record ft
where true
--     and ft.date_id = 20230103
  and ft.street_order_id = 10619782066
  and ft.is_busted = 'N'
-- and ft.date_id = ex.exec_date_id -- sy: 20211216
group by ft.date_id

select time_in_force_id, * from data_marts.f_yield_capture
where order_id = 10619802252;


select orig_order_id, * from dwh.client_order
    where order_id in (10619781643)


select client_order_id, * from dwh.client_order
    where order_id in (10619774439)

B062AAAG457520230103

    B062AAAG469720230103
B062AAAG457520230103
