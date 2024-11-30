select * from public.load_timing;

select nextval('load_timing_seq'::regclass);

select * from db_management.table_partman;

create schema if not exists db_management;

create table if not exists db_management.table_partman
(
    schema_name      varchar(255) not null,
    table_name       varchar(255) not null,
    part_schema_name varchar(255) null,
    part_type        varchar(10)  not null,
    part_schedule    varchar(10)  not null,
    is_active        bool         not null,
    constraint table_partman_pkey primary key (schema_name, table_name, is_active)
);
alter table db_management.table_partman add column part_priority int2 default 99 not null;

CREATE TABLE db_management.table_retention
(
    schema_name      varchar(255) NOT NULL,
    table_name       varchar(255) NOT NULL,
    retention_period int4         NOT NULL,
    cleanup_schedule varchar(20)  NULL,
    key_field        varchar(30)  NULL,
    is_active        bool         NOT NULL,
    clean_order      int4         NULL, -- cleanup order. To avoid FK issue
    retention_type   bpchar       NULL, -- 'M' - move to tail, 'D' - delete
    roll_off_order   int4         NULL,
    file_location    varchar(100) NULL,
    file_mask        varchar(100) NULL,
    constraint table_retention_check check (((cleanup_schedule)::text = any
                                             (array [('DAY'::character varying)::text, ('MONTH'::character varying)::text, ('YEAR'::character varying)::text]))),
    constraint table_retention_pk primary key (schema_name, table_name, is_active)
);
comment on column db_management.table_retention.clean_order is 'cleanup order. To avoid FK issue';
comment on column db_management.table_retention.retention_type is '''M'' - move to tail, ''D'' - delete';


create table if not exists db_management.table_retention
(
    schema_name      varchar(255) null,
    table_name       varchar(255) null,
    retention_period int4         null,
    cleanup_schedule varchar(20)  null,
    key_field        varchar(30)  null,
    is_active        bool         null,
    retention_type   bpchar       null -- 'M' - move to tail, 'd' - delete
);
-- Column comments
comment on column db_management.table_retention.retention_type is '''M'' - move to tail, ''D'' - delete';

alter table db_management.table_retention add column if not exists roll_off_order int4 null;


CREATE OR REPLACE FUNCTION db_management.db_cleanup_table_trigger_part(in_schema_name character varying,
                                                                       in_table_name character varying,
                                                                       in_load_timing_id integer DEFAULT nextval('load_timing_seq'::regclass))
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
declare
    partition_cnt   int;
    l_load_id       int ;
    l_step_id       int;
    l_table_name    varchar;
    l_schema_name   varchar;
    l_limit_date_id int;
    l_sql           text;
    part            record;
begin
    partition_cnt := 0;
    if in_load_timing_id is null
    then
        select nextval('load_timing_seq') into l_load_id;
        l_step_id := 1;
        select public.load_log(l_load_id, l_step_id,
                               'DB_CLEANUP_TABLE FOR ' || in_schema_name || '.' || in_table_name || ' STARTED===', 0,
                               'O')
        into l_step_id;
    else
        l_load_id := in_load_timing_id;
        select coalesce(max(step), 0) + 1
        into l_step_id
        from public.load_timing
        where load_timing_id = in_load_timing_id;
    end if;
    select schema_name,
           table_name,
           to_char(date_trunc(cleanup_schedule,
                              (current_date - CAST(retention_period || ' ' || cleanup_schedule AS Interval))),
                   'YYYYMMDD')::int as date_id
    into l_schema_name, l_table_name, l_limit_date_id
    from db_management.table_retention
    where table_name = in_table_name
      and schema_name = in_schema_name
      and is_active
      and retention_type = 'D';
    create temp table obsolete_partitions
    (
        schema_name varchar(255),
        table_name  varchar(255)
    );
    with cte as
             (select cn.nspname                                          as child_schema,
                     c.relname                                           as child_table,
                     cast(regexp_replace(coalesce(substring(c.relname, length(c.relname) - 8 + 1, 8), '99999999'),
                                         '[^0-9]+', '', 'g') as integer) as date_id
              --pn.nspname as parent_schema, p.relname as parent_table
              from pg_inherits
                       join pg_class as c on (inhrelid = c.oid)
                       join pg_class as p on (inhparent = p.oid)
                       join pg_namespace pn on pn.oid = p.relnamespace
                       join pg_namespace cn on cn.oid = c.relnamespace
              where p.relname = l_table_name
                and pn.nspname = l_schema_name)
    insert
    into obsolete_partitions (schema_name, table_name)
    --if daily partitions
    select child_schema, child_table
    from cte
    where date_id < l_limit_date_id
      and date_id between 10000000 and 99999999
    union all
    --if monthly partitions
    select child_schema, child_table
    from cte
    where date_id < l_limit_date_id / 100
      and date_id between 100000 and 999999;
    for part in (select schema_name, table_name from obsolete_partitions)
        loop
            l_sql := 'drop table ' || part.schema_name || '.' || part.table_name || ';';
            execute l_sql;
            select load_log(l_load_id, l_step_id,
                            'Partition ' || part.schema_name || '.' || part.table_name || ' has been dropped', 0, 'D')
            into l_step_id;
            partition_cnt := partition_cnt + 1;
        end loop;
    drop table obsolete_partitions;
    if in_load_timing_id is null
    then
        select load_log(l_load_id, l_step_id,
                        'DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name || ' COMPLETED ===',
                        partition_cnt, 'O')
        into l_step_id;
    end if;
    return l_step_id;
