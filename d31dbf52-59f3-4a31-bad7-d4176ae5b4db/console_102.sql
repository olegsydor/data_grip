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
   , all_rows as (select co.order_id,
                         coalesce(pyc.client_order_id, co.client_order_id)                 as "Parent Cl Ord ID",
                         a.account_name                                                    as "Account",
                         case
                             when hsd.instrument_type_id = 'E' then 'Equity'
                             when hsd.instrument_type_id = 'O' then 'Option'
                             end                                                           as "Security Type",
                         coalesce(exd.ex_destination_desc, co.ex_destination)              as "Ex Dest",
                         lst_ex.exec_type_description                                      as "Event Type",
                         lst_ex.exec_text                                                  as "Free Text",
                         null::text                                                        as "Reject Reason",
                         case when oic.multileg_reporting_type = '1' then 'N' else 'Y' end as "Is Mleg",
                         case when co.cross_order_id is not null then 'Y' else 'N' end     as "Is Cross",
                         tf.trading_firm_name                                              as "Trading Firm"

                  from order_ids_cte oic
                           join dwh.client_order co on
                      co.create_date_id = oic.create_date_id and co.order_id = oic.order_id and
                      co.create_date_id between :in_start_date_id and :in_end_date_id
                           left join dwh.client_order pyc on
                      pyc.create_date_id between :in_start_date_id and :in_end_date_id and
                      pyc.create_date_id = co.create_date_id and pyc.order_id = co.parent_order_id
                           join dwh.d_account a on (a.account_id = co.account_id)
                           join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                           join dwh.historic_security_definition_all hsd
                                on (hsd.instrument_id = co.instrument_id)

                           left join dwh.d_ex_destination exd
                                     on (exd.ex_destination_code = co.ex_destination and
                                         coalesce(exd.exchange_id, '') =
                                         coalesce(co.exchange_id, '') and
                                         exd.instrument_type_id =
                                         oic.instrument_type_id and
                                         exd.is_active)
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
                               left join dwh.d_order_status os
                                         on (os.order_status = ex.order_status and os.is_active)
                               left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
                      where ex.order_id = co.order_id
                        and ex.exec_date_id between :in_start_date_id and :in_end_date_id
                        and ex.exec_date_id = co.create_date_id
                        and ex.order_status <> '3'
                      order by ex.exec_id desc
                      limit 1
                      ) lst_ex on true
                  where co.create_date_id between :in_start_date_id and :in_end_date_id
                    and co.multileg_reporting_type in ('1', '2')
                    and co.trans_type <> 'F')
select "Ex Dest",
       "Account",
       "Security Type",
       "Event Type",
       "Free Text",
       "Reject Reason",
       "Is Mleg",
       "Is Cross",
       "Trading Firm",
       array_agg(distinct "Parent Cl Ord ID") as parent_orders,
       count(distinct "Parent Cl Ord ID")     as parent_order_count,
       count(order_id)                        as order_count
from all_rows
group by "Account", "Security Type", "Ex Dest", "Event Type", "Free Text", "Reject Reason", "Is Mleg", "Is Cross",
         "Trading Firm"