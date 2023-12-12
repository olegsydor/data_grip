select max(create_time) from genesis2.alert
where create_time > '2023-01-01'

select max(create_time) from genesis2.alert2
where create_time > '2023-01-01'


insert into genesis2.alert (alert_id, sub_system_id, severity, alert_subject, alert_text, alert_status, create_time,
                            send_mail_result, is_risk_alert)
select alert_id,
       sub_system_id,
       severity,
       alert_subject,
       alert_text,
       alert_status,
       create_time,
       send_mail_result,
       is_risk_alert
from genesis2.alert2
where true
  and severity = ANY (ARRAY ['N', 'W', 'E', 'F'])
  and sub_system_id not in (select distinct sub_system_id
                            from genesis2.alert2
                            where sub_system_id not in (select sub_system_id from genesis2.sub_system))
  and alert2.create_time >= '2023-11-01';



insert into genesis2.alert_param_value2(alert_id, generic_param_key, generic_param_value)
select apv.alert_id,
       apv.generic_param_key,
       apv.generic_param_value
from staging.mv_alert_param_value apv
         join genesis2.alert2 al on al.alert_id = apv.alert_id
where extract(year from al.create_time) = 2023
  and extract(month from al.create_time) = 11
  and not exists (select null from genesis2.alert_param_value2 v2 where v2.alert_id = apv.alert_id);

create materialized view staging.mv_alert_param_value
as select * from staging.alert_param_value;

create index on staging.mv_alert_param_value (alert_id);

insert into genesis2.alert_param_value(alert_id, generic_param_key, generic_param_value)
select apv.alert_id, generic_param_key, generic_param_value
from genesis2.alert_param_value2 apv
join genesis2.alert2 al on al.alert_id = apv.alert_id
where apv.alert_id in (select alert_id from genesis2.alert)
and extract(year from al.create_time) = 2023
  and extract(month from al.create_time) = 11;

SELECT setval('alert_alert_id_seq', (select max(alert_id) from genesis2.alert), true);