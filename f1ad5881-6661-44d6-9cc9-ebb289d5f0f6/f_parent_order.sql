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


create or replace function data_marts.load_parent_order_inc2(in_parent_order_ids bigint[] default null::bigint[],
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
    select cl.parent_order_id,
           min(create_date_id) as create_date_id, --??
           min(exec_id)        as min_exec_id,
           max(exec_id)        as max_exec_id
    from dwh.execution ex
             join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = l_date_id
    where exec_date_id = l_date_id
      and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
      and not is_parent_level
      and cl.parent_order_id is not null
    group by cl.parent_order_id;

    get diagnostics l_row_cnt = row_count;
    raise notice 't_base - %', l_row_cnt;

    -- new groupped by parent_order
    drop table if exists t_parent_orders;
    create temp table t_parent_orders as
    select bs.*,
           val.*,
           nup.need_update
    from t_base bs
             join lateral ( select case
                                       when exists (select null
                                                    from data_marts.f_parent_order fp
                                                    where fp.status_date_id = l_date_id
                                                      and fp.parent_order_id = bs.parent_order_id
                                                      and fp.last_exec_id >= bs.min_exec_id)
                                           then true
                                       else false end as need_update
        ) nup on true
             join lateral (select street_count, trade_count, last_qty, amount
                           from data_marts.get_exec_for_parent_order(in_parent_order_id := bs.parent_order_id,
                                                                     in_date_id := l_date_id,
                                                                     in_min_exec_id := case when nup.need_update then 0 else bs.min_exec_id end
                                )
                           limit 1) val on true;
    get diagnostics l_row_cnt = row_count;
    raise notice 't_street_orders create - %', l_row_cnt;
    create index on t_parent_orders (parent_order_id);

    get diagnostics l_row_cnt = row_count;
    raise notice 't_parent_orders insert - %', l_row_cnt;

    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           street_count, trade_count,
                                           last_qty, amount, pg_db_create_time)
    select tp.parent_order_id,
           tp.max_exec_id,
           tp.create_date_id,
           l_date_id,
           case when tp.need_update then tp.street_count else tp.street_count + coalesce(fp.street_count, 0) end,
           case when tp.need_update then tp.trade_count else tp.trade_count + coalesce(fp.trade_count, 0) end,
           case when tp.need_update then tp.last_qty else tp.last_qty + coalesce(fp.last_qty, 0) end,
           case when tp.need_update then tp.amount else tp.amount + coalesce(fp.amount, 0) end,
           clock_timestamp()
    from t_parent_orders tp
             left join data_marts.f_parent_order fp
                       on fp.parent_order_id = tp.parent_order_id and fp.status_date_id = l_date_id
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


select *
from data_marts.load_parent_order_inc2(in_date_id := 20240315), in_dataset_ids := '{36247850,36247951,36247960,36247970,36248211,36248284,36248371,36248380,36248518,36248536,36248595,36248613,36248673,36248693,36248772,36248841,36248859,36248927,36248971,36248986,36249005,36249039,36249054,36249108,36249123,36249318,36249330,36249351,36249442,36249460,36249497,36249513,36249565,36249590,36249692,36249701,36249750,36249768,36249929,36249957,36249965,36249982,36250032,36250050,36250168,36250188,36250460,36250476,36250658,36250668,36250684,36250756,36250766,36250781,36250823,36250841,36250901,36250925,36256028,36256042}');

create temp drop table t_01 as
select *--parent_order_id, last_exec_id, street_count, trade_count, last_qty, amount
from data_marts.f_parent_order
where status_date_id = 20240315

select * from t_04
except
select * from t_01;


delete from data_marts.f_parent_order
where status_date_id = 20240315;

select array_agg(dataset_id) from (select distinct dataset_id
                                    from dwh.execution
                                    where exec_date_id = 20240315
                                    limit 200 offset 0) x;

create or replace function data_marts.get_exec_for_parent_order(in_parent_order_id int8,
                                                                in_date_id int4 default to_char(current_date, 'YYYYMMDD')::int,
                                                                in_min_exec_id int8 default null)
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
        select --cl.parent_order_id,
               count(distinct ex.order_id)   as street_count,
               count(*)                      as trade_count,
               sum(ex.last_qty)              as last_qty,
               sum(ex.last_qty * ex.last_px) as amount
        --        ,min(ex.exec_id)               as min_exec_id,
--        max(ex.exec_id)               as max_exec_id
        from dwh.execution ex
                 join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = in_date_id
        where ex.exec_date_id = in_date_id
          and cl.parent_order_id = in_parent_order_id
          and ex.exec_id >= in_min_exec_id
          and ex.exec_type = 'F'
          and ex.is_busted = 'N'
        group by cl.parent_order_id;
end;
$fx$;

select * from data_marts.load_parent_order_inc(in_date_id := 20240307), in_dataset_ids := '{35848774,35848831,35848848,35848908,35848917,35848926,35848986,35848995,35849005,35849065,35849074,35849083,35849144,35849153,35849162,35849222,35849231,35849240,35849298,35849309}');
select * from data_marts.f_parent_order
where parent_order_id = 284701287;

-----
select count(distinct ex.order_id)   as street_count,
       count(*)                      as trade_count,
       sum(ex.last_qty)              as last_qty,
       sum(ex.last_qty * ex.last_px) as amount,
       min(ex.exec_id)               as min_exec_id,
       max(ex.exec_id)               as max_exec_id
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = :in_date_id
where ex.exec_date_id = :in_date_id
--   and ex.exec_id >= :in_min_exec_id
  and ex.exec_type = 'F'
  and ex.is_busted = 'N'
group by cl.parent_order_id;