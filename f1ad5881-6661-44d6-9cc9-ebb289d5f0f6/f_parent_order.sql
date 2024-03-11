drop table if exists data_marts.f_parent_order;
create table data_marts.f_parent_order
(
    parent_order_id     int8      not null,
    last_exec_id        int8,
    create_date_id      int4      not null,
    status_date_id      int4,
    time_in_force_id    bpchar(1),
    account_id          int4
        constraint f_parent_order_d_account_fk references dwh.d_account (account_id),
    trading_firm_unq_id int4
        constraint f_parent_order_d_trading_firm_fk references dwh.d_trading_firm (trading_firm_unq_id),
    instrument_id       int4
        constraint f_parent_order_d_instrument_fk references dwh.d_instrument (instrument_id),
    instrument_type_id  bpchar(1),
    street_count        int4,
    trade_count         int4,
    order_qty           int4,
    street_order_qty    int4, --sum order_qty streets
    last_qty            int8, -- sum last_qty exec
    amount              numeric, -- last_qty * price
    pg_db_create_time   timestamp not null default clock_timestamp(),
    pg_db_update_time   timestamp
--     process_time
);
alter table data_marts.f_parent_order set (fillfactor = 70);
alter table data_marts.f_parent_order add constraint f_parent_order_pk primary key (status_date_id, parent_order_id);

comment on table data_marts.f_parent_order is 'data mart for parent_orders incrementally updating during the market day';
comment on column data_marts.f_parent_order.parent_order_id is 'parent_order from dwh.client_order';
comment on column data_marts.f_parent_order.create_date_id is 'create_date_id for parent_order';
comment on column data_marts.f_parent_order.last_exec_id is 'last processed exec_id to info';
comment on column data_marts.f_parent_order.status_date_id is 'date_id of the day where parent_order was processed into the table. As sama as create_date_id for non GTC orders';
comment on column data_marts.f_parent_order.time_in_force_id is 'time_in_force_id of parent_order';
comment on column data_marts.f_parent_order.account_id is 'account_id of parent_order related to d_account';
comment on column data_marts.f_parent_order.trading_firm_unq_id is 'trading_firm_unq_id of parent_order related to d_trading_firm';
comment on column data_marts.f_parent_order.instrument_id is 'instrument_id of parent_order related to d_instrument';
comment on column data_marts.f_parent_order.instrument_type_id is 'instrument_type_id of parent_order';
comment on column data_marts.f_parent_order.pg_db_create_time is '';
comment on column data_marts.f_parent_order.pg_db_update_time is '';


create function data_marts.load_parent_order_inc(in_parent_order_ids bigint[] default null::bigint[],
                                                 in_date_id integer default null::integer,
                                                 in_load_id bigint default null::bigint)
    returns int4
    language plpgsql
