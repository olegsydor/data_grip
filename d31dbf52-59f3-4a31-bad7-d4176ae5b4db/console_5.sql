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


       tf.trading_firm_name                                                as "Trading Firm",




       ot.order_type_name                                                  as "Ord Type",





       case
           when hsd.instrument_type_id = 'E' then 'Equity'
           when hsd.instrument_type_id = 'O' then 'Option'
           end                                                             as "Sec Type",
       coalesce(exd.ex_destination_desc, co.ex_destination)                as "Ex Dest",
       dss.sub_strategy                                                    as "Sub Strategy",

       case
           when co.open_close = 'O' then 'Open'
           when co.open_close = 'C' then 'Close'
           else '' end                                                     as "O/C",






       ex.exchange_name                                                    as "Exchange Name",
       cf.customer_or_firm_name                                            as "Cust/Firm",
       co.clearing_firm_id                                                 as "CMTA",
       yc.client_id                                                        as "Client ID",
       hsd.opra_symbol                                                     as "OSI Symbol",
       hsd.underlying_symbol                                               as "Root Symbol",

       hsd.put_call                                                        as "Put/Call",
       hsd.strike_px                                                       as "Strike",
       case when yc.multileg_reporting_type = '1' then 'N' else 'Y' end    as "Is Mleg",
       case when yc.cross_order_id is not null then 'Y' else 'N' end       as "Is Cross",

       co.max_floor                                                        as "Max Floor",
       case
           when co.exec_instruction like '1%' then 'NH' -- Not Held
           when co.exec_instruction like '5%' then 'H' -- Held
           else 'NH'
           end                                                             as "Held Status",
       coalesce(fm_ex.tag_6376, fm_co.tag_6376)                            as "Alternative Compliance ID",
       coalesce(fm_ex.tag_376, fm_co.tag_6376)                             as "Compliance ID",
       coalesce(fm_ex.tag_21, fm_co.tag_21)                                as "Handling Instructions",
       coalesce(fm_ex.tag_18, fm_co.tag_18)                                as "Execution Instructions",
       co.co_client_leg_ref_id                                             as "Leg ID",
       lst_ex.text_                                                        as "Free Text"
from data_marts.f_yield_capture yc
         join dwh.d_account a on (a.account_id = yc.account_id)
         join dwh.client_order co on (co.create_date_id between :in_start_date_id and :in_end_date_id and
                                      co.create_date_id = yc.status_date_id and
                                      co.order_id = yc.order_id)
         left join dwh.client_order orig
                   on (orig.create_date_id between :in_start_date_id and :in_end_date_id and
                       orig.create_date_id = yc.status_date_id and
                       orig.order_id = co.orig_order_id)
         join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
         left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = yc.time_in_force_id
         left join dwh.d_order_type ot on ot.order_type_id = yc.order_type_id
         join dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
         left join data_marts.d_sub_strategy dss on yc.sub_strategy_id = dss.sub_strategy_id
         left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
                                                coalesce(exd.exchange_id, '') =
                                                coalesce(yc.exchange_id, '') and
                                                exd.instrument_type_id = yc.instrument_type_id and
                                                exd.is_active)
         left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
         left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
         left join lateral
    (
    select os.order_status_description, ex.text_, ex.fix_message_id
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
where yc.status_date_id between :in_start_date_id and :in_end_date_id
  and case
          when :in_row_type is null then true
          when :in_row_type = 'Parent' then yc.parent_order_id is null
          when :in_row_type = 'Child' then yc.parent_order_id is not null end
  and case when :in_instrument_type is null then true else yc.instrument_type_id = :in_instrument_type end
  and yc.account_id = any ('{26594,26668,26675,64854}')
  and yc.multileg_reporting_type in ('1', '2')
-- order by co.create_date_id, co.order_id
-- ;

select * from dwh.d_account
where account_name in ('5CG05976', '5CG05464', '5CG05518', '5CG05523')