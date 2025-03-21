/*
create schema blaze7_settings;

create table blaze7_settings.entity_cat_representative_defaults
(
    entity_id           int4                      not null,
    created_by          int4                      not null,
    creation_time       timestamptz default now() not null,
    is_deleted          bool        default false not null,
    deleted_by          int4                      null,
    deleted_time        timestamptz               null,
    fdid                varchar(200)              null,
    account_holder_type bpchar(1)                 null
);
create unique index entity_cat_representative_defaults_idx on blaze7_settings.entity_cat_representative_defaults using btree (entity_id) where (is_deleted = false);
*/


INSERT INTO blaze7_settings.entity_cat_representative_defaults (entity_id, created_by, creation_time, is_deleted,
                                                                deleted_by, deleted_time, fdid, account_holder_type)
VALUES (1, 2034, '2025-03-16 06:08:26.826447-04', true, 2034, '2025-03-16 06:08:40.550923-04', 'string', '1'),
       (1, 2034, '2025-03-18 06:08:40.550923-04', false, NULL, NULL, 'string', '2');

select * from blaze7_settings.entity_cat_representative_defaults
         where true
             and (creation_time > :new_ts or deleted_time > :new_ts)
order by entity_id, case when is_deleted then 1 else 2 end, deleted_time;
