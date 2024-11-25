create or replace function trash.so_order_blotter_reg(in_start_date_id int4, in_end_date_id int4, in_client_order_ids text[])
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$$
begin
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
                               where po.create_date_id between in_start_date_id and in_end_date_id
                                 and po.multileg_reporting_type in ('1', '2')
                                 and case
                                         when coalesce(in_client_order_ids, '{}') = '{}' then true
                                         else po.client_order_id = any (in_client_order_ids) end)
           , all_rows as (select co.account_id,
                                 hsd.instrument_type_id,
                                 co.client_order_id,
                                 hsd.symbol,
                                 co.order_id,
                                 to_char(co.process_time, 'MM/DD/YYYY')                            as "Event Date",
                                 lst_ex.order_status_description                                   as "Order Status",
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
                              co.create_date_id between in_start_date_id and in_end_date_id
                                   left join dwh.client_order pyc on
                              pyc.create_date_id between in_start_date_id and in_end_date_id and
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
                                and ex.exec_date_id between in_start_date_id and in_end_date_id
                                and ex.exec_date_id = co.create_date_id
                                and ex.order_status <> '3'
                              order by ex.exec_id desc
                              limit 1
                              ) lst_ex on true
                          where co.create_date_id between in_start_date_id and in_end_date_id
                            and co.multileg_reporting_type in ('1', '2')
                            and co.trans_type <> 'F')
        select array_to_string(ARRAY [
                                   "Event Date",
                                   "Order Status",
                                   "Ex Dest",
                                   "Event Type",
                                   "Free Text",
                                   "Reject Reason",
                                   "Is Mleg",
                                   "Is Cross",
                                   "Security Type",
                                   "Account",
                                   "Trading Firm",
                                   count(distinct "Parent Cl Ord ID")::text,
                                   count(order_id)::text
                                   ], ',', '') as ret_row
        from all_rows
        group by "Event Date",
                                   "Order Status",
                                   "Ex Dest",
                                   "Event Type",
                                   "Free Text",
                                   "Reject Reason",
                                   "Is Mleg",
                                   "Is Cross",
                                   "Security Type",
                                   "Account",
                                   "Trading Firm";
end;
$$;

select * from trash.so_order_blotter_reg(20221212, 20221212,'{0180000134}');


select 'Event Date,Order Status,Ex Dest,Event Type,Free Text,Reject Reason,Is Mleg,Is Cross,Security Type,Account,Trading Firm,Count Parent Cl Ord ID,Count Order_id'


select --tf.trading_firm_id, a.account_name, ts.target_strategy_name, fmo.fix_message->>'9000' as tag9000, co.client_order_id, co.create_date_id
distinct co.client_order_id, co.create_date_id
into temp table t_so
from dwh.client_order co
left join dwh.d_account a on (a.account_id = co.account_id)
-- left join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
left join dwh.d_target_strategy ts on (ts.target_strategy_id = co.sub_strategy_id)
-- left join fix_capture.fix_message_json fmo on (fmo.date_id = co.create_date_id and fmo.fix_message_id = co.fix_message_id)
where co.create_date_id between 20221201 and 20230131
 and co.parent_order_id is null --Parent orders only
 and co.multileg_reporting_type in ('1','2')
 and ts.target_strategy_name = 'VOL'

select * from t_so
         where create_date_id >= 20230101
order by 2