call staging.cleanup_event_eod(in_dry_run:=false);
create or replace procedure staging.cleanup_event_eod(
    in_dry_run boolean default true
)
language plpgsql
as
$function$
declare
    l_rec           record;
    l_metrics_match boolean;
    l_pair_cnt      integer;
    l_checked_cnt   integer := 0;
    l_skipped_cnt   integer := 0;
    l_deleted_cnt   integer := 0;
    l_eligible_cnt  integer := 0;
begin
    if in_dry_run is null then
        raise exception 'in_dry_run cannot be null';
    end if;

    -- Prevent concurrent cleanup executions.
    if not pg_try_advisory_xact_lock(
            hashtextextended('staging.cleanup_event_eod', 0)
           ) then
        raise notice 'Another cleanup is already running';
        return;
    end if;

    -- Process all tables except the latest one.
    for l_rec in
        select c.relname                                      as table_name,
               n.nspname                                      as schema_name,
               substring(c.relname from 23 for 8)::numeric(8) as date_id
        from pg_catalog.pg_class c
                 join pg_catalog.pg_namespace n
                      on n.oid = c.relnamespace
        where n.nspname = 'partitions'
          and c.relkind in ('r', 'p')
          and c.relname ~ '^hft_fix_message_event_[0-9]{8}_eod$'
        order by c.relname desc
        offset 2
        loop
            l_checked_cnt := l_checked_cnt + 1;
            -- compare eod and inc metrics.
            select count(*),
                   bool_and(
                           e.metric_cnt_rows is not distinct from i.metric_cnt_rows
                               and e.metric_value_01 is not distinct from i.metric_value_01
                               and e.metric_value_02 is not distinct from i.metric_value_02
                               and e.metric_value_03 is not distinct from i.metric_value_03
                   )
            into l_pair_cnt,
                l_metrics_match
            from staging.sync_test_calculated_metrics e
                     join staging.sync_test_calculated_metrics i
                          on i.date_id = e.date_id
                              and i.table_name = e.table_name
                              and i.source_name = 'CAT_INC'
            where e.source_name = 'CAT_EOD'
              and e.date_id = l_rec.date_id;

            if l_pair_cnt <> 1 then
                raise notice '%: SKIP. Expected 1 metric pair, found %',
                    l_rec.table_name,
                    l_pair_cnt;

                l_skipped_cnt := l_skipped_cnt + 1;
                continue;
            end if;

            if l_metrics_match is not true then
                raise notice '%: SKIP. Metrics mismatch',
                    l_rec.table_name;

                l_skipped_cnt := l_skipped_cnt + 1;
                continue;
            end if;

            l_eligible_cnt := l_eligible_cnt + 1;

            if in_dry_run then
                raise notice 'DRY RUN. Would drop table: %',
                    l_rec.table_name;
            else
                execute format(
                        'DROP TABLE IF EXISTS %I.%I',
                        l_rec.schema_name,
                        l_rec.table_name
                        );

                l_deleted_cnt := l_deleted_cnt + 1;

                raise notice '%: DROPPED',
                    l_rec.table_name;
            end if;
        end loop;

    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'Tables checked  : %', l_checked_cnt;
    RAISE NOTICE 'Tables skipped  : %', l_skipped_cnt;
    RAISE NOTICE 'Tables eligible : %', l_eligible_cnt;
    RAISE NOTICE 'Tables dropped  : %', l_deleted_cnt;
    RAISE NOTICE '----------------------------------------';

END;
$function$
    SET lock_timeout = '5s';

CREATE TABLE partitions.hft_fix_message_event_20261124_eod (
	date_id int4 NULL,
	fix_date varchar(32) NULL,
	msg_type varchar(3) NULL,
	sub_system_id varchar(32) NULL,
	sender_comp_id varchar(32) NULL,
	target_comp_id varchar(32) NULL,
	account_name varchar(32) NULL,
	cl_ord_id varchar(128) NULL,
	parent_cl_ord_id varchar(128) NULL,
	secondary_ord_id varchar(32) NULL,
	exch_exec_id varchar(128) NULL,
	sec_exch_exec_id varchar(128) NULL,
	exch_ord_id varchar(128) NULL,
	session_id varchar(32) NULL,
	orig_cl_ord_id varchar(128) NULL,
	security_type varchar(10) NULL,
	leg_cfi_code varchar(10) NULL,
	fix_msg_json jsonb NULL,
	load_batch_id int8 NULL,
	exec_type varchar(8) NULL,
	leg_ref_id varchar(30) NULL,
	alternative_cl_ord_id varchar(128) NULL
);
CREATE TABLE partitions.hft_fix_message_event_20261123_eod (
	date_id int4 NULL,
	fix_date varchar(32) NULL,
	msg_type varchar(3) NULL,
	sub_system_id varchar(32) NULL,
	sender_comp_id varchar(32) NULL,
	target_comp_id varchar(32) NULL,
	account_name varchar(32) NULL,
	cl_ord_id varchar(128) NULL,
	parent_cl_ord_id varchar(128) NULL,
	secondary_ord_id varchar(32) NULL,
	exch_exec_id varchar(128) NULL,
	sec_exch_exec_id varchar(128) NULL,
	exch_ord_id varchar(128) NULL,
	session_id varchar(32) NULL,
	orig_cl_ord_id varchar(128) NULL,
	security_type varchar(10) NULL,
	leg_cfi_code varchar(10) NULL,
	fix_msg_json jsonb NULL,
	load_batch_id int8 NULL,
	exec_type varchar(8) NULL,
	leg_ref_id varchar(30) NULL,
	alternative_cl_ord_id varchar(128) NULL
);
CREATE TABLE partitions.hft_fix_message_event_20261120_eod (
	date_id int4 NULL,
	fix_date varchar(32) NULL,
	msg_type varchar(3) NULL,
	sub_system_id varchar(32) NULL,
	sender_comp_id varchar(32) NULL,
	target_comp_id varchar(32) NULL,
	account_name varchar(32) NULL,
	cl_ord_id varchar(128) NULL,
	parent_cl_ord_id varchar(128) NULL,
	secondary_ord_id varchar(32) NULL,
	exch_exec_id varchar(128) NULL,
	sec_exch_exec_id varchar(128) NULL,
	exch_ord_id varchar(128) NULL,
	session_id varchar(32) NULL,
	orig_cl_ord_id varchar(128) NULL,
	security_type varchar(10) NULL,
	leg_cfi_code varchar(10) NULL,
	fix_msg_json jsonb NULL,
	load_batch_id int8 NULL,
	exec_type varchar(8) NULL,
	leg_ref_id varchar(30) NULL,
	alternative_cl_ord_id varchar(128) NULL
);

alter TABLE partitions.hft_fix_message_event_20261122_eod rename to hft_fix_message_event_20261120_eod