as
$fn$
    -- SO: 20240307 https://dashfinancial.atlassian.net/browse/DS-8065
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

    -- the list of orders
    drop table if exists t_base;
    create temp table t_base as
    select order_id,
           min(exec_id) as min_exec_id,
           max(exec_id) as max_exec_id,
           count(*) as street_count,
           sum(case when exec_type = 'F' then 1 else 0 end) as trade_count,
           sum(last_qty) as last_qty,
           sum(last_qty * last_px)--, sum (case when tr)
    from dwh.execution
    where exec_date_id = 20240308--l_date_id
      and true                   -- it is a condition for subscriptions
    group by order_id;


    -- non gtc
    drop table if exists t_orders;
    create temp table t_orders as
    select bs.*, cl.parent_order_id, cl.create_date_id
    from t_base bs
             join lateral (select parent_order_id, create_date_id
                           from dwh.client_order cl
                           where cl.order_id = bs.order_id
                             and cl.create_date_id = 20240308--l_date_id
                             and cl.parent_order_id is not null
                           limit 1) cl on true;
    create index on t_orders (parent_order_id, order_id);

    insert into t_orders (order_id, min_exec_id, max_exec_id, cnt, sum, parent_order_id, create_date_id)
    select bs.*, cl.parent_order_id, cl.create_date_id
    from t_base bs
             join dwh.gtc_order_status gos using (order_id)
             join lateral (select parent_order_id, cl.create_date_id
                           from dwh.client_order cl
                           where cl.order_id = bs.order_id
                             and cl.create_date_id = gos.create_date_id
                             and cl.parent_order_id is not null
                           limit 1 ) cl on true;


    drop table if exists t_parent;
    create temp table t_parent as
    select parent_order_id,
           min(create_date_id) as create_date_id,
           min(min_exec_id)    as min_exec_id,
           max(max_exec_id)    as max_exec_id
    from t_orders tor
    group by parent_order_id;

    select * from data_marts.f_parent_order;
    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           time_in_force_id, account_id, trading_firm_unq_id, instrument_id,
                                           instrument_type_id, street_qty, trade_qty, order_qty, street_order_qty,
                                           last_qty, vwap)
    select parent_order_id,
           greatest(tp.max_exec_id, coalesce(fpr.last_exec_id, 0)),
           create_date_id,
           :l_date_id,
           null,                                                                   -- time_in_force_id
           null,                                                                   -- account_id
           null,                                                                   -- trading_firm_unq_id
           null,                                                                   -- instrument_id
           null,                                                                   -- instrument_type_id
           case when tp.min_exec_id > coalesce(fpr.last_exec_id, 0) then tp.cnt else -1000 end, -- the function that counts all data for parent order
           null,                                                                   -- trade_qty
           null,                                                                   -- order_qty
           null,                                                                   -- street_order_qty
           null,                                                                   -- last_qty
           null                                                                    -- vwap
    from t_parent tp
             left join data_marts.f_parent_order fpr using (parent_order_id, create_date_id)
    on conflict (parent_order_id) do update
    set street_qty = excluded.street_qty;

    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           time_in_force_id, account_id, trading_firm_unq_id, instrument_id,
                                           instrument_type_id, street_qty, trade_qty, order_qty, street_order_qty,
                                           last_qty, vwap)
    select parent_order_id,
           max(max_exec_id),    -- last_exec_id
           min(create_date_id), -- create_date_id
           :l_date_id,          -- status_date_id
           null,                -- time_in_force_id
           null,                -- account_id
           null,                -- trading_firm_unq_id
           null,                -- instrument_id
           null,                -- instrument_type_id
           sum(cnt),            -- street_qty
           null,                -- trade_qty
           null,                -- order_qty
           null,                -- street_order_qty
           null,                -- last_qty
           null                 -- vwap
    from t_orders tor
    group by parent_order_id
    on conflict (parent_order_id) do update
    set last_exec_id = excluded.last_exec_id,
        street_qty = case when t_orders.max(max_exec_id) > f_parent_order.last_exec_id then street_qty + excluded.street_qty else -1000 end;

--         select * from t_orders;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' FINISHED ===', 0, 'O')
    into l_step_id;
end;

$fn$;


select case when extract(epoch from pg_db_create_time - exec_time) > 50 then 'upd' else 'no' end, count(*)
from dwh.execution
where exec_date_id = 20240307
group by case when extract(epoch from pg_db_create_time - exec_time) > 50 then 'upd' else 'no' end


select * from fix_capture.fix_message_json where fix_message_id = 686046122


create temp table t_parent_order as
select
min(ex.exec_id) as min_exec_id,
max(ex.exec_id) as max_exec_id,
ex.order_id,
min(cl.parent_order_id) as parent_order_id,
count(*) as cnt
from dwh.execution ex
         join lateral (select parent_order_id
                       from dwh.client_order cl
                       where cl.order_id = ex.order_id
                         and cl.create_date_id <= ex.exec_date_id
                         and cl.parent_order_id is not null
                       limit 1 ) cl on true
where exec_date_id = 20240307
group by ex.order_id;

select * from t_parent_order

