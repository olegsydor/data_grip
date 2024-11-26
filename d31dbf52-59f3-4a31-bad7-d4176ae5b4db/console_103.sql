create table data_marts.f_parent_order_new
(
    parent_order_id     int8                                not null,
    last_exec_id        int8                                null,
    create_date_id      int4                                not null,
    status_date_id      int4                                not null,
    time_in_force_id    bpchar(1)                           null,
    account_id          int4                                null,
    trading_firm_unq_id int4                                null,
    instrument_id       int4                                null,
    instrument_type_id  bpchar(1)                           null,
    street_count        int4                                null,
    trade_count         int4                                null,
    order_qty           int4                                null,
    street_order_qty    int4                                null,
    last_qty            int8                                null,
    amount              numeric                             null,
    pg_db_create_time   timestamp DEFAULT clock_timestamp() not null,
    pg_db_update_time   timestamp                           null,
    side                bpchar(1)                           null,
    leaves_qty          int8                                null,
    check_sum           text                                null,
    constraint f_parent_order_new_pk primary key (status_date_id, parent_order_id)
)
    partition by range (status_date_id);

comment on table data_marts.f_parent_order_new IS 'data mart for parent_orders incrementally updating during the market day';

-- Column comments

comment on column data_marts.f_parent_order_new.parent_order_id is 'parent_order from dwh.client_order';
comment on column data_marts.f_parent_order_new.last_exec_id is 'last processed exec_id to info';
comment on column data_marts.f_parent_order_new.create_date_id is 'create_date_id for parent_order';
comment on column data_marts.f_parent_order_new.status_date_id is 'date_id of the day where parent_order was processed into the table. As sama as create_date_id for non GTC orders';
comment on column data_marts.f_parent_order_new.time_in_force_id is 'time_in_force_id of parent_order';
comment on column data_marts.f_parent_order_new.account_id is 'account_id of parent_order related to d_account';
comment on column data_marts.f_parent_order_new.trading_firm_unq_id is 'trading_firm_unq_id of parent_order related to d_trading_firm';
comment on column data_marts.f_parent_order_new.instrument_id is 'instrument_id of parent_order related to d_instrument';
comment on column data_marts.f_parent_order_new.instrument_type_id is 'instrument_type_id of parent_order';

create table partitions.f_parent_order_new_202404 partition of data_marts.f_parent_order_new for values from (20240401) to (20240501)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202405 partition of data_marts.f_parent_order_new for values from (20240501) to (20240601)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202406 partition of data_marts.f_parent_order_new for values from (20240601) to (20240701)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202407 partition of data_marts.f_parent_order_new for values from (20240701) to (20240801)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202408 partition of data_marts.f_parent_order_new for values from (20240801) to (20240901)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202409 partition of data_marts.f_parent_order_new for values from (20240901) to (20241001)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202410 partition of data_marts.f_parent_order_new for values from (20241001) to (20241101)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202411 partition of data_marts.f_parent_order_new for values from (20241101) to (20241201)
    with ( fillfactor = 50);
create table partitions.f_parent_order_new_202412 partition of data_marts.f_parent_order_new for values from (20241201) to (20250101)
    with ( fillfactor = 50);

-- here is sh for copying

-- alter table data_marts.f_parent_order add constraint f_parent_order_d_account_fk foreign key (account_id) references dwh.d_account (account_id);
-- alter table data_marts.f_parent_order add constraint f_parent_order_d_instrument_fk foreign key (instrument_id) references dwh.d_instrument (instrument_id);

-- run db_management

insert into db_management.table_partman
(schema_name, table_name, part_schema_name, part_type, part_schedule, is_active, part_priority)
values ('data_marts', 'f_parent_order', 'partitions', 'int', 'MONTH', false, 99);