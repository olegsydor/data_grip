-- https://dashfinancial.atlassian.net/browse/DS-11872
drop foreign table staging.v_lifecycle_order;

IMPORT FOREIGN SCHEMA blaze7 LIMIT TO (v_lifecycle_order)
FROM SERVER blaze7_uat
into staging

drop table if exists genesis2.blaze_lifecycle_order;
create table if not exists genesis2.blaze_lifecycle_order
(
    parent_order_id          int8        not null
        constraint blaze_lifecycle_order_pk primary key,
    lifecycle_orderid        int8        null,
    lifecycle_orderid_status char(1)     not null,
    last_exec_id             varchar(30) not null,
    db_create_time           timestamp default clock_timestamp(),
    db_update_time           timestamp
);
create index blaze_lifecycle_order_last_exec_id_idx on genesis2.blaze_lifecycle_order (last_exec_id);

create or replace function genesis2.load_blaze_lifecycle_order(in_last_exec_id varchar(30) default null)
    returns int4
    language plpgsql
as
$fn$
    -- 20260806 SO https://dashfinancial.atlassian.net/browse/DS-11870
declare
    l_last_exec_id varchar(30);
    l_row_cnt      int4;
begin
    select coalesce(in_last_exec_id, max(last_exec_id), '')
    into l_last_exec_id
    from genesis2.blaze_lifecycle_order;

    insert into genesis2.blaze_lifecycle_order (parent_order_id, lifecycle_orderid, lifecycle_orderid_status,
                                                last_exec_id)
    select order_id, lifecycle_orderid, lifecycle_orderid_status, exec_id
    from staging.v_lifecycle_order vl
    where exec_id > l_last_exec_id
    on conflict (parent_order_id)
        do update set lifecycle_orderid        = excluded.lifecycle_orderid,
                      lifecycle_orderid_status = excluded.lifecycle_orderid_status,
                      last_exec_id             = excluded.last_exec_id,
                      db_update_time           = clock_timestamp()
    where blaze_lifecycle_order.lifecycle_orderid is distinct from excluded.lifecycle_orderid
       or blaze_lifecycle_order.lifecycle_orderid_status != excluded.lifecycle_orderid_status
       or blaze_lifecycle_order.last_exec_id != excluded.last_exec_id;
    get diagnostics l_row_cnt = row_count;
    return l_row_cnt;
end;
$fn$;

select * from genesis2.load_blaze_lifecycle_order('');
select * from genesis2.load_blaze_lifecycle_order();


select * from genesis2.blaze_lifecycle_order
WHERE parent_order_id = 647855791876882432 AND lifecycle_orderid = 647855791876882432


select order_id, lifecycle_orderid, lifecycle_orderid_status, exec_id
from staging.v_lifecycle_order vl;