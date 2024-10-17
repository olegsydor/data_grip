
select client_order_id, count(*)
	from staging.trade_record_missed_lp
		where date_id = 20241016
group by client_order_id
having count(*) > 1

create temp table t_new as
select *
	from trash.so_missed_lp
		where date_id = 20241016
and client_order_id = '1_106241016';

create temp table t_old as
select *
	from staging.trade_record_missed_lp
		where date_id = 20241016
and client_order_id = '1_106241016';


select
--     distinct
    order_id,
       order_id_guid,
       rep_ex_destination,
       trade_record_time,
       db_create_time,
       date_id,
       is_busted,
       subsystem_id,
       account_name,
       client_order_id,
       instrument_id,
       side,
       openclose,
       exec_id,
       exch_exec_id,
       secondary_exch_exec_id,
       last_mkt,
       last_qty,
       last_px,
       ex_destination,
       sub_strategy,
       street_order_qty,
       order_qty,
       multileg_reporting_type,
       exec_broker,
       cmta,
       tif,
       street_time_in_force,
       opt_customer_firm,
       is_cross_order,
       contra_broker,
       client_id,
       order_price,
       order_process_time,
       remarks,
       street_client_order_id,
       fix_comp_id,
       leaves_qty,
       leg_ref_id,
       load_batch_id,
       strategy_decision_reason_code,
       is_parent,
       symbol,
       strike_price,
       type_code,
       put_or_call,
       maturuty_year,
       maturuty_month,
       maturuty_day,
       security_type,
       child_orders,
       handling,
       secondary_order_id2,
       display_instrument_id,
       instrument_type_id,
       activ_symbol,
       mapping_logic,
       commision_rate_unit,
       is_sor_routed,
       is_company_name_changed,
       company_name,
       generation,
       mx_gen,
       parent_order_id,
       mic_code,
       option_range,
       client_entity_id,
       status,
       trade_liquidity_indicator,
       order_create_time,
       blaze_account_alias
, edw_status
, system_order_type_id
from t_new tn;

select 'new' as src,
       client_order_id,
       side,
       openclose,
       exch_exec_id,
       secondary_exch_exec_id,
       last_mkt,
       last_qty,
       last_px,
       ex_destination,
       street_order_qty::int,
       order_qty::int,
       multileg_reporting_type::text,
       exec_broker,
       cmta,
       street_time_in_force::text,
       opt_customer_firm,
       is_cross_order,
       contra_broker,
       client_id,
       order_price,
       leaves_qty::int,
       symbol,
       strike_price,
       put_or_call,
       maturuty_year,
       maturuty_month,
       maturuty_day,
       security_type,
       display_instrument_id,
       instrument_type_id,
       activ_symbol,
       company_name,
       generation::int,
       mx_gen::int
-- , edw_status
-- , system_order_type_id
from t_new
union all
select 'old' as src,
       client_order_id,
       side,
       open_close,
       exch_exec_id,
       secondary_exch_exec_id,
       last_mkt,
       last_qty,
       last_px,
       ex_destination,
       street_order_qty,
       order_qty,
       multileg_reporting_type::text,
       exec_broker,
       cmta,
       street_time_in_force,
       opt_customer_firm,
       is_cross_order,
       contra_broker,
       client_id,
       order_price,
       leaves_qty,
       symbol,
       strike_price,
       put_or_call,
       maturity_year,
       maturity_month,
       maturity_day,
       security_type,
       display_instrument_id,
       instrument_type_id,
       activ_symbol,
       companyname,
       generation,
       mx_gen
from t_old