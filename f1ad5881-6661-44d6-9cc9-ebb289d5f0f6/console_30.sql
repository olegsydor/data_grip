ALTER TABLE dwh.flat_trade_record_dmpsrc ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE dwh.flat_trade_record_old ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE dwh.request_for_quote ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE dwh_new.conditional_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE dwh.conditional_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_dmp_ftr ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_dmp_trade_record ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_flat_trade_record ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_oracle_cond_exec_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_oracle_cond_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_oracle_trade_record ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_trade_record ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.pd_flat_trade_record ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.temp_conditional_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
--ALTER TABLE staging.tlnd_conditional_order_123 ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
--ALTER TABLE staging.tlnd_load_exhausted_dash_trades ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
--ALTER TABLE staging.tlnd_temp_conditional_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
--ALTER TABLE staging.trade_record_missed_lp ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_cond_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;
ALTER TABLE staging.dmp_db_comp_conditional_execution_order ALTER COLUMN fix_connection_id TYPE int4 USING fix_connection_id::int4;



DROP FOREIGN TABLE staging.exchange_connection;

CREATE FOREIGN TABLE staging.exchange_connection (
	exchange_id varchar(6) NOT NULL,
	exchange_connector_id varchar(30) NOT NULL,
	fix_connection_id int4 NOT NULL,
	fix_engine_session_id varchar(30) NULL,
	create_time timestamptz(3) NOT NULL,
	is_deleted bpchar(1) NOT NULL,
	delete_time timestamptz(3) NULL,
	description varchar(256) NULL,
	client_order_id_range_mask varchar(30) NULL,
	exch_lb_instance_name varchar(20) NULL,
	uid_complex_pattern_id varchar(32) NULL,
	exchange_connection_id int8 OPTIONS(key 'true') NOT NULL,
	intended_scope_of_use bpchar(1) NOT NULL,
	fix_session_role int2 NOT NULL,
	leg_uid_complex_pattern_id varchar(32) NULL
)
SERVER oracle_prod
OPTIONS (schema 'GENESIS2_QA_20100601', table 'EXCHANGE_CONNECTION');


DROP FOREIGN TABLE staging.fix_connection;

CREATE FOREIGN TABLE staging.fix_connection (
	fix_connection_id int4 OPTIONS(key 'true') NOT NULL,
	acceptor_id varchar(30) NOT NULL,
	heartbeat_interval int2 NULL,
	fix_comp_id varchar(30) NOT NULL,
	start_time varchar(5) NULL,
	terminate_time varchar(5) NULL,
	in_seq_num int8 NOT NULL,
	out_seq_num int8 NOT NULL,
	force_seq_num_reset bpchar(1) NULL,
	description varchar(256) NULL,
	recreate_on_logout bpchar(1) NOT NULL,
	intraday_logout_tolerance bpchar(1) NOT NULL,
	force_reconnect bpchar(1) NOT NULL,
	rej_no_connection bpchar(1) NOT NULL,
	ign_seq_too_low_logon bpchar(1) NOT NULL,
	max_msg_in_bunch int8 NOT NULL,
	tcp_buffer_disabled bpchar(1) NOT NULL,
	user_name varchar(30) NULL,
	user_name_tag int4 NULL,
	"password" varchar(16) NULL,
	password_tag int4 NULL,
	password_tag_length int2 NULL,
	sender_sub_id varchar(20) NULL,
	target_sub_id varchar(20) NULL,
	create_time timestamptz(3) NOT NULL,
	is_deleted bpchar(1) NOT NULL,
	delete_time timestamptz(3) NULL,
	is_high_frequency_trader bpchar(1) NOT NULL,
	config_session_name varchar(30) NULL,
	allow_msg_wo_poss_dup_flag bpchar(1) NULL,
	sub_system_id varchar(20) NULL,
	expected_start_time varchar(5) NULL,
	expected_terminate_time varchar(5) NULL,
	cancel_on_disconnect bpchar(1) NOT NULL
)
SERVER oracle_prod
OPTIONS (schema 'GENESIS2_QA_20100601', table 'FIX_CONNECTION');

drop VIEW staging.ats_cons_stats_v;
DROP FOREIGN TABLE staging.lp_connection;

CREATE FOREIGN TABLE staging.lp_connection (
	liquidity_provider_id varchar(9) NOT NULL,
	lp_connector_id varchar(30) NOT NULL,
	fix_connection_id int4 NOT NULL,
	fix_engine_session_id varchar(30) NOT NULL,
	lp_lb_instance_name varchar(20) NULL,
	description varchar(256) NULL,
	create_time timestamptz NOT NULL,
	is_deleted bpchar(1) NOT NULL,
	delete_time timestamptz NULL,
	lp_connection_id int8 NOT NULL
)
SERVER oracle_prod
OPTIONS (schema 'GENESIS2_QA_20100601', table 'LP_CONNECTION');


DROP FOREIGN TABLE staging.request_for_quote;

