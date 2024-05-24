
alter table data_marts.f_parent_order add column check_sum text;

insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           street_count, trade_count, last_qty, amount, street_order_qty,
                                           pg_db_create_time,
                                           order_qty,
                                           time_in_force_id, account_id, trading_firm_unq_id, instrument_id,
                                           instrument_type_id, check_sum)
    select tp.parent_order_id,
           tp.max_exec_id,
           tp.create_date_id,
           :l_date_id,
           case when tp.need_update then tp.street_count else tp.street_count + coalesce(fp.street_count, 0) end,
           case when tp.need_update then tp.trade_count else tp.trade_count + coalesce(fp.trade_count, 0) end,
           case when tp.need_update then tp.last_qty else tp.last_qty + coalesce(fp.last_qty, 0) end,
           case when tp.need_update then tp.amount else tp.amount + coalesce(fp.amount, 0) end,
           case when tp.need_update then tp.street_order_qty else tp.amount + coalesce(fp.street_order_qty, 0) end,
           clock_timestamp(),
           --
           tp.parent_order_qty,
           tp.time_in_force_id,
           tp.account_id,
           tp.trading_firm_unq_id,
           tp.instrument_id,
           tp.instrument_type_id,
           md5(row (:date_id, tp.max_exec_id, tp.street_count,tp.trade_count,tp.last_qty,tp.amount,tp.street_order_qty,tp.parent_order_qty,tp.instrument_id)::text) as check_sum
    from t_parent_orders tp
             left join data_marts.f_parent_order fp
                       on fp.parent_order_id = tp.parent_order_id and fp.status_date_id = l_date_id
    on conflict (status_date_id, parent_order_id)
    do update
        set last_exec_id      = excluded.last_exec_id,
            street_count      = excluded.street_count,
            trade_count       = excluded.trade_count,
            last_qty          = excluded.last_qty,
            amount            = excluded.amount,
            street_order_qty  = excluded.street_order_qty,
            pg_db_update_time = clock_timestamp(),
            instrument_id     = excluded.instrument_id
where check_sum <> excluded.check_sum;