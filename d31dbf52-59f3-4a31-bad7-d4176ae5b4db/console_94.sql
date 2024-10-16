create or replace function dash360.report_risk_credit_utilization(in_start_date_id int4, in_end_date_id int4,
                                                                  in_trading_firm_ids character varying[] default '{}'::character varying[],
                                                                  in_account_ids int4[] default '{}'::int4[],
                                                                  in_trader_ids int8[] default '{}'::int8[],
                                                                  in_instrument_type_id char default null::char)
    returns table
            (
                "Parameter"         text,
                "Scope"             text,
                "Security Type"     text,
                "Value"             numeric,
                "Trading Firm"      text,
                "Account"           text,
                "Trader"            text,
                "Min Notional"      numeric,
                "Max Notional"      numeric,
                "Avg Notional"      numeric,
                "Min % Utilization" numeric,
                "Max % Utilization" numeric,
                "Avg % Utilization" numeric
            )
    language plpgsql
AS
$fx$
    -- 20241011 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4990
declare
    l_row_cnt    int;
    l_load_id    int;
    l_step_id    int;
    l_trader_ids text[] := array(select dt.trader_id
                                 from dwh.d_trader dt
                                 where dt.trader_internal_id = any (in_trader_ids));

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_risk_credit_utilization for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;

    return query
        with account_data as
            (select distinct rlu.security_type,
                             rlu.risk_limit_parameter,
                             rlu.date_id,
                             rlu.acc_risk_limit_param_max_value,
                             rlu.acc_avg,
                             rlu.acc_sum,
                             ac.account_name,
                             ac.account_id
             from dash_bi.risk_limit_usage_dt rlu
                      join dwh.d_account ac using (account_id)
                      join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = ac.trading_firm_unq_id)
             where true
               and rlu.date_id between in_start_date_id and in_end_date_id
               and case
                       when coalesce(in_account_ids, '{}') = '{}' then true
                       else rlu.account_id = any (in_account_ids) end
               and case
                       when coalesce(in_trading_firm_ids, '{}') = '{}' then true
                       else rlu.trading_firm_id = any (in_trading_firm_ids) end
               and case
                       when coalesce(in_trader_ids, '{}') = '{}' then true
                       else rlu.trader_id = any (l_trader_ids) end
               and case
                       when in_instrument_type_id is null then true
                       when in_instrument_type_id = 'O' then rlu.security_type = 'Option'
                       when in_instrument_type_id = 'E' then rlu.security_type = 'Equity'
                       when in_instrument_type_id = 'M' then rlu.security_type = 'Multileg'
                 end)
           , trading_firm_data as
            (select distinct rlu.security_type,
                             rlu.risk_limit_parameter,
                             rlu.date_id,
                             rlu.tf_risk_limit_param_max_value,
                             rlu.tf_avg,
                             rlu.tf_sum,
                             tf.trading_firm_name,
                             tf.trading_firm_id
             from dash_bi.risk_limit_usage_dt rlu
                      join dwh.d_account ac using (account_id)
                      left join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = ac.trading_firm_unq_id)
             where true
               and rlu.date_id between in_start_date_id and in_end_date_id
               and case
                       when coalesce(in_account_ids, '{}') = '{}' then true
                       else rlu.account_id = any (in_account_ids) end
               and case
                       when coalesce(in_trading_firm_ids, '{}') = '{}' then true
                       else rlu.trading_firm_id = any (in_trading_firm_ids) end
               and case
                       when coalesce(in_trader_ids, '{}') = '{}' then true
                       else rlu.trader_id = any (l_trader_ids) end
               and case
                       when in_instrument_type_id is null then true
                       when in_instrument_type_id = 'O' then rlu.security_type = 'Option'
                       when in_instrument_type_id = 'E' then rlu.security_type = 'Equity'
                       when in_instrument_type_id = 'M' then rlu.security_type = 'Multileg'
                 end)

           , trader_data as
            (select distinct rlu.security_type,
                             rlu.risk_limit_parameter,
                             rlu.date_id,
                             rlu.trd_risk_limit_param_max_value,
                             rlu.trd_avg,
                             rlu.trd_sum,
                             rlu.trader_id,
                             dt.trader_internal_id
             from dash_bi.risk_limit_usage_dt rlu
                      join dwh.d_trader dt using (trader_id)
             where true
               and rlu.date_id between in_start_date_id and in_end_date_id
               and case
                       when coalesce(in_account_ids, '{}') = '{}' then true
                       else rlu.account_id = any (in_account_ids) end
               and case
                       when coalesce(in_trading_firm_ids, '{}') = '{}' then true
                       else rlu.trading_firm_id = any (in_trading_firm_ids) end
               and case
                       when coalesce(in_trader_ids, '{}') = '{}' then true
                       else dt.trader_internal_id = any (in_trader_ids) end
               and case
                       when in_instrument_type_id is null then true
                       when in_instrument_type_id = 'O' then rlu.security_type = 'Option'
                       when in_instrument_type_id = 'E' then rlu.security_type = 'Equity'
                       when in_instrument_type_id = 'M' then rlu.security_type = 'Multileg'
                 end
               and rlu.trader_id is not null)

           , cte_param as
            (select replace(rlp.osr_param_name, '_LowTouch', '') as norm_osr_param_name, --What should we deal with it? EquityTotalNotionalNonCross_LowTouch vs EquityTotalNotionalNonCross?
                    rlp.*
             from staging.risk_limits_osr_param_v rlp
             where rlp.osr_param_name ilike '%totalnotional%'
               and (case
                       when coalesce(in_trading_firm_ids, '{}') = '{}' then false
                       else rlp.trading_firm_id = any (in_trading_firm_ids) end
               or case
                       when coalesce(in_account_ids, '{}') = '{}' then false
                       else rlp.account_id = any (in_account_ids) end
               or case
                       when coalesce(in_trader_ids, '{}') = '{}' then true
                       else rlp.trader_internal_id = any (in_trader_ids) end))
        -- account_level
        select acd.risk_limit_parameter::text                                   as "Parameter",
               'Account -Level'                                                 as "Scope", --We should make it works for other scopes as well (Trading Firm, Account, Trader)
               acd.security_type::text                                          as "Security Type",
               p.osr_param_value::numeric                                       as "Value",
               null::text                                                       as "Trading Firm",
               acd.account_name::text                                           as "Account",
               null::text                                                       as "Trader",
               round(min(acd.acc_sum), 2)::numeric                              as "Min Notional",
               round(max(acd.acc_sum), 2)::numeric                              as "Max Notional",
               round(avg(acd.acc_sum), 2)::numeric                              as "Avg Notional",
               round(min(acd.acc_sum) / p.osr_param_value::numeric, 4)::numeric as "Max % Utilization",
               round(max(acd.acc_sum) / p.osr_param_value::numeric, 4)::numeric as "Min % Utilization",
               round(avg(acd.acc_sum) / p.osr_param_value::numeric, 4)::numeric as "Avg % Utilization"
        from account_data as acd
                 join cte_param as p
                      on (p.norm_osr_param_name = acd.risk_limit_parameter and acd.account_id = p.account_id)
        where true
          and case when coalesce(in_account_ids, '{}') = '{}' then false else true end
        group by acd.risk_limit_parameter, acd.security_type, p.osr_param_value, acd.account_name