exception
    when others then
        select load_log(l_load_id, l_step_id, sqlstate || ': ' || sqlerrm, 0, 'e')
        into l_step_id;
        raise notice '% %', sqlstate, sqlerrm;
        select load_log(l_load_id, l_step_id,
                        'ERROR DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name || ' COMPLETED ===',
                        partition_cnt, 'E')
        into l_step_id;
        perform load_error_log('db_cleanup_table for ' || l_schema_name || '.' || l_table_name, 'i', sqlerrm,
                               l_load_id);
        raise;
end
$function$
;


CREATE OR REPLACE FUNCTION db_management.db_cleanup_table_native_part(in_schema_name character varying,
                                                                      in_table_name character varying,
                                                                      in_load_timing_id integer DEFAULT nextval('load_timing_seq'::regclass))
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
declare
    partition_cnt   int;
    l_load_id       int ;
    l_step_id       int;
    l_table_name    varchar;
    l_schema_name   varchar;
    l_limit_date_id int;
    l_sql           text;
    part            record;
begin
    --l_row_cnt:=0;
    partition_cnt := 0;
    if in_load_timing_id is null
    then
        select nextval('load_timing_seq') into l_load_id;
        l_step_id := 1;
        select public.load_log(l_load_id, l_step_id,
                               'DB_CLEANUP_TABLE FOR ' || in_schema_name || '.' || in_table_name || ' STARTED===', 0,
                               'O')
        into l_step_id;
    else
        l_load_id := in_load_timing_id;
        select coalesce(max(step), 0) + 1
        into l_step_id
        from public.load_timing
        where load_timing_id = in_load_timing_id;
    end if;
    select schema_name,
           table_name,
           to_char(date_trunc(cleanup_schedule,
                              (current_date - CAST(retention_period || ' ' || cleanup_schedule AS Interval))),
                   'YYYYMMDD')::int as date_id
    into l_schema_name, l_table_name, l_limit_date_id
    from db_management.table_retention
    where table_name = in_table_name
      and schema_name = in_schema_name
      and is_active
      and retention_type = 'D';
    create temp table obsolete_partitions
    (
        schema_name varchar(255),
        table_name  varchar(255)
    );
    with cte as
             (select cn.nspname                                          as child_schema,
                     c.relname                                           as child_table,
                     cast(regexp_replace(coalesce(substring(c.relname, length(c.relname) - 8 + 1, 8), '99999999'),
                                         '[^0-9]+', '', 'g') as integer) as date_id
              --pn.nspname as parent_schema, p.relname as parent_table
              from pg_inherits
                       join pg_class as c on (inhrelid = c.oid)
                       join pg_class as p on (inhparent = p.oid)
                       join pg_namespace pn on pn.oid = p.relnamespace
                       join pg_namespace cn on cn.oid = c.relnamespace
              where p.relname = l_table_name
                and pn.nspname = l_schema_name
                and c.relkind not in ('f'))
    insert
    into obsolete_partitions (schema_name, table_name)
    --if daily partitions
    select child_schema, child_table
    from cte
    where date_id < l_limit_date_id
      and date_id between 10000000 and 99999999
    union all
    --if monthly partitions
    select child_schema, child_table
    from cte
    where date_id < l_limit_date_id / 100
      and date_id between 100000 and 999999;
    for part in (select schema_name, table_name from obsolete_partitions)
        loop
            l_sql := 'drop table ' || part.schema_name || '.' || part.table_name || ';';
            execute l_sql;
            select load_log(l_load_id, l_step_id,
                            'Partition ' || part.schema_name || '.' || part.table_name || ' has been dropped', 0, 'D')
            into l_step_id;
            partition_cnt := partition_cnt + 1;
        end loop;
    drop table obsolete_partitions;
    if in_load_timing_id is null
    then
        select load_log(l_load_id, l_step_id,
                        'DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name || ' COMPLETED ===', 0, 'O')
        into l_step_id;
    end if;
    return l_step_id;
exception
    when others then
        select load_log(l_load_id, l_step_id, sqlstate || ': ' || sqlerrm, 0, 'E')
        into l_step_id;
        raise notice '% %', sqlstate, sqlerrm;
        select load_log(l_load_id, l_step_id,
                        'ERROR DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name || ' COMPLETED ===',
                        partition_cnt, 'E')
        into l_step_id;
        perform load_error_log('DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name, 'I', sqlerrm,
                               l_load_id);
        raise;
end
$function$
;
CREATE OR REPLACE FUNCTION db_management.db_cleanup_table(in_schema_name character varying,
                                                          in_table_name character varying,
                                                          in_load_timing_id integer DEFAULT nextval('load_timing_seq'::regclass))
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
declare
    l_load_id       int;
    l_step_id       int;
    l_row_cnt       int;
    l_table_name    varchar;
    l_schema_name   varchar;
    l_limit_date_id int;
    l_key_field     varchar;
    l_field_type    varchar;
    l_sql           text;
begin
    l_row_cnt := 0;
    if in_load_timing_id is null
    then
        select nextval('load_timing_seq') into l_load_id;
        l_step_id := 1;
        select public.load_log(l_load_id, l_step_id,
                               'DB_CLEANUP_TABLE FOR ' || in_schema_name || '.' || in_table_name || ' STARTED===', 0,
                               'O')
        into l_step_id;
    else
        l_load_id := in_load_timing_id;
        select coalesce(max(step), 0) + 1
        into l_step_id
        from public.load_timing
        where load_timing_id = l_load_id;
    end if;
    raise notice '% %', l_load_id, l_step_id;
    select schema_name,
           table_name,
           to_char(current_date - CAST(retention_period || ' ' || cleanup_schedule AS Interval), 'YYYYMMDD') as date_id,
           key_field
    into l_schema_name, l_table_name, l_limit_date_id, l_key_field
    from db_management.table_retention
    where table_name = in_table_name
      and schema_name = in_schema_name
      and is_active
      and retention_type = 'D';
    if l_key_field = 'truncate' then
        l_sql := 'truncate table ' || l_schema_name || '.' || l_table_name;
        execute l_sql;
        get diagnostics l_row_cnt = ROW_COUNT;
        select load_log(l_load_id, l_step_id, 'Table ' || l_schema_name || '.' || l_table_name || ' has been truncated',
                        l_row_cnt, 'T')
        into l_step_id;
        return 1;
    end if;
    select case typcategory
               when 'D' then 'date'
               when 'N' then 'int'
               when 'S' then 'varchar'
               else null
               end as field_type_category
    into l_field_type
    from pg_attribute att
             join pg_type t on att.atttypid = t.oid
    where attrelid = (l_schema_name || '.' || l_table_name)::regclass
      and attname = l_key_field
      and typcategory in ('D', 'N', 'S')
      and not attisdropped;
    if l_field_type is not null
    then
        l_sql := 'delete from ' || l_schema_name || '.' || l_table_name || '
			where "' || l_key_field || '" < ''' || l_limit_date_id || '''::' || l_field_type || ' ;';
        execute l_sql;
        get diagnostics l_row_cnt = ROW_COUNT;
        select load_log(l_load_id, l_step_id,
                        'Data has been deleted from the table ' || l_schema_name || '.' || l_table_name || ' where "' ||
                        l_key_field || '" < ' || l_limit_date_id || '', l_row_cnt, 'D')
        into l_step_id;
    else
        raise warning 'Data type of key field is not appropriate';
        select load_log(l_load_id, l_step_id, 'Data type of key field is not appropriate ' || l_field_type, 0, 'O')
        into l_step_id;
        return 0;
    end if;
    if in_load_timing_id is null
    then
        select load_log(l_load_id, l_step_id,
                        'DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name || ' COMPLETED ===', 0, 'O')
        into l_step_id;
    end if;
    return l_step_id;
exception
    when others then
        select load_log(l_load_id, l_step_id, sqlstate || ': ' || sqlerrm, 0, 'E')
        into l_step_id;
        raise notice '% %', sqlstate, sqlerrm;
        select load_log(l_load_id, l_step_id,
                        'ERROR DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name || ' COMPLETED ===', 0,
                        'O')
        into l_step_id;
        perform load_error_log('DB_CLEANUP_TABLE FOR ' || l_schema_name || '.' || l_table_name, 'I', sqlerrm,
                               l_load_id);
        raise;
end
$function$
;


CREATE OR REPLACE FUNCTION db_management.db_cleanup_data_rolloff()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- SY: 20231128 https://dashfinancial.atlassian.net/browse/DS-7534 perform has been replaced with l_step_id :=
declare
	is_trigger_part bool;
	is_native_part 	bool;
	tbl 			record;
	l_load_id 		int;
	l_step_id 		int;
begin
	l_step_id:=0;
	select nextval('load_timing_seq') into l_load_id;
	select public.load_log(l_load_id, l_step_id, 'DB_CLEANUP_DATA_ROLLOFF STARTED===', 0, 'O')
	into l_step_id;
	for tbl in (select schema_name, table_name from db_management.table_retention where is_active and retention_type = 'D' order by roll_off_order nulls last)
		loop
			select public.load_log(l_load_id, l_step_id, 'Procesing '||tbl.schema_name||'.'||tbl.table_name||'...', 0, 'O')
			into l_step_id;
			select (count(1) - sum(child.relispartition::int))::int::bool as is_trigger_part, sum(child.relispartition::int)::int::bool as is_native_part
			into is_trigger_part, is_native_part
			from pg_inherits
			join pg_class as child on (inhrelid=child.oid)
			join pg_class as parent on (inhparent=parent.oid)
			join pg_namespace pn on pn.oid = parent.relnamespace
			where parent.relname = tbl.table_name and pn.nspname = tbl.schema_name;
			if (is_trigger_part) then
				l_step_id:= db_management.db_cleanup_table_trigger_part(tbl.schema_name, tbl.table_name, l_load_id);
			elseif (is_native_part) then
				l_step_id:= db_management.db_cleanup_table_native_part(tbl.schema_name, tbl.table_name, l_load_id);
			  --null;
			else
				l_step_id:= db_management.db_cleanup_table(tbl.schema_name, tbl.table_name, l_load_id);
			end if;
	end loop;
	select public.load_log(l_load_id, l_step_id, 'DB_CLEANUP_DATA_ROLLOFF COMPLETED===', 0, 'O')
	into l_step_id;
	return 1;
end
$function$
;


-- DROP PROCEDURE call db_management.add_partitions();

CREATE OR REPLACE PROCEDURE db_management.add_partitions()
    LANGUAGE plpgsql
AS
$procedure$
declare
    scr                 record;
    int_rec             record;
    fk                  record;
    l_load_id           int;
    l_step_id           int;
    l_new_part_name     varchar(255);
    l_existed_part_name varchar(255);
    fSource_table       varchar(255);
    fPrevDT             varchar(10);
    l_existed_sets      text;

begin
    select nextval('load_timing_seq') into l_load_id;
    l_step_id := 1;

    select load_log(l_load_id, l_step_id, 'DB_MANAGEMENT.ADD_PARTITIONS STARTED===', 0, 'O')
    into l_step_id;

    for scr in (select schema_name,
                       table_name,
                       part_schema_name,
                       upper(part_type)     as part_type,
                       upper(part_schedule) as part_schedule
                from db_management.table_partman
                where is_active
                order by part_priority)
        loop
            if (select count(1)
                from pg_class c
                         JOIN pg_namespace n ON n.oid = c.relnamespace
                where c.relname = scr.table_name
                  and n.nspname = scr.schema_name
                  and relkind = 'p') = 0
            then
                select load_log(l_load_id, l_step_id, 'The Table ' || scr.schema_name || '.' || scr.table_name ||
                                                      ' does not exists or is not partitioned', 0, 'O')
                into l_step_id;
            else
                case scr.part_schedule
                    when 'DAY'
                        then l_existed_part_name := '';
                             for int_rec in (select dt, to_dt
                                             from (select dt, --to_char(public.get_business_date(to_date(dt::varchar,'YYYYMMDD'),1), 'YYYYMMDD')::int as to_dt
                                                          lead(dt) over (order by dt) as to_dt
                                                   from unnest(public.get_last_workdate_ids_arr(22,
                                                                                                (now() + interval '30 day')::date)) dt) dates_range
                                             where to_dt is not null
                                             union
                                             select dt::int, to_dt
                                             from (select right(child.relname, 8) as dt, -1 as to_dt
                                                   FROM pg_inherits
                                                            JOIN pg_class AS child ON (inhrelid = child.oid)
                                                            JOIN pg_class as parent ON (inhparent = parent.oid)
                                                            JOIN pg_namespace pn ON pn.oid = parent.relnamespace
                                                            JOIN pg_namespace cn ON cn.oid = child.relnamespace
                                                   where child.relkind not in ('i', 'f')
                                                     and parent.relkind not in ('i')
                                                     and child.relispartition
                                                     and pn.nspname = scr.schema_name
                                                     and parent.relname = scr.table_name
                                                     and cn.nspname = scr.part_schema_name
                                                     and child.relname like parent.relname || '_________' -- table_name + date (YYYYMMDD)
                                                   order by child.relname desc
                                                   limit 1) for_like
                                             order by 2)
                                 loop
                                     /* CURSOR CONTAINS At least one existing partition. It must be the first partition */
                                     l_new_part_name :=
                                             scr.part_schema_name || '.' || scr.table_name || '_' || int_rec.dt;
                                     if (select Count(1)
                                         FROM pg_inherits
                                                  JOIN pg_class AS child ON (inhrelid = child.oid)
                                                  JOIN pg_class as parent ON (inhparent = parent.oid)
                                                  JOIN pg_namespace pn ON pn.oid = parent.relnamespace
                                                  JOIN pg_namespace cn ON cn.oid = child.relnamespace
                                         where child.relkind not in ('i')
                                           and parent.relkind not in ('i')
                                           and child.relispartition
                                           and pn.nspname = scr.schema_name
                                           and parent.relname = scr.table_name
                                           and child.relname = scr.table_name || '_' || int_rec.dt
                                           and cn.nspname = scr.part_schema_name) = 0
                                     then /* Partition needs to be created */
                                         select load_log(l_load_id, l_step_id,
                                                         'DAILY Partition ' || l_new_part_name || ' needs to be added ',
                                                         0, 'O')
                                         into l_step_id;

                                         RAISE NOTICE 'l_existed_part_name is %', l_existed_part_name;

                                         execute
                                             'CREATE TABLE ' || l_new_part_name || '( LIKE ' || l_existed_part_name ||
                                             ' INCLUDING ALL);';
                                         execute 'ALTER TABLE ' || scr.schema_name || '."' || scr.table_name ||
                                                 '" ATTACH PARTITION ' || l_new_part_name || '  FOR VALUES FROM (' ||
                                                 int_rec.dt || ') TO (' || int_rec.to_dt || ')';
                                         if l_existed_sets is not null
                                         then
--                          raise notice '%', l_existed_sets;
                                             execute 'ALTER TABLE ' || l_new_part_name || ' set (' || l_existed_sets || ')';
                                         end if;
                                         commit;

                                         select load_log(l_load_id, l_step_id,
                                                         'DAILY Partition ' || l_new_part_name || ' added ', 0, 'O')
                                         into l_step_id;

                                         -- Create Foreign key from partition to partition \/
                                         fSource_table :=
                                                 replace(l_existed_part_name, scr.part_schema_name || '.', ''); -- orig partition to copy the FK
                                         for fk in (SELECT nsp.nspname, rel.relname, con."oid", con.conname
                                                    FROM pg_catalog.pg_constraint con
                                                             INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
                                                             INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace
                                                    WHERE nsp.nspname = scr.part_schema_name
                                                      AND rel.relname = fSource_table
                                                      and con.contype = 'f')
                                             loop
                                                 if (SELECT count(1) -- check whether constrain already exists on new partition
                                                     FROM pg_catalog.pg_constraint con
                                                              INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace
                                                     WHERE nsp.nspname = scr.part_schema_name
                                                       AND con.conname = replace(fk.conname, fPrevDT, int_rec.dt::text) -- new constraint name
                                                       AND con.contype = 'f') = 0 then
                                                     raise notice 'FK Constraint to be created for %', l_new_part_name;
                                                     execute replace(format('alter table %s add constraint %s %s',
                                                                            l_new_part_name, fk.conname,
                                                                            pg_get_constraintdef(fk.oid)), fPrevDT,
                                                                     int_rec.dt::text);
                                                 else
                                                     raise notice '************  FK Constraint already exists for %', l_new_part_name;
                                                 end if;
                                             end loop;
                                         -- Create Foreign key from partition to partition /\

                                     else
                                         if l_existed_part_name = ''
                                         then
                                             select load_log(l_load_id, l_step_id,
                                                             'Last table ' || scr.schema_name || '.' ||
                                                             scr.table_name || ' partition is ' || l_new_part_name ||
                                                             '', 0, 'O')
                                             into l_step_id;
                                         else
                                             select load_log(l_load_id, l_step_id,
                                                             'DAILY Partition ' || l_new_part_name || ' already exists',
                                                             0, 'O')
                                             into l_step_id;
                                         end if;

                                         l_existed_part_name :=
                                                 scr.part_schema_name || '.' || scr.table_name || '_' || int_rec.dt;
                                         l_existed_sets = (select array_to_string(reloptions, ',')
                                                           from pg_class c
                                                                    join pg_namespace n on (n.oid = c.relnamespace)
                                                           where nspname = scr.part_schema_name
                                                             and relname = scr.table_name || '_' || int_rec.dt);
                                         fPrevDT := int_rec.dt::text;
                                     end if;
                                 end loop; /* 10 day forwar loop to create some extra partitions*/
                    when 'MONTH'
                        then l_existed_part_name := '';
                             for int_rec in (select dt, to_dt
                                             from (select to_char(dt, 'YYYYMM')::int                            as dt,
                                                          (lead(to_char(dt, 'YYYYMM')) over (order by dt))::int as to_dt
                                                   from generate_series(now(), now() + interval '5 month', '1 month') dt) month_range
                                             where to_dt is not null
                                             union
                                             select dt::int, to_dt::int
                                             from (select right(child.relname, 6) as dt, -1 as to_dt
                                                   FROM pg_inherits
                                                            JOIN pg_class AS child ON (inhrelid = child.oid)
                                                            JOIN pg_class as parent ON (inhparent = parent.oid)
                                                            JOIN pg_namespace pn ON pn.oid = parent.relnamespace
                                                            JOIN pg_namespace cn ON cn.oid = child.relnamespace
                                                   where child.relkind not in ('i', 'f')
                                                     and parent.relkind not in ('i')
                                                     and child.relispartition
                                                     and pn.nspname = scr.schema_name
                                                     and parent.relname = scr.table_name
                                                     and cn.nspname = scr.part_schema_name
                                                     and child.relname like parent.relname || '_______' --table_name + date(YYYYMM)
                                                   order by child.relname desc
                                                   limit 1) for_like
                                             order by 2)
                                 loop
                                     l_new_part_name :=
                                             scr.part_schema_name || '."' || scr.table_name || '_' || int_rec.dt || '"';
                                     if (select Count(1)
                                         FROM pg_inherits
                                                  JOIN pg_class AS child ON (inhrelid = child.oid)
                                                  JOIN pg_class as parent ON (inhparent = parent.oid)
                                                  JOIN pg_namespace pn ON pn.oid = parent.relnamespace
                                                  JOIN pg_namespace cn ON cn.oid = child.relnamespace
                                         where child.relkind not in ('i')
                                           and parent.relkind not in ('i')
                                           and child.relispartition
                                           and pn.nspname = scr.schema_name
                                           and parent.relname = scr.table_name
                                           and child.relname = scr.table_name || '_' || int_rec.dt
                                           and cn.nspname = scr.part_schema_name) = 0
                                     then /* Partition needs to be created */
                                         select load_log(l_load_id, l_step_id,
                                                         'MONTHLY Partition ' || l_new_part_name ||
                                                         ' need to be added ', 0, 'O')
                                         into l_step_id;
                                         --raise notice '%, %', l_new_part_name, l_existed_part_name;
                                         execute
                                             'CREATE TABLE ' || l_new_part_name || '( LIKE ' || l_existed_part_name ||
                                             ' INCLUDING ALL);';
                                         execute 'ALTER TABLE ' || scr.schema_name || '."' || scr.table_name ||
                                                 '" ATTACH PARTITION ' || l_new_part_name || '  FOR VALUES FROM (' ||
                                                 int_rec.dt || '01) TO (' || int_rec.to_dt || '01)';
--						  execute 'CREATE TABLE '||l_new_part_name||' PARTITION OF '||scr.schema_name||'.'||scr.table_name||' FOR VALUES FROM ('||int_rec.dt||'01) TO ('||int_rec.dt::int+1||'01)';
                                         if l_existed_sets is not null then
--                          raise notice '%', l_existed_sets;
                                             execute 'ALTER TABLE ' || l_new_part_name || ' set (' || l_existed_sets || ')';
                                         end if;
                                         commit;

                                         select load_log(l_load_id, l_step_id, l_new_part_name || ' added ', 0, 'O')
                                         into l_step_id;
                                     else
                                         if l_existed_part_name = ''
                                         then
                                             select load_log(l_load_id, l_step_id,
                                                             'Last table ' || scr.schema_name || '.' ||
                                                             scr.table_name || ' partition is ' || l_new_part_name ||
                                                             '', 0, 'O')
                                             into l_step_id;
                                         else
                                             select load_log(l_load_id, l_step_id,
                                                             'MONTHLY Partition ' || l_new_part_name ||
                                                             ' already exists', 0, 'O')
                                             into l_step_id;
                                         end if;

                                         l_existed_part_name :=
                                                 scr.part_schema_name || '."' || scr.table_name || '_' || int_rec.dt ||
                                                 '"';
                                         l_existed_sets = (select array_to_string(reloptions, ',')
                                                           from pg_class c
                                                                    join pg_namespace n on (n.oid = c.relnamespace)
                                                           where nspname = scr.part_schema_name
                                                             and relname = scr.table_name || '_' || int_rec.dt);
                                     end if;
                                 end loop; /* 4 months */

                    when 'YEAR'
                        then l_existed_part_name := '';
                             for int_rec in (select dt, to_dt
                                             from (select to_char(dt, 'YYYY')::int                            as dt,
                                                          (lead(to_char(dt, 'YYYY')) over (order by dt))::int as to_dt
                                                   from generate_series(now(), now() + interval '2 year', '1 year') dt) year_range
                                             where to_dt is not null
                                             union
                                             select dt::int, to_dt::int
                                             from (select right(child.relname, 4) as dt, -1 as to_dt
                                                   FROM pg_inherits
                                                            JOIN pg_class AS child ON (inhrelid = child.oid)
                                                            JOIN pg_class as parent ON (inhparent = parent.oid)
                                                            JOIN pg_namespace pn ON pn.oid = parent.relnamespace
                                                            JOIN pg_namespace cn ON cn.oid = child.relnamespace
                                                   where child.relkind not in ('i', 'f')
                                                     and parent.relkind not in ('i')
                                                     and child.relispartition
                                                     and pn.nspname = scr.schema_name
                                                     and parent.relname = scr.table_name
                                                     and cn.nspname = scr.part_schema_name
                                                     and child.relname like parent.relname || '_____' --table_name + date(YYYY)
                                                   order by child.relname desc
                                                   limit 1) for_like
                                             order by 2)
                                 loop
                                     l_new_part_name :=
                                             scr.part_schema_name || '."' || scr.table_name || '_' || int_rec.dt || '"';
                                     if (select Count(1)
                                         FROM pg_inherits
                                                  JOIN pg_class AS child ON (inhrelid = child.oid)
                                                  JOIN pg_class as parent ON (inhparent = parent.oid)
                                                  JOIN pg_namespace pn ON pn.oid = parent.relnamespace
                                                  JOIN pg_namespace cn ON cn.oid = child.relnamespace
                                         where child.relkind not in ('i')
                                           and parent.relkind not in ('i')
                                           and child.relispartition
                                           and pn.nspname = scr.schema_name
                                           and parent.relname = scr.table_name
                                           and child.relname = scr.table_name || '_' || int_rec.dt
                                           and cn.nspname = scr.part_schema_name) = 0
                                     then /* Partition needs to be created */
                                         select load_log(l_load_id, l_step_id,
                                                         'YEAR Partition ' || l_new_part_name || ' needs to be added ',
                                                         0, 'O')
                                         into l_step_id;

                                         execute
                                             'CREATE TABLE ' || l_new_part_name || '( LIKE ' || l_existed_part_name ||
                                             ' INCLUDING ALL);';
                                         execute 'ALTER TABLE ' || scr.schema_name || '."' || scr.table_name ||
                                                 '" ATTACH PARTITION ' || l_new_part_name || '  FOR VALUES FROM (' ||
                                                 int_rec.dt || '0101) TO (' || int_rec.to_dt || '0101)';
                                         if l_existed_sets is not null then
--                          raise notice '%', l_existed_sets;
                                             execute 'ALTER TABLE ' || l_new_part_name || ' set (' || l_existed_sets || ')';
                                         end if;
--						  execute 'CREATE TABLE '||l_new_part_name||' PARTITION OF '||scr.schema_name||'.'||scr.table_name||' FOR VALUES FROM ('||int_rec.dt||'01) TO ('||int_rec.dt::int+1||'01)';
                                         commit;

                                         select load_log(l_load_id, l_step_id, l_new_part_name || ' added ', 0, 'O')
                                         into l_step_id;
                                     else
                                         if l_existed_part_name = ''
                                         then
                                             select load_log(l_load_id, l_step_id,
                                                             'Last table ' || scr.schema_name || '.' ||
                                                             scr.table_name || ' partition is ' || l_new_part_name ||
                                                             '', 0, 'O')
                                             into l_step_id;
                                         else
                                             select load_log(l_load_id, l_step_id,
                                                             'YEAR Partition ' || l_new_part_name || ' already exists',
                                                             0, 'O')
                                             into l_step_id;
                                         end if;

                                         l_existed_part_name :=
                                                 scr.part_schema_name || '."' || scr.table_name || '_' || int_rec.dt ||
                                                 '"';
                                         l_existed_sets = (select array_to_string(reloptions, ',')
                                                           from pg_class c
                                                                    join pg_namespace n on (n.oid = c.relnamespace)
                                                           where nspname = scr.part_schema_name
                                                             and relname = scr.table_name || '_' || int_rec.dt);
                                     end if;
                                 end loop; /* 2 years */


                    end case; /* CASE */
            end if; /* Check if table is partitioned */
        end loop;
    select load_log(l_load_id, l_step_id, 'DB_MANAGEMENT.ADD_PARTITIONS COMPLETED===', 0, 'O')
    into l_step_id;
end;
    -- Enter function body here
$procedure$
;
