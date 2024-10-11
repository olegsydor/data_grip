where (case when coalesce(in_accounts, '{}') = '{}' then false else vi.account_id = any (in_accounts) end
        	   or case when coalesce(in_trader_ids, '{}') = '{}' then false else vi.trader_internal_id = any (in_trader_ids) end)

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
DECLARE
    l_row_cnt integer;
    l_load_id integer;
    l_step_id integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_risk_credit_utilization for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;

    return query
SELECT 'Parameter,Scope,Security Type,Value,Trading Firm,Account,Trader,Min Notional,Max Notional,Average Notional,Max % Utilization';

    return query
        with cte_daily as
(
	select rlu.security_type, rlu.risk_limit_parameter, rlu.date_id, tf.trading_firm_name, rlu.tf_risk_limit_param_max_value, rlu.tf_avg, rlu.tf_sum
	from dash_bi.risk_limit_usage_dt rlu
	join dwh.d_account a on (a.account_id = rlu.account_id)
	join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
	where rlu.date_id between :in_start_date_id and :in_end_date_id
		and rlu.trading_firm_id = any(:in_trading_firm_ids)
	and a.is_active
	and tf.is_active
	group by rlu.security_type, rlu.risk_limit_parameter, rlu.date_id, tf.trading_firm_name, rlu.tf_risk_limit_param_max_value, rlu.tf_avg, rlu.tf_sum
	--order by rlu.security_type, rlu.risk_limit_parameter, rlu.date_id, tf.trading_firm_name, rlu.tf_risk_limit_param_max_value, rlu.tf_avg, rlu.tf_sum
),
cte_param as
(
	select
		replace(rlp.osr_param_name, '_LowTouch', '') as norm_osr_param_name, --What should we deal with it? EquityTotalNotionalNonCross_LowTouch vs EquityTotalNotionalNonCross?
		rlp.*
	from staging.risk_limits_osr_param_v rlp
	where rlp.osr_param_name ilike '%totalnotional%'
		and rlp.trading_firm_id = any(in_trading_firm_ids)
)
select
	d.risk_limit_parameter as "Parameter",
	'Trading Firm -Level' as "Scope", --We should make it works for other scopes as well (Trading Firm, Account, Trader)
	d.security_type as "Security Type",
	p.osr_param_value::numeric as "Value",
	d.trading_firm_name as "Trading Firm",
	null as "Account",
	null as "Trader",
	round(min(d.tf_sum), 2) as "Min Notional",
	round(max(d.tf_sum), 2) as "Max Notional",
	round(avg(d.tf_sum), 2) as "Average Notional",
	round(max(d.tf_sum) / p.osr_param_value::numeric, 4) as "Max % Utilization"

from cte_daily as d
join cte_param as p on (p.norm_osr_param_name = d.risk_limit_parameter)
group by "Parameter", "Scope", "Security Type", "Value", "Trading Firm", "Account", "Trader"
order by "Parameter", "Scope", "Security Type", "Value", "Trading Firm", "Account", "Trader";

        $fx$



select distinct on (rlu.security_type, rlu.risk_limit_parameter, rlu.date_id, rlu.tf_risk_limit_param_max_value, rlu.tf_avg, rlu.tf_sum, tf.trading_firm_name) rlu.security_type,
                                                                                                                                                               rlu.risk_limit_parameter,
                                                                                                                                                               rlu.date_id,
                                                                                                                                                               rlu.tf_risk_limit_param_max_value,
                                                                                                                                                               rlu.tf_avg,
                                                                                                                                                               rlu.tf_sum,
                                                                                                                                                               tf.trading_firm_name
from dash_bi.risk_limit_usage_dt rlu
         join dwh.d_account a on (a.account_id = rlu.account_id)
         join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
where rlu.date_id between :in_start_date_id and :in_end_date_id
  and rlu.trading_firm_id = any (:in_trading_firm_ids)
-- 	and a.is_active
-- 	and tf.is_active
