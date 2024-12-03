create table public.load_timing
(
    load_timing_id int8         not null,
    step           int4         not null,
    table_name     varchar(250) null,
    row_count      int4         null,
    seconds        int4         null,
    log_date       timestamp(3) default clock_timestamp() null,
    operation      bpchar(1)    null
);
create index load_timing_log_date_idx on public.load_timing using btree (log_date);
create index load_timing_lt_id_step_idx on public.load_timing using btree (load_timing_id);
create index load_timing_table_name_idx on public.load_timing using btree (table_name) include (log_date);

grant all on table public.load_timing to adequate;



create sequence public.load_timing_seq
    increment by 1
    minvalue 0
    maxvalue 9223372036854775807
    start 1
    cache 1
    no cycle;

grant all on sequence public.load_timing_seq to adequate;


create or replace function public.load_log(in_load_timing_id bigint, inout in_step integer,
                                           in_table_name character varying, in_row_count integer,
                                           in_operation character)
    returns integer
    language plpgsql
    security definer
as
$function$
begin

    perform public.dblink_connect_u('pragma_log', 'dbname=sirius');
    perform public.dblink_exec('pragma_log', 'insert into public.load_timing (load_timing_id, step, table_name, row_count, operation, log_date)
                                  values (' || in_load_timing_id::TEXT || ', ' || in_step::TEXT || ', ''' ||
                                             left(in_table_name, 250) || ''', ' || in_row_count::TEXT || ', ''' ||
                                             in_operation || ''', now());');
    perform public.dblink_exec('pragma_log', 'commit;');
    perform public.dblink_disconnect('pragma_log'::text);
    RAISE INFO '% %: %  % , %', clock_timestamp(), in_step, in_table_name, in_row_count, in_operation;
    in_step := in_step + 1;
exception
    when others then
        perform public.dblink_disconnect('pragma_log'::text);

end;
$function$
;

select * from public.load_log(1, 1, 'test', 0, 'I');

alter table public.load_timing alter column log_date drop not null;

