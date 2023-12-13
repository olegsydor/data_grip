{"params":{"file_fmt":"Excel","theme":"White","file_name_template":null,"tf_id":"OFP0011","date_range":["2023-11-06T05:00:00.000Z","2023-11-11T04:59:00.000Z"],"is_generate_empty_file":"No"},"repId":"risk_alerts","reportConfigurationId":34}


    create temp table alert as
    select a.alert_id, a.severity, a.create_time, a.alert_text
    from staging.alert a
             inner join staging.alert_param_value ap
                        on (a.alert_id = ap.alert_id and ap.generic_param_key = 'RISK_ALERT')
             inner join staging.alert_param_value ap_tf
                        on (a.alert_id = ap_tf.alert_id and ap_tf.generic_param_key = 'TR_FIRM_ID')
    where true
      and ap.generic_param_value = 'Y'
      and ap_tf.generic_param_value = 'OFP0011'
      and a.create_time between :in_start_date::timestamp and :in_end_date::timestamp + interval '1 day'
      and a.severity = 'E';

    select array_agg(distinct alert_id) from alert into alerts_id;





    create temp table alert_param_value as
    select apv.alert_id, apv.generic_param_key, apv.generic_param_value
    from staging.alert_param_value apv
             where apv.alert_id = any(:alerts_id);

    create index on alert_param_value (alert_id, generic_param_key);
    create index on alert_param_value (generic_param_value);


        with alerts as (select a.alert_id
                        from alert a)
        SELECT a.CREATE_TIME                  alert_time,--Event Time
               case
                   when a.severity = 'E' then 'Error'
                   when a.severity = 'F' then 'Fatal'
                   when a.severity = 'N' then 'Note'
                   when a.severity = 'W' then 'Warning'
                   end                        severity,--Severity
              osr.OSR_PARAM_NAME osr_prm_name,--Risk Parameter
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
                                                  co.create_date_id between :in_start_date_id and :in_end_date_id
                 left join dwh.d_instrument i on co.instrument_id = i.instrument_id
        where a.severity = 'E'
        order by a.create_time desc;

end;
$function$
;
