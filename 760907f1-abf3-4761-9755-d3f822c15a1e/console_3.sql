alter table db_management.table_retention add column if not exists roll_off_order int4 null;
-- clean_order
do
$$
    begin
        alter table db_management.table_retention
            add constraint table_retention_pk primary key (schema_name, table_name, is_active);
    exception
        when others then raise notice 'primary key already exists';
    end;
$$;

do
$$
    begin
        alter table db_management.table_retention
            add constraint table_retention_check check (cleanup_schedule in ('DAY', 'MONTH', 'YEAR'));
    exception
        when others then raise notice 'constraint already exists';
    end;
$$;


do
$$
    begin
        update db_management.table_retention
        set roll_off_order = clean_order
        where clean_order is not null;
    exception
        when others then raise notice 'clean_order was not implemented in this table';
    end;
$$;


do
$$
    begin
        alter table db_management.table_retention
            alter column schema_name set not null;
        alter table db_management.table_retention
            alter column table_name set not null;
        alter table db_management.table_retention
            alter column retention_period set not null;
        alter table db_management.table_retention
            alter column is_active set not null;
    exception
        when others then raise notice 'constraint already exists';
    end;
$$;


alter function db_management.db_cleanup_table_trigger_part(varchar, varchar, int4) set schema trash;
alter function trash.db_cleanup_table_trigger_part(varchar, varchar, int4) rename to db_cleanup_table_trigger_part_old;

alter function db_management.db_cleanup_table_native_part(varchar, varchar, int4) set schema trash;
alter function trash.db_cleanup_table_native_part(varchar, varchar, int4) rename to db_cleanup_table_native_part_old;

alter function db_management.db_cleanup_table (varchar, varchar, int4) set schema trash;
alter function trash.db_cleanup_table (varchar, varchar, int4) rename to db_cleanup_table_old;

alter function db_management.db_cleanup_data_rolloff() set schema trash;
alter function trash.db_cleanup_data_rolloff() rename to db_cleanup_data_rolloff_old;


create or replace function db_management.db_cleanup_table_trigger_part(in_schema_name character varying,
                                                                       in_table_name character varying,
                                                                       in_load_timing_id integer default nextval('load_timing_seq'::regclass))
    returns integer
    language plpgsql
as
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


create or replace function db_management.db_cleanup_table_native_part(in_schema_name character varying,
                                                                      in_table_name character varying,
                                                                      in_load_timing_id integer default nextval('load_timing_seq'::regclass))
    returns integer
    language plpgsql
as
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