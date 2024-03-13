select array_agg(id)
from (select distinct dataset_id as id
      from dwh.execution
      where exec_date_id = 20240308
      order by 1
      limit 20 offset 150) x

select * from data_marts.f_parent_order;

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


create or replace function data_marts.load_parent_order_inc(in_parent_order_ids bigint[] default null::bigint[],
                                                            in_date_id integer default null::integer,
                                                            in_dataset_ids bigint[] default null::bigint[])
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
           min(exec_id)                                     as min_exec_id,
           max(exec_id)                                     as max_exec_id,
           count(*)                                         as street_count,
           sum(case when exec_type = 'F' then 1 else 0 end) as trade_count,
           sum(last_qty)                                    as last_qty,
           sum(last_qty * last_px)                          as amount
    from dwh.execution
    where exec_date_id = l_date_id
      and case when in_dataset_ids is null then true else dataset_id = any (in_dataset_ids) end
    group by order_id;
    get diagnostics l_row_cnt = row_count;
    raise notice 't_base - %', l_row_cnt;


    -- non gtc
    drop table if exists t_orders;
    create temp table t_orders as
    select bs.*, cl.parent_order_id, cl.create_date_id
    from t_base bs
             join lateral (select parent_order_id, create_date_id
                           from dwh.client_order cl
                           where cl.order_id = bs.order_id
                             and cl.create_date_id = l_date_id
                             and cl.parent_order_id is not null
                           limit 1) cl on true;
    get diagnostics l_row_cnt = row_count;
    raise notice 't_orders create - %', l_row_cnt;
    create index on t_orders (parent_order_id, order_id);

    -- gtc
    insert into t_orders (order_id, min_exec_id, max_exec_id, street_count, trade_count, last_qty, amount,
                          parent_order_id, create_date_id)
    select bs.*, cl.parent_order_id, cl.create_date_id
    from t_base bs
             join dwh.gtc_order_status gos using (order_id)
             join lateral (select parent_order_id, cl.create_date_id
                           from dwh.client_order cl
                           where cl.order_id = bs.order_id
                             and cl.create_date_id = gos.create_date_id
                             and cl.parent_order_id is not null
                           limit 1 ) cl on true;
    get diagnostics l_row_cnt = row_count;
    raise notice 't_orders insert - %', l_row_cnt;


    drop table if exists t_parent;
    create temp table t_parent as
    select parent_order_id,
           min(create_date_id) as create_date_id,
           min(min_exec_id)    as min_exec_id,
           max(max_exec_id)    as max_exec_id,
           sum(street_count)   as street_count,
           sum(trade_count)    as trade_count,
           sum(last_qty)       as last_qty,
           sum(amount)         as amount
    from t_orders tor
    group by parent_order_id;
    get diagnostics l_row_cnt = row_count;
    raise notice 't_parent insert - %', l_row_cnt;
--     select * from data_marts.f_parent_order;
    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           street_count, trade_count,
                                           last_qty, amount, pg_db_create_time)
    select pn.parent_order_id,
           pn.max_exec_id,
           pn.create_date_id,
           l_date_id,
           case
               when coalesce(pn.min_exec_id > pb.last_exec_id, true) then pn.street_count + coalesce(pb.street_count, 0)
               else full_ord.street_count end as street_count,
           case
               when coalesce(pn.min_exec_id > pb.last_exec_id, true) then pn.trade_count + coalesce(pb.trade_count, 0)
               else full_ord.trade_count end  as trade_count,
           case
               when coalesce(pn.min_exec_id > pb.last_exec_id, true) then pn.last_qty + coalesce(pb.last_qty, 0)
               else full_ord.last_qty end     as last_qty,
           case
               when coalesce(pn.min_exec_id > pb.last_exec_id, true) then pn.amount + coalesce(pb.amount, 0)
               else full_ord.amount end       as amount,
           clock_timestamp()
    from t_parent as pn -- parents new
             left join data_marts.f_parent_order pb -- parents base
                       on pb.parent_order_id = pn.parent_order_id and pb.status_date_id = l_date_id --l_date_id
             left join lateral (select *
                                from data_marts.get_data_for_parent_order(pn.parent_order_id, l_date_id)
                                where pb.last_exec_id > pn.min_exec_id) full_ord on true
    on conflict (status_date_id, parent_order_id) do update
        set last_exec_id      = excluded.last_exec_id,
            street_count      = excluded.street_count,
            trade_count       = excluded.trade_count,
            last_qty          = excluded.last_qty,
            amount            = excluded.amount,
            pg_db_update_time = clock_timestamp();

    get diagnostics l_row_cnt = row_count;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' FINISHED ===', l_row_cnt, 'E')
    into l_step_id;

    return l_row_cnt;
end;
$fn$;


select case when extract(epoch from pg_db_create_time - exec_time) > 50 then 'upd' else 'no' end, count(*)
from dwh.execution
where exec_date_id = 20240307
group by case when extract(epoch from pg_db_create_time - exec_time) > 50 then 'upd' else 'no' end


select * from fix_capture.fix_message_json where fix_message_id = 686046122

create or replace function data_marts.get_data_for_parent_order(in_parent_order_id int8,
                                                                in_date_id int4 default to_char(current_date, 'YYYYMMDD')::int)
    returns table
            (
                street_count int8,
                trade_count  int8,
                last_qty     numeric,
                amount       numeric
            )
    language plpgsql
as
$fx$
declare

begin
    return query
        select count(*)                                            as street_count,
               sum(case when ex.exec_type = 'F' then 1 else 0 end) as trade_count,
               sum(ex.last_qty)                                    as last_qty,
               sum(ex.last_qty * ex.last_px)                       as amount
        from dwh.client_order cl
                 join dwh.execution ex on ex.order_id = cl.order_id
        where ex.exec_date_id = in_date_id
          and cl.parent_order_id = in_parent_order_id
        group by cl.parent_order_id;
end;
$fx$;

select * from data_marts.load_parent_order_inc(in_date_id := 20240307), in_dataset_ids := '{35848774,35848831,35848848,35848908,35848917,35848926,35848986,35848995,35849005,35849065,35849074,35849083,35849144,35849153,35849162,35849222,35849231,35849240,35849298,35849309}');
select * from data_marts.f_parent_order
where parent_order_id = 284701287;