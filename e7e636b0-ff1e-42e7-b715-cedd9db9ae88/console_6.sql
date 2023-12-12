
select * from dash360.get_user_sessions_by_range(20231201, 20231201);
select * from dash360.get_user_login_stats_by_range(20231101, 20231201);
create or replace function dash360.get_user_sessions_by_range(in_start_date_id int4, in_end_date_id int4
)
    returns table
            (
                session_id         int8,
                user_name          varchar(30),
                first_name         varchar(30),
                last_name          varchar(100),
                email              varchar(60),
                user_role          varchar(1),
                is_locked          varchar(1),
                login_time         timestamptz(3),
                logout_time        timestamptz(3),
                src_ip_addr        varchar(15),
                is_logout_graceful bpchar(1),
                transport_session  varchar(20)
            )
    language plpgsql
as
$fx$
declare
    l_start_date timestamptz := in_start_date_id::text::date::timestamptz;
    l_end_date   timestamptz := in_end_date_id::text::date::timestamptz + interval '1 day';
begin
    return query
        select us.session_id,
               ui.user_name,
               ui.first_name,
               ui.last_name,
               ui.email,
               ui.user_role,
               ui.is_locked,
               us.login_time,
               us.logout_time,
               us.src_ip_addr,
               us.is_logout_graceful,
               us.transport_session
        from genesis2.user_session us
                 left join genesis2.user_identifier ui on (us.user_id = ui.user_id)
        where us.login_time::date >= l_start_date
          and us.login_time < l_end_date;

end;
$fx$


create or replace function dash360.get_user_login_stats_by_range(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                username        varchar(30),
                first_name      varchar(30),
                last_name       varchar(100),
                email           varchar(60),
                "day"           text,
                logins_that_day int8,
                user_id         int4,
                java_logins     text,
                sl_logins       text,
                dash360_logins  text
            )
    language plpgsql
as
$fx$
declare
    l_start_date timestamptz := in_start_date_id::text::date::timestamptz;
    l_end_date   timestamptz := in_end_date_id::text::date::timestamptz + interval '1 day';
begin

    return query
        select ui.user_name                                          username,
               ui.first_name,
               ui.last_name,
               ui.email,
               eal.day,
               eal.logins_that_day,
               ui.user_id,
               case when java_portal > 0 then 'Y' else 'N' end    as java_logins,
               case when sl_portal > 0 then 'Y' else 'N' end      as sl_logins,
               case when dash360_portal > 0 then 'Y' else 'N' end as dash360_logins

        from (select eal.owner,
                     to_char(start_time::date, 'MM/DD/YYYY') as day,
                     count(start_time)                          logins_that_day,
                     max(eal.process_parameters)                pp
              from genesis2.event_audit_log eal
              where eal.start_time >= l_start_date
                and eal.start_time < l_end_date
                and eal.sub_system_id is null
                and eal.process_name != 'TimeSyncRequest'
              --AND eal.OWNER IS NOT null
              group by eal.owner, start_time::date
              order by eal.owner, start_time::date desc) eal
                 left join genesis2.user_identifier ui on (eal.owner = ui.user_id)
                 left join (select regexp_substr(regexp_substr(eal.process_parameters, '(UserID: [[:alnum:]]+)'),
                                                 '[0-9]+')::int as user_id,
                                   sum(case
                                           when substr(reverse(eal.process_parameters), 1, 1) = 'J' then 1
                                           else 0 end)          as java_portal,
                                   sum(case
                                           when substr(reverse(eal.process_parameters), 1, 1) = 'S' then 1
                                           else 0 end)          as sl_portal,
                                   sum(case
                                           when substr(reverse(eal.process_parameters), 1, 1) = 'W' then 1
                                           else 0 end)          as dash360_portal
                            from genesis2.event_audit_log eal
                            where eal.start_time >= l_start_date
                              and eal.start_time < l_end_date
                              and eal.sub_system_id is null
                              and process_name = 'PortalUserLayoutRequest'
                            group by regexp_substr(regexp_substr(eal.process_parameters, '(UserID: [[:alnum:]]+)'),
                                                   '[0-9]+')) lr on eal.owner = lr.user_id;
end;
$fx$