--         order by acd.risk_limit_parameter, acd.security_type, p.osr_param_value, acd.account_name

        union all

        -- trading_firm level
        select acd.risk_limit_parameter::text                                  as "Parameter",
               'Trading Firm -Level'                                           as "Scope", --We should make it works for other scopes as well (Trading Firm, Account, Trader)
               acd.security_type::text                                         as "Security Type",
               p.osr_param_value::numeric                                      as "Value",
               acd.trading_firm_name::text                                     as "Trading Firm",
               null::text                                                      as "Account",
               null::text                                                      as "Trader",
               round(min(acd.tf_sum), 2)::numeric                              as "Min Notional",
               round(max(acd.tf_sum), 2)::numeric                              as "Max Notional",
               round(avg(acd.tf_sum), 2)::numeric                              as "Avg Notional",
               round(min(acd.tf_sum) / p.osr_param_value::numeric, 4)::numeric as "Max % Utilization",
               round(max(acd.tf_sum) / p.osr_param_value::numeric, 4)::numeric as "Min % Utilization",
               round(avg(acd.tf_sum) / p.osr_param_value::numeric, 4)::numeric as "Avg % Utilization"

        from trading_firm_data as acd
                 join cte_param as p on (p.norm_osr_param_name = acd.risk_limit_parameter and acd.trading_firm_id = p.trading_firm_id)
        where true
          and case when coalesce(in_trading_firm_ids, '{}') = '{}' then false else true end
        group by acd.risk_limit_parameter, acd.security_type, p.osr_param_value, acd.trading_firm_name

        union all
        -- trader level
        select acd.risk_limit_parameter::text                                   as "Parameter",
               'Trader -Level'                                                  as "Scope", --We should make it works for other scopes as well (Trading Firm, Account, Trader)
               acd.security_type::text                                          as "Security Type",
               p.osr_param_value::numeric                                       as "Value",
               null::text                                                       as "Trading Firm",
               null::text                                                       as "Account",
               acd.trader_id::text                                              as "Trader",
               round(min(acd.trd_sum), 2)::numeric                              as "Min Notional",
               round(max(acd.trd_sum), 2)::numeric                              as "Max Notional",
               round(avg(acd.trd_sum), 2)::numeric                              as "Avg Notional",
               round(min(acd.trd_sum) / p.osr_param_value::numeric, 4)::numeric as "Max % Utilization",
               round(max(acd.trd_sum) / p.osr_param_value::numeric, 4)::numeric as "Min % Utilization",
               round(avg(acd.trd_sum) / p.osr_param_value::numeric, 4)::numeric as "Avg % Utilization"
        from trader_data as acd
                 join cte_param as p on (p.norm_osr_param_name = acd.risk_limit_parameter and acd.trader_internal_id = p.trader_internal_id)
        where true
          and case when coalesce(in_trader_ids, '{}') = '{}' then false else true end
        group by acd.risk_limit_parameter, acd.security_type, p.osr_param_value, acd.trader_id

        order by 1, 2, 3, 4, 5, 6;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_risk_credit_utilization for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' completed====', l_row_cnt, 'E')
    into l_step_id;
end;
$fx$;




select * from dash360.report_risk_credit_utilization(in_start_date_id := 20240701, in_end_date_id := 20240930, in_trader_ids := '{182,233,223,160}');
select * from dash360.report_risk_credit_utilization(in_start_date_id := 20240701, in_end_date_id := 20240930, in_account_ids := '{142,1183,1446,1472,2925,2928,3481,6329,6331,6670,7548,7612,7670,7671,8712,9234,9251,9264,9374,9432,10423,10492,11203,11209,11239,11240,11241,11806,11808,11820,11826,11844,11881,11941,11948,12001,12013,12264,12271,12351,12397,12657,12713,12757,12770,12833,12909}');
select * from dash360.report_risk_credit_utilization(in_start_date_id := 20240701, in_end_date_id := 20240930, in_trading_firm_ids := '{"OFP0016"}');


select *
from dash360.report_risk_credit_utilization(
 in_start_date_id := 20240701,
 in_end_date_id := 20240930,
 in_trading_firm_ids := '{"ctctrad01"}',
 in_account_ids := '{24508,24505,24614,24507}'
);


select replace(rlp.osr_param_name, '_LowTouch', '') as norm_osr_param_name, --What should we deal with it? EquityTotalNotionalNonCross_LowTouch vs EquityTotalNotionalNonCross?
                    rlp.*
             from staging.risk_limits_osr_param_v rlp
             where rlp.osr_param_name ilike '%totalnotional%'
               and (case
                       when coalesce(:in_trading_firm_ids, '{}') = '{}' then false
                       else rlp.trading_firm_id = any (:in_trading_firm_ids) end
               or case
                       when coalesce(:in_account_ids, '{}') = '{}' then false
                       else rlp.account_id = any (:in_account_ids) end)
               or case
                       when coalesce(in_trader_ids, '{}') = '{}' then false
                       else rlp.trader_internal_id = any (in_trader_ids) end