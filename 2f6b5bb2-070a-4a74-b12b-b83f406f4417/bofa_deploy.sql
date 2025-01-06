create table genesis2.user_identifier
(
    user_id            int4         not null,
    acl_id             int4         null,
    user_name          varchar(30)  null,
    "password"         varchar(256) null,
    user_role          varchar(1)   not null,
    first_name         varchar(30)  null,
    last_name          varchar(100) null,
    email              varchar(60)  null,
    phone_num          varchar(20)  null,
    create_time        timestamp    not null,
    is_deleted         varchar(1)   not null,
    delete_time        timestamp    null,
    is_locked          varchar(1)   not null,
    is_logging_enabled varchar(1)   null,
    constraint user_identifier_pkey primary key (user_id)
);

-- drop table if exists dash_reporting.bofa_allocation_instruction_status;
create table if not exists dash_reporting.bofa_allocation_instruction_status
(
    alloc_instr_id int4                                not null, -- link to allocation instruction
    date_id        int4                                not null, -- link to date_id of allocation instruction
    claimed_by     int4                                null,     -- user id from genesis2.user_identifier
    claim_status   bpchar    default 'O'::bpchar       not null, -- status. 'O' - unclaimed (default & initial), 'C' - claimed, 'R' - resolved
    db_update_time timestamp default clock_timestamp() not null, -- create\last update time
    constraint bofa_allocation_instruction_status_pk primary key (alloc_instr_id),
    constraint bofa_allocation_instruction_status_user_identifier_fk foreign key (claimed_by) references genesis2.user_identifier (user_id)
);
comment on table dash_reporting.bofa_allocation_instruction_status is 'Table contains information on the current claim/resolve status on Allocation Instructions that are unreportable in BOFA report. Only Admins can change the satatus';

-- Column comments

comment on column dash_reporting.bofa_allocation_instruction_status.alloc_instr_id is 'link to allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.date_id is 'link to date_id of allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.claimed_by is 'user id from genesis2.user_identifier';
comment on column dash_reporting.bofa_allocation_instruction_status.claim_status is 'status. ''O'' - unclaimed (default & initial), ''C'' - claimed, ''R'' - resolved';
comment on column dash_reporting.bofa_allocation_instruction_status.db_update_time is 'create\last update time';


drop table if exists dash_reporting.bofa_allocation_report;
create table dash_reporting.bofa_allocation_report
(
    alloc_instr_id                int4                                null,
    side                          bpchar(1)                           null,
    avg_px                        numeric(14, 6)                      null,
    date_id                       int4                                null,
    open_close                    bpchar(1)                           null,
    alloc_qty                     int4                                null,
    opt_is_fix_clfirm_processed   bpchar(1)                           null,
    ftr_cmta                      varchar(3)                          null,
    ca_cmta                       varchar(3)                          null,
    opt_is_fix_custfirm_processed bpchar(1)                           null,
    opt_customer_firm             bpchar(1)                           null,
    opt_customer_or_firm          bpchar(1)                           null,
    occ_actionable_id             varchar(10)                         null,
    dataset                       int4                                null,
    to_report                     bpchar                              null,
    db_create_time                timestamp default clock_timestamp() not null,
    instrument_id                 int8                                null,
    opt_penny_commission          numeric(12, 4)                      null,
    opt_nickel_commission         numeric(12, 4)                      null,
    root_symbol                   varchar(10)                         null,
    min_tick_increment            numeric(12, 4)                      null,
    put_call                      bpchar(1)                           null,
    maturity_year                 int2                                null,
    maturity_month                int2                                null,
    maturity_day                  int2                                null,
    strike_price                  numeric(12, 4)                      null
);
create index bofa_allocation_report_alloc_instr_id_idx on dash_reporting.bofa_allocation_report using btree (alloc_instr_id);
create index bofa_allocation_report_date_id_idx on dash_reporting.bofa_allocation_report using btree (date_id);



-- dash_reporting.bofa_trade_record definition

-- Drop table

drop table if exists dash_reporting.bofa_trade_record;
create table if not exists dash_reporting.bofa_trade_record
(
    date_id         int4                                null,
    trade_record_id int8                                null,
    dataset         int4                                null,
    db_create_time  timestamp default clock_timestamp() not null
);
create index bofa_trade_record_trade_record_date_id_idx on dash_reporting.bofa_trade_record using btree (date_id, trade_record_id);


