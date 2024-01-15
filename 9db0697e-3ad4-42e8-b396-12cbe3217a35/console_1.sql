create schema inc_hft;

create table inc_hft.hft_incremental_files
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
create index on inc_hft.hft_incremental_files using btree (date_id);
create index on inc_hft.hft_incremental_files using btree (filename);


create table inc_hft.cures
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


create or replace function inc_hft.hft_cure(in_date_id integer, in_process text)
    returns text
    language plpgsql
as
$fn$
declare
    l_load_id       int;
    l_step_id       int;
    a_batch_ids     int8[];
    a_batch_ids_upd int8[];
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
            into a_batch_ids;

            ret_val = format('reported to delete: %s', a_batch_ids);
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
        into a_batch_ids;

        delete
        from partitions.hft_fix_message_event_inc hft
        where hft.load_batch_id = any (a_batch_ids);

        with upd as (
            update inc_hft.cures
                set status = 'processed',
                    processed = clock_timestamp()
                where id_to_delete = any (a_batch_ids)
                    and to_char(date_ts, 'YYYYMMDD')::int = in_date_id
                returning id_to_delete as upd_batchs)
        select array_agg(distinct upd_batchs)
        into a_batch_ids_upd
        from upd;

        if cardinality(a_batch_ids_upd) > 0 then
            ret_val = format('fixed: %s', a_batch_ids_upd);
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
                                       from public.hft_incremental_files hif2
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

$fn$
;
