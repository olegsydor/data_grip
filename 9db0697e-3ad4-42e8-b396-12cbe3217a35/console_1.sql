create schema if not exists inc_hft;

create table if not exists inc_hft.hft_incremental_files
(
    date_id          int4        not null,
    filename         varchar     not null,
    start_processing timestamptz null,
    start_position   int8        null,
    end_processing   timestamptz null,
    end_position     int8        null,
    load_batch_id    int4        null,
    is_processed     bpchar(1)   null default 'S'::bpchar,
    file_size        int8        null,
    processed_rows   int8        null,
    hft_comment      text        null,
    last_row_hash    varchar     null,
    is_active        bpchar(1)   null default 'Y'::bpchar,
    checked_loading  bool        null,
    node_name        text        null
);
create index if not exists inc_hft_hft_incremental_files_date_idx on inc_hft.hft_incremental_files using btree (date_id);
create index if not exists inc_hft_hft_incremental_files_filename_idx on inc_hft.hft_incremental_files using btree (filename);


create table if not exists inc_hft.cures
(
    date_ts       timestamp not null default clock_timestamp(),
    ids_to_delete varchar   null,
    processed     timestamp null,
    status        varchar   null,
    id_to_delete  int8      null
);

create or replace function inc_hft.sum_in_progress(in_date_id integer default to_char(now(), 'YYYYMMDD')::int4)
    returns integer
    language plpgsql
as
$fn$

declare
    ret_count integer;

begin
    with ct as (select filename,
                       processed_rows,
                       start_processing,
                       start_position,
                       end_position,
                       is_processed,
                       row_number() over (partition by filename order by is_processed, start_processing desc) as rn
                from inc_hft.hft_incremental_files hif
                where date_id = in_date_id
                  and start_processing is not null)
    select sum(end_position - start_position)
    into ret_count
    from ct
    where rn <= 2
      and is_processed = 'N';

    return coalesce(ret_count, 0);
end;
$fn$;
comment on function inc_hft.sum_in_progress is 'Counts active processes. Is called from the main script - inc_hft.sh';


create or replace function inc_hft.hft_cure(in_date_id integer, in_process text)
    returns text
    language plpgsql
as
$fn$
declare
    l_load_id       int;
    l_step_id       int;
    l_batch_ids     int8[];
    l_batch_ids_upd int8[];
    ret_val         varchar := '';
begin
    -- set log_error_verbosity='terse';
    /* 20210824: SO https://dashfinancial.atlassian.net/browse/DS-4037
       - table inc_hft.cures was altered and new column id_to_delete int8. Old column ids_to_delete varchar has been left just in case
       - checking and modifying part have been changed into working with separate id instead of array
       - interval back (30 minutes) until script process checked id for deleting was decreased to 10 minutes
     */

    -- LOGGING
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'HFT cure started', 0, 'S') into l_step_id;

    -- CHECK
    if lower(in_process) = 'check' then
        if (select count(*)
            from inc_hft.hft_incremental_files hif
            where date_id = in_date_id
              and is_active = 'Y'
              and upper(hft_comment) like '%BAD%') > 0 then
            -- Insert ids into the table
            with st as
                (select filename,
                        load_batch_id,
                        sum(case when upper("comment") like '%BAD%' then 1 else 0 end)
                        over (partition by filename order by load_batch_id) as to_del
                 from (select hif.filename,
                              hif.load_batch_id,
                              lead(hft_comment) over (partition by filename order by load_batch_id) as "comment"
                       from inc_hft.hft_incremental_files hif
                       where hif.date_id = in_date_id
                         and hif.is_active = 'Y'
                         and hif.filename not in (select hif2.filename
                                                  from inc_hft.hft_incremental_files hif2
                                                  where hif2.date_id = in_date_id
                                                    and hif2.is_processed = 'N')) x)
               , insrt as (
                insert into inc_hft.cures (id_to_delete, status)
                    select load_batch_id, 'reported'
                    from st
                    where to_del > 0
                      and load_batch_id is not null
                    returning id_to_delete as ins_batchs)
               , upd as (
                update inc_hft.hft_incremental_files hif
                    set is_active = 'N'
                    where date_id = in_date_id
                        and load_batch_id in (select ins_batchs from insrt)
                    returning load_batch_id as upd_batchs)
            select array_agg(upd_batchs)
            from upd
            into l_batch_ids;

            ret_val = format('reported to delete: %s', l_batch_ids);
        else
            ret_val = 'Nothing to report';
        end if;
        -- FIX
    elseif lower(in_process) = 'fix' then
        --start deleting
        select array_agg(id_to_delete)
        from inc_hft.cures cr
        where cr.status = 'reported'
          and cr.date_ts < clock_timestamp() - interval '1 second'
        into l_batch_ids;

        delete
        from partitions.hft_fix_message_event_inc hft
        where hft.load_batch_id = any (l_batch_ids);

        with upd as (
            update inc_hft.cures
                set status = 'processed',
                    processed = clock_timestamp()
                where id_to_delete = any (l_batch_ids)
                    and to_char(date_ts, 'YYYYMMDD')::int = in_date_id
                returning id_to_delete as upd_batchs)
        select array_agg(distinct upd_batchs)
        into l_batch_ids_upd
        from upd;

        if cardinality(l_batch_ids_upd) > 0 then
            ret_val = format('fixed: %s', l_batch_ids_upd);
        else
            ret_val = 'Nothing to fix'; --nothing to fix
        end if;
    else
        ret_val = 'wrong command';
    end if;
    select public.load_log(l_load_id, l_step_id, 'hft cure finished', 0, 'F') into l_step_id;
    --raise notice 'finished: %', ret_val;
    return ret_val;

