select tf.trading_firm_id, * from dwh.d_account da
join dwh.d_trading_firm tf on tf.trading_firm_unq_id = da.trading_firm_unq_id
left join staging.trader2trading_firm ttf on ttf.trading_firm_id = tf.trading_firm_id
left join dwh.d_trader dt on dt.trader_internal_id = ttf.trader_internal_id
where (case when coalesce(:in_accounts, '{}') = '{}' then false else da.account_id = any (:in_accounts) end
        	   or case when coalesce(:in_trader_ids, '{}') = '{}' then false else ttf.trader_internal_id = any (:in_trader_ids) end
    or case when coalesce(:in_trading_firm_ids, '{}') = '{}' then false else tf.trading_firm_id = any(:in_trading_firm_ids) end);


select array_agg(distinct tf.trading_firm_id), array_agg(da.account_id)
from dwh.d_account da
join dwh.d_trading_firm tf on tf.trading_firm_unq_id = da.trading_firm_unq_id
left join staging.trader2trading_firm ttf on ttf.trading_firm_id = tf.trading_firm_id
-- left join dwh.d_trader dt on dt.trader_internal_id = ttf.trader_internal_id
where (case when coalesce(:in_accounts, '{}') = '{}' then true else da.account_id = any (:in_accounts) end
        	   and case when coalesce(:in_trader_ids, '{}') = '{}' then true else ttf.trader_internal_id = any (:in_trader_ids) end
    and case when coalesce(:in_trading_firm_ids, '{}') = '{}' then true else tf.trading_firm_id = any(:in_trading_firm_ids) end);

alter function dash360.report_risk_credit_utilization rename to report_risk_credit_utilization_csv;
create or replace function dash360.report_risk_credit_utilization(in_start_date_id int4, in_end_date_id int4,
                                                                  in_trading_firm_ids character varying[] default '{"OFP0016"}'::character varying[],
                                                                  in_account_ids int4[] default '{}'::int4[],
                                                                  in_trader_ids int8[] default '{}'::int8[],
                                                                  in_instrument_type_id char default null::char)
    returns table
            (
                export_row text
            )
    language plpgsql
AS
$fx$
    -- 20241011 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4990
declare
    l_row_cnt          int;
    l_load_id          int;
    l_step_id          int;
    l_account_ids      int[];
    l_trading_firm_ids text[];

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_risk_credit_utilization for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;

    select array_agg(distinct tf.trading_firm_id), array_agg(da.account_id)
    into l_trading_firm_ids, l_account_ids
    from dwh.d_account da
             join dwh.d_trading_firm tf on tf.trading_firm_unq_id = da.trading_firm_unq_id
             left join staging.trader2trading_firm ttf on ttf.trading_firm_id = tf.trading_firm_id
    where (case when coalesce(in_account_ids, '{}') = '{}' then true else da.account_id = any (in_account_ids) end
        and case
                when coalesce(in_trader_ids, '{}') = '{}' then true
                else ttf.trader_internal_id = any (in_trader_ids) end
        and case
                when coalesce(in_trading_firm_ids, '{}') = '{}' then true
                else tf.trading_firm_id = any (in_trading_firm_ids) end);


    return query
        SELECT 'Parameter,Scope,Security Type,Value,Trading Firm,Account,Trader,Min Notional,Max Notional,Average Notional,Max % Utilization';

    return query
        with cte_daily as
            (select distinct rlu.security_type,
                             rlu.risk_limit_parameter,
                             rlu.date_id,
                             rlu.tf_risk_limit_param_max_value,
                             rlu.tf_avg,
                             rlu.tf_sum,
                             tf.trading_firm_name
             from dash_bi.risk_limit_usage_dt rlu
                      join dwh.d_account da using (account_id)
                      join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = da.trading_firm_unq_id)
             where rlu.date_id between in_start_date_id and in_end_date_id
               and da.account_id = any (l_account_ids)
               and case
                       when in_instrument_type_id is null then true
                       when in_instrument_type_id = 'O' then rlu.security_type = 'Option'
                       when in_instrument_type_id = 'E' then rlu.security_type = 'Equity'
                       when in_instrument_type_id = 'M' then rlu.security_type = 'Multileg'
                 end)
           , cte_param as
            (select replace(rlp.osr_param_name, '_LowTouch', '') as norm_osr_param_name, --What should we deal with it? EquityTotalNotionalNonCross_LowTouch vs EquityTotalNotionalNonCross?
                    rlp.*
             from staging.risk_limits_osr_param_v rlp
             where rlp.osr_param_name ilike '%totalnotional%'
               and rlp.trading_firm_id = any (l_trading_firm_ids))
        select array_to_string(ARRAY [
                                   d.risk_limit_parameter , -- as "Parameter",
                                   'Trading Firm -Level' , -- as "Scope", --We should make it works for other scopes as well (Trading Firm, Account, Trader)
                                   d.security_type , -- as "Security Type",
                                   p.osr_param_value , -- as "Value",
                                   d.trading_firm_name , -- as "Trading Firm",
                                   null , -- as "Account",
                                   null , -- as "Trader",
                                   round(min(d.tf_sum), 2)::text , -- as "Min Notional",
                                   round(max(d.tf_sum), 2)::text , -- as "Max Notional",
                                   round(avg(d.tf_sum), 2)::text , -- as "Average Notional",
                                   round(max(d.tf_sum) / p.osr_param_value::numeric, 4)::text -- as "Max % Utilization"
                                   ], ',', '')
        from cte_daily as d
                 join cte_param as p on (p.norm_osr_param_name = d.risk_limit_parameter)
        group by d.risk_limit_parameter, d.security_type, p.osr_param_value, d.trading_firm_name
        order by d.risk_limit_parameter, d.security_type, p.osr_param_value, d.trading_firm_name;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_risk_credit_utilization for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' completed====', l_row_cnt, 'E')
    into l_step_id;
end;
$fx$;




select * from dash360.report_risk_credit_utilization(in_start_date_id := 20240701, in_end_date_id := 20240930);
select * from dash360.report_risk_credit_utilization(in_start_date_id := 20240701, in_end_date_id := 20240930, in_trading_firm_ids := '{"OFP0016", "OFP0050"}');
select * from dash360.report_risk_credit_utilization(in_start_date_id := 20240701, in_end_date_id := 20240930, in_trading_firm_ids := null);

select distinct on (rlu.security_type, rlu.risk_limit_parameter, rlu.date_id, rlu.tf_risk_limit_param_max_value, rlu.tf_avg, rlu.tf_sum, tf.trading_firm_name) rlu.security_type,
                                                                                                                                                                            rlu.risk_limit_parameter,
                                                                                                                                                                            rlu.date_id,
                                                                                                                                                                            rlu.tf_risk_limit_param_max_value,
                                                                                                                                                                            rlu.tf_avg,
                                                                                                                                                                            rlu.tf_sum,
                                                                                                                                                                            tf.trading_firm_name,
                                                                                                                                                                            tf.trading_firm_id
             from dash_bi.risk_limit_usage_dt rlu
                      join dwh.d_account da using (account_id)
                      join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = da.trading_firm_unq_id)
             where rlu.date_id between :in_start_date_id and :in_end_date_id
and da.trading_firm_id != 'OFP0016'