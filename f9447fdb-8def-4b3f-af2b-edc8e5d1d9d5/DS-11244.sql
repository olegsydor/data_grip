-- genesis2.alloc_drop_message_status definition

-- Drop table

-- DROP TABLE genesis2.ptm_alloc_drop_message_status;

create table genesis2.ptm_alloc_drop_message_status
(
    ptm_drop_message_status_id int4                                NOT NULL
        constraint ptm_alloc_drop_message_status_Pk primary key DEFAULT nextval('genesis2.alloc_drop_message_status_drop_message_status_id_seq'), -- PK auto incremental column
    db_create_time             timestamp DEFAULT clock_timestamp() NOT NULL,                                                                      -- Created time
    msg_type                   bpchar    DEFAULT 'N'::bpchar       NOT NULL,                                                                      -- Message type. N - New - default, C - Cancel
    msg_status                 bpchar    DEFAULT 'N'::bpchar       NOT NULL,                                                                      -- N - new, S - sent, A - accepted, R - rejected, P - partial accepted, I - internally rejected
    reject_reason              text                                NULL,
    orig_trade_record_id       int8                                NULL
);
create index ptm_alloc_drop_message_status_orig_trade_record_id_msg_type_idx on genesis2.ptm_alloc_drop_message_status using btree (orig_trade_record_id, msg_type);
comment on table genesis2.ptm_alloc_drop_message_status IS 'Stores PTM 35=J NEW and CANCEL lifecycle statuses linked to CI/CIE/trade lineage.';


comment on column genesis2.ptm_alloc_drop_message_status.ptm_drop_message_status_id is 'PK auto incremental column';
comment on column genesis2.ptm_alloc_drop_message_status.db_create_time is 'Created time';
comment on column genesis2.ptm_alloc_drop_message_status.msg_type is 'Message type. N - New - default, C - Cancel';
comment on column genesis2.ptm_alloc_drop_message_status.msg_status is 'N - new, S - sent, A - accepted, R - rejected, P - partial accepted, I - internally rejected';
comment on column genesis2.ptm_alloc_drop_message_status.reject_reason is 'Reject reason';
comment on column genesis2.ptm_alloc_drop_message_status.orig_trade_record_id is 'Linked orig trade_record_id';


-- DROP FUNCTION dash360.ptm_alloc_drop_message_status_init(int8, bpchar);
create function dash360.ptm_alloc_drop_message_status_init(in_orig_trade_record_id bigint, in_msg_type character)
    returns integer
    language plpgsql
as
$fn$
declare
    l_ptm_drop_message_status_id int4;
begin
    if in_msg_type in ('N', 'C') and not exists (select null
                                                 from genesis2.ptm_alloc_drop_message_status
                                                 where orig_trade_record_id = in_orig_trade_record_id
                                                   and msg_type = in_msg_type) then
        insert into genesis2.ptm_alloc_drop_message_status(orig_trade_record_id, msg_type)
        values (in_orig_trade_record_id, in_msg_type)
        returning ptm_drop_message_status_id into l_ptm_drop_message_status_id;
    else
        l_ptm_drop_message_status_id := -1;
    end if;
    return l_ptm_drop_message_status_id;
end;
$fn$
;
comment on function dash360.ptm_alloc_drop_message_status_init(int8, bpchar) is 'Insert data into ptm_alloc_drop_message_status';


-- DROP FUNCTION dash360.ptm_alloc_drop_message_status_update(int4, bpchar, text);

create function dash360.ptm_alloc_drop_message_status_update(in_ptm_drop_message_status_id integer,
                                                             in_msg_status character, in_reject_reason text)
    returns integer
    language plpgsql
as
$function$
declare
    l_ptm_drop_message_status_id int4;
begin
    update genesis2.ptm_alloc_drop_message_status adms
    set msg_status    = in_msg_status,
        reject_reason = in_reject_reason
    where adms.ptm_drop_message_status_id = in_ptm_drop_message_status_id
    returning in_ptm_drop_message_status_id into l_ptm_drop_message_status_id;

    return l_ptm_drop_message_status_id;
end;
$function$
;