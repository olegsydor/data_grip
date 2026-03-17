
-- DROP FUNCTION data_marts.load_parent_order_inc(_int8, int4, _int8);

CREATE OR REPLACE FUNCTION data_marts.load_parent_order_inc(in_parent_order_ids bigint[] DEFAULT NULL::bigint[], in_date_id integer DEFAULT NULL::integer, in_dataset_ids bigint[] DEFAULT NULL::bigint[])
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL: f_parent_order_process'
AS $function$
    -- SO: 20240307 https://dashfinancial.atlassian.net/browse/DS-8065
    -- SO: 20240424 removed leaves_qty
    -- SO: 20240513 replaced get_dateid with get_gth_date_id_by_instrument_type
    -- SO: 20240604 added checksum to avoid unnecessary record updates
    -- SO: 20260114 https://dashfinancial.atlassian.net/browse/DS-10567 added order_status
    -- SO: 20260114 https://dashfinancial.atlassian.net/browse/DS-10567 changed md5 calculation algorithm
declare
    l_row_cnt int4;
    l_load_id int8;
    l_step_id int4;
    l_date_id int4 := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::int4);

begin
--     perform pg_sleep(10);
    select nextval('public.load_timing_seq')
    into l_load_id;

    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    -- the list of orders with permanent attributes
    drop table if exists t_base;
    create temp table t_base as
    select cl.parent_order_id,
           min(ex.exec_id)                   as min_exec_id,
           max(ex.exec_id)                   as max_exec_id,
           min(cl.parent_order_process_time) as parent_order_process_time,
           min(ex.order_create_date_id)      as order_create_date_id,
           min(cl.create_date_id)            as create_date_id
    from dwh.execution ex
             join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
    where ex.exec_date_id = l_date_id
      and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
      and case when in_parent_order_ids is null then true else cl.parent_order_id = any (in_parent_order_ids) end
      and not ex.is_parent_level
--      and ex.is_busted <> 'Y'
      and ex.exec_type in ('F', '0', 'W')
      and cl.parent_order_id is not null
    group by cl.parent_order_id;


    get diagnostics l_row_cnt = row_count;
--     raise notice 't_base - %', l_row_cnt;

    select public.load_log(l_load_id, l_step_id, 't_base created', l_row_cnt, 'C')
    into l_step_id;


    analyze t_base;

    select public.load_log(l_load_id, l_step_id, 't_base Analyzed ', 0, 'A')
    into l_step_id;

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
           par.side                as side,
           exi.order_status
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
--                             and par.create_date_id = get_dateid(base.parent_order_process_time)
                             and par.create_date_id =
                                 public.get_gth_date_id_by_instrument_type(base.parent_order_process_time,
                                                                           di.instrument_type_id)
                           limit 1) par on true
             left join lateral (select order_status
                                from dwh.execution exi
                                where exi.order_id = base.parent_order_id
                                  and exi.exec_date_id = l_date_id
                                  and exi.order_status <> '3'
                                  and exi.exec_type in ('F', '0', 'W')
                                order by exec_id desc
                                limit 1) exi on true
    where true
      and par.parent_order_id is null;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_base_extended - %', l_row_cnt;
    select public.load_log(l_load_id, l_step_id, 't_base_ext created', l_row_cnt, 'C')
    into l_step_id;

    analyze t_base_ext;

    select public.load_log(l_load_id, l_step_id, 't_base_ext analyzed', 0, 'A')
    into l_step_id;

    -- new groupped by parent_order
    drop table if exists t_parent_orders;
    create temp table t_parent_orders as
    select bs.*,
           val.*,
           true as need_update
    from t_base_ext bs
             join lateral (select street_count, trade_count, last_qty, amount, street_order_qty
                           from data_marts.get_exec_for_parent_order(in_parent_order_id := bs.parent_order_id,
                                                                     in_date_id := l_date_id,
                                                                     in_min_exec_id := 0, --case when nup.need_update then 0 else bs.min_exec_id end,
                                                                     in_max_exec_id := bs.max_exec_id,
                                                                     in_order_create_date_id := bs.create_date_id
                                )
                           limit 1) val on true;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_street_orders create - %', l_row_cnt;
    select public.load_log(l_load_id, l_step_id, 't_parent_orders created', l_row_cnt, 'C')
    into l_step_id;

    create index on t_parent_orders (parent_order_id);

    select public.load_log(l_load_id, l_step_id, 't_parent_orders indexed', 0, 'I')
    into l_step_id;

    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           street_count, trade_count, last_qty, amount, street_order_qty,
                                           pg_db_create_time,
                                           order_qty,
                                           time_in_force_id, account_id, trading_firm_unq_id, instrument_id,
                                           instrument_type_id, side, check_sum, order_status)
    select tp.parent_order_id,
           tp.max_exec_id,
           tp.create_date_id,
           l_date_id,
           tp.street_count,
           tp.trade_count,
           tp.last_qty,
           tp.amount,
           tp.street_order_qty,
           clock_timestamp(),
           --
           tp.parent_order_qty,
           tp.time_in_force_id,
           tp.account_id,
           tp.trading_firm_unq_id,
           tp.instrument_id,
           tp.instrument_type_id,
           tp.side,
           md5(concat_ws('|', l_date_id, tp.max_exec_id, tp.street_count, tp.create_date_id, tp.trade_count,
                         tp.last_qty, tp.amount, tp.street_order_qty, tp.parent_order_qty, tp.instrument_id,
                         tp.order_status)),
           tp.order_status
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
            instrument_id     = excluded.instrument_id,
            check_sum         = excluded.check_sum,
            order_status      = excluded.order_status
    where data_marts.f_parent_order.check_sum is distinct from excluded.check_sum;
    get diagnostics l_row_cnt = row_count;
    --     raise notice 't_parent_orders insert - %', l_row_cnt;

--    select nextval('public.load_timing_seq') into l_load_id;
--    l_step_id := 1; -- Commented by SY 20240726
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' FINISHED ===', l_row_cnt, 'E')
    into l_step_id;

    return l_step_id;
end;
$function$
;
