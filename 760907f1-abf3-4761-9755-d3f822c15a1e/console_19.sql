drop table if exists monitoring.pg_error;
create table monitoring.pg_error
(
    pg_error_id    int4      not null
        constraint pg_error_id_pk primary key generated by default as identity,
    db_id          int4      not null,
    error_id       int4,
    error_text     text,
    db_create_time timestamp not null default clock_timestamp(),
    db_sent_time   timestamp
);
comment on table monitoring.pg_error is 'the table for gathering errors from db';
comment on column monitoring.pg_error.pg_error_id is 'id';
comment on column monitoring.pg_error.db_id is 'id of database: 1 - prod bigdata, 2 prod genesis2';
comment on column monitoring.pg_error.error_id is 'id of error inside the log file';
comment on column monitoring.pg_error.error_text is 'Text of error';
comment on column monitoring.pg_error.db_create_time is 'timestamp of creation event';
comment on column monitoring.pg_error.db_sent_time is 'timestamp where error was sent';

insert into monitoring.pg_error(db_id, error_text)
values (1, % s)