exception
    when others then
        perform public.load_error_log('hft cure', 'i', sqlerrm, l_load_id);

        raise notice 'something went wrong: %', clock_timestamp()::text;
        raise notice 'error: %', sqlerrm;

        select public.load_log(l_load_id, l_step_id, sqlerrm, 0, 'F') into l_step_id;
end;
$fn$
;
comment on function inc_hft.hft_cure is 'Fixes bugs of mistaken loads. Calls from inc_hft.sh and by specific script inc_hft_cure.sh';


create or replace function inc_hft.unfinished_hft_inc(in_date_id integer default to_char(now(), 'YYYYMMDD'::text)::integer)
    returns integer
    language plpgsql
as
$fn$

declare
    ret_count integer;

begin
    with ct as (select filename,
                       processed_rows,
                       start_processing,
                       is_processed,
                       row_number() over (partition by filename order by is_processed, start_processing desc) as rn
                from inc_hft.hft_incremental_files hif
                where date_id = in_date_id
                  and filename not in (select filename
                                       from inc_hft.hft_incremental_files hif2
                                       where date_id = in_date_id
                                         and is_active = 'Y'
                                         and is_processed is null))
    select count(distinct hif.filename) - (select coalesce(sum(case is_processed when 'Y' then 1 else 0 end), 0)
                                           from ct
                                           where rn = 1
                                             and ct.processed_rows is not null)
    into ret_count
    from inc_hft.hft_incremental_files hif
    where date_id = in_date_id;

    return ret_count;

end;

$fn$;
comment on function inc_hft.unfinished_hft_inc is 'Counts active process near to EOD. Called from inc_hft_late.sh';


create or replace function inc_hft.hft_check_if_loaded()
    returns integer
    language plpgsql
AS
$fn$
declare
    l_load_batch_id int4;
    l_date_id       int4 := to_char(current_date, 'YYYYMMDD')::int4;
begin
    l_load_batch_id = (select load_batch_id
                       from inc_hft.hft_incremental_files
                       where date_id = l_date_id
                         and is_processed = 'Y'
                         and processed_rows > 0
                         and checked_loading is null
                       order by end_processing
                       limit 1);
    raise notice '%: load_batch_id - %', clock_timestamp(), l_load_batch_id;

    if l_load_batch_id is null then
        return -1;
    end if;

    update inc_hft.hft_incremental_files
    set checked_loading = true
    where load_batch_id = l_load_batch_id
      and date_id = l_date_id;

    if exists (select null from so_hft.hft_fix_message_event where load_batch_id = l_load_batch_id) then
        raise notice '%: load_batch_id % checked - OK', clock_timestamp(), l_load_batch_id;
        return 0;
    else
        update inc_hft.hft_incremental_files
        set hft_comment = hft_comment || 'BAD - was not loaded'
        where load_batch_id = l_load_batch_id
          and date_id = l_date_id;
        raise notice '%: load_batch_id % checked - marked to delete', clock_timestamp(), l_load_batch_id;
        return 1;
    end if;
end;
$fn$;
comment on function inc_hft.hft_check_if_loaded is 'Checking if all files\batches mentioned in inc_hft.hft_incremental_files have been really loaded in the partitions.hft_fix_message_event_inc';



create or replace function inc_hft.is_unfinished_other_node(in_node text, in_date_id integer, in_only_show boolean default true)
    returns integer[]
    language plpgsql
as
$fn$
declare
    l_load_id                     int;
    l_list_of_unfinished_batch_id int4[]; -- list of unfinished load_batch_id that have been started during the other node was active
begin

    l_list_of_unfinished_batch_id = (select array_agg(load_batch_id)
                                     from inc_hft.hft_incremental_files hif
                                     where date_id = in_date_id
                                       and node_name is distinct from in_node
                                       and is_processed is distinct from 'Y'
                                       and start_processing is not null
                                       and is_active = 'Y'
                                       and 1 = 2);

    if array_length(l_list_of_unfinished_batch_id, 1) > 0 and not in_only_show then
        update inc_hft.hft_incremental_files
        set hft_comment = concat_ws(', ', hft_comment, 'BAD by switching node')
        where date_id = in_date_id
          and load_batch_id = any (l_list_of_unfinished_batch_id);

        select nextval('public.load_timing_seq') into l_load_id;

        perform public.load_log(l_load_id, 1, 'unfinished batch_id because of switching node were marked to cure', 0,
                                'o');
    end if;

    return l_list_of_unfinished_batch_id;
end;
$fn$
;
comment on function inc_hft.is_unfinished_other_node is 'the function checks if load_batch_ids exist that were created
on different in_node node and depending on in_only_show marks them as BAD. Later those batch_ids will be deleted and
reloaded by hft_cures script, that will change is_active into ''F''
    This script calls from python script as python can pass current node as a parameter';



create or replace function inc_hft.add_files_to_process_node(in_date text, in_files text, in_sizes text, in_node_name text)
    returns integer
    language plpgsql
as
$fn$
declare
    row_cnt int4;
begin

    with sz as
             (select in_date::int               as date_id,
                     unnest(in_files::text[])   as filename,
                     unnest(in_sizes::bigint[]) as file_size,
                     in_node_name)
    insert
    into inc_hft.hft_incremental_files (date_id, filename, node_name)
        -- for new files
        (select sz.date_id, sz.filename, sz.in_node_name
         from sz
         where not exists(select 1
                          from inc_hft.hft_incremental_files hif
                          where hif.date_id = sz.date_id
                            and hif.filename = sz.filename))
    union
    -- for
    (select sz.date_id, sz.filename, sz.in_node_name
     from sz
     where exists(select 1
                  from inc_hft.hft_incremental_files hif
                  where hif.date_id = sz.date_id
                    and hif.filename = sz.filename
                    and (is_processed = 'Y' or end_position is not null))
       and not exists(select 1
                      from inc_hft.hft_incremental_files hif
                      where hif.date_id = sz.date_id
                        and hif.filename = sz.filename
                        and is_processed <> 'Y'
                        and end_position is null)
       and not exists(select 1
                      from inc_hft.hft_incremental_files hif
                      where hif.filename = sz.filename
                        and hif.start_processing >=
                            to_date(sz.date_id::text, 'YYYYMMDD') + interval '16 hour 30 minutes'));

    get diagnostics row_cnt = row_count;
    return row_cnt;

end;
$fn$;
comment on function inc_hft.add_files_to_process_node is 'Selects the next file to save in inc_hft.hft_incremental_files. Called from a Python script';


create or replace function inc_hft.choose_next_file_node(in_date_id integer, in_node character varying,
                                                         in_just_show character varying default 'N'::character varying)
    returns table
            (
                filename      character varying,
                last_row      bigint,
                load_batch_id integer,
                last_row_hash character varying
            )
    language plpgsql
as
$fn$
declare
    l_start_row bigint;
    l_batch     int;
    l_filename  varchar := '';
    l_hash      varchar;

--f_to_show: if = 'Y' - function just show all data but doesn't update the table

begin
    l_filename = (select hif.filename
    from inc_hft.hft_incremental_files hif
    where hif.date_id = in_date_id
    and hif.node_name = in_node
      and is_active = 'Y'
      and not exists (select 1
                     from inc_hft.hft_incremental_files hif2
                     where hif2.filename = hif.filename
                       and hif2.start_processing >= to_date(in_date_id::text, 'YYYYMMDD') + interval '16 hour 30 minute'
                       and hif2.is_active = 'Y'
        )
    group by hif.filename
    order by max(hif.start_processing) nulls first
    limit 1);

--    raise notice 'in_filename - %', in_filename;
    if l_filename is not null then
        -- start position
        select end_position
        from inc_hft.hft_incremental_files hif
        where hif.date_id = in_date_id
          and hif.filename = l_filename
          and hif.is_active = 'Y'
        order by end_position desc nulls last
        limit 1
        into l_start_row;

        select hif.last_row_hash
        from inc_hft.hft_incremental_files hif
        where hif.date_id = in_date_id
          and hif.filename = l_filename
          and coalesce(hif.end_position, 0) = coalesce(l_start_row, 0)
          and hif.is_active = 'Y'
        into l_hash;

        if in_just_show <> 'Y' then
            l_batch = (select nextval('public.load_batch_id'));
--            into in_batch;

            update inc_hft.hft_incremental_files hif
            set load_batch_id    = l_batch,
                start_position   = coalesce(l_start_row, 0) + 1,
                start_processing = clock_timestamp()
            where hif.date_id = in_date_id
              and hif.filename = l_filename
              and hif.load_batch_id is null
              and hif.end_position is null
              and hif.is_active = 'Y';
        end if;

        return query select l_filename::varchar, coalesce(l_start_row, 0)::bigint, l_batch::int, l_hash::varchar;
        return;
    end if;

end ;
$fn$;
comment on function inc_hft.choose_next_file_node is 'Selects the next file to process. Called from a Python script'
