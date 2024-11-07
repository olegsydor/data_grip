with order_ids_cte as (select co.create_date_id, co.order_id, di.instrument_type_id
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
select --array_to_string(ARRAY [
       coalesce(pyc.client_order_id, co.client_order_id),                   -- as "Parent Cl Ord ID",
       case when co.parent_order_id is null then 'Parent' else 'Child' end, -- as "Row Type",
       a.account_name,                                                      -- as "Account",
       to_char(co.create_time, 'MM/DD/YYYY'),                               -- as "Creation Date",
       to_char(co.process_time, 'MM/DD/YYYY'),                               -- as "Event Date",
       to_char(co.create_time, 'HH24:MI:SS.US'),                            -- as "Creation Time",
       to_char(co.process_time, 'HH24:MI:SS.US'),                            -- as "Routed Time",
       to_char(yc.exec_time, 'HH24:MI:SS.US'),                              -- as "Event Time",
       lst_ex.order_status_description,                                     -- as "Order Status",
       yc.client_order_id,                                                  -- as "Cl Ord ID",
       orig.client_order_id,                                                -- as "Orig Cl Ord ID",
/*                                   case
                                       when yc.side = '1' then 'Buy'
                                       when yc.side in ('2', '5', '6') then 'Sell'
                                       else ''
                                       end, -- as "Side",
                                   yc.order_qty::text, -- as "Ord Qty",
                                   yc.day_cum_qty::text, -- as "Ex Qty",
                                   yc.day_leaves_qty::text, -- as "Lvs Qty",
                                   hsd.display_instrument_id, -- as "Symbol",
                                   to_char(hsd.maturity_date, 'MM/DD/YYYY'), -- as "Expiration Day",
                                   round(yc.order_price, 6)::text, -- as "Price",
                                   round(yc.avg_px, 6)::text, -- as "Avg Px",
                                   tif.tif_name, -- as "TIF",
                                   ot.order_type_name, -- as "Ord Type",
                                   case
                                       when co.open_close = 'O' then 'Open'
                                       when co.open_close = 'C' then 'Close'
                                       else '' end, -- as "O/C",
                                   case
                                       when hsd.instrument_type_id = 'E' then 'Equity'
                                       when hsd.instrument_type_id = 'O' then 'Option'
                                       end, -- as "Security Type",
                                   hsd.underlying_symbol, -- as "Root Symbol",
                                   yc.client_id, -- as "Client ID",
                                   cf.customer_or_firm_name, -- as "Capacity",
                                   dss.sub_strategy, -- as "Sub Strategy",
                                   coalesce(exd.ex_destination_desc, co.ex_destination), -- as "Ex Dest",
                                   fc.fix_comp_id, -- as "Sending Firm",
                                   lst_ex.exec_type_description, -- as "Event Type",
                                   lst_ex.exec_text, -- as "Free Text",
                                   null::text, -- as "Reject Reason",
                                   co.max_floor::text, -- as "Max Floor",
                                   lst_ex.exec_broker, -- as "Exec Broker",
                                   co.clearing_firm_id, -- as "CMTA",
                                   case when yc.multileg_reporting_type = '1' then 'N' else 'Y' end, -- as "Is Mleg",
                                   case when yc.cross_order_id is not null then 'Y' else 'N' end, -- as "Is Cross",
                                   coa.auction_id::text, -- as "ATS Auction ID", -- ??
                                   case
                                       when cro.cross_type = 'C' then 'Customer Match'
                                       when cro.cross_type in ('F', '2') then 'Facilitation'
                                       when cro.cross_type in ('P', '4') then 'Price Improvement Mechanism'
                                       when cro.cross_type = 'S' then 'Solicitation'
                                       when cro.cross_type = 'Q' then 'Qualified Contingent Cross'
                                       when cro.cross_type = '1' then 'Solicitation or Customer Match Order'
                                       else cro.cross_type
                                       end, -- as "Cross Ord Type",
                                   co.fee_sensitivity::text, -- as "Fee Sensitivity",
            --coalesce(fm_ex.tag_21, fm_co.tag_21)                                , -- as "Handle Inst",
                                   co.handl_inst::varchar, -- as "Handle Inst",
                                   co.locate_broker, -- as "Locate Broker",
                                   co.co_client_leg_ref_id, -- as "Leg ID",
                                   a.broker_dealer_mpid, -- as "MPID",           --??
                                   co.occ_optional_data, -- as "OCC Opt Data", --fix_message->>'10441'
                                   doc.order_capacity_name, -- as "Ord Capacity",
                                   hsd.opra_symbol, -- as "OSI Symbol",
                                   ds.sub_system_id, -- as "Sub System",
                                   co.session_eligibility::varchar, -- as "Session Eligibility",
                                   co.sweep_style::varchar, -- as "Sweep Style",

 */
       tf.trading_firm_name                                                 -- as "Trading Firm"
--                                     ], ',', '')
from order_ids_cte oic
         --                  join data_marts.f_yield_capture yc
--                       on (yc.status_date_id between :in_start_date_id and :in_end_date_id and
--                           yc.status_date_id = oic.create_date_id and yc.order_id = oic.order_id)
--                  left join data_marts.f_yield_capture pyc
--                            on (pyc.status_date_id between in_start_date_id and in_end_date_id and
--                                pyc.status_date_id = yc.status_date_id and pyc.order_id = yc.parent_order_id)
         join dwh.client_order co on co.create_date_id = oic.create_date_id and co.order_id = oic.order_id and
                                     co.create_date_id between :in_start_date_id and :in_end_date_id
         left join dwh.client_order pyc on pyc.create_date_id between :in_start_date_id and :in_end_date_id and
                                           pyc.create_date_id = co.create_date_id and pyc.order_id = co.parent_order_id
         join dwh.d_account a on (a.account_id = co.account_id)
    --                  join dwh.client_order co on (co.create_date_id between :in_start_date_id and :in_end_date_id and
--                                               co.create_date_id = yc.status_date_id and co.order_id = yc.order_id)
         left join lateral (select co.client_order_id
                            from dwh.client_order orig
                            where orig.create_date_id between :in_start_date_id and :in_end_date_id
                              and orig.create_date_id = co.create_date_id
                              and orig.order_id = co.orig_order_id
                            limit 1) orig on true
         join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
         left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = co.time_in_force_id
         left join dwh.d_order_type ot on ot.order_type_id = co.order_type_id
--                  join dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
         left join data_marts.d_sub_strategy dss on co.sub_strategy_id = dss.sub_strategy_id
         left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                coalesce(exd.exchange_id, '') = coalesce(co.exchange_id, '') and
                                                exd.instrument_type_id = oic.instrument_type_id and
                                                exd.is_active)
         left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
         left join dwh.d_exchange ex on (ex.exchange_unq_id = co.exchange_unq_id)
         left join lateral
    (
    select os.order_status_description, ex.exec_text, ex.fix_message_id, exec_type_description, exec_broker
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
         left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id --and fc.is_active
         left join dwh.client_order2auction coa
                   on coa.create_date_id between :in_start_date_id and :in_end_date_id and
                      coa.create_date_id = co.create_date_id and coa.order_id = co.order_id
         left join dwh.d_order_capacity doc on doc.order_capacity_id = co.eq_order_capacity
         left join dwh.d_sub_system ds on ds.sub_system_unq_id = co.sub_system_unq_id --and ds.is_active
         left join dwh.cross_order cro on cro.cross_order_id = co.cross_order_id and co.cross_order_id is not null


where co.create_date_id between :in_start_date_id and :in_end_date_id
  and co.multileg_reporting_type in ('1', '2')
--         order by yc.status_date_id, coalesce(yc.parent_order_id, yc.order_id), yc.order_id;



