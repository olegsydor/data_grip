
select client_order_id, count(*)
	from staging.trade_record_missed_lp
		where date_id = 20241016
group by client_order_id
having count(*) > 1

create temp table t_new as
select *
	from trash.so_missed_lp
		where date_id = 20241017
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



---
select *
FROM trash.so_away_trade aw
     LEFT JOIN LATERAL ( SELECT lm_1.id,
            lm_1.mic_code,
            lm_1.security_type,
            lm_1.venue_exchange,
            lm_1.business_name,
            lm_1.ex_destination,
            lm_1.last_mkt
           FROM staging.d_blaze_exchange_codes lm_1
          WHERE COALESCE(lm_1.last_mkt, lm_1.ex_destination)::text = aw.ex_destination AND
                CASE
                    WHEN aw.securitytype = '1'::text THEN 'O'::text
                    WHEN aw.securitytype IS NULL THEN 'O'::text
                    WHEN aw.securitytype = '2'::text THEN 'E'::text
                    ELSE aw.securitytype
                END = lm_1.security_type::text
         LIMIT 1) lm ON true
     LEFT JOIN staging.t_users us ON us.user_id = aw.userid::integer
     LEFT JOIN LATERAL ( SELECT den_1.last_mkt
           FROM billing.dash_exchange_names den_1
          WHERE den_1.mic_code::text = COALESCE(lm.ex_destination, aw.ex_destination::character varying)::text AND den_1.real_exchange_id::text = den_1.exchange_id::text AND den_1.mic_code::text <> ''::text AND den_1.is_active
         LIMIT 1) den ON true
     LEFT JOIN LATERAL ( SELECT den1_1.last_mkt,
            den1_1.mic_code
           FROM billing.dash_exchange_names den1_1
          WHERE den1_1.exchange_id::text = COALESCE(lm.ex_destination, aw.ex_destination::character varying)::text AND den1_1.real_exchange_id::text = den1_1.exchange_id::text AND den1_1.mic_code::text <> ''::text AND den1_1.is_active
         LIMIT 1) den1 ON true
     LEFT JOIN staging.d_time_in_force tif ON tif.enum = aw.co_time_in_force
     LEFT JOIN billing.time_in_force ltf ON tif.id = ltf.code AND ltf.systemid = 8
     LEFT JOIN billing.lforwhom lfw ON lfw.shortdesc::text = aw.option_range AND lfw.systemid = 4
     LEFT JOIN billing.tcompany cmp ON us.company_id = cmp.companyid AND us.system_id = cmp.systemid AND cmp.edwactive = 1::bit(1)
     LEFT JOIN staging.d_liquidity_type lt ON aw.rep_liquidity_type = lt.enum::text
   left join staging.d_blaze_order_status bos on aw.status = bos.enum and bos.order_or_report_status = 2
   left join staging.l_order_status los on bos.id = los.statuscode and los.systemid = 8
   left join staging.d_order_class oc on oc.enum = aw.systemordertypeid
   left join staging.l_order_type lot on oc.ID = lot.Code and lot.SystemID = 8
  WHERE true
    AND (aw.status = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
   and aw.cl_ord_id in ('1_1q4241017')
 and exec_id in ('jelu6ngc0000', 'jelucahg0002', 'jelucaho0002', 'jelu6ngk0004');


select report_exec_id_guid, cl_ord_id
from trash.so_away_trade
where date_id = 20241017
and report_cl_ord_id_guid ilike '00000000-0001-0000-0000-03471313AD79'

select * from trash.so_missed_lp
where date_id = 20241017
  and client_order_id =  '1_1q4241017'
and order_id_guid ilike '00000000-0001-0000-0000-03471313AD79'
