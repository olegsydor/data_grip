
with dwh_src as(
select
	'CLIENT_ORDER'::text AS table_name
	,&p_date_id::numeric as date_id
	,count(1)    AS cn
	,stddev(l2.client_order_id) AS client_order_id_dev
	,stddev(l2.order_id) AS order_id_dev
	,stddev(l2.order_qty) AS order_qty_dev
	,stddev(l2.account_id) AS account_id_dev
	,stddev(l2.sub_strategy_id) AS sub_strategy_id_dev
	,stddev(l2.transaction_id) AS transaction_id_dev
	,stddev(l2.locate_req) AS locate_req_dev
	,stddev(l2.discretion_offset) AS discretion_offset_dev
	,stddev(l2.step_up_price) AS step_up_price_dev
	,stddev(l2.cross_account_id) AS cross_account_id_dev
	,stddev(l2.session_eligibility) AS session_eligibility_dev
	,stddev(l2.opt_customer_firm_street) AS opt_customer_firm_street_dev
	,stddev(l2.consolidator_billing_type) AS consolidator_billing_type_dev
	,stddev(l2.cons_spi_instr) AS cons_spi_instr_dev
	,stddev(l2.is_held) AS is_held_dev
	,stddev(l2.orig_account_id) AS orig_account_id_dev
	,stddev(l2.order_text) AS order_text_dev
	,stddev(l2.trading_firm_id) AS trading_firm_id_dev
	,corr((l2.order_id)::double precision, (l2.client_order_id)::double precision) AS corr_client_order_id
	,corr((l2.order_id)::double precision, (l2.order_id)::double precision) AS corr_order_id
	,corr((l2.order_id)::double precision, (l2.order_qty)::double precision) AS corr_order_qty
	,corr((l2.order_id)::double precision, (l2.account_id)::double precision) AS corr_account_id
	,corr((l2.order_id)::double precision, (l2.sub_strategy_id)::double precision) AS corr_sub_strategy_id
	,corr((l2.order_id)::double precision, (l2.transaction_id)::double precision) AS corr_transaction_id
	,corr((l2.order_id)::double precision, (l2.locate_req)::double precision) AS corr_locate_req
	,corr((l2.order_id)::double precision, (l2.discretion_offset)::double precision) AS corr_discretion_offset
	,corr((l2.order_id)::double precision, (l2.step_up_price)::double precision) AS corr_step_up_price
	,corr((l2.order_id)::double precision, (l2.cross_account_id)::double precision) AS corr_cross_account_id
	,corr((l2.order_id)::double precision, (l2.session_eligibility)::double precision) AS corr_session_eligibility
	,corr((l2.order_id)::double precision, (l2.opt_customer_firm_street)::double precision) AS corr_opt_customer_firm_street
	,corr((l2.order_id)::double precision, (l2.consolidator_billing_type)::double precision) AS corr_consolidator_billing_type
	,corr((l2.order_id)::double precision, (l2.cons_spi_instr)::double precision) AS corr_cons_spi_instr
	,corr((l2.order_id)::double precision, (l2.is_held)::double precision) AS corr_is_held
	,corr((l2.order_id)::double precision, (l2.orig_account_id)::double precision) AS corr_orig_account_id
	,corr((l2.order_id)::double precision, (l2.order_text)::double precision) AS corr_order_text
	,corr((l2.order_id)::double precision, (l2.trading_firm_id)::double precision) AS corr_trading_firm_id,
	 corr((l2._exec_id)::double precision, (l2._last_qty)::double precision) AS pk_last_qty_corr,
 from
(select
	((('x'::text || lpad(md5((client_order_id)::text), 32, '0'::text)))::bit(64))::bigint as client_order_id
	,coalesce(order_id, 0) as order_id
	,coalesce(order_qty, 0) as order_qty
	,coalesce(create_date_id, 0) as create_date_id
	,coalesce(account_id, 0) as account_id
	,coalesce(sub_strategy_id, 0) as sub_strategy_id
	,coalesce(transaction_id, 0) as transaction_id
	,coalesce (ascii(locate_req), 0) as locate_req
	,coalesce(discretion_offset, 0) as discretion_offset
	,coalesce(step_up_price, 0) as step_up_price
	,coalesce(cross_account_id, 0) as cross_account_id
	,coalesce (ascii(session_eligibility), 0) as session_eligibility
	,coalesce (ascii(opt_customer_firm_street), 0) as opt_customer_firm_street
	,coalesce(consolidator_billing_type, 0) as consolidator_billing_type
	,coalesce (ascii(cons_spi_instr), 0) as cons_spi_instr
	,coalesce (ascii(is_held), 0) as is_held
	,coalesce(orig_account_id, 0) as orig_account_id
	,((('x'::text || lpad(md5((order_text)::text), 32, '0'::text)))::bit(64))::bigint as order_text
	,((('x'::text || lpad(md5((trading_firm_id)::text), 32, '0'::text)))::bit(64))::bigint as trading_firm_id
-- 	 date_part(''epoch''::text, ((((''now''::text)::date)::timestamp without time zone)::timestamp with time zone - (execution_1.exec_time)::timestamp with time zone)) AS _exec_time,
from dwh.client_order
where create_date_id in (&p_date_id, ( select to_char( public.get_business_date( ('&p_date_id'::varchar)::date,1 ),'YYYYMMDD')::int4))
and create_time >= to_date('&p_date_id'::varchar, 'YYYYMMDD') -- HARDCODE, change to variable
and create_time < to_date('&p_date_id'::varchar, 'YYYYMMDD') + interval '1 day'
ORDER BY order_id
) l2
)
insert into staging.sync_test_calculated_metrics (source_name, table_name, date_id, pg_db_updated_time, metric_cnt_rows
			, metric_name_01, metric_value_01, metric_name_02, metric_value_02, metric_name_03, metric_value_03, metric_name_04, metric_value_04, metric_name_05, metric_value_05
			, metric_name_06, metric_value_06, metric_name_07, metric_value_07, metric_name_08, metric_value_08, metric_name_09, metric_value_09, metric_name_10, metric_value_10
			, metric_name_11, metric_value_11, metric_name_12, metric_value_12, metric_name_13, metric_value_13, metric_name_14, metric_value_14, metric_name_15, metric_value_15
			, metric_name_16, metric_value_16, metric_name_17, metric_value_17, metric_name_18, metric_value_18, metric_name_19, metric_value_19, metric_name_20, metric_value_20
			, metric_name_21, metric_value_21, metric_name_22, metric_value_22, metric_name_23, metric_value_23, metric_name_24, metric_value_24, metric_name_25, metric_value_25
			, metric_name_26, metric_value_26, metric_name_27, metric_value_27, metric_name_28, metric_value_28, metric_name_29, metric_value_29, metric_name_30, metric_value_30
			, metric_name_31, metric_value_31, metric_name_32, metric_value_32, metric_name_33, metric_value_33, metric_name_34, metric_value_34, metric_name_35, metric_value_35
			, metric_name_36, metric_value_36)
select
	'DWH' as source_name
	, d.table_name as table_name
	, d.date_id as date_id
	, clock_timestamp() as pg_db_updated_time
	, d.cn::double precision as metric_cnt_rows
	, 'client_order_id_dev'::varchar as metric_name_01
	, d.client_order_id_dev::double precision as metric_value_01
	, 'order_id_dev'::varchar as metric_name_02
	, d.order_id_dev::double precision as metric_value_02
	, 'order_qty_dev'::varchar as metric_name_03
	, d.order_qty_dev::double precision as metric_value_03
	, 'account_id_dev'::varchar as metric_name_04
	, d.account_id_dev::double precision as metric_value_04
	, 'sub_strategy_id_dev'::varchar as metric_name_05
	, d.sub_strategy_id_dev::double precision as metric_value_05
	, 'transaction_id_dev'::varchar as metric_name_06
	, d.transaction_id_dev::double precision as metric_value_06
	, 'locate_req_dev'::varchar as metric_name_07
	, d.locate_req_dev::double precision as metric_value_07
	, 'discretion_offset_dev'::varchar as metric_name_08
	, d.discretion_offset_dev::double precision as metric_value_08
	, 'step_up_price_dev'::varchar as metric_name_09
	, d.step_up_price_dev::double precision as metric_value_09
	, 'cross_account_id_dev'::varchar as metric_name_10
	, d.cross_account_id_dev::double precision as metric_value_10
	, 'session_eligibility_dev'::varchar as metric_name_11
	, d.session_eligibility_dev::double precision as metric_value_11
	, 'opt_customer_firm_street_dev'::varchar as metric_name_12
	, d.opt_customer_firm_street_dev::double precision as metric_value_12
	, 'consolidator_billing_type_dev'::varchar as metric_name_13
	, d.consolidator_billing_type_dev::double precision as metric_value_13
	, 'cons_spi_instr_dev'::varchar as metric_name_14
	, d.cons_spi_instr_dev::double precision as metric_value_14
	, 'is_held_dev'::varchar as metric_name_15
	, d.is_held_dev::double precision as metric_value_15
	, 'orig_account_id_dev'::varchar as metric_name_16
	, d.orig_account_id_dev::double precision as metric_value_16
	, 'order_text_dev'::varchar as metric_name_17
	, d.order_text_dev::double precision as metric_value_17
	, 'trading_firm_id_dev'::varchar as metric_name_18
	, d.trading_firm_id_dev::double precision as metric_value_18
	, 'corr_client_order_id'::varchar as metric_name_19
	, d.corr_client_order_id::double precision as metric_value_19
	, 'corr_order_id'::varchar as metric_name_20
	, d.corr_order_id::double precision as metric_value_20
	, 'corr_order_qty'::varchar as metric_name_21
	, d.corr_order_qty::double precision as metric_value_21
	, 'corr_account_id'::varchar as metric_name_22
	, d.corr_account_id::double precision as metric_value_22
	, 'corr_sub_strategy_id'::varchar as metric_name_23
	, d.corr_sub_strategy_id::double precision as metric_value_23
	, 'corr_transaction_id'::varchar as metric_name_24
	, d.corr_transaction_id::double precision as metric_value_24
	, 'corr_locate_req'::varchar as metric_name_25
	, d.corr_locate_req::double precision as metric_value_25
	, 'corr_discretion_offset'::varchar as metric_name_26
	, d.corr_discretion_offset::double precision as metric_value_26
	, 'corr_step_up_price'::varchar as metric_name_27
	, d.corr_step_up_price::double precision as metric_value_27
	, 'corr_cross_account_id'::varchar as metric_name_28
	, d.corr_cross_account_id::double precision as metric_value_28
	, 'corr_session_eligibility'::varchar as metric_name_29
	, d.corr_session_eligibility::double precision as metric_value_29
	, 'corr_opt_customer_firm_street'::varchar as metric_name_30
	, d.corr_opt_customer_firm_street::double precision as metric_value_30
	, 'corr_consolidator_billing_type'::varchar as metric_name_31
	, d.corr_consolidator_billing_type::double precision as metric_value_31
	, 'corr_cons_spi_instr'::varchar as metric_name_32
	, d.corr_cons_spi_instr::double precision as metric_value_32
	, 'corr_is_held'::varchar as metric_name_33
	, d.corr_is_held::double precision as metric_value_33
	, 'corr_orig_account_id'::varchar as metric_name_34
	, d.corr_orig_account_id::double precision as metric_value_34
	, 'corr_order_text'::varchar as metric_name_35
	, d.corr_order_text::double precision as metric_value_35
	, 'corr_trading_firm_id'::varchar as metric_name_36
	, d.corr_trading_firm_id::double precision as metric_value_36
	from dwh_src as d
on conflict on constraint sync_test_calc_metrics_pkey do
update set
  pg_db_updated_time 	= excluded.pg_db_updated_time
, metric_cnt_rows    	= excluded.metric_cnt_rows
, metric_name_01	= excluded.metric_name_01
, metric_value_01	= excluded.metric_value_01
, metric_name_02	= excluded.metric_name_02
, metric_value_02	= excluded.metric_value_02
, metric_name_03	= excluded.metric_name_03
, metric_value_03	= excluded.metric_value_03
, metric_name_04	= excluded.metric_name_04
, metric_value_04	= excluded.metric_value_04
, metric_name_05	= excluded.metric_name_05
, metric_value_05	= excluded.metric_value_05
, metric_name_06	= excluded.metric_name_06
, metric_value_06	= excluded.metric_value_06
, metric_name_07	= excluded.metric_name_07
, metric_value_07	= excluded.metric_value_07
, metric_name_08	= excluded.metric_name_08
, metric_value_08	= excluded.metric_value_08
, metric_name_09	= excluded.metric_name_09
, metric_value_09	= excluded.metric_value_09
, metric_name_10	= excluded.metric_name_10
, metric_value_10	= excluded.metric_value_10
, metric_name_11	= excluded.metric_name_11
, metric_value_11	= excluded.metric_value_11
, metric_name_12	= excluded.metric_name_12
, metric_value_12	= excluded.metric_value_12
, metric_name_13	= excluded.metric_name_13
, metric_value_13	= excluded.metric_value_13
, metric_name_14	= excluded.metric_name_14
, metric_value_14	= excluded.metric_value_14
, metric_name_15	= excluded.metric_name_15
, metric_value_15	= excluded.metric_value_15
, metric_name_16	= excluded.metric_name_16
, metric_value_16	= excluded.metric_value_16
, metric_name_17	= excluded.metric_name_17
, metric_value_17	= excluded.metric_value_17
, metric_name_18	= excluded.metric_name_18
, metric_value_18	= excluded.metric_value_18
, metric_name_19	= excluded.metric_name_19
, metric_value_19	= excluded.metric_value_19
, metric_name_20	= excluded.metric_name_20
, metric_value_20	= excluded.metric_value_20
, metric_name_21	= excluded.metric_name_21
, metric_value_21	= excluded.metric_value_21