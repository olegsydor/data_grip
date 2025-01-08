create schema inc_hft;
create table inc_hft.load_finish
(
    date_id        int4                                not null,
    node_name      text                                null,
    db_create_time timestamp default clock_timestamp() not null,
    constraint load_finish_pk primary key (date_id)
);
comment on table inc_hft.load_finish is 'The signal table. date_id is filling as soon as daily loading has been finished';


drop function if exists inc_hft.load_finish_change_trg;
create or replace function inc_hft.load_finish_change_trg()
    returns trigger
    language plpgsql
as
$trg$
begin
    perform public.send('oleh.sydor@iongroup.com', 'EOS ETL',
                        new.date_id::text || ': ' || new.node_name || '. ' || 'Ready to reporting');
    return new;
end;
$trg$;

create trigger load_finish_insert_trigger
    after insert
    on inc_hft.load_finish
    for each row
    execute function inc_hft.load_finish_change_trg();

create table public.mail_to_send
(
    event_id     serial4                                   not null,
    mail_from    varchar(250)                              not null,
    mail_to      varchar(250)                              not null,
    mail_subject varchar(250)                              not null,
    mail_body    text                                      null,
    created_by   varchar(25)                               null,
    created_time timestamptz                               null,
    postpone_to  timestamptz                               null,
    was_sent     timestamptz                               null,
    tries        int4                                      null,
    crypto       varchar(1) default 'N'::character varying null
);


CREATE OR REPLACE FUNCTION public.send(in_to character varying, in_subject character varying, in_body text,
                                       in_from character varying DEFAULT NULL::bpchar,
                                       in_created_by character DEFAULT NULL::bpchar,
                                       in_when timestamp with time zone DEFAULT NULL::timestamp with time zone,
                                       crypto character DEFAULT 'N'::bpchar)
    RETURNS boolean
    LANGUAGE plpgsql
AS
$function$
declare
    l_load_id int;
    each_mail varchar;
    all_mails varchar[];
    inst_name varchar := 'CAT_PROD';

begin
    if in_from is null
    then
        in_from := lower(inst_name) || '@iongroup.com';
    else
        in_from := lower(replace(in_from, '@', '_')) || '@iongroup.com';
    end if;
    --1. managing mail_to list

    --1.1. removing spaces from the list
    in_to = replace(in_to, ' ', '');

    --1.2. checking correctness of mails
    all_mails = (select string_to_array(in_to, ','));
    foreach each_mail in array all_mails
        loop
            if not (each_mail ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$') then
                all_mails = array_remove(all_mails, each_mail);
            end if;
        end loop;

    INSERT INTO public.mail_to_send
    (mail_from, mail_to, mail_subject, mail_body, created_by, created_time, postpone_to, crypto)
    VALUES (in_from, array_to_string(all_mails, ','), in_subject, in_body, coalesce(in_created_by, inst_name),
            now()::timestamp with time zone, coalesce(in_when, now()::timestamp with time zone), crypto);
    return true;

EXCEPTION
    when others then
-- 	PERFORM public.load_error_log('Sending mail from '||left(in_from, 20)||' time: '||to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),  'I', sqlerrm, l_load_id);
        return false;

end;
$function$
;

select public.send('oleh.sydor@iongroup.com', 'EOS ETL', 'Ready to reporting') into ok;

select * from public.mail_to_send;

select * from inc_hft.load_finish