select yc.parent_order_id                                                  as "Parent Cl Ord ID",
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
       yc.order_qty                                                        as "Ord Qty",
       yc.day_cum_qty                                                      as "Ex Qty",
       yc.day_leaves_qty                                                   as "Lvs Qty",
       hsd.display_instrument_id                                           as "Symbol",
       to_char(hsd.maturity_date, 'MM/DD/YYYY')                            as "Expiration Day",
       yc.order_price                                                      as "Price",
       yc.avg_px                                                           as "Avg Px",
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
       lst_ex.text_                                                        as "Free Text",
       null::text                                                          as "Reject Reason",
       co.max_floor                                                        as "Max Floor",
       lst_ex.exec_broker                                                  as "Exec Broker",
       co.clearing_firm_id                                                 as "CMTA",
       case when yc.multileg_reporting_type = '1' then 'N' else 'Y' end    as "Is Mleg",
       case when yc.cross_order_id is not null then 'Y' else 'N' end       as "Is Cross",
       coa.auction_id                                                      as "ATS Auction ID", -- ??
       null::text                                                          as "Cross Ord Type",
       co.fee_sensitivity                                                  as "Fee Sensitivity",
       coalesce(fm_ex.tag_21, fm_co.tag_21)                                as "Handle Inst",
       co.locate_broker                                                    as "Locate Broker",
       co.co_client_leg_ref_id                                             as "Leg ID",
       a.broker_dealer_mpid                                                as "MPID",           --??
       null::text                                                          as "OCC Opt Data",
       doc.order_capacity_name                                             as "Ord Capacity",
       hsd.opra_symbol                                                     as "OSI Symbol",
       ds.sub_system_id                                                   as "Sub System",
       co.session_eligibility                                              as "Session Eligibility",
       co.sweep_style                                                      as "Sweep Style",
       tf.trading_firm_name                                                as "Trading Firm"
from data_marts.f_yield_capture yc
         join dwh.d_account a on (a.account_id = yc.account_id)
         join dwh.client_order co on (co.create_date_id between :in_start_date_id and :in_end_date_id and co.create_date_id = yc.status_date_id and co.order_id = yc.order_id)
         left join dwh.client_order orig on (orig.create_date_id between :in_start_date_id and :in_end_date_id and orig.create_date_id = yc.status_date_id and orig.order_id = co.orig_order_id)
         join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
         left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = yc.time_in_force_id
         left join dwh.d_order_type ot on ot.order_type_id = yc.order_type_id
         join dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
         left join data_marts.d_sub_strategy dss on yc.sub_strategy_id = dss.sub_strategy_id
         left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and coalesce(exd.exchange_id, '') = coalesce(yc.exchange_id, '') and exd.instrument_type_id = yc.instrument_type_id and exd.is_active)
         left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
         left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
         left join lateral
    (
    select os.order_status_description, ex.text_, ex.fix_message_id, exec_type_description, exec_broker
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
         left join lateral (select fix_message ->> '6376' as tag_6376,
                                   fix_message ->> '376'  as tag_376,
                                   fix_message ->> '21'   as tag_21,
                                   fix_message ->> '18'   as tag_18
                            from fix_capture.fix_message_json fm
                            where fm.fix_message_id = co.fix_message_id
                              and fm.date_id between :in_start_date_id and :in_end_date_id
                            limit 1) fm_co on true
         left join lateral (select fix_message ->> '6376' as tag_6376,
                                   fix_message ->> '376'  as tag_376,
                                   fix_message ->> '21'   as tag_21,
                                   fix_message ->> '18'   as tag_18
                            from fix_capture.fix_message_json fm
                            where fm.fix_message_id = lst_ex.fix_message_id
                              and fm.date_id between :in_start_date_id and :in_end_date_id
                            limit 1) fm_ex on true
         left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id and fc.is_active
         left join dwh.client_order2auction coa on coa.order_id = co.order_id and coa.create_date_id = co.create_date_id
         left join dwh.d_order_capacity doc on doc.order_capacity_id = co.order_capacity_id
         left join dwh.d_sub_system ds on ds.sub_system_unq_id = co.sub_system_unq_id and ds.is_active
where yc.status_date_id between :in_start_date_id and :in_end_date_id
  and case
          when :in_row_type is null then true
          when :in_row_type = 'Parent' then yc.parent_order_id is null
          when :in_row_type = 'Child' then yc.parent_order_id is not null end
  and case when :in_instrument_type is null then true else yc.instrument_type_id = :in_instrument_type end
  and yc.account_id = any ('{26594,26668,26675,64854}')
  and yc.multileg_reporting_type in ('1', '2')
-- order by co.create_date_id, co.order_id
;


select * from dwh.d_account
where account_name in ('5CG05976', '5CG05464', '5CG05518', '5CG05523');


select * from data_marts.f_yield_capture
where status_date_id = 20230726
and order_id in (109649403,109644969,109649404,109737892,109649482)
;

select "CrossOrderID", "CrossType", "ClOrdID" from
dwh.historic_order_details_storage x
where "Status_Date_id" = 20230726
and "CrossOrderID" is not null;

select * from dwh.client_order co
             where true
-- and create_date_id = 20230726
-- and client_order_id = 'DHAA1507-20230726'
and cross_order_id = 107162675

select cross_order_id, count(distinct order_type_id)
from dwh.client_order co
where true
  and create_date_id > 20230701
group by cross_order_id
having count(distinct order_type_id) > 1
limit 10