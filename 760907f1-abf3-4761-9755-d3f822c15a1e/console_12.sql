
CREATE TABLE dm_partitions.f_yield_capture_20240416 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240416 OWNER TO dwh;

--
-- Name: f_yield_capture_20240417; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240417 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240417 OWNER TO dwh;

--
-- Name: f_yield_capture_20240418; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240418 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240418 OWNER TO dwh;

--
-- Name: f_yield_capture_20240419; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240419 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240419 OWNER TO dwh;

--
-- Name: f_yield_capture_20240422; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240422 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240422 OWNER TO dwh;

--
-- Name: f_yield_capture_20240423; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240423 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240423 OWNER TO dwh;

--
-- Name: f_yield_capture_20240424; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240424 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240424 OWNER TO dwh;

--
-- Name: f_yield_capture_20240425; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240425 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240425 OWNER TO dwh;

--
-- Name: f_yield_capture_20240426; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240426 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240426 OWNER TO dwh;

--
-- Name: f_yield_capture_20240429; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240429 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240429 OWNER TO dwh;

--
-- Name: f_yield_capture_20240430; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240430 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240430 OWNER TO dwh;

--
-- Name: f_yield_capture_20240501; Type: TABLE; Schema: dm_partitions; Owner: dwh
--

CREATE TABLE dm_partitions.f_yield_capture_20240501 (
    order_id bigint NOT NULL,
    client_order_id character varying(256),
    parent_order_id bigint,
    cross_order_id bigint,
    multileg_reporting_type character(1),
    time_in_force_id character(1),
    day_leaves_qty integer,
    status_date_id integer NOT NULL,
    order_type_id character(1),
    side character(1),
    order_qty integer,
    order_price numeric(12,4),
    transaction_id bigint,
    account_id bigint,
    sub_strategy_id integer,
    instrument_type_id character(1),
    instrument_id integer,
    strategy_decision_reason_code smallint,
    day_order_qty integer,
    day_cum_qty integer,
    day_avg_px numeric(10,4),
    is_marketable character(1),
    order_size_state character(1),
    yield numeric(15,5),
    buy_or_sell character(1),
    avg_px numeric,
    exec_time timestamp without time zone,
    routed_time timestamp without time zone,
    db_merge_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    nbbo_bid_price numeric(12,4),
    nbbo_bid_quantity integer,
    nbbo_ask_price numeric(12,4),
    nbbo_ask_quantity integer,
    num_exch smallint,
    exchange_unq_id smallint,
    exch_bid_price numeric(12,4),
    exch_bid_quantity integer,
    exch_ask_price numeric(12,4),
    exch_ask_quantity integer,
    trading_firm_unq_id integer,
    wave_no smallint,
    order_end_time timestamp without time zone,
    order_fix_message_id bigint,
    routing_table_id integer,
    parent_sub_strategy_id integer,
    exchange_id character varying(6),
    real_exchange_id character varying(6),
    order_type_mapping_id integer,
    pt_basket_id character varying(100),
    is_ats boolean,
    client_id character varying(255),
    customer_or_firm_id character(1)
);


ALTER TABLE dm_partitions.f_yield_capture_20240501 OWNER TO dwh;

--
-- Name: qa_metadata_list; Type: TABLE; Schema: dq; Owner: autotest
--

CREATE TABLE dq.qa_metadata_list (
    table_catalog information_schema.sql_identifier,
    table_schema information_schema.sql_identifier,
    table_name information_schema.sql_identifier,
    column_name information_schema.sql_identifier,
    ordinal_position information_schema.cardinal_number,
    column_default information_schema.character_data,
    is_nullable information_schema.yes_or_no,
    data_type information_schema.character_data,
    character_maximum_length information_schema.cardinal_number,
    character_octet_length information_schema.cardinal_number,
    numeric_precision information_schema.cardinal_number,
    numeric_precision_radix information_schema.cardinal_number,
    numeric_scale information_schema.cardinal_number,
    datetime_precision information_schema.cardinal_number,
    last_update timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dq.qa_metadata_list OWNER TO autotest;

--
-- Name: qa_metadata_list_temp; Type: TABLE; Schema: dq; Owner: autotest
--

CREATE TABLE dq.qa_metadata_list_temp (
    table_catalog name,
    table_schema name,
    table_name name,
    column_name name,
    ordinal_position integer,
    column_default character varying,
    is_nullable character varying,
    data_type character varying,
    character_maximum_length integer,
    character_octet_length integer,
    numeric_precision integer,
    numeric_precision_radix integer,
    numeric_scale integer,
    datetime_precision integer,
    last_update timestamp without time zone
);


ALTER TABLE dq.qa_metadata_list_temp OWNER TO autotest;

--
-- Name: qa_metadata_test_log; Type: TABLE; Schema: dq; Owner: autotest
--

CREATE TABLE dq.qa_metadata_test_log (
    rs_table character varying,
    table_catalog information_schema.sql_identifier,
    table_schema information_schema.sql_identifier,
    table_name information_schema.sql_identifier,
    column_name information_schema.sql_identifier,
    ordinal_position information_schema.cardinal_number,
    column_default information_schema.character_data,
    is_nullable information_schema.yes_or_no,
    data_type information_schema.character_data,
    character_maximum_length information_schema.cardinal_number,
    character_octet_length information_schema.cardinal_number,
    numeric_precision information_schema.cardinal_number,
    numeric_precision_radix information_schema.cardinal_number,
    numeric_scale information_schema.cardinal_number,
    datetime_precision information_schema.cardinal_number,
    test_run timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dq.qa_metadata_test_log OWNER TO autotest;

--
-- Name: test_metadata_err_view; Type: VIEW; Schema: dq; Owner: autotest
--

CREATE VIEW dq.test_metadata_err_view AS
 SELECT table_schema,
    table_name,
    column_name,
    count(*) AS count,
        CASE
            WHEN (count(*) = 2) THEN 'Column is changed'::text
            WHEN ((count(*) = 1) AND (max((rs_table)::text) = 'table_real'::text)) THEN 'Column is added'::text
            WHEN ((count(*) = 1) AND (max((rs_table)::text) = 'table_expected'::text)) THEN 'Column is deleted'::text
            ELSE NULL::text
        END AS column_edits,
    date_trunc('minute'::text, test_run) AS test_run1,
    to_char(test_run, 'YYYYMMDD'::text) AS date2
   FROM dq.qa_metadata_test_log qmtl
  WHERE ((rs_table)::text <> 'table_ok'::text)
  GROUP BY table_schema, table_name, column_name, (date_trunc('minute'::text, test_run)), (to_char(test_run, 'YYYYMMDD'::text))
  ORDER BY (date_trunc('minute'::text, test_run));


ALTER VIEW dq.test_metadata_err_view OWNER TO autotest;

--
-- Name: test_metadata_log_view; Type: VIEW; Schema: dq; Owner: autotest
--

CREATE VIEW dq.test_metadata_log_view AS
 SELECT table_schema,
    table_name,
    column_name,
    count(*) AS count,
        CASE
            WHEN (count(*) = 2) THEN 'Column is changed'::text
            WHEN ((count(*) = 1) AND (max((rs_table)::text) = 'table_real'::text)) THEN 'Column is added'::text
            WHEN ((count(*) = 1) AND (max((rs_table)::text) = 'table_expected'::text)) THEN 'Column is deleted'::text
            WHEN ((count(*) = 1) AND (max((rs_table)::text) = 'table_ok'::text)) THEN 'OK'::text
            ELSE NULL::text
        END AS column_edits,
    date_trunc('minute'::text, test_run) AS test_run1,
    to_char(test_run, 'YYYYMMDD'::text) AS date2
   FROM dq.qa_metadata_test_log qmtl
  GROUP BY table_schema, table_name, column_name, (date_trunc('minute'::text, test_run)), (to_char(test_run, 'YYYYMMDD'::text))
  ORDER BY (date_trunc('minute'::text, test_run));


ALTER VIEW dq.test_metadata_log_view OWNER TO autotest;

--
-- Name: test_metadata_ok_view; Type: VIEW; Schema: dq; Owner: autotest
--

CREATE VIEW dq.test_metadata_ok_view AS
 SELECT table_schema,
    table_name,
    date_trunc('minute'::text, test_run) AS test_run1,
    'OK'::text AS table_status
   FROM dq.qa_metadata_test_log
  WHERE ((rs_table)::text = 'table_ok'::text)
  GROUP BY table_schema, table_name, column_name, (date_trunc('minute'::text, test_run))
  ORDER BY (date_trunc('minute'::text, test_run));


ALTER VIEW dq.test_metadata_ok_view OWNER TO autotest;

--
-- Name: account2instrument_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.account2instrument_type (
    account_id bigint NOT NULL,
    instrument_type_id character(1) NOT NULL,
    is_active boolean,
    pg_update_time timestamp without time zone
);


ALTER TABLE dwh.account2instrument_type OWNER TO dwh;

--
-- Name: account2routing_table; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.account2routing_table (
    account_id bigint NOT NULL,
    routing_table_unq_id integer NOT NULL,
    routing_table_id bigint NOT NULL,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.account2routing_table OWNER TO dwh;

--
-- Name: allocation2trade_record; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.allocation2trade_record (
    trade_record_id bigint NOT NULL,
    alloc_instr_id integer NOT NULL,
    bundle_id integer,
    order_id bigint,
    date_id integer NOT NULL,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    alloc_scope character(1),
    alloc_qty integer,
    clearing_account_id integer,
    is_active boolean,
    avg_px numeric(14,6),
    dataset_id integer,
    occ_actionable_id character varying(10)
);


ALTER TABLE dwh.allocation2trade_record OWNER TO dwh;

--
-- Name: artur_test; Type: TABLE; Schema: dwh; Owner: akhomenko
--

CREATE TABLE dwh.artur_test (
    order_id bigint NOT NULL,
    create_time timestamp without time zone
);


ALTER TABLE dwh.artur_test OWNER TO akhomenko;

--
-- Name: banking_holiday_calendar; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.banking_holiday_calendar (
    banking_holiday_id bigint NOT NULL,
    banking_holiday_name character varying(100) NOT NULL,
    banking_holiday_date date NOT NULL,
    banking_holiday_date_id integer,
    is_active boolean,
    date_start timestamp without time zone,
    date_end timestamp without time zone
);


ALTER TABLE dwh.banking_holiday_calendar OWNER TO dwh;

SET default_tablespace = arch_data;

--
-- Name: bundle_allocation_info_storage; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.bundle_allocation_info_storage (
    "TradeDate" date,
    "BundleID" bigint NOT NULL,
    "Side" character varying(1),
    "AccountID" integer,
    "InstrumentID" bigint,
    "DayCumQty" bigint,
    "DayAvgPx" numeric(12,4),
    "AllocQty" bigint,
    "Symbol" character varying(10),
    "OPRASymbol" character varying(21),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "DisplayInstrumentID" character varying(256),
    "OpenClose" character varying(1),
    "AllocUserName" character varying(30),
    "TransactTime" timestamp without time zone,
    "PrincipalAmount" numeric(20,6),
    "AccDashCommissionAmount" numeric(20,6),
    "AccExecutionCost" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "NetMoneyAmount" numeric(20,6),
    "AccMiscFeeNameID1" character varying(6),
    "AccMiscFeeNameID2" character varying(6),
    "AccMiscFeeNameID3" character varying(6),
    "AccMiscFeeNameID4" character varying(6),
    "AccMiscFeeNameID5" character varying(6),
    "AccMiscFeeDisplayName1" character varying(256),
    "AccMiscFeeDisplayName2" character varying(256),
    "AccMiscFeeDisplayName3" character varying(256),
    "AccMiscFeeDisplayName4" character varying(256),
    "AccMiscFeeDisplayName5" character varying(256),
    "AccMiscFeeAmount1" numeric(20,6),
    "AccMiscFeeAmount2" numeric(20,6),
    "AccMiscFeeAmount3" numeric(20,6),
    "AccMiscFeeAmount5" numeric(20,6),
    "AccMiscFeeAmount4" numeric(20,6),
    "AccCommissionScheduleRateType" character varying(1),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "FirmMiscFeeNameID1" character varying(6),
    "FirmMiscFeeNameID2" character varying(6),
    "FirmMiscFeeNameID3" character varying(6),
    "FirmMiscFeeNameID4" character varying(6),
    "FirmMiscFeeNameID5" character varying(6),
    "FirmMiscFeeDisplayName1" character varying(256),
    "FirmMiscFeeDisplayName2" character varying(256),
    "FirmMiscFeeDisplayName3" character varying(256),
    "FirmMiscFeeDisplayName4" character varying(256),
    "FirmMiscFeeDisplayName5" character varying(256),
    "FirmMiscFeeAmount1" numeric(20,6),
    "FirmMiscFeeAmount2" numeric(20,6),
    "FirmMiscFeeAmount3" numeric(20,6),
    "FirmMiscFeeAmount4" numeric(20,6),
    "FirmMiscFeeAmount5" numeric(20,6),
    "AliasAccExecutionCost" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "FirmCommissionScheduleRateType" character varying(1),
    "MSSFeeAmount" numeric(20,6),
    "Trade_Date_id" integer
);


ALTER TABLE dwh.bundle_allocation_info_storage OWNER TO dwh;

--
-- Name: TABLE bundle_allocation_info_storage; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON TABLE dwh.bundle_allocation_info_storage IS 'Replicated table from the Oracle PROD on nightly basis by the EOD';


--
-- Name: sq_trading_firm; Type: SEQUENCE; Schema: dwh; Owner: dhw_admin
--

CREATE SEQUENCE dwh.sq_trading_firm
    START WITH 2000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_trading_firm OWNER TO dhw_admin;

SET default_tablespace = '';

--
-- Name: d_trading_firm; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_trading_firm (
    trading_firm_unq_id integer DEFAULT nextval('dwh.sq_trading_firm'::regclass) NOT NULL,
    trading_firm_id character varying(9),
    trading_firm_name character varying(60),
    max_day_order_value numeric(20,6),
    eq_commission_rate numeric(12,4),
    eq_commission_rate_unit character(1),
    is_broker_dealer character(1),
    broker_dealer_mpid character varying(4),
    locate_broker character varying(20),
    trading_firm_demo_mnemonic character varying(100),
    large_trader_id character varying(13),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean,
    is_eligible4consolidator character(1),
    trading_firm_side character(1),
    cat_imid character varying(13),
    is_affiliate character varying(1),
    cat_report_on_behalf_of character(1),
    cat_suppress character(1),
    cat_crd character varying(15),
    is_liquidity_provider character(1),
    trading_firm_touch character(1),
    is_prime_brokerage_customer character(1),
    cat_use_account_imid character(1)
);


ALTER TABLE dwh.d_trading_firm OWNER TO dwh;

--
-- Name: cdc_d_trading_firm; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.cdc_d_trading_firm AS
 SELECT ((xmin)::text)::bigint AS scn,
    trading_firm_unq_id,
    trading_firm_id,
    trading_firm_name,
    max_day_order_value,
    eq_commission_rate,
    eq_commission_rate_unit,
    is_broker_dealer,
    broker_dealer_mpid,
    locate_broker,
    trading_firm_demo_mnemonic,
    large_trader_id,
    date_start,
    date_end,
    is_active,
    is_eligible4consolidator
   FROM dwh.d_trading_firm t;


ALTER VIEW dwh.cdc_d_trading_firm OWNER TO dwh;

--
-- Name: clearing_instruction; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.clearing_instruction (
    clearing_instr_id integer NOT NULL,
    date_id integer NOT NULL,
    status character(1) NOT NULL,
    remarks character varying(256),
    create_time timestamp without time zone DEFAULT now(),
    created_by_user_id integer,
    claim_time timestamp without time zone,
    claimed_by_user_id integer,
    is_active boolean,
    delete_time timestamp without time zone,
    deleted_by_user_id integer,
    process_time timestamp without time zone,
    processed_by_user_id integer,
    modification_type bpchar
);


ALTER TABLE dwh.clearing_instruction OWNER TO dwh;

--
-- Name: clearing_instruction_clearing_instr_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.clearing_instruction_clearing_instr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.clearing_instruction_clearing_instr_id_seq OWNER TO dwh;

--
-- Name: clearing_instruction_clearing_instr_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.clearing_instruction_clearing_instr_id_seq OWNED BY dwh.clearing_instruction.clearing_instr_id;


--
-- Name: clearing_instruction_entry; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.clearing_instruction_entry (
    clearing_instr_entry_id integer NOT NULL,
    date_id integer NOT NULL,
    clearing_instr_id integer NOT NULL,
    new_trade_record_id bigint,
    trade_record_id bigint NOT NULL,
    account_id integer NOT NULL,
    opt_customer_firm character(1),
    open_close character(1),
    last_qty integer NOT NULL,
    last_px numeric(12,4) NOT NULL,
    exec_broker character varying(32),
    cmta character varying(3),
    clearing_account_number character varying(25),
    trade_liquidity_indicator character varying(256),
    sub_account character varying(5),
    remarks character varying(100),
    trade_record_time timestamp without time zone,
    electronic_report_status bpchar,
    street_account_name character varying(255),
    street_exec_broker character varying(32),
    client_commission_rate numeric(16,6)
);


ALTER TABLE dwh.clearing_instruction_entry OWNER TO dwh;

--
-- Name: clearing_instruction_entry_clearing_instr_entry_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.clearing_instruction_entry_clearing_instr_entry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.clearing_instruction_entry_clearing_instr_entry_id_seq OWNER TO dwh;

--
-- Name: clearing_instruction_entry_clearing_instr_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.clearing_instruction_entry_clearing_instr_entry_id_seq OWNED BY dwh.clearing_instruction_entry.clearing_instr_entry_id;


--
-- Name: client_order; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.client_order (
    order_id bigint NOT NULL,
    instrument_id bigint,
    option_contract_id bigint,
    account_id integer,
    trading_firm_unq_id integer,
    parent_order_id bigint,
    orig_order_id bigint,
    order_type_id character(1),
    time_in_force_id character(1),
    create_date_id integer NOT NULL,
    exch_order_id character varying(128),
    osr_street_client_order_id character varying(128),
    client_order_id character varying(256),
    expire_time timestamp(3) without time zone,
    order_cancel_time timestamp(3) without time zone,
    create_time timestamp(3) without time zone,
    process_time timestamp without time zone,
    side character(1),
    order_qty integer,
    price numeric(12,4),
    stop_price numeric(12,4),
    max_show_qty integer,
    trans_type character(1),
    multileg_reporting_type character(1),
    open_close character(1),
    dataset_id bigint,
    sub_strategy_id integer,
    fix_connection_id integer,
    fix_message_id bigint,
    occ_optional_data character varying(128),
    alias_ex_destination_id integer,
    is_late_hours_order character(1),
    cancel_code smallint,
    order_class character(1),
    max_floor bigint,
    transaction_id bigint,
    sub_system_unq_id integer,
    fee_sensitivity smallint,
    clearing_firm_id character varying(3),
    market_participant_id character varying(18),
    cross_order_id bigint,
    customer_or_firm_id character(1),
    mm_preference_code_id integer,
    exchange_id character varying(6),
    eq_order_capacity character(1),
    opt_exec_broker_id integer,
    strtg_decision_reason_code smallint,
    compliance_id character varying(256),
    exchange_unq_id smallint,
    ex_destination character varying(5),
    aggression_level smallint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    exec_instruction character varying(128),
    quote_id character varying(256),
    step_up_price_type character(1),
    step_up_price numeric(12,4),
    multileg_order_id bigint,
    routing_table_id integer,
    liquidity_provider_id character varying(9),
    internal_component_type character(1),
    no_legs integer,
    clearing_account character varying(256),
    sub_account character varying(256),
    request_number integer,
    pt_basket_id character varying(100),
    ratio_qty bigint,
    handl_inst character(1),
    sub_strategy_desc character varying(128),
    pt_order_id bigint,
    cons_payment_per_contract numeric(12,4),
    alternative_compliance_id character varying(256),
    is_originator character(1),
    internal_order_id bigint,
    sweep_style character(1),
    co_client_leg_ref_id character varying(30),
    extended_ord_type character(1),
    algo_start_time timestamp without time zone,
    algo_end_time timestamp without time zone,
    occ_customer_id character varying(128),
    locate_req character(1),
    locate_broker character varying(20),
    algo_client_order_id character varying(128),
    dash_client_order_id character varying(128),
    on_behalf_of_sub_id character varying(256),
    prim_listing_exchange character varying(5),
    posting_exchange character varying(5),
    pre_open_behavior character(1),
    hidden_flag character(1),
    algo_stop_px numeric(12,4),
    tot_no_orders_in_transaction bigint,
    max_wave_qty_pct bigint,
    discretion_offset numeric(12,4),
    cross_account_id bigint,
    conditional_client_order_id character varying(256),
    osr_customer_order_id bigint,
    osr_street_order_id bigint,
    session_eligibility character(1),
    cnt integer,
    co_routing_table_entry_id bigint,
    max_vega_per_strike bigint,
    per_strike_vega_exposure character(1),
    vega_behavior integer,
    delta_behavior character(1),
    hedge_param_units character(1),
    min_delta bigint,
    product_description character varying(256),
    parent_order_process_time timestamp without time zone,
    client_id_text character varying(256),
    dash_rfr_id character varying(256),
    routing_instr_side character(1),
    opt_customer_firm_street character(1),
    exchange_fix_connection_id bigint,
    pragma_routing_reason character varying(256),
    optwap_bin_number integer,
    optwap_phase character varying(30),
    optwap_order_price numeric(12,4),
    optwap_bin_duration integer,
    optwap_bin_qty integer,
    optwap_phase_duration integer,
    order_text character varying(256),
    trading_firm_id character varying(9),
    consolidator_billing_type smallint,
    cons_spi_instr character(1),
    is_held character(1),
    orig_account_id bigint
)
PARTITION BY RANGE (create_date_id);


ALTER TABLE dwh.client_order OWNER TO dwh;

--
-- Name: COLUMN client_order.trading_firm_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order.trading_firm_unq_id IS 'Foreign key to the d_trading firm using surrogate key ';


--
-- Name: COLUMN client_order.process_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order.process_time IS 'We need to add microseconds  +  coalesce((cl.process_time_micsec::numeric/1000 - trunc(cl.process_time_micsec::numeric/1000,0))/1000,0) *  interval ''1 seconds''';


--
-- Name: COLUMN client_order.exchange_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order.exchange_unq_id IS 'Foreign key to d_exchange using surrogate key ';


--
-- Name: COLUMN client_order.pg_db_create_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order.pg_db_create_time IS 'Time of record creation in the postgreSQL big_data DB';


--
-- Name: COLUMN client_order.quote_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order.quote_id IS 'Unique reference number assigned to the quote at the liquidity provider''s side. ';


--
-- Name: COLUMN client_order.step_up_price_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order.step_up_price_type IS 'Specifies the step-up price type.
Supported values: 1 - Market, 2 - Limit.';


--
-- Name: COLUMN client_order.step_up_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order.step_up_price IS 'Specifies the step-up price. Required if StepUpPriceType = 2 (Limit).';


--
-- Name: client_order2auction; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.client_order2auction (
    order_id bigint NOT NULL,
    auction_id bigint NOT NULL,
    rfq_transact_time timestamp without time zone,
    create_date_id bigint NOT NULL,
    dataset_id integer,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (create_date_id);


ALTER TABLE dwh.client_order2auction OWNER TO dwh;

--
-- Name: client_order_last_transaction; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.client_order_last_transaction (
    date_id integer NOT NULL,
    order_id bigint,
    transaction_id bigint
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh.client_order_last_transaction OWNER TO dwh;

--
-- Name: client_order_late; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.client_order_late (
    order_id bigint NOT NULL,
    pg_order_create_time timestamp without time zone NOT NULL,
    create_date_id bigint
);


ALTER TABLE dwh.client_order_late OWNER TO dwh;

--
-- Name: client_order_leg; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.client_order_leg (
    order_id bigint NOT NULL,
    multileg_order_id bigint NOT NULL,
    client_leg_ref_id character varying(30) NOT NULL,
    time_for_test timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
)
WITH (autovacuum_enabled='true', autovacuum_vacuum_scale_factor='2');


ALTER TABLE dwh.client_order_leg OWNER TO dwh;

--
-- Name: client_order_old; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.client_order_old (
    order_id bigint NOT NULL,
    instrument_id bigint,
    option_contract_id bigint,
    account_id integer,
    trading_firm_unq_id integer,
    parent_order_id bigint,
    orig_order_id bigint,
    order_type_id character(1),
    time_in_force_id character(1),
    ex_destination_code_id integer,
    create_date_id integer NOT NULL,
    exch_order_id character varying(128),
    osr_street_client_order_id character varying(128),
    client_order_id character varying(256),
    client_id integer,
    expire_time timestamp(3) without time zone,
    order_cancel_time timestamp(3) without time zone,
    create_time timestamp(3) without time zone,
    process_time timestamp without time zone,
    side character(1),
    order_qty integer,
    price numeric(12,4),
    stop_price numeric(12,4),
    max_show_qty integer,
    trans_type character(1),
    multileg_reporting_type character(1),
    open_close character(1),
    dataset_id integer,
    sub_strategy_id integer,
    fix_connection_id integer,
    fix_message_id bigint,
    occ_optional_data character varying(128),
    order_capacity_id character(1),
    alias_ex_destination_id integer,
    is_late_hours_order character(1),
    cancel_code smallint,
    order_class character(1),
    max_floor bigint,
    transaction_id bigint,
    sub_system_unq_id integer,
    fee_sensitivity smallint,
    clearing_firm_id character varying(3),
    market_participant_id character varying(18),
    cross_order_id bigint,
    customer_or_firm_id character(1),
    mm_preference_code_id integer,
    exchange_id character varying(6),
    eq_order_capacity character(1),
    opt_exec_broker_id integer,
    strtg_decision_reason_code smallint,
    compliance_id character varying(256),
    exchange_unq_id smallint,
    ex_destination character varying(5),
    aggression_level smallint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    process_time_micsec character varying(6),
    process_time_unix numeric(20,4),
    exec_instruction character varying(128),
    quote_id character varying(256),
    step_up_price_type character(1),
    step_up_price numeric(12,4),
    cross_account_id integer,
    multileg_order_id bigint,
    routing_table_id integer,
    liquidity_provider_id character varying(9),
    internal_component_type character(1),
    no_legs integer,
    clearing_account character varying(256),
    sub_account character varying(256),
    request_number integer,
    pt_basket_id character varying(100),
    ratio_qty bigint,
    handl_inst character(1),
    sub_strategy_desc character varying(128),
    pt_order_id bigint,
    cons_payment_per_contract numeric(12,4),
    alternative_compliance_id character varying(256),
    is_originator character(1),
    internal_order_id bigint,
    sweep_style character(1),
    co_client_leg_ref_id character varying(30),
    extended_ord_type character(1)
)
WITH (autovacuum_enabled='true', autovacuum_vacuum_scale_factor='2');


ALTER TABLE dwh.client_order_old OWNER TO dwh;

--
-- Name: COLUMN client_order_old.trading_firm_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.trading_firm_unq_id IS 'Foreign key to the d_trading firm using surrogate key ';


--
-- Name: COLUMN client_order_old.process_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.process_time IS 'We need to add microseconds  +  coalesce((cl.process_time_micsec::numeric/1000 - trunc(cl.process_time_micsec::numeric/1000,0))/1000,0) *  interval ''1 seconds''';


--
-- Name: COLUMN client_order_old.exchange_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.exchange_unq_id IS 'Foreign key to d_exchange using surrogate key ';


--
-- Name: COLUMN client_order_old.pg_db_create_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.pg_db_create_time IS 'Time of record creation in the postgreSQL big_data DB';


--
-- Name: COLUMN client_order_old.process_time_micsec; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.process_time_micsec IS 'Additional field to store microseconds as a Talend bug workaround ';


--
-- Name: COLUMN client_order_old.quote_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.quote_id IS 'Unique reference number assigned to the quote at the liquidity provider''s side. ';


--
-- Name: COLUMN client_order_old.step_up_price_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.step_up_price_type IS 'Specifies the step-up price type.
Supported values: 1 - Market, 2 - Limit.';


--
-- Name: COLUMN client_order_old.step_up_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.client_order_old.step_up_price IS 'Specifies the step-up price. Required if StepUpPriceType = 2 (Limit).';


--
-- Name: cnt_dst_active; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.cnt_dst_active (
    count bigint
);


ALTER TABLE dwh.cnt_dst_active OWNER TO dwh;

--
-- Name: conditional_execution; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.conditional_execution (
    exec_id bigint NOT NULL,
    exch_exec_id character varying(200),
    order_id bigint NOT NULL,
    fix_message_id bigint,
    exec_type character(1),
    order_status character(1),
    exec_time timestamp without time zone,
    leaves_qty bigint,
    last_mkt character varying(20),
    exec_text character varying(512),
    is_busted character(1),
    exchange_id character varying(10),
    date_id integer,
    last_qty bigint,
    cum_qty bigint,
    last_px numeric(12,4),
    ref_exec_id bigint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    dataset_id bigint
);


ALTER TABLE dwh.conditional_execution OWNER TO dwh;

--
-- Name: conditional_order; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.conditional_order (
    order_id bigint NOT NULL,
    instrument_id bigint NOT NULL,
    account_id bigint NOT NULL,
    fix_connection_id smallint NOT NULL,
    parent_order_id bigint,
    fix_message_id bigint,
    orig_order_id bigint,
    client_order_id character varying(256) NOT NULL,
    client_id_text character varying(255),
    order_type character(1) NOT NULL,
    create_time timestamp without time zone,
    process_time timestamp without time zone,
    order_class character(1) NOT NULL,
    side character(1) NOT NULL,
    order_qty bigint NOT NULL,
    price numeric(12,4),
    ex_destination character varying(5),
    mpid character varying(18),
    exec_inst character varying(128),
    osr_street_client_order_id character varying(128),
    orig_account_id bigint NOT NULL,
    trans_type character(1) NOT NULL,
    sub_system_id character varying(20),
    transaction_id bigint,
    exchange_id character varying(6),
    strategy_decision_reason_code smallint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    date_id integer,
    time_in_force character(1),
    expire_time timestamp(6) without time zone,
    open_close character(1),
    handl_inst character(1),
    max_show_qty bigint,
    max_floor bigint,
    eq_order_capacity character(1),
    locate_req character(1),
    locate_broker character varying(20),
    algo_client_order_id character varying(128),
    algo_start_time timestamp(6) without time zone,
    algo_end_time timestamp(6) without time zone,
    min_target_qty bigint,
    discretion_offset numeric(12,4),
    co_sub_account character varying(256),
    liquidity_provider_id character varying(9),
    internal_component_type character(1),
    osr_customer_order_id bigint,
    osr_street_order_id bigint,
    occ_optional_data character varying(128),
    dataset_id bigint,
    order_text character varying(256),
    sub_strategy_id integer
);


ALTER TABLE dwh.conditional_order OWNER TO dwh;

--
-- Name: cross_order; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.cross_order (
    cross_order_id bigint NOT NULL,
    cross_id character varying(256),
    exposure_flag character(1),
    step_up_px numeric(12,4),
    broker_pct integer,
    cross_type character(1),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.cross_order OWNER TO dwh;

--
-- Name: d_acc_allowed_liquidity_provider; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_acc_allowed_liquidity_provider (
    acc_allowed_liquidity_provider_unq_id integer NOT NULL,
    account_id bigint NOT NULL,
    liquidity_provider_id character varying(9) NOT NULL,
    lp_interaction_type character(1) NOT NULL,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_acc_allowed_liquidity_provider OWNER TO dwh;

--
-- Name: d_acc_allowed_liquidity_provi_acc_allowed_liquidity_provide_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_acc_allowed_liquidity_provi_acc_allowed_liquidity_provide_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_acc_allowed_liquidity_provi_acc_allowed_liquidity_provide_seq OWNER TO dwh;

--
-- Name: d_acc_allowed_liquidity_provi_acc_allowed_liquidity_provide_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_acc_allowed_liquidity_provi_acc_allowed_liquidity_provide_seq OWNED BY dwh.d_acc_allowed_liquidity_provider.acc_allowed_liquidity_provider_unq_id;


--
-- Name: d_acc_allowed_liquidity_provider_audit; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_acc_allowed_liquidity_provider_audit (
    audit_record_id bigint NOT NULL,
    account_id bigint NOT NULL,
    liquidity_provider_id character varying(9) NOT NULL,
    lp_interaction_type character(1) NOT NULL,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_acc_allowed_liquidity_provider_audit OWNER TO dwh;

--
-- Name: d_acceptor; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_acceptor (
    acceptor_id character varying(30) NOT NULL,
    fix_comp_id character varying(30) NOT NULL,
    listen_host character varying(256) NOT NULL,
    listen_port integer NOT NULL,
    fix_version character varying(6) NOT NULL,
    start_time character varying(5),
    terminate_time character varying(5),
    in_seq_num bigint DEFAULT 0 NOT NULL,
    out_seq_num bigint DEFAULT 0 NOT NULL,
    force_seq_num_reset character(1) DEFAULT '2'::bpchar,
    recreate_on_logout character(1) DEFAULT 'Y'::bpchar NOT NULL,
    intraday_logout_tolerance character(1) DEFAULT 'Y'::bpchar NOT NULL,
    rej_no_connection character(1) DEFAULT 'N'::bpchar NOT NULL,
    ign_seq_too_low_logon character(1) DEFAULT 'Y'::bpchar NOT NULL,
    max_msg_in_bunch bigint DEFAULT 1 NOT NULL,
    tcp_buffer_disabled character(1) DEFAULT 'N'::bpchar NOT NULL,
    sender_sub_id character varying(20),
    target_sub_id character varying(20),
    create_time timestamp without time zone,
    is_deleted character(1) DEFAULT 'N'::bpchar NOT NULL,
    delete_time timestamp without time zone,
    description character varying(256),
    socket_priority character varying(16),
    config_session_name character varying(30),
    allow_msg_wo_poss_dup_flag character(1) DEFAULT 'N'::bpchar,
    sub_system_id character varying(20),
    secondary_listen_host character varying(256) DEFAULT NULL::character varying,
    secondary_listen_port integer,
    CONSTRAINT ckc_ign_seq_too_low_l_acceptor CHECK ((ign_seq_too_low_logon = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ckc_intraday_logout_t_acceptor CHECK ((intraday_logout_tolerance = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ckc_is_deleted_acceptor CHECK ((is_deleted = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ckc_recreate_on_logou_acceptor CHECK ((recreate_on_logout = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ckc_rej_no_connection_acceptor CHECK ((rej_no_connection = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ckc_tcp_buffer_disabl_acceptor CHECK ((tcp_buffer_disabled = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


ALTER TABLE dwh.d_acceptor OWNER TO dwh;

--
-- Name: d_account; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_account (
    account_id integer NOT NULL,
    account_name character varying(30),
    trading_firm_unq_id integer,
    eq_mpid character varying(4),
    eq_order_capacity character varying(1),
    eq_commission numeric(12,4),
    eq_commission_type character varying(1),
    eq_is_validate_short_stock character varying(1),
    opt_penny_commission numeric(12,4),
    opt_nickel_commission numeric(12,4),
    drop_copy_enabled character varying(1),
    opt_customer_or_firm character varying(1),
    opt_is_fix_execbrok_processed character varying(1),
    account_demo_mnemonic character varying(100),
    trading_firm_id character varying(9),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean,
    opt_is_fix_clfirm_processed character(1),
    opt_is_fix_custfirm_processed character(1),
    first_trade_date date,
    last_trade_date date,
    account_class_id character(1),
    broker_dealer_mpid character varying(4),
    is_finra_member character(1),
    crd_number character varying(6),
    oats_account_type_code character(1),
    oats_report_on_behalf_of character(1),
    oats_suppress_nw character(1),
    oats_use_custom_order_id character(1),
    opt_report_to_mpid character varying(4),
    client_dtc_number character varying(4),
    nscc_commission_enabled character(1),
    nscc_sec_fee_enabled character(1),
    nscc_mpid character varying(4),
    account_holder_type character varying(1),
    cat_fdid character varying(40),
    cat_report_on_behalf_of character(1),
    cat_suppress character(1),
    is_auto_allocate character(1),
    is_option_auto_allocate character(1) DEFAULT 'N'::bpchar,
    account_algo_alias character varying(15),
    is_broker_dealer character(1),
    eq_executing_service character varying(4),
    opt_is_dark_pool_eligible character(1),
    is_clearing_enabled character(1),
    max_day_order_value bigint,
    is_risk_management_enabled character(1),
    is_locked character(1),
    locked_time timestamp without time zone,
    eq_report_to_mpid character varying(4),
    opt_executing_service character varying(4),
    is_specific_allocated character(1),
    eq_reporting_avgpx_precision integer,
    opt_is_baml_dma_eligible character varying(4),
    opt_avg_px_account character varying(10),
    eq_avg_px_account character varying(10),
    eq_real_time_report_to_mpid character varying(4),
    eq_nasdaq_act_drop character(1),
    settlement_period character(1),
    use_new_model character(1),
    opt_occ_id character varying(40)
);


ALTER TABLE dwh.d_account OWNER TO dwh;

--
-- Name: COLUMN d_account.trading_firm_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_account.trading_firm_unq_id IS 'Foreign key to d_trading_firm using surrogate key ';


--
-- Name: d_account2customer_account_number; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_account2customer_account_number (
    account_id bigint NOT NULL,
    cust_acc_number character varying(256)
);


ALTER TABLE dwh.d_account2customer_account_number OWNER TO dwh;

--
-- Name: d_account2disallowed_exchange; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_account2disallowed_exchange (
    account_id integer NOT NULL,
    exchange_id character varying(20) NOT NULL,
    is_active boolean,
    date_start timestamp without time zone,
    date_end timestamp without time zone
);


ALTER TABLE dwh.d_account2disallowed_exchange OWNER TO dwh;

--
-- Name: d_account_class; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_account_class (
    account_class_id character(1),
    account_class_name character varying(30),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_account_class OWNER TO dwh;

--
-- Name: d_account_name_override; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_account_name_override (
    account_id integer NOT NULL,
    overriden_account_name character varying(255) NOT NULL
);


ALTER TABLE dwh.d_account_name_override OWNER TO dwh;

--
-- Name: d_account_temp_test; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_account_temp_test (
    account_id integer,
    account_name character varying(30),
    trading_firm_unq_id integer,
    eq_mpid character varying(4),
    eq_order_capacity character varying(1),
    eq_commission numeric(12,4),
    eq_commission_type character varying(1),
    eq_is_validate_short_stock character varying(1),
    opt_penny_commission numeric(12,4),
    opt_nickel_commission numeric(12,4),
    drop_copy_enabled character varying(1),
    opt_customer_or_firm character varying(1),
    opt_is_fix_execbrok_processed character varying(1),
    account_demo_mnemonic character varying(100),
    trading_firm_id character varying(9),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_account_temp_test OWNER TO dwh;

--
-- Name: d_algo_wizard_data; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_algo_wizard_data (
    algo_param_unq_id bigint NOT NULL,
    target_strategy_id integer NOT NULL,
    account_id integer NOT NULL,
    instrument_type_id character(1),
    param_data text,
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_algo_wizard_data OWNER TO dwh;

--
-- Name: COLUMN d_algo_wizard_data.algo_param_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_algo_wizard_data.algo_param_unq_id IS 'Surrogate key. Primary key';


--
-- Name: COLUMN d_algo_wizard_data.target_strategy_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_algo_wizard_data.target_strategy_id IS 'FK to D_account';


--
-- Name: COLUMN d_algo_wizard_data.param_data; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_algo_wizard_data.param_data IS 'List of all parameters with values covered into jsonb';


--
-- Name: COLUMN d_algo_wizard_data.date_start; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_algo_wizard_data.date_start IS 'SCD field. Date starting from that time record is active';


--
-- Name: COLUMN d_algo_wizard_data.date_end; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_algo_wizard_data.date_end IS 'SCD field. Date starting from that time record is non active';


--
-- Name: COLUMN d_algo_wizard_data.is_active; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_algo_wizard_data.is_active IS 'SCD field. Indicated if record is currently active';


--
-- Name: d_algo_wizard_data_algo_param_unq_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_algo_wizard_data_algo_param_unq_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_algo_wizard_data_algo_param_unq_id_seq OWNER TO dwh;

--
-- Name: d_algo_wizard_data_algo_param_unq_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_algo_wizard_data_algo_param_unq_id_seq OWNED BY dwh.d_algo_wizard_data.algo_param_unq_id;


--
-- Name: d_algo_wizard_data_test; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_algo_wizard_data_test (
    algo_param_unq_id bigint NOT NULL,
    target_strategy_id integer NOT NULL,
    account_id integer NOT NULL,
    instrument_type_id character(1),
    param_data text,
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_algo_wizard_data_test OWNER TO dwh;

--
-- Name: d_algo_wizard_data_test_algo_param_unq_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_algo_wizard_data_test_algo_param_unq_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_algo_wizard_data_test_algo_param_unq_id_seq OWNER TO dwh;

--
-- Name: d_algo_wizard_data_test_algo_param_unq_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_algo_wizard_data_test_algo_param_unq_id_seq OWNED BY dwh.d_algo_wizard_data_test.algo_param_unq_id;


--
-- Name: d_algo_wizard_data_tr_firm; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_algo_wizard_data_tr_firm (
    algo_param_unq_id bigint NOT NULL,
    target_strategy_id integer NOT NULL,
    trading_firm_id character varying(50) NOT NULL,
    instrument_type_id character(1),
    param_data text,
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_algo_wizard_data_tr_firm OWNER TO dwh;

--
-- Name: d_algo_wizard_data_tr_firm_algo_param_unq_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_algo_wizard_data_tr_firm_algo_param_unq_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_algo_wizard_data_tr_firm_algo_param_unq_id_seq OWNER TO dwh;

--
-- Name: d_algo_wizard_data_tr_firm_algo_param_unq_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_algo_wizard_data_tr_firm_algo_param_unq_id_seq OWNED BY dwh.d_algo_wizard_data_tr_firm.algo_param_unq_id;


--
-- Name: d_algo_wizard_data_trader; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_algo_wizard_data_trader (
    algo_param_unq_id bigint NOT NULL,
    target_strategy_id integer NOT NULL,
    trader_internal_id bigint NOT NULL,
    instrument_type_id character(1),
    param_data text,
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_algo_wizard_data_trader OWNER TO dwh;

--
-- Name: d_algo_wizard_data_trader_algo_param_unq_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_algo_wizard_data_trader_algo_param_unq_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_algo_wizard_data_trader_algo_param_unq_id_seq OWNER TO dwh;

--
-- Name: d_algo_wizard_data_trader_algo_param_unq_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_algo_wizard_data_trader_algo_param_unq_id_seq OWNED BY dwh.d_algo_wizard_data_trader.algo_param_unq_id;


--
-- Name: d_ats_liquidity_provider; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_ats_liquidity_provider (
    liquidity_provider_id character varying(9) NOT NULL,
    liquidity_provider_name character varying(60) NOT NULL,
    create_time timestamp with time zone NOT NULL,
    is_active boolean,
    delete_time timestamp with time zone,
    lp_symbol_list_id integer,
    lp_symbol_black_list_id integer,
    lp_demo_mnemonic character varying(60)
);


ALTER TABLE dwh.d_ats_liquidity_provider OWNER TO dwh;

--
-- Name: d_bloomberg_strategy_name; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_bloomberg_strategy_name (
    bloomberg_strategy_name_unq_id integer NOT NULL,
    original_sub_strategy character varying(128) NOT NULL,
    aggression_level smallint,
    trading_firm_id character varying(9) NOT NULL,
    bloomberg_strategy_name character varying(255) NOT NULL,
    original_sub_strategy_unq_id integer,
    trading_firm_unq_id integer NOT NULL
);


ALTER TABLE dwh.d_bloomberg_strategy_name OWNER TO dwh;

--
-- Name: d_bloomberg_strategy_name_bloomberg_strategy_name_unq_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_bloomberg_strategy_name_bloomberg_strategy_name_unq_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_bloomberg_strategy_name_bloomberg_strategy_name_unq_id_seq OWNER TO dwh;

--
-- Name: d_bloomberg_strategy_name_bloomberg_strategy_name_unq_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_bloomberg_strategy_name_bloomberg_strategy_name_unq_id_seq OWNED BY dwh.d_bloomberg_strategy_name.bloomberg_strategy_name_unq_id;


--
-- Name: d_capacity_group; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_capacity_group (
    capacity_group_id integer,
    capacity_group_name character varying(30),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_capacity_group OWNER TO dwh;

--
-- Name: d_clearing_account; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_clearing_account (
    clearing_account_id integer NOT NULL,
    account_id integer NOT NULL,
    clearing_account_name character varying(256),
    clearing_account_type character(1) NOT NULL,
    clearing_account_number character varying(30) NOT NULL,
    is_default character(1) NOT NULL,
    major_account character varying(5),
    account_executive_number character varying(3),
    office_code character varying(3),
    market_type character(1) NOT NULL,
    cmta character varying(3),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_clearing_account OWNER TO dwh;

--
-- Name: d_client; Type: VIEW; Schema: dwh; Owner: dwh_reader
--

CREATE VIEW dwh.d_client AS
 SELECT client_id AS client_unq_id,
    client_src_id AS client_id
   FROM data_marts.d_client;


ALTER VIEW dwh.d_client OWNER TO dwh_reader;

--
-- Name: d_client_name_override; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_client_name_override (
    trading_firm_id character varying(9) NOT NULL,
    original_client_name character varying(255) NOT NULL,
    overriden_client_name character varying(255) NOT NULL
);


ALTER TABLE dwh.d_client_name_override OWNER TO dwh;

--
-- Name: d_commission_set; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_commission_set (
    commission_set_id integer NOT NULL,
    account_id integer,
    ticker_group_id integer,
    instrument_type_id character varying(1),
    scope character varying(1),
    opt_incr_type character varying(1),
    start_date date,
    end_date date,
    date_start timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    date_end timestamp without time zone,
    trading_firm_id character varying(9),
    subject character varying(1) NOT NULL,
    commission_type character varying(1),
    calculation_method character varying(1) NOT NULL
);


ALTER TABLE dwh.d_commission_set OWNER TO dwh;

--
-- Name: d_commission_setting; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_commission_setting (
    commission_setting_unq_id integer NOT NULL,
    commission_setting_id integer NOT NULL,
    commission_set_id integer NOT NULL,
    account_id integer,
    trading_firm_id character varying(9),
    trding_firm_unq_id integer,
    instrument_type_id character(1),
    commission_type character(1),
    routing_type character(1),
    start_date date,
    end_date date,
    commission_tier json,
    misc_fee json,
    date_start timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    date_end timestamp without time zone,
    is_active boolean DEFAULT false NOT NULL
);


ALTER TABLE dwh.d_commission_setting OWNER TO dwh;

--
-- Name: d_customer_or_firm; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_customer_or_firm (
    capacity_group_id integer NOT NULL,
    customer_or_firm_id character varying(1) NOT NULL,
    customer_or_firm_name character varying(255) NOT NULL,
    is_active boolean,
    start_date timestamp without time zone,
    end_date timestamp without time zone
);


ALTER TABLE dwh.d_customer_or_firm OWNER TO dwh;

--
-- Name: d_exchange_connection; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_exchange_connection (
    exchange_id character varying(6) NOT NULL,
    exchange_unq_id smallint NOT NULL,
    exchange_connector_id character varying(30) NOT NULL,
    fix_connection_id integer NOT NULL,
    fix_engine_session_id character varying(30),
    date_start timestamp(3) without time zone,
    date_end timestamp(3) without time zone,
    is_active boolean,
    description character varying(256),
    client_order_id_range_mask character varying(30),
    exch_lb_instance_name character varying(20),
    uid_complex_pattern_id character varying(32),
    exchange_connection_id integer NOT NULL,
    intended_scope_of_use character(1) DEFAULT 'D'::bpchar NOT NULL,
    fix_session_role smallint DEFAULT 1 NOT NULL,
    leg_uid_complex_pattern_id character varying(32)
);


ALTER TABLE dwh.d_exchange_connection OWNER TO dwh;

--
-- Name: d_fix_connection; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_fix_connection (
    fix_connection_id smallint NOT NULL,
    acceptor_id character varying(30) NOT NULL,
    heartbeat_interval smallint,
    fix_comp_id character varying(30) NOT NULL,
    start_time character varying(5),
    terminate_time character varying(5),
    in_seq_num bigint NOT NULL,
    out_seq_num bigint NOT NULL,
    force_seq_num_reset character varying(1),
    description character varying(256),
    recreate_on_logout character varying(1) NOT NULL,
    intraday_logout_tolerance character varying(1) NOT NULL,
    force_reconnect character varying(1) NOT NULL,
    rej_no_connection character varying(1) NOT NULL,
    ign_seq_too_how_logon character varying(1) NOT NULL,
    max_msg_in_bunch bigint NOT NULL,
    tcp_buffer_disabled character varying(1) NOT NULL,
    user_name character varying(30),
    user_name_tag integer,
    password character varying(16),
    password_tag integer,
    password_tag_length smallint,
    sender_sub_id character varying(20),
    target_sub_id character varying(20),
    is_high_frequency_trader character varying(1) NOT NULL,
    config_session_name character varying(30),
    allow_msg_wo_poss_dup_flag character varying(1),
    sub_system_id character varying(20),
    expected_start_time character varying(5),
    expected_terminate_time character varying(5),
    cancel_on_disconnect character varying(1) NOT NULL,
    is_active boolean,
    start_date timestamp(3) without time zone,
    end_date timestamp(3) without time zone
);


ALTER TABLE dwh.d_fix_connection OWNER TO dwh;

--
-- Name: d_eos_fix_connection_v; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.d_eos_fix_connection_v AS
 SELECT ec.fix_engine_session_id,
    ec.exchange_id,
    ec.fix_connection_id,
    fc.fix_comp_id,
    fc.config_session_name
   FROM (dwh.d_exchange_connection ec
     LEFT JOIN dwh.d_fix_connection fc ON ((ec.fix_connection_id = fc.fix_connection_id)))
  WHERE ((1 = 1) AND ((ec.exchange_connector_id)::text ~~ '%HFT%'::text) AND (ec.is_active = true));


ALTER VIEW dwh.d_eos_fix_connection_v OWNER TO dwh;

--
-- Name: d_ex_destination; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_ex_destination (
    ex_destination_id smallint NOT NULL,
    ex_destination_code character varying(5),
    ex_destination_desc character varying(255),
    instrument_type_id character(1),
    exchange_id character varying(6),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_ex_destination OWNER TO dwh;

--
-- Name: d_ex_destination_code; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_ex_destination_code (
    ex_destination_code character varying(5) NOT NULL,
    ex_destination_code_name character varying(256) NOT NULL,
    date_start timestamp(3) without time zone,
    date_end timestamp(3) without time zone,
    is_acitive boolean
);


ALTER TABLE dwh.d_ex_destination_code OWNER TO dwh;

--
-- Name: d_exchange; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_exchange (
    exchange_unq_id smallint NOT NULL,
    exchange_id character varying(6) NOT NULL,
    exchange_name character varying(256),
    activ_exchange_code character varying(6),
    internalization_priority smallint,
    eq_mpid character varying(4),
    is_activ_md_required character(1),
    display_exchange_name character varying(32),
    instrument_type_id character(1),
    customer_or_firm_tag integer,
    trading_venue_class character(1),
    exch_rt_pref_code_tag integer,
    is_rt_mngr_eligible character(1),
    tcce_display_name character varying(40),
    exegy_exchange_code character varying(6),
    date_start timestamp(3) without time zone,
    date_end timestamp(3) without time zone,
    real_exchange_id character varying(6),
    may_street_exchange_code smallint,
    is_active boolean,
    mic_code character varying(4),
    last_mkt character varying(5),
    exec_broker_tag numeric(5,0),
    dark_venue_category_id character(1),
    cat_exchange_id character varying(9),
    cat_crd character varying(15),
    cat_is_exchange character(1),
    cat_suppress character(1),
    cat_collapse character(1),
    is_exchange_active boolean,
    eq_mpid_tag integer,
    eq_order_capacity_tag integer
);


ALTER TABLE dwh.d_exchange OWNER TO dwh;

--
-- Name: TABLE d_exchange; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON TABLE dwh.d_exchange IS 'Excahnge Dimension ';


--
-- Name: COLUMN d_exchange.exchange_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_exchange.exchange_unq_id IS 'Primary Key';


--
-- Name: COLUMN d_exchange.exchange_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_exchange.exchange_id IS 'Naturral key ';


--
-- Name: COLUMN d_exchange.exchange_name; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_exchange.exchange_name IS 'EXCHANGE NAME';


--
-- Name: COLUMN d_exchange.exec_broker_tag; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_exchange.exec_broker_tag IS 'Specifies value of tag for street level EXEC Broker (e.g. if exchange uses tag 76, 50, ...)';


--
-- Name: d_exchange2customer_or_firm; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_exchange2customer_or_firm (
    exchange2customer_or_firm_unq_id integer NOT NULL,
    exchange_unq_id smallint NOT NULL,
    exchange_id character varying(6) NOT NULL,
    customer_or_firm_id character(1) NOT NULL,
    exch_customer_or_firm_id character(1) NOT NULL,
    exch_customer_or_firm_name character varying(255) NOT NULL,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_exchange2customer_or_firm OWNER TO dwh;

--
-- Name: d_exchange2customer_or_firm_exchange2customer_or_firm_unq_i_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_exchange2customer_or_firm_exchange2customer_or_firm_unq_i_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_exchange2customer_or_firm_exchange2customer_or_firm_unq_i_seq OWNER TO dwh;

--
-- Name: d_exchange2customer_or_firm_exchange2customer_or_firm_unq_i_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_exchange2customer_or_firm_exchange2customer_or_firm_unq_i_seq OWNED BY dwh.d_exchange2customer_or_firm.exchange2customer_or_firm_unq_id;


--
-- Name: d_exchange_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_exchange_type (
    exchange_type_id bpchar NOT NULL,
    exchange_type_name character varying(64)
);


ALTER TABLE dwh.d_exchange_type OWNER TO dwh;

--
-- Name: d_exchlb_calibration_monitor; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_exchlb_calibration_monitor (
    monitoring_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    fix_engine_session_id character varying(30),
    exch_lb_instance_name character varying(20) NOT NULL,
    calibration_type character(1),
    transport_adjustment numeric(12,4),
    transport_rtt integer,
    application_adjustment numeric(12,4),
    application_rtt integer,
    estimated_delay integer,
    CONSTRAINT ckc_calibration_type_exch_lb_ CHECK (((calibration_type IS NULL) OR (calibration_type = ANY (ARRAY['A'::bpchar, 'M'::bpchar, 'O'::bpchar]))))
);


ALTER TABLE dwh.d_exchlb_calibration_monitor OWNER TO dwh;

--
-- Name: COLUMN d_exchlb_calibration_monitor.calibration_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_exchlb_calibration_monitor.calibration_type IS 'Calc field auto=>‘A’, sync => ‘M’, off => ‘O’';


--
-- Name: d_exec_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_exec_type (
    exec_type character(1) NOT NULL,
    exec_type_description character varying(256) NOT NULL
);


ALTER TABLE dwh.d_exec_type OWNER TO dwh;

--
-- Name: d_historic_definition; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_historic_definition (
    sms_hist_sec_def_id numeric,
    instrument_id bigint,
    trade_date timestamp without time zone,
    symbol character varying(10),
    instrument_type_id character(1),
    underlying_instrument_id bigint,
    maturity_year smallint,
    maturity_month smallint,
    maturity_day smallint,
    put_call character(1),
    strike_price numeric(12,4),
    opra_symbol character varying(30),
    instrument_name character varying(255),
    display_instrument_id character varying(100),
    activ_symbol character varying(30),
    instr_class_id character varying(2),
    symbol_suffix character varying(10),
    symbol_bats character varying(4000),
    symbol_cqs character varying(4000),
    cusip character varying(4000),
    trade_date_id integer
);


ALTER TABLE dwh.d_historic_definition OWNER TO dwh;

--
-- Name: d_instrument; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_instrument (
    instrument_id integer NOT NULL,
    instrument_type_id character(1),
    symbol character varying(10),
    display_instrument_id character varying(100),
    instrument_name character varying(255),
    is_trading_allowed character(1),
    activ_symbol character varying(30),
    symbol_suffix character varying(10),
    primary_exchange_id character varying(6),
    exegy_symbol character varying(30),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    last_trade_date timestamp(0) without time zone,
    is_active boolean,
    display_instrument_id2 character varying(100),
    pg_update_time timestamp without time zone
);


ALTER TABLE dwh.d_instrument OWNER TO dwh;

--
-- Name: d_instrument_class; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_instrument_class (
    instrument_class_id character varying(2),
    instrument_class_name character varying(30)
);


ALTER TABLE dwh.d_instrument_class OWNER TO dwh;

--
-- Name: d_instrument_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_instrument_type (
    instrument_type_id character(1),
    instrument_type_name character varying(100),
    instrument_type_table character varying(100),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_instrument_type OWNER TO dwh;

--
-- Name: d_last_market; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_last_market (
    last_mkt character varying(5) NOT NULL,
    last_mkt_name character varying(256) NOT NULL,
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_last_market OWNER TO dwh;

--
-- Name: sq_liquidity_indicator; Type: SEQUENCE; Schema: dwh; Owner: dhw_admin
--

CREATE SEQUENCE dwh.sq_liquidity_indicator
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_liquidity_indicator OWNER TO dhw_admin;

--
-- Name: d_liquidity_indicator; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_liquidity_indicator (
    sq_liquidity_indicator integer DEFAULT nextval('dwh.sq_liquidity_indicator'::regclass) NOT NULL,
    description character varying(256),
    exchange_id character varying(6) NOT NULL,
    is_grey character varying(1),
    liquidity_indicator_type_id smallint,
    trade_liquidity_indicator character varying(256) NOT NULL,
    is_active boolean,
    start_date date,
    end_date date
);


ALTER TABLE dwh.d_liquidity_indicator OWNER TO dwh;

--
-- Name: d_liquidity_indicator_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_liquidity_indicator_type (
    liquidity_indicator_type_id smallint NOT NULL,
    liquidity_indicator_type character varying(256) NOT NULL,
    start_date date,
    end_date date,
    is_active boolean
);


ALTER TABLE dwh.d_liquidity_indicator_type OWNER TO dwh;

--
-- Name: d_mpid; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_mpid (
    id integer NOT NULL,
    mpid character varying(10),
    mp_type character varying(10),
    name character varying(100),
    location character varying(100),
    telephone character varying(100),
    nasdaq_member character varying(100),
    fintra_member character varying(100),
    nasdaq_bx_member character varying(100),
    psx_participant character varying(100),
    db_load_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.d_mpid OWNER TO dwh;

--
-- Name: d_mpid_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.d_mpid_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.d_mpid_id_seq OWNER TO dwh;

--
-- Name: d_mpid_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.d_mpid_id_seq OWNED BY dwh.d_mpid.id;


--
-- Name: d_oats_account_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_oats_account_type (
    oats_account_type_code character(1) NOT NULL,
    oats_account_type_desc character varying(256) NOT NULL
);


ALTER TABLE dwh.d_oats_account_type OWNER TO dwh;

--
-- Name: d_opt_exec_broker; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_opt_exec_broker (
    opt_exec_broker_id integer NOT NULL,
    account_id bigint,
    is_default character varying(1) NOT NULL,
    opt_exec_broker character varying(3),
    is_active boolean,
    start_date timestamp(3) without time zone,
    end_date timestamp(3) without time zone
);


ALTER TABLE dwh.d_opt_exec_broker OWNER TO dwh;

--
-- Name: d_option_contract; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_option_contract (
    instrument_id bigint NOT NULL,
    option_series_id bigint,
    maturity_year smallint,
    maturity_month smallint,
    maturity_day smallint,
    put_call character(1),
    strike_price numeric(12,4),
    opra_symbol character varying(30),
    date_start timestamp(3) without time zone,
    date_end timestamp(3) without time zone,
    is_active boolean,
    pg_update_time timestamp without time zone,
    pg_big_data_create_time timestamp(6) without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.d_option_contract OWNER TO dwh;

--
-- Name: d_option_series; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_option_series (
    option_series_id bigint NOT NULL,
    underlying_instrument_id bigint NOT NULL,
    root_symbol character varying(10) NOT NULL,
    contract_multiplier bigint,
    shares_per_contract bigint,
    min_tick_increment numeric(12,4),
    exercise_style character varying(1),
    date_start timestamp(3) without time zone,
    date_end timestamp(3) without time zone,
    is_active boolean,
    cash_per_contract numeric(10,4),
    underlying_symbol_group bpchar,
    underlying_index_type bpchar,
    pg_update_time timestamp without time zone
);


ALTER TABLE dwh.d_option_series OWNER TO dwh;

--
-- Name: d_order_capacity; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_order_capacity (
    order_capacity_id character varying(1) NOT NULL,
    order_capacity_name character varying(255)
);


ALTER TABLE dwh.d_order_capacity OWNER TO dwh;

--
-- Name: d_order_status; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_order_status (
    order_status character varying NOT NULL,
    order_status_description character varying,
    is_active boolean,
    date_start timestamp(6) without time zone,
    date_end timestamp(6) without time zone
)
WITH (autovacuum_enabled='true', autovacuum_vacuum_scale_factor='2');


ALTER TABLE dwh.d_order_status OWNER TO dwh;

--
-- Name: d_order_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_order_type (
    order_type_id character(1) NOT NULL,
    order_type_short_name character varying(3),
    order_type_name character varying(255)
);


ALTER TABLE dwh.d_order_type OWNER TO dwh;

--
-- Name: d_osr_param_dictionary; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_osr_param_dictionary (
    osr_param_code character varying(6) NOT NULL,
    osr_param_scope character(1) NOT NULL,
    osr_param_name character varying(256) NOT NULL,
    osr_param_type character(1) NOT NULL,
    osr_param_desc character varying(1024),
    default_behavior character varying(1024),
    dash_public_fix_tag_num integer,
    osr_param_display_position smallint,
    is_active boolean DEFAULT true NOT NULL,
    date_start timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    date_end timestamp without time zone
);


ALTER TABLE dwh.d_osr_param_dictionary OWNER TO dwh;

--
-- Name: d_osr_param_set; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_osr_param_set (
    osr_param_set_id bigint NOT NULL,
    osr_param_set_desc character varying(256),
    osr_param_values json,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean,
    osr_param_code character varying
);


ALTER TABLE dwh.d_osr_param_set OWNER TO dwh;

--
-- Name: d_routing_table; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_routing_table (
    routing_table_unq_id integer NOT NULL,
    routing_table_id bigint NOT NULL,
    instr_class_id character varying(2),
    routing_table_name character varying(30) NOT NULL,
    routing_table_desc character varying(255),
    root_symbol character varying(10),
    routing_table_type character(1) NOT NULL,
    instrument_type_id character(1) NOT NULL,
    account_class_id character(1),
    capacity_group_id integer,
    orig_routing_table_id bigint,
    market_state character(1),
    target_strategy smallint NOT NULL,
    osr_param_set_id bigint,
    symbol_list_id character varying(6),
    fee_sensitivity smallint,
    symbol_suffix character varying(10),
    intended_scope_of_use character(1) NOT NULL,
    owner character(1) NOT NULL,
    owner_trading_firm_unq_id integer,
    owner_trading_firm_id character varying(9),
    is_default character varying(1),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_routing_table OWNER TO dwh;

--
-- Name: TABLE d_routing_table; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON TABLE dwh.d_routing_table IS 'Routing Table Dimension ';


--
-- Name: COLUMN d_routing_table.routing_table_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_routing_table.routing_table_type IS 'Roting table type.

Valid values:
''C'' (Routing by Instrument class);
''S'' (Routing by root symbol);
''T'' (Specific for instrument type);
''L'' (Specific for symbol list).';


--
-- Name: COLUMN d_routing_table.instrument_type_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_routing_table.instrument_type_id IS 'Instrument type unique identifier.';


--
-- Name: COLUMN d_routing_table.intended_scope_of_use; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_routing_table.intended_scope_of_use IS 'Indended scope.

Valid values:
''A'' (Account);
''T'' (Trading Firm);
''D'' (Default/Global).';


--
-- Name: COLUMN d_routing_table.owner; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_routing_table.owner IS 'The owner of the Routing Table.

Valid values:
''D'' (Dash Administrator);
''T'' (Trading Firm Manager).';


--
-- Name: COLUMN d_routing_table.owner_trading_firm_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_routing_table.owner_trading_firm_id IS 'The Trading Firm identification in case if Routing Table is created by Trading Firm Manager.';


--
-- Name: d_routing_table_entry; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_routing_table_entry (
    routing_table_entry_id bigint NOT NULL,
    exchange_type_id character(1) NOT NULL,
    exchange_rank_id character(1),
    routing_table_id bigint NOT NULL,
    routing_table_unq_id integer NOT NULL,
    exchange_id character varying(6) NOT NULL,
    exchange_priority character varying(10),
    comment character varying(255),
    billing_code_id smallint,
    ratio_table_id bigint,
    osr_param_set_id bigint,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_routing_table_entry OWNER TO dwh;

--
-- Name: d_strategy_decision_reason_code; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_strategy_decision_reason_code (
    strategy_decision_reason_code smallint NOT NULL,
    strategy_user_data character varying(256) NOT NULL,
    wave_type_name character varying(256),
    is_active boolean,
    start_date timestamp(3) without time zone,
    end_date timestamp(3) without time zone,
    wave_class_id bpchar
);


ALTER TABLE dwh.d_strategy_decision_reason_code OWNER TO dwh;

--
-- Name: d_sub_system; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_sub_system (
    sub_system_unq_id integer NOT NULL,
    sub_system_id character varying(20) NOT NULL,
    sub_system_name character varying(256),
    host character varying(32),
    service_port integer,
    sub_system_desc character varying(1024),
    monitoring_session_comp_id character varying(30),
    is_active boolean,
    date_start timestamp without time zone,
    date_end timestamp without time zone
);


ALTER TABLE dwh.d_sub_system OWNER TO dwh;

--
-- Name: TABLE d_sub_system; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON TABLE dwh.d_sub_system IS 'Sub System Dimension ';


--
-- Name: COLUMN d_sub_system.sub_system_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_sub_system.sub_system_unq_id IS 'Primary Key';


--
-- Name: COLUMN d_sub_system.sub_system_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_sub_system.sub_system_id IS 'Naturral key ';


--
-- Name: COLUMN d_sub_system.sub_system_name; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.d_sub_system.sub_system_name IS 'Sub System NAME';


--
-- Name: d_symbol_list; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_symbol_list (
    symbol_list_id character varying(6) NOT NULL,
    symbol_list_name character varying(256) NOT NULL,
    symbol_list_desc character varying(256),
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone,
    is_active boolean NOT NULL
);


ALTER TABLE dwh.d_symbol_list OWNER TO dwh;

--
-- Name: d_target_strategy; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_target_strategy (
    target_strategy_id integer NOT NULL,
    target_strategy_desc character varying(128) NOT NULL,
    is_default character(1) NOT NULL,
    target_strategy_name character varying(128),
    target_strategy_group_id bigint,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean,
    strategy_alias character varying[]
);


ALTER TABLE dwh.d_target_strategy OWNER TO dwh;

SET default_tablespace = ssd_ts;

--
-- Name: d_test_symbol_list; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: ssd_ts
--

CREATE TABLE dwh.d_test_symbol_list (
    symbol character varying(10) NOT NULL
);


ALTER TABLE dwh.d_test_symbol_list OWNER TO dwh;

SET default_tablespace = '';

--
-- Name: d_time_in_force; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_time_in_force (
    tif_id character(1) NOT NULL,
    tif_short_name character varying(3),
    tif_name character varying(255),
    is_active boolean,
    date_start timestamp without time zone,
    date_end timestamp without time zone
);


ALTER TABLE dwh.d_time_in_force OWNER TO dwh;

--
-- Name: d_trader; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_trader (
    trader_internal_id integer NOT NULL,
    trader_id character varying(30),
    trader_description character varying(50),
    first_name character varying(30),
    last_name character varying(100),
    email character varying(60),
    phone_num character varying(20),
    company_name character varying(100),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_trader OWNER TO dwh;

--
-- Name: d_user2user_function; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_user2user_function (
    user_id integer,
    function_id character varying(6),
    access_mode character varying(1),
    user2user_unq_id integer NOT NULL,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_user2user_function OWNER TO dwh;

--
-- Name: d_user_function; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_user_function (
    function_id character varying(6) NOT NULL,
    description character varying(255),
    read_message_id character varying(2),
    write_message_id character varying(2),
    user_role character varying(1)
);


ALTER TABLE dwh.d_user_function OWNER TO dwh;

--
-- Name: d_user_identifier; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.d_user_identifier (
    user_id integer NOT NULL,
    acl_id integer,
    user_name character varying(30),
    password character varying(256),
    user_role character varying(1) NOT NULL,
    first_name character varying(30),
    last_name character varying(100),
    email character varying(60),
    phone_num character varying(20),
    is_locked character varying(1) NOT NULL,
    is_logging_enabled character varying(1),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.d_user_identifier OWNER TO dwh;

--
-- Name: dual; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.dual AS
 SELECT 1 AS dummy;


ALTER VIEW dwh.dual OWNER TO dwh;

--
-- Name: exchlb_latency; Type: TABLE; Schema: dwh; Owner: dhw_admin
--

CREATE TABLE dwh.exchlb_latency (
    exch_lb_instance_name character varying(20),
    client_order_id character varying(256),
    ex_destination_code character varying(5),
    transaction_id bigint,
    tot_no_orders_in_wave integer,
    receive_time timestamp(6) with time zone,
    send_time timestamp(6) with time zone,
    send_date_id numeric(8,0)
);


ALTER TABLE dwh.exchlb_latency OWNER TO dhw_admin;

--
-- Name: execution; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.execution (
    exec_id bigint NOT NULL,
    order_id bigint NOT NULL,
    order_status character(1),
    exec_type character(1) NOT NULL,
    exec_date_id integer NOT NULL,
    exec_time timestamp(6) without time zone NOT NULL,
    is_busted character(1) NOT NULL,
    leaves_qty bigint,
    cum_qty bigint,
    avg_px numeric,
    last_qty bigint,
    last_px numeric,
    bust_qty bigint,
    last_mkt character varying(5),
    contra_broker character varying(256),
    secondary_order_id character varying(256),
    exch_exec_id character varying(128),
    secondary_exch_exec_id character varying(128),
    contra_account_capacity character(1),
    trade_liquidity_indicator character varying(256),
    account_id integer,
    fix_message_id bigint,
    text_ character varying(512),
    is_parent_level boolean,
    exec_broker character varying(32),
    auction_id bigint,
    match_qty bigint,
    match_px numeric(12,4),
    internal_component_type character(1),
    exchange_id character varying(6),
    contra_trader character varying(256),
    ref_exec_id bigint,
    cnt integer,
    time_in_force_id character(1),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    dataset_id bigint,
    order_create_date_id integer,
    reject_code smallint
)
PARTITION BY RANGE (exec_date_id);


ALTER TABLE dwh.execution OWNER TO dwh;

--
-- Name: COLUMN execution.auction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.execution.auction_id IS 'Unique reference number assigned to the auction.';


--
-- Name: COLUMN execution.match_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.execution.match_qty IS 'Match quantity (number of shares/contracts). ';


--
-- Name: COLUMN execution.match_px; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.execution.match_px IS 'Match price.';


--
-- Name: execution_old; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.execution_old (
    exec_id bigint NOT NULL,
    order_id bigint NOT NULL,
    order_status character(1),
    exec_type character(1) NOT NULL,
    exec_date_id integer NOT NULL,
    exec_time timestamp(3) without time zone NOT NULL,
    is_billed character varying(1) DEFAULT 'N'::character varying,
    is_busted character(1) NOT NULL,
    leaves_qty integer,
    cum_qty integer,
    avg_px numeric(12,4),
    last_qty integer,
    last_px numeric(12,4),
    bust_qty integer,
    dataset_id integer,
    last_mkt character varying(5),
    contra_broker character varying(256),
    secondary_order_id character varying(256),
    exch_exec_id character varying(128),
    secondary_exch_exec_id character varying(128),
    contra_account_capacity character(1),
    trade_liquidity_indicator character varying(256),
    account_id integer,
    fix_message_id bigint,
    text_ character varying(512),
    is_parent_level boolean,
    exec_broker character varying(32),
    auction_id bigint,
    match_qty integer,
    match_px numeric(12,4),
    internal_component_type character(1),
    exchange_id character varying(6),
    contra_trader character varying(256)
);


ALTER TABLE dwh.execution_old OWNER TO dwh;

--
-- Name: COLUMN execution_old.auction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.execution_old.auction_id IS 'Unique reference number assigned to the auction.';


--
-- Name: COLUMN execution_old.match_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.execution_old.match_qty IS 'Match quantity (number of shares/contracts). ';


--
-- Name: COLUMN execution_old.match_px; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.execution_old.match_px IS 'Match price.';


--
-- Name: fact_last_load_time; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.fact_last_load_time (
    table_name character varying(63),
    latest_load_time timestamp with time zone,
    pg_db_updated_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.fact_last_load_time OWNER TO dwh;

--
-- Name: COLUMN fact_last_load_time.table_name; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.fact_last_load_time.table_name IS 'Name of FACT table to retrieve the last load time stamp';


--
-- Name: COLUMN fact_last_load_time.latest_load_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.fact_last_load_time.latest_load_time IS 'The last load time stamp for the fact table by ETL';


--
-- Name: COLUMN fact_last_load_time.pg_db_updated_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.fact_last_load_time.pg_db_updated_time IS 'The time stamp when row was updated';


--
-- Name: fix_message_field; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.fix_message_field (
    fix_message_id integer NOT NULL,
    tag_num integer NOT NULL,
    field_value character varying(4000),
    pg_db_create_time timestamp(3) without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.fix_message_field OWNER TO dwh;

--
-- Name: fix_msg_upd; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.fix_msg_upd (
    fix_message_id bigint,
    date_id integer,
    btrim text
);


ALTER TABLE dwh.fix_msg_upd OWNER TO dwh;

--
-- Name: flat_trade_record; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.flat_trade_record (
    trade_record_id bigint NOT NULL,
    trade_record_time timestamp without time zone,
    db_create_time timestamp without time zone,
    date_id integer NOT NULL,
    is_busted character(1),
    orig_trade_record_id bigint,
    trade_record_trans_type character(1),
    trade_record_reason character(1),
    subsystem_id character varying(20),
    user_id integer,
    account_id integer,
    client_order_id character varying(256),
    instrument_id integer,
    side character(1),
    open_close character(1),
    fix_connection_id smallint,
    exec_id integer,
    exchange_id character varying(6),
    trade_liquidity_indicator character varying(256),
    secondary_order_id character varying(256),
    exch_exec_id character varying(128),
    secondary_exch_exec_id character varying(128),
    last_mkt character varying(5),
    last_qty integer,
    last_px numeric(16,8),
    ex_destination character varying(5),
    sub_strategy character varying(128),
    street_order_id bigint,
    order_id bigint,
    street_order_qty integer,
    order_qty integer,
    multileg_reporting_type character(1),
    is_largest_leg character(1),
    street_max_floor integer,
    exec_broker character varying(32),
    cmta character varying(3),
    street_time_in_force character(1),
    street_order_type character(1),
    opt_customer_firm character(1),
    street_mpid character varying(18),
    is_cross_order character(1),
    street_is_cross_order character(1),
    street_cross_type character(1),
    cross_is_originator character(1),
    street_cross_is_originator character(1),
    contra_account character(1),
    contra_broker character varying(256),
    trade_exec_broker character varying(32),
    order_fix_message_id integer,
    trade_fix_message_id integer,
    street_order_fix_message_id integer,
    bid_price numeric(16,4),
    ask_price numeric(16,4),
    trade_id numeric(24,0),
    client_id character varying(255),
    street_transaction_id bigint,
    transaction_id bigint,
    tcce_account_dash_commission_amount numeric(20,8),
    tcce_account_execution_cost numeric(20,8),
    tcce_firm_dash_commission_amount numeric(20,8),
    tcce_firm_execution_cost numeric(20,8),
    tcce_mss_fee_amount numeric(20,8),
    tcce_maker_taker_fee_amount numeric(20,8),
    tcce_occ_fee_amount numeric(20,8),
    tcce_option_regulatory_fee_amount numeric(20,8),
    tcce_royalty_fee_amount numeric(20,8),
    tcce_sec_fee_amount numeric(20,8),
    tcce_transaction_fee_amount numeric(20,8),
    tcce_trade_processing_fee_amount numeric(20,8),
    order_price numeric(12,4),
    order_process_time timestamp without time zone,
    clearing_account_number character varying(25),
    sub_account character varying(30),
    remarks character varying(100),
    optional_data character varying(25),
    street_client_order_id character varying(256),
    fix_comp_id character varying(30),
    ask_qty integer,
    bid_qty integer,
    is_billed character(1),
    street_exec_inst character varying(128),
    leaves_qty bigint,
    principal_amount numeric(20,4),
    trading_firm_id character varying(9),
    fee_sensitivity smallint,
    street_order_price numeric(12,4),
    routing_time_bid_price numeric(16,4),
    routing_time_bid_qty integer,
    routing_time_ask_price numeric(16,4),
    routing_time_ask_qty integer,
    is_street_order_marketable character(1),
    tcce_admin_maker_taker_fee_amount numeric(20,8),
    tcce_admin_transaction_fee_amount numeric(20,8),
    strategy_decision_reason_code smallint,
    compliance_id character varying(256),
    account_schedule_rate_type character varying(1),
    trading_firm_schedule_rate_type character varying(1),
    auction_id bigint,
    street_exec_broker character varying(32),
    multileg_order_id bigint,
    pg_big_data_create_time timestamp(6) without time zone DEFAULT clock_timestamp(),
    floor_broker_id character varying(255),
    street_opt_customer_firm character varying(1),
    internal_component_type character varying(1),
    instrument_type_id character varying(1),
    street_trade_fix_message_id bigint,
    pt_basket_id character varying(100),
    pt_order_id integer,
    transact_time timestamp without time zone,
    trade_exchange_id character varying(6),
    trading_firm_unq_id integer,
    client_commission_rate numeric(20,8),
    blaze_account_alias character varying(255),
    customer_review_status character(1) DEFAULT NULL::bpchar,
    street_account_name character varying(255),
    trade_text character varying(100),
    branch_sequence_number character varying(256),
    frequent_trader_id character varying(6),
    int_liq_source_type character varying(1),
    allocation_avg_price numeric(12,6),
    account_nickname character varying(40),
    load_batch_id bigint,
    clearing_account_id integer,
    market_participant_id character varying(18),
    alternative_compliance_id character varying(256),
    clearing_fee_amout numeric(16,4),
    street_trade_record_time timestamp without time zone,
    penny_nickel character(1),
    market_data_trade_time timestamp without time zone,
    tcce_admin_trade_processing_fee numeric(20,8),
    tcce_admin_royalty_fee numeric(20,8),
    street_order_process_time timestamp without time zone,
    leg_ref_id character varying(100)
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh.flat_trade_record OWNER TO dwh;

--
-- Name: COLUMN flat_trade_record.trade_record_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_record_time IS 'Exec time from PARENT level EXECUTION';


--
-- Name: COLUMN flat_trade_record.date_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.date_id IS 'based on exec_time of the parent level order';


--
-- Name: COLUMN flat_trade_record.orig_trade_record_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.orig_trade_record_id IS 'If we split trade we bust the old one and create two or more new trades with old_trade_record_if in the orig_trade_record_id field';


--
-- Name: COLUMN flat_trade_record.trade_record_trans_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_record_trans_type IS 'Based on client_order.trans_type of the parent level order';


--
-- Name: COLUMN flat_trade_record.trade_record_reason; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_record_reason IS 'Initially based on STRATEGY_DECISION_REASON_CODE field of the parent level of client_order record
- ''P'': post-trade modification/correction (all splits, clearing changes)
- ''A'': manual (away) trade
- ''B'': trade bust/cancel (electronic or manual)
- ''L'': manual allocation
- ''U'': Manual unallocation';


--
-- Name: COLUMN flat_trade_record.subsystem_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.subsystem_id IS 'Based on client_order.SUB_SYSTEM_ID of the parent order level';


--
-- Name: COLUMN flat_trade_record.user_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.user_id IS 'Based on client_order.user_id of the parent order level';


--
-- Name: COLUMN flat_trade_record.account_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.account_id IS 'Based on client_order.account_id of the parent order level';


--
-- Name: COLUMN flat_trade_record.client_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.client_order_id IS 'client_order_id of the parent level record';


--
-- Name: COLUMN flat_trade_record.instrument_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.instrument_id IS 'Based on client_order.instrument_id of the parent order level';


--
-- Name: COLUMN flat_trade_record.side; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.side IS 'Side of the parent level order';


--
-- Name: COLUMN flat_trade_record.open_close; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.open_close IS 'Based on client_order.open_close of the parent order level';


--
-- Name: COLUMN flat_trade_record.fix_connection_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.fix_connection_id IS 'Fix_connection_id of the parent level order. Base on cl.fix_connection_id';


--
-- Name: COLUMN flat_trade_record.exec_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.exec_id IS 'Exec ID of the parent level trade';


--
-- Name: COLUMN flat_trade_record.exchange_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.exchange_id IS 'Base on execution.EXCHANGE_ID of the parent order level';


--
-- Name: COLUMN flat_trade_record.trade_liquidity_indicator; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_liquidity_indicator IS 'Based on execution.TRADE_LIQUIDITY_INDICATOR of the parent order trade';


--
-- Name: COLUMN flat_trade_record.secondary_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.secondary_order_id IS 'Based on execution.SECONDARY_ORDER_ID of the parent order trade. Means street client_order_id???';


--
-- Name: COLUMN flat_trade_record.exch_exec_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.exch_exec_id IS 'Based on execution.exch_exec_id of the parent order trade. Means exec_id that arrives form the exchange';


--
-- Name: COLUMN flat_trade_record.secondary_exch_exec_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.secondary_exch_exec_id IS 'Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange';


--
-- Name: COLUMN flat_trade_record.last_mkt; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.last_mkt IS 'Based on execution.last_mkt of the parent order trade.';


--
-- Name: COLUMN flat_trade_record.last_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.last_qty IS 'Based on execution.last_qty of the parent order trade. Means quantity';


--
-- Name: COLUMN flat_trade_record.last_px; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.last_px IS 'Based on execution.last_px of the parent order trade. Means price';


--
-- Name: COLUMN flat_trade_record.ex_destination; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.ex_destination IS 'Based on client_order.ex_destination of the parent order level';


--
-- Name: COLUMN flat_trade_record.sub_strategy; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.sub_strategy IS 'Based on client_order.sub_strategy of the parent order level';


--
-- Name: COLUMN flat_trade_record.street_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_order_id IS 'street order_id str.order_id';


--
-- Name: COLUMN flat_trade_record.order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.order_id IS 'parent order ID cl.order_id';


--
-- Name: COLUMN flat_trade_record.street_order_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_order_qty IS 'order_qty arrives from STREET level of client_order table';


--
-- Name: COLUMN flat_trade_record.order_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.order_qty IS 'order_qty arrives from PARENT level of client_order table';


--
-- Name: COLUMN flat_trade_record.multileg_reporting_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.multileg_reporting_type IS 'MULTILEG_REPORTING_TYPE arrives from PARENT level of client_order table';


--
-- Name: COLUMN flat_trade_record.is_largest_leg; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.is_largest_leg IS 'by default ''N'' ';


--
-- Name: COLUMN flat_trade_record.street_max_floor; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_max_floor IS 'MAX_FLOOR field of the STREET level client order';


--
-- Name: COLUMN flat_trade_record.exec_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.exec_broker IS 'based on  street client_order.opt_exec_broker ';


--
-- Name: COLUMN flat_trade_record.cmta; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.cmta IS 'Based on client_order.Clearing_firm_id of he parent level order. if it is empty we use 439 fix message if still empty we use  clearing_account.CMTA';


--
-- Name: COLUMN flat_trade_record.street_time_in_force; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_time_in_force IS 'Based on client_order.TIME_IN_FORCE of the strret level order';


--
-- Name: COLUMN flat_trade_record.street_order_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_order_type IS 'Based on client_order.ORDER_TYPE of the strret level order';


--
-- Name: COLUMN flat_trade_record.opt_customer_firm; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.opt_customer_firm IS 'Based on client_order.OPT_CUSTOMER_FIRM of the parent level order';


--
-- Name: COLUMN flat_trade_record.street_mpid; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_mpid IS 'Based on client_order.MPID of the strret level order';


--
-- Name: COLUMN flat_trade_record.is_cross_order; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.is_cross_order IS 'N if cross_order_id of the parent level order is null and Y in other case';


--
-- Name: COLUMN flat_trade_record.street_is_cross_order; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_is_cross_order IS 'N if cross_order_id of the street level order is null and Y in other case';


--
-- Name: COLUMN flat_trade_record.street_cross_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_cross_type IS 'CROSS_TYPE of the street level order';


--
-- Name: COLUMN flat_trade_record.cross_is_originator; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.cross_is_originator IS 'Based on the IS_ORIGINATOR of the PARENT level client_order';


--
-- Name: COLUMN flat_trade_record.street_cross_is_originator; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_cross_is_originator IS 'Based on the IS_ORIGINATOR of the STREET level client_order';


--
-- Name: COLUMN flat_trade_record.contra_account; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.contra_account IS 'Based on the CONTRA_ACCOUNT_CAPACITY field of the PARENT level exection';


--
-- Name: COLUMN flat_trade_record.contra_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.contra_broker IS 'Based on the CONTRA_BROKER field of the PARENT level exection';


--
-- Name: COLUMN flat_trade_record.trade_exec_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_exec_broker IS 'based on execution.exec_broker';


--
-- Name: COLUMN flat_trade_record.order_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.order_fix_message_id IS 'Based on the fix_message_id field of the PARENT level client_order';


--
-- Name: COLUMN flat_trade_record.trade_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_fix_message_id IS 'Based on the fix_message_id field of the PARENT level EXECUTION';


--
-- Name: COLUMN flat_trade_record.street_order_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_order_fix_message_id IS 'Based on the fix_message_id field of the STREET level of client_order table';


--
-- Name: COLUMN flat_trade_record.bid_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.bid_price IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_price)';


--
-- Name: COLUMN flat_trade_record.ask_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.ask_price IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_price)';


--
-- Name: COLUMN flat_trade_record.trade_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_id IS 'A-la FK to market_data.trade.trade_id';


--
-- Name: COLUMN flat_trade_record.client_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.client_id IS 'Based on the client_id field of the PARENT level client_order';


--
-- Name: COLUMN flat_trade_record.street_transaction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_transaction_id IS 'client_order.transaction_id of the street level';


--
-- Name: COLUMN flat_trade_record.transaction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.transaction_id IS 'client_order.transaction_id of the parent order level';


--
-- Name: COLUMN flat_trade_record.tcce_account_dash_commission_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_account_dash_commission_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_account_execution_cost; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_account_execution_cost IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_firm_dash_commission_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_firm_dash_commission_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_firm_execution_cost; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_firm_execution_cost IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_mss_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_mss_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_maker_taker_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_maker_taker_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_occ_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_occ_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_option_regulatory_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_option_regulatory_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_royalty_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_royalty_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_sec_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_sec_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_transaction_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_transaction_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.tcce_trade_processing_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_trade_processing_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record.order_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.order_price IS 'Based on client_order.PRICE of the parent order level';


--
-- Name: COLUMN flat_trade_record.order_process_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.order_process_time IS 'Based on client_order.PROCESS_TIME of the parent order level';


--
-- Name: COLUMN flat_trade_record.ask_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.ask_qty IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_qty)';


--
-- Name: COLUMN flat_trade_record.bid_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.bid_qty IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_qty)';


--
-- Name: COLUMN flat_trade_record.is_billed; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.is_billed IS 'Value indicates if trade is billed, not billed or prepared for recalculation. ''Y'', ''N'', ''R'', ''D''. ''E'' - TCCE error';


--
-- Name: COLUMN flat_trade_record.street_exec_inst; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_exec_inst IS 'based on EXEC_INST of the street level order';


--
-- Name: COLUMN flat_trade_record.leaves_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.leaves_qty IS 'Based on the LEAVES_QTY field of the PARENT level EXECUTION';


--
-- Name: COLUMN flat_trade_record.fee_sensitivity; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.fee_sensitivity IS 'Fee sencitivity of the parent level execution. Arrives from the 9090 fix message tag';


--
-- Name: COLUMN flat_trade_record.street_order_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_order_price IS 'arrives from client_order.price of street order level';


--
-- Name: COLUMN flat_trade_record.routing_time_bid_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.routing_time_bid_price IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record.routing_time_bid_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.routing_time_bid_qty IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record.routing_time_ask_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.routing_time_ask_price IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record.routing_time_ask_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.routing_time_ask_qty IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record.is_street_order_marketable; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.is_street_order_marketable IS 'Y/N ';


--
-- Name: COLUMN flat_trade_record.tcce_admin_maker_taker_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_maker_taker_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table AMTK book_record_type_id';


--
-- Name: COLUMN flat_trade_record.tcce_admin_transaction_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_transaction_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table ATF book_record_type_id';


--
-- Name: COLUMN flat_trade_record.strategy_decision_reason_code; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.strategy_decision_reason_code IS 'Routing reason. Based on strategy_decision_reason_code of the strret order. Parent order field is used in case street order value is null';


--
-- Name: COLUMN flat_trade_record.compliance_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.compliance_id IS 'Based on client_order.compliance_id of the parent level order';


--
-- Name: COLUMN flat_trade_record.auction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.auction_id IS 'AUCTION_ID based on execution.AUCTION_ID of the parent order level';


--
-- Name: COLUMN flat_trade_record.street_exec_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_exec_broker IS 'Exec Broker of street level order. Based on tag value provided in d_exchange';


--
-- Name: COLUMN flat_trade_record.multileg_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.multileg_order_id IS 'The vaule is based on CO_MULTILEG_ORDER_ID of the parent order';


--
-- Name: COLUMN flat_trade_record.floor_broker_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.floor_broker_id IS 'Tag 143 of the customer order. Assigned value used to identify specific message destination''s location (i.e. geographic location and/or desk, trader)';


--
-- Name: COLUMN flat_trade_record.street_opt_customer_firm; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_opt_customer_firm IS 'Customer_or_firm id fo the street order level. Arrives from tag 47 or tag 204';


--
-- Name: COLUMN flat_trade_record.internal_component_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.internal_component_type IS 'INTERNAL_COMPONENT_TYPE of the parent execution level';


--
-- Name: COLUMN flat_trade_record.instrument_type_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN flat_trade_record.street_trade_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_trade_fix_message_id IS 'Fix message ID of street trade';


--
-- Name: COLUMN flat_trade_record.pt_basket_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.pt_basket_id IS 'Basket_id of the parent order. Base on 9047 tag of parent order fix message';


--
-- Name: COLUMN flat_trade_record.transact_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.transact_time IS 'Based on Tag 60 of the execution report';


--
-- Name: COLUMN flat_trade_record.trade_exchange_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_exchange_id IS 'exhcnage_id of the venue where trade was realy executed. The field is null when trade executed on the same exchenage_id as routed ';


--
-- Name: COLUMN flat_trade_record.trading_firm_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trading_firm_unq_id IS 'FK to d_trading_firm';


--
-- Name: COLUMN flat_trade_record.client_commission_rate; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.client_commission_rate IS 'Client commission rate per unit. Customer uses to charge its client';


--
-- Name: COLUMN flat_trade_record.blaze_account_alias; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.blaze_account_alias IS 'Base on EDWDilling..TOrder_EDW.AccountAlias. Filled for blaze traffic only';


--
-- Name: COLUMN flat_trade_record.street_account_name; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_account_name IS 'street_account_name based on Tag 1 of of street trade fix message. Arrives from genesis2.trade_record';


--
-- Name: COLUMN flat_trade_record.trade_text; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.trade_text IS 'Based on 58 tag of parent execution ';


--
-- Name: COLUMN flat_trade_record.branch_sequence_number; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.branch_sequence_number IS 'Based on 9861 tag of parent execution ';


--
-- Name: COLUMN flat_trade_record.frequent_trader_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.frequent_trader_id IS 'CBOE-specific field "FrequentTraderID" based on tag 21097 of the street trade message. Arrives from PG genesis2.trade_record';


--
-- Name: COLUMN flat_trade_record.int_liq_source_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.int_liq_source_type IS 'A - ATS, C - Consolidator';


--
-- Name: COLUMN flat_trade_record.allocation_avg_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.allocation_avg_price IS 'Avarenge price of allocated trades';


--
-- Name: COLUMN flat_trade_record.account_nickname; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.account_nickname IS 'account_nickname. should be populated from the dash360 as free text during allocation';


--
-- Name: COLUMN flat_trade_record.load_batch_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.load_batch_id IS 'The field for ETL purposes';


--
-- Name: COLUMN flat_trade_record.clearing_account_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.clearing_account_id IS 'FK to d_clearing_account';


--
-- Name: COLUMN flat_trade_record.market_participant_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.market_participant_id IS 'Tag 115 of the parent order. Based on client_order.MPID field of the parent order level';


--
-- Name: COLUMN flat_trade_record.alternative_compliance_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.alternative_compliance_id IS 'Tag 6376 of the parent order. Based on client_order.ALTERNATIVE_COMPLIANCE_ID field of the parent order level';


--
-- Name: COLUMN flat_trade_record.clearing_fee_amout; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.clearing_fee_amout IS 'Based on trade_level Book record CLRF book_record_type';


--
-- Name: COLUMN flat_trade_record.street_trade_record_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.street_trade_record_time IS 'Exec time from street level EXECUTION';


--
-- Name: COLUMN flat_trade_record.market_data_trade_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.market_data_trade_time IS 'trade_time from market_data.trade';


--
-- Name: COLUMN flat_trade_record.tcce_admin_trade_processing_fee; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_trade_processing_fee IS 'Arrives from the postgres PROD trade_level_book_record table ATPF book_record_type_id';


--
-- Name: COLUMN flat_trade_record.tcce_admin_royalty_fee; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_royalty_fee IS 'Arrives from the postgres PROD trade_level_book_record table ARTY book_record_type_id';


--
-- Name: flat_trade_record_old; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.flat_trade_record_old (
    trade_record_id integer NOT NULL,
    trade_record_time timestamp without time zone,
    db_create_time timestamp without time zone,
    date_id integer NOT NULL,
    is_busted character(1),
    orig_trade_record_id integer,
    trade_record_trans_type character(1),
    trade_record_reason character(1),
    subsystem_id character varying(20),
    user_id integer,
    account_id integer,
    client_order_id character varying(256),
    instrument_id integer,
    side character(1),
    open_close character(1),
    fix_connection_id smallint,
    exec_id integer,
    exchange_id character varying(6),
    trade_liquidity_indicator character varying(256),
    secondary_order_id character varying(256),
    exch_exec_id character varying(128),
    secondary_exch_exec_id character varying(128),
    last_mkt character varying(5),
    last_qty integer,
    last_px numeric(12,4),
    ex_destination character varying(5),
    sub_strategy character varying(128),
    street_order_id bigint,
    order_id bigint,
    street_order_qty integer,
    order_qty integer,
    multileg_reporting_type character(1),
    is_largest_leg character(1),
    street_max_floor integer,
    exec_broker character varying(32),
    cmta character varying(3),
    street_time_in_force character(1),
    street_order_type character(1),
    opt_customer_firm character(1),
    street_mpid character varying(18),
    is_cross_order character(1),
    street_is_cross_order character(1),
    street_cross_type character(1),
    cross_is_originator character(1),
    street_cross_is_originator character(1),
    contra_account character(1),
    contra_broker character varying(256),
    trade_exec_broker character varying(32),
    order_fix_message_id integer,
    trade_fix_message_id integer,
    street_order_fix_message_id integer,
    bid_price numeric(16,4),
    ask_price numeric(16,4),
    trade_id numeric(24,0),
    client_id character varying(255),
    street_transaction_id bigint,
    transaction_id bigint,
    tcce_account_dash_commission_amount numeric(16,4),
    tcce_account_execution_cost numeric(16,4),
    tcce_firm_dash_commission_amount numeric(16,4),
    tcce_firm_execution_cost numeric(16,4),
    tcce_mss_fee_amount numeric(16,4),
    tcce_maker_taker_fee_amount numeric(16,4),
    tcce_occ_fee_amount numeric(16,4),
    tcce_option_regulatory_fee_amount numeric(16,4),
    tcce_royalty_fee_amount numeric(16,4),
    tcce_sec_fee_amount numeric(16,4),
    tcce_transaction_fee_amount numeric(16,4),
    tcce_trade_processing_fee_amount numeric(16,4),
    order_price numeric(12,4),
    order_process_time timestamp(3) without time zone,
    clearing_account_number character varying(25),
    sub_account character varying(30),
    remarks character varying(100),
    pfof_exchange_marketing_fee numeric(16,4),
    pfof_maker_taker_fee numeric(16,4),
    pfof_royalty_fee numeric(16,4),
    pfof_complex_rebates numeric(16,4),
    pfof_break_up_rebates numeric(16,4),
    pfof_crossing_rebates numeric(16,4),
    optional_data character varying(25),
    street_client_order_id character varying(256),
    fix_comp_id character varying(30),
    ask_qty integer,
    bid_qty integer,
    is_billed character(1),
    street_exec_inst character varying(128),
    leaves_qty bigint,
    principal_amount numeric(20,4),
    trading_firm_id character varying(9),
    fee_sensitivity smallint,
    street_order_price numeric(12,4),
    routing_time_bid_price numeric(16,4),
    routing_time_bid_qty integer,
    routing_time_ask_price numeric(16,4),
    routing_time_ask_qty integer,
    is_street_order_marketable character(1),
    tcce_admin_maker_taker_fee_amount numeric(16,4),
    tcce_admin_transaction_fee_amount numeric(16,4),
    strategy_decision_reason_code smallint,
    compliance_id character varying(256),
    account_schedule_rate_type character varying(1),
    trading_firm_schedule_rate_type character varying(1),
    auction_id bigint,
    street_exec_broker character varying(32),
    multileg_order_id bigint,
    pg_big_data_create_time timestamp(6) without time zone DEFAULT clock_timestamp(),
    floor_broker_id character varying(255),
    street_opt_customer_firm character varying(1),
    internal_component_type character varying(1),
    instrument_type_id character varying(1),
    street_trade_fix_message_id bigint,
    pt_basket_id character varying(100),
    pt_order_id integer,
    transact_time timestamp without time zone,
    trade_exchange_id character varying(6),
    trading_firm_unq_id integer,
    client_commission_rate numeric(16,6),
    blaze_account_alias character varying(255),
    customer_review_status character(1) DEFAULT NULL::bpchar,
    street_account_name character varying(255),
    trade_text character varying(100),
    branch_sequence_number character varying(256),
    frequent_trader_id character varying(6),
    int_liq_source_type character varying(1),
    allocation_avg_price numeric(12,6),
    account_nickname character varying(40),
    load_batch_id bigint,
    clearing_account_id integer,
    market_participant_id character varying(18),
    alternative_compliance_id character varying(256),
    clearing_fee_amout numeric(16,4),
    street_trade_record_time timestamp without time zone,
    penny_nickel character(1)
);


ALTER TABLE dwh.flat_trade_record_old OWNER TO dwh;

--
-- Name: COLUMN flat_trade_record_old.trade_record_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_record_time IS 'Exec time from PARENT level EXECUTION';


--
-- Name: COLUMN flat_trade_record_old.date_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.date_id IS 'based on exec_time of the parent level order';


--
-- Name: COLUMN flat_trade_record_old.orig_trade_record_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.orig_trade_record_id IS 'If we split trade we bust the old one and create two or more new trades with old_trade_record_if in the orig_trade_record_id field';


--
-- Name: COLUMN flat_trade_record_old.trade_record_trans_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_record_trans_type IS 'Based on client_order.trans_type of the parent level order';


--
-- Name: COLUMN flat_trade_record_old.trade_record_reason; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_record_reason IS 'Initially based on STRATEGY_DECISION_REASON_CODE field of the parent level of client_order record';


--
-- Name: COLUMN flat_trade_record_old.subsystem_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.subsystem_id IS 'Based on client_order.SUB_SYSTEM_ID of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.user_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.user_id IS 'Based on client_order.user_id of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.account_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.account_id IS 'Based on client_order.account_id of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.client_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.client_order_id IS 'client_order_id of the parent level record';


--
-- Name: COLUMN flat_trade_record_old.instrument_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.instrument_id IS 'Based on client_order.instrument_id of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.side; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.side IS 'Side of the parent level order';


--
-- Name: COLUMN flat_trade_record_old.open_close; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.open_close IS 'Based on client_order.open_close of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.fix_connection_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.fix_connection_id IS 'Fix_connection_id of the parent level order. Base on cl.fix_connection_id';


--
-- Name: COLUMN flat_trade_record_old.exec_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.exec_id IS 'Exec ID of the parent level trade';


--
-- Name: COLUMN flat_trade_record_old.exchange_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.exchange_id IS 'Base on execution.EXCHANGE_ID of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.trade_liquidity_indicator; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_liquidity_indicator IS 'Based on execution.TRADE_LIQUIDITY_INDICATOR of the parent order trade';


--
-- Name: COLUMN flat_trade_record_old.secondary_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.secondary_order_id IS 'Based on execution.SECONDARY_ORDER_ID of the parent order trade. Means street client_order_id???';


--
-- Name: COLUMN flat_trade_record_old.exch_exec_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.exch_exec_id IS 'Based on execution.exch_exec_id of the parent order trade. Means exec_id that arrives form the exchange';


--
-- Name: COLUMN flat_trade_record_old.secondary_exch_exec_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.secondary_exch_exec_id IS 'Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange';


--
-- Name: COLUMN flat_trade_record_old.last_mkt; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.last_mkt IS 'Based on execution.last_mkt of the parent order trade.';


--
-- Name: COLUMN flat_trade_record_old.last_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.last_qty IS 'Based on execution.last_qty of the parent order trade. Means quantity';


--
-- Name: COLUMN flat_trade_record_old.last_px; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.last_px IS 'Based on execution.last_px of the parent order trade. Means price';


--
-- Name: COLUMN flat_trade_record_old.ex_destination; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.ex_destination IS 'Based on client_order.ex_destination of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.sub_strategy; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.sub_strategy IS 'Based on client_order.sub_strategy of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.street_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_order_id IS 'street order_id str.order_id';


--
-- Name: COLUMN flat_trade_record_old.order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.order_id IS 'parent order ID cl.order_id';


--
-- Name: COLUMN flat_trade_record_old.street_order_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_order_qty IS 'order_qty arrives from STREET level of client_order table';


--
-- Name: COLUMN flat_trade_record_old.order_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.order_qty IS 'order_qty arrives from PARENT level of client_order table';


--
-- Name: COLUMN flat_trade_record_old.multileg_reporting_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.multileg_reporting_type IS 'MULTILEG_REPORTING_TYPE arrives from PARENT level of client_order table';


--
-- Name: COLUMN flat_trade_record_old.is_largest_leg; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.is_largest_leg IS 'by default ''N'' ';


--
-- Name: COLUMN flat_trade_record_old.street_max_floor; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_max_floor IS 'MAX_FLOOR field of the STREET level client order';


--
-- Name: COLUMN flat_trade_record_old.exec_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.exec_broker IS 'based on  street client_order.opt_exec_broker ';


--
-- Name: COLUMN flat_trade_record_old.cmta; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.cmta IS 'Based on client_order.Clearing_firm_id of he parent level order. if it is empty we use 439 fix message if still empty we use  clearing_account.CMTA';


--
-- Name: COLUMN flat_trade_record_old.street_time_in_force; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_time_in_force IS 'Based on client_order.TIME_IN_FORCE of the strret level order';


--
-- Name: COLUMN flat_trade_record_old.street_order_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_order_type IS 'Based on client_order.ORDER_TYPE of the strret level order';


--
-- Name: COLUMN flat_trade_record_old.opt_customer_firm; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.opt_customer_firm IS 'Based on client_order.OPT_CUSTOMER_FIRM of the parent level order';


--
-- Name: COLUMN flat_trade_record_old.street_mpid; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_mpid IS 'Based on client_order.MPID of the strret level order';


--
-- Name: COLUMN flat_trade_record_old.is_cross_order; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.is_cross_order IS 'N if cross_order_id of the parent level order is null and Y in other case';


--
-- Name: COLUMN flat_trade_record_old.street_is_cross_order; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_is_cross_order IS 'N if cross_order_id of the street level order is null and Y in other case';


--
-- Name: COLUMN flat_trade_record_old.street_cross_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_cross_type IS 'CROSS_TYPE of the street level order';


--
-- Name: COLUMN flat_trade_record_old.cross_is_originator; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.cross_is_originator IS 'Based on the IS_ORIGINATOR of the PARENT level client_order';


--
-- Name: COLUMN flat_trade_record_old.street_cross_is_originator; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_cross_is_originator IS 'Based on the IS_ORIGINATOR of the STREET level client_order';


--
-- Name: COLUMN flat_trade_record_old.contra_account; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.contra_account IS 'Based on the CONTRA_ACCOUNT_CAPACITY field of the PARENT level exection';


--
-- Name: COLUMN flat_trade_record_old.contra_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.contra_broker IS 'Based on the CONTRA_BROKER field of the PARENT level exection';


--
-- Name: COLUMN flat_trade_record_old.trade_exec_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_exec_broker IS 'based on execution.exec_broker';


--
-- Name: COLUMN flat_trade_record_old.order_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.order_fix_message_id IS 'Based on the fix_message_id field of the PARENT level client_order';


--
-- Name: COLUMN flat_trade_record_old.trade_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_fix_message_id IS 'Based on the fix_message_id field of the PARENT level EXECUTION';


--
-- Name: COLUMN flat_trade_record_old.street_order_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_order_fix_message_id IS 'Based on the fix_message_id field of the STREET level of client_order table';


--
-- Name: COLUMN flat_trade_record_old.bid_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.bid_price IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_price)';


--
-- Name: COLUMN flat_trade_record_old.ask_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.ask_price IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_price)';


--
-- Name: COLUMN flat_trade_record_old.trade_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_id IS 'A-la FK to market_data.trade.trade_id';


--
-- Name: COLUMN flat_trade_record_old.client_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.client_id IS 'Based on the client_id field of the PARENT level client_order';


--
-- Name: COLUMN flat_trade_record_old.street_transaction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_transaction_id IS 'client_order.transaction_id of the street level';


--
-- Name: COLUMN flat_trade_record_old.transaction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.transaction_id IS 'client_order.transaction_id of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.tcce_account_dash_commission_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_account_dash_commission_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_account_execution_cost; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_account_execution_cost IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_firm_dash_commission_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_firm_dash_commission_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_firm_execution_cost; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_firm_execution_cost IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_mss_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_mss_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_maker_taker_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_maker_taker_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_occ_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_occ_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_option_regulatory_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_option_regulatory_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_royalty_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_royalty_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_sec_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_sec_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_transaction_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_transaction_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.tcce_trade_processing_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_trade_processing_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';


--
-- Name: COLUMN flat_trade_record_old.order_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.order_price IS 'Based on client_order.PRICE of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.order_process_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.order_process_time IS 'Based on client_order.PROCESS_TIME of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.ask_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.ask_qty IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_qty)';


--
-- Name: COLUMN flat_trade_record_old.bid_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.bid_qty IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_qty)';


--
-- Name: COLUMN flat_trade_record_old.is_billed; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.is_billed IS 'Value indicates if trade is billed, not billed or prepared for recalculation. ''Y'', ''N'', ''R'', ''D''. ''E'' - TCCE error';


--
-- Name: COLUMN flat_trade_record_old.street_exec_inst; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_exec_inst IS 'based on EXEC_INST of the street level order';


--
-- Name: COLUMN flat_trade_record_old.leaves_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.leaves_qty IS 'Based on the LEAVES_QTY field of the PARENT level EXECUTION';


--
-- Name: COLUMN flat_trade_record_old.fee_sensitivity; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.fee_sensitivity IS 'Fee sencitivity of the parent level execution. Arrives from the 9090 fix message tag';


--
-- Name: COLUMN flat_trade_record_old.street_order_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_order_price IS 'arrives from client_order.price of street order level';


--
-- Name: COLUMN flat_trade_record_old.routing_time_bid_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.routing_time_bid_price IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record_old.routing_time_bid_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.routing_time_bid_qty IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record_old.routing_time_ask_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.routing_time_ask_price IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record_old.routing_time_ask_qty; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.routing_time_ask_qty IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';


--
-- Name: COLUMN flat_trade_record_old.is_street_order_marketable; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.is_street_order_marketable IS 'Y/N ';


--
-- Name: COLUMN flat_trade_record_old.tcce_admin_maker_taker_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_admin_maker_taker_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table AMTK book_record_type_id';


--
-- Name: COLUMN flat_trade_record_old.tcce_admin_transaction_fee_amount; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.tcce_admin_transaction_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table ATF book_record_type_id';


--
-- Name: COLUMN flat_trade_record_old.strategy_decision_reason_code; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.strategy_decision_reason_code IS 'Routing reason. Based on strategy_decision_reason_code of the strret order. Parent order field is used in case street order value is null';


--
-- Name: COLUMN flat_trade_record_old.compliance_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.compliance_id IS 'Based on client_order.compliance_id of the parent level order';


--
-- Name: COLUMN flat_trade_record_old.auction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.auction_id IS 'AUCTION_ID based on execution.AUCTION_ID of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.street_exec_broker; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_exec_broker IS 'Exec Broker of street level order. Based on tag value provided in d_exchange';


--
-- Name: COLUMN flat_trade_record_old.multileg_order_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.multileg_order_id IS 'The vaule is based on CO_MULTILEG_ORDER_ID of the parent order';


--
-- Name: COLUMN flat_trade_record_old.floor_broker_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.floor_broker_id IS 'Tag 143 of the customer order. Assigned value used to identify specific message destination''s location (i.e. geographic location and/or desk, trader)';


--
-- Name: COLUMN flat_trade_record_old.street_opt_customer_firm; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_opt_customer_firm IS 'Customer_or_firm id fo the street order level. Arrives from tag 47 or tag 204';


--
-- Name: COLUMN flat_trade_record_old.internal_component_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.internal_component_type IS 'INTERNAL_COMPONENT_TYPE of the parent execution level';


--
-- Name: COLUMN flat_trade_record_old.instrument_type_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN flat_trade_record_old.street_trade_fix_message_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_trade_fix_message_id IS 'Fix message ID of street trade';


--
-- Name: COLUMN flat_trade_record_old.pt_basket_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.pt_basket_id IS 'Basket_id of the parent order. Base on 9047 tag of parent order fix message';


--
-- Name: COLUMN flat_trade_record_old.transact_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.transact_time IS 'Based on Tag 60 of the execution report';


--
-- Name: COLUMN flat_trade_record_old.trade_exchange_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_exchange_id IS 'exhcnage_id of the venue where trade was realy executed. The field is null when trade executed on the same exchenage_id as routed ';


--
-- Name: COLUMN flat_trade_record_old.trading_firm_unq_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trading_firm_unq_id IS 'FK to d_trading_firm';


--
-- Name: COLUMN flat_trade_record_old.client_commission_rate; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.client_commission_rate IS 'Client commission rate per unit. Customer uses to charge its client';


--
-- Name: COLUMN flat_trade_record_old.blaze_account_alias; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.blaze_account_alias IS 'Base on EDWDilling..TOrder_EDW.AccountAlias. Filled for blaze traffic only';


--
-- Name: COLUMN flat_trade_record_old.street_account_name; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_account_name IS 'street_account_name based on Tag 1 of of street trade fix message. Arrives from genesis2.trade_record';


--
-- Name: COLUMN flat_trade_record_old.trade_text; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.trade_text IS 'Based on 58 tag of parent execution ';


--
-- Name: COLUMN flat_trade_record_old.branch_sequence_number; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.branch_sequence_number IS 'Based on 9861 tag of parent execution ';


--
-- Name: COLUMN flat_trade_record_old.frequent_trader_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.frequent_trader_id IS 'CBOE-specific field "FrequentTraderID" based on tag 21097 of the street trade message. Arrives from PG genesis2.trade_record';


--
-- Name: COLUMN flat_trade_record_old.int_liq_source_type; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.int_liq_source_type IS 'A - ATS, C - Consolidator';


--
-- Name: COLUMN flat_trade_record_old.allocation_avg_price; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.allocation_avg_price IS 'Avarenge price of allocated trades';


--
-- Name: COLUMN flat_trade_record_old.account_nickname; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.account_nickname IS 'account_nickname. should be populated from the dash360 as free text during allocation';


--
-- Name: COLUMN flat_trade_record_old.load_batch_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.load_batch_id IS 'The field for ETL purposes';


--
-- Name: COLUMN flat_trade_record_old.clearing_account_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.clearing_account_id IS 'FK to d_clearing_account';


--
-- Name: COLUMN flat_trade_record_old.market_participant_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.market_participant_id IS 'Tag 115 of the parent order. Based on client_order.MPID field of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.alternative_compliance_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.alternative_compliance_id IS 'Tag 6376 of the parent order. Based on client_order.ALTERNATIVE_COMPLIANCE_ID field of the parent order level';


--
-- Name: COLUMN flat_trade_record_old.clearing_fee_amout; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.clearing_fee_amout IS 'Based on trade_level Book record CLRF book_record_type';


--
-- Name: COLUMN flat_trade_record_old.street_trade_record_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.flat_trade_record_old.street_trade_record_time IS 'Exec time from street level EXECUTION';


--
-- Name: gtc_order_status; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.gtc_order_status (
    order_id bigint NOT NULL,
    create_date_id integer NOT NULL,
    order_status character(1),
    exec_time timestamp(6) without time zone,
    last_trade_date timestamp(0) without time zone,
    last_mod_date_id integer,
    is_parent boolean,
    close_date_id integer,
    account_id integer,
    time_in_force_id character(1) DEFAULT '1'::bpchar,
    db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    db_update_time timestamp without time zone,
    closing_reason character(1),
    client_order_id character varying(256),
    instrument_id bigint,
    multileg_reporting_type character(1)
)
PARTITION BY RANGE (close_date_id);


ALTER TABLE dwh.gtc_order_status OWNER TO dwh;

--
-- Name: COLUMN gtc_order_status.last_trade_date; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.gtc_order_status.last_trade_date IS 'It is last_trade_date from instrument for time_in_force_id = 1 or expire_time from client_order for time_in_force_id = 6';


--
-- Name: COLUMN gtc_order_status.account_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.gtc_order_status.account_id IS 'account_id from dwh.d_account';


--
-- Name: COLUMN gtc_order_status.time_in_force_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.gtc_order_status.time_in_force_id IS 'time_in_force_id - 1 for GTC, 6 - for GTD';


--
-- Name: COLUMN gtc_order_status.closing_reason; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.gtc_order_status.closing_reason IS '''the order was closed because of
E - by the execution flow (''2'', ''4'', ''8'')
P - by the parent flow (closed street because its parent was closed)
I - instrument or client order expire time
L - the one of closed leg has closed the head
H - the head closed before has closed all non closed legs
    ';


--
-- Name: v_client_order_today; Type: VIEW; Schema: dwh; Owner: vpylypets
--

CREATE VIEW dwh.v_client_order_today AS
 SELECT cl.order_id,
    cl.instrument_id,
    cl.option_contract_id,
    cl.account_id,
    cl.trading_firm_unq_id,
    cl.parent_order_id,
    cl.orig_order_id,
    cl.order_type_id,
    cl.time_in_force_id,
    cl.create_date_id,
    cl.exch_order_id,
    cl.osr_street_client_order_id,
    cl.client_order_id,
    cl.expire_time,
    cl.order_cancel_time,
    cl.create_time,
    cl.process_time,
    cl.side,
    cl.order_qty,
    cl.price,
    cl.stop_price,
    cl.max_show_qty,
    cl.trans_type,
    cl.multileg_reporting_type,
    cl.open_close,
    cl.dataset_id,
    cl.sub_strategy_id,
    cl.fix_connection_id,
    cl.fix_message_id,
    cl.occ_optional_data,
    cl.alias_ex_destination_id,
    cl.is_late_hours_order,
    cl.cancel_code,
    cl.order_class,
    cl.max_floor,
    cl.transaction_id,
    cl.sub_system_unq_id,
    cl.fee_sensitivity,
    cl.clearing_firm_id,
    cl.market_participant_id,
    cl.cross_order_id,
    cl.customer_or_firm_id,
    cl.mm_preference_code_id,
    cl.exchange_id,
    cl.eq_order_capacity,
    cl.opt_exec_broker_id,
    cl.strtg_decision_reason_code,
    cl.compliance_id,
    cl.exchange_unq_id,
    cl.ex_destination,
    cl.aggression_level,
    cl.pg_db_create_time,
    cl.exec_instruction,
    cl.quote_id,
    cl.step_up_price_type,
    cl.step_up_price,
    cl.cross_account_id,
    cl.multileg_order_id,
    cl.routing_table_id,
    cl.liquidity_provider_id,
    cl.internal_component_type,
    cl.no_legs,
    cl.clearing_account,
    cl.sub_account,
    cl.request_number,
    cl.pt_basket_id,
    cl.ratio_qty,
    cl.handl_inst,
    cl.sub_strategy_desc,
    cl.pt_order_id,
    cl.cons_payment_per_contract,
    cl.alternative_compliance_id,
    cl.is_originator,
    cl.internal_order_id,
    cl.extended_ord_type,
    cl.sweep_style,
    cl.co_client_leg_ref_id,
    cl.algo_start_time,
    cl.algo_end_time,
    cl.occ_customer_id,
    cl.locate_req,
    cl.locate_broker,
    cl.algo_stop_px,
    cl.algo_client_order_id,
    cl.dash_client_order_id,
    cl.tot_no_orders_in_transaction,
    cl.on_behalf_of_sub_id,
    cl.prim_listing_exchange,
    cl.posting_exchange,
    cl.pre_open_behavior,
    cl.max_wave_qty_pct,
    cl.discretion_offset,
    cl.hidden_flag,
    cl.conditional_client_order_id,
    cl.osr_customer_order_id,
    cl.osr_street_order_id,
    cl.session_eligibility,
    cl.co_routing_table_entry_id,
    cl.max_vega_per_strike,
    cl.per_strike_vega_exposure,
    cl.vega_behavior,
    cl.delta_behavior,
    cl.hedge_param_units,
    cl.min_delta,
    cl.product_description,
    cl.parent_order_process_time,
    cl.client_id_text,
    cl.dash_rfr_id,
    cl.routing_instr_side
   FROM dwh.client_order cl
  WHERE (cl.create_date_id = (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer)
UNION ALL
 SELECT cl.order_id,
    cl.instrument_id,
    cl.option_contract_id,
    cl.account_id,
    cl.trading_firm_unq_id,
    cl.parent_order_id,
    cl.orig_order_id,
    cl.order_type_id,
    cl.time_in_force_id,
    cl.create_date_id,
    cl.exch_order_id,
    cl.osr_street_client_order_id,
    cl.client_order_id,
    cl.expire_time,
    cl.order_cancel_time,
    cl.create_time,
    cl.process_time,
    cl.side,
    cl.order_qty,
    cl.price,
    cl.stop_price,
    cl.max_show_qty,
    cl.trans_type,
    cl.multileg_reporting_type,
    cl.open_close,
    cl.dataset_id,
    cl.sub_strategy_id,
    cl.fix_connection_id,
    cl.fix_message_id,
    cl.occ_optional_data,
    cl.alias_ex_destination_id,
    cl.is_late_hours_order,
    cl.cancel_code,
    cl.order_class,
    cl.max_floor,
    cl.transaction_id,
    cl.sub_system_unq_id,
    cl.fee_sensitivity,
    cl.clearing_firm_id,
    cl.market_participant_id,
    cl.cross_order_id,
    cl.customer_or_firm_id,
    cl.mm_preference_code_id,
    cl.exchange_id,
    cl.eq_order_capacity,
    cl.opt_exec_broker_id,
    cl.strtg_decision_reason_code,
    cl.compliance_id,
    cl.exchange_unq_id,
    cl.ex_destination,
    cl.aggression_level,
    cl.pg_db_create_time,
    cl.exec_instruction,
    cl.quote_id,
    cl.step_up_price_type,
    cl.step_up_price,
    cl.cross_account_id,
    cl.multileg_order_id,
    cl.routing_table_id,
    cl.liquidity_provider_id,
    cl.internal_component_type,
    cl.no_legs,
    cl.clearing_account,
    cl.sub_account,
    cl.request_number,
    cl.pt_basket_id,
    cl.ratio_qty,
    cl.handl_inst,
    cl.sub_strategy_desc,
    cl.pt_order_id,
    cl.cons_payment_per_contract,
    cl.alternative_compliance_id,
    cl.is_originator,
    cl.internal_order_id,
    cl.extended_ord_type,
    cl.sweep_style,
    cl.co_client_leg_ref_id,
    cl.algo_start_time,
    cl.algo_end_time,
    cl.occ_customer_id,
    cl.locate_req,
    cl.locate_broker,
    cl.algo_stop_px,
    cl.algo_client_order_id,
    cl.dash_client_order_id,
    cl.tot_no_orders_in_transaction,
    cl.on_behalf_of_sub_id,
    cl.prim_listing_exchange,
    cl.posting_exchange,
    cl.pre_open_behavior,
    cl.max_wave_qty_pct,
    cl.discretion_offset,
    cl.hidden_flag,
    cl.conditional_client_order_id,
    cl.osr_customer_order_id,
    cl.osr_street_order_id,
    cl.session_eligibility,
    cl.co_routing_table_entry_id,
    cl.max_vega_per_strike,
    cl.per_strike_vega_exposure,
    cl.vega_behavior,
    cl.delta_behavior,
    cl.hedge_param_units,
    cl.min_delta,
    cl.product_description,
    cl.parent_order_process_time,
    cl.client_id_text,
    cl.dash_rfr_id,
    cl.routing_instr_side
   FROM (dwh.gtc_order_status gt
     JOIN dwh.client_order cl ON (((gt.create_date_id = cl.create_date_id) AND (gt.order_id = cl.order_id))))
  WHERE (gt.close_date_id IS NULL);


ALTER VIEW dwh.v_client_order_today OWNER TO vpylypets;

--
-- Name: frt_alive_orders; Type: VIEW; Schema: dwh; Owner: vpylypets
--

CREATE VIEW dwh.frt_alive_orders AS
 SELECT co.order_id AS orderid,
    co.fix_connection_id AS fixconnectionid,
    cro.cross_id AS crossid,
    co.client_order_id AS clientorderid,
    co.parent_order_id AS parentorderid
   FROM ((dwh.v_client_order_today co
     JOIN dwh.d_time_in_force dtif ON ((co.time_in_force_id = dtif.tif_id)))
     LEFT JOIN dwh.cross_order cro ON ((co.cross_order_id = cro.cross_order_id)))
  WHERE ((co.multileg_reporting_type = ANY (ARRAY['1'::bpchar, '3'::bpchar])) AND dtif.is_active AND (co.time_in_force_id = ANY (ARRAY['1'::bpchar, '6'::bpchar, 'C'::bpchar, 'M'::bpchar])))
  ORDER BY co.order_id;


ALTER VIEW dwh.frt_alive_orders OWNER TO vpylypets;

--
-- Name: historic_oes_storage; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.historic_oes_storage (
    "OrderID" bigint NOT NULL,
    "ClOrdID" character varying(256),
    "InstrumentID" bigint,
    "Symbol" character varying(10),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "OPRASymbol" character varying(30),
    "DisplayInstrumentID" character varying(256),
    "TransactTime" timestamp(3) without time zone,
    "Side" character varying(1),
    "OrderQty" integer,
    "MarketParticipantID" character varying(4),
    "LeavesQty" integer,
    "CumQty" integer,
    "AvgPx" numeric,
    "AccountID" integer,
    "MultilegReportingType" character varying(1),
    "OpenClose" character varying(1),
    "ExDestination" character varying(5),
    "ClearingFirmID" character varying(9),
    "ExecBroker" character varying(32),
    "FixCompID" character varying(30),
    "ClientID" character varying(256),
    "SubStrategy" character varying(256),
    "PrincipalAmount" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "CommissionScheduleRateType" character varying(1),
    "AccDashCommissionAmount" numeric(20,6),
    "AccExecutionCost" numeric(20,6),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "CustomerOrderID" bigint,
    "UnderlyingDisplayInstrID" character varying(100),
    "AliasExDestination" character varying(5),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "AliasAccExecutionCost" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "DashClOrdID" character varying(128),
    "CrossOrderID" bigint,
    "StatusDate" date NOT NULL,
    "CustomerOrFirm" character varying(1),
    "OCCOptionalData" character varying(128),
    "MSSFeeAmount" numeric(20,6),
    "FeeSensitivity" smallint,
    "FirmCommissionScheduleRateType" character varying(1),
    "ExtendedOrdType" character varying(1),
    "SweepStyle" character varying(1),
    "CrossType" character varying(1),
    "HiddenFlag" character varying(1),
    "AggressionLevel" smallint,
    "DiscretionOffset" numeric(12,4),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "QuoteID" character varying(256),
    "StepUpPriceType" character(1),
    "StepUpPrice" numeric(12,4),
    "SessionEligibility" character varying(1),
    "CreateDateID" integer
)
PARTITION BY RANGE ("Status_Date_id");


ALTER TABLE dwh.historic_oes_storage OWNER TO dwh;

SET default_tablespace = arch_data;

--
-- Name: historic_oes_storage_old; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.historic_oes_storage_old (
    "OrderID" bigint NOT NULL,
    "ClOrdID" character varying(256),
    "InstrumentID" bigint,
    "Symbol" character varying(10),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "OPRASymbol" character varying(30),
    "DisplayInstrumentID" character varying(256),
    "TransactTime" timestamp without time zone,
    "Side" character varying(1),
    "OrderQty" bigint,
    "MarketParticipantID" character varying(4),
    "LeavesQty" bigint,
    "CumQty" bigint,
    "AvgPx" numeric,
    "AccountID" integer,
    "MultilegReportingType" character varying(1),
    "OpenClose" character varying(1),
    "ExDestination" character varying(5),
    "ClearingFirmID" character varying(9),
    "ExecBroker" character varying(32),
    "FixCompID" character varying(30),
    "ClientID" character varying(256),
    "SubStrategy" character varying(256),
    "PrincipalAmount" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "CommissionScheduleRateType" character varying(1),
    "AccDashCommissionAmount" numeric(20,6),
    "AccExecutionCost" numeric(20,6),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "CustomerOrderID" bigint,
    "UnderlyingDisplayInstrID" character varying(100),
    "AliasExDestination" character varying(5),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "AliasAccExecutionCost" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "DashClOrdID" character varying(128),
    "CrossOrderID" bigint,
    "StatusDate" date NOT NULL,
    "CustomerOrFirm" character varying(1),
    "OCCOptionalData" character varying(128),
    "MSSFeeAmount" numeric(20,6),
    "FeeSensitivity" smallint,
    "FirmCommissionScheduleRateType" character varying(1),
    "StreetCustomerOrFirm" character(1),
    "StreetExecBroker" character varying(5),
    "StreetClearingFirm" character varying(3),
    "StreetAccount" character varying(10),
    "ExtendedOrdType" character(1),
    "SweepStyle" character(1),
    "DiscretionOffset" numeric(12,4),
    "CrossType" character(1),
    "AggressionLevel" smallint,
    "HiddenFlag" character(1),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "StepUpPriceType" character(1),
    "StepUpPrice" numeric(12,4),
    "QuoteID" character varying(256),
    "SessionEligibility" character varying(1),
    "CreateDateID" integer
);


ALTER TABLE dwh.historic_oes_storage_old OWNER TO dwh;

--
-- Name: COLUMN historic_oes_storage_old."AuctionID"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_oes_storage_old."AuctionID" IS 'Unique reference number assigned to the auction.';


--
-- Name: COLUMN historic_oes_storage_old."StepUpPriceType"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_oes_storage_old."StepUpPriceType" IS 'Specifies the step-up price type.
Supported values: 1 - Market, 2 - Limit.';


--
-- Name: COLUMN historic_oes_storage_old."StepUpPrice"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_oes_storage_old."StepUpPrice" IS 'Specifies the step-up price. Required if StepUpPriceType = 2 (Limit).';


--
-- Name: COLUMN historic_oes_storage_old."QuoteID"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_oes_storage_old."QuoteID" IS 'Unique reference number assigned to the quote at the liquidity provider''s side. ';


--
-- Name: COLUMN historic_oes_storage_old."SessionEligibility"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_oes_storage_old."SessionEligibility" IS ' ''R'' (Participate in RTH only)
''A'' (Participate in GTH, RTH and Curb)
''G'' (Participate in GTH only)
''D'' (Participate in GTH and RTH)
''F'' (Participate in RTH and Curb)
''C'' (Participate in Curb only)';


--
-- Name: COLUMN historic_oes_storage_old."CreateDateID"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_oes_storage_old."CreateDateID" IS 'Date of order creation time converted to int acording to GTH rules';


--
-- Name: historic_oes_storage_rt; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.historic_oes_storage_rt (
    "OrderID" bigint NOT NULL,
    "ClOrdID" character varying(256),
    "InstrumentID" bigint,
    "Symbol" character varying(10),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "OPRASymbol" character varying(30),
    "DisplayInstrumentID" character varying(256),
    "TransactTime" timestamp without time zone,
    "Side" character varying(1),
    "OrderQty" bigint,
    "MarketParticipantID" character varying(4),
    "LeavesQty" bigint,
    "CumQty" bigint,
    "AvgPx" numeric(12,4),
    "AccountID" integer,
    "MultilegReportingType" character varying(1),
    "OpenClose" character varying(1),
    "ExDestination" character varying(5),
    "ClearingFirmID" character varying(9),
    "ExecBroker" character varying(32),
    "FixCompID" character varying(30),
    "ClientID" character varying(256),
    "SubStrategy" character varying(256),
    "PrincipalAmount" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "CommissionScheduleRateType" character varying(1),
    "AccDashCommissionAmount" numeric(20,6),
    "AccExecutionCost" numeric(20,6),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "CustomerOrderID" bigint,
    "UnderlyingDisplayInstrID" character varying(100),
    "AliasExDestination" character varying(5),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "AliasAccExecutionCost" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "DashClOrdID" character varying(128),
    "CrossOrderID" bigint,
    "StatusDate" date NOT NULL,
    "CustomerOrFirm" character varying(1),
    "OCCOptionalData" character varying(128),
    "MSSFeeAmount" numeric(20,6),
    "FeeSensitivity" smallint,
    "FirmCommissionScheduleRateType" character varying(1),
    "StreetCustomerOrFirm" character(1),
    "StreetExecBroker" character varying(5),
    "StreetClearingFirm" character varying(3),
    "StreetAccount" character varying(10),
    "ExtendedOrdType" character(1),
    "SweepStyle" character(1),
    "DiscretionOffset" numeric(12,4),
    "CrossType" character(1),
    "AggressionLevel" smallint,
    "HiddenFlag" character(1),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "StepUpPriceType" character(1),
    "StepUpPrice" numeric(12,4),
    "QuoteID" character varying(256),
    "SessionEligibility" character varying(1),
    "CreateDateID" integer
);


ALTER TABLE dwh.historic_oes_storage_rt OWNER TO dwh;

SET default_tablespace = '';

--
-- Name: historic_order_details_storage; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.historic_order_details_storage (
    "OrderID" bigint NOT NULL,
    "ClOrdID" character varying(256),
    "OrigClOrdID" character varying(256),
    "ExecID" bigint,
    "RefExecID" bigint,
    "Symbol" character varying(10),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "DisplayInstrumentID" character varying(256),
    "TransactTime" timestamp(3) without time zone,
    "OrderType" character varying(1),
    "OrderClass" character varying(1),
    "Side" character varying(1),
    "OrderQty" integer,
    "Price" numeric(12,4),
    "StopPx" numeric(12,4),
    "TimeInForce" character varying(1),
    "ExpireTime" timestamp(3) without time zone,
    "HandlInst" character varying(1),
    "OpenClose" character varying(1),
    "ExecInst" character varying(128),
    "MaxShowQty" integer,
    "MaxFloorQty" integer,
    "ClearingFirmID" character varying(9),
    "ExecBroker" character varying(32),
    "MarketParticipantID" character varying(4),
    "CustomerOrFirm" character varying(1),
    "OrderCapacity" character varying(1),
    "IsLocateRequired" character varying(1),
    "LocateBroker" character varying(20),
    "ExecType" character varying(1),
    "OrderStatus" character varying(1),
    "RejectReason" character varying(512),
    "LeavesQty" integer,
    "CumQty" integer,
    "AvgPx" numeric,
    "LastQty" integer,
    "LastPx" numeric,
    "LastMkt" character varying(5),
    "StreetExDestination" character varying(5),
    "DayOrderQty" integer,
    "DayCumQty" integer,
    "DayAvgPx" numeric,
    "AccountID" integer,
    "MultilegReportingType" character varying(1),
    "LegRefID" character varying(30),
    "TradeLiquidityIndicator" character varying(256),
    "CustomerOrderID" bigint,
    "FixCompID" character varying(30),
    "ClientID" character varying(255),
    "Text" character varying(512),
    "RoutedTime" timestamp(6) without time zone,
    "ExchExecID" character varying(128),
    "OrderFixMsgID" bigint,
    "ExecFixMsgID" bigint,
    "MultilegOrderID" bigint,
    "InstrumentID" bigint,
    "LogTime" timestamp(3) without time zone,
    "RouteReason" character varying(128),
    "IsOSROrder" character varying(1),
    "OSROrderID" bigint,
    "OPRASymbol" character varying(30),
    "OrderCreationTime" timestamp(3) without time zone,
    "SubStrategy" character varying(256),
    "UnderlyingDisplayInstrID" character varying(256),
    "AlgoClOrdID" character varying(256),
    "AliasExDestination" character varying(5),
    "AlgoStopPx" numeric(12,4),
    "DashClOrdID" character varying(128),
    "StatusDate" date NOT NULL,
    "OCCOptionalData" character varying(128),
    "ExDestination" character varying(5),
    "SubSystemID" character varying(20),
    "TransactionID" bigint,
    "TotNoOrdersInTransaction" integer,
    "ExchangeID" character varying(6),
    "FeeSensitivity" smallint,
    "OnBehalfOfSubID" character varying(256),
    "StrategyDecisionReasonCode" smallint,
    "InternalOrderID" bigint,
    "CrossOrderID" bigint,
    "AlgoStartTime" timestamp(3) with time zone,
    "AlgoEndTime" timestamp(3) with time zone,
    "MinTargetQty" bigint,
    "ExtendedOrdType" character(1),
    "PrimListingExchange" character varying(5),
    "PostingExchange" character varying(5),
    "PreOpenBehavior" character(1),
    "MaxWaveQtyPct" smallint,
    "SweepStyle" character(1),
    "DiscretionOffset" numeric(12,4),
    "CrossType" character(1),
    "AggressionLevel" smallint,
    "HiddenFlag" character(1),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "QuoteID" character varying(256),
    "StepUpPriceType" character(1),
    "StepUpPrice" numeric(12,4),
    "CrossAccountID" integer,
    "ClearingAccount" character varying(256),
    "SubAccount" character varying(256),
    "RequestNumber" integer,
    "LiquidityProviderID" character varying(9),
    "InternalComponentType" character(1),
    "ComplianceID" character varying(256),
    "AlternativeComplianceID" character varying(256),
    "ConditionalClientOrderID" character varying(256),
    "IsConditionalOrder" character(1) DEFAULT 'N'::bpchar,
    "MaxVegaPerStrike" numeric(13,0),
    "PerStrikeVegaExposure" character(1),
    "VegaBehavior" numeric(1,0),
    "DeltaBehavior" character(1),
    "HedgeParamUnits" character(1),
    "MinDelta" numeric(13,0),
    "RoutingTableEntryID" bigint,
    "SymbolSfx" character varying(10),
    "FixCompID2" character varying(30),
    "ProductDescription" character varying(256),
    "SessionEligibility" character varying(1),
    "CreateDateID" integer,
    "OptwapBinNumber" integer,
    "OptwapPhase" character varying(30),
    "OptwapOrderPrice" numeric(12,4),
    "OptwapBinDuration" integer,
    "OptwapBinQty" integer,
    "OptwapPhaseDuration" integer
)
PARTITION BY RANGE ("Status_Date_id");


ALTER TABLE dwh.historic_order_details_storage OWNER TO dwh;

SET default_tablespace = arch_data;

--
-- Name: historic_order_details_storage_old; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.historic_order_details_storage_old (
    "OrderID" bigint NOT NULL,
    "ClOrdID" character varying(256),
    "OrigClOrdID" character varying(256),
    "ExecID" bigint,
    "RefExecID" bigint,
    "Symbol" character varying(10),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "DisplayInstrumentID" character varying(256),
    "TransactTime" timestamp(3) without time zone,
    "OrderType" character varying(1),
    "OrderClass" character varying(1),
    "Side" character varying(1),
    "OrderQty" bigint,
    "Price" numeric(12,4),
    "StopPx" numeric(12,4),
    "TimeInForce" character varying(1),
    "ExpireTime" timestamp(3) without time zone,
    "HandlInst" character varying(1),
    "OpenClose" character varying(1),
    "ExecInst" character varying(128),
    "MaxShowQty" bigint,
    "MaxFloorQty" bigint,
    "ClearingFirmID" character varying(9),
    "ExecBroker" character varying(32),
    "MarketParticipantID" character varying(4),
    "CustomerOrFirm" character varying(1),
    "OrderCapacity" character varying(1),
    "IsLocateRequired" character varying(1),
    "LocateBroker" character varying(20),
    "ExecType" character varying(1),
    "OrderStatus" character varying(1),
    "RejectReason" character varying(512),
    "LeavesQty" bigint,
    "CumQty" bigint,
    "AvgPx" numeric,
    "LastQty" bigint,
    "LastPx" numeric,
    "LastMkt" character varying(5),
    "StreetExDestination" character varying(5),
    "DayOrderQty" bigint,
    "DayCumQty" bigint,
    "DayAvgPx" numeric,
    "AccountID" integer,
    "MultilegReportingType" character varying(1),
    "LegRefID" character varying(30),
    "TradeLiquidityIndicator" character varying(256),
    "CustomerOrderID" bigint,
    "FixCompID" character varying(30),
    "ClientID" character varying(255),
    "Text" character varying(512),
    "RoutedTime" timestamp(6) without time zone,
    "ExchExecID" character varying(128),
    "OrderFixMsgID" bigint,
    "ExecFixMsgID" bigint,
    "MultilegOrderID" bigint,
    "InstrumentID" bigint,
    "LogTime" timestamp(3) without time zone,
    "RouteReason" character varying(128),
    "IsOSROrder" character varying(1),
    "OSROrderID" bigint,
    "OPRASymbol" character varying(30),
    "OrderCreationTime" timestamp(3) without time zone,
    "SubStrategy" character varying(256),
    "UnderlyingDisplayInstrID" character varying(256),
    "AlgoClOrdID" character varying(256),
    "AliasExDestination" character varying(5),
    "AlgoStopPx" numeric(12,4),
    "DashClOrdID" character varying(128),
    "StatusDate" date NOT NULL,
    "OCCOptionalData" character varying(128),
    "ExDestination" character varying(5),
    "SubSystemID" character varying(20),
    "TransactionID" bigint,
    "TotNoOrdersInTransaction" integer,
    "ExchangeID" character varying(6),
    "FeeSensitivity" smallint,
    "OnBehalfOfSubID" character varying(256),
    "StrategyDecisionReasonCode" smallint,
    "InternalOrderID" bigint,
    "CrossOrderID" bigint,
    "AlgoStartTime" timestamp without time zone,
    "AlgoEndTime" timestamp without time zone,
    "MinTargetQty" bigint,
    "ExtendedOrdType" character(1),
    "PrimListingExchange" character varying(5),
    "PostingExchange" character varying(5),
    "PreOpenBehavior" character(1),
    "MaxWaveQtyPct" smallint,
    "SweepStyle" character(1),
    "DiscretionOffset" numeric(12,4),
    "CrossType" character(1),
    "AggressionLevel" smallint,
    "HiddenFlag" character(1),
    "Status_Date_id" integer NOT NULL,
    "AuctionID" bigint,
    "QuoteID" character varying(256),
    "StepUpPriceType" character(1),
    "StepUpPrice" numeric(12,4),
    "CrossAccountID" integer,
    "ConditionalClientOrderID" character varying(256),
    "IsConditionalOrder" character(1),
    "MaxVegaPerStrike" numeric(13,0),
    "PerStrikeVegaExposure" character(1),
    "VegaBehavior" numeric(1,0),
    "DeltaBehavior" character(1),
    "HedgeParamUnits" character(1),
    "MinDelta" numeric(13,0),
    "RoutingTableEntryID" bigint,
    "SymbolSfx" character varying(10),
    "FixCompID2" character varying(30),
    "ProductDescription" character varying(256),
    "SessionEligibility" character varying(1),
    "CreateDateID" integer,
    "AlternativeComplianceID" character varying(256),
    "ComplianceID" character varying(256),
    "ClearingAccount" character varying(256),
    "SubAccount" character varying(256),
    "RequestNumber" integer,
    "LiquidityProviderID" character varying(9),
    "InternalComponentType" character(1)
);


ALTER TABLE dwh.historic_order_details_storage_old OWNER TO dwh;

--
-- Name: COLUMN historic_order_details_storage_old."AuctionID"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_order_details_storage_old."AuctionID" IS 'Unique reference number assigned to the auction.';


--
-- Name: COLUMN historic_order_details_storage_old."QuoteID"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_order_details_storage_old."QuoteID" IS 'Unique reference number assigned to the quote at the liquidity provider''s side. ';


--
-- Name: COLUMN historic_order_details_storage_old."StepUpPriceType"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_order_details_storage_old."StepUpPriceType" IS 'Specifies the step-up price type.
Supported values: 1 - Market, 2 - Limit.';


--
-- Name: COLUMN historic_order_details_storage_old."StepUpPrice"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_order_details_storage_old."StepUpPrice" IS 'Specifies the step-up price. Required if StepUpPriceType = 2 (Limit).';


--
-- Name: historic_order_details_storage_rt; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.historic_order_details_storage_rt (
    "OrderID" bigint NOT NULL,
    "ClOrdID" character varying(256),
    "OrigClOrdID" character varying(256),
    "ExecID" bigint,
    "RefExecID" bigint,
    "Symbol" character varying(10),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "DisplayInstrumentID" character varying(256),
    "TransactTime" timestamp without time zone,
    "OrderType" character varying(1),
    "OrderClass" character varying(1),
    "Side" character varying(1),
    "OrderQty" bigint,
    "Price" numeric(12,4),
    "StopPx" numeric(12,4),
    "TimeInForce" character varying(1),
    "ExpireTime" timestamp without time zone,
    "HandlInst" character varying(1),
    "OpenClose" character varying(1),
    "ExecInst" character varying(128),
    "MaxShowQty" bigint,
    "MaxFloorQty" bigint,
    "ClearingFirmID" character varying(9),
    "ExecBroker" character varying(32),
    "MarketParticipantID" character varying(4),
    "CustomerOrFirm" character varying(1),
    "OrderCapacity" character varying(1),
    "IsLocateRequired" character varying(1),
    "LocateBroker" character varying(20),
    "ExecType" character varying(1),
    "OrderStatus" character varying(1),
    "RejectReason" character varying(512),
    "LeavesQty" bigint,
    "CumQty" bigint,
    "AvgPx" numeric(12,4),
    "LastQty" bigint,
    "LastPx" numeric(12,4),
    "LastMkt" character varying(5),
    "StreetExDestination" character varying(5),
    "DayOrderQty" bigint,
    "DayCumQty" bigint,
    "DayAvgPx" numeric(12,4),
    "AccountID" integer,
    "MultilegReportingType" character varying(1),
    "LegRefID" character varying(30),
    "TradeLiquidityIndicator" character varying(256),
    "CustomerOrderID" bigint,
    "FixCompID" character varying(30),
    "ClientID" character varying(255),
    "Text" character varying(512),
    "RoutedTime" timestamp(6) without time zone,
    "ExchExecID" character varying(128),
    "OrderFixMsgID" bigint,
    "ExecFixMsgID" bigint,
    "MultilegOrderID" bigint,
    "InstrumentID" bigint,
    "LogTime" timestamp without time zone,
    "RouteReason" character varying(128),
    "IsOSROrder" character varying(1),
    "OSROrderID" bigint,
    "OPRASymbol" character varying(30),
    "OrderCreationTime" timestamp without time zone,
    "SubStrategy" character varying(256),
    "UnderlyingDisplayInstrID" character varying(256),
    "AlgoClOrdID" character varying(256),
    "AliasExDestination" character varying(5),
    "AlgoStopPx" numeric(12,4),
    "DashClOrdID" character varying(128),
    "StatusDate" date NOT NULL,
    "OCCOptionalData" character varying(128),
    "ExDestination" character varying(5),
    "SubSystemID" character varying(20),
    "TransactionID" bigint,
    "TotNoOrdersInTransaction" integer,
    "ExchangeID" character varying(6),
    "FeeSensitivity" smallint,
    "OnBehalfOfSubID" character varying(256),
    "StrategyDecisionReasonCode" smallint,
    "InternalOrderID" bigint,
    "CrossOrderID" bigint,
    "AlgoStartTime" timestamp without time zone,
    "AlgoEndTime" timestamp without time zone,
    "MinTargetQty" bigint,
    "ExtendedOrdType" character(1),
    "PrimListingExchange" character varying(5),
    "PostingExchange" character varying(5),
    "PreOpenBehavior" character(1),
    "MaxWaveQtyPct" smallint,
    "SweepStyle" character(1),
    "DiscretionOffset" numeric(12,4),
    "CrossType" character(1),
    "AggressionLevel" smallint,
    "HiddenFlag" character(1),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "QuoteID" character varying(256),
    "StepUpPriceType" character(1),
    "StepUpPrice" numeric(12,4),
    "CrossAccountID" integer,
    "ConditionalClientOrderID" character varying(256),
    "IsConditionalOrder" character(1),
    "MaxVegaPerStrike" numeric(13,0),
    "PerStrikeVegaExposure" character(1),
    "VegaBehavior" numeric(1,0),
    "DeltaBehavior" character(1),
    "HedgeParamUnits" character(1),
    "MinDelta" numeric(13,0),
    "RoutingTableEntryID" bigint,
    "SymbolSfx" character varying(10),
    "FixCompID2" character varying(30),
    "ProductDescription" character varying(256),
    "SessionEligibility" character varying(1),
    "CreateDateID" integer
);


ALTER TABLE dwh.historic_order_details_storage_rt OWNER TO dwh;

--
-- Name: historic_security_definition; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.historic_security_definition AS
 SELECT i.instrument_id,
    i.symbol,
    i.instrument_type_id,
    u.symbol AS underlying_symbol,
    oc.maturity_year,
    oc.maturity_month,
    oc.maturity_day,
    oc.put_call,
    oc.strike_price AS strike_px,
    oc.opra_symbol,
    os.contract_multiplier,
    i.instrument_name,
    i.display_instrument_id,
    u.display_instrument_id AS underlying_display_instrument_id,
    to_date((((((oc.maturity_year * 10000) + (oc.maturity_month * 100)) + oc.maturity_day))::character varying)::text, 'YYYYMMDD'::text) AS maturity_date
   FROM (((dwh.d_instrument i
     LEFT JOIN dwh.d_option_contract oc ON ((i.instrument_id = oc.instrument_id)))
     LEFT JOIN dwh.d_option_series os ON ((oc.option_series_id = os.option_series_id)))
     LEFT JOIN dwh.d_instrument u ON ((os.underlying_instrument_id = u.instrument_id)))
  WHERE ((i.instrument_type_id = ANY (ARRAY['E'::bpchar, 'O'::bpchar])) AND i.is_active);


ALTER VIEW dwh.historic_security_definition OWNER TO dwh;

--
-- Name: historic_security_definition_all; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.historic_security_definition_all AS
 SELECT i.instrument_id,
    i.symbol,
    i.instrument_type_id,
    u.symbol AS underlying_symbol,
    oc.maturity_year,
    oc.maturity_month,
    oc.maturity_day,
    oc.put_call,
    oc.strike_price AS strike_px,
    oc.opra_symbol,
    os.contract_multiplier,
    i.instrument_name,
    i.display_instrument_id,
    u.display_instrument_id AS underlying_display_instrument_id,
    to_date((((((oc.maturity_year * 10000) + (oc.maturity_month * 100)) + oc.maturity_day))::character varying)::text, 'YYYYMMDD'::text) AS maturity_date,
    i.activ_symbol
   FROM (((dwh.d_instrument i
     LEFT JOIN dwh.d_option_contract oc ON ((i.instrument_id = oc.instrument_id)))
     LEFT JOIN dwh.d_option_series os ON ((oc.option_series_id = os.option_series_id)))
     LEFT JOIN dwh.d_instrument u ON ((os.underlying_instrument_id = u.instrument_id)))
  WHERE (i.instrument_type_id = ANY (ARRAY['E'::bpchar, 'O'::bpchar]));


ALTER VIEW dwh.historic_security_definition_all OWNER TO dwh;

SET default_tablespace = '';

--
-- Name: historic_trade_details_storage; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.historic_trade_details_storage (
    "OrderID" bigint,
    "ExecID" bigint NOT NULL,
    "RefExecID" bigint,
    "TransactTime" timestamp(3) without time zone,
    "ExecType" character varying(1),
    "LeavesQty" integer,
    "CumQty" integer,
    "AvgPx" numeric,
    "LastQty" integer,
    "LastPx" numeric,
    "LastMkt" character varying(5),
    "TradeLiquidityIndicator" character varying(256),
    "Text" character varying(512),
    "ExchExecID" character varying(256),
    "PrincipalAmount" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "AccountDashCommissionAmount" numeric(20,6),
    "AccountExecutionCost" numeric(20,6),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "AliasLastMkt" character varying(5),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "AliasAccountExecutionCost" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "StatusDate" date NOT NULL,
    "MSSFeeAmount" numeric(20,6),
    "SecondaryOrderID" character varying(256),
    "CommissionScheduleRateType" character varying(1),
    "FirmCommissionScheduleRateType" character varying(1),
    "ExchangeID" character varying(6),
    "StreetCustomerOrFirm" character varying(1),
    "StreetExecBroker" character varying(5),
    "StreetClearingFirm" character varying(3),
    "StreetAccount" character varying(256),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "TradeDateID" integer
)
PARTITION BY RANGE ("Status_Date_id");


ALTER TABLE dwh.historic_trade_details_storage OWNER TO dwh;

SET default_tablespace = arch_data;

--
-- Name: historic_trade_details_storage_old; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.historic_trade_details_storage_old (
    "OrderID" bigint,
    "ExecID" bigint NOT NULL,
    "RefExecID" bigint,
    "TransactTime" timestamp(3) without time zone,
    "ExecType" character varying(1),
    "LeavesQty" bigint,
    "CumQty" bigint,
    "AvgPx" numeric,
    "LastQty" bigint,
    "LastPx" numeric,
    "LastMkt" character varying(5),
    "TradeLiquidityIndicator" character varying(256),
    "Text" character varying(512),
    "ExchExecID" character varying(256),
    "PrincipalAmount" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "AccountDashCommissionAmount" numeric(20,6),
    "AccountExecutionCost" numeric(20,6),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "AliasLastMkt" character varying(5),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "AliasAccountExecutionCost" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "StatusDate" date NOT NULL,
    "MSSFeeAmount" numeric(20,6),
    "SecondaryOrderID" character varying(256),
    "CommissionScheduleRateType" character varying(1),
    "FirmCommissionScheduleRateType" character varying(1),
    "ExchangeID" character varying(6),
    "StreetCustomerOrFirm" character varying(1),
    "StreetExecBroker" character varying(5),
    "StreetClearingFirm" character varying(3),
    "StreetAccount" character varying(256),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "TradeDateID" integer
);


ALTER TABLE dwh.historic_trade_details_storage_old OWNER TO dwh;

--
-- Name: COLUMN historic_trade_details_storage_old."AuctionID"; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.historic_trade_details_storage_old."AuctionID" IS 'Unique reference number assigned to the auction.';


--
-- Name: historic_trade_details_storage_rt; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.historic_trade_details_storage_rt (
    "OrderID" bigint,
    "ExecID" bigint NOT NULL,
    "RefExecID" bigint,
    "TransactTime" timestamp(3) without time zone,
    "ExecType" character varying(1),
    "LeavesQty" bigint,
    "CumQty" bigint,
    "AvgPx" numeric(12,4),
    "LastQty" bigint,
    "LastPx" numeric(12,4),
    "LastMkt" character varying(5),
    "TradeLiquidityIndicator" character varying(256),
    "Text" character varying(512),
    "ExchExecID" character varying(256),
    "PrincipalAmount" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "AccountDashCommissionAmount" numeric(20,6),
    "AccountExecutionCost" numeric(20,6),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "AliasLastMkt" character varying(5),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "AliasAccountExecutionCost" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "StatusDate" date NOT NULL,
    "MSSFeeAmount" numeric(20,6),
    "SecondaryOrderID" character varying(256),
    "CommissionScheduleRateType" character varying(1),
    "FirmCommissionScheduleRateType" character varying(1),
    "ExchangeID" character varying(6),
    "StreetCustomerOrFirm" character varying(1),
    "StreetExecBroker" character varying(5),
    "StreetClearingFirm" character varying(3),
    "StreetAccount" character varying(256),
    "Status_Date_id" integer,
    "AuctionID" bigint,
    "TradeDateID" integer
);


ALTER TABLE dwh.historic_trade_details_storage_rt OWNER TO dwh;

--
-- Name: sq_l1_snapshot_id; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_l1_snapshot_id
    START WITH 0
    INCREMENT BY -1
    MINVALUE -9223372036854775807
    MAXVALUE 0
    CACHE 50;


ALTER SEQUENCE dwh.sq_l1_snapshot_id OWNER TO dwh;

SET default_tablespace = '';

--
-- Name: l1_snapshot; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l1_snapshot (
    l1_snapshot_id bigint DEFAULT nextval('dwh.sq_l1_snapshot_id'::regclass) NOT NULL,
    start_date_id integer NOT NULL,
    transaction_id bigint NOT NULL,
    exchange_id character varying(6),
    instrument_id integer,
    bid_price numeric(12,4),
    ask_price numeric(12,4),
    bid_quantity bigint,
    ask_quantity bigint,
    dataset_id integer,
    transaction_time timestamp without time zone,
    pg_big_data_create_time timestamp(6) without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (start_date_id);


ALTER TABLE dwh.l1_snapshot OWNER TO dwh;

--
-- Name: COLUMN l1_snapshot.l1_snapshot_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot.l1_snapshot_id IS 'PK based on Oracle field as min of two side records ';


--
-- Name: COLUMN l1_snapshot.transaction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot.transaction_id IS 'positive values for DASH traffic and negative value for LP traffic ';


--
-- Name: COLUMN l1_snapshot.exchange_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot.exchange_id IS 'NBBO for l1_scope =''N'' and exchange_id from l1_scope =''E'' ';


--
-- Name: COLUMN l1_snapshot.instrument_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot.instrument_id IS 'FK to D_INSTRUMENT ';


--
-- Name: COLUMN l1_snapshot.dataset_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot.dataset_id IS 'ETL needs ';


--
-- Name: l1_snapshot_606; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l1_snapshot_606 (
    start_date_id integer,
    transaction_id bigint NOT NULL,
    exchange_id character varying(6),
    instrument_id integer,
    bid_price numeric(12,4),
    ask_price numeric(12,4),
    bid_quantity bigint,
    ask_quantity bigint,
    dataset_id integer,
    transaction_time timestamp without time zone,
    pg_big_data_create_time timestamp(6) without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (start_date_id);


ALTER TABLE dwh.l1_snapshot_606 OWNER TO dwh;

--
-- Name: COLUMN l1_snapshot_606.transaction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot_606.transaction_id IS 'positive values for DASH traffic and negative value for LP traffic ';


--
-- Name: COLUMN l1_snapshot_606.exchange_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot_606.exchange_id IS 'NBBO for l1_scope =''N'' and exchange_id from l1_scope =''E'' ';


--
-- Name: COLUMN l1_snapshot_606.instrument_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot_606.instrument_id IS 'FK to D_INSTRUMENT ';


--
-- Name: COLUMN l1_snapshot_606.dataset_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.l1_snapshot_606.dataset_id IS 'ETL needs ';


--
-- Name: l_crd_number; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l_crd_number (
    max text
);


ALTER TABLE dwh.l_crd_number OWNER TO dwh;

--
-- Name: l_date_id; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l_date_id (
    min integer
);


ALTER TABLE dwh.l_date_id OWNER TO dwh;

--
-- Name: l_date_ids; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l_date_ids (
    "?column?" text
);


ALTER TABLE dwh.l_date_ids OWNER TO dwh;

--
-- Name: l_file_name; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l_file_name (
    roe character varying(128)
);


ALTER TABLE dwh.l_file_name OWNER TO dwh;

--
-- Name: l_max_tca_trade_record_id; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l_max_tca_trade_record_id (
    max bigint
);


ALTER TABLE dwh.l_max_tca_trade_record_id OWNER TO dwh;

--
-- Name: l_start_date_id; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.l_start_date_id (
    "coalesce" text
);


ALTER TABLE dwh.l_start_date_id OWNER TO dwh;

--
-- Name: msg_json; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.msg_json (
    msg_id bigint NOT NULL,
    date_id integer NOT NULL,
    msg json
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh.msg_json OWNER TO dwh;

--
-- Name: msg_json_msg_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.msg_json_msg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.msg_json_msg_id_seq OWNER TO dwh;

--
-- Name: msg_json_msg_id_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.msg_json_msg_id_seq OWNED BY dwh.msg_json.msg_id;


--
-- Name: msg_json_20180102; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.msg_json_20180102 (
    msg_id bigint DEFAULT nextval('dwh.msg_json_msg_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    msg json
);


ALTER TABLE dwh.msg_json_20180102 OWNER TO dwh;

--
-- Name: msg_json_20180103; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.msg_json_20180103 (
    msg_id bigint DEFAULT nextval('dwh.msg_json_msg_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    msg json
);


ALTER TABLE dwh.msg_json_20180103 OWNER TO dwh;

--
-- Name: mv_active_account_snapshot; Type: MATERIALIZED VIEW; Schema: dwh; Owner: dwh
--

CREATE MATERIALIZED VIEW dwh.mv_active_account_snapshot AS
 SELECT account_id,
    account_name,
    trading_firm_unq_id,
    eq_mpid,
    eq_order_capacity,
    eq_commission,
    eq_commission_type,
    eq_is_validate_short_stock,
    opt_penny_commission,
    opt_nickel_commission,
    drop_copy_enabled,
    opt_customer_or_firm,
    opt_is_fix_execbrok_processed,
    account_demo_mnemonic,
    trading_firm_id,
    date_start,
    date_end,
    is_active,
    opt_is_fix_clfirm_processed,
    opt_is_fix_custfirm_processed,
    first_trade_date,
    last_trade_date,
    account_class_id,
    broker_dealer_mpid,
    is_finra_member,
    crd_number,
    oats_account_type_code,
    oats_report_on_behalf_of,
    oats_suppress_nw,
    oats_use_custom_order_id,
    opt_report_to_mpid,
    client_dtc_number,
    nscc_commission_enabled,
    nscc_sec_fee_enabled,
    nscc_mpid,
    account_holder_type,
    cat_fdid,
    cat_report_on_behalf_of,
    cat_suppress,
    is_auto_allocate,
    is_option_auto_allocate,
    account_algo_alias,
    is_broker_dealer,
    eq_executing_service,
    opt_is_dark_pool_eligible,
    is_clearing_enabled,
    max_day_order_value,
    is_risk_management_enabled,
    is_locked,
    locked_time,
    eq_report_to_mpid,
    opt_executing_service,
    is_specific_allocated,
    eq_reporting_avgpx_precision,
    opt_is_baml_dma_eligible,
    opt_avg_px_account,
    eq_avg_px_account,
    eq_real_time_report_to_mpid,
    eq_nasdaq_act_drop,
    settlement_period,
    use_new_model,
    opt_occ_id
   FROM dwh.d_account ac
  WHERE (true AND is_active)
  WITH NO DATA;


ALTER MATERIALIZED VIEW dwh.mv_active_account_snapshot OWNER TO dwh;

--
-- Name: mytab; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.mytab (
    num integer,
    description text,
    modcnt integer
);


ALTER TABLE dwh.mytab OWNER TO dwh;

--
-- Name: non_directed_orders_606; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.non_directed_orders_606 (
    order_id bigint
)
WITH (autovacuum_enabled='true', autovacuum_vacuum_scale_factor='2');


ALTER TABLE dwh.non_directed_orders_606 OWNER TO dwh;

--
-- Name: order_algo_parameters; Type: TABLE; Schema: dwh; Owner: vpylypets
--

CREATE TABLE dwh.order_algo_parameters (
    order_id bigint NOT NULL,
    algo_parameters jsonb NOT NULL,
    date_id integer NOT NULL,
    pg_big_data_create_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    source character varying
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh.order_algo_parameters OWNER TO vpylypets;

--
-- Name: order_algo_parameters_old; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.order_algo_parameters_old (
    order_id bigint NOT NULL,
    algo_parameters jsonb NOT NULL,
    date_id integer NOT NULL,
    pg_big_data_create_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    source character varying
);


ALTER TABLE dwh.order_algo_parameters_old OWNER TO dwh;

SET default_tablespace = arch_data;

--
-- Name: order_allocation_info_storage; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: arch_data
--

CREATE TABLE dwh.order_allocation_info_storage (
    "TradeDate" date NOT NULL,
    "BundleID" bigint,
    "OrderID" bigint NOT NULL,
    "MultilegReportingType" character varying(1),
    "MultilegOrderID" bigint,
    "Side" character varying(1),
    "AccountID" integer,
    "InstrumentID" bigint,
    "DayCumQty" bigint,
    "DayAvgPx" numeric(12,4),
    "AllocQty" bigint,
    "Symbol" character varying(10),
    "OPRASymbol" character varying(21),
    "InstrumentType" character varying(1),
    "MaturityYear" smallint,
    "MaturityMonth" smallint,
    "MaturityDay" smallint,
    "PutCall" character varying(1),
    "StrikePx" numeric(12,4),
    "DisplayInstrumentID" character varying(256),
    "OpenClose" character varying(1),
    "IsPartOfOrderChain" character varying(1),
    "AllocUserName" character varying(30),
    "TransactTime" timestamp(3) without time zone,
    "PrincipalAmount" numeric(20,6),
    "AccDashCommissionAmount" numeric(20,6),
    "AccExecutionCost" numeric(20,6),
    "MakerTakerFeeAmount" numeric(20,6),
    "TransactionFeeAmount" numeric(20,6),
    "TradeProcessingFeeAmount" numeric(20,6),
    "RoyaltyFeeAmount" numeric(20,6),
    "SECFeeAmount" numeric(20,6),
    "OptionRegulatoryFeeAmount" numeric(20,6),
    "OCCFeeAmount" numeric(20,6),
    "NetMoneyAmount" numeric(20,6),
    "AccMiscFeeNameID1" character varying(6),
    "AccMiscFeeNameID2" character varying(6),
    "AccMiscFeeNameID3" character varying(6),
    "AccMiscFeeNameID4" character varying(6),
    "AccMiscFeeNameID5" character varying(6),
    "AccMiscFeeDisplayName1" character varying(256),
    "AccMiscFeeDisplayName2" character varying(256),
    "AccMiscFeeDisplayName3" character varying(256),
    "AccMiscFeeDisplayName4" character varying(256),
    "AccMiscFeeDisplayName5" character varying(256),
    "AccMiscFeeAmount1" numeric(20,6),
    "AccMiscFeeAmount2" numeric(20,6),
    "AccMiscFeeAmount3" numeric(20,6),
    "AccMiscFeeAmount5" numeric(20,6),
    "AccMiscFeeAmount4" numeric(20,6),
    "AccCommissionScheduleRateType" character varying(1),
    "FirmDashCommissionAmount" numeric(20,6),
    "FirmExecutionCost" numeric(20,6),
    "FirmMiscFeeNameID1" character varying(6),
    "FirmMiscFeeNameID2" character varying(6),
    "FirmMiscFeeNameID3" character varying(6),
    "FirmMiscFeeNameID4" character varying(6),
    "FirmMiscFeeNameID5" character varying(6),
    "FirmMiscFeeDisplayName1" character varying(256),
    "FirmMiscFeeDisplayName2" character varying(256),
    "FirmMiscFeeDisplayName3" character varying(256),
    "FirmMiscFeeDisplayName4" character varying(256),
    "FirmMiscFeeDisplayName5" character varying(256),
    "FirmMiscFeeAmount1" numeric(20,6),
    "FirmMiscFeeAmount2" numeric(20,6),
    "FirmMiscFeeAmount3" numeric(20,6),
    "FirmMiscFeeAmount4" numeric(20,6),
    "FirmMiscFeeAmount5" numeric(20,6),
    "AliasFirmExecutionCost" numeric(20,6),
    "AliasAccExecutionCost" numeric(20,6),
    "AliasMakerTakerFeeAmount" numeric(20,6),
    "AliasTransactionFeeAmount" numeric(20,6),
    "AliasTradeProcessingFeeAmount" numeric(20,6),
    "AliasRoyaltyFeeAmount" numeric(20,6),
    "FirmCommissionScheduleRateType" character varying(1),
    "Text" character varying(256),
    "MSSFeeAmount" numeric(20,6),
    "ClearingFirmID" character varying(9),
    "ExecBroker" character varying(32),
    "ComplianceID" character varying(256),
    "Trade_Date_id" integer
);


ALTER TABLE dwh.order_allocation_info_storage OWNER TO dwh;

SET default_tablespace = '';

--
-- Name: order_tca_performance; Type: TABLE; Schema: tca; Owner: dwh
--

CREATE TABLE tca.order_tca_performance (
    parent_order_id bigint,
    date_id integer,
    account_id integer,
    activ_symbol character varying(30),
    avg_px numeric(20,6),
    vwap numeric(20,6),
    limit_adj_vwap numeric(20,6),
    market_price numeric(20,6),
    exec_qty bigint,
    tca_time timestamp without time zone DEFAULT now(),
    last_trade_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (date_id);


ALTER TABLE tca.order_tca_performance OWNER TO dwh;

--
-- Name: order_tca_performance_201809; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.order_tca_performance_201809 (
    parent_order_id bigint NOT NULL,
    date_id integer NOT NULL,
    account_id integer,
    activ_symbol character varying(30),
    avg_px numeric(20,6),
    vwap numeric(20,6),
    limit_adj_vwap numeric(20,6),
    market_price numeric(20,6),
    exec_qty bigint,
    tca_time timestamp without time zone DEFAULT now() NOT NULL,
    last_trade_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.order_tca_performance_201809 OWNER TO dwh;

--
-- Name: order_tca_performance_201810; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.order_tca_performance_201810 (
    parent_order_id bigint NOT NULL,
    date_id integer NOT NULL,
    account_id integer,
    activ_symbol character varying(30),
    avg_px numeric(20,6),
    vwap numeric(20,6),
    limit_adj_vwap numeric(20,6),
    market_price numeric(20,6),
    exec_qty bigint,
    tca_time timestamp without time zone DEFAULT now() NOT NULL,
    last_trade_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.order_tca_performance_201810 OWNER TO dwh;

--
-- Name: order_tca_performance_201811; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.order_tca_performance_201811 (
    parent_order_id bigint NOT NULL,
    date_id integer NOT NULL,
    account_id integer,
    activ_symbol character varying(30),
    avg_px numeric(20,6),
    vwap numeric(20,6),
    limit_adj_vwap numeric(20,6),
    market_price numeric(20,6),
    exec_qty bigint,
    tca_time timestamp without time zone DEFAULT now() NOT NULL,
    last_trade_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.order_tca_performance_201811 OWNER TO dwh;

--
-- Name: order_tca_performance_201812; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.order_tca_performance_201812 (
    parent_order_id bigint NOT NULL,
    date_id integer NOT NULL,
    account_id integer,
    activ_symbol character varying(30),
    avg_px numeric(20,6),
    vwap numeric(20,6),
    limit_adj_vwap numeric(20,6),
    market_price numeric(20,6),
    exec_qty bigint,
    tca_time timestamp without time zone DEFAULT now() NOT NULL,
    last_trade_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.order_tca_performance_201812 OWNER TO dwh;

--
-- Name: order_tca_performance_after_2018; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.order_tca_performance_after_2018 (
    parent_order_id bigint NOT NULL,
    date_id integer NOT NULL,
    account_id integer,
    activ_symbol character varying(30),
    avg_px numeric(20,6),
    vwap numeric(20,6),
    limit_adj_vwap numeric(20,6),
    market_price numeric(20,6),
    exec_qty bigint,
    tca_time timestamp without time zone DEFAULT now() NOT NULL,
    last_trade_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.order_tca_performance_after_2018 OWNER TO dwh;

--
-- Name: order_tca_performance_before_2018; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.order_tca_performance_before_2018 (
    parent_order_id bigint NOT NULL,
    date_id integer NOT NULL,
    account_id integer,
    activ_symbol character varying(30),
    avg_px numeric(20,6),
    vwap numeric(20,6),
    limit_adj_vwap numeric(20,6),
    market_price numeric(20,6),
    exec_qty bigint,
    tca_time timestamp without time zone DEFAULT now() NOT NULL,
    last_trade_time timestamp without time zone,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.order_tca_performance_before_2018 OWNER TO dwh;

--
-- Name: pd_test_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.pd_test_seq
    START WITH 1
    INCREMENT BY 5
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.pd_test_seq OWNER TO dwh;

SET default_tablespace = ssd_ts;

--
-- Name: pfof_606_reporting; Type: TABLE; Schema: dwh; Owner: dwh; Tablespace: ssd_ts
--

CREATE TABLE dwh.pfof_606_reporting (
    trade_date_id integer,
    exchange_id character varying(128),
    volume integer,
    eligibility character varying(10),
    rebate numeric(14,6),
    total numeric(14,6),
    market_maker character varying(128),
    trade_record_id bigint,
    exchange_fee_type character varying(128),
    load_bach_id bigint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (trade_date_id);


ALTER TABLE dwh.pfof_606_reporting OWNER TO dwh;

SET default_tablespace = '';

--
-- Name: pfof_606_reporting_old; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.pfof_606_reporting_old (
    trade_date_id integer,
    exchange_id character varying(128),
    volume integer,
    eligibility character varying(10),
    rebate numeric(14,6),
    total numeric(14,6),
    market_maker character varying(128),
    trade_record_id bigint,
    exchange_fee_type character varying(128),
    load_bach_id bigint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE dwh.pfof_606_reporting_old OWNER TO dwh;

--
-- Name: pg_lp_dash_merge_606; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.pg_lp_dash_merge_606 (
    security character(1),
    exchange_id character varying(6),
    total numeric(20,4),
    non_dir numeric(20,4),
    market numeric(20,4),
    "limit" numeric(20,4),
    other numeric(20,4)
)
WITH (autovacuum_enabled='true', autovacuum_vacuum_scale_factor='2');


ALTER TABLE dwh.pg_lp_dash_merge_606 OWNER TO dwh;

--
-- Name: pg_lp_merge_606; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.pg_lp_merge_606 (
    security character(1),
    ex_destination character varying(6),
    total numeric(20,4),
    non_dir numeric(20,4),
    mkt numeric(20,4),
    lmt numeric(20,4),
    other numeric(20,4)
)
WITH (autovacuum_enabled='true', autovacuum_vacuum_scale_factor='2');


ALTER TABLE dwh.pg_lp_merge_606 OWNER TO dwh;

--
-- Name: sec_master_import; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.sec_master_import (
    sec_master_import_batch_id bigint NOT NULL,
    underlying_symbol character varying(10) NOT NULL,
    underlying_symbol_group character varying(1) NOT NULL,
    index_type character varying(1)
);


ALTER TABLE dwh.sec_master_import OWNER TO dwh;

--
-- Name: sec_master_import_batch; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.sec_master_import_batch (
    sec_master_import_batch_id bigint NOT NULL,
    status character varying(1) NOT NULL,
    reject_reason character varying,
    file_name character varying(256) NOT NULL,
    file_date date NOT NULL,
    create_time timestamp(0) without time zone NOT NULL
);


ALTER TABLE dwh.sec_master_import_batch OWNER TO dwh;

--
-- Name: security_tape_606; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.security_tape_606 AS
 SELECT instrument_id,
        CASE instrument_type_id
            WHEN 'E'::bpchar THEN
            CASE COALESCE(primary_exchange_id, 'NSDQE'::character varying)
                WHEN 'NYSE'::text THEN 'A'::text
                WHEN 'NSDQE'::text THEN 'C'::text
                ELSE 'B'::text
            END
            ELSE 'O'::text
        END AS security_tape
   FROM dwh.d_instrument i
  WHERE (instrument_type_id = ANY (ARRAY['E'::bpchar, 'O'::bpchar]));


ALTER VIEW dwh.security_tape_606 OWNER TO dwh;

--
-- Name: sms_hist_security_definition; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.sms_hist_security_definition (
    sms_hist_sec_def_id bigint NOT NULL,
    trade_date timestamp with time zone NOT NULL,
    instrument_id bigint,
    symbol character varying(10),
    instrument_type_id character(1),
    underlying_instrument_id bigint,
    maturity_year integer,
    maturity_month smallint,
    maturity_day smallint,
    put_call character(1),
    strike_price numeric(12,4),
    opra_symbol character varying(30),
    instrument_name character varying(255),
    display_instrument_id character varying(100),
    activ_symbol character varying(30),
    instr_class_id character varying(2),
    symbol_suffix character varying(10),
    trade_date_id integer
);


ALTER TABLE dwh.sms_hist_security_definition OWNER TO dwh;

--
-- Name: sq_acc_allowed_liquidity_provider; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_acc_allowed_liquidity_provider
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_acc_allowed_liquidity_provider OWNER TO dwh;

--
-- Name: sq_account2disallowed_exchange; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_account2disallowed_exchange
    START WITH 28252
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_account2disallowed_exchange OWNER TO dwh;

--
-- Name: sq_account2instrument_type; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_account2instrument_type
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_account2instrument_type OWNER TO dwh;

--
-- Name: sq_commission_setting; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_commission_setting
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_commission_setting OWNER TO dwh;

--
-- Name: sq_exchange; Type: SEQUENCE; Schema: dwh; Owner: dhw_admin
--

CREATE SEQUENCE dwh.sq_exchange
    START WITH 250
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_exchange OWNER TO dhw_admin;

--
-- Name: sq_exchange2customer_or_firm; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_exchange2customer_or_firm
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_exchange2customer_or_firm OWNER TO dwh;

--
-- Name: sq_odwh_market_data; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_odwh_market_data
    START WITH -1
    INCREMENT BY -1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_odwh_market_data OWNER TO dwh;

--
-- Name: sq_routing_table; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_routing_table
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_routing_table OWNER TO dwh;

--
-- Name: sq_sub_system; Type: SEQUENCE; Schema: dwh; Owner: dhw_admin
--

CREATE SEQUENCE dwh.sq_sub_system
    START WITH 1010
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_sub_system OWNER TO dhw_admin;

--
-- Name: sq_user2user; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.sq_user2user
    START WITH 28252
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.sq_user2user OWNER TO dwh;

--
-- Name: start_date; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.start_date (
    "?column?" timestamp without time zone
);


ALTER TABLE dwh.start_date OWNER TO dwh;

--
-- Name: strategy_in_l1_snapshot; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.strategy_in_l1_snapshot (
    strategy_in_l1_snp_id bigint NOT NULL,
    start_date_id integer,
    transaction_id bigint,
    exchange_id character varying(6),
    activ_symbol character varying(30),
    l1_scope character(1),
    side character(1),
    price numeric(12,4),
    quantity bigint
);


ALTER TABLE dwh.strategy_in_l1_snapshot OWNER TO dwh;

--
-- Name: strategy_transaction_output; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.strategy_transaction_output (
    transaction_id bigint NOT NULL,
    date_id integer NOT NULL,
    strategy_script_output text,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh.strategy_transaction_output OWNER TO dwh;

--
-- Name: COLUMN strategy_transaction_output.transaction_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.strategy_transaction_output.transaction_id IS 'Unique key and FK to strategy_in_l1_snapshot';


--
-- Name: COLUMN strategy_transaction_output.date_id; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.strategy_transaction_output.date_id IS 'date_id based on date of transaction';


--
-- Name: COLUMN strategy_transaction_output.db_create_time; Type: COMMENT; Schema: dwh; Owner: dwh
--

COMMENT ON COLUMN dwh.strategy_transaction_output.db_create_time IS 'time of record arrival to the DB';


--
-- Name: sy_trade; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.sy_trade (
    activ_symbol character varying(30),
    date_id integer,
    trade_time timestamp without time zone,
    trade_id numeric(24,0),
    action_type character varying(30),
    condition_code character varying(30),
    price double precision,
    quantity integer,
    ref_trade_id bigint,
    reporting_venue character varying(5),
    bid_price numeric(16,4),
    ask_price numeric(16,4),
    bid_quantity integer,
    ask_quantity integer,
    db_create_time timestamp(3) without time zone,
    implied_volatility numeric(8,4),
    instrument_type_id character varying(1)
);


ALTER TABLE dwh.sy_trade OWNER TO dwh;

--
-- Name: symbol2symbol_list; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.symbol2symbol_list (
    symbol2symbol_list_id bigint NOT NULL,
    symbol_list_id character varying(6),
    symbol character varying(10),
    symbol_suffix character varying(10),
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean DEFAULT true
);


ALTER TABLE dwh.symbol2symbol_list OWNER TO dwh;

--
-- Name: symbol_list2instrument_type; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.symbol_list2instrument_type (
    instrument_type_id character(1) NOT NULL,
    symbol_list_id character varying(6) NOT NULL,
    symbol_list_priority smallint NOT NULL
);


ALTER TABLE dwh.symbol_list2instrument_type OWNER TO dwh;

--
-- Name: temp_d_instrument; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.temp_d_instrument (
    instrument_id numeric(13,0) NOT NULL,
    instrument_type_id character(1),
    symbol character varying(10),
    display_instrument_id character varying(100),
    instrument_name character varying(255),
    is_trading_allowed character varying(1),
    last_trade_date timestamp(0) without time zone,
    activ_symbol character varying(30),
    symbol_suffix character varying(10),
    primary_exchange_id character varying(6),
    exegy_symbol character varying(30),
    is_active boolean,
    date_start timestamp(0) without time zone,
    date_end timestamp(0) without time zone
);


ALTER TABLE dwh.temp_d_instrument OWNER TO dwh;

--
-- Name: temp_test; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.temp_test (
    billing_year integer,
    billing_month integer,
    id bigint NOT NULL,
    trade_date timestamp without time zone,
    process_date timestamp without time zone,
    exchange character varying(50),
    exchange_code character varying(50),
    side smallint,
    oc character varying(20),
    quantity integer,
    order_quantity integer,
    price numeric(12,4),
    osym character varying(50),
    osi_symbol character varying(50),
    exp_year character varying(10),
    exp_month character varying(10),
    exp_day character varying(10),
    strk numeric(12,4),
    pc character varying(10),
    usym character varying(10),
    order_time timestamp without time zone,
    execution_time timestamp without time zone,
    account_type character varying(30),
    parent_order_id character varying(100),
    message_number character varying(50),
    client_id character varying(50),
    account_name character varying(50),
    execution_source character varying(50),
    occ_cust_acct character varying(50),
    occ_client_order_id character varying(50),
    cmta character varying(50),
    mnemonic character varying(50),
    mm_id character varying(50),
    pref_lp character varying(50),
    account_origin character varying(50),
    liquidity character varying(50),
    strategy character varying(50),
    routed character varying(50),
    exchange_access_fee numeric(12,4),
    away_market character varying(50),
    spread_indicator character(1),
    bd_flag character(1),
    prof_cust_flag character(1),
    order_type character varying(50),
    tif character varying(50),
    record_type character varying(50),
    deleted character(1) DEFAULT 'N'::bpchar,
    occid character varying(50),
    pass character(1)
);


ALTER TABLE dwh.temp_test OWNER TO dwh;

--
-- Name: tmtz_test; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.tmtz_test (
    test_tz timestamp with time zone DEFAULT now(),
    test_wtz timestamp without time zone DEFAULT now(),
    id integer
);


ALTER TABLE dwh.tmtz_test OWNER TO dwh;

--
-- Name: trade_record_v_historical; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.trade_record_v_historical AS
 SELECT ex.exec_time AS trade_record_time,
    ex.exec_date_id AS date_id,
    cl.trans_type AS trade_record_trans_type,
    cl.strtg_decision_reason_code AS trade_record_reason,
    dss.sub_system_id,
    cl.account_id,
    cl.client_order_id,
    cl.instrument_id,
    cl.side,
    cl.open_close,
    cl.fix_connection_id,
    cl.price AS order_price,
    str.price AS street_order_price,
    cl.process_time AS order_process_time,
    ex.exec_id,
    ex.exchange_id,
    ex.trade_liquidity_indicator,
    ex.secondary_order_id,
    ex.exch_exec_id,
    ex.secondary_exch_exec_id,
    ex.last_mkt,
    ex.last_qty,
    ex.last_px,
    cl.ex_destination,
    cl.sub_strategy_desc AS sub_strategy,
    str.order_id AS street_order_id,
    cl.order_id,
    str.order_qty AS street_order_qty,
    cl.order_qty,
    cl.multileg_reporting_type,
    str.max_floor AS street_max_floor,
        CASE
            WHEN (i.instrument_type_id = 'O'::bpchar) THEN
            CASE
                WHEN ((acc.opt_is_fix_execbrok_processed)::text = 'Y'::text) THEN COALESCE(COALESCE(cl_br.opt_exec_broker, public.get_message_tag_string_cross_multileg(cl.fix_message_id, 76, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
                CASE
                    WHEN (cl.cross_order_id IS NULL) THEN false
                    ELSE true
                END)), opx.opt_exec_broker)
                ELSE opx.opt_exec_broker
            END
            ELSE public.get_message_tag_string_cross_multileg(str.fix_message_id, 76, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
            CASE
                WHEN (str.cross_order_id IS NULL) THEN false
                ELSE true
            END)
        END AS exec_broker,
    lpad(
        CASE
            WHEN (i.instrument_type_id = 'O'::bpchar) THEN NULLIF((COALESCE(COALESCE(COALESCE(public.get_message_tag_string(ex.fix_message_id, 439, ex.exec_date_id), public.get_message_tag_string(str_ex.fix_message_id, 439, str_ex.exec_date_id)), ((str.clearing_firm_id)::text)::character varying), public.get_message_tag_string_cross_multileg(cl.fix_message_id, 439, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
            CASE
                WHEN (cl.cross_order_id IS NULL) THEN false
                ELSE true
            END)))::text, '949'::text)
            ELSE NULL::text
        END, 3, '0'::text) AS cmta,
    str.time_in_force_id AS street_time_in_force,
    str.order_type_id AS street_order_type,
    cl.customer_or_firm_id AS opt_customer_firm,
    ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) AS str_opt_customer_firm,
    str.market_participant_id AS street_mpid,
        CASE
            WHEN (cl.cross_order_id IS NULL) THEN 'N'::text
            ELSE 'Y'::text
        END AS is_cross_order,
        CASE
            WHEN (str.cross_order_id IS NULL) THEN 'N'::text
            ELSE 'Y'::text
        END AS street_is_cross_order,
    ( SELECT c.cross_type
           FROM dwh.cross_order c
          WHERE (c.cross_order_id = str.cross_order_id)) AS street_cross_type,
    cl.is_originator AS cross_is_originator,
    str.is_originator AS street_cross_is_originator,
    ex.contra_account_capacity AS contra_account,
    ex.contra_broker,
    ex.exec_broker AS trade_exec_broker,
    cl.fix_message_id AS order_fix_message_id,
    ex.fix_message_id AS trade_fix_message_id,
    str.fix_message_id AS street_order_fix_message_id,
    cl.client_id_text AS client_id,
    str.transaction_id AS street_transaction_id,
    cl.transaction_id,
    fc.fix_comp_id,
    str.client_order_id AS street_client_order_id,
    ex.leaves_qty,
    str.exec_instruction AS street_exec_inst,
    public.get_message_tag_string(ex.fix_message_id, 9090, ex.exec_date_id) AS fee_sensitivity,
    COALESCE(str.strtg_decision_reason_code, cl.strtg_decision_reason_code) AS strategy_decision_reason_code,
    cl.compliance_id,
    public.get_message_tag_string_cross_multileg(cl.fix_message_id, 143, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
        CASE
            WHEN (cl.cross_order_id IS NULL) THEN false
            ELSE true
        END) AS floor_broker_id,
    str2au.auction_id,
        CASE
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('AMEX'::character varying)::text, ('ARCE'::character varying)::text])) THEN
            CASE ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text))
                WHEN '3'::text THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 50, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('ISE'::character varying)::text, ('GEMINI'::character varying)::text, ('MCRY'::character varying)::text, ('MIAX'::character varying)::text, ('MPRL'::character varying)::text, ('PHLX'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['4'::text, '5'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('BATO'::character varying)::text, ('EDGO'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'N'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('C2OX'::character varying)::text, ('CBOE'::character varying)::text, ('CBOEEH'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'N'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 1462, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = 'BOX'::text) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'X'::text])) THEN NULL::text
                ELSE NULL::text
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('NSDQO'::character varying)::text, ('NQBXO'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'O'::text])) THEN (public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END))::text
                ELSE NULL::text
            END
            ELSE NULL::text
        END AS sub_account,
        CASE
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('AMEX'::character varying)::text, ('ARCE'::character varying)::text])) THEN
            CASE ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text))
                WHEN '3'::text THEN NULL::character varying
                ELSE cross_acc.account_name
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('BATO'::character varying)::text, ('EDGO'::character varying)::text])) THEN cross_acc.account_name
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('C2OX'::character varying)::text, ('CBOE'::character varying)::text, ('CBOEEH'::character varying)::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
            CASE
                WHEN (str.cross_order_id IS NULL) THEN false
                ELSE true
            END)
            WHEN ((ex.exchange_id)::text = 'BOX'::text) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'X'::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('ISE'::character varying)::text, ('GEMINI'::character varying)::text, ('MCRY'::character varying)::text, ('MIAX'::character varying)::text, ('MPRL'::character varying)::text, ('PHLX'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['4'::text, '5'::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            WHEN ((ex.exchange_id)::text = ANY (ARRAY[('NSDQO'::character varying)::text, ('NQBXO'::character varying)::text])) THEN
            CASE
                WHEN (ltrim(rtrim((COALESCE(str.eq_order_capacity, str.customer_or_firm_id))::text)) = ANY (ARRAY['M'::text, 'O'::text])) THEN public.get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
                CASE
                    WHEN (str.cross_order_id IS NULL) THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            ELSE NULL::character varying
        END AS clearing_account,
    cl.multileg_order_id,
    ex.internal_component_type,
    str_ex.fix_message_id AS str_trade_fix_message_id,
    cl.pt_basket_id,
    cl.pt_order_id,
    public.get_message_tag_string(str_ex.fix_message_id, 5049, str_ex.exec_date_id) AS str_cls_comp_id,
    COALESCE(public.get_message_tag_string(str_ex.fix_message_id, 1, str_ex.exec_date_id), public.get_message_tag_string_cross_multileg(str.fix_message_id, 1, str.create_date_id, (str.client_order_id)::text, (acc.account_name)::text, (str.co_client_leg_ref_id)::text,
        CASE
            WHEN (str.cross_order_id IS NULL) THEN false
            ELSE true
        END)) AS street_account_name,
    public.get_message_tag_string(str_ex.fix_message_id, 9861, str_ex.exec_date_id) AS branch_seq_num,
    str_ex.text_ AS trade_text,
    public.get_message_tag_string(str_ex.fix_message_id, 21097, str_ex.exec_date_id) AS frequent_trader_id,
    cl.time_in_force_id AS time_in_force,
    cl.internal_component_type AS int_liq_source_type,
    cl.market_participant_id AS mpid,
    cl.alternative_compliance_id,
    str_ex.exec_time AS street_trade_record_time,
    str.process_time AS street_order_process_time,
    cl.co_client_leg_ref_id,
    public.get_message_tag_string_cross_multileg(cl.fix_message_id, 10445, cl.create_date_id, (cl.client_order_id)::text, (acc.account_name)::text, (cl.co_client_leg_ref_id)::text,
        CASE
            WHEN (cl.cross_order_id IS NULL) THEN false
            ELSE true
        END) AS blaze_account_alias
   FROM ((((((((((((dwh.execution ex
     JOIN dwh.client_order cl ON (((ex.order_id = cl.order_id) AND (cl.multileg_reporting_type = ANY (ARRAY['1'::bpchar, '2'::bpchar])) AND (cl.parent_order_id IS NULL) AND (cl.trans_type <> 'F'::bpchar))))
     JOIN dwh.d_account acc ON ((cl.account_id = acc.account_id)))
     JOIN dwh.d_instrument i ON ((cl.instrument_id = i.instrument_id)))
     LEFT JOIN dwh.d_sub_system dss ON ((cl.sub_system_unq_id = dss.sub_system_unq_id)))
     LEFT JOIN dwh.client_order str ON ((((ex.secondary_order_id)::text = (str.client_order_id)::text) AND (str.parent_order_id = cl.order_id))))
     LEFT JOIN dwh.client_order2auction str2au ON (((str.order_id = str2au.order_id) AND (str.create_date_id = str2au.create_date_id))))
     LEFT JOIN dwh.d_account cross_acc ON ((str.cross_account_id = cross_acc.account_id)))
     LEFT JOIN dwh.execution str_ex ON ((((ex.secondary_exch_exec_id)::text = (str_ex.exch_exec_id)::text) AND (str_ex.order_id = str.order_id) AND (ex.exec_date_id = str_ex.exec_date_id))))
     LEFT JOIN dwh.d_opt_exec_broker opx ON (((cl.account_id = opx.account_id) AND opx.is_active AND ((opx.is_default)::text = 'Y'::text))))
     LEFT JOIN dwh.d_opt_exec_broker cl_br ON ((cl.opt_exec_broker_id = cl_br.opt_exec_broker_id)))
     LEFT JOIN dwh.d_opt_exec_broker str_br ON ((str_br.opt_exec_broker_id = opx.opt_exec_broker_id)))
     LEFT JOIN dwh.d_fix_connection fc ON ((fc.fix_connection_id = cl.fix_connection_id)))
  WHERE ((ex.is_busted <> 'Y'::bpchar) AND (ex.exec_type = 'F'::bpchar));


ALTER VIEW dwh.trade_record_v_historical OWNER TO dwh;

--
-- Name: trading_firm2routing_table; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.trading_firm2routing_table (
    trading_firm_unq_id integer NOT NULL,
    routing_table_unq_id integer NOT NULL,
    trading_firm_id character varying(9) NOT NULL,
    routing_table_id bigint NOT NULL,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    is_active boolean
);


ALTER TABLE dwh.trading_firm2routing_table OWNER TO dwh;

--
-- Name: user2account; Type: FOREIGN TABLE; Schema: staging; Owner: dwh
--

CREATE FOREIGN TABLE staging.user2account (
    user_role character(1),
    user_id bigint,
    account_id bigint,
    trading_firm_id character varying(9)
)
SERVER oracle_prod
OPTIONS (
    schema 'GENESIS2_QA_20100601',
    "table" 'USER2ACCOUNT'
);


ALTER FOREIGN TABLE staging.user2account OWNER TO dwh;

--
-- Name: user2account_mv; Type: MATERIALIZED VIEW; Schema: dwh; Owner: dwh
--

CREATE MATERIALIZED VIEW dwh.user2account_mv AS
 SELECT user_role,
    user_id,
    account_id,
    trading_firm_id
   FROM staging.user2account
  WITH NO DATA;


ALTER MATERIALIZED VIEW dwh.user2account_mv OWNER TO dwh;

--
-- Name: web_slow_orders; Type: VIEW; Schema: dwh; Owner: dwh
--

CREATE VIEW dwh.web_slow_orders AS
 SELECT ac.account_name,
    cl.client_order_id AS slow_parent_client_order_id,
    cls.client_order_id AS slow_child_client_order_id,
    cl.trans_type,
    substr(to_char((cls.process_time - cl.process_time), 'HH24:MI:SS.ff9'::text), 12) AS latency,
    to_char(cl.process_time, 'HH24:MI:SS.ff6'::text) AS parent_order_create_time,
    to_char(cls.process_time, 'HH24:MI:SS.ff6'::text) AS street_order_create_time,
    fc.fix_comp_id,
    dss.sub_system_id,
    cl.ex_destination,
    dts.target_strategy_name,
    cl.internal_order_id
   FROM (((((dwh.client_order cl
     JOIN LATERAL ( SELECT str.process_time,
            str.client_order_id
           FROM dwh.client_order str
          WHERE ((str.parent_order_id = cl.order_id) AND (str.create_date_id = cl.create_date_id))
          ORDER BY str.order_id
         LIMIT 1) cls ON (true))
     JOIN dwh.d_account ac ON ((cl.account_id = ac.account_id)))
     JOIN dwh.d_fix_connection fc ON ((fc.fix_connection_id = cl.fix_connection_id)))
     JOIN dwh.d_sub_system dss ON ((cl.sub_system_unq_id = dss.sub_system_unq_id)))
     JOIN dwh.d_target_strategy dts ON ((cl.sub_strategy_id = dts.target_strategy_id)))
  WHERE ((cl.create_date_id = public.get_dateid(public.get_business_date())) AND (cl.multileg_reporting_type = ANY (ARRAY['1'::bpchar, '2'::bpchar])) AND (cl.process_time > (now() - '01:40:00'::interval)) AND ((cls.process_time - cl.process_time) > ((0.1)::double precision * '00:00:01'::interval)))
  ORDER BY (cls.process_time - cl.process_time) DESC
 LIMIT 200;


ALTER VIEW dwh.web_slow_orders OWNER TO dwh;

--
-- Name: ytest; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.ytest (
    test_id bigint NOT NULL,
    transaction_id bigint NOT NULL,
    transaction_time timestamp without time zone
);


ALTER TABLE dwh.ytest OWNER TO dwh;

--
-- Name: ytest_date; Type: TABLE; Schema: dwh; Owner: dwh
--

CREATE TABLE dwh.ytest_date (
    idx integer NOT NULL,
    dt date
);


ALTER TABLE dwh.ytest_date OWNER TO dwh;

--
-- Name: ytest_date_idx_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.ytest_date_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.ytest_date_idx_seq OWNER TO dwh;

--
-- Name: ytest_date_idx_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: dwh
--

ALTER SEQUENCE dwh.ytest_date_idx_seq OWNED BY dwh.ytest_date.idx;


--
-- Name: ytest_id_seq; Type: SEQUENCE; Schema: dwh; Owner: dwh
--

CREATE SEQUENCE dwh.ytest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dwh.ytest_id_seq OWNER TO dwh;

--
-- Name: cancel_client_order; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.cancel_client_order (
    new_order_id bigint NOT NULL,
    order_id bigint NOT NULL,
    orig_create_date_id integer NOT NULL,
    create_time timestamp(3) with time zone,
    process_time timestamp(6) with time zone,
    trans_type character(1),
    exch_order_id character varying(128),
    client_order_id character varying(256),
    osr_street_client_order_id character varying(128),
    fix_message_id bigint,
    create_date_id integer NOT NULL,
    stg_db_create_time timestamp without time zone,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    is_processed boolean DEFAULT false,
    etl_proc_time timestamp without time zone
)
PARTITION BY RANGE (create_date_id);


ALTER TABLE dwh_new.cancel_client_order OWNER TO dwh;

--
-- Name: cancel_conditional_order; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.cancel_conditional_order (
    new_order_id bigint NOT NULL,
    order_id bigint NOT NULL,
    orig_create_date_id integer NOT NULL,
    create_time timestamp without time zone,
    process_time timestamp without time zone,
    trans_type character(1) NOT NULL,
    exch_order_id character varying(128),
    client_order_id character varying(256) NOT NULL,
    osr_street_client_order_id character varying(128),
    fix_message_id bigint,
    date_id integer NOT NULL,
    stg_db_create_time timestamp without time zone,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    is_processed boolean DEFAULT false,
    etl_proc_time timestamp without time zone
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.cancel_conditional_order OWNER TO dwh;

--
-- Name: cancel_cross_order; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.cancel_cross_order (
    new_cross_order_id bigint NOT NULL,
    cross_order_id bigint NOT NULL,
    orig_create_date_id integer NOT NULL,
    date_id integer NOT NULL,
    create_time timestamp(3) with time zone,
    process_time timestamp(6) with time zone,
    trans_type character(1),
    cross_id character varying(256),
    stg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    is_processed boolean DEFAULT false,
    etl_proc_time timestamp without time zone
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.cancel_cross_order OWNER TO dwh;

--
-- Name: client_order; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.client_order (
    order_id bigint NOT NULL,
    instrument_id bigint,
    option_contract_id bigint,
    account_id integer,
    trading_firm_unq_id integer,
    trading_firm_id character varying(9),
    parent_order_id bigint,
    orig_order_id bigint,
    order_type_id character(1),
    time_in_force_id character(1),
    ex_destination_code_id integer,
    create_date_id integer NOT NULL,
    exch_order_id character varying(128),
    osr_street_client_order_id character varying(128),
    client_order_id character varying(256),
    client_id_text character varying(255),
    expire_time timestamp(3) without time zone,
    order_cancel_time timestamp(3) without time zone,
    create_time timestamp(3) with time zone,
    process_time timestamp(6) with time zone,
    side character(1),
    order_qty integer,
    price numeric(12,4),
    stop_price numeric(12,4),
    max_show_qty integer,
    trans_type character(1),
    multileg_reporting_type character(1),
    open_close character(1),
    dataset_id integer,
    sub_strategy_id integer,
    fix_connection_id integer,
    fix_message_id bigint,
    occ_optional_data character varying(128),
    order_capacity_id character(1),
    alias_ex_destination_id integer,
    is_late_hours_order character(1),
    cancel_code smallint,
    order_class character(1),
    max_floor bigint,
    transaction_id bigint,
    sub_system_unq_id integer,
    fee_sensitivity smallint,
    clearing_firm_id character varying(3),
    market_participant_id character varying(18),
    cross_order_id bigint,
    customer_or_firm_id character(1),
    mm_preference_code_id integer,
    exchange_id character varying(6),
    eq_order_capacity character(1),
    opt_exec_broker_id integer,
    strtg_decision_reason_code smallint,
    compliance_id character varying(256),
    exchange_unq_id smallint,
    ex_destination character varying(5),
    aggression_level smallint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone,
    process_time_micsec character varying(6),
    process_time_unix numeric(20,4),
    exec_instruction character varying(128),
    quote_id character varying(256),
    step_up_price_type character(1),
    step_up_price numeric(12,4),
    cross_account_id integer,
    multileg_order_id bigint,
    routing_table_id integer,
    liquidity_provider_id character varying(9),
    internal_component_type character(1),
    no_legs integer,
    clearing_account character varying(256),
    sub_account character varying(256),
    request_number integer,
    pt_basket_id character varying(100),
    ratio_qty bigint,
    handl_inst character(1),
    sub_strategy_desc character varying(128),
    pt_order_id bigint,
    cons_payment_per_contract numeric(12,4),
    alternative_compliance_id character varying(256),
    is_originator character(1),
    internal_order_id bigint,
    extended_ord_type character(1),
    sweep_style character(1),
    co_client_leg_ref_id character varying(30),
    algo_start_time timestamp without time zone,
    algo_end_time timestamp without time zone,
    occ_customer_id character varying(128),
    locate_req character(1),
    locate_broker character varying(20),
    algo_stop_px numeric(12,4),
    algo_client_order_id character varying(128),
    dash_client_order_id character varying(128),
    tot_no_orders_in_transaction bigint,
    on_behalf_of_sub_id character varying(256),
    prim_listing_exchange character varying(5),
    posting_exchange character varying(5),
    pre_open_behavior character(1),
    max_wave_qty_pct bigint,
    discretion_offset numeric(12,4),
    hidden_flag character(1),
    conditional_client_order_id character varying(256),
    osr_customer_order_id bigint,
    osr_street_order_id bigint,
    session_eligibility character(1),
    co_routing_table_entry_id bigint,
    max_vega_per_strike bigint,
    per_strike_vega_exposure character(1),
    vega_behavior integer,
    delta_behavior character(1),
    hedge_param_units character(1),
    min_delta bigint,
    product_description character varying(256),
    parent_order_process_time timestamp without time zone,
    text character varying(256),
    consolidator_billing_type smallint,
    orig_account_id numeric(13,0),
    is_held character(1),
    dash_rfr_id character varying(256),
    routing_instr_side character(1),
    cons_spi_instr character(1),
    opt_customer_firm_street character(1)
)
PARTITION BY RANGE (create_date_id);


ALTER TABLE dwh_new.client_order OWNER TO dwh;

--
-- Name: client_order2auction; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.client_order2auction (
    order_id bigint NOT NULL,
    auction_id bigint NOT NULL,
    rfq_transact_time timestamp without time zone,
    create_date_id bigint NOT NULL,
    dataset_id bigint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone
)
PARTITION BY RANGE (create_date_id);


ALTER TABLE dwh_new.client_order2auction OWNER TO dwh;

--
-- Name: client_order_leg; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.client_order_leg (
    order_id bigint NOT NULL,
    multileg_order_id bigint NOT NULL,
    client_leg_ref_id character varying(30) NOT NULL,
    date_id integer NOT NULL,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.client_order_leg OWNER TO dwh;

--
-- Name: cond_execution_bust; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.cond_execution_bust (
    order_id bigint NOT NULL,
    exch_exec_id character varying(128),
    bust_exec_id bigint NOT NULL,
    exec_bust_date_id integer NOT NULL,
    stg_db_create_time timestamp without time zone,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    is_processed boolean DEFAULT false,
    etl_proc_time timestamp without time zone
)
PARTITION BY RANGE (exec_bust_date_id);


ALTER TABLE dwh_new.cond_execution_bust OWNER TO dwh;

--
-- Name: conditional_execution; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.conditional_execution (
    exec_id bigint NOT NULL,
    exch_exec_id character varying(200),
    order_id bigint,
    fix_message_id bigint,
    exec_type character(1),
    order_status character(1),
    exec_time timestamp without time zone,
    leaves_qty integer,
    last_mkt character varying(20),
    text character varying(512),
    is_busted character(1),
    exchange_id character varying(10),
    date_id integer NOT NULL,
    last_qty bigint,
    last_px numeric(12,4),
    cum_qty bigint,
    reject_code smallint,
    ref_exec_id bigint,
    internal_component_type character(1),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.conditional_execution OWNER TO dwh;

--
-- Name: conditional_order; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.conditional_order (
    order_id bigint NOT NULL,
    instrument_id bigint NOT NULL,
    account_id bigint NOT NULL,
    fix_connection_id smallint NOT NULL,
    parent_order_id bigint,
    fix_message_id bigint,
    orig_order_id bigint,
    client_order_id character varying(256) NOT NULL,
    client_id_text character varying(255),
    order_type_id character(1) NOT NULL,
    create_time timestamp without time zone,
    process_time timestamp without time zone,
    order_class character(1) NOT NULL,
    side character(1) NOT NULL,
    order_qty bigint NOT NULL,
    price numeric(12,4),
    ex_destination character varying(5),
    mpid character varying(18),
    exec_instruction character varying(128),
    osr_street_client_order_id character varying(128),
    orig_account_id bigint NOT NULL,
    trans_type character(1) NOT NULL,
    sub_system_id character varying(20),
    sub_system_unq_id integer,
    transaction_id bigint,
    exchange_id character varying(6),
    strtg_decision_reason_code smallint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone,
    date_id integer NOT NULL,
    time_in_force_id character(1),
    expire_time timestamp(6) without time zone,
    open_close character(1),
    handl_inst character(1),
    max_show_qty bigint,
    max_floor bigint,
    eq_order_capacity character(1),
    locate_req character(1),
    locate_broker character varying(20),
    sub_strategy_desc character varying(128),
    algo_client_order_id character varying(128),
    algo_start_time timestamp(6) without time zone,
    algo_end_time timestamp(6) without time zone,
    min_target_qty bigint,
    discretion_offset numeric(12,4),
    co_sub_account character varying(256),
    liquidity_provider_id character varying(9),
    internal_component_type character(1),
    osr_customer_order_id bigint,
    osr_street_order_id bigint,
    occ_optional_data character varying(128),
    exch_order_id character varying(128),
    free_text character varying(256)
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.conditional_order OWNER TO dwh;

--
-- Name: cross_order; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.cross_order (
    cross_order_id bigint NOT NULL,
    cross_id character varying(256),
    exposure_flag character(1),
    step_up_px numeric(12,4),
    broker_pct integer,
    cross_type character(1),
    trans_type character(1),
    create_time timestamp(3) with time zone,
    orig_cross_order_id bigint,
    date_id integer NOT NULL,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone,
    process_time timestamp(6) with time zone
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.cross_order OWNER TO dwh;

--
-- Name: execution; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.execution (
    exec_id bigint NOT NULL,
    order_id bigint NOT NULL,
    order_status character(1),
    exec_type character(1) NOT NULL,
    exec_date_id integer NOT NULL,
    exec_time timestamp(6) without time zone NOT NULL,
    is_billed character varying(1) DEFAULT 'N'::character varying,
    is_busted character(1) NOT NULL,
    leaves_qty bigint,
    cum_qty bigint,
    avg_px numeric(12,4),
    last_qty bigint,
    last_px numeric(12,4),
    bust_qty bigint,
    dataset_id integer,
    last_mkt character varying(5),
    contra_broker character varying(256),
    secondary_order_id character varying(256),
    exch_exec_id character varying(128),
    secondary_exch_exec_id character varying(128),
    contra_account_capacity character(1),
    trade_liquidity_indicator character varying(256),
    account_id integer,
    fix_message_id bigint,
    text character varying(512),
    is_parent_level boolean,
    exec_broker character varying(32),
    auction_id bigint,
    match_qty bigint,
    match_px numeric(12,4),
    internal_component_type character(1),
    exchange_id character varying(6),
    contra_trader character varying(256),
    ref_exec_id bigint,
    exch_connection_id bigint,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone,
    order_create_date_id integer,
    time_in_force_id character(1),
    reject_code smallint
)
PARTITION BY RANGE (exec_date_id);


ALTER TABLE dwh_new.execution OWNER TO dwh;

--
-- Name: execution_bust; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.execution_bust (
    order_id bigint NOT NULL,
    exch_exec_id character varying(128),
    bust_exec_id bigint NOT NULL,
    exec_bust_date_id integer NOT NULL,
    stg_db_create_time timestamp without time zone,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    is_processed boolean DEFAULT false,
    etl_proc_time timestamp without time zone
)
PARTITION BY RANGE (exec_bust_date_id);


ALTER TABLE dwh_new.execution_bust OWNER TO dwh;

--
-- Name: gtc_order_status; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.gtc_order_status (
    order_id bigint,
    create_date_id integer,
    order_status character(1),
    exec_time timestamp(6) without time zone,
    last_trade_date timestamp(0) without time zone,
    last_mod_date_id integer,
    is_parent boolean
);


ALTER TABLE dwh_new.gtc_order_status OWNER TO dwh;

--
-- Name: request_for_quote; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.request_for_quote (
    rfq_id bigint NOT NULL,
    auction_id bigint NOT NULL,
    security_desc character varying(256),
    quote_type character(1) NOT NULL,
    order_qty integer NOT NULL,
    transact_time timestamp(3) without time zone NOT NULL,
    min_response_qty integer,
    fix_connection_id integer,
    fix_message_id bigint,
    parent_order_id bigint NOT NULL,
    multileg_reporting_type character(1),
    transaction_id bigint,
    process_time timestamp without time zone,
    date_id integer NOT NULL,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.request_for_quote OWNER TO dwh;

--
-- Name: request_for_quote_leg; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.request_for_quote_leg (
    rfq_leg_id bigint NOT NULL,
    rfq_id bigint NOT NULL,
    instrument_id bigint NOT NULL,
    side character(1),
    ratio_qty integer,
    date_id integer NOT NULL,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    stg_db_create_time timestamp without time zone
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.request_for_quote_leg OWNER TO dwh;

--
-- Name: routing_table_to_order; Type: TABLE; Schema: dwh_new; Owner: dwh
--

CREATE TABLE dwh_new.routing_table_to_order (
    transaction_id bigint,
    routing_table_id integer,
    date_id integer NOT NULL
)
PARTITION BY RANGE (date_id);


ALTER TABLE dwh_new.routing_table_to_order OWNER TO dwh;

--
-- Name: btb_drop_record; Type: TABLE; Schema: eod_reports; Owner: dwh
--

CREATE TABLE eod_reports.btb_drop_record (
    firm_filter_num smallint NOT NULL,
    drop_record_id bigint NOT NULL,
    exec_id bigint,
    account_id integer NOT NULL,
    instrument_id bigint NOT NULL,
    order_id bigint NOT NULL,
    parent_client_order_id character varying(256) NOT NULL,
    customer_or_firm character varying(1),
    clearing_firm_id character varying(3),
    order_avg_px numeric(12,4),
    dash_commission numeric(12,4),
    exchange_fee numeric(12,4),
    sec_fee numeric(12,4),
    occ_fee numeric(12,4),
    orf numeric(12,4),
    bid_px numeric(12,4),
    offer_px numeric(12,4),
    bid_size bigint,
    offer_size bigint,
    mkt_bid_px numeric(12,4),
    mkt_offer_px numeric(12,4),
    mkt_bid_size bigint,
    mkt_offer_size bigint,
    wave_no bigint,
    parent_exec_id bigint,
    parent_order_id bigint,
    account_name character varying(30),
    order_no bigint,
    date_id integer,
    multileg_reporting_type character varying(1),
    mleg_trade_no character varying(10),
    order_status character varying(1),
    exec_type character varying(1),
    leg1 numeric(13,0),
    leg2 numeric(13,0),
    leg3 numeric(13,0),
    leg4 numeric(13,0),
    strategy_decision_reason_code character varying(8),
    street_cross_id character varying(256),
    parent_cross_id character varying(256)
);


ALTER TABLE eod_reports.btb_drop_record OWNER TO dwh;

--
-- Name: ihs_markit_606_economic_fields; Type: TABLE; Schema: eod_reports; Owner: dwh
--

CREATE TABLE eod_reports.ihs_markit_606_economic_fields (
    order_id bigint,
    secondary_order_id character varying(256),
    secondary_exch_exec_id character varying(256),
    trade_record_id bigint,
    date_id integer,
    payment_for_order_flow_received numeric(24,6),
    payment_for_profit_sharing_received numeric(24,6),
    rebate_received_for_order_execution numeric(24,6),
    fee_paid_for_order_execution numeric(24,6),
    net_fee_rebate numeric(24,6),
    net_amount_paid_received numeric(24,6),
    net_rate_per_share numeric(24,6)
)
PARTITION BY RANGE (date_id);


ALTER TABLE eod_reports.ihs_markit_606_economic_fields OWNER TO dwh;

--
-- Name: ihs_markit_rep_clients; Type: TABLE; Schema: eod_reports; Owner: dwh
--

CREATE TABLE eod_reports.ihs_markit_rep_clients (
    trading_firm_name character varying(60) NOT NULL,
    trading_firm_id character varying(9) NOT NULL,
    billing_entity character varying(32),
    is_active boolean DEFAULT true NOT NULL,
    imid character varying(20) NOT NULL,
    is_rep_606a character varying(1) DEFAULT 'Y'::character varying NOT NULL,
    is_rep_606b character varying(1) DEFAULT 'Y'::character varying NOT NULL
);


ALTER TABLE eod_reports.ihs_markit_rep_clients OWNER TO dwh;

--
-- Name: pd_date; Type: TABLE; Schema: eod_reports; Owner: pdubnytskyi
--

CREATE TABLE eod_reports.pd_date (
    date_id integer,
    is_processed boolean
);


ALTER TABLE eod_reports.pd_date OWNER TO pdubnytskyi;

--
-- Name: algo_order_tca; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.algo_order_tca (
    order_id bigint NOT NULL,
    generation_number integer NOT NULL,
    date_id integer NOT NULL,
    orig_order_id bigint,
    capacity character varying(3),
    activ_symbol character varying(8) NOT NULL,
    instrument_id integer NOT NULL,
    order_qty integer NOT NULL,
    exec_qty integer NOT NULL,
    avg_px numeric,
    strategy character varying(24),
    order_type character(1),
    order_price numeric,
    tif character varying(3),
    stop_price numeric,
    last_fill timestamp without time zone,
    cancel_time timestamp without time zone,
    arrival_time timestamp without time zone,
    last_transaction character varying(24),
    side character varying(3),
    fill_count integer,
    event_count integer,
    order_state character varying(25),
    error integer,
    urgency character varying(6),
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    max_vol_participation integer,
    min_vol_participation integer,
    finish_qty integer,
    finish_price numeric,
    target_participation integer,
    upper_participation integer,
    upper_participation_threshold integer,
    lower_participation integer,
    lower_participation_threshold integer,
    c10b18 character varying(2),
    fee_sensitivity numeric,
    fee_sensitivity2 numeric,
    min_target_qty integer,
    stock_ref_price numeric,
    plusminus_cents_per_share numeric,
    working_delta numeric,
    stock_px_out_of_range_behavior character(1),
    preopen_behavior character(1),
    force_sensor_qty integer,
    close_aggression integer,
    close_sizing character varying(8),
    close_sizing_pc numeric,
    min_fill_qty integer,
    min_first_fill_qty integer,
    preopen character(1),
    must_complete character(1),
    min_threshold_qty integer,
    aggression integer,
    hidden character(1),
    dark_min_fill_qty integer,
    participation_level integer,
    smart_posting_exch character varying(8),
    duration_instruction character varying(8),
    include_block_volume character varying(8),
    tmp_order_status character varying(25),
    tmp_exec_type character varying(25)
);


ALTER TABLE eq_tca.algo_order_tca OWNER TO eq_tca_group;

--
-- Name: algo_order_tca_what_if; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.algo_order_tca_what_if (
    order_id bigint NOT NULL,
    what_if_type character varying(30),
    generation_number integer,
    date_id integer,
    orig_order_id bigint,
    capacity character varying(3),
    activ_symbol character varying(8),
    instrument_id integer,
    order_qty integer,
    exec_qty integer,
    avg_px numeric,
    strategy character varying(24),
    order_type character(1),
    order_price numeric,
    tif character varying(3),
    stop_price numeric,
    last_fill timestamp without time zone,
    cancel_time timestamp without time zone,
    arrival_time timestamp without time zone,
    last_transaction character varying(24),
    side character varying(3),
    fill_count integer,
    event_count integer,
    order_state character varying(25),
    error integer,
    urgency character varying(6),
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    max_vol_participation integer,
    min_vol_participation integer,
    finish_qty integer,
    finish_price numeric,
    target_participation integer,
    upper_participation integer,
    upper_participation_threshold integer,
    lower_participation integer,
    lower_participation_threshold integer,
    c10b18 character varying(2),
    fee_sensitivity numeric,
    fee_sensitivity2 numeric,
    min_target_qty integer,
    stock_ref_price numeric,
    plusminus_cents_per_share numeric,
    working_delta numeric,
    stock_px_out_of_range_behavior character(1),
    preopen_behavior character(1),
    force_sensor_qty integer,
    close_aggression integer,
    close_sizing character varying(8),
    close_sizing_pc numeric,
    min_fill_qty integer,
    min_first_fill_qty integer,
    preopen character(1),
    must_complete character(1),
    min_threshold_qty integer,
    aggression integer,
    hidden character(1),
    dark_min_fill_qty integer,
    participation_level integer,
    smart_posting_exch character varying(8),
    duration_instruction character varying(8),
    include_block_volume character varying(8),
    tmp_order_status character varying(25),
    tmp_exec_type character varying(25),
    orig_order_price numeric,
    client_gen_number character varying,
    orig_arrival_time timestamp without time zone,
    orig_last_fill timestamp without time zone,
    orig_cancel_time timestamp without time zone,
    orig_end_time timestamp without time zone,
    orig_start_time timestamp without time zone,
    orig_date_id numeric,
    orig_order_qty integer,
    order_price_m numeric,
    uuid uuid
);


ALTER TABLE eq_tca.algo_order_tca_what_if OWNER TO eq_tca_group;

--
-- Name: COLUMN algo_order_tca_what_if.order_price_m; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algo_order_tca_what_if.order_price_m IS 'meant to bridge the gap of market orders that come in without a price. In those cases this is average price of execution; otherwise limit order px.';


--
-- Name: algorithmic_order_analytic; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.algorithmic_order_analytic (
    create_time timestamp without time zone DEFAULT now(),
    generation_number integer NOT NULL,
    version character varying(16) NOT NULL,
    date_id integer NOT NULL,
    instrument_id bigint NOT NULL,
    order_id bigint NOT NULL,
    orig_order_id bigint,
    calc_type public.calculation_scheme NOT NULL,
    start_type public.start_price_scheme NOT NULL,
    error_code character varying(16) DEFAULT NULL::character varying,
    activ_symbol character varying(8) NOT NULL,
    strategy character varying(16) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    bid_at_arrival numeric,
    ask_at_arrival numeric,
    order_arrival_price numeric,
    quote_time_at_arrival timestamp without time zone,
    quote_time_at_start timestamp without time zone,
    last_trade_time_at_start timestamp without time zone,
    bid_at_start numeric,
    ask_at_start numeric,
    order_start_price numeric,
    order_end_price numeric,
    vwap_over_life numeric,
    volume_over_life integer,
    eligible_vwap_over_life numeric,
    eligible_volume_over_life integer,
    percentage_of_volume_limit numeric,
    trade_count integer,
    eligible_trade_count integer,
    time_of_last_fill timestamp without time zone,
    time_of_first_fill timestamp without time zone,
    effective_end_time timestamp without time zone,
    effective_start_time timestamp without time zone,
    pwp_5pc numeric,
    pwp_10pc numeric,
    pwp_15pc numeric,
    pwp_20pc numeric,
    pwp_25pc numeric,
    pwp_30pc numeric,
    pwp_35pc numeric,
    first_time_eligible timestamp without time zone,
    limit_eligible_intervals integer,
    limit_eligible interval,
    stop_trigger_time timestamp without time zone,
    buyback_limit_eligible_volume integer,
    buyback_limit_eligible_vwap numeric,
    buyback_vwap numeric,
    buyback_volume integer,
    buyback_pwp10 numeric,
    buyback_pwp10_end_time timestamp without time zone,
    high numeric,
    low numeric,
    high_time timestamp without time zone,
    low_time timestamp without time zone,
    eligible_pwp_5pc numeric,
    eligible_pwp_10pc numeric,
    eligible_pwp_15pc numeric,
    eligible_pwp_20pc numeric,
    eligible_pwp_25pc numeric,
    eligible_pwp_30pc numeric,
    eligible_pwp_35pc numeric,
    pwp_5pc_end_time timestamp without time zone,
    pwp_10pc_end_time timestamp without time zone,
    pwp_15pc_end_time timestamp without time zone,
    pwp_20pc_end_time timestamp without time zone,
    pwp_25pc_end_time timestamp without time zone,
    pwp_30pc_end_time timestamp without time zone,
    pwp_35pc_end_time timestamp without time zone,
    eligible_pwp_5pc_end_time timestamp without time zone,
    eligible_pwp_10pc_end_time timestamp without time zone,
    eligible_pwp_15pc_end_time timestamp without time zone,
    eligible_pwp_20pc_end_time timestamp without time zone,
    eligible_pwp_25pc_end_time timestamp without time zone,
    eligible_pwp_30pc_end_time timestamp without time zone,
    eligible_pwp_35pc_end_time timestamp without time zone,
    market_reference_at_start numeric,
    market_reference_symbol character varying(8),
    market_reference_at_end numeric,
    market_reference_vwap_over_life numeric,
    twap_over_life numeric,
    eligible_twap_over_life numeric,
    block_value numeric,
    block_volume integer,
    block_count integer,
    wtd_avg_spread_arrival numeric,
    post_trade_vwap_5mins numeric,
    post_trade_vwap_10mins numeric,
    post_trade_vwap_15mins numeric,
    post_pwp_5pc numeric,
    post_pwp_10pc numeric,
    post_pwp_15pc numeric,
    post_pwp_20pc numeric,
    post_pwp_25pc numeric,
    post_pwp_5pc_end_time timestamp without time zone,
    post_pwp_10pc_end_time timestamp without time zone,
    post_pwp_15pc_end_time timestamp without time zone,
    post_pwp_20pc_end_time timestamp without time zone,
    post_pwp_25pc_end_time timestamp without time zone,
    eligible_vwap_whole_day numeric,
    price_5s_after_order numeric,
    price_10s_after_order numeric,
    price_30s_after_order numeric,
    price_1m_after_order numeric,
    price_5m_after_order numeric,
    avg_spread_capture numeric,
    price_t5_pct_after_order numeric,
    price_t10_pct_after_order numeric,
    price_t20_pct_after_order numeric,
    price_t30_pct_after_order numeric,
    price_t50_pct_after_order numeric,
    price_t100_pct_after_order numeric,
    price_v5_pct_after_order numeric,
    price_v10_pct_after_order numeric,
    price_v20_pct_after_order numeric,
    price_v30_pct_after_order numeric,
    price_v50_pct_after_order numeric,
    price_v100_pct_after_order numeric,
    spread_capture numeric,
    spread_opportunity numeric,
    stddev_of_price numeric,
    realized_stddev_of_executions numeric,
    stddev_of_price_wtd numeric,
    order_arrival_price_limit numeric,
    order_end_price_limit numeric,
    error_text text,
    eligible_volume_over_life_by_exchange json,
    noneligible_volume_over_life_by_exchange json,
    wtd_avg_spread_start numeric,
    order_arrival_price_b numeric,
    order_arrival_price_b_time timestamp without time zone,
    last_fill_time timestamp without time zone,
    eligible_vwap_start_lf numeric,
    eligible_vwap_start_lf_shares integer,
    vwap_start_eod_shares integer,
    vwap_start_lf numeric,
    vwap_start_lf_shares integer,
    vwap_sod_start numeric,
    vwap_sod_start_shares integer,
    vwap_end_eod numeric,
    vwap_end_eod_shares integer,
    vwap_start_eod numeric,
    order_arrival_price_limit_b numeric,
    order_arrival_price_limit_b_time timestamp without time zone,
    best_vwap numeric,
    best_eligible_vwap numeric,
    worst_vwap numeric,
    worst_eligible_vwap numeric,
    best_eligible_ticks integer,
    best_eligible_shares integer,
    best_eligible_end_time timestamp without time zone,
    best_ticks integer,
    best_shares integer,
    best_end_time timestamp without time zone,
    worst_ticks integer,
    worst_shares integer,
    worst_end_time timestamp without time zone,
    worst_eligible_ticks integer,
    worst_eligible_shares integer,
    worst_eligible_end_time timestamp without time zone,
    snaps_from_end json,
    snaps_from_last_fill json
);


ALTER TABLE eq_tca.algorithmic_order_analytic OWNER TO eq_tca_group;

--
-- Name: COLUMN algorithmic_order_analytic.eligible_volume_over_life_by_exchange; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.eligible_volume_over_life_by_exchange IS 'dictionary of exchanges and (limit price eligible) volumes over life of trade.';


--
-- Name: COLUMN algorithmic_order_analytic.noneligible_volume_over_life_by_exchange; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.noneligible_volume_over_life_by_exchange IS 'dictionary of exchanges and (unconstrained) volumes over life of trade.';


--
-- Name: COLUMN algorithmic_order_analytic.wtd_avg_spread_start; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.wtd_avg_spread_start IS 'time weighted average of spread from start to end of order.';


--
-- Name: COLUMN algorithmic_order_analytic.order_arrival_price_b; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.order_arrival_price_b IS 'first trade (unconstrained) before arrival time.';


--
-- Name: COLUMN algorithmic_order_analytic.order_arrival_price_b_time; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.order_arrival_price_b_time IS 'time of first trade (unconstrained) before arrival time.';


--
-- Name: COLUMN algorithmic_order_analytic.last_fill_time; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.last_fill_time IS 'last fill time for parent order strategy.';


--
-- Name: COLUMN algorithmic_order_analytic.eligible_vwap_start_lf; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.eligible_vwap_start_lf IS 'vwap (limit price eligible) from start of order to end of day.';


--
-- Name: COLUMN algorithmic_order_analytic.eligible_vwap_start_lf_shares; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.eligible_vwap_start_lf_shares IS 'shares (limit price eligible) from start of order to end of day.';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_start_eod_shares; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_start_eod_shares IS 'vwap (unconstrained) from start of order to end of day.';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_start_lf; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_start_lf IS 'vwap (unconstrained) from start of order to lf (last_fill).';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_start_lf_shares; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_start_lf_shares IS 'shares (unconstrained) from start of order to lf (last fill).';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_sod_start; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_sod_start IS 'vwap (unconstrained) from start of day to start of order.';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_sod_start_shares; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_sod_start_shares IS 'shares (unconstrained) from start of day to start of order.';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_end_eod; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_end_eod IS 'vwap (unconstrained) from end of order to end of day.';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_end_eod_shares; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_end_eod_shares IS 'shares (unconstrained) from end of order to end of day.';


--
-- Name: COLUMN algorithmic_order_analytic.vwap_start_eod; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.vwap_start_eod IS 'vwap (unconstrained) from start of order to end of day.';


--
-- Name: COLUMN algorithmic_order_analytic.order_arrival_price_limit_b; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.order_arrival_price_limit_b IS 'first trade (limit price eligible)  before arrival time.';


--
-- Name: COLUMN algorithmic_order_analytic.order_arrival_price_limit_b_time; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.order_arrival_price_limit_b_time IS 'time of first trade (limit price eligible)  before arrival time.';


--
-- Name: COLUMN algorithmic_order_analytic.best_vwap; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.best_vwap IS 'best possible vwap (unconstrained) over life of trade.';


--
-- Name: COLUMN algorithmic_order_analytic.best_eligible_vwap; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.best_eligible_vwap IS 'best possible vwap (limit price eligible) over life of trade.';


--
-- Name: COLUMN algorithmic_order_analytic.worst_vwap; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.worst_vwap IS 'worst possible vwap (unconstrained) over life of trade.';


--
-- Name: COLUMN algorithmic_order_analytic.worst_eligible_vwap; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.algorithmic_order_analytic.worst_eligible_vwap IS 'worst possible vwap (limit price eligible) over life of trade.';


--
-- Name: algorithmic_order_analytic_wtf; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.algorithmic_order_analytic_wtf (
    create_time timestamp without time zone DEFAULT now(),
    generation_number integer NOT NULL,
    version character varying(8) NOT NULL,
    date_id integer NOT NULL,
    instrument_id integer NOT NULL,
    order_id integer NOT NULL,
    orig_order_id integer,
    calc_type public.calculation_scheme NOT NULL,
    start_type public.start_price_scheme NOT NULL,
    error_code character varying(16) DEFAULT NULL::character varying,
    activ_symbol character varying(8) NOT NULL,
    strategy character varying(16) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    bid_at_arrival numeric,
    ask_at_arrival numeric,
    order_arrival_price numeric,
    quote_time_at_arrival timestamp without time zone,
    quote_time_at_start timestamp without time zone,
    last_trade_time_at_start timestamp without time zone,
    bid_at_start numeric,
    ask_at_start numeric,
    order_start_price numeric,
    order_end_price numeric,
    vwap_over_life numeric,
    volume_over_life integer,
    eligible_vwap_over_life numeric,
    eligible_volume_over_life integer,
    percentage_of_volume_limit numeric,
    trade_count integer,
    eligible_trade_count integer,
    time_of_last_fill timestamp without time zone,
    time_of_first_fill timestamp without time zone,
    effective_end_time timestamp without time zone,
    effective_start_time timestamp without time zone,
    best_possible_avgprice numeric,
    worst_possible_avgprice numeric,
    best_possible_eligible_avgprice numeric,
    pwp_5pc numeric,
    pwp_10pc numeric,
    pwp_15pc numeric,
    pwp_20pc numeric,
    pwp_25pc numeric,
    pwp_30pc numeric,
    pwp_35pc numeric,
    first_time_eligible timestamp without time zone,
    limit_eligible_intervals integer,
    limit_eligible interval,
    stop_trigger_time timestamp without time zone,
    buyback_limit_eligible_volume integer,
    buyback_limit_eligible_vwap numeric,
    buyback_vwap numeric,
    buyback_volume integer,
    buyback_pwp10 numeric,
    buyback_pwp10_end_time timestamp without time zone,
    high numeric,
    low numeric,
    high_time timestamp without time zone,
    low_time timestamp without time zone,
    eligible_pwp_5pc numeric,
    eligible_pwp_10pc numeric,
    eligible_pwp_15pc numeric,
    eligible_pwp_20pc numeric,
    eligible_pwp_25pc numeric,
    eligible_pwp_30pc numeric,
    eligible_pwp_35pc numeric,
    pwp_5pc_end_time timestamp without time zone,
    pwp_10pc_end_time timestamp without time zone,
    pwp_15pc_end_time timestamp without time zone,
    pwp_20pc_end_time timestamp without time zone,
    pwp_25pc_end_time timestamp without time zone,
    pwp_30pc_end_time timestamp without time zone,
    pwp_35pc_end_time timestamp without time zone,
    eligible_pwp_5pc_end_time timestamp without time zone,
    eligible_pwp_10pc_end_time timestamp without time zone,
    eligible_pwp_15pc_end_time timestamp without time zone,
    eligible_pwp_20pc_end_time timestamp without time zone,
    eligible_pwp_25pc_end_time timestamp without time zone,
    eligible_pwp_30pc_end_time timestamp without time zone,
    eligible_pwp_35pc_end_time timestamp without time zone,
    market_reference_at_start numeric,
    market_reference_symbol character varying(8),
    market_reference_at_end numeric,
    market_reference_vwap_over_life numeric,
    twap_over_life numeric,
    eligible_twap_over_life numeric,
    block_value numeric,
    block_volume integer,
    block_count integer,
    weighted_avg_bid_ask_spread numeric,
    post_trade_vwap_5mins numeric,
    post_trade_vwap_10mins numeric,
    post_trade_vwap_15mins numeric,
    post_pwp_5pc numeric,
    post_pwp_10pc numeric,
    post_pwp_15pc numeric,
    post_pwp_20pc numeric,
    post_pwp_25pc numeric,
    post_pwp_5pc_end_time timestamp without time zone,
    post_pwp_10pc_end_time timestamp without time zone,
    post_pwp_15pc_end_time timestamp without time zone,
    post_pwp_20pc_end_time timestamp without time zone,
    post_pwp_25pc_end_time timestamp without time zone,
    eligible_vwap_whole_day numeric,
    price_5s_after_order numeric,
    price_10s_after_order numeric,
    price_30s_after_order numeric,
    price_1m_after_order numeric,
    price_5m_after_order numeric,
    avg_spread_capture numeric,
    price_t5_pct_after_order numeric,
    price_t10_pct_after_order numeric,
    price_t20_pct_after_order numeric,
    price_t30_pct_after_order numeric,
    price_t50_pct_after_order numeric,
    price_t100_pct_after_order numeric,
    price_v5_pct_after_order numeric,
    price_v10_pct_after_order numeric,
    price_v20_pct_after_order numeric,
    price_v30_pct_after_order numeric,
    price_v50_pct_after_order numeric,
    price_v100_pct_after_order numeric,
    spread_capture numeric,
    spread_opportunity numeric,
    stddev_of_price numeric,
    realized_stddev_of_executions numeric,
    stddev_of_price_wtd numeric,
    order_arrival_price_limit numeric,
    order_end_price_limit numeric,
    error_text text,
    what_if_type character varying(30) NOT NULL
);


ALTER TABLE eq_tca.algorithmic_order_analytic_wtf OWNER TO eq_tca_group;

--
-- Name: TABLE algorithmic_order_analytic_wtf; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON TABLE eq_tca.algorithmic_order_analytic_wtf IS '-add client_gen_number after added to script';


--
-- Name: daily_analytic; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.daily_analytic (
    instrument_id integer,
    date_id integer,
    symbol character varying(12),
    primary_open_shares integer,
    primary_open_time timestamp without time zone,
    open_price numeric,
    close_price numeric,
    ticks integer,
    vwap numeric,
    low numeric,
    high numeric,
    twap numeric,
    shares bigint,
    preopen_trades integer,
    preopen_shares integer,
    nonprimary_opening_shares integer,
    postclose_shares integer,
    primary_closing_shares integer,
    postclose_trades integer,
    nonprimary_closing_shares integer,
    px_hist json,
    close_snaps json,
    oddlot_venues json,
    oddlot_shares integer,
    oddlot_prints integer,
    block_venues json,
    block_shares integer,
    block_prints integer,
    iso_prints integer,
    iso_shares integer,
    trade_size_hist json,
    price_hist json,
    half_day boolean,
    size_0001_ile integer,
    size_0010_ile integer,
    size_0100_ile integer,
    block_shares_prior_0001_ile integer,
    block_shares_prior_0010_ile integer,
    block_shares_prior_0100_ile integer,
    block_prints_prior_0001_ile integer,
    block_prints_prior_0010_ile integer,
    block_prints_prior_0100_ile integer,
    pg_db_create_time timestamp(0) without time zone DEFAULT clock_timestamp(),
    pg_db_update_time timestamp(0) without time zone,
    regular_venues json,
    regular_prints_by_venue json,
    oddlot_prints_by_venue json,
    derivatively_priced_shares integer,
    derivatively_priced_prints integer,
    derivatively_priced_prints_by_venue json
);


ALTER TABLE eq_tca.daily_analytic OWNER TO eq_tca_group;

--
-- Name: daily_analytic_beta; Type: TABLE; Schema: eq_tca; Owner: dwh
--

CREATE TABLE eq_tca.daily_analytic_beta (
    instrument_id integer,
    date_id integer,
    symbol character varying(12),
    primary_open_shares integer,
    primary_open_time timestamp without time zone,
    open_price numeric,
    close_price numeric,
    ticks integer,
    vwap numeric,
    low numeric,
    high numeric,
    twap numeric,
    shares integer,
    preopen_trades integer,
    preopen_shares integer,
    nonprimary_opening_shares integer,
    postclose_shares integer,
    primary_closing_shares integer,
    postclose_trades integer,
    nonprimary_closing_shares integer,
    px_hist json,
    close_snaps json,
    oddlot_venues json,
    oddlot_shares integer,
    oddlot_prints integer,
    block_venues json,
    block_shares integer,
    block_prints integer,
    iso_prints integer,
    iso_shares integer,
    trade_size_hist json,
    price_hist json,
    half_day boolean,
    size_0001_ile integer,
    size_0010_ile integer,
    size_0100_ile integer,
    block_shares_prior_0001_ile integer,
    block_shares_prior_0010_ile integer,
    block_shares_prior_0100_ile integer,
    block_prints_prior_0001_ile integer,
    block_prints_prior_0010_ile integer,
    block_prints_prior_0100_ile integer,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    pg_db_update_time timestamp without time zone
);


ALTER TABLE eq_tca.daily_analytic_beta OWNER TO dwh;

--
-- Name: daily_analytic_corp_adj; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.daily_analytic_corp_adj (
    instrument_id integer,
    date_id integer NOT NULL,
    symbol character varying(12),
    primary_open_shares numeric(10,0),
    primary_open_time timestamp without time zone,
    open_price numeric,
    close_price numeric,
    ticks integer,
    vwap numeric(14,4),
    low numeric(14,4),
    high numeric(14,4),
    twap numeric(14,4),
    shares numeric(14,4),
    preopen_trades integer,
    preopen_shares numeric(14,4),
    nonprimary_opening_shares numeric(14,4),
    postclose_shares numeric(14,4),
    primary_closing_shares numeric(14,4),
    postclose_trades integer,
    nonprimary_closing_shares numeric(14,4),
    px_hist json,
    close_snaps json,
    oddlot_venues json,
    oddlot_shares numeric(14,4),
    oddlot_prints integer,
    block_venues json,
    block_shares numeric(14,4),
    block_prints integer,
    iso_prints integer,
    iso_shares numeric(14,4),
    trade_size_hist json,
    price_hist json,
    half_day boolean,
    size_0001_ile numeric(14,4),
    size_0010_ile numeric(14,4),
    size_0100_ile numeric(14,4),
    block_shares_prior_0001_ile numeric(14,4),
    block_shares_prior_0010_ile numeric(14,4),
    block_shares_prior_0100_ile numeric(14,4),
    block_prints_prior_0001_ile integer,
    block_prints_prior_0010_ile integer,
    block_prints_prior_0100_ile integer,
    open_perc_adv numeric,
    close_perc_adv numeric,
    curve_class character varying,
    alpha_high_minus_low numeric,
    alpha_close_minus_open numeric,
    is_div_adjusted boolean,
    div_adj_close_price numeric(14,4),
    split_adjustment numeric(14,8),
    last_corp_adjusted integer
);


ALTER TABLE eq_tca.daily_analytic_corp_adj OWNER TO eq_tca_group;

--
-- Name: eq_rev_ft; Type: TABLE; Schema: eq_tca; Owner: dwh
--

CREATE TABLE eq_tca.eq_rev_ft (
    date_id integer,
    trade_record_id bigint,
    trade_record_time timestamp without time zone,
    symbol character varying,
    bid_price numeric,
    ask_price numeric,
    bid_qty numeric,
    ask_qty numeric,
    m1ms_bid numeric,
    m1ms_ask numeric,
    m1ms_bid_size numeric,
    m1ms_ask_size numeric,
    m1ms_bid_time timestamp without time zone,
    m1ms_ask_time timestamp without time zone,
    p1ms_bid numeric,
    p1ms_ask numeric,
    p1ms_bid_size numeric,
    p1ms_ask_size numeric,
    p1ms_bid_time timestamp without time zone,
    p1ms_ask_time timestamp without time zone,
    m2ms_bid numeric,
    m2ms_ask numeric,
    m2ms_bid_size numeric,
    m2ms_ask_size numeric,
    m2ms_bid_time timestamp without time zone,
    m2ms_ask_time timestamp without time zone,
    p2ms_bid numeric,
    p2ms_ask numeric,
    p2ms_bid_size numeric,
    p2ms_ask_size numeric,
    p2ms_bid_time timestamp without time zone,
    p2ms_ask_time timestamp without time zone,
    m5ms_bid numeric,
    m5ms_ask numeric,
    m5ms_bid_size numeric,
    m5ms_ask_size numeric,
    m5ms_bid_time timestamp without time zone,
    m5ms_ask_time timestamp without time zone,
    p5ms_bid numeric,
    p5ms_ask numeric,
    p5ms_bid_size numeric,
    p5ms_ask_size numeric,
    p5ms_bid_time timestamp without time zone,
    p5ms_ask_time timestamp without time zone,
    m10ms_bid numeric,
    m10ms_ask numeric,
    m10ms_bid_size numeric,
    m10ms_ask_size numeric,
    m10ms_bid_time timestamp without time zone,
    m10ms_ask_time timestamp without time zone,
    p10ms_bid numeric,
    p10ms_ask numeric,
    p10ms_bid_size numeric,
    p10ms_ask_size numeric,
    p10ms_bid_time timestamp without time zone,
    p10ms_ask_time timestamp without time zone,
    m25ms_bid numeric,
    m25ms_ask numeric,
    m25ms_bid_size numeric,
    m25ms_ask_size numeric,
    m25ms_bid_time timestamp without time zone,
    m25ms_ask_time timestamp without time zone,
    p25ms_bid numeric,
    p25ms_ask numeric,
    p25ms_bid_size numeric,
    p25ms_ask_size numeric,
    p25ms_bid_time timestamp without time zone,
    p25ms_ask_time timestamp without time zone,
    m50ms_bid numeric,
    m50ms_ask numeric,
    m50ms_bid_size numeric,
    m50ms_ask_size numeric,
    m50ms_bid_time timestamp without time zone,
    p50ms_bid numeric,
    p50ms_ask numeric,
    p50ms_bid_size numeric,
    p50ms_ask_size numeric,
    p50ms_bid_time timestamp without time zone,
    p50ms_ask_time timestamp without time zone,
    m75ms_bid numeric,
    m75ms_ask numeric,
    m75ms_bid_size numeric,
    m75ms_ask_size numeric,
    m75ms_bid_time timestamp without time zone,
    m75ms_ask_time timestamp without time zone,
    p75ms_bid numeric,
    p75ms_ask numeric,
    p75ms_bid_size numeric,
    p75ms_ask_size numeric,
    p75ms_bid_time timestamp without time zone,
    p75ms_ask_time timestamp without time zone,
    m100ms_bid numeric,
    m100ms_ask numeric,
    m100ms_bid_size numeric,
    m100ms_ask_size numeric,
    m100ms_bid_time timestamp without time zone,
    m100ms_ask_time timestamp without time zone,
    p100ms_bid numeric,
    p100ms_ask numeric,
    p100ms_bid_size numeric,
    p100ms_ask_size numeric,
    p100ms_bid_time timestamp without time zone,
    p100ms_ask_time timestamp without time zone,
    m50ms_ask_time timestamp without time zone,
    m0ms_bid numeric,
    m0ms_ask numeric,
    m0ms_ask_size numeric,
    m0ms_bid_size numeric,
    m0ms_ask_time timestamp(6) without time zone,
    m0ms_bid_time timestamp(6) without time zone,
    p0ms_bid numeric,
    p0ms_ask numeric,
    p0ms_ask_size numeric,
    p0ms_bid_size numeric,
    p0ms_ask_time timestamp(6) without time zone,
    p0ms_bid_time timestamp(6) without time zone,
    trading_firm_unq_id integer,
    sub_strategy character varying,
    error_code character varying
)
WITH (autovacuum_freeze_table_age='520000000', autovacuum_enabled='true', autovacuum_freeze_max_age='520000000');


ALTER TABLE eq_tca.eq_rev_ft OWNER TO dwh;

--
-- Name: equities_order_state; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.equities_order_state (
    order_id integer NOT NULL,
    batch_id character varying(48) NOT NULL,
    date_id integer NOT NULL,
    fix_message_id bigint NOT NULL,
    client_order_id character varying(64),
    orig_client_order_id character varying(64),
    dash_id character varying(64),
    segment_id character varying(16),
    parent_fix_message_id bigint NOT NULL,
    exch_order_id character varying(32),
    capacity character varying(3),
    exdestination character varying(16),
    client_id character varying(16),
    generation integer NOT NULL,
    symbol character varying(8) NOT NULL,
    instrument_id integer NOT NULL,
    quantity integer NOT NULL,
    done integer NOT NULL,
    avgprc numeric,
    strategy character varying(24),
    mkt boolean,
    stop boolean,
    tif character varying(3),
    limit_price numeric,
    stop_price numeric,
    pegged boolean,
    last_fill timestamp without time zone,
    cancel_time timestamp without time zone,
    arrival_time timestamp without time zone,
    last_transaction character varying(24),
    replace_count integer,
    side character varying(3),
    fill_count integer,
    event_count integer,
    order_state character varying(12),
    error_count integer,
    urgency character varying(6),
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    max_vol_participation integer,
    min_vol_participation integer,
    finish_qty integer,
    finish_price numeric,
    target_participation integer,
    upper_participation integer,
    upper_participation_threshold integer,
    lower_participation integer,
    lower_participation_threshold integer,
    c10b18 character varying(2),
    fee_sensitivity numeric,
    fee_sensitivity2 numeric,
    min_target_qty integer,
    stock_ref_price numeric,
    plusminus_cents_per_share numeric,
    working_delta numeric,
    stock_px_out_of_range_behavior character(1),
    preopen_behavior character(1),
    force_sensor_qty integer,
    close_aggression integer,
    close_sizing character varying(8),
    close_sizing_pc numeric,
    min_fill_qty integer,
    min_first_fill_qty integer,
    preopen character(1),
    must_complete character(1),
    min_threshold_qty integer,
    aggression integer,
    hidden character(1),
    dark_min_fill_qty integer,
    participation_level integer,
    smart_posting_exch character varying(8),
    duration_instruction character varying(8),
    include_block_volume character varying(8)
);


ALTER TABLE eq_tca.equities_order_state OWNER TO eq_tca_group;

--
-- Name: equities_order_state_order_id_seq; Type: SEQUENCE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE SEQUENCE eq_tca.equities_order_state_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE eq_tca.equities_order_state_order_id_seq OWNER TO eq_tca_group;

--
-- Name: equities_order_state_order_id_seq; Type: SEQUENCE OWNED BY; Schema: eq_tca; Owner: eq_tca_group
--

ALTER SEQUENCE eq_tca.equities_order_state_order_id_seq OWNED BY eq_tca.equities_order_state.order_id;


--
-- Name: market_cap_classification; Type: TABLE; Schema: eq_tca; Owner: eq_tca_group
--

CREATE TABLE eq_tca.market_cap_classification (
    market_cap_name character varying NOT NULL,
    upper_limit bigint,
    lower_limit bigint,
    effective_date numeric,
    client_id character varying
);


ALTER TABLE eq_tca.market_cap_classification OWNER TO eq_tca_group;

--
-- Name: COLUMN market_cap_classification.market_cap_name; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.market_cap_classification.market_cap_name IS 'Associated upper and lower limits are in dollars and based on the price * # of outstanding shares';


--
-- Name: COLUMN market_cap_classification.client_id; Type: COMMENT; Schema: eq_tca; Owner: eq_tca_group
--

COMMENT ON COLUMN eq_tca.market_cap_classification.client_id IS 'Specific group, client, or version of market capitalization range set.';


--
-- Name: order_type_mapping; Type: FOREIGN TABLE; Schema: eq_tca; Owner: dwh
--

CREATE FOREIGN TABLE eq_tca.order_type_mapping (
    real_exchange_id character varying NOT NULL,
    ord_type character varying,
    time_in_force character varying,
    exec_inst character varying,
    routing_inst character varying,
    routing_instruction character varying,
    display_inst character varying,
    display_indicator character varying,
    on_behalf_of_comp_id boolean,
    target_location_id boolean,
    max_floor_qty boolean,
    min_qty boolean,
    peg_diff boolean,
    offset_price boolean,
    cross_trade_flag character varying,
    extended_exec_inst character varying,
    rout_strategy character varying,
    peg_price character varying,
    order_type_unq_id bigint NOT NULL,
    hierarchy_1 character varying,
    hierarchy_2 character varying
)
SERVER postgres_true_reversion_stats
OPTIONS (
    schema_name 'order_types',
    table_name 'order_type_mapping'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN real_exchange_id OPTIONS (
    column_name 'real_exchange_id'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN ord_type OPTIONS (
    column_name 'ord_type'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN time_in_force OPTIONS (
    column_name 'time_in_force'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN exec_inst OPTIONS (
    column_name 'exec_inst'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN routing_inst OPTIONS (
    column_name 'routing_inst'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN routing_instruction OPTIONS (
    column_name 'routing_instruction'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN display_inst OPTIONS (
    column_name 'display_inst'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN display_indicator OPTIONS (
    column_name 'display_indicator'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN on_behalf_of_comp_id OPTIONS (
    column_name 'on_behalf_of_comp_id'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN target_location_id OPTIONS (
    column_name 'target_location_id'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN max_floor_qty OPTIONS (
    column_name 'max_floor_qty'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN min_qty OPTIONS (
    column_name 'min_qty'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN peg_diff OPTIONS (
    column_name 'peg_diff'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN offset_price OPTIONS (
    column_name 'offset_price'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN cross_trade_flag OPTIONS (
    column_name 'cross_trade_flag'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN extended_exec_inst OPTIONS (
    column_name 'extended_exec_inst'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN rout_strategy OPTIONS (
    column_name 'rout_strategy'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN peg_price OPTIONS (
    column_name 'peg_price'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN order_type_unq_id OPTIONS (
    column_name 'order_type_unq_id'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN hierarchy_1 OPTIONS (
    column_name 'hierarchy_1'
);
ALTER FOREIGN TABLE eq_tca.order_type_mapping ALTER COLUMN hierarchy_2 OPTIONS (
    column_name 'hierarchy_2'
);


ALTER FOREIGN TABLE eq_tca.order_type_mapping OWNER TO dwh;

--
-- Name: pd_algo_order_tca; Type: TABLE; Schema: eq_tca; Owner: pdubnytskyi
--

CREATE TABLE eq_tca.pd_algo_order_tca (
    order_id bigint,
    generation_number integer,
    date_id integer,
    orig_order_id bigint,
    capacity character varying(3),
    activ_symbol character varying(8),
    instrument_id integer,
    order_qty integer,
    exec_qty integer,
    avg_px numeric,
    strategy character varying(24),
    order_type character(1),
    order_price numeric,
    tif character varying(3),
    stop_price numeric,
    last_fill timestamp without time zone,
    cancel_time timestamp without time zone,
    arrival_time timestamp without time zone,
    last_transaction character varying(24),
    side character varying(3),
    fill_count integer,
    event_count integer,
    order_state character varying(25),
    error integer,
    urgency character varying(6),
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    max_vol_participation integer,
    min_vol_participation integer,
    finish_qty integer,
    finish_price numeric,
    target_participation integer,
    upper_participation integer,
    upper_participation_threshold integer,
    lower_participation integer,
    lower_participation_threshold integer,
    c10b18 character varying(2),
    fee_sensitivity numeric,
    fee_sensitivity2 numeric,
    min_target_qty integer,
    stock_ref_price numeric,
    plusminus_cents_per_share numeric,
    working_delta numeric,
    stock_px_out_of_range_behavior character(1),
    preopen_behavior character(1),
    force_sensor_qty integer,
    close_aggression integer,
    close_sizing character varying(8),
    close_sizing_pc numeric,
    min_fill_qty integer,
    min_first_fill_qty integer,
    preopen character(1),
    must_complete character(1),
    min_threshold_qty integer,
    aggression integer,
    hidden character(1),
    dark_min_fill_qty integer,
    participation_level integer,
    smart_posting_exch character varying(8),
    duration_instruction character varying(8),
    include_block_volume character varying(8),
    tmp_order_status character varying(25),
    tmp_exec_type character varying(25),
    first_fill timestamp without time zone
);


ALTER TABLE eq_tca.pd_algo_order_tca OWNER TO pdubnytskyi;

--
-- Name: activ_5min_bars; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_5min_bars (
    activ_symbol character varying(50) NOT NULL,
    date_time timestamp without time zone NOT NULL,
    open double precision,
    high double precision,
    low double precision,
    close double precision,
    total_volume integer,
    total_value double precision,
    total_price double precision,
    tick_count integer,
    alternative_volume integer,
    flag boolean,
    date_id integer
);


ALTER TABLE external_data.activ_5min_bars OWNER TO dwh;

--
-- Name: activ_industry_sector; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_industry_sector (
    activ_industry_code character varying(10) NOT NULL,
    name character varying(50)
);


ALTER TABLE external_data.activ_industry_sector OWNER TO dwh;

--
-- Name: activ_na_analytics; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_na_analytics (
    atm_call_implied_volatility numeric(20,4),
    atm_put_implied_volatility numeric(20,4),
    average_volume_100day bigint,
    average_volume22day bigint,
    average_volume_250day bigint,
    beta numeric(20,4),
    closing_price_month numeric(20,4),
    closing_price_quarter numeric(20,4),
    closing_price_week numeric(20,4),
    closing_price_year numeric(20,4),
    current_yield numeric(20,4),
    moving_average_100day numeric(20,4),
    moving_average_14day numeric(20,4),
    moving_average_21day numeric(20,4),
    moving_average_250day numeric(20,4),
    moving_average_50day numeric(20,4),
    moving_average_9day numeric(20,4),
    rate_of_return_12month numeric(20,4),
    rate_of_return_year numeric(20,4),
    volatility_01month numeric(20,4),
    volatility_02month numeric(20,4),
    volatility_03month numeric(20,4),
    volatility_04month numeric(20,4),
    volatility_05month numeric(20,4),
    volatility_06month numeric(20,4),
    volatility_07month numeric(20,4),
    volatility_08month numeric(20,4),
    volatility_09month numeric(20,4),
    volatility_10month numeric(20,4),
    volatility_11month numeric(20,4),
    volatility_12month numeric(20,4),
    volatility_20day numeric(20,4),
    context integer,
    create_date date,
    entity_type integer,
    last_update_date date,
    permission_id integer,
    record_status integer,
    reset_date date,
    symbol character varying(100),
    update_id integer,
    indicated_yield numeric(20,4),
    pe_ratio numeric(20,4),
    volatility_10day numeric(20,4),
    volatility_30day numeric(20,4),
    volatility_60day numeric(20,4),
    volatility_90day numeric(20,4),
    volatility_120day numeric(20,4),
    volatility_150day numeric(20,4),
    volatility_180day numeric(20,4),
    volatility_360day numeric(20,4),
    average_volume_10day bigint,
    average_volume_20day bigint,
    average_volume_30day bigint,
    average_volume_60day bigint,
    average_volume_90day bigint,
    average_volume_120day bigint,
    average_volume_150day bigint,
    average_volume_180day bigint,
    average_volume_360day bigint,
    moving_average_10day numeric(20,4),
    moving_average_20day numeric(20,4),
    moving_average_30day numeric(20,4),
    moving_average_60day numeric(20,4),
    moving_average_90day numeric(20,4),
    moving_average_120day numeric(20,4),
    moving_average_150day numeric(20,4),
    moving_average_180day numeric(20,4),
    moving_average_360day numeric(20,4),
    average_volume_5day bigint,
    average_volume_15day bigint,
    average_volume_45day bigint,
    moving_average_5day numeric(20,4),
    moving_average_15day numeric(20,4),
    moving_average_45day numeric(20,4),
    volatility_5day numeric(20,4),
    volatility_15day numeric(20,4),
    volatility_45day numeric(20,4),
    closing_price_3months numeric(20,4),
    closing_price_6months numeric(20,4),
    closing_price_9months numeric(20,4),
    closing_price_12months numeric(20,4),
    pe_ratio_diluted numeric(20,4),
    exponential_moving_average_5day numeric(20,4),
    exponential_moving_average_9day numeric(20,4),
    exponential_moving_average_10day numeric(20,4),
    exponential_moving_average_14day numeric(20,4),
    exponential_moving_average_15day numeric(20,4),
    exponential_moving_average_20day numeric(20,4),
    exponential_moving_average_21day numeric(20,4),
    exponential_moving_average_30day numeric(20,4),
    exponential_moving_average_45day numeric(20,4),
    exponential_moving_average_50day numeric(20,4),
    exponential_moving_average_60day numeric(20,4),
    exponential_moving_average_90day numeric(20,4),
    exponential_moving_average_100day numeric(20,4),
    exponential_moving_average_120day numeric(20,4),
    exponential_moving_average_150day numeric(20,4),
    exponential_moving_average_180day numeric(20,4),
    exponential_moving_average_250day numeric(20,4),
    exponential_moving_average_360day numeric(20,4),
    relative_strength_index numeric(20,4),
    date_id integer
);


ALTER TABLE external_data.activ_na_analytics OWNER TO dwh;

--
-- Name: activ_ohlc; Type: TABLE; Schema: external_data; Owner: a.shum
--

CREATE TABLE external_data.activ_ohlc (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (asof_date_id);


ALTER TABLE external_data.activ_ohlc OWNER TO "a.shum";

--
-- Name: activ_ohlc_2; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_ohlc_2 (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    prev_date_id integer,
    asof_date_id integer,
    open_px numeric,
    high_px numeric,
    low_px numeric,
    close_px numeric,
    prev_open numeric,
    prev_high numeric,
    prev_low numeric,
    prev_close numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data.activ_ohlc_2 OWNER TO dwh;

--
-- Name: activ_symbol2activ_industry_sector; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_symbol2activ_industry_sector (
    active_symbol character varying(20) NOT NULL,
    industry_code character varying(10)
);


ALTER TABLE external_data.activ_symbol2activ_industry_sector OWNER TO dwh;

--
-- Name: activ_us_equity_option; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_us_equity_option (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint
)
PARTITION BY RANGE (load_date_id);


ALTER TABLE external_data.activ_us_equity_option OWNER TO dwh;

--
-- Name: activ_us_equity_option_old; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_us_equity_option_old (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint
);


ALTER TABLE external_data.activ_us_equity_option_old OWNER TO dwh;

--
-- Name: activ_us_listing; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.activ_us_listing (
    date_id integer NOT NULL,
    activ_symbol character varying(50) NOT NULL,
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    lot_size integer,
    bid_time time without time zone,
    permission_id integer,
    recordstatus integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_condition character varying(25),
    bid_exchange character varying(25),
    ask_time time without time zone,
    state integer,
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(25),
    quote_date date,
    column15 character varying(25),
    limit_high_low_time time without time zone,
    limit_high_price double precision,
    ask_condition character varying(25),
    composite_close_date date,
    trade_size integer,
    trade double precision,
    trade_date date,
    limit_low_price double precision,
    retail_price_improvement_indicator character varying(25),
    close_date date,
    last_reported_trade_size integer,
    composite_close double precision,
    status_change_time time without time zone,
    trade_high double precision,
    trade_through_exempt_flag character varying(25),
    close_status integer,
    cumulative_value double precision,
    trade_time time without time zone,
    trade_low double precision,
    entity_type integer,
    closing_quote_date date,
    cumulative_price double precision,
    trade_exchange character varying(25),
    last_reported_trade_date date,
    close double precision,
    financial_status character varying(25),
    create_date date,
    trade_count integer,
    closing_bid double precision,
    last_reported_trade_time time without time zone,
    pre_post_market_trade_date date,
    trade_condition character varying(25),
    closing_ask double precision,
    previous_trade_time time without time zone,
    short_sale_price_restricted character varying(25),
    last_reported_trade_through_exempt_flag character varying(25),
    close_cumulative_volume_date date,
    cumulative_volume integer,
    previous_bid double precision,
    last_reported_trade_exchange character varying(25),
    trade_reporting_exchange character varying(25),
    country_code character varying(25),
    pre_post_market_trade_through_exempt_flag character varying(25),
    close_cumulative_volume_status integer,
    column62 character varying(25),
    net_change double precision,
    year_high double precision,
    price_variation_indicator character varying(25),
    close_cumulative_value_status integer,
    pre_post_market_cumulative_volume integer,
    last_reported_trade double precision,
    reset_date date,
    year_low double precision,
    close_cumulative_volume integer,
    last_reported_trade_condition character varying(25),
    percent_change double precision,
    last_reported_trade_reporting_exchange character varying(25),
    close_cumulative_value double precision,
    previous_ask double precision,
    close_time time without time zone,
    pre_post_market_cumulative_value double precision,
    imbalance_volume_time time without time zone,
    life_time_high double precision,
    market_order_imbalance_buy_volume integer,
    last_block_trade_size integer,
    pre_post_market_trade double precision,
    previous_trading_date date,
    life_time_low double precision,
    column89 character varying(25),
    block_trade_count integer,
    year_high_date date,
    previous_trade_high double precision,
    previous_cumulative_volume integer,
    block_trade_cumulative_volume integer,
    year_low_date date,
    previous_trade_low double precision,
    cross_type character varying(25),
    closing_bid_exchange character varying(25),
    pre_post_market_trade_size integer,
    previous_percent_change double precision,
    trade_high_exchange character varying(25),
    context integer,
    closing_ask_exchange character varying(25),
    trading_status character varying(25),
    previous_cumulative_value double precision,
    high_indication_price double precision,
    trade_low_exchange character varying(25),
    previous_unadjusted_close double precision,
    display_denominator integer,
    previous_cumulative_price double precision,
    open_exchange character varying(25),
    life_time_high_date date,
    previous_open double precision,
    market_tier character varying(25),
    previous_quote_date date,
    current_reference_price double precision,
    previous_net_change double precision,
    life_time_low_date date,
    paired_shares integer,
    close_exchange character varying(2),
    column124 character varying(25),
    trade_low_time time without time zone,
    pre_post_market_trade_high double precision,
    previous_cumulative_volume_date date,
    column128 character varying(25),
    pre_post_market_trade_condition character varying(25),
    trade_high_time time without time zone,
    pre_post_market_trade_low double precision,
    column132 character varying(25),
    column133 character varying(25),
    ssr_filing_price double precision,
    indication_price_time time without time zone,
    trade_id character varying(25),
    bid_market_maker_id character varying(25),
    high_lrp_price double precision,
    pre_post_market_trade_time time without time zone,
    last_reported_trade_id character varying(22),
    ask_market_maker_id character varying(25),
    clearing_price double precision,
    lrp_price_time time without time zone,
    pre_post_market_tradeid character varying(22),
    low_lrp_price double precision,
    closing_only_clearing_price double precision,
    imbalance_sell_volume integer,
    pre_post_market_trade_exchange character varying(25),
    trade_id_original character varying(25),
    far_price double precision,
    low_indication_price double precision,
    pre_post_market_trade_high_time time without time zone,
    trade_id_cancel character varying(25),
    trading_status_reason character varying(25),
    pre_post_market_trade_low_time time without time zone,
    local_trading_code character varying(25),
    trade_correction_time time without time zone,
    market_status_symbol character varying(25),
    quote_lot_size integer,
    imbalance_buy_volume integer,
    pre_post_market_trade_high_exchange character varying(25),
    local_code character varying(25),
    near_price double precision,
    market_order_imbalance_sell_volume integer,
    pre_post_market_trade_low_exchange character varying(25),
    instrument_status_binary character varying(25),
    pre_post_market_trade_reporting_exchange character varying(25),
    is_in character varying(25),
    transaction_lot_size integer,
    composite_close_exchange character varying(25),
    trade_id_corrected character varying(25),
    mic character varying(25),
    currency character varying(25),
    trade_correction_date date,
    pg_db_modified_date date,
    activ_exchange_code character varying(25)
);


ALTER TABLE external_data.activ_us_listing OWNER TO dwh;

--
-- Name: activ_us_listing_temp; Type: FOREIGN TABLE; Schema: external_data; Owner: dwh
--

CREATE FOREIGN TABLE external_data.activ_us_listing_temp (
    activ_symbol character varying(50),
    date_id integer
)
SERVER postgres_big_data
OPTIONS (
    schema_name 'external_data',
    table_name 'activ_us_listing'
);


ALTER FOREIGN TABLE external_data.activ_us_listing_temp OWNER TO dwh;

--
-- Name: option_security_master_new; Type: TABLE; Schema: external_data; Owner: akhomenko
--

CREATE TABLE external_data.option_security_master_new (
    id bigint NOT NULL,
    option_symbol character varying(20),
    underlying_option_symbol character varying(20),
    underlying_stock_symbol character varying(20),
    cusip_number character varying(20),
    cycle_name character varying(20),
    option_type character varying(20),
    dual_exchange character varying(20),
    primary_code character varying(20),
    strike_price numeric(12,4),
    standard_strike_code character varying(20),
    call_code character varying(20),
    put_code character varying(20),
    month_code character varying(20),
    expiration_date timestamp without time zone,
    effective_date timestamp without time zone,
    contract_size numeric(12,4),
    is_adjusted smallint,
    exp_frequency character varying(20),
    strike_status smallint,
    last_updated timestamp without time zone,
    opra_17_call character varying(32),
    opra_17_put character varying(32),
    occ_21_call character varying(32),
    occ_21_put character varying(32),
    consolidated_opra_17_call character varying(32),
    consolidated_opra_17_put character varying(32),
    consolidated_occ_21_call character varying(32),
    consolidated_occ_21_put character varying(32),
    date_id integer
);


ALTER TABLE external_data.option_security_master_new OWNER TO akhomenko;

--
-- Name: artur_test_id_seq; Type: SEQUENCE; Schema: external_data; Owner: akhomenko
--

ALTER TABLE external_data.option_security_master_new ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME external_data.artur_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: baml_rstr_exch_import_list_record_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dwh
--

CREATE SEQUENCE external_data.baml_rstr_exch_import_list_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_data.baml_rstr_exch_import_list_record_id_seq OWNER TO dwh;

--
-- Name: baml_rstr_exch_import; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.baml_rstr_exch_import (
    baml_rstr_exch_import_batch_id integer NOT NULL,
    baml_rstr_exch_list_record_id bigint DEFAULT nextval('external_data.baml_rstr_exch_import_list_record_id_seq'::regclass) NOT NULL,
    symbol character varying(10) NOT NULL,
    maturity_year smallint,
    maturity_month smallint,
    strike_price numeric(12,4),
    put_call character(1),
    exchange_id character varying(6) NOT NULL,
    maturity_day smallint
);


ALTER TABLE external_data.baml_rstr_exch_import OWNER TO dwh;

--
-- Name: TABLE baml_rstr_exch_import; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON TABLE external_data.baml_rstr_exch_import IS 'Entity from list of restricted exchanges. Import will be performed daily. The list will be used by SOR to exclude certain exchanges from routing.';


--
-- Name: COLUMN baml_rstr_exch_import.baml_rstr_exch_import_batch_id; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.baml_rstr_exch_import_batch_id IS 'Unique batch identification.';


--
-- Name: COLUMN baml_rstr_exch_import.baml_rstr_exch_list_record_id; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.baml_rstr_exch_list_record_id IS 'Unique list entity (record) identification.';


--
-- Name: COLUMN baml_rstr_exch_import.symbol; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.symbol IS 'Root Symbol.';


--
-- Name: COLUMN baml_rstr_exch_import.maturity_year; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.maturity_year IS 'Maturity year of the instrument.';


--
-- Name: COLUMN baml_rstr_exch_import.maturity_month; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.maturity_month IS 'Maturity month of the instrument.';


--
-- Name: COLUMN baml_rstr_exch_import.strike_price; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.strike_price IS 'Strike price of the instrument.';


--
-- Name: COLUMN baml_rstr_exch_import.put_call; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.put_call IS 'Put/Call of the instrument.

Valid values:
''0'' (Put);
''1'' (Call).

Note: Absence of value (null) indicates value both put and call. ';


--
-- Name: COLUMN baml_rstr_exch_import.exchange_id; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.exchange_id IS 'Unique exchange identification to which the rules are applied. Referebces to dwh.d_exchange.exchange_id.';


--
-- Name: COLUMN baml_rstr_exch_import.maturity_day; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import.maturity_day IS 'Maturity day of the instrument.';


--
-- Name: baml_rstr_exch_import_batch_import_batch_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dwh
--

CREATE SEQUENCE external_data.baml_rstr_exch_import_batch_import_batch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_data.baml_rstr_exch_import_batch_import_batch_id_seq OWNER TO dwh;

--
-- Name: baml_rstr_exch_import_batch; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.baml_rstr_exch_import_batch (
    baml_rstr_exch_import_batch_id integer DEFAULT nextval('external_data.baml_rstr_exch_import_batch_import_batch_id_seq'::regclass) NOT NULL,
    create_time timestamp without time zone NOT NULL,
    status character(1) NOT NULL,
    reject_reason text
);


ALTER TABLE external_data.baml_rstr_exch_import_batch OWNER TO dwh;

--
-- Name: TABLE baml_rstr_exch_import_batch; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON TABLE external_data.baml_rstr_exch_import_batch IS 'Batch of imports responsible for list of restricted exchanges. Import will be performed daily. The list will be used by SOR to exclude certain exchanges from routing.';


--
-- Name: COLUMN baml_rstr_exch_import_batch.baml_rstr_exch_import_batch_id; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import_batch.baml_rstr_exch_import_batch_id IS 'Unique batch identification.';


--
-- Name: COLUMN baml_rstr_exch_import_batch.create_time; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import_batch.create_time IS 'Batch creation time.';


--
-- Name: COLUMN baml_rstr_exch_import_batch.status; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import_batch.status IS 'Status of import action.
Valid values:
''I'' (Imported successfully);
''R'' (Rejected).';


--
-- Name: COLUMN baml_rstr_exch_import_batch.reject_reason; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.baml_rstr_exch_import_batch.reject_reason IS 'Rejected reason for import fail/reject.';


--
-- Name: contra_occ_trade_data_matching; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.contra_occ_trade_data_matching (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id bigint NOT NULL,
    matching_id bigint NOT NULL,
    trade_id bigint,
    matching_logic smallint
);


ALTER TABLE external_data.contra_occ_trade_data_matching OWNER TO dwh;

--
-- Name: contra_occ_trade_data_matching_matching_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dwh
--

CREATE SEQUENCE external_data.contra_occ_trade_data_matching_matching_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_data.contra_occ_trade_data_matching_matching_id_seq OWNER TO dwh;

--
-- Name: contra_occ_trade_data_matching_matching_id_seq; Type: SEQUENCE OWNED BY; Schema: external_data; Owner: dwh
--

ALTER SEQUENCE external_data.contra_occ_trade_data_matching_matching_id_seq OWNED BY external_data.contra_occ_trade_data_matching.matching_id;


--
-- Name: core_us_fundamentals; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.core_us_fundamentals (
    ticker character varying(32),
    company_name character varying(255),
    cusip character varying(9),
    sector character varying(100),
    date_id integer,
    scale_market_cap character varying(32)
);


ALTER TABLE external_data.core_us_fundamentals OWNER TO dwh;

--
-- Name: dividend_full; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.dividend_full (
    "Column0" character varying(10),
    "Column1" timestamp(6) without time zone,
    "Column2" numeric(16,8)
);


ALTER TABLE external_data.dividend_full OWNER TO dwh;

--
-- Name: eos3_monitor; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.eos3_monitor (
    trading_firm_id character varying(9),
    account_name character varying(30),
    symbol character varying(150),
    exchange_id character varying(6),
    side character varying(1),
    total_orders_count integer,
    total_open_orders_count integer,
    total_open_qty integer,
    total_exec_qty integer,
    last_tarde_time character varying(25)
);


ALTER TABLE external_data.eos3_monitor OWNER TO dwh;

--
-- Name: eos_monitor; Type: TABLE; Schema: external_data; Owner: pragma_user
--

CREATE TABLE external_data.eos_monitor (
    trading_firm_id character varying(9),
    account_name character varying(30),
    symbol character varying(150),
    exchange_id character varying(6),
    side character varying(1),
    total_orders_count integer,
    total_open_orders_count integer,
    total_open_qty integer,
    total_exec_qty integer,
    last_tarde_time character varying(25)
);


ALTER TABLE external_data.eos_monitor OWNER TO pragma_user;

--
-- Name: eq_sec_type; Type: FOREIGN TABLE; Schema: external_data; Owner: dwh
--

CREATE FOREIGN TABLE external_data.eq_sec_type (
    symbol character varying(20),
    type character varying(20)
)
SERVER postgres_true_reversion_stats
OPTIONS (
    schema_name 'external_data',
    table_name 'eq_sec_type'
);


ALTER FOREIGN TABLE external_data.eq_sec_type OWNER TO dwh;

--
-- Name: etf_data; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.etf_data (
    ticker character varying(10) NOT NULL,
    company_name character varying(100),
    market_cap character varying(100),
    sector character varying(100)
);


ALTER TABLE external_data.etf_data OWNER TO dwh;

--
-- Name: f_box_street_executions; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.f_box_street_executions (
    create_date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character varying(1),
    order_status character varying(1),
    street_client_order_id character varying(256),
    street_orig_client_order_id character varying(256),
    street_order_id character varying(256),
    street_exec_id character varying(256),
    street_secondary_order_id character varying(256),
    street_orig_exec_id character varying(256),
    street_transact_time timestamp without time zone,
    street_sending_time timestamp without time zone,
    street_routed_time timestamp without time zone,
    target_location_id character varying(256),
    client_id character varying(256),
    clearing_optional_data character varying(256),
    parent_client_order_id character varying(256),
    parent_exec_id character varying(256),
    parent_orig_client_order_id character varying(256),
    parent_secondary_order_id character varying(256),
    parent_secondary_exec_id character varying(256),
    parent_create_date_id integer,
    street_account_name character varying(30),
    on_behalf_of_comp_id character varying(128),
    price_type character varying(64),
    exec_inst character varying(128),
    sender_comp_id character varying,
    side character(1),
    price numeric(12,4),
    order_qty integer
)
PARTITION BY RANGE (create_date_id);


ALTER TABLE external_data.f_box_street_executions OWNER TO dwh;

--
-- Name: f_cboe_street_executions; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.f_cboe_street_executions (
    create_date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character varying(1),
    order_status character varying(1),
    street_client_order_id character varying(256),
    street_orig_client_order_id character varying(256),
    street_order_id character varying(256),
    street_exec_id character varying(256),
    street_secondary_order_id character varying(256),
    street_orig_exec_id character varying(256),
    street_transact_time timestamp without time zone,
    street_sending_time timestamp without time zone,
    street_routed_time timestamp without time zone,
    target_location_id character varying(256),
    client_id character varying(256),
    clearing_optional_data character varying(256),
    parent_client_order_id character varying(256),
    parent_exec_id character varying(256),
    parent_orig_client_order_id character varying(256),
    parent_secondary_order_id character varying(256),
    parent_secondary_exec_id character varying(256),
    parent_create_date_id integer,
    street_account_name character varying(30),
    on_behalf_of_comp_id character varying(128),
    price_type character varying(64),
    exec_inst character varying(128)
)
PARTITION BY RANGE (create_date_id);


ALTER TABLE external_data.f_cboe_street_executions OWNER TO dwh;

--
-- Name: gtc_reconciliation; Type: TABLE; Schema: external_data; Owner: genesis2
--

CREATE TABLE external_data.gtc_reconciliation (
    reason character varying(256),
    sub_system_id character varying(50),
    client_order_id character varying(30),
    account_name character varying(50),
    order_status character varying(30),
    sender_comp_id character varying(30),
    client_id character varying(50),
    is_mleg bpchar,
    expiration_date_id integer,
    put_call bpchar,
    strike_price numeric,
    order_qty integer,
    side bpchar,
    security_type character varying(30),
    order_creation_date_id integer,
    ex_destination character varying(50),
    symbol_db character varying(30),
    symbol_log character varying(30),
    order_id character varying(50),
    date_id integer NOT NULL,
    db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data.gtc_reconciliation OWNER TO genesis2;

--
-- Name: load_batch; Type: TABLE; Schema: external_data; Owner: dhw_admin
--

CREATE TABLE external_data.load_batch (
    load_batch_id integer NOT NULL,
    file_name character varying,
    file_provider character varying,
    process_date_time timestamp without time zone,
    status character varying(2),
    rows_processed integer,
    process_end_date_time timestamp without time zone
);


ALTER TABLE external_data.load_batch OWNER TO dhw_admin;

--
-- Name: load_batch_load_batch_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dhw_admin
--

CREATE SEQUENCE external_data.load_batch_load_batch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_data.load_batch_load_batch_id_seq OWNER TO dhw_admin;

--
-- Name: load_batch_load_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: external_data; Owner: dhw_admin
--

ALTER SEQUENCE external_data.load_batch_load_batch_id_seq OWNED BY external_data.load_batch.load_batch_id;


--
-- Name: lp_nxp_stats; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.lp_nxp_stats (
    order_id character varying(36) NOT NULL,
    ofp_cross_order_id character varying(36),
    dma_redirect smallint,
    lpo_cross_order_id character varying(36),
    responded integer,
    trade_date date NOT NULL,
    price numeric(19,4),
    package_quantity integer,
    filled_price numeric(19,4),
    package_qty_filled integer,
    create_date_time timestamp without time zone,
    first_fill_date_time timestamp without time zone,
    ofp_qty_entered integer,
    ofp_qty_filled integer,
    cross_qty integer,
    cross_qty_filled integer,
    lpo_qty integer,
    lpo_qty_filled integer,
    action_lpo character varying(20),
    liquidity_providers character varying(50),
    ofp_login character varying(50),
    ofp_company character varying(100),
    lpo_login character varying(50),
    lpo_company character varying(50),
    is_spread integer,
    symbol_type character varying(20),
    tier character varying(20),
    cross_exchange character varying(20),
    symbol character varying(20),
    nbbo_bid numeric(19,4),
    nbbo_ask numeric(19,4),
    nbbo_bid_quantity integer,
    nbbo_ask_quantity integer,
    entitled numeric(19,4),
    marketability character varying(20),
    contracts_pi integer,
    total_dollar_improvement numeric(19,4),
    effective_width numeric(19,4),
    order_size character varying(20),
    live_entered integer,
    live_entitled numeric(19,4),
    live_filled integer,
    invested_filled numeric(19,4),
    invested_bid numeric(19,4),
    invested_ask numeric(19,4),
    market_width character varying(20),
    filled_orders integer,
    filled_orders_pi integer,
    price_improve numeric(19,4),
    liquidity_enhancement numeric(19,4),
    lpo_price numeric(19,4),
    date_id integer,
    side character(1),
    is_penny character(1),
    order_type character varying(20),
    completed_date_time timestamp without time zone,
    leg_count character(1),
    speed_ms integer
);


ALTER TABLE external_data.lp_nxp_stats OWNER TO dwh;

--
-- Name: money_out_full; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.money_out_full (
    ticker character varying(30),
    expiry character varying(60),
    trade_date character varying(60),
    smooth numeric(12,6),
    width numeric(12,6),
    alert integer,
    stock_price numeric(12,6),
    risk_free_rate character varying(60),
    yield_rate character varying(60),
    residual_yield_rate character varying(60),
    residual_rate_slope numeric(12,6),
    residual_r_2 numeric(12,6),
    confidence character varying(60),
    mwvol character varying(60),
    vol___100_delta character varying(60),
    vol___95_delta character varying(60),
    vol___90_delta character varying(60),
    vol___85_delta character varying(60),
    vol___80_delta character varying(60),
    vol___75_delta character varying(60),
    vol___70_delta character varying(60),
    vol___65_delta character varying(60),
    vol___60_delta character varying(60),
    vol___55_delta character varying(60),
    vol___50_delta character varying(60),
    vol___45_delta character varying(60),
    vol___40_delta character varying(60),
    vol___35_delta character varying(60),
    vol___30_delta character varying(60),
    vol___25_delta character varying(60),
    vol___20_delta character varying(60),
    vol___15_delta character varying(60),
    vol___10_delta character varying(60),
    vol___5_delta character varying(60),
    vol___0_delta character varying(60),
    type_flag integer,
    load_batch_id integer NOT NULL
);


ALTER TABLE external_data.money_out_full OWNER TO dwh;

--
-- Name: mpid_dictionary; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.mpid_dictionary (
    mpid_name character varying(4) NOT NULL,
    mpid_abbreviation character varying(100) NOT NULL
);


ALTER TABLE external_data.mpid_dictionary OWNER TO dwh;

--
-- Name: occ_member_directory; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.occ_member_directory (
    firm_num character(3) NOT NULL,
    firm_name character varying(80),
    equity_options boolean,
    index_options boolean,
    stock_loan_participant boolean,
    single_stock_futures boolean,
    commodity_options_and_futures_listed_on_cfe_elx_nfx boolean,
    treasury_options boolean,
    extended_trading_hours boolean
);


ALTER TABLE external_data.occ_member_directory OWNER TO dwh;

--
-- Name: occ_trade_data; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.occ_trade_data (
    trade_id bigint NOT NULL,
    date_id integer NOT NULL,
    rpt_id text,
    lastqty integer,
    lastpx numeric,
    sym character varying,
    matdt timestamp without time zone,
    strkpx numeric,
    exch character varying,
    transtyp character varying,
    cl_ord_id character varying(255),
    mlegrpttyp character varying,
    side character(1),
    trdid text,
    exchspeclinstr text,
    trade_record_id bigint,
    opposing_clear_mbr character varying(5),
    cmta_exec_gvup character varying(5),
    contra_give_cmta character varying(5),
    opposing_sub_account character varying(4),
    capacity character varying(1),
    contra_capacity character varying(1),
    customer_account_number character varying(255),
    possition_effect character varying,
    contra_secondary_order_id character varying(255),
    contra_secondary_exch_exec_id character varying(255)
)
PARTITION BY RANGE (date_id);


ALTER TABLE external_data.occ_trade_data OWNER TO dwh;

--
-- Name: COLUMN occ_trade_data.contra_secondary_exch_exec_id; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.occ_trade_data.contra_secondary_exch_exec_id IS 'secondary_exch_exec_id of the contraside. Based on trid  of the FIXML';


--
-- Name: occ_trade_data_matching_all; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.occ_trade_data_matching_all (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
)
PARTITION BY RANGE (date_id);


ALTER TABLE external_data.occ_trade_data_matching_all OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_matching_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dwh
--

CREATE SEQUENCE external_data.occ_trade_data_matching_all_matching_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_data.occ_trade_data_matching_all_matching_id_seq OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_matching_id_seq; Type: SEQUENCE OWNED BY; Schema: external_data; Owner: dwh
--

ALTER SEQUENCE external_data.occ_trade_data_matching_all_matching_id_seq OWNED BY external_data.occ_trade_data_matching_all.matching_id;


--
-- Name: occ_trade_data_trade_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dwh
--

CREATE SEQUENCE external_data.occ_trade_data_trade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_data.occ_trade_data_trade_id_seq OWNER TO dwh;

--
-- Name: occ_trade_data_trade_id_seq; Type: SEQUENCE OWNED BY; Schema: external_data; Owner: dwh
--

ALTER SEQUENCE external_data.occ_trade_data_trade_id_seq OWNED BY external_data.occ_trade_data.trade_id;


--
-- Name: occ_volume_trade_data; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.occ_volume_trade_data (
    quantity integer,
    underlying_symbol character varying(10),
    option_symbol character varying(10),
    account_type character varying(20),
    put_call character varying(4),
    exchange character varying(10),
    activity_date date,
    option_type character varying(3)
);


ALTER TABLE external_data.occ_volume_trade_data OWNER TO dwh;

--
-- Name: opt_master_detail_792; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.opt_master_detail_792 (
    master_id integer NOT NULL,
    source_id integer NOT NULL,
    trade_date date,
    client_number character varying(20),
    execution_source character varying(50),
    mapped_exch character varying(50),
    side character(1),
    quantity integer,
    underlying_symbol character varying(15),
    osi_symbol character varying(50),
    premium numeric(12,4),
    oc character(1),
    exch_acct_type character(1),
    opt_data character varying(50),
    cl_order_id character varying(255),
    cust_acct character varying(50),
    exch_opt_data character varying(50),
    occ_trade_id character varying(100),
    order_id character varying(255),
    report_id bigint,
    executing_broker character varying(10),
    mm_id character varying(10),
    cmta character varying(3),
    executing_firm character varying(3),
    product_category character varying(20),
    penny_pilot_flag character(1),
    liquidity character varying(5),
    execution_fee numeric(12,4),
    exch_fees_passed numeric(12,4),
    clrg_fee_passed numeric(12,4),
    external_occ_cust_acct character varying(50),
    external_occ_cl_order_id character varying(50),
    load_batch_id integer,
    date_id integer,
    trade_record_id integer,
    file_source character varying(10),
    trading_firm_id character varying(9),
    em_matching_logic smallint
);


ALTER TABLE external_data.opt_master_detail_792 OWNER TO dwh;

--
-- Name: opt_master_detail_792_old; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.opt_master_detail_792_old (
    master_id integer NOT NULL,
    source_id integer NOT NULL,
    trade_date date,
    client_number character varying(20),
    execution_source character varying(50),
    mapped_exch character varying(50),
    side character(1),
    quantity integer,
    underlying_symbol character varying(15),
    osi_symbol character varying(50),
    premium numeric(12,4),
    oc character(1),
    exch_acct_type character(1),
    opt_data character varying(50),
    cl_order_id character varying(255),
    cust_acct character varying(50),
    exch_opt_data character varying(50),
    occ_trade_id character varying(100),
    order_id character varying(255),
    report_id bigint,
    executing_broker character varying(10),
    mm_id character varying(10),
    cmta character varying(3),
    executing_firm character varying(3),
    product_category character varying(20),
    penny_pilot_flag character(1),
    liquidity character varying(5),
    execution_fee numeric(12,4),
    exch_fees_passed numeric(12,4),
    clrg_fee_passed numeric(12,4),
    external_occ_cust_acct character varying(50),
    external_occ_cl_order_id character varying(50),
    load_batch_id integer,
    date_id integer,
    trade_record_id integer
);


ALTER TABLE external_data.opt_master_detail_792_old OWNER TO dwh;

--
-- Name: opt_master_detail_792_test_vd; Type: FOREIGN TABLE; Schema: external_data; Owner: vdobriianskyi
--

CREATE FOREIGN TABLE external_data.opt_master_detail_792_test_vd (
    master_id integer NOT NULL,
    source_id integer NOT NULL,
    trade_date date,
    client_number character varying(20),
    execution_source character varying(50),
    mapped_exch character varying(50),
    side character(1),
    quantity integer,
    underlying_symbol character varying(15),
    osi_symbol character varying(50),
    premium numeric(12,4),
    oc character(1),
    exch_acct_type character(1),
    opt_data character varying(50),
    cl_order_id character varying(255),
    cust_acct character varying(50),
    exch_opt_data character varying(50),
    occ_trade_id character varying(100),
    order_id character varying(255),
    report_id bigint,
    executing_broker character varying(10),
    mm_id character varying(10),
    cmta character varying(3),
    executing_firm character varying(3),
    product_category character varying(20),
    penny_pilot_flag character(1),
    liquidity character varying(5),
    execution_fee numeric(12,4),
    exch_fees_passed numeric(12,4),
    clrg_fee_passed numeric(12,4),
    external_occ_cust_acct character varying(50),
    external_occ_cl_order_id character varying(50),
    load_batch_id integer,
    date_id integer,
    trade_record_id bigint,
    file_source character varying(10),
    trading_firm_id character varying(9)
)
SERVER big_data_prod
OPTIONS (
    schema_name 'external_data',
    table_name 'opt_master_detail_792'
);


ALTER FOREIGN TABLE external_data.opt_master_detail_792_test_vd OWNER TO vdobriianskyi;

--
-- Name: option_security_master; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.option_security_master (
    id bigint NOT NULL,
    option_symbol character varying(20),
    underlying_option_symbol character varying(20),
    underlying_stock_symbol character varying(20),
    cusip_number character varying(20),
    cycle_name character varying(20),
    option_type character varying(20),
    dual_exchange character varying(20),
    primary_code character varying(20),
    strike_price numeric(12,4),
    standard_strike_code character varying(20),
    call_code character varying(20),
    put_code character varying(20),
    month_code character varying(20),
    expiration_date timestamp without time zone,
    effective_date timestamp without time zone,
    contract_size numeric(12,4),
    is_adjusted smallint,
    exp_frequency character varying(20),
    strike_status smallint,
    last_updated timestamp without time zone,
    opra_17_call character varying(32),
    opra_17_put character varying(32),
    occ_21_call character varying(32),
    occ_21_put character varying(32),
    consolidated_opra_17_call character varying(32),
    consolidated_opra_17_put character varying(32),
    consolidated_occ_21_call character varying(32),
    consolidated_occ_21_put character varying(32),
    date_id integer
);


ALTER TABLE external_data.option_security_master OWNER TO dwh;

--
-- Name: orats_dividend_projection; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.orats_dividend_projection (
    date_id integer NOT NULL,
    symbol character varying(20) NOT NULL,
    n_dates smallint,
    dividend_projection character varying(255)
);


ALTER TABLE external_data.orats_dividend_projection OWNER TO dwh;

--
-- Name: orats_treasury_rate; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.orats_treasury_rate (
    date_id bigint NOT NULL,
    n_rates bigint,
    rates character varying(255)
);


ALTER TABLE external_data.orats_treasury_rate OWNER TO dwh;

--
-- Name: panorama; Type: TABLE; Schema: external_data; Owner: genesis2
--

CREATE TABLE external_data.panorama (
    n_strategy character varying(128),
    n_side character varying(128),
    n_symbol character varying(128),
    n_qty integer,
    n_qtydone integer,
    n_qtylive integer,
    n_shrsout integer,
    n_done numeric(5,2),
    n_limitpx numeric(12,4),
    n_avgpx numeric(12,4),
    n_price numeric(12,4),
    n_bbid numeric(12,4),
    n_bbidsz integer,
    n_bask numeric(12,4),
    n_basksz integer,
    n_povtarget numeric(5,2),
    n_minpov integer,
    n_maxpov integer,
    n_algominpov numeric,
    n_algomaxpov numeric,
    n_povcurrent numeric,
    n_lastpovcurrent numeric,
    n_poveligiblevolume integer,
    n_reseteligiblevolume integer,
    n_lastpovvolume integer,
    n_adaptpov numeric,
    n_adaptrate numeric,
    n_aggression integer,
    n_capturelevel integer,
    n_mustcomplete boolean,
    n_10b18 boolean,
    n_status character varying(128),
    n_timestarted time without time zone,
    n_tod time without time zone,
    n_arrivepx numeric(12,4),
    n_vwapsf numeric,
    n_vwapsf_usd numeric,
    n_mktvwapsf numeric,
    n_mktvwapsf_usd numeric,
    n_benchsf numeric,
    n_benchsf_usd numeric,
    n_taskvolume integer,
    n_vwap numeric,
    n_mktvwap numeric,
    n_povshortfall integer,
    n_maxpovexpleaves integer,
    n_advscale numeric,
    n_desiredquantityfromparent text,
    n_crosseffectiveqty text,
    n_crossdone text,
    n_openxqty integer,
    n_open numeric(12,2),
    n_effopenqty integer,
    n_openxdone integer,
    n_closexqty integer,
    n_effcloseqty integer,
    n_closexdone integer,
    n_close numeric(12,2),
    n_closeaggression integer,
    n_effstarttime time without time zone,
    n_wouldeffectivepx numeric(12,4),
    n_wouldeffectiveqty integer,
    n_woulddone integer,
    n_discabove integer,
    n_discbelow integer,
    n_statusmsg character varying(128),
    n_taskblacklist character varying(2048),
    n_dquotedest character varying(128),
    n_stime time without time zone,
    n_etime time without time zone,
    n_subid character varying(128),
    n_taskid character varying(128),
    n_note character varying(128),
    n_acct character varying(128),
    n_sellshortrestricted boolean,
    n_trajfinishtime time without time zone,
    n_tickpilotgroup character varying(128),
    n_hardminqty integer,
    n_priceexoddlots numeric(12,4),
    date_id integer,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data.panorama OWNER TO genesis2;

--
-- Name: panorama_uat; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.panorama_uat (
    n_strategy character varying(128),
    n_side character varying(128),
    n_symbol character varying(128),
    n_qty integer,
    n_qtydone integer,
    n_qtylive integer,
    n_shrsout integer,
    n_done numeric(5,2),
    n_limitpx numeric(12,4),
    n_avgpx numeric(12,4),
    n_price numeric(12,4),
    n_bbid numeric(12,4),
    n_bbidsz integer,
    n_bask numeric(12,4),
    n_basksz integer,
    n_povtarget numeric(5,2),
    n_minpov integer,
    n_maxpov integer,
    n_algominpov numeric,
    n_algomaxpov numeric,
    n_povcurrent numeric,
    n_lastpovcurrent numeric,
    n_poveligiblevolume integer,
    n_reseteligiblevolume integer,
    n_lastpovvolume integer,
    n_adaptpov numeric,
    n_adaptrate numeric,
    n_aggression integer,
    n_capturelevel integer,
    n_mustcomplete boolean,
    n_10b18 boolean,
    n_status character varying(128),
    n_timestarted time without time zone,
    n_tod time without time zone,
    n_arrivepx numeric(12,4),
    n_vwapsf numeric,
    n_vwapsf_usd numeric,
    n_mktvwapsf numeric,
    n_mktvwapsf_usd numeric,
    n_benchsf numeric,
    n_benchsf_usd numeric,
    n_taskvolume integer,
    n_vwap numeric,
    n_mktvwap numeric,
    n_povshortfall integer,
    n_maxpovexpleaves integer,
    n_advscale numeric,
    n_desiredquantityfromparent text,
    n_crosseffectiveqty text,
    n_crossdone text,
    n_openxqty integer,
    n_open numeric(12,2),
    n_effopenqty integer,
    n_openxdone integer,
    n_closexqty integer,
    n_effcloseqty integer,
    n_closexdone integer,
    n_close numeric(12,2),
    n_closeaggression integer,
    n_effstarttime time without time zone,
    n_wouldeffectivepx numeric(12,4),
    n_wouldeffectiveqty integer,
    n_woulddone integer,
    n_discabove integer,
    n_discbelow integer,
    n_statusmsg character varying(128),
    n_taskblacklist character varying(2048),
    n_dquotedest character varying(128),
    n_stime time without time zone,
    n_etime time without time zone,
    n_subid character varying(128),
    n_taskid character varying(128),
    n_note character varying(128),
    n_acct character varying(128),
    n_sellshortrestricted boolean,
    n_trajfinishtime time without time zone,
    n_tickpilotgroup character varying(128),
    n_hardminqty integer,
    n_priceexoddlots numeric(12,4),
    date_id integer,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    n_cltaskid text,
    n_estimatedclosevolume integer
);


ALTER TABLE external_data.panorama_uat OWNER TO dwh;

--
-- Name: panorama_ui; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.panorama_ui (
    n_strategy character varying(128),
    n_side character varying(128),
    n_symbol character varying(128),
    n_qty integer,
    n_qtydone integer,
    n_qtylive integer,
    n_shrsout integer,
    n_done numeric(5,2),
    n_limitpx numeric(12,4),
    n_avgpx numeric(12,4),
    n_price numeric(12,4),
    n_bbid numeric(12,4),
    n_bbidsz integer,
    n_bask numeric(12,4),
    n_basksz integer,
    n_povtarget numeric(5,2),
    n_minpov integer,
    n_maxpov integer,
    n_algominpov numeric,
    n_algomaxpov numeric,
    n_povcurrent numeric,
    n_lastpovcurrent numeric,
    n_poveligiblevolume integer,
    n_reseteligiblevolume integer,
    n_lastpovvolume integer,
    n_adaptpov numeric,
    n_adaptrate numeric,
    n_aggression integer,
    n_capturelevel integer,
    n_mustcomplete boolean,
    n_10b18 boolean,
    n_status character varying(128),
    n_timestarted time without time zone,
    n_tod time without time zone,
    n_arrivepx numeric(12,4),
    n_vwapsf numeric,
    n_vwapsf_usd numeric,
    n_mktvwapsf numeric,
    n_mktvwapsf_usd numeric,
    n_benchsf numeric,
    n_benchsf_usd numeric,
    n_taskvolume integer,
    n_vwap numeric,
    n_mktvwap numeric,
    n_povshortfall integer,
    n_maxpovexpleaves integer,
    n_advscale numeric,
    n_desiredquantityfromparent text,
    n_crosseffectiveqty text,
    n_crossdone text,
    n_openxqty integer,
    n_open numeric(12,2),
    n_effopenqty integer,
    n_openxdone integer,
    n_closexqty integer,
    n_effcloseqty integer,
    n_closexdone integer,
    n_close numeric(12,2),
    n_closeaggression integer,
    n_effstarttime time without time zone,
    n_wouldeffectivepx numeric(12,4),
    n_wouldeffectiveqty integer,
    n_woulddone integer,
    n_discabove integer,
    n_discbelow integer,
    n_statusmsg character varying(128),
    n_taskblacklist character varying(2048),
    n_dquotedest character varying(128),
    n_stime time without time zone,
    n_etime time without time zone,
    n_subid character varying(128),
    n_taskid character varying(128),
    n_note character varying(128),
    n_acct character varying(128),
    n_sellshortrestricted boolean,
    n_trajfinishtime time without time zone,
    n_tickpilotgroup character varying(128),
    n_hardminqty integer,
    n_priceexoddlots numeric(12,4),
    date_id integer NOT NULL,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    n_cltaskid text NOT NULL,
    n_estimatedclosevolume integer,
    f_check_sum text
);


ALTER TABLE external_data.panorama_ui OWNER TO dwh;

--
-- Name: pov_block_size_limit_import; Type: TABLE; Schema: external_data; Owner: dhw_admin
--

CREATE TABLE external_data.pov_block_size_limit_import (
    symbol character varying(10),
    size integer,
    date_id numeric(8,0),
    load_batch_id integer
);


ALTER TABLE external_data.pov_block_size_limit_import OWNER TO dhw_admin;

--
-- Name: security_master_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dwh
--

ALTER TABLE external_data.option_security_master ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME external_data.security_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: smf_data; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.smf_data (
    activ_symbol character varying(32) NOT NULL,
    close_px_prev double precision,
    security_type character varying(32),
    implied_liquidity bigint,
    sector character varying(32),
    lot_size integer,
    volume_20d double precision,
    volume_5d double precision,
    volume_prev integer,
    volume_today integer,
    spread_pct double precision,
    volatility_30d double precision,
    beta double precision,
    tick_size double precision,
    eps double precision,
    dividend_yield double precision,
    fund_type character varying(32),
    cusip character varying(9),
    sedol character varying(7),
    isin character varying(12),
    market_cap double precision,
    open_auction_volume_5d integer,
    close_auction_volume_5d integer,
    open_auction_volume_today integer,
    close_auction_volume_today integer,
    open_px_today double precision,
    close_px_today double precision,
    company_name character varying(255),
    date_id integer
);


ALTER TABLE external_data.smf_data OWNER TO dwh;

--
-- Name: COLUMN smf_data.close_px_prev; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.close_px_prev IS 'Price of yesterday''s last trade. This field doesn''t follow financial day logic, it includes holiday for day count.';


--
-- Name: COLUMN smf_data.security_type; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.security_type IS 'Description of the specific instrument type within its market sector.';


--
-- Name: COLUMN smf_data.implied_liquidity; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.implied_liquidity IS 'ETF Implied liquidity is a representation of how many shares can potentially be traded daily in an ETF as portrayed by the creation unit.
This is defined as the smallest value of the IDTS (Implied Daily Tradable Shares) for each holding in the creation unit.';


--
-- Name: COLUMN smf_data.sector; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.sector IS 'A text description indicating GICS sector classification. GICS (Global Industry Classification Standard) is an industry classification standard developed by MSCI in collaboration with Standard & Poors (S&P).
The GICS classification assigns a sector name to each company according to its principal business activity.';


--
-- Name: COLUMN smf_data.lot_size; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.lot_size IS 'Minimum number of shares of stock that can be purchased without incurring a larger fee. Also known as a board lot. Anything other than the round lot size is considered an odd lot.';


--
-- Name: COLUMN smf_data.volume_20d; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.volume_20d IS 'Number of shares traded on average for the past 20 trading days. The average is calculated based on the total volume over the last 20 trading days divided by 20.
The end date for past 20 days is always the prior business day.';


--
-- Name: COLUMN smf_data.volume_5d; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.volume_5d IS 'Number of shares traded on average for the past five trading days. The average is calculated based on the total volume over the last five trading days divided by five.
The end date for past five days is always the prior business day.';


--
-- Name: COLUMN smf_data.volume_prev; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.volume_prev IS 'Total volume for the last trading day prior to the current one.';


--
-- Name: COLUMN smf_data.volume_today; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.volume_today IS 'Total number of shares traded on a security on the current day. If the security has not traded, then it is the total number of shares from the last day the security traded.
If an exchange sends official closing price without a volume, the return will be ''0''.';


--
-- Name: COLUMN smf_data.spread_pct; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.spread_pct IS 'Average of all bid/ask spreads taken as a percentage of the mid price.
The bid/ask points used for the computation correspond to the quotes received for the period of five days ending in the latest completed trading day.';


--
-- Name: COLUMN smf_data.volatility_30d; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.volatility_30d IS 'A measure of the risk of price moves for a security calculated from the standard deviation of day to day logarithmic historical price changes.
The 30-day price volatility equals the annualized standard deviation of the relative price change for the 30 most recent trading days closing price, expressed as a percentage.';


--
-- Name: COLUMN smf_data.beta; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.beta IS 'Estimate of a security''s future beta. This is an adjusted beta derived from the past two years of weekly data, but modified by the assumption that a security''s beta moves toward the market average over time.
The formula used to adjust beta is : Adjusted Beta = (0.66666) * Raw Beta + (0.33333) * 1.0';


--
-- Name: COLUMN smf_data.tick_size; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.tick_size IS 'Reference for the security, where the tick size is determined on the basis of a reference price defined as being the Last Trade/Last Price.
For securities subject to a dynamic tick size, the tick size corresponds to the price band in which the Last Trade/Last Price falls.';


--
-- Name: COLUMN smf_data.eps; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.eps IS 'Earnings Per Share (EPS Adjusted) estimate returns Earnings Per Share from Continuing Operations, which may exclude the effects of one-time and extraordinary gains/losses.
The EPS GAAP estimate returns Reported Earnings Per Share (Before Extraordinary Items OR Bottom Line).';


--
-- Name: COLUMN smf_data.dividend_yield; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.dividend_yield IS 'Ratio calculated by dividing the dividend per share (DPS) estimate based on the current fiscal year provided by the requested firm/broker by the current price of the security.';


--
-- Name: COLUMN smf_data.fund_type; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.fund_type IS 'Broad asset sector the fund will invest in as stated in the prospectus. Bloomberg asset classes include: equity, fixed income, mixed allocation, money market, real estate, commodity, specialty, private equity and alternative investment.';


--
-- Name: COLUMN smf_data.cusip; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.cusip IS 'Security identification number for the U.S. and Canada. The Committee on Uniform Security Identification Procedures (CUSIP) number consists of  nine alpha-numeric characters.
The first six characters identify the issuer, the following two identify the issue, and the final character is a check digit.';


--
-- Name: COLUMN smf_data.sedol; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.sedol IS 'Stock Exchange Daily Official List number (SEDOL). This SEDOL is associated with the country listed in the SEDOL1 ISO Country.
This does not include any Sedol FMQs.';


--
-- Name: COLUMN smf_data.isin; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.isin IS 'The International Securities Identification Number (ISIN) is a twelve-character number assigned by the local national numbering agency.';


--
-- Name: COLUMN smf_data.market_cap; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.market_cap IS 'Total current market value of all of a company''s outstanding shares stated in the pricing currency. Capitalization is a measure of corporate size.
Current market capitalization is calculated as: Current Shares Outstanding * Last Price';


--
-- Name: COLUMN smf_data.open_auction_volume_5d; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.open_auction_volume_5d IS 'Average open auction volume across five days (end date default value is latest completed trading day). This is only available for select exchanges that have auctions as a feature of their trading system.
Field calculation is based on the average of the end of day value of Official Open Auction Volume.';


--
-- Name: COLUMN smf_data.close_auction_volume_5d; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.close_auction_volume_5d IS 'Average close auction volume across five days (end date default value is latest completed trading day). This is only available for select exchanges that have auctions as a feature of their trading system.
Field calculation is based on the average of the end of day value of Official Close Auction Volume.';


--
-- Name: COLUMN smf_data.open_auction_volume_today; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.open_auction_volume_today IS 'Accumulated volume of all on-book executions that arise from a scheduled opening auction call trading phase on the execution venue for the security on the referenced trading day.
This volume excludes executions arising from any other type of auction call.';


--
-- Name: COLUMN smf_data.close_auction_volume_today; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.close_auction_volume_today IS 'Accumulated volume of all on-book executions that arise from a scheduled closing auction call trading phase on the execution venue for the security on the referenced trading day.
This volume excludes executions arising from any other type of auction call.';


--
-- Name: COLUMN smf_data.open_px_today; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.open_px_today IS 'Official open auction price represents the price at which all orders had been executed upon conclusion of the opening auction call trading phase.';


--
-- Name: COLUMN smf_data.close_px_today; Type: COMMENT; Schema: external_data; Owner: dwh
--

COMMENT ON COLUMN external_data.smf_data.close_px_today IS 'The Official Close is an exchange-calculated and published closing price.
Depending on the methodology that is used by the exchange, the closing price may differ from the last traded price.';


--
-- Name: sp500_constituent; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.sp500_constituent (
    symbol character varying(32) NOT NULL,
    company_name character varying(100),
    isin character varying(12),
    cusip character varying(9),
    date_id integer
);


ALTER TABLE external_data.sp500_constituent OWNER TO dwh;

--
-- Name: trade_halt; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.trade_halt (
    id integer NOT NULL,
    title character varying(100),
    pub_date character varying,
    issue_symbol character varying,
    issue_name character varying,
    mkt character varying,
    reason_code character varying,
    pause_threshold_price character varying,
    halt_date date,
    halt_time time without time zone,
    resumption_date timestamp without time zone,
    resumption_quote_time time without time zone,
    resumption_trade_time timestamp without time zone,
    date_id integer,
    pg_create_time timestamp without time zone DEFAULT now()
);


ALTER TABLE external_data.trade_halt OWNER TO dwh;

--
-- Name: trade_halt_id_seq; Type: SEQUENCE; Schema: external_data; Owner: dwh
--

CREATE SEQUENCE external_data.trade_halt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_data.trade_halt_id_seq OWNER TO dwh;

--
-- Name: trade_halt_id_seq; Type: SEQUENCE OWNED BY; Schema: external_data; Owner: dwh
--

ALTER SEQUENCE external_data.trade_halt_id_seq OWNED BY external_data.trade_halt.id;


--
-- Name: us_option_root; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.us_option_root (
    last_update_date date,
    permission_id bigint,
    record_status bigint,
    update_id bigint,
    cash_per_contract numeric,
    contract_multiplier integer,
    contract_type smallint,
    country_code character varying,
    currency character varying(50),
    display_denominator character varying,
    exercise_style character varying(20),
    name character varying(100),
    shares_per_contract bigint,
    tick_size numeric,
    context character varying(50),
    create_date date,
    entity_type integer,
    reset_date character varying(50),
    symbol character varying(50),
    underlying_symbol character varying(50),
    contract_size integer,
    minimum_tick numeric,
    trading_day_start_time time without time zone,
    trading_day_end_time time without time zone,
    has_deliverables character varying(20),
    settlement_allocation integer,
    settlement_type character varying(20),
    expiration_date_list character varying,
    strike_price_list character varying,
    delivery_method character varying,
    currency_multiplier character varying(20),
    cash_in_lieu_settlement_amount numeric,
    cash_in_lieu_settlement_shares numeric,
    cash numeric,
    option_deliverables_description character varying,
    tick_rule_symbol character varying(20),
    has_extended_trading_hours character varying,
    file_source_name character varying(100)
);


ALTER TABLE external_data.us_option_root OWNER TO dwh;

--
-- Name: ws_corporate_action; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.ws_corporate_action (
    date_id integer NOT NULL,
    event_class character varying(25) NOT NULL,
    event_body jsonb,
    pg_db_update_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data.ws_corporate_action OWNER TO dwh;

--
-- Name: ws_corporate_action_conf; Type: TABLE; Schema: external_data; Owner: dwh
--

CREATE TABLE external_data.ws_corporate_action_conf (
    event_class character varying(25) NOT NULL,
    exent_description character varying(100),
    period smallint,
    is_active boolean
);


ALTER TABLE external_data.ws_corporate_action_conf OWNER TO dwh;

--
-- Name: activ_ohlc_201901; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201901 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201901 OWNER TO dwh;

--
-- Name: activ_ohlc_201902; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201902 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201902 OWNER TO dwh;

--
-- Name: activ_ohlc_201903; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201903 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201903 OWNER TO dwh;

--
-- Name: activ_ohlc_201904; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201904 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201904 OWNER TO dwh;

--
-- Name: activ_ohlc_201905; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201905 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201905 OWNER TO dwh;

--
-- Name: activ_ohlc_201906; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201906 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201906 OWNER TO dwh;

--
-- Name: activ_ohlc_201907; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201907 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201907 OWNER TO dwh;

--
-- Name: activ_ohlc_201908; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201908 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201908 OWNER TO dwh;

--
-- Name: activ_ohlc_201909; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201909 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201909 OWNER TO dwh;

--
-- Name: activ_ohlc_201910; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201910 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201910 OWNER TO dwh;

--
-- Name: activ_ohlc_201911; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201911 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201911 OWNER TO dwh;

--
-- Name: activ_ohlc_201912; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_ohlc_201912 (
    activ_symbol character varying(30) NOT NULL,
    asof_date_id integer NOT NULL,
    date_id integer NOT NULL,
    open_price numeric,
    high_price numeric,
    low_price numeric,
    close_price numeric,
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE external_data_partitions.activ_ohlc_201912 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20190928; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20190928 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time without time zone,
    bid_exchange character varying(10),
    ask_time time without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(10),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20190928 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20210301; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20210301 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20210301 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20210302; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20210302 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20210302 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240325; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240325 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240325 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240326; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240326 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240326 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240327; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240327 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240327 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240328; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240328 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240328 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240329; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240329 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240329 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240401; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240401 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240401 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240402; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240402 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240402 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240403; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240403 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240403 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240404; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240404 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240404 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240405; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240405 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240405 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240408; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240408 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240408 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240409; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240409 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240409 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240410; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240410 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240410 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240411; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240411 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240411 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240412; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240412 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240412 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240415; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240415 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240415 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240416; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240416 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240416 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240417; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240417 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240417 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240418; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240418 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240418 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240419; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240419 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240419 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240422; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240422 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240422 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240423; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240423 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240423 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240424; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240424 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240424 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240425; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240425 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240425 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240426; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240426 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240426 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240429; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240429 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240429 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240430; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240430 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240430 OWNER TO dwh;

--
-- Name: activ_us_equity_option_20240501; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.activ_us_equity_option_20240501 (
    permission_id integer,
    state integer,
    bid_condition character varying(5),
    record_status integer,
    update_id integer,
    bid_size integer,
    bid double precision,
    bid_time time(3) without time zone,
    bid_exchange character varying(10),
    ask_time time(3) without time zone,
    ask_condition character varying(10),
    last_update_date date,
    ask_size integer,
    ask double precision,
    ask_exchange character varying(10),
    quote_date date,
    previous_close double precision,
    option_type character(1),
    create_date date,
    trade_size integer,
    trade double precision,
    trade_exchange character varying(10),
    trade_date date,
    open double precision,
    expiration_type integer,
    close_date date,
    cumulative_value double precision,
    trade_id character varying(20),
    trade_high double precision,
    entity_type integer,
    close_status integer,
    cumulative_price double precision,
    trade_time time(3) without time zone,
    previous_trading_date date,
    trade_low double precision,
    closing_quote_date date,
    trade_count integer,
    previous_trade_time time(3) without time zone,
    reset_date date,
    close double precision,
    previous_quote_date date,
    cumulative_volume integer,
    closing_bid double precision,
    previous_open double precision,
    closing_bid_exchange character varying(5),
    trade_correction_time time(3) without time zone,
    closing_ask double precision,
    trade_condition character varying(10),
    previous_trade_high double precision,
    close_cumulative_volume_date date,
    strike_price double precision,
    previous_ask double precision,
    open_exchange character varying(10),
    previous_trade_low double precision,
    close_cumulative_volume_status integer,
    trade_id_cancel character varying(10),
    net_change double precision,
    life_time_high double precision,
    close_cumulative_value_tatus integer,
    mic character varying(10),
    previous_net_change double precision,
    trade_low_time time(3) without time zone,
    life_time_low double precision,
    close_cumulative_volume integer,
    percent_change double precision,
    trade_id_original character varying(10),
    "close_cumulative_vValue" double precision,
    trade_high_time time(3) without time zone,
    trade_correction_date date,
    trade_id_corrected character varying(10),
    previous_cumulative_volume integer,
    previous_bid double precision,
    trade_high_exchange character varying(10),
    open_interest_date date,
    local_code character varying(21),
    trade_low_exchange character varying(10),
    previous_open_interest_date date,
    context integer,
    close_exchange character varying(10),
    previous_cumulative_value double precision,
    open_time time(3) without time zone,
    life_time_high_date date,
    open_interest integer,
    closing_ask_exchange character varying(2),
    previous_cumulative_volume_date date,
    previous_percent_change double precision,
    trade_high_condition character varying(10),
    life_time_low_date date,
    previous_open_interest integer,
    close_condition character varying(5),
    previous_close_date date,
    previous_cumulative_price double precision,
    trade_low_condition character varying(10),
    expiration_date date,
    open_condition character varying(10),
    symbol character varying(20),
    load_date_id integer DEFAULT (to_char(now(), 'YYYYMMDD'::text))::integer,
    load_batch_id bigint,
    CONSTRAINT chk_activ_us_equity_option_20240202 CHECK ((load_date_id = 20240202))
);


ALTER TABLE external_data_partitions.activ_us_equity_option_20240501 OWNER TO dwh;

--
-- Name: f_box_street_executions_202108; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.f_box_street_executions_202108 (
    create_date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character varying(1),
    order_status character varying(1),
    street_client_order_id character varying(256),
    street_orig_client_order_id character varying(256),
    street_order_id character varying(256),
    street_exec_id character varying(256),
    street_secondary_order_id character varying(256),
    street_orig_exec_id character varying(256),
    street_transact_time timestamp without time zone,
    street_sending_time timestamp without time zone,
    street_routed_time timestamp without time zone,
    target_location_id character varying(256),
    client_id character varying(256),
    clearing_optional_data character varying(256),
    parent_client_order_id character varying(256),
    parent_exec_id character varying(256),
    parent_orig_client_order_id character varying(256),
    parent_secondary_order_id character varying(256),
    parent_secondary_exec_id character varying(256),
    parent_create_date_id integer,
    street_account_name character varying(30),
    on_behalf_of_comp_id character varying(128),
    price_type character varying(64),
    exec_inst character varying(128),
    sender_comp_id character varying,
    side character(1),
    price numeric(12,4),
    order_qty integer
);


ALTER TABLE external_data_partitions.f_box_street_executions_202108 OWNER TO dwh;

--
-- Name: f_cboe_street_executions_202108; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.f_cboe_street_executions_202108 (
    create_date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character varying(1),
    order_status character varying(1),
    street_client_order_id character varying(256),
    street_orig_client_order_id character varying(256),
    street_order_id character varying(256),
    street_exec_id character varying(256),
    street_secondary_order_id character varying(256),
    street_orig_exec_id character varying(256),
    street_transact_time timestamp without time zone,
    street_sending_time timestamp without time zone,
    street_routed_time timestamp without time zone,
    target_location_id character varying(256),
    client_id character varying(256),
    clearing_optional_data character varying(256),
    parent_client_order_id character varying(256),
    parent_exec_id character varying(256),
    parent_orig_client_order_id character varying(256),
    parent_secondary_order_id character varying(256),
    parent_secondary_exec_id character varying(256),
    parent_create_date_id integer,
    street_account_name character varying(30),
    on_behalf_of_comp_id character varying(128),
    price_type character varying(64),
    exec_inst character varying(128)
);


ALTER TABLE external_data_partitions.f_cboe_street_executions_202108 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240229; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240229 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240229 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240301; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240301 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240301 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240304; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240304 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240304 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240305; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240305 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240305 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240306; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240306 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240306 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240307; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240307 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240307 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240308; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240308 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240308 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240311; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240311 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240311 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240312; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240312 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240312 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240313; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240313 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240313 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240314; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240314 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240314 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240315; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240315 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240315 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240318; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240318 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240318 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240319; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240319 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240319 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240320; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240320 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240320 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240321; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240321 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240321 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240322; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240322 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240322 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240325; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240325 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240325 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240326; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240326 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240326 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240327; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240327 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240327 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240328; Type: TABLE; Schema: external_data_partitions; Owner: vpylypets
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240328 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240328 OWNER TO vpylypets;

--
-- Name: occ_trade_data_matching_all_20240329; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240329 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240329 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240401; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240401 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240401 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240402; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240402 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240402 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240403; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240403 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240403 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240404; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240404 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240404 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240405; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240405 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240405 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240408; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240408 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240408 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240409; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240409 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240409 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240410; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240410 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240410 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240411; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240411 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240411 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240412; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240412 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240412 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240415; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240415 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240415 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240416; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240416 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240416 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240417; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240417 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240417 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240418; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240418 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240418 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240419; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240419 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240419 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240422; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240422 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240422 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240423; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240423 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240423 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240424; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240424 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240424 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240425; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240425 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240425 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240426; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240426 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240426 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240429; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240429 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240429 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240430; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240430 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240430 OWNER TO dwh;

--
-- Name: occ_trade_data_matching_all_20240501; Type: TABLE; Schema: external_data_partitions; Owner: dwh
--

CREATE TABLE external_data_partitions.occ_trade_data_matching_all_20240501 (
    date_id integer NOT NULL,
    rpt_id character varying NOT NULL,
    trade_record_id integer NOT NULL,
    matching_id bigint DEFAULT nextval('external_data.occ_trade_data_matching_all_matching_id_seq'::regclass) NOT NULL,
    trade_id bigint,
    is_procesed boolean DEFAULT false,
    matching_logic smallint
);


ALTER TABLE external_data_partitions.occ_trade_data_matching_all_20240501 OWNER TO dwh;

--
-- Name: pov_block_size_limit_import_201606; Type: TABLE; Schema: external_data_partitions; Owner: dhw_admin
--

CREATE TABLE external_data_partitions.pov_block_size_limit_import_201606 (
    CONSTRAINT chk_pov_block_size_limit_import_201606 CHECK (((date_id >= (20160601)::numeric) AND (date_id < (20160701)::numeric)))
)
INHERITS (external_data.pov_block_size_limit_import);


ALTER TABLE external_data_partitions.pov_block_size_limit_import_201606 OWNER TO dhw_admin;

--
-- Name: pov_block_size_limit_import_201607; Type: TABLE; Schema: external_data_partitions; Owner: dhw_admin
--

CREATE TABLE external_data_partitions.pov_block_size_limit_import_201607 (
    CONSTRAINT chk_pov_block_size_limit_import_201607 CHECK (((date_id >= (20160701)::numeric) AND (date_id < (20160801)::numeric)))
)
INHERITS (external_data.pov_block_size_limit_import);


ALTER TABLE external_data_partitions.pov_block_size_limit_import_201607 OWNER TO dhw_admin;

--
-- Name: pov_block_size_limit_import_201608; Type: TABLE; Schema: external_data_partitions; Owner: dhw_admin
--

CREATE TABLE external_data_partitions.pov_block_size_limit_import_201608 (
    CONSTRAINT chk_pov_block_size_limit_import_201608 CHECK (((date_id >= (20160801)::numeric) AND (date_id < (20160901)::numeric)))
)
INHERITS (external_data.pov_block_size_limit_import);


ALTER TABLE external_data_partitions.pov_block_size_limit_import_201608 OWNER TO dhw_admin;

--
-- Name: pov_block_size_limit_import_201609; Type: TABLE; Schema: external_data_partitions; Owner: dhw_admin
--

CREATE TABLE external_data_partitions.pov_block_size_limit_import_201609 (
    CONSTRAINT chk_pov_block_size_limit_import_201609 CHECK (((date_id >= (20160901)::numeric) AND (date_id < (20161001)::numeric)))
)
INHERITS (external_data.pov_block_size_limit_import);


ALTER TABLE external_data_partitions.pov_block_size_limit_import_201609 OWNER TO dhw_admin;

--
-- Name: pov_block_size_limit_import_201610; Type: TABLE; Schema: external_data_partitions; Owner: dhw_admin
--

CREATE TABLE external_data_partitions.pov_block_size_limit_import_201610 (
    CONSTRAINT chk_pov_block_size_limit_import_201610 CHECK (((date_id >= (20161001)::numeric) AND (date_id < (20161101)::numeric)))
)
INHERITS (external_data.pov_block_size_limit_import);


ALTER TABLE external_data_partitions.pov_block_size_limit_import_201610 OWNER TO dhw_admin;

--
-- Name: pov_block_size_limit_import_201611; Type: TABLE; Schema: external_data_partitions; Owner: dhw_admin
--

CREATE TABLE external_data_partitions.pov_block_size_limit_import_201611 (
    CONSTRAINT chk_pov_block_size_limit_import_201611 CHECK (((date_id >= (20161101)::numeric) AND (date_id < (20161201)::numeric)))
)
INHERITS (external_data.pov_block_size_limit_import);


ALTER TABLE external_data_partitions.pov_block_size_limit_import_201611 OWNER TO dhw_admin;

--
-- Name: fix_message_json; Type: TABLE; Schema: fix_capture; Owner: dwh
--

CREATE TABLE fix_capture.fix_message_json (
    fix_message_id bigint NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
)
PARTITION BY RANGE (date_id);


ALTER TABLE fix_capture.fix_message_json OWNER TO dwh;

--
-- Name: fix_message_json_fix_message_id_seq; Type: SEQUENCE; Schema: fix_capture; Owner: dwh
--

CREATE SEQUENCE fix_capture.fix_message_json_fix_message_id_seq
    START WITH 1
    INCREMENT BY -1
    MINVALUE -9223372036854775807
    MAXVALUE 1
    CACHE 1;


ALTER SEQUENCE fix_capture.fix_message_json_fix_message_id_seq OWNER TO dwh;

--
-- Name: fix_message_json_fix_message_id_seq; Type: SEQUENCE OWNED BY; Schema: fix_capture; Owner: dwh
--

ALTER SEQUENCE fix_capture.fix_message_json_fix_message_id_seq OWNED BY fix_capture.fix_message_json.fix_message_id;


--
-- Name: fix_message_json_20240101; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240101 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240101 OWNER TO dwh;

--
-- Name: fix_message_json_20240102; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240102 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240102 OWNER TO dwh;

--
-- Name: fix_message_json_20240103; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240103 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240103 OWNER TO dwh;

--
-- Name: fix_message_json_20240104; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240104 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240104 OWNER TO dwh;

--
-- Name: fix_message_json_20240105; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240105 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240105 OWNER TO dwh;

--
-- Name: fix_message_json_20240108; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240108 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240108 OWNER TO dwh;

--
-- Name: fix_message_json_20240109; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240109 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240109 OWNER TO dwh;

--
-- Name: fix_message_json_20240110; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240110 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240110 OWNER TO dwh;

--
-- Name: fix_message_json_20240111; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240111 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240111 OWNER TO dwh;

--
-- Name: fix_message_json_20240112; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240112 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240112 OWNER TO dwh;

--
-- Name: fix_message_json_20240115; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240115 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240115 OWNER TO dwh;

--
-- Name: fix_message_json_20240116; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240116 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240116 OWNER TO dwh;

--
-- Name: fix_message_json_20240117; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240117 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240117 OWNER TO dwh;

--
-- Name: fix_message_json_20240118; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240118 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240118 OWNER TO dwh;

--
-- Name: fix_message_json_20240119; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240119 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240119 OWNER TO dwh;

--
-- Name: fix_message_json_20240122; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240122 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240122 OWNER TO dwh;

--
-- Name: fix_message_json_20240123; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240123 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240123 OWNER TO dwh;

--
-- Name: fix_message_json_20240124; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240124 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240124 OWNER TO dwh;

--
-- Name: fix_message_json_20240125; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240125 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240125 OWNER TO dwh;

--
-- Name: fix_message_json_20240126; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240126 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240126 OWNER TO dwh;

--
-- Name: fix_message_json_20240129; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240129 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240129 OWNER TO dwh;

--
-- Name: fix_message_json_20240130; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240130 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240130 OWNER TO dwh;

--
-- Name: fix_message_json_20240131; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240131 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240131 OWNER TO dwh;

--
-- Name: fix_message_json_20240201; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240201 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240201 OWNER TO dwh;

--
-- Name: fix_message_json_20240202; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240202 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240202 OWNER TO dwh;

--
-- Name: fix_message_json_20240205; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240205 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240205 OWNER TO dwh;

--
-- Name: fix_message_json_20240206; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240206 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240206 OWNER TO dwh;

--
-- Name: fix_message_json_20240207; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240207 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240207 OWNER TO dwh;

--
-- Name: fix_message_json_20240208; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240208 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240208 OWNER TO dwh;

--
-- Name: fix_message_json_20240209; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240209 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240209 OWNER TO dwh;

--
-- Name: fix_message_json_20240212; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240212 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240212 OWNER TO dwh;

--
-- Name: fix_message_json_20240213; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240213 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240213 OWNER TO dwh;

--
-- Name: fix_message_json_20240214; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240214 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240214 OWNER TO dwh;

--
-- Name: fix_message_json_20240215; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240215 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240215 OWNER TO dwh;

--
-- Name: fix_message_json_20240216; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240216 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240216 OWNER TO dwh;

--
-- Name: fix_message_json_20240219; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240219 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240219 OWNER TO dwh;

--
-- Name: fix_message_json_20240220; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240220 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240220 OWNER TO dwh;

--
-- Name: fix_message_json_20240221; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240221 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240221 OWNER TO dwh;

--
-- Name: fix_message_json_20240222; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240222 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240222 OWNER TO dwh;

--
-- Name: fix_message_json_20240223; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240223 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240223 OWNER TO dwh;

--
-- Name: fix_message_json_20240226; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240226 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240226 OWNER TO dwh;

--
-- Name: fix_message_json_20240227; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240227 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240227 OWNER TO dwh;

--
-- Name: fix_message_json_20240228; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240228 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240228 OWNER TO dwh;

--
-- Name: fix_message_json_20240229; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240229 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240229 OWNER TO dwh;

--
-- Name: fix_message_json_20240301; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240301 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240301 OWNER TO dwh;

--
-- Name: fix_message_json_20240304; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240304 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240304 OWNER TO dwh;

--
-- Name: fix_message_json_20240305; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240305 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240305 OWNER TO dwh;

--
-- Name: fix_message_json_20240306; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240306 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240306 OWNER TO dwh;

--
-- Name: fix_message_json_20240307; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240307 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240307 OWNER TO dwh;

--
-- Name: fix_message_json_20240308; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240308 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240308 OWNER TO dwh;

--
-- Name: fix_message_json_20240311; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240311 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240311 OWNER TO dwh;

--
-- Name: fix_message_json_20240312; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240312 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240312 OWNER TO dwh;

--
-- Name: fix_message_json_20240313; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240313 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240313 OWNER TO dwh;

--
-- Name: fix_message_json_20240314; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240314 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240314 OWNER TO dwh;

--
-- Name: fix_message_json_20240315; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240315 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240315 OWNER TO dwh;

--
-- Name: fix_message_json_20240318; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240318 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240318 OWNER TO dwh;

--
-- Name: fix_message_json_20240319; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240319 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240319 OWNER TO dwh;

--
-- Name: fix_message_json_20240320; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240320 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240320 OWNER TO dwh;

--
-- Name: fix_message_json_20240321; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240321 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240321 OWNER TO dwh;

--
-- Name: fix_message_json_20240322; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240322 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240322 OWNER TO dwh;

--
-- Name: fix_message_json_20240325; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240325 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240325 OWNER TO dwh;

--
-- Name: fix_message_json_20240326; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240326 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240326 OWNER TO dwh;

--
-- Name: fix_message_json_20240327; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240327 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240327 OWNER TO dwh;

--
-- Name: fix_message_json_20240328; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240328 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240328 OWNER TO dwh;

--
-- Name: fix_message_json_20240329; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240329 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240329 OWNER TO dwh;

--
-- Name: fix_message_json_20240401; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240401 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240401 OWNER TO dwh;

--
-- Name: fix_message_json_20240402; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240402 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240402 OWNER TO dwh;

--
-- Name: fix_message_json_20240403; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240403 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240403 OWNER TO dwh;

--
-- Name: fix_message_json_20240404; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240404 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240404 OWNER TO dwh;

--
-- Name: fix_message_json_20240405; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240405 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240405 OWNER TO dwh;

--
-- Name: fix_message_json_20240408; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240408 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240408 OWNER TO dwh;

--
-- Name: fix_message_json_20240409; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240409 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240409 OWNER TO dwh;

--
-- Name: fix_message_json_20240410; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240410 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240410 OWNER TO dwh;

--
-- Name: fix_message_json_20240411; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240411 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240411 OWNER TO dwh;

--
-- Name: fix_message_json_20240412; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240412 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240412 OWNER TO dwh;

--
-- Name: fix_message_json_20240415; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240415 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240415 OWNER TO dwh;

--
-- Name: fix_message_json_20240416; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240416 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240416 OWNER TO dwh;

--
-- Name: fix_message_json_20240417; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240417 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240417 OWNER TO dwh;

--
-- Name: fix_message_json_20240418; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240418 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240418 OWNER TO dwh;

--
-- Name: fix_message_json_20240419; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240419 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240419 OWNER TO dwh;

--
-- Name: fix_message_json_20240422; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240422 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240422 OWNER TO dwh;

--
-- Name: fix_message_json_20240423; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240423 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240423 OWNER TO dwh;

--
-- Name: fix_message_json_20240424; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240424 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240424 OWNER TO dwh;

--
-- Name: fix_message_json_20240425; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240425 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240425 OWNER TO dwh;

--
-- Name: fix_message_json_20240426; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240426 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240426 OWNER TO dwh;

--
-- Name: fix_message_json_20240429; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240429 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240429 OWNER TO dwh;

--
-- Name: fix_message_json_20240430; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240430 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240430 OWNER TO dwh;

--
-- Name: fix_message_json_20240501; Type: TABLE; Schema: fc_partitions; Owner: dwh
--

CREATE TABLE fc_partitions.fix_message_json_20240501 (
    fix_message_id bigint DEFAULT nextval('fix_capture.fix_message_json_fix_message_id_seq'::regclass) NOT NULL,
    date_id integer NOT NULL,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fc_partitions.fix_message_json_20240501 OWNER TO dwh;

--
-- Name: compliance_regiso_orders_tb; Type: TABLE; Schema: fintech_dwh; Owner: dwh
--

CREATE TABLE fintech_dwh.compliance_regiso_orders_tb (
    order_date date,
    process_time character varying(20),
    order_id bigint NOT NULL,
    mkt_data_id bigint NOT NULL,
    substrategy character varying(20),
    trading_firm character varying(100),
    account_name character varying(50),
    parent_client_order_id character varying(255),
    street_client_order_id character varying(255),
    security_type character varying(20),
    side character varying(20),
    strategy_step integer,
    order_qty bigint,
    exec_qty bigint,
    symbol character varying(50),
    expiration_day character varying(20),
    price numeric(12,6),
    routing_reason character varying(100),
    ex_destination character varying(50),
    tif character varying(50),
    order_type character varying(50),
    underlying_symbol character varying(50),
    exec_inst character varying(20),
    opra_symbol character varying(30),
    mkt_data_exchange character varying(50),
    nbbo_bid_px numeric(12,6),
    nbbo_bid_size bigint,
    nbbo_ask_px numeric(12,6),
    nbbo_ask_size bigint,
    bid_quantity bigint,
    bid_price numeric(12,6),
    ask_quantity bigint,
    ask_price numeric(12,6),
    is_mleg character varying(20),
    cross_order_id character varying(256)
);


ALTER TABLE fintech_dwh.compliance_regiso_orders_tb OWNER TO dwh;

--
-- Name: reg_nms_orderid_tb; Type: TABLE; Schema: fintech_dwh; Owner: dwh
--

CREATE TABLE fintech_dwh.reg_nms_orderid_tb (
    order_id character varying(250),
    date_id integer,
    cross_order_id character varying(256),
    is_parent boolean
);


ALTER TABLE fintech_dwh.reg_nms_orderid_tb OWNER TO dwh;

--
-- Name: do_not_store_field; Type: TABLE; Schema: fix_capture; Owner: dwh
--

CREATE TABLE fix_capture.do_not_store_field (
    tag_num integer NOT NULL
);


ALTER TABLE fix_capture.do_not_store_field OWNER TO dwh;

--
-- Name: COLUMN do_not_store_field.tag_num; Type: COMMENT; Schema: fix_capture; Owner: dwh
--

COMMENT ON COLUMN fix_capture.do_not_store_field.tag_num IS 'Tags to do not store';


--
-- Name: failed_to_save; Type: TABLE; Schema: fix_capture; Owner: dwh
--

CREATE TABLE fix_capture.failed_to_save (
    event_id bigint NOT NULL,
    date_id integer NOT NULL,
    event_time timestamp without time zone NOT NULL,
    fix_message text,
    sub_system_id character varying(255) NOT NULL,
    error_message character varying(1000),
    pg_db_create_time timestamp without time zone DEFAULT clock_timestamp(),
    jmsxgroupid character varying
);


ALTER TABLE fix_capture.failed_to_save OWNER TO dwh;

--
-- Name: failed_to_save_event_id_seq; Type: SEQUENCE; Schema: fix_capture; Owner: dwh
--

CREATE SEQUENCE fix_capture.failed_to_save_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fix_capture.failed_to_save_event_id_seq OWNER TO dwh;

--
-- Name: failed_to_save_event_id_seq; Type: SEQUENCE OWNED BY; Schema: fix_capture; Owner: dwh
--

ALTER SEQUENCE fix_capture.failed_to_save_event_id_seq OWNED BY fix_capture.failed_to_save.event_id;


--
-- Name: fix_message2rpt_group_entry_pk_seq; Type: SEQUENCE; Schema: fix_capture; Owner: dwh
--

CREATE SEQUENCE fix_capture.fix_message2rpt_group_entry_pk_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fix_capture.fix_message2rpt_group_entry_pk_seq OWNER TO dwh;

--
-- Name: fix_message_fix_message_id_seq; Type: SEQUENCE; Schema: fix_capture; Owner: dwh
--

CREATE SEQUENCE fix_capture.fix_message_fix_message_id_seq
    START WITH -1
    INCREMENT BY -1
    NO MINVALUE
    MAXVALUE 0
    CACHE 1;


ALTER SEQUENCE fix_capture.fix_message_fix_message_id_seq OWNER TO dwh;

--
-- Name: fix_message_json_cmp; Type: TABLE; Schema: fix_capture; Owner: dwh
--

CREATE TABLE fix_capture.fix_message_json_cmp (
    fix_message_id bigint,
    date_id integer,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone
)
WITH (toast_tuple_target='128');


ALTER TABLE fix_capture.fix_message_json_cmp OWNER TO dwh;

--
-- Name: fix_message_last_loaded_id; Type: TABLE; Schema: fix_capture; Owner: dwh
--

CREATE TABLE fix_capture.fix_message_last_loaded_id (
    last_loaded_fix_message_id bigint,
    traffic_source character(1),
    load_batch_id integer
);


ALTER TABLE fix_capture.fix_message_last_loaded_id OWNER TO dwh;

--
-- Name: rejected_files_info; Type: TABLE; Schema: fix_capture; Owner: dwh
--

CREATE TABLE fix_capture.rejected_files_info (
    file_name character varying(30) NOT NULL,
    file_path character varying(100),
    date_id integer NOT NULL,
    error_messages_count integer NOT NULL,
    last_update_time timestamp without time zone DEFAULT clock_timestamp()
);


ALTER TABLE fix_capture.rejected_files_info OWNER TO dwh;

--
-- Name: storable_message_type; Type: TABLE; Schema: fix_capture; Owner: dwh
--

CREATE TABLE fix_capture.storable_message_type (
    tag_35_value character varying(256) NOT NULL
);


ALTER TABLE fix_capture.storable_message_type OWNER TO dwh;

--
-- Name: COLUMN storable_message_type.tag_35_value; Type: COMMENT; Schema: fix_capture; Owner: dwh
--

COMMENT ON COLUMN fix_capture.storable_message_type.tag_35_value IS 'Needs to be clarified ';


--
-- Name: 5min_volume_bar; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data."5min_volume_bar" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
)
PARTITION BY RANGE (date_id);


ALTER TABLE market_data."5min_volume_bar" OWNER TO dwh;

--
-- Name: COLUMN "5min_volume_bar".avg_spread; Type: COMMENT; Schema: market_data; Owner: dwh
--

COMMENT ON COLUMN market_data."5min_volume_bar".avg_spread IS 'Avg spread of marekt data avg(ask_price - bid_price) where bid_price > 0 and ask_price > 0 and bid_quantity > 0 and ask_quantity > 0';


--
-- Name: COLUMN "5min_volume_bar".n_trade; Type: COMMENT; Schema: market_data; Owner: dwh
--

COMMENT ON COLUMN market_data."5min_volume_bar".n_trade IS 'Number of trades in market_data.trade';


--
-- Name: equities_trade; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data.equities_trade (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
)
PARTITION BY RANGE (date_id);


ALTER TABLE market_data.equities_trade OWNER TO dwh;

--
-- Name: load_missing_equities_log; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data.load_missing_equities_log (
    date_id integer,
    trade_time timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE market_data.load_missing_equities_log OWNER TO dwh;

--
-- Name: load_missing_options_log; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data.load_missing_options_log (
    date_id integer,
    trade_time timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE market_data.load_missing_options_log OWNER TO dwh;

--
-- Name: options_trade; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data.options_trade (
    date_id integer NOT NULL,
    trade_time timestamp without time zone NOT NULL,
    trade_id text NOT NULL,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
)
PARTITION BY RANGE (date_id);


ALTER TABLE market_data.options_trade OWNER TO dwh;

--
-- Name: tablespace_test_table; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data.tablespace_test_table (
    id integer
);


ALTER TABLE market_data.tablespace_test_table OWNER TO dwh;

--
-- Name: trade; Type: TABLE; Schema: market_data; Owner: market_data_role
--

CREATE TABLE market_data.trade (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    trade_time timestamp without time zone NOT NULL,
    trade_id numeric(24,0) NOT NULL,
    action_type character varying(30),
    condition_code character varying(30),
    price double precision,
    quantity integer,
    ref_trade_id bigint,
    reporting_venue character varying(5),
    bid_price numeric(16,4),
    ask_price numeric(16,4),
    bid_quantity integer,
    ask_quantity integer,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    implied_volatility numeric(8,4),
    instrument_type_id character varying(1)
)
PARTITION BY RANGE (date_id);


ALTER TABLE market_data.trade OWNER TO market_data_role;

--
-- Name: COLUMN trade.activ_symbol; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.activ_symbol IS 'As in dwh.d_instrument.activ_symbol. Format: <RootSymbol> for Equity, <RootSymbol>/<SerializedData> for Option.';


--
-- Name: COLUMN trade.date_id; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.date_id IS 'A Date of trade event received from Activ CGW. Format: YYYYMMDD';


--
-- Name: COLUMN trade.trade_time; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.trade_time IS 'A Time of trade event received from Activ CGW. TimeZone is EDT';


--
-- Name: COLUMN trade.trade_id; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.trade_id IS 'An Identifier received from Activ CGW';


--
-- Name: COLUMN trade.action_type; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.action_type IS 'Constantly TRADE. Will be removed';


--
-- Name: COLUMN trade.price; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.price IS 'Actual Price of the trade';


--
-- Name: COLUMN trade.quantity; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.quantity IS 'Actual Quantity of the trade';


--
-- Name: COLUMN trade.ref_trade_id; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.ref_trade_id IS 'Constantly 0. Will be removed';


--
-- Name: COLUMN trade.reporting_venue; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.reporting_venue IS 'Exchange code. As in dwh.d_exchange.activ_exchange_code';


--
-- Name: COLUMN trade.bid_price; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.bid_price IS 'NBBO Bid price';


--
-- Name: COLUMN trade.ask_price; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.ask_price IS 'NBBO Ask price';


--
-- Name: COLUMN trade.bid_quantity; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.bid_quantity IS 'NBBO Bid quantity';


--
-- Name: COLUMN trade.ask_quantity; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade.ask_quantity IS 'NBBO Ask quantity';


--
-- Name: trade_java_uat; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data.trade_java_uat (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    trade_time timestamp without time zone NOT NULL,
    trade_id numeric(24,0) NOT NULL,
    action_type character varying(30),
    condition_code character varying(30),
    price double precision,
    quantity integer,
    ref_trade_id bigint,
    reporting_venue character varying(5),
    bid_price numeric(16,4),
    ask_price numeric(16,4),
    bid_quantity integer,
    ask_quantity integer,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    implied_volatility numeric(8,4),
    instrument_type_id character varying(1)
);


ALTER TABLE market_data.trade_java_uat OWNER TO dwh;

--
-- Name: trade_old; Type: TABLE; Schema: market_data; Owner: market_data_role
--

CREATE TABLE market_data.trade_old (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    trade_time timestamp without time zone NOT NULL,
    trade_id numeric(24,0) NOT NULL,
    action_type character varying(30),
    condition_code character varying(30),
    price double precision,
    quantity integer,
    ref_trade_id bigint,
    reporting_venue character varying(5),
    bid_price numeric(16,4),
    ask_price numeric(16,4),
    bid_quantity integer,
    ask_quantity integer,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    implied_volatility numeric(8,4),
    instrument_type_id character varying(1)
);


ALTER TABLE market_data.trade_old OWNER TO market_data_role;

--
-- Name: COLUMN trade_old.activ_symbol; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.activ_symbol IS 'As in dwh.d_instrument.activ_symbol. Format: <RootSymbol> for Equity, <RootSymbol>/<SerializedData> for Option.';


--
-- Name: COLUMN trade_old.date_id; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.date_id IS 'A Date of trade event received from Activ CGW. Format: YYYYMMDD';


--
-- Name: COLUMN trade_old.trade_time; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.trade_time IS 'A Time of trade event received from Activ CGW. TimeZone is EDT';


--
-- Name: COLUMN trade_old.trade_id; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.trade_id IS 'An Identifier received from Activ CGW';


--
-- Name: COLUMN trade_old.action_type; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.action_type IS 'Constantly TRADE. Will be removed';


--
-- Name: COLUMN trade_old.price; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.price IS 'Actual Price of the trade';


--
-- Name: COLUMN trade_old.quantity; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.quantity IS 'Actual Quantity of the trade';


--
-- Name: COLUMN trade_old.ref_trade_id; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.ref_trade_id IS 'Constantly 0. Will be removed';


--
-- Name: COLUMN trade_old.reporting_venue; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.reporting_venue IS 'Exchange code. As in dwh.d_exchange.activ_exchange_code';


--
-- Name: COLUMN trade_old.bid_price; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.bid_price IS 'NBBO Bid price';


--
-- Name: COLUMN trade_old.ask_price; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.ask_price IS 'NBBO Ask price';


--
-- Name: COLUMN trade_old.bid_quantity; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.bid_quantity IS 'NBBO Bid quantity';


--
-- Name: COLUMN trade_old.ask_quantity; Type: COMMENT; Schema: market_data; Owner: market_data_role
--

COMMENT ON COLUMN market_data.trade_old.ask_quantity IS 'NBBO Ask quantity';


--
-- Name: volume_curve_open_close; Type: TABLE; Schema: market_data; Owner: dwh
--

CREATE TABLE market_data.volume_curve_open_close (
    date_id integer NOT NULL,
    day_type character varying(1) NOT NULL,
    activ_symbol character varying(30) NOT NULL,
    bucket character varying(255),
    open_fraction double precision,
    close_fraction double precision
);


ALTER TABLE market_data.volume_curve_open_close OWNER TO dwh;

--
-- Name: 5min_volume_bar_201801; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201801" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201801" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201802; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201802" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201802" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201803; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201803" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201803" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201804; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201804" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201804" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201805; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201805" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201805" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201806; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201806" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201806" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201807; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201807" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201807" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201808; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201808" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201808" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201809; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201809" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201809" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201810; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201810" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201810" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201811; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201811" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201811" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201812; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201812" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201812" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201901; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201901" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201901" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201902; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201902" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201902" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201903; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201903" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201903" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201904; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201904" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201904" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201905; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201905" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201905" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201906; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201906" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201906" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201907; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201907" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201907" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201908; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201908" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201908" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201909; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201909" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201909" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201910; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201910" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201910" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201911; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201911" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201911" OWNER TO dwh;

--
-- Name: 5min_volume_bar_201912; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_201912" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_201912" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202001; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202001" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202001" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202002; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202002" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202002" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202003; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202003" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202003" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202004; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202004" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202004" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202005; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202005" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202005" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202006; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202006" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202006" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202007; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202007" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202007" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202008; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202008" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202008" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202009; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202009" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202009" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202010; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202010" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202010" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202011; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202011" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202011" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202012; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202012" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202012" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202101; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202101" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202101" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202102; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202102" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202102" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202103; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202103" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202103" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202104; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202104" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202104" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202105; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202105" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202105" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202106; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202106" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202106" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202107; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202107" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202107" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202108; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202108" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202108" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202109; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202109" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202109" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202110; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202110" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202110" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202111; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202111" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202111" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202112; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202112" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202112" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202201; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202201" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202201" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202202; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202202" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202202" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202203; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202203" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202203" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202204; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202204" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202204" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202205; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202205" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202205" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202206; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202206" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202206" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202207; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202207" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202207" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202208; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202208" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202208" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202209; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202209" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202209" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202210; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202210" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202210" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202211; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202211" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202211" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202212; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202212" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202212" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202301; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202301" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202301" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202302; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202302" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202302" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202303; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202303" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202303" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202304; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202304" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202304" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202305; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202305" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202305" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202306; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202306" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202306" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202307; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202307" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202307" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202308; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202308" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202308" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202309; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202309" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202309" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202310; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202310" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202310" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202311; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202311" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202311" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202312; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202312" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202312" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202401; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202401" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202401" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202402; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202402" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202402" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202403; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202403" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202403" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202404; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202404" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202404" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202405; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202405" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202405" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202406; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202406" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202406" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202407; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202407" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202407" OWNER TO dwh;

--
-- Name: 5min_volume_bar_202408; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions."5min_volume_bar_202408" (
    activ_symbol character varying(30) NOT NULL,
    date_id integer NOT NULL,
    bin_type character(1),
    bin_start_time timestamp without time zone NOT NULL,
    total_value numeric(16,4),
    total_volume integer,
    total_volume_excl_blocks integer,
    block_volume integer,
    total_volume_pov numeric(8,4),
    total_volume_excl_blocks_pov numeric(8,4),
    block_volume_pov numeric(8,4),
    instrument_id integer,
    cusip character varying(9),
    avg_spread numeric(10,6),
    std_spread double precision,
    avg_price double precision,
    std_price double precision,
    n_trade integer
);


ALTER TABLE md_partitions."5min_volume_bar_202408" OWNER TO dwh;

--
-- Name: equities_trade_20200807; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200807 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200807 OWNER TO dwh;

--
-- Name: equities_trade_20200826; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200826 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200826 OWNER TO dwh;

--
-- Name: equities_trade_20200827; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200827 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200827 OWNER TO dwh;

--
-- Name: equities_trade_20200828; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200828 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200828 OWNER TO dwh;

--
-- Name: equities_trade_20200831; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200831 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200831 OWNER TO dwh;

--
-- Name: equities_trade_20200901; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200901 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200901 OWNER TO dwh;

--
-- Name: equities_trade_20200902; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200902 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200902 OWNER TO dwh;

--
-- Name: equities_trade_20200903; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200903 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200903 OWNER TO dwh;

--
-- Name: equities_trade_20200904; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200904 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200904 OWNER TO dwh;

--
-- Name: equities_trade_20200908; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200908 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200908 OWNER TO dwh;

--
-- Name: equities_trade_20200909; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200909 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200909 OWNER TO dwh;

--
-- Name: equities_trade_20200910; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200910 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200910 OWNER TO dwh;

--
-- Name: equities_trade_20200911; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200911 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200911 OWNER TO dwh;

--
-- Name: equities_trade_20200914; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200914 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200914 OWNER TO dwh;

--
-- Name: equities_trade_20200915; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200915 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200915 OWNER TO dwh;

--
-- Name: equities_trade_20200916; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200916 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200916 OWNER TO dwh;

--
-- Name: equities_trade_20200917; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200917 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200917 OWNER TO dwh;

--
-- Name: equities_trade_20200918; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200918 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200918 OWNER TO dwh;

--
-- Name: equities_trade_20200921; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200921 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200921 OWNER TO dwh;

--
-- Name: equities_trade_20200922; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200922 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200922 OWNER TO dwh;

--
-- Name: equities_trade_20200923; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200923 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200923 OWNER TO dwh;

--
-- Name: equities_trade_20200924; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200924 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200924 OWNER TO dwh;

--
-- Name: equities_trade_20200925; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200925 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200925 OWNER TO dwh;

--
-- Name: equities_trade_20200928; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200928 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200928 OWNER TO dwh;

--
-- Name: equities_trade_20200929; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200929 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200929 OWNER TO dwh;

--
-- Name: equities_trade_20200930; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20200930 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20200930 OWNER TO dwh;

--
-- Name: equities_trade_20201001; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201001 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201001 OWNER TO dwh;

--
-- Name: equities_trade_20201002; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201002 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201002 OWNER TO dwh;

--
-- Name: equities_trade_20201005; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201005 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201005 OWNER TO dwh;

--
-- Name: equities_trade_20201006; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201006 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201006 OWNER TO dwh;

--
-- Name: equities_trade_20201007; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201007 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201007 OWNER TO dwh;

--
-- Name: equities_trade_20201008; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201008 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201008 OWNER TO dwh;

--
-- Name: equities_trade_20201009; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201009 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201009 OWNER TO dwh;

--
-- Name: equities_trade_20201012; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201012 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201012 OWNER TO dwh;

--
-- Name: equities_trade_20201013; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201013 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201013 OWNER TO dwh;

--
-- Name: equities_trade_20201014; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201014 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201014 OWNER TO dwh;

--
-- Name: equities_trade_20201015; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201015 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201015 OWNER TO dwh;

--
-- Name: equities_trade_20201016; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201016 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201016 OWNER TO dwh;

--
-- Name: equities_trade_20201019; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201019 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201019 OWNER TO dwh;

--
-- Name: equities_trade_20201020; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201020 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201020 OWNER TO dwh;

--
-- Name: equities_trade_20201021; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201021 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201021 OWNER TO dwh;

--
-- Name: equities_trade_20201022; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201022 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201022 OWNER TO dwh;

--
-- Name: equities_trade_20201023; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201023 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201023 OWNER TO dwh;

--
-- Name: equities_trade_20201026; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201026 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201026 OWNER TO dwh;

--
-- Name: equities_trade_20201027; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201027 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201027 OWNER TO dwh;

--
-- Name: equities_trade_20201028; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201028 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201028 OWNER TO dwh;

--
-- Name: equities_trade_20201029; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201029 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201029 OWNER TO dwh;

--
-- Name: equities_trade_20201030; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201030 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201030 OWNER TO dwh;

--
-- Name: equities_trade_20201102; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201102 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201102 OWNER TO dwh;

--
-- Name: equities_trade_20201103; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201103 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201103 OWNER TO dwh;

--
-- Name: equities_trade_20201104; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201104 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201104 OWNER TO dwh;

--
-- Name: equities_trade_20201105; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201105 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201105 OWNER TO dwh;

--
-- Name: equities_trade_20201106; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201106 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201106 OWNER TO dwh;

--
-- Name: equities_trade_20201109; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201109 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201109 OWNER TO dwh;

--
-- Name: equities_trade_20201110; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201110 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201110 OWNER TO dwh;

--
-- Name: equities_trade_20201111; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201111 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201111 OWNER TO dwh;

--
-- Name: equities_trade_20201112; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201112 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201112 OWNER TO dwh;

--
-- Name: equities_trade_20201113; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201113 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201113 OWNER TO dwh;

--
-- Name: equities_trade_20201116; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201116 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201116 OWNER TO dwh;

--
-- Name: equities_trade_20201117; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201117 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201117 OWNER TO dwh;

--
-- Name: equities_trade_20201118; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201118 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201118 OWNER TO dwh;

--
-- Name: equities_trade_20201119; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201119 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201119 OWNER TO dwh;

--
-- Name: equities_trade_20201120; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201120 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201120 OWNER TO dwh;

--
-- Name: equities_trade_20201123; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201123 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201123 OWNER TO dwh;

--
-- Name: equities_trade_20201124; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201124 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201124 OWNER TO dwh;

--
-- Name: equities_trade_20201125; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201125 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201125 OWNER TO dwh;

--
-- Name: equities_trade_20201127; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201127 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201127 OWNER TO dwh;

--
-- Name: equities_trade_20201130; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201130 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201130 OWNER TO dwh;

--
-- Name: equities_trade_20201201; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201201 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201201 OWNER TO dwh;

--
-- Name: equities_trade_20201202; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201202 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201202 OWNER TO dwh;

--
-- Name: equities_trade_20201203; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201203 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201203 OWNER TO dwh;

--
-- Name: equities_trade_20201204; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201204 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201204 OWNER TO dwh;

--
-- Name: equities_trade_20201207; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201207 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201207 OWNER TO dwh;

--
-- Name: equities_trade_20201208; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201208 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201208 OWNER TO dwh;

--
-- Name: equities_trade_20201209; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201209 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201209 OWNER TO dwh;

--
-- Name: equities_trade_20201210; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201210 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201210 OWNER TO dwh;

--
-- Name: equities_trade_20201211; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201211 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201211 OWNER TO dwh;

--
-- Name: equities_trade_20201214; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201214 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201214 OWNER TO dwh;

--
-- Name: equities_trade_20201215; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201215 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201215 OWNER TO dwh;

--
-- Name: equities_trade_20201216; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201216 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201216 OWNER TO dwh;

--
-- Name: equities_trade_20201217; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201217 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201217 OWNER TO dwh;

--
-- Name: equities_trade_20201218; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201218 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201218 OWNER TO dwh;

--
-- Name: equities_trade_20201221; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201221 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201221 OWNER TO dwh;

--
-- Name: equities_trade_20201222; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201222 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201222 OWNER TO dwh;

--
-- Name: equities_trade_20201223; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201223 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201223 OWNER TO dwh;

--
-- Name: equities_trade_20201224; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201224 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201224 OWNER TO dwh;

--
-- Name: equities_trade_20201228; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201228 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201228 OWNER TO dwh;

--
-- Name: equities_trade_20201229; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201229 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201229 OWNER TO dwh;

--
-- Name: equities_trade_20201230; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201230 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201230 OWNER TO dwh;

--
-- Name: equities_trade_20201231; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20201231 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20201231 OWNER TO dwh;

--
-- Name: equities_trade_20210101; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210101 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210101 OWNER TO dwh;

--
-- Name: equities_trade_20210104; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210104 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210104 OWNER TO dwh;

--
-- Name: equities_trade_20210105; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210105 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210105 OWNER TO dwh;

--
-- Name: equities_trade_20210106; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210106 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210106 OWNER TO dwh;

--
-- Name: equities_trade_20210107; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210107 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210107 OWNER TO dwh;

--
-- Name: equities_trade_20210108; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210108 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210108 OWNER TO dwh;

--
-- Name: equities_trade_20210111; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210111 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210111 OWNER TO dwh;

--
-- Name: equities_trade_20210112; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210112 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210112 OWNER TO dwh;

--
-- Name: equities_trade_20210113; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210113 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210113 OWNER TO dwh;

--
-- Name: equities_trade_20210114; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210114 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210114 OWNER TO dwh;

--
-- Name: equities_trade_20210115; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210115 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210115 OWNER TO dwh;

--
-- Name: equities_trade_20210118; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210118 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210118 OWNER TO dwh;

--
-- Name: equities_trade_20210119; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210119 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210119 OWNER TO dwh;

--
-- Name: equities_trade_20210120; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210120 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210120 OWNER TO dwh;

--
-- Name: equities_trade_20210121; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210121 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210121 OWNER TO dwh;

--
-- Name: equities_trade_20210122; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210122 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210122 OWNER TO dwh;

--
-- Name: equities_trade_20210125; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210125 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210125 OWNER TO dwh;

--
-- Name: equities_trade_20210126; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210126 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210126 OWNER TO dwh;

--
-- Name: equities_trade_20210127; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210127 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210127 OWNER TO dwh;

--
-- Name: equities_trade_20210128; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210128 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210128 OWNER TO dwh;

--
-- Name: equities_trade_20210129; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210129 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210129 OWNER TO dwh;

--
-- Name: equities_trade_20210201; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210201 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210201 OWNER TO dwh;

--
-- Name: equities_trade_20210202; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210202 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210202 OWNER TO dwh;

--
-- Name: equities_trade_20210203; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210203 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210203 OWNER TO dwh;

--
-- Name: equities_trade_20210204; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210204 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210204 OWNER TO dwh;

--
-- Name: equities_trade_20210205; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210205 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210205 OWNER TO dwh;

--
-- Name: equities_trade_20210208; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210208 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210208 OWNER TO dwh;

--
-- Name: equities_trade_20210209; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210209 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210209 OWNER TO dwh;

--
-- Name: equities_trade_20210210; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210210 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210210 OWNER TO dwh;

--
-- Name: equities_trade_20210211; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210211 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210211 OWNER TO dwh;

--
-- Name: equities_trade_20210212; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210212 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210212 OWNER TO dwh;

--
-- Name: equities_trade_20210215; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210215 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210215 OWNER TO dwh;

--
-- Name: equities_trade_20210216; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210216 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210216 OWNER TO dwh;

--
-- Name: equities_trade_20210217; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210217 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210217 OWNER TO dwh;

--
-- Name: equities_trade_20210218; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210218 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210218 OWNER TO dwh;

--
-- Name: equities_trade_20210219; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210219 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210219 OWNER TO dwh;

--
-- Name: equities_trade_20210222; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210222 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210222 OWNER TO dwh;

--
-- Name: equities_trade_20210223; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210223 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210223 OWNER TO dwh;

--
-- Name: equities_trade_20210224; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210224 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210224 OWNER TO dwh;

--
-- Name: equities_trade_20210225; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210225 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210225 OWNER TO dwh;

--
-- Name: equities_trade_20210226; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210226 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210226 OWNER TO dwh;

--
-- Name: equities_trade_20210301; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210301 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210301 OWNER TO dwh;

--
-- Name: equities_trade_20210302; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210302 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210302 OWNER TO dwh;

--
-- Name: equities_trade_20210303; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210303 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210303 OWNER TO dwh;

--
-- Name: equities_trade_20210304; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210304 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210304 OWNER TO dwh;

--
-- Name: equities_trade_20210305; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210305 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210305 OWNER TO dwh;

--
-- Name: equities_trade_20210308; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210308 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210308 OWNER TO dwh;

--
-- Name: equities_trade_20210309; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210309 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210309 OWNER TO dwh;

--
-- Name: equities_trade_20210310; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210310 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210310 OWNER TO dwh;

--
-- Name: equities_trade_20210311; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210311 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210311 OWNER TO dwh;

--
-- Name: equities_trade_20210312; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210312 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210312 OWNER TO dwh;

--
-- Name: equities_trade_20210315; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210315 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210315 OWNER TO dwh;

--
-- Name: equities_trade_20210316; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210316 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210316 OWNER TO dwh;

--
-- Name: equities_trade_20210317; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210317 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210317 OWNER TO dwh;

--
-- Name: equities_trade_20210318; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210318 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210318 OWNER TO dwh;

--
-- Name: equities_trade_20210319; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210319 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210319 OWNER TO dwh;

--
-- Name: equities_trade_20210322; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210322 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210322 OWNER TO dwh;

--
-- Name: equities_trade_20210323; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210323 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210323 OWNER TO dwh;

--
-- Name: equities_trade_20210324; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210324 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210324 OWNER TO dwh;

--
-- Name: equities_trade_20210325; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210325 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210325 OWNER TO dwh;

--
-- Name: equities_trade_20210326; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210326 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210326 OWNER TO dwh;

--
-- Name: equities_trade_20210329; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210329 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210329 OWNER TO dwh;

--
-- Name: equities_trade_20210330; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210330 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210330 OWNER TO dwh;

--
-- Name: equities_trade_20210331; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210331 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210331 OWNER TO dwh;

--
-- Name: equities_trade_20210401; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210401 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210401 OWNER TO dwh;

--
-- Name: equities_trade_20210405; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210405 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210405 OWNER TO dwh;

--
-- Name: equities_trade_20210406; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210406 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210406 OWNER TO dwh;

--
-- Name: equities_trade_20210407; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210407 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210407 OWNER TO dwh;

--
-- Name: equities_trade_20210408; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210408 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210408 OWNER TO dwh;

--
-- Name: equities_trade_20210409; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210409 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210409 OWNER TO dwh;

--
-- Name: equities_trade_20210412; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210412 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210412 OWNER TO dwh;

--
-- Name: equities_trade_20210413; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210413 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210413 OWNER TO dwh;

--
-- Name: equities_trade_20210414; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210414 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210414 OWNER TO dwh;

--
-- Name: equities_trade_20210415; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210415 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210415 OWNER TO dwh;

--
-- Name: equities_trade_20210416; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210416 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210416 OWNER TO dwh;

--
-- Name: equities_trade_20210419; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210419 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210419 OWNER TO dwh;

--
-- Name: equities_trade_20210420; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210420 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210420 OWNER TO dwh;

--
-- Name: equities_trade_20210421; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210421 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210421 OWNER TO dwh;

--
-- Name: equities_trade_20210422; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210422 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210422 OWNER TO dwh;

--
-- Name: equities_trade_20210423; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210423 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210423 OWNER TO dwh;

--
-- Name: equities_trade_20210426; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210426 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210426 OWNER TO dwh;

--
-- Name: equities_trade_20210427; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210427 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210427 OWNER TO dwh;

--
-- Name: equities_trade_20210428; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210428 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210428 OWNER TO dwh;

--
-- Name: equities_trade_20210429; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210429 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210429 OWNER TO dwh;

--
-- Name: equities_trade_20210430; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210430 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210430 OWNER TO dwh;

--
-- Name: equities_trade_20210503; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210503 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210503 OWNER TO dwh;

--
-- Name: equities_trade_20210504; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210504 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210504 OWNER TO dwh;

--
-- Name: equities_trade_20210505; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210505 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210505 OWNER TO dwh;

--
-- Name: equities_trade_20210506; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210506 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210506 OWNER TO dwh;

--
-- Name: equities_trade_20210507; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210507 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210507 OWNER TO dwh;

--
-- Name: equities_trade_20210510; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210510 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210510 OWNER TO dwh;

--
-- Name: equities_trade_20210511; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210511 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210511 OWNER TO dwh;

--
-- Name: equities_trade_20210512; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210512 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210512 OWNER TO dwh;

--
-- Name: equities_trade_20210513; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210513 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210513 OWNER TO dwh;

--
-- Name: equities_trade_20210514; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210514 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210514 OWNER TO dwh;

--
-- Name: equities_trade_20210517; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210517 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210517 OWNER TO dwh;

--
-- Name: equities_trade_20210518; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210518 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210518 OWNER TO dwh;

--
-- Name: equities_trade_20210519; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210519 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210519 OWNER TO dwh;

--
-- Name: equities_trade_20210520; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210520 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210520 OWNER TO dwh;

--
-- Name: equities_trade_20210521; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210521 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210521 OWNER TO dwh;

--
-- Name: equities_trade_20210524; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210524 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210524 OWNER TO dwh;

--
-- Name: equities_trade_20210525; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210525 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210525 OWNER TO dwh;

--
-- Name: equities_trade_20210526; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210526 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210526 OWNER TO dwh;

--
-- Name: equities_trade_20210527; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210527 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210527 OWNER TO dwh;

--
-- Name: equities_trade_20210528; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210528 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210528 OWNER TO dwh;

--
-- Name: equities_trade_20210601; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210601 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210601 OWNER TO dwh;

--
-- Name: equities_trade_20210602; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210602 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210602 OWNER TO dwh;

--
-- Name: equities_trade_20210603; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210603 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210603 OWNER TO dwh;

--
-- Name: equities_trade_20210604; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210604 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210604 OWNER TO dwh;

--
-- Name: equities_trade_20210607; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210607 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210607 OWNER TO dwh;

--
-- Name: equities_trade_20210608; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210608 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210608 OWNER TO dwh;

--
-- Name: equities_trade_20210609; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210609 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210609 OWNER TO dwh;

--
-- Name: equities_trade_20210610; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210610 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210610 OWNER TO dwh;

--
-- Name: equities_trade_20210611; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210611 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210611 OWNER TO dwh;

--
-- Name: equities_trade_20210614; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210614 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210614 OWNER TO dwh;

--
-- Name: equities_trade_20210615; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210615 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210615 OWNER TO dwh;

--
-- Name: equities_trade_20210616; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210616 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210616 OWNER TO dwh;

--
-- Name: equities_trade_20210617; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210617 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210617 OWNER TO dwh;

--
-- Name: equities_trade_20210618; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210618 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210618 OWNER TO dwh;

--
-- Name: equities_trade_20210621; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210621 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210621 OWNER TO dwh;

--
-- Name: equities_trade_20210622; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210622 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210622 OWNER TO dwh;

--
-- Name: equities_trade_20210623; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210623 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210623 OWNER TO dwh;

--
-- Name: equities_trade_20210624; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210624 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210624 OWNER TO dwh;

--
-- Name: equities_trade_20210625; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210625 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210625 OWNER TO dwh;

--
-- Name: equities_trade_20210628; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210628 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210628 OWNER TO dwh;

--
-- Name: equities_trade_20210629; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210629 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210629 OWNER TO dwh;

--
-- Name: equities_trade_20210630; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210630 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210630 OWNER TO dwh;

--
-- Name: equities_trade_20210701; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210701 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210701 OWNER TO dwh;

--
-- Name: equities_trade_20210702; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210702 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210702 OWNER TO dwh;

--
-- Name: equities_trade_20210706; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210706 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210706 OWNER TO dwh;

--
-- Name: equities_trade_20210707; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210707 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210707 OWNER TO dwh;

--
-- Name: equities_trade_20210708; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210708 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210708 OWNER TO dwh;

--
-- Name: equities_trade_20210709; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210709 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210709 OWNER TO dwh;

--
-- Name: equities_trade_20210712; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210712 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210712 OWNER TO dwh;

--
-- Name: equities_trade_20210713; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210713 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210713 OWNER TO dwh;

--
-- Name: equities_trade_20210714; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210714 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210714 OWNER TO dwh;

--
-- Name: equities_trade_20210715; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210715 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210715 OWNER TO dwh;

--
-- Name: equities_trade_20210716; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210716 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210716 OWNER TO dwh;

--
-- Name: equities_trade_20210719; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210719 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210719 OWNER TO dwh;

--
-- Name: equities_trade_20210720; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210720 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210720 OWNER TO dwh;

--
-- Name: equities_trade_20210721; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210721 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210721 OWNER TO dwh;

--
-- Name: equities_trade_20210722; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210722 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210722 OWNER TO dwh;

--
-- Name: equities_trade_20210723; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210723 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210723 OWNER TO dwh;

--
-- Name: equities_trade_20210726; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210726 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210726 OWNER TO dwh;

--
-- Name: equities_trade_20210727; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210727 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210727 OWNER TO dwh;

--
-- Name: equities_trade_20210728; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210728 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210728 OWNER TO dwh;

--
-- Name: equities_trade_20210729; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210729 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210729 OWNER TO dwh;

--
-- Name: equities_trade_20210730; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210730 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210730 OWNER TO dwh;

--
-- Name: equities_trade_20210802; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210802 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210802 OWNER TO dwh;

--
-- Name: equities_trade_20210803; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210803 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210803 OWNER TO dwh;

--
-- Name: equities_trade_20210804; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210804 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210804 OWNER TO dwh;

--
-- Name: equities_trade_20210805; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210805 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210805 OWNER TO dwh;

--
-- Name: equities_trade_20210806; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210806 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210806 OWNER TO dwh;

--
-- Name: equities_trade_20210809; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210809 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210809 OWNER TO dwh;

--
-- Name: equities_trade_20210810; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210810 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210810 OWNER TO dwh;

--
-- Name: equities_trade_20210811; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210811 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210811 OWNER TO dwh;

--
-- Name: equities_trade_20210812; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210812 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210812 OWNER TO dwh;

--
-- Name: equities_trade_20210813; Type: TABLE; Schema: md_partitions; Owner: dwh
--

CREATE TABLE md_partitions.equities_trade_20210813 (
    date_id integer,
    trade_time timestamp without time zone,
    trade_id text,
    activ_symbol text,
    ask_price numeric,
    ask_quantity integer,
    bid_price numeric,
    bid_quantity integer,
    condition_code text,
    fid_trade_exchange text,
    price numeric,
    quantity integer,
    reporting_venue text,
    load_time timestamp without time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE md_partitions.equities_trade_20210813 OWNER TO dwh;