CREATE FOREIGN TABLE staging.request_for_quote (
	rfq_id int8 OPTIONS(key 'true') NOT NULL,
	auction_id int8 NOT NULL,
	security_desc varchar(256) NULL,
	quote_type bpchar(1) NOT NULL,
	order_qty int8 NOT NULL,
	transact_time timestamptz(3) NOT NULL,
	min_response_qty int8 NULL,
	fix_connection_id int4 NULL,
	fix_message_id int8 NULL,
	parent_order_id int8 NOT NULL,
	multileg_reporting_type bpchar(1) NOT NULL,
	transaction_id int8 NULL,
	process_time timestamptz(6) NULL
)
SERVER oracle_prod
OPTIONS (schema 'GENESIS2_QA_20100601', table 'REQUEST_FOR_QUOTE');

-- staging.conditional_order definition

-- Drop table

DROP FOREIGN TABLE staging.conditional_order;

CREATE FOREIGN TABLE staging.conditional_order (
	order_id int8 OPTIONS(key 'true') NULL,
	instrument_id int8 NULL,
	account_id int8 NULL,
	fix_connection_id int4 NULL,
	parent_order_id int8 NULL,
	fix_message_id int8 NULL,
	orig_order_id int8 NULL,
	client_order_id varchar(256) NULL,
	exch_order_id varchar(128) NULL,
	client_id varchar(255) NULL,
	order_type bpchar(1) NULL,
	create_time timestamptz(3) NULL,
	process_time timestamptz(6) NULL,
	order_class bpchar(1) NULL,
	side bpchar(1) NULL,
	order_qty int8 NULL,
	price numeric(12, 4) NULL,
	time_in_force bpchar(1) NULL,
	expire_time timestamptz(3) NULL,
	handl_inst bpchar(1) NULL,
	ex_destination varchar(5) NULL,
	open_close bpchar(1) NULL,
	max_show_qty int8 NULL,
	mpid varchar(18) NULL,
	eq_order_capacity bpchar(1) NULL,
	locate_req bpchar(1) NULL,
	locate_broker varchar(20) NULL,
	max_floor int8 NULL,
	exec_inst varchar(128) NULL,
	osr_customer_order_id int8 NULL,
	osr_street_order_id int8 NULL,
	osr_street_client_order_id varchar(128) NULL,
	orig_account_id int8 NULL,
	trans_type bpchar(1) NULL,
	is_archived bpchar(1) NULL,
	alias_ex_destination varchar(5) NULL,
	sub_strategy varchar(128) NULL,
	algo_client_order_id varchar(128) NULL,
	routing_inst varchar(32) NULL,
	occ_customer_id varchar(128) NULL,
	occ_optional_data varchar(128) NULL,
	exch_rt_pref_code_value varchar(32) NULL,
	sub_system_id varchar(20) NULL,
	free_text varchar(256) NULL,
	transaction_id int8 NULL,
	exchange_id varchar(6) NULL,
	strategy_decision_reason_code int2 NULL,
	algo_start_time timestamptz(3) NULL,
	algo_end_time timestamptz(3) NULL,
	min_target_qty int8 NULL,
	discretion_offset numeric(12, 4) NULL,
	co_sub_account varchar(256) NULL,
	liquidity_provider_id varchar(9) NULL,
	internal_component_type bpchar(1) NULL,
	create_date_id numeric NULL
)
SERVER oracle_prod
OPTIONS (schema 'GENESIS2_QA_20100601', table 'CONDITIONAL_ORDER');


