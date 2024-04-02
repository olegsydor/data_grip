
CREATE TABLE trash.so_fix_message_json (
    fix_message_id bigint,
    date_id integer,
    message_type character varying(10),
    exec_type character(1),
    traffic_source character(1),
    fix_message json,
    client_order_id character varying(255),
    orig_client_order_id character varying(255),
    pg_db_create_time timestamp without time zone
);


ALTER TABLE trash.so_fix_message_json OWNER TO dwh;

--
-- Name: so_gtc_20240301; Type: TABLE; Schema: trash; Owner: dwh
--

CREATE TABLE trash.so_gtc_20240301 (
    order_id bigint,
    close_date_id integer,
    order_status character(1),
    closing_reason text,
    client_order_id character varying(256),
    multileg_reporting_type character(1)
);


ALTER TABLE trash.so_gtc_20240301 OWNER TO dwh;

--
-- Name: so_parent_orders_1; Type: TABLE; Schema: trash; Owner: dwh
--

CREATE TABLE trash.so_parent_orders_1 (
    parent_order_id bigint,
    last_exec_id bigint,
    create_date_id integer,
    status_date_id integer,
    time_in_force_id character(1),
    account_id integer,
    trading_firm_unq_id integer,
    instrument_id integer,
    instrument_type_id character(1),
    street_count integer,
    trade_count integer,
    order_qty integer,
    street_order_qty integer,
    last_qty bigint,
    amount numeric,
    pg_db_create_time timestamp without time zone,
    pg_db_update_time timestamp without time zone
);


ALTER TABLE trash.so_parent_orders_1 OWNER TO dwh;

--
-- Name: so_parent_orders_2; Type: TABLE; Schema: trash; Owner: dwh
--

CREATE TABLE trash.so_parent_orders_2 (
    parent_order_id bigint,
    last_exec_id bigint,
    create_date_id integer,
    status_date_id integer,
    time_in_force_id character(1),
    account_id integer,
    trading_firm_unq_id integer,
    instrument_id integer,
    instrument_type_id character(1),
    street_count integer,
    trade_count integer,
    order_qty integer,
    street_order_qty integer,
    last_qty bigint,
    amount numeric,
    pg_db_create_time timestamp without time zone,
    pg_db_update_time timestamp without time zone
);


ALTER TABLE trash.so_parent_orders_2 OWNER TO dwh;

--
-- Name: so_test_truncate; Type: TABLE; Schema: trash; Owner: dwh
--

CREATE TABLE trash.so_test_truncate (
    trunc_id integer NOT NULL,
    trunc_value text
);


ALTER TABLE trash.so_test_truncate OWNER TO dwh;

--
-- Name: so_test_truncate_trunc_id_seq; Type: SEQUENCE; Schema: trash; Owner: dwh
--

CREATE SEQUENCE trash.so_test_truncate_trunc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE trash.so_test_truncate_trunc_id_seq OWNER TO dwh;

--
-- Name: so_test_truncate_trunc_id_seq; Type: SEQUENCE OWNED BY; Schema: trash; Owner: dwh
--

ALTER SEQUENCE trash.so_test_truncate_trunc_id_seq OWNED BY trash.so_test_truncate.trunc_id;


--
-- Name: so_to_delete; Type: TABLE; Schema: trash; Owner: dwh
--

CREATE TABLE trash.so_to_delete (
    alert_time timestamp without time zone,
    severity text,
    tf_name character varying(60),
    alert_text text,
    alert_scope text,
    cl_order_id text,
    account_name text,
    exp_date timestamp(0) without time zone,
    symbol character varying(10),
    side character(1),
    price numeric(12,4),
    qty integer
);


ALTER TABLE trash.so_to_delete OWNER TO dwh;

--
-- Name: so_waves; Type: TABLE; Schema: trash; Owner: dwh
--

CREATE TABLE trash.so_waves (
    transaction_id bigint,
    date_id integer,
    transaction_time timestamp without time zone,
    order_id bigint,
    instrument_type_id bpchar,
    order_qty bigint,
    account_id bigint,
    last_qty bigint,
    last_px numeric,
    exchange_id character varying,
    wave_type_code integer,
    side bpchar,
    account_execution_cost numeric,
    price numeric,
    is_last_step boolean
);


ALTER TABLE trash.so_waves OWNER TO dwh;

--
-- Name: sy_bloat_test; Type: TABLE; Schema: trash; Owner: dwh
--

CREATE TABLE trash.sy_bloat_test (
    schemaname name,
    tablename name,
    tableowner name,
    tablespace name,
    hasindexes boolean,
    hasrules boolean,
    hastriggers boolean,
    rowsecurity boolean
);


ALTER TABLE trash.sy_bloat_test OWNER TO dwh;

--
-- Name: sy_test_msgtype; Type: TABLE; Schema: trash; Owner: dwh
--