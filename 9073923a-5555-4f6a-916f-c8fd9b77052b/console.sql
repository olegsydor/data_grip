create schema so_hft;

create table so_hft.hft_fix_message_event
(
    date_id               int4         NULL,
    fix_date              varchar(32)  NULL,
    msg_type              varchar(3)   NULL,
    sub_system_id         varchar(32)  NULL,
    sender_comp_id        varchar(32)  NULL,
    target_comp_id        varchar(32)  NULL,
    account_name          varchar(32)  NULL,
    cl_ord_id             varchar(128) NULL,
    parent_cl_ord_id      varchar(128) NULL,
    secondary_ord_id      varchar(32)  NULL,
    exch_exec_id          varchar(128) NULL,
    sec_exch_exec_id      varchar(128) NULL,
    exch_ord_id           varchar(128) NULL,
    session_id            varchar(32)  NULL,
    orig_cl_ord_id        varchar(128) NULL,
    security_type         varchar(10)  NULL,
    leg_cfi_code          varchar(10)  NULL,
    fix_msg_json          jsonb        NULL,
    load_batch_id         int8         NULL,
    exec_type             varchar(8)   NULL,
    leg_ref_id            varchar(30)  NULL,
    alternative_cl_ord_id varchar(128) NULL
)
    partition by range (date_id);
create index so_hft_fix_message_event_clord_msgtype on only so_hft.hft_fix_message_event using btree (cl_ord_id, msg_type, exec_type) include (date_id, account_name);
create index so_hft_fix_message_event_date_orig_idx on only so_hft.hft_fix_message_event using btree (orig_cl_ord_id) include (msg_type, date_id, cl_ord_id);


create table partitions.so_hft_fix_message_event_20240115 partition of so_hft.hft_fix_message_event for values from (20240115) to (20240116);
create index on partitions.so_hft_fix_message_event_20240115 using btree (alternative_cl_ord_id);
create index on partitions.so_hft_fix_message_event_20240115 using btree (cl_ord_id, msg_type, exec_type) include (date_id, account_name);
create index on partitions.so_hft_fix_message_event_20240115 using btree (load_batch_id);
create index on partitions.so_hft_fix_message_event_20240115 using btree (orig_cl_ord_id) include (msg_type, date_id, cl_ord_id);