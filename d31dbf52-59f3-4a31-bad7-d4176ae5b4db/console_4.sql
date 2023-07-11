        select po.client_order_id                     as parent_client_order_id,
               co.client_order_id,
               co.exch_order_id,
               ex.order_id,
               co.side,
               co.order_qty,
               co.price,
               tif.tif_short_name                        time_in_force,
               inst.instrument_name,
               inst.last_trade_date,
               acc.account_name,
               dss.sub_system_id,
               co.multileg_reporting_type,
               ex.exec_id,
               ex.ref_exec_id,
               ex.exch_exec_id,
               ex.exec_time                           as exec_time_orig,
               to_char(ex.exec_time, 'HH12:MI:SS.MS') as exec_time,
               et.exec_type_description               as exec_type,
               os.order_status_description            as order_status,
               ex.leaves_qty,
               ex.cum_qty,
               ex.avg_px,
               ex.last_qty,
               ex.last_px,
               ex.bust_qty,
               ex.last_mkt,
               lm.last_mkt_name                       as last_mkt_name,
               ex.text_,
               ex.trade_liquidity_indicator,
               ex.is_busted,
               ex.exec_broker,
               ex.exchange_id,
               e.exchange_name
        from dwh.execution ex
                 join dwh.client_order co on co.order_id = ex.order_id
                 inner join dwh.client_order po on po.order_id = co.parent_order_id
                 inner join dwh.d_account acc on co.account_id = acc.account_id
                 inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
                 left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
                 left join dwh.d_order_status os on os.order_status = ex.order_status
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
                 left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
                 left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
                 left join dwh.d_exec_type et on et.exec_type = ex.exec_type
        where ex.exec_type in ('F', 'H')
          and co.account_id = any('{63384,63109,54131}')
--           and case when coalesce(in_account_ids, '{}') = '{}' then true else co.account_id = any (in_account_ids) end
--           and case when coalesce(in_exchange_ids, '{}') = '{}' then true else ex.exchange_id = any (in_exchange_ids) end
--           and ex.exec_date_id >= public.get_dateid(in_start_date)
--           and ex.exec_date_id <= public.get_dateid(in_end_date + 1)
          and ex.exec_date_id >= public.get_dateid(:in_start_date::date)
          and ex.exec_date_id < public.get_dateid(:in_end_date::date + 1 )
          and co.parent_order_id is not null;