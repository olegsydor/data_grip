drop view if exists data_marts.v_mon_dash_trade;
drop table if exists data_marts.f_parent_order;
create table data_marts.f_parent_order
(
    parent_order_id     int8                                not null, -- parent_order from dwh.client_order
    last_exec_id        int8                                null,     -- last processed exec_id to info
    create_date_id      int4                                not null, -- create_date_id for parent_order
    status_date_id      int4                                not null, -- date_id of the day where parent_order was processed into the table. As sama as create_date_id for non GTC orders
    time_in_force_id    bpchar(1)                           null,     -- time_in_force_id of parent_order
    account_id          int4                                null,     -- account_id of parent_order related to d_account
    trading_firm_unq_id int4                                null,     -- trading_firm_unq_id of parent_order related to d_trading_firm
    instrument_id       int4                                null,     -- instrument_id of parent_order related to d_instrument
    instrument_type_id  bpchar(1)                           null,     -- instrument_type_id of parent_order
    street_count        int4                                null,
    trade_count         int4                                null,
    order_qty           int4                                null,
    street_order_qty    int4                                null,
    last_qty            int8                                null,
    amount              numeric                             null,
    pg_db_create_time   timestamp default clock_timestamp() not null,
    pg_db_update_time   timestamp                           null,
    side                bpchar(1)                           null,
    leaves_qty          int8                                null,
    constraint f_parent_order_pk primary key (status_date_id, parent_order_id),
    constraint f_parent_order_d_account_fk foreign key (account_id) references dwh.d_account (account_id),
    constraint f_parent_order_d_instrument_fk foreign key (instrument_id) references dwh.d_instrument (instrument_id)
)
    with (
        fillfactor = 50
        );
comment on table data_marts.f_parent_order is 'data mart for parent_orders incrementally updating during the market day';

comment on column data_marts.f_parent_order.parent_order_id is 'parent_order from dwh.client_order';
comment on column data_marts.f_parent_order.last_exec_id is 'last processed exec_id to info';
comment on column data_marts.f_parent_order.create_date_id is 'create_date_id for parent_order';
comment on column data_marts.f_parent_order.status_date_id is 'date_id of the day where parent_order was processed into the table. As sama as create_date_id for non GTC orders';
comment on column data_marts.f_parent_order.time_in_force_id is 'time_in_force_id of parent_order';
comment on column data_marts.f_parent_order.account_id is 'account_id of parent_order related to d_account';
comment on column data_marts.f_parent_order.trading_firm_unq_id iS 'trading_firm_unq_id of parent_order related to d_trading_firm';
comment on column data_marts.f_parent_order.instrument_id is 'instrument_id of parent_order related to d_instrument';
comment on column data_marts.f_parent_order.instrument_type_id is 'instrument_type_id of parent_order';


drop function if exists data_marts.get_exec_for_parent_order(int8, int4, int8, int8, int4);
create or replace function data_marts.get_exec_for_parent_order(in_parent_order_id bigint,
                                                                in_date_id integer default (to_char((current_date)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                                in_min_exec_id bigint default null::bigint,
                                                                in_max_exec_id bigint default null::bigint,
                                                                in_order_create_date_id int4 default null::int4)
    returns table
            (
                street_count     bigint,
                trade_count      bigint,
                last_qty         numeric,
                amount           numeric,
                street_order_qty integer,
                leaves_qty       numeric
            )
    language plpgsql
as
$function$
declare

begin
    return query
        select count(*)                                                                     as street_count,
               count(case when ex.exec_type = 'F' then 1 end)                               as trade_count,
               sum(case when ex.exec_type = 'F' then ex.last_qty else 0 end)                as last_qty,
               sum(case when ex.exec_type = 'F' then ex.last_qty * ex.last_px else 0 end)   as amount,
               sum(case when ex.exec_type in ('0', 'W') then ex.order_qty else 0 end)::int4 as street_order_qty,
               null::numeric                                                                as leaves_qty
        from (select distinct on (ex.order_id, ex.exec_id) cl.order_id,
                                                           cl.order_qty,
                                                           ex.exec_type,
                                                           ex.last_qty,
                                                           ex.last_px,
                                                           ex.leaves_qty
              from dwh.execution ex
                       join dwh.client_order cl
                            on cl.order_id = ex.order_id and cl.create_date_id = in_order_create_date_id
              where ex.exec_date_id = in_date_id
                and cl.parent_order_id = in_parent_order_id
                and ex.exec_id between in_min_exec_id and in_max_exec_id
                and ex.exec_type in ('F', '0', 'W')
                and cl.trans_type <> 'F'
                and ex.is_busted = 'N') ex;
end;
$function$
;

drop function if exists data_marts.load_parent_order_inc(_int8, int4, _int8);
create or replace function data_marts.load_parent_order_inc(in_parent_order_ids bigint[] default null::bigint[],
                                                            in_date_id integer default null::integer,
                                                            in_dataset_ids bigint[] default null::bigint[])
    returns integer
    language plpgsql
as
$function$
    -- SO: 20240307 https://dashfinancial.atlassian.net/browse/DS-8065
    -- SO: 20240424 removed leaves_qty
declare
    l_row_cnt int4;
    l_load_id int8;
    l_step_id int4;
    l_date_id int4 := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::int4);

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

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
      and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
      and case when in_parent_order_ids is null then true else cl.parent_order_id = any (in_parent_order_ids) end
      and not is_parent_level
      and ex.is_busted <> 'Y'
      and ex.exec_type in ('F', '0', 'W')
      and cl.parent_order_id is not null
    group by cl.parent_order_id;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_base - %', l_row_cnt;

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
           di.instrument_type_id   as instrument_type_id,
           par.trading_firm_unq_id as trading_firm_unq_id,
           par.order_qty           as parent_order_qty,
           par.side                as side
    --           ex.leaves_qty           as leaves_qty /* SY: we do not track cancels rejects etc. So we are not able to track leaves_qty correctly. Let's skip that field */
--            0                       as leaves_qty /* SO: aggree and confirmed with O.Semenchenko */
    from t_base base
             join lateral (select *
                           from dwh.client_order par
                           where par.order_id = base.parent_order_id
                             and par.parent_order_id is null
                             and par.create_date_id = get_dateid(base.parent_order_process_time)
                           /*SY should add and par.create_date_id = get_dateid(base.parent_order_process_time)*/
                           limit 1) par on true
             join dwh.d_instrument di on di.instrument_id = par.instrument_id and di.is_active

    where true
      and par.parent_order_id is null;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_base_extended - %', l_row_cnt;

    -- new groupped by parent_order
    drop table if exists t_parent_orders;
    create temp table t_parent_orders as
    select bs.*,
           val.*,
           true as need_update
    from t_base_ext bs
             join lateral (select true as need_update) nup on true
             join lateral (select street_count, trade_count, last_qty, amount, street_order_qty
                           from data_marts.get_exec_for_parent_order(in_parent_order_id := bs.parent_order_id,
                                                                     in_date_id := l_date_id,
                                                                     in_min_exec_id := 0, --case when nup.need_update then 0 else bs.min_exec_id end,
                                                                     in_max_exec_id := bs.max_exec_id,
                                                                     in_order_create_date_id := bs.order_create_date_id
                                )
                           limit 1) val on true;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_street_orders create - %', l_row_cnt;
    create index on t_parent_orders (parent_order_id);

    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           street_count, trade_count, last_qty, amount, street_order_qty,
                                           pg_db_create_time,
                                           order_qty,
                                           time_in_force_id, account_id, trading_firm_unq_id, instrument_id,
                                           instrument_type_id, side)
    select tp.parent_order_id,
           tp.max_exec_id,
           tp.create_date_id,
           l_date_id,
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
           tp.side
    from t_parent_orders tp
             left join data_marts.f_parent_order fp
                       on fp.parent_order_id = tp.parent_order_id and fp.status_date_id = l_date_id
    on conflict (status_date_id, parent_order_id) do update
        set last_exec_id      = excluded.last_exec_id,
            street_count      = excluded.street_count,
            trade_count       = excluded.trade_count,
            last_qty          = excluded.last_qty,
            amount            = excluded.amount,
            street_order_qty  = excluded.street_order_qty,
            pg_db_update_time = clock_timestamp();

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_parent_orders insert - %', l_row_cnt;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' FINISHED ===', l_row_cnt, 'E')
    into l_step_id;

    return l_row_cnt;
end;
$function$
;

drop function if exists data_marts.run_f_parent_order_process();
create or replace function data_marts.run_f_parent_order_process(in_limit int4 default 500)
    returns integer
    language plpgsql
as
$function$
    -- 2024-04-24 SO added processing diferent date_id from unprocessed subscriptions
    -- 2024-04-25 SY->SO fixed selecting date_id
declare

    l_row_cnt     int4 := 0;
    l_sum_row_cnt int4 := 0;
    scr           record;
    l_load_id     int;
    l_step_id     int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'run_f_parent_order_process STARTED ====', 0, 'O')
    into l_step_id;

    for scr in (select date_id, array_agg(load_batch_id) ids
                from (select date_id, load_batch_id
                      from public.etl_subscriptions
                      where source_table_name = 'execution'
                        and subscription_name = 'f_parent_order'
                        and not is_processed
                      order by load_batch_id
                      limit in_limit) l
                group by date_id)
        loop
            -- raise notice 'ids: %', scr.ids;
            perform data_marts.load_parent_order_inc(in_date_id := scr.date_id, in_dataset_ids := scr.ids);
            select public.load_log(l_load_id, l_step_id,
                                   'date_id: ' || scr.date_id::text || ', load_batch_ids: ' || scr.ids::text,
                                   array_length(scr.ids, 1),
                                   'O')
            into l_step_id;

            update public.etl_subscriptions
            set is_processed = true,
                process_time = clock_timestamp()
            where true
              and source_table_name = 'execution'
              and subscription_name = 'f_parent_order'
              and not is_processed
              and load_batch_id = any (scr.ids)
              and date_id = coalesce(scr.date_id, to_char(current_date, 'YYYYMMDD')::int4);

            get diagnostics l_row_cnt = row_count;
            l_sum_row_cnt = l_sum_row_cnt + l_row_cnt;

        end loop;
    select public.load_log(l_load_id, l_step_id, 'run_f_parent_order_process COMPLETED ====', l_sum_row_cnt, 'O')
    into l_step_id;
    return l_sum_row_cnt;
end;
$function$
;


-- data_marts.v_mon_dash_trade source

create or replace view data_marts.v_mon_dash_trade
as
select trading_firm_unq_id,
       account_id,
       sum(
               case
                   when instrument_type_id = 'E'::bpchar then noorderssent
                   else 0::bigint
                   end)     as eq_no_orders_sent,
       sum(
               case
                   when instrument_type_id = 'E'::bpchar then qtyopentobuy
                   else 0::numeric
                   end)     as eq_qty_open_to_buy,
       sum(
               case
                   when instrument_type_id = 'E'::bpchar then qtybought
                   else 0::numeric
                   end)     as eq_qty_bought,
       sum(
               case
                   when instrument_type_id = 'E'::bpchar then qtyopentosell
                   else 0::numeric
                   end)     as eq_qty_open_to_sell,
       sum(
               case
                   when instrument_type_id = 'E'::bpchar then qtysold
                   else 0::numeric
                   end)     as eq_qty_sold,
       sum(
               case
                   when instrument_type_id = 'E'::bpchar then streetorderssent
                   else 0::bigint
                   end)     as eq_street_qty,
       sum(
               case
                   when instrument_type_id = 'O'::bpchar then noorderssent
                   else 0::bigint
                   end)     as opt_no_orders_sent,
       sum(
               case
                   when instrument_type_id = 'O'::bpchar then qtyopentobuy
                   else 0::numeric
                   end)     as opt_qty_open_to_buy,
       sum(
               case
                   when instrument_type_id = 'O'::bpchar then qtybought
                   else 0::numeric
                   end)     as opt_qty_bought,
       sum(
               case
                   when instrument_type_id = 'O'::bpchar then qtyopentosell
                   else 0::numeric
                   end)     as opt_qty_open_to_sell,
       sum(
               case
                   when instrument_type_id = 'O'::bpchar then qtysold
                   else 0::numeric
                   end)     as opt_qty_sold,
       sum(
               case
                   when instrument_type_id = 'O'::bpchar then streetorderssent
                   else 0::bigint
                   end)     as opt_street_qty,
       max(last_trade_time) as last_trade_time
from (select t.account_id,
             t.instrument_type_id,
             t.trading_firm_unq_id,
             count(1)                                                as noorderssent,
             sum(
                     case
                         when t.side = '1'::bpchar then t.leaves_qty
                         else 0::bigint
                         end)                                        as qtyopentobuy,
             sum(
                     case
                         when t.side = '1'::bpchar then t.last_qty
                         else 0::bigint
                         end)                                        as qtybought,
             sum(
                     case
                         when t.side <> '1'::bpchar then t.leaves_qty
                         else 0::bigint
                         end)                                        as qtyopentosell,
             sum(
                     case
                         when t.side <> '1'::bpchar then t.last_qty
                         else 0::bigint
                         end)                                        as qtysold,
             sum(t.street_count)                                     as streetorderssent,
             max(coalesce(t.pg_db_update_time, t.pg_db_create_time)) as last_trade_time
      from (select f_parent_order.account_id,
                   f_parent_order.trading_firm_unq_id,
                   f_parent_order.instrument_type_id,
                   f_parent_order.street_count,
                   f_parent_order.last_qty,
                   f_parent_order.pg_db_create_time,
                   f_parent_order.pg_db_update_time,
                   f_parent_order.side,
                   f_parent_order.leaves_qty
            from data_marts.f_parent_order
            where f_parent_order.status_date_id =
                  to_char(current_date::timestamp with time zone, 'YYYYMMDD'::text)::integer) t
      group by t.account_id, t.instrument_type_id, t.trading_firm_unq_id) x
group by trading_firm_unq_id, account_id;


select * from data_marts.run_f_parent_order_process(30);


select * from public.etl_subscriptions
    where load_batch_id = 207082399;