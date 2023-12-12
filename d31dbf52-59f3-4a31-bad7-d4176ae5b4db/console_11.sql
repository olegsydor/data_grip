IMPORT FOREIGN SCHEMA genesis2 LIMIT TO (alert_param_value)
FROM SERVER postgresprod
into staging;

IMPORT FOREIGN SCHEMA genesis2 LIMIT TO (alert2)
FROM SERVER postgresprod
into staging;


select * from staging.alert2;


alter function trash.get_risk_alerts rename to get_risk_alerts_old;
alter function trash.get_risk_alerts1 rename to get_risk_alerts;

select * from trash.get_risk_alerts(in_tf_id := 'OFP0016', in_start_date := '2023-10-01', in_end_date := '2023-10-10');

create or replace function trash.get_risk_alerts(in_tf_id text, in_start_date date, in_end_date date)
    returns table
            (
                alert_time   timestamp,
                severity     text,
                tf_name      varchar(60),
                alert_text   text,
                alert_scope  text,
                cl_order_id  text,
                account_name text,
                exp_date     timestamp,
                symbol       varchar(10),
                side         bpchar(1),
                price        numeric(12, 4),
                qty          int4
            )
    language plpgsql
as
$fx$
declare
    in_start_date_id int4 := to_char(in_start_date, 'YYYYMMDD')::int4;
    in_end_date_id   int4 := to_char(in_end_date, 'YYYYMMDD')::int4;
    alerts_id int[];
begin

    create temp table alert on commit drop as
    select a.alert_id, a.severity, a.create_time, a.alert_text
    from staging.alert2 a
--              inner join staging.alert_param_value ap
--                         on (a.alert_id = ap.alert_id and ap.generic_param_key = 'RISK_ALERT')
--              inner join staging.alert_param_value ap_tf
--                         on (a.alert_id = ap_tf.alert_id and ap_tf.generic_param_key = 'TR_FIRM_ID')
    where true
--       and ap.generic_param_value = 'Y'
--       and ap_tf.generic_param_value = :in_tf_id
      and a.create_time between :in_start_date::timestamp and :in_end_date::timestamp
      and a.severity = 'E';

    select * from staging.alert2
                 where alert_id = 35267966
    select array_agg(distinct alert_id) from alert into alerts_id;

    create index on alert (alert_id);
    raise notice 'alert - %', (select count(*) from alert);



    create temp table alert_param_value on commit drop as
    select apv.alert_id, apv.generic_param_key, apv.generic_param_value
    from staging.alert_param_value apv
             where apv.alert_id = any(alerts_id);

    create index on alert_param_value (alert_id, generic_param_key);
    create index on alert_param_value (generic_param_value);

    raise notice 'alert_param_value - %', (select count(*) from alert_param_value);

    return query
        with alerts as (select a.alert_id
                        from alert a)
        SELECT a.CREATE_TIME                  alert_time,--Event Time
               case
                   when a.severity = 'E' then 'Error'
                   when a.severity = 'F' then 'Fatal'
                   when a.severity = 'N' then 'Note'
                   when a.severity = 'W' then 'Warning'
                   end                        severity,--Severity
--               osr.OSR_PARAM_NAME osr_prm_name,--Risk Parameter
               tf.trading_firm_name           tf_name,--Trading Firm
               a.alert_text                as alert_text, --Alert
               case
                   when ap_scope.generic_param_value = 'A' then 'Account'
                   when ap_scope.generic_param_value = 'B' then 'Account (Crosses)'
                   when ap_scope.generic_param_value = 'G' then 'DASH global parameters'
                   when ap_scope.generic_param_value = 'H' then 'Account (HFT)'
                   when ap_scope.generic_param_value = 'T' then 'Trading firm (Cloud)'
                   when ap_scope.generic_param_value = 'U' then 'Trading firm (Crosses)'
                   end                     as alert_scope, --Scope
               ap_clid.GENERIC_PARAM_VALUE AS cl_order_id, --Cl Ord ID
               ap_acc.GENERIC_PARAM_VALUE  AS account_name, --Account Name
               i.LAST_TRADE_DATE           as exp_date,
               i.symbol,
               co.side,
               co.price,
               co.order_qty                as qty
        from alert a
                 inner join alerts alerts on (a.alert_id = alerts.alert_id)
                 left join alert_param_value ap_clid
                           on (a.alert_id = ap_clid.alert_id and ap_clid.generic_param_key = 'CS_CLORDID')
                 left join alert_param_value ap_acc
                           on (a.alert_id = ap_acc.alert_id and ap_acc.generic_param_key = 'ACCT_NAME')
                 left join alert_param_value ap_scope
                           on (a.alert_id = ap_scope.alert_id and ap_scope.generic_param_key = 'RISK_SCOPE')
                 left join alert_param_value ap_prm
                           on (a.alert_id = ap_prm.alert_id and ap_prm.generic_param_key = 'OSR_PARAM')
                 left join alert_param_value ap_tf
                           on (a.alert_id = ap_tf.alert_id and ap_tf.generic_param_key = 'TR_FIRM_ID')
                 left join dwh.d_trading_firm tf on tf.trading_firm_id = ap_tf.generic_param_value
                 left join dwh.d_osr_param_dictionary osr on osr.osr_param_code = ap_prm.generic_param_value
                 left join dwh.client_order co on co.client_order_id = ap_clid.generic_param_value and
                                                  co.create_date_id between in_start_date_id and in_end_date_id
                 left join dwh.d_instrument i on co.instrument_id = i.instrument_id
        where a.severity = 'E'
        order by a.create_time desc;

end;
$fx$


