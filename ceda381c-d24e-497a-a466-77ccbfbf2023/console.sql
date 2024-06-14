create schema monitoring;

drop table if exists monitoring.error_tracking;
create table monitoring.error_tracking
(
    error_tracking_id int8      not null
        constraint error_tracking_id_pk primary key generated by default as identity,
    db_host           text      not null,
    error_id          int4,
    error_text        text,
    db_create_time    timestamp not null default clock_timestamp(),
    db_process_time   timestamp
);
comment on table monitoring.error_tracking is 'the table for gathering errors from db';
comment on column monitoring.error_tracking.error_tracking_id is 'id';
comment on column monitoring.error_tracking.db_host is 'host of database';
comment on column monitoring.error_tracking.error_id is 'id of error inside the log file';
comment on column monitoring.error_tracking.error_text is 'Text of error';
comment on column monitoring.error_tracking.db_create_time is 'timestamp of creation event';
comment on column monitoring.error_tracking.db_process_time is 'timestamp where error was processed';

select * from monitoring.error_tracking
order by error_tracking_id desc;

create index error_tracking_db_process_time_idx on monitoring.error_tracking (db_process_time);
create index error_tracking_db_host_idx on monitoring.error_tracking (db_host);


alter table monitoring.error_tracking add column db_type text;
create index error_tracking_db_type_idx on monitoring.error_tracking (db_type);
select distinct(db_type) from monitoring.error_tracking;
update monitoring.error_tracking
set db_type = 'PROD'
where db_host != 'pgtest1.uat.dashops.net'
and db_type is null