CREATE OR REPLACE VIEW staging.ats_cons_stats_v
AS SELECT oa.auction_id,
        CASE
            WHEN aucs.orig_order_id IS NOT NULL THEN aucs.auction_date_id
            ELSE o.create_date_id
        END AS auction_date_id,
        CASE
            WHEN aucs.orig_order_id IS NOT NULL THEN COALESCE(lp.liquidity_provider_id, str_ats_lp.liquidity_provider_id)
            ELSE COALESCE(cons_lpo.liquidity_provider_id, str_cons_lp.liquidity_provider_id)
        END AS liquidity_provider_id,
    aucs.orig_order_id AS ofp_orig_order_id,
        CASE
            WHEN aucs.orig_order_id IS NOT NULL THEN true
            ELSE false
        END AS is_ats,
        CASE
            WHEN aucs.orig_order_id IS NULL THEN true
            ELSE false
        END AS is_cons,
        CASE
            WHEN o.parent_order_id IS NULL AND NOT (lp.liquidity_provider_id IS NOT NULL OR cons_lpo.liquidity_provider_id IS NOT NULL) THEN true
            ELSE false
        END AS is_ofp_parent,
        CASE
            WHEN o.parent_order_id IS NOT NULL AND NOT (str_ats_lp.liquidity_provider_id IS NOT NULL OR str_cons_lp.liquidity_provider_id IS NOT NULL) THEN true
            ELSE false
        END AS is_ofp_street,
        CASE
            WHEN o.parent_order_id IS NULL AND (lp.liquidity_provider_id IS NOT NULL OR cons_lpo.liquidity_provider_id IS NOT NULL) THEN true
            ELSE false
        END AS is_lpo_parent,
        CASE
            WHEN o.parent_order_id IS NOT NULL AND (str_ats_lp.liquidity_provider_id IS NOT NULL OR str_cons_lp.liquidity_provider_id IS NOT NULL) THEN true
            ELSE false
        END AS is_lpo_street,
    oa.order_id,
    o.client_order_id,
    o.parent_order_id,
    o.create_time AS order_create_time,
    o.create_date_id,
    o.price AS order_price,
    o.order_qty,
    o.order_type_id,
    o.account_id,
    o.instrument_id,
    o.transaction_id,
    o.side,
    o.multileg_reporting_type,
    o.cross_order_id,
    o.client_id_text,
    o.exchange_id,
    o.fix_connection_id,
    fc_ord.fix_comp_id,
    o.internal_component_type,
    dss.sub_system_id,
    o.liquidity_provider_id AS order_liquidity_provider_id,
    o.exch_order_id,
    o.exec_instruction,
    o.strtg_decision_reason_code AS strategy_decision_reason_code,
    cf.capacity_group_id
   FROM client_order2auction oa
     JOIN LATERAL ( SELECT o_1.create_date_id,
            o_1.client_order_id,
            o_1.parent_order_id,
            o_1.create_time,
            o_1.price,
            o_1.order_qty,
            o_1.order_type_id,
            o_1.account_id,
            o_1.instrument_id,
            o_1.transaction_id,
            o_1.side,
            o_1.multileg_reporting_type,
            o_1.cross_order_id,
            o_1.client_id_text,
            o_1.exchange_id,
            o_1.fix_connection_id,
            o_1.internal_component_type,
            o_1.liquidity_provider_id,
            o_1.exch_order_id,
            o_1.exec_instruction,
            o_1.strtg_decision_reason_code,
            o_1.sub_system_unq_id,
            o_1.customer_or_firm_id,
            o_1.trans_type
           FROM client_order o_1
          WHERE oa.order_id = o_1.order_id AND oa.create_date_id = o_1.create_date_id
         LIMIT 1) o ON true
     LEFT JOIN d_account ac ON o.account_id = ac.account_id
     LEFT JOIN staging.cons_lp2trading_firm cons_lpo ON cons_lpo.trading_firm_id::text = ac.trading_firm_id::text
     LEFT JOIN d_sub_system dss ON o.sub_system_unq_id = dss.sub_system_unq_id
     LEFT JOIN d_fix_connection fc_ord ON o.fix_connection_id = fc_ord.fix_connection_id AND fc_ord.is_active = true
     LEFT JOIN staging.lp_connection lp ON lp.lp_connector_id::text = 'LPLB'::text AND lp.is_deleted = 'N'::bpchar AND o.fix_connection_id = lp.fix_connection_id
     LEFT JOIN d_customer_or_firm cf ON o.customer_or_firm_id = cf.customer_or_firm_id::bpchar
     LEFT JOIN LATERAL ( SELECT DISTINCT ON (r.auction_id, r.parent_order_id, r.auction_date_id) r.auction_id,
            r.parent_order_id AS orig_order_id,
            r.auction_date_id
           FROM request_for_quote r
          WHERE r.auction_id = oa.auction_id AND r.auction_date_id >= to_char(now() - '5 days'::interval, 'YYYYMMDD'::text)::integer
         LIMIT 1) aucs ON true
     LEFT JOIN LATERAL ( SELECT po_1.account_id,
            po_1.order_id,
            po_1.fix_connection_id
           FROM client_order po_1
          WHERE o.parent_order_id = po_1.order_id AND o.create_date_id = po_1.create_date_id AND po_1.parent_order_id IS NULL AND (po_1.time_in_force_id <> ALL (ARRAY['1'::bpchar, '6'::bpchar]))
        UNION ALL
         SELECT po_1.account_id,
            po_1.order_id,
            po_1.fix_connection_id
           FROM client_order po_1
          WHERE o.parent_order_id = po_1.order_id AND o.create_date_id >= po_1.create_date_id AND po_1.parent_order_id IS NULL AND (po_1.time_in_force_id = ANY (ARRAY['1'::bpchar, '6'::bpchar])) AND (EXISTS ( SELECT NULL::text AS text
                   FROM gtc_order_status gos
                  WHERE gos.order_id = po_1.order_id AND gos.create_date_id = po_1.create_date_id))) po ON true
     LEFT JOIN d_account pac ON po.account_id = pac.account_id
     LEFT JOIN staging.lp_connection str_ats_lp ON str_ats_lp.lp_connector_id::text = 'LPLB'::text AND str_ats_lp.is_deleted = 'N'::bpchar AND po.fix_connection_id = str_ats_lp.fix_connection_id
     LEFT JOIN staging.cons_lp2trading_firm str_cons_lp ON pac.trading_firm_id::text = str_cons_lp.trading_firm_id::text
  WHERE COALESCE(o.trans_type, '-1'::bpchar) <> 'F'::bpchar;



-- staging.client_order_temp definition

-- Drop table

--