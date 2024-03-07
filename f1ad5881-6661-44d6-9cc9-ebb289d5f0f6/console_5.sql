create table data_marts.f_parent_order
(
    parent_order_id     int8      not null
        constraint f_parent_order_parent_order_id primary key,
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
    street_qty          int4,
    trade_qty           int4,
    order_qty           int4,
    street_order_qty    int4,
    last_qty            int8,
    vwap                numeric,
    pg_db_create_time   timestamp not null default clock_timestamp(),
    pg_db_update_time   timestamp
--     process_time
);
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
comment on column data_marts.f_parent_order.street_qty is 'total anount of streets';
comment on column data_marts.f_parent_order.trade_qty is 'total anount of trades';
comment on column data_marts.f_parent_order.order_qty is '';
comment on column data_marts.f_parent_order.street_order_qty is '';
comment on column data_marts.f_parent_order.last_qty is '';
comment on column data_marts.f_parent_order.vwap is '';
comment on column data_marts.f_parent_order.pg_db_create_time is '';
comment on column data_marts.f_parent_order.pg_db_update_time is '';


create function data_marts.load_parent_order_inc(in_parent_order_ids bigint[] default null::bigint[],
                                                 in_date_id integer default null::integer,
                                                 in_load_id bigint default null::bigint)
returns int4
language plpgsql
as $fn$
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
                               'load_parent_order_inc for ' || l_date_id::text || ' STARTED===', 0, 'O')
        into l_step_id;

    end;

    $fn$;


select case when extract(epoch from pg_db_create_time - exec_time) > 50 then 'upd' else 'no' end, count(*)
from dwh.execution
where exec_date_id = 20240307
group by case when extract(epoch from pg_db_create_time - exec_time) > 50 then 'upd' else 'no' end


select * from fix_capture.fix_message_json where fix_message_id = 686046122