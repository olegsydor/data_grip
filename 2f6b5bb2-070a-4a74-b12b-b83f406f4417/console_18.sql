create schema blaze7_settings;

CREATE TABLE blaze7_settings.entity_cat_representative_defaults (
	entity_id int4 NOT NULL,
	created_by int4 NOT NULL,
	creation_time timestamptz DEFAULT now() NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	deleted_by int4 NULL,
	deleted_time timestamptz NULL,
	fdid varchar(200) NULL,
	account_holder_type bpchar(1) NULL
);
CREATE UNIQUE INDEX entity_cat_representative_defaults_idx ON blaze7_settings.entity_cat_representative_defaults USING btree (entity_id) WHERE (is_deleted = false);


