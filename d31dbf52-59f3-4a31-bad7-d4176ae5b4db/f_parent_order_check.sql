-- DROP FUNCTION staging.load_parent_order_track(_int8, int4, _int8);

create or replace function staging.load_parent_order_track(in_parent_order_ids bigint[],
                                                in_date_id integer,
                                                in_dataset_ids bigint[])
    returns table
            (
                parent_order_id     int8,
                min_exec_id         int8,
                max_exec_id         int8,
                create_date_id      int4,
                status_date_id      int4,
                time_in_force_id    bpchar(1),
                account_id          int4,
                trading_firm_unq_id int4,
                instrument_id       int8,
                instrument_type_id  bpchar(1),
                street_count        int4,
                trade_count         int4,
                order_qty           int4,
                street_order_qty    int4,
                last_qty            numeric,
                amount              numeric,
                side                bpchar(1)
            )
    language plpgsql
as
$function$
    -- SO: 20240307 https://dashfinancial.atlassian.net/browse/DS-8065
    -- SO: 20240424 removed leaves_qty
    -- SO: 20240513 replaced get_dateid with get_gth_date_id_by_instrument_type
------------------------------------------------------------------------------------------------------------------------
    -- SO: 20240520 the new script in schema staging is a modification of the main script that returns a table with data
    -- for certain dataset_id and parent_order_id to be able to track changes
declare
    l_date_id int4 := in_date_id;

begin

    -- the list of orders with permanent attributes
    drop table if exists t_base;
    create temp table t_base as
    select cl.parent_order_id,
           min(exec_id)                      as min_exec_id,
           max(exec_id)                      as max_exec_id,
           min(cl.parent_order_process_time) as parent_order_process_time,
           min(ex.order_create_date_id)      as order_create_date_id
    from dwh.execution ex
             join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
    where exec_date_id = l_date_id
      and ex.dataset_id = any (in_dataset_ids)
      and cl.parent_order_id = any (in_parent_order_ids)
      and not is_parent_level
      and ex.exec_type in ('F', '0', 'W')
      and cl.parent_order_id is not null
    group by cl.parent_order_id;

    drop table if exists t_base_ext;
    create temp table t_base_ext as
    select base.parent_order_id,
           base.order_create_date_id,
           par.create_date_id      as create_date_id,
           base.min_exec_id        as min_exec_id,
           base.max_exec_id        as max_exec_id,
           par.time_in_force_id    as time_in_force_id,
           par.account_id          as account_id,
           par.instrument_id       as instrument_id,
           par.instrument_type_id  as instrument_type_id,
           par.trading_firm_unq_id as trading_firm_unq_id,
           par.order_qty           as parent_order_qty,
           par.side                as side
    from t_base base
             join lateral (select par.parent_order_id,
                                  par.create_date_id,
                                  par.time_in_force_id,
                                  par.account_id,
                                  par.instrument_id,
                                  di.instrument_type_id,
                                  par.trading_firm_unq_id,
                                  par.order_qty,
                                  par.side
                           from dwh.client_order par
                                    join dwh.d_instrument di on di.instrument_id = par.instrument_id and di.is_active
                           where par.order_id = base.parent_order_id
                             and par.parent_order_id is null
                             and par.create_date_id =
                                 public.get_gth_date_id_by_instrument_type(base.parent_order_process_time,
                                                                           di.instrument_type_id)
                           limit 1) par on true
    where true
      and par.parent_order_id is null;

    -- new groupped by parent_order
    drop table if exists t_parent_orders;
    create temp table t_parent_orders as
    select bs.*,
           val.*
    from t_base_ext bs
             join lateral (select lo.street_count, lo.trade_count, lo.last_qty, lo.amount, lo.street_order_qty
                           from data_marts.get_exec_for_parent_order(in_parent_order_id := bs.parent_order_id,
                                                                     in_date_id := l_date_id,
                                                                     in_min_exec_id := 0,
                                                                     in_max_exec_id := bs.max_exec_id,
                                                                     in_order_create_date_id := bs.create_date_id
                                ) as lo
                           limit 1) val on true;

    return query
        select tp.parent_order_id,
               tp.min_exec_id,
               tp.max_exec_id,
               tp.create_date_id,
               l_date_id,
               tp.time_in_force_id,
               tp.account_id,
               tp.trading_firm_unq_id,
               tp.instrument_id,
               tp.instrument_type_id,
               tp.street_count::int4,
               tp.trade_count::int4,
               tp.parent_order_qty::int4,
               tp.street_order_qty::int4,
               tp.last_qty,
               tp.amount,
               tp.side
        from t_parent_orders tp
                 left join data_marts.f_parent_order fp
                           on fp.parent_order_id = tp.parent_order_id and fp.status_date_id = l_date_id;

end;
$function$
;

select * from data_marts.f_parent_order
where status_date_id = 20240517
and parent_order_id = any('{15612386971,13187087931,13732271060,13931084228,15612178004,15612257823,15612352582}')
order by 1, 2;

select distinct cl.parent_order_id, ex.dataset_id--, instrument_id, order_create_date_id, is_busted, *
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
where cl.parent_order_id = any ('{15661367123}')
  and ex.exec_date_id = 20240522
  and exec_type = 'F'
order by 1, 2;



select parent_order_id,
       create_date_id,
       status_date_id,
       time_in_force_id,
       account_id,
       trading_firm_unq_id,
       instrument_id,
       instrument_type_id,
       street_count,
       trade_count,
       order_qty,
       street_order_qty,
       last_qty,
       amount
from staging.load_parent_order_track(in_parent_order_ids := '{15661367123}',
                                     in_date_id := 20240522,
                                     in_dataset_ids := '{209159174}');

209159097
209159174

select last_qty--ex.exec_type, ex.*
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
where cl.parent_order_id = any ('{15661367123}')
  and ex.exec_date_id = 20240522
  and exec_type = 'F'
and ex.dataset_id in (209159174)--, 209159174)
order by ex.exec_id