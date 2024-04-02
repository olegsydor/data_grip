
--
-- Name: COLUMN order_tca_20210217.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210217.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210217.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210217.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210217.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210217.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210217.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210217.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210217.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210217.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210217.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210217.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210217.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210217.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210217.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210217.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210217.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210217.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210217.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210217.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210217.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210217.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210217.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210217.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210217.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210217.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210217.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210217.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210217.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210217.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210217.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210217.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210217.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210217.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210217.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210217.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210217.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210217.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210217.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210217.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210217.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210217.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210217.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210217.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210217.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210217.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210217.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210217.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210217.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210217.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210217.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210218; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210218 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210218 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210218.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210218.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210218.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210218.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210218.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210218.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210218.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210218.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210218.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210218.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210218.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210218.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210218.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210218.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210218.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210218.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210218.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210218.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210218.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210218.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210218.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210218.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210218.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210218.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210218.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210218.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210218.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210218.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210218.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210218.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210218.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210218.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210218.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210218.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210218.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210218.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210218.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210218.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210218.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210218.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210218.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210218.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210218.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210218.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210218.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210218.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210218.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210218.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210218.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210218.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210218.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210218.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210218.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210218.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210218.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210218.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210218.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210218.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210218.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210218.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210218.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210218.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210218.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210218.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210218.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210218.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210218.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210218.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210218.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210218.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210218.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210218.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210218.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210218.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210218.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210219; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210219 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210219 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210219.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210219.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210219.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210219.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210219.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210219.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210219.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210219.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210219.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210219.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210219.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210219.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210219.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210219.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210219.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210219.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210219.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210219.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210219.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210219.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210219.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210219.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210219.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210219.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210219.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210219.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210219.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210219.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210219.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210219.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210219.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210219.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210219.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210219.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210219.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210219.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210219.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210219.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210219.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210219.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210219.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210219.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210219.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210219.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210219.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210219.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210219.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210219.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210219.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210219.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210219.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210219.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210219.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210219.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210219.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210219.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210219.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210219.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210219.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210219.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210219.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210219.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210219.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210219.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210219.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210219.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210219.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210219.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210219.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210219.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210219.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210219.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210219.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210219.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210219.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210222; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210222 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210222 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210222.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210222.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210222.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210222.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210222.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210222.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210222.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210222.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210222.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210222.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210222.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210222.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210222.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210222.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210222.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210222.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210222.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210222.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210222.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210222.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210222.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210222.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210222.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210222.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210222.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210222.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210222.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210222.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210222.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210222.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210222.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210222.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210222.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210222.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210222.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210222.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210222.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210222.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210222.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210222.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210222.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210222.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210222.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210222.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210222.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210222.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210222.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210222.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210222.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210222.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210222.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210222.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210222.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210222.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210222.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210222.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210222.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210222.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210222.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210222.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210222.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210222.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210222.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210222.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210222.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210222.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210222.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210222.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210222.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210222.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210222.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210222.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210222.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210222.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210222.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210223; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210223 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210223 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210223.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210223.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210223.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210223.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210223.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210223.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210223.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210223.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210223.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210223.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210223.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210223.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210223.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210223.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210223.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210223.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210223.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210223.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210223.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210223.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210223.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210223.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210223.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210223.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210223.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210223.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210223.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210223.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210223.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210223.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210223.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210223.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210223.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210223.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210223.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210223.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210223.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210223.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210223.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210223.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210223.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210223.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210223.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210223.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210223.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210223.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210223.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210223.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210223.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210223.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210223.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210223.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210223.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210223.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210223.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210223.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210223.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210223.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210223.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210223.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210223.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210223.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210223.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210223.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210223.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210223.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210223.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210223.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210223.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210223.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210223.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210223.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210223.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210223.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210223.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210224; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210224 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210224 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210224.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210224.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210224.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210224.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210224.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210224.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210224.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210224.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210224.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210224.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210224.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210224.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210224.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210224.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210224.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210224.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210224.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210224.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210224.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210224.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210224.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210224.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210224.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210224.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210224.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210224.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210224.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210224.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210224.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210224.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210224.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210224.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210224.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210224.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210224.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210224.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210224.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210224.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210224.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210224.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210224.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210224.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210224.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210224.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210224.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210224.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210224.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210224.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210224.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210224.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210224.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210224.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210224.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210224.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210224.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210224.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210224.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210224.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210224.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210224.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210224.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210224.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210224.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210224.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210224.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210224.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210224.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210224.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210224.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210224.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210224.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210224.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210224.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210224.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210224.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210225; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210225 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210225 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210225.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210225.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210225.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210225.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210225.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210225.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210225.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210225.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210225.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210225.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210225.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210225.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210225.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210225.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210225.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210225.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210225.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210225.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210225.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210225.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210225.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210225.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210225.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210225.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210225.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210225.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210225.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210225.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210225.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210225.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210225.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210225.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210225.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210225.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210225.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210225.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210225.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210225.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210225.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210225.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210225.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210225.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210225.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210225.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210225.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210225.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210225.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210225.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210225.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210225.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210225.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210225.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210225.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210225.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210225.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210225.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210225.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210225.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210225.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210225.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210225.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210225.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210225.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210225.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210225.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210225.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210225.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210225.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210225.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210225.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210225.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210225.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210225.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210225.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210225.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210226; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210226 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210226 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210226.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210226.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210226.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210226.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210226.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210226.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210226.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210226.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210226.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210226.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210226.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210226.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210226.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210226.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210226.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210226.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210226.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210226.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210226.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210226.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210226.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210226.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210226.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210226.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210226.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210226.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210226.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210226.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210226.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210226.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210226.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210226.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210226.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210226.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210226.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210226.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210226.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210226.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210226.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210226.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210226.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210226.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210226.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210226.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210226.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210226.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210226.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210226.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210226.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210226.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210226.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210226.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210226.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210226.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210226.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210226.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210226.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210226.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210226.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210226.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210226.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210226.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210226.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210226.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210226.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210226.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210226.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210226.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210226.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210226.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210226.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210226.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210226.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210226.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210226.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210301; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210301 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210301 OWNER TO dwh;

--
-- Name: order_tca_20210302; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210302 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210302 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210302.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210302.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210302.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210302.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210302.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210302.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210302.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210302.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210302.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210302.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210302.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210302.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210302.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210302.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210302.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210302.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210302.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210302.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210302.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210302.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210302.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210302.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210302.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210302.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210302.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210302.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210302.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210302.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210302.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210302.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210302.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210302.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210302.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210302.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210302.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210302.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210302.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210302.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210302.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210302.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210302.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210302.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210302.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210302.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210302.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210302.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210302.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210302.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210302.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210302.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210302.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210302.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210302.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210302.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210302.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210302.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210302.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210302.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210302.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210302.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210302.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210302.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210302.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210302.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210302.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210302.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210302.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210302.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210302.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210302.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210302.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210302.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210302.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210302.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210302.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210303; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210303 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210303 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210303.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210303.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210303.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210303.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210303.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210303.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210303.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210303.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210303.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210303.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210303.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210303.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210303.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210303.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210303.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210303.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210303.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210303.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210303.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210303.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210303.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210303.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210303.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210303.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210303.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210303.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210303.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210303.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210303.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210303.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210303.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210303.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210303.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210303.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210303.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210303.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210303.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210303.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210303.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210303.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210303.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210303.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210303.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210303.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210303.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210303.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210303.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210303.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210303.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210303.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210303.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210303.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210303.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210303.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210303.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210303.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210303.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210303.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210303.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210303.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210303.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210303.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210303.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210303.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210303.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210303.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210303.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210303.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210303.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210303.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210303.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210303.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210303.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210303.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210303.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210304; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210304 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210304 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210304.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210304.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210304.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210304.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210304.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210304.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210304.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210304.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210304.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210304.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210304.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210304.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210304.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210304.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210304.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210304.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210304.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210304.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210304.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210304.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210304.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210304.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210304.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210304.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210304.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210304.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210304.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210304.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210304.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210304.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210304.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210304.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210304.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210304.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210304.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210304.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210304.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210304.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210304.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210304.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210304.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210304.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210304.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210304.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210304.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210304.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210304.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210304.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210304.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210304.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210304.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210304.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210304.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210304.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210304.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210304.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210304.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210304.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210304.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210304.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210304.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210304.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210304.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210304.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210304.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210304.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210304.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210304.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210304.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210304.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210304.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210304.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210304.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210304.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210304.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210305; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210305 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210305 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210305.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210305.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210305.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210305.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210305.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210305.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210305.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210305.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210305.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210305.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210305.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210305.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210305.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210305.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210305.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210305.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210305.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210305.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210305.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210305.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210305.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210305.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210305.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210305.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210305.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210305.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210305.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210305.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210305.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210305.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210305.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210305.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210305.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210305.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210305.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210305.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210305.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210305.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210305.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210305.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210305.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210305.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210305.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210305.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210305.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210305.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210305.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210305.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210305.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210305.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210305.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210305.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210305.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210305.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210305.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210305.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210305.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210305.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210305.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210305.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210305.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210305.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210305.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210305.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210305.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210305.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210305.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210305.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210305.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210305.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210305.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210305.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210305.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210305.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210305.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210308; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210308 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210308 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210308.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210308.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210308.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210308.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210308.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210308.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210308.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210308.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210308.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210308.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210308.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210308.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210308.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210308.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210308.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210308.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210308.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210308.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210308.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210308.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210308.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210308.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210308.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210308.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210308.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210308.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210308.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210308.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210308.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210308.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210308.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210308.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210308.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210308.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210308.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210308.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210308.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210308.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210308.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210308.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210308.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210308.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210308.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210308.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210308.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210308.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210308.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210308.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210308.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210308.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210308.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210308.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210308.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210308.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210308.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210308.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210308.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210308.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210308.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210308.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210308.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210308.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210308.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210308.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210308.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210308.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210308.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210308.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210308.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210308.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210308.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210308.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210308.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210308.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210308.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210309; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210309 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210309 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210309.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210309.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210309.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210309.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210309.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210309.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210309.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210309.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210309.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210309.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210309.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210309.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210309.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210309.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210309.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210309.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210309.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210309.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210309.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210309.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210309.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210309.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210309.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210309.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210309.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210309.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210309.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210309.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210309.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210309.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210309.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210309.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210309.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210309.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210309.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210309.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210309.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210309.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210309.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210309.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210309.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210309.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210309.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210309.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210309.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210309.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210309.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210309.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210309.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210309.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210309.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210309.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210309.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210309.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210309.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210309.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210309.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210309.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210309.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210309.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210309.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210309.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210309.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210309.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210309.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210309.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210309.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210309.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210309.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210309.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210309.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210309.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210309.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210309.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210309.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210310; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210310 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210310 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210310.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210310.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210310.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210310.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210310.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210310.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210310.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210310.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210310.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210310.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210310.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210310.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210310.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210310.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210310.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210310.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210310.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210310.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210310.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210310.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210310.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210310.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210310.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210310.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210310.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210310.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210310.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210310.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210310.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210310.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210310.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210310.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210310.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210310.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210310.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210310.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210310.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210310.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210310.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210310.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210310.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210310.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210310.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210310.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210310.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210310.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210310.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210310.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210310.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210310.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210310.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210310.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210310.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210310.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210310.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210310.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210310.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210310.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210310.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210310.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210310.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210310.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210310.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210310.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210310.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210310.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210310.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210310.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210310.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210310.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210310.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210310.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210310.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210310.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210310.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210311; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210311 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210311 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210311.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210311.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210311.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210311.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210311.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210311.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210311.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210311.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210311.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210311.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210311.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210311.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210311.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210311.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210311.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210311.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210311.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210311.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210311.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210311.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210311.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210311.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210311.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210311.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210311.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210311.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210311.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210311.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210311.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210311.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210311.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210311.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210311.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210311.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210311.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210311.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210311.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210311.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210311.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210311.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210311.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210311.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210311.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210311.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210311.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210311.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210311.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210311.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210311.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210311.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210311.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210311.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210311.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210311.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210311.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210311.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210311.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210311.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210311.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210311.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210311.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210311.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210311.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210311.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210311.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210311.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210311.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210311.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210311.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210311.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210311.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210311.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210311.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210311.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210311.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210312; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210312 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210312 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210312.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210312.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210312.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210312.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210312.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210312.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210312.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210312.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210312.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210312.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210312.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210312.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210312.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210312.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210312.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210312.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210312.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210312.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210312.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210312.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210312.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210312.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210312.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210312.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210312.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210312.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210312.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210312.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210312.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210312.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210312.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210312.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210312.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210312.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210312.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210312.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210312.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210312.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210312.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210312.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210312.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210312.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210312.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210312.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210312.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210312.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210312.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210312.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210312.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210312.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210312.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210312.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210312.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210312.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210312.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210312.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210312.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210312.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210312.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210312.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210312.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210312.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210312.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210312.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210312.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210312.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210312.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210312.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210312.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210312.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210312.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210312.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210312.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210312.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210312.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210315; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210315 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210315 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210315.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210315.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210315.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210315.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210315.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210315.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210315.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210315.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210315.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210315.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210315.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210315.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210315.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210315.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210315.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210315.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210315.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210315.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210315.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210315.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210315.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210315.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210315.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210315.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210315.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210315.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210315.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210315.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210315.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210315.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210315.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210315.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210315.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210315.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210315.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210315.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210315.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210315.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210315.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210315.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210315.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210315.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210315.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210315.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210315.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210315.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210315.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210315.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210315.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210315.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210315.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210315.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210315.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210315.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210315.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210315.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210315.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210315.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210315.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210315.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210315.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210315.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210315.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210315.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210315.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210315.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210315.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210315.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210315.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210315.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210315.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210315.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210315.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210315.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210315.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210316; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210316 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210316 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210316.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210316.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210316.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210316.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210316.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210316.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210316.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210316.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210316.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210316.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210316.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210316.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210316.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210316.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210316.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210316.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210316.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210316.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210316.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210316.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210316.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210316.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210316.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210316.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210316.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210316.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210316.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210316.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210316.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210316.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210316.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210316.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210316.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210316.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210316.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210316.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210316.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210316.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210316.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210316.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210316.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210316.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210316.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210316.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210316.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210316.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210316.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210316.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210316.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210316.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210316.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210316.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210316.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210316.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210316.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210316.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210316.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210316.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210316.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210316.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210316.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210316.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210316.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210316.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210316.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210316.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210316.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210316.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210316.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210316.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210316.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210316.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210316.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210316.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210316.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210317; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210317 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210317 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210317.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210317.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210317.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210317.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210317.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210317.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210317.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210317.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210317.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210317.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210317.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210317.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210317.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210317.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210317.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210317.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210317.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210317.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210317.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210317.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210317.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210317.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210317.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210317.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210317.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210317.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210317.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210317.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210317.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210317.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210317.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210317.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210317.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210317.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210317.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210317.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210317.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210317.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210317.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210317.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210317.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210317.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210317.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210317.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210317.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210317.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210317.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210317.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210317.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210317.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210317.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210317.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210317.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210317.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210317.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210317.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210317.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210317.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210317.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210317.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210317.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210317.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210317.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210317.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210317.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210317.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210317.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210317.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210317.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210317.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210317.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210317.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210317.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210317.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210317.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210318; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210318 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210318 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210318.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210318.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210318.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210318.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210318.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210318.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210318.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210318.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210318.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210318.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210318.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210318.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210318.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210318.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210318.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210318.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210318.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210318.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210318.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210318.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210318.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210318.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210318.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210318.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210318.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210318.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210318.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210318.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210318.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210318.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210318.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210318.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210318.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210318.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210318.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210318.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210318.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210318.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210318.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210318.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210318.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210318.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210318.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210318.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210318.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210318.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210318.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210318.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210318.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210318.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210318.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210318.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210318.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210318.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210318.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210318.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210318.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210318.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210318.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210318.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210318.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210318.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210318.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210318.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210318.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210318.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210318.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210318.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210318.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210318.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210318.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210318.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210318.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210318.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210318.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210319; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210319 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210319 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210319.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210319.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210319.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210319.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210319.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210319.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210319.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210319.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210319.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210319.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210319.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210319.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210319.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210319.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210319.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210319.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210319.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210319.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210319.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210319.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210319.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210319.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210319.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210319.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210319.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210319.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210319.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210319.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210319.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210319.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210319.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210319.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210319.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210319.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210319.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210319.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210319.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210319.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210319.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210319.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210319.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210319.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210319.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210319.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210319.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210319.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210319.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210319.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210319.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210319.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210319.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210319.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210319.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210319.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210319.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210319.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210319.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210319.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210319.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210319.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210319.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210319.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210319.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210319.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210319.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210319.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210319.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210319.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210319.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210319.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210319.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210319.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210319.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210319.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210319.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210322; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210322 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210322 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210322.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210322.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210322.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210322.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210322.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210322.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210322.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210322.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210322.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210322.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210322.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210322.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210322.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210322.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210322.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210322.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210322.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210322.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210322.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210322.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210322.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210322.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210322.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210322.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210322.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210322.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210322.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210322.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210322.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210322.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210322.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210322.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210322.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210322.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210322.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210322.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210322.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210322.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210322.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210322.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210322.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210322.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210322.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210322.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210322.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210322.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210322.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210322.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210322.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210322.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210322.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210322.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210322.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210322.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210322.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210322.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210322.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210322.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210322.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210322.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210322.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210322.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210322.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210322.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210322.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210322.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210322.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210322.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210322.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210322.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210322.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210322.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210322.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210322.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210322.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210323; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210323 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210323 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210323.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210323.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210323.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210323.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210323.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210323.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210323.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210323.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210323.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210323.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210323.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210323.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210323.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210323.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210323.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210323.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210323.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210323.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210323.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210323.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210323.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210323.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210323.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210323.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210323.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210323.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210323.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210323.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210323.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210323.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210323.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210323.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210323.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210323.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210323.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210323.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210323.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210323.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210323.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210323.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210323.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210323.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210323.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210323.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210323.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210323.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210323.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210323.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210323.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210323.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210323.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210323.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210323.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210323.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210323.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210323.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210323.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210323.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210323.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210323.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210323.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210323.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210323.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210323.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210323.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210323.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210323.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210323.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210323.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210323.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210323.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210323.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210323.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210323.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210323.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210324; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210324 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210324 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210324.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210324.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210324.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210324.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210324.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210324.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210324.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210324.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210324.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210324.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210324.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210324.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210324.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210324.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210324.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210324.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210324.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210324.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210324.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210324.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210324.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210324.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210324.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210324.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210324.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210324.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210324.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210324.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210324.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210324.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210324.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210324.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210324.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210324.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210324.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210324.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210324.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210324.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210324.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210324.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210324.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210324.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210324.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210324.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210324.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210324.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210324.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210324.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210324.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210324.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210324.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210324.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210324.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210324.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210324.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210324.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210324.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210324.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210324.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210324.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210324.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210324.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210324.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210324.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210324.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210324.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210324.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210324.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210324.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210324.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210324.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210324.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210324.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210324.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210324.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210325; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210325 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210325 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210325.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210325.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210325.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210325.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210325.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210325.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210325.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210325.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210325.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210325.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210325.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210325.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210325.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210325.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210325.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210325.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210325.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210325.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210325.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210325.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210325.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210325.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210325.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210325.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210325.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210325.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210325.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210325.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210325.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210325.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210325.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210325.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210325.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210325.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210325.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210325.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210325.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210325.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210325.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210325.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210325.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210325.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210325.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210325.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210325.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210325.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210325.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210325.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210325.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210325.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210325.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210325.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210325.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210325.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210325.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210325.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210325.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210325.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210325.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210325.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210325.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210325.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210325.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210325.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210325.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210325.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210325.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210325.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210325.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210325.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210325.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210325.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210325.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210325.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210325.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210326; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210326 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210326 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210326.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210326.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210326.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210326.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210326.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210326.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210326.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210326.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210326.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210326.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210326.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210326.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210326.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210326.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210326.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210326.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210326.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210326.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210326.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210326.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210326.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210326.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210326.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210326.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210326.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210326.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210326.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210326.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210326.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210326.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210326.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210326.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210326.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210326.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210326.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210326.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210326.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210326.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210326.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210326.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210326.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210326.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210326.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210326.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210326.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210326.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210326.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210326.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210326.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210326.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210326.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210326.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210326.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210326.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210326.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210326.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210326.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210326.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210326.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210326.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210326.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210326.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210326.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210326.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210326.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210326.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210326.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210326.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210326.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210326.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210326.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210326.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210326.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.end_px_diff_bps IS 'Performance vs Last at order End (bps)';


--
-- Name: COLUMN order_tca_20210326.percentage_volume_limit_adjusted; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210326.percentage_volume_limit_adjusted IS 'percentage_volume_limit_adjusted means
"volume at less price during order life_time"/"volume during order life time"
';


--
-- Name: order_tca_20210329; Type: TABLE; Schema: partitions; Owner: dwh
--

CREATE TABLE partitions.order_tca_20210329 (
    parent_order_id bigint NOT NULL,
    side integer,
    date_id integer NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    order_start_price numeric(12,4),
    order_end_price numeric(12,4),
    avg_bid_ask_spread numeric(12,4),
    avg_bid_ask_spread_bps numeric(20,6),
    price_5s_after_order numeric(12,4),
    price_10s_after_order numeric(12,4),
    price_30s_after_order numeric(12,4),
    price_1m_after_order numeric(12,4),
    price_5m_after_order numeric(12,4),
    price_5s_after_order_bps numeric(20,6),
    price_10s_after_order_bps numeric(20,6),
    price_30s_after_order_bps numeric(20,6),
    price_1m_after_order_bps numeric(20,6),
    price_5m_after_order_bps numeric(20,6),
    avg_px numeric(12,6),
    volume integer,
    parent_client_order_id character varying(256),
    today_volume bigint,
    volume_during_time bigint,
    volume_at_less_price bigint,
    adv bigint,
    val numeric(20,4),
    duration numeric(12,4),
    vwap numeric(20,6),
    vwap_diff numeric(20,6),
    percentage_of_volume numeric(10,2),
    percentage_of_volume_day numeric(12,4),
    vwap_diff_bps numeric(20,6),
    percentage_of_volume_limit numeric(12,4),
    arrival_px_diff numeric(12,4),
    arrival_px_diff_bps numeric(20,6),
    adv_pct numeric(12,4),
    avg_spread_capture numeric(20,6),
    pwp_5 numeric(20,6),
    pwp_10 numeric(20,6),
    pwp_15 numeric(20,6),
    pwp_20 numeric(20,6),
    weighted_avg_bid_ask_spread_by_time numeric(20,6),
    last_trade_time timestamp(3) without time zone,
    db_create_time timestamp(3) without time zone DEFAULT clock_timestamp(),
    cancel_time timestamp without time zone,
    activ_symbol character varying(30),
    previous_close double precision,
    previous_close_date date,
    todays_open double precision,
    todays_open_time time(3) without time zone,
    todays_volweightopenpx double precision,
    "52week_high" double precision,
    "52week_high_date" date,
    "52week_low" double precision,
    "52week_low_date" date,
    account_id integer NOT NULL,
    principal_amount numeric(18,4),
    price_t5_pct_after_order numeric(12,4),
    price_t10_pct_after_order numeric(12,4),
    price_t20_pct_after_order numeric(12,4),
    price_t30_pct_after_order numeric(12,4),
    price_t50_pct_after_order numeric(12,4),
    price_t100_pct_after_order numeric(12,4),
    price_v5_pct_after_order numeric(12,4),
    price_v10_pct_after_order numeric(12,4),
    price_v20_pct_after_order numeric(12,4),
    price_v30_pct_after_order numeric(12,4),
    price_v50_pct_after_order numeric(12,4),
    price_v100_pct_after_order numeric(12,4),
    order_start_nbbo_bid_price numeric(16,4),
    order_start_nbbo_bid_qty integer,
    order_start_nbbo_ask_price numeric(16,4),
    order_start_nbbo_ask_qty integer,
    aggression_level smallint,
    twap numeric(20,6),
    order_qty integer,
    sub_strategy character varying(128),
    limit_adj_vwap numeric(12,4),
    instrument_type_id character varying(1),
    order_price numeric,
    pt_basket_id character varying(100),
    db_merge_time timestamp without time zone,
    last_trade_record_id bigint,
    order_type_id character(1),
    avg_fill_size double precision,
    trade_count integer,
    fix_message_id bigint,
    interval_number_of_blocks integer,
    interval_block_volume bigint,
    end_px_diff_bps numeric(20,6),
    percentage_volume_limit_adjusted numeric,
    display_instrument_id character varying(100)
);


ALTER TABLE partitions.order_tca_20210329 OWNER TO dwh;

--
-- Name: COLUMN order_tca_20210329.parent_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.parent_order_id IS 'Order id of parent order. Based on flat_trade_record.order_id';


--
-- Name: COLUMN order_tca_20210329.side; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.side IS '1 sell, 2 buy';


--
-- Name: COLUMN order_tca_20210329.date_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.date_id IS 'based on flat_trade_record.date_id. Partitioning key ';


--
-- Name: COLUMN order_tca_20210329.start_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.start_time IS 'time of order start';


--
-- Name: COLUMN order_tca_20210329.end_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.end_time IS 'time of order comleted/replaced/canseled';


--
-- Name: COLUMN order_tca_20210329.order_start_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_start_price IS 'Price on the market for the activ_symbol before the order start or just after order start (several seconds) ';


--
-- Name: COLUMN order_tca_20210329.order_end_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_end_price IS 'Price on the market for the activ_symbol after order completed';


--
-- Name: COLUMN order_tca_20210329.avg_bid_ask_spread; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.avg_bid_ask_spread IS 'abs(sum(tr.bid_PRICE) - sum(tr.ask_price)). data arrives from market_data.trade->flat_trade_record->order_tca';


--
-- Name: COLUMN order_tca_20210329.price_5s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_5s_after_order IS 'Price on the market for the activ_symbol 5 s after order start. The first record in trade table 5 s after order start';


--
-- Name: COLUMN order_tca_20210329.price_10s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_10s_after_order IS 'Price on the market for the activ_symbol 10 s after order start. The first record in trade table 10 s after order start';


--
-- Name: COLUMN order_tca_20210329.price_30s_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_30s_after_order IS 'Price on the market for the activ_symbol 30 s after order start. The first record in trade table 30 s after order start';


--
-- Name: COLUMN order_tca_20210329.price_1m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_1m_after_order IS 'Price on the market for the activ_symbol 1m after order start. The first record in trade table 1m after order start';


--
-- Name: COLUMN order_tca_20210329.price_5m_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_5m_after_order IS 'Price on the market for the activ_symbol 5m after order start. The first record in trade table 5m after order start';


--
-- Name: COLUMN order_tca_20210329.price_5s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_5s_after_order_bps IS 'price_5s_after_order- avg_px)/price_5s_after_order*10000';


--
-- Name: COLUMN order_tca_20210329.price_10s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_10s_after_order_bps IS 'price_10s_after_order- avg_px)/price_10s_after_order*10000';


--
-- Name: COLUMN order_tca_20210329.price_30s_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_30s_after_order_bps IS 'price_30s_after_order- avg_px)/price_30s_after_order*10000';


--
-- Name: COLUMN order_tca_20210329.price_1m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_1m_after_order_bps IS 'price_1m_after_order- avg_px)/price_1m_after_order*10000';


--
-- Name: COLUMN order_tca_20210329.price_5m_after_order_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_5m_after_order_bps IS 'price_5m_after_order- avg_px)/price_5m_after_order*10000';


--
-- Name: COLUMN order_tca_20210329.avg_px; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.avg_px IS 'VWAP SUM(tr.LAST_QTY * tr.LAST_PX)/nullif(SUM(tr.LAST_QTY),0)';


--
-- Name: COLUMN order_tca_20210329.volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.volume IS 'Total executed quantity of the order ';


--
-- Name: COLUMN order_tca_20210329.parent_client_order_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.parent_client_order_id IS 'client order id of the parent order';


--
-- Name: COLUMN order_tca_20210329.today_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.today_volume IS 'Volume for entire day 9:30-16:00';


--
-- Name: COLUMN order_tca_20210329.volume_during_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.volume_during_time IS 'market volume between start and end time above from market data';


--
-- Name: COLUMN order_tca_20210329.volume_at_less_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.volume_at_less_price IS 'IF side=’buy’ market volume between start and end time less than order limit
IF side=’Sell’ market volume between start and end time greater than order limi
';


--
-- Name: COLUMN order_tca_20210329.adv; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.adv IS 'Information from security characteristic database';


--
-- Name: COLUMN order_tca_20210329.val; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.val IS 'Avg Px * volume';


--
-- Name: COLUMN order_tca_20210329.duration; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.duration IS 'duration in hours (example 6.2)';


--
-- Name: COLUMN order_tca_20210329.vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.vwap IS 'VWAP based on market_data.trade data or avg_px ';


--
-- Name: COLUMN order_tca_20210329.percentage_of_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.percentage_of_volume IS 'Volume/Market Volume during time period';


--
-- Name: COLUMN order_tca_20210329.percentage_of_volume_day; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.percentage_of_volume_day IS 'Volume/Market Volume during the entire Day ';


--
-- Name: COLUMN order_tca_20210329.vwap_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.vwap_diff_bps IS 'vwap_diff/VWAP*10000';


--
-- Name: COLUMN order_tca_20210329.percentage_of_volume_limit; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.percentage_of_volume_limit IS 'percentage of volume limited by external_data.pov_block_size_limit_import to trade volume ';


--
-- Name: COLUMN order_tca_20210329.arrival_px_diff; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.arrival_px_diff IS 'Difference between order_start_price and avg_px';


--
-- Name: COLUMN order_tca_20210329.pwp_5; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.pwp_5 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 5% of order volume';


--
-- Name: COLUMN order_tca_20210329.pwp_10; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.pwp_10 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 10% of order volume';


--
-- Name: COLUMN order_tca_20210329.pwp_15; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.pwp_15 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 15% of order volume';


--
-- Name: COLUMN order_tca_20210329.pwp_20; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.pwp_20 IS 'VWAP based on market_data.trade for the activ_symbol for trades up to 20% of order volume';


--
-- Name: COLUMN order_tca_20210329.last_trade_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.last_trade_time IS 'time of the last trade for the parent order';


--
-- Name: COLUMN order_tca_20210329.db_create_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.db_create_time IS 'Time of record insertion into the table (Insert but not update)';


--
-- Name: COLUMN order_tca_20210329.cancel_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.cancel_time IS 'Order replace of Cancel time based on execution time where ORDER_STATUS = ''4''';


--
-- Name: COLUMN order_tca_20210329.activ_symbol; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.activ_symbol IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329.previous_close; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.previous_close IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329.previous_close_date; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.previous_close_date IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329.todays_open; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.todays_open IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329.todays_open_time; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.todays_open_time IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329.todays_volweightopenpx; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.todays_volweightopenpx IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329."52week_high"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329."52week_high" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329."52week_high_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329."52week_high_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329."52week_low"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329."52week_low" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329."52week_low_date"; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329."52week_low_date" IS 'Arrives from the external_data.activ_us_listing';


--
-- Name: COLUMN order_tca_20210329.account_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.account_id IS 'Arrives from flat_trade_record.account_id';


--
-- Name: COLUMN order_tca_20210329.principal_amount; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.principal_amount IS ' LAST_QTY * LAST_PX * CONTRACT_MULTIPLIER for options and simple  LAST_QTY * LAST_PX  for equity';


--
-- Name: COLUMN order_tca_20210329.price_t5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_t5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210329.price_t10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_t10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210329.price_t20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_t20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210329.price_t30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_t30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210329.price_t50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_t50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210329.price_t100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_t100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order duration after order completed';


--
-- Name: COLUMN order_tca_20210329.price_v5_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_v5_pct_after_order IS 'Price on the market for the activ_symbol 5% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210329.price_v10_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_v10_pct_after_order IS 'Price on the market for the activ_symbol 10% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210329.price_v20_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_v20_pct_after_order IS 'Price on the market for the activ_symbol 20% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210329.price_v30_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_v30_pct_after_order IS 'Price on the market for the activ_symbol 30% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210329.price_v50_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_v50_pct_after_order IS 'Price on the market for the activ_symbol 50% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210329.price_v100_pct_after_order; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.price_v100_pct_after_order IS 'Price on the market for the activ_symbol 100% of order volume after order completed';


--
-- Name: COLUMN order_tca_20210329.order_start_nbbo_bid_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_start_nbbo_bid_price IS 'NBBO arrives from market_data.trade.bid_price';


--
-- Name: COLUMN order_tca_20210329.order_start_nbbo_bid_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_start_nbbo_bid_qty IS 'NBBO arrives from market_data.trade.bid_quantity';


--
-- Name: COLUMN order_tca_20210329.order_start_nbbo_ask_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_start_nbbo_ask_price IS 'NBBO arrives from market_data.trade.ask_price';


--
-- Name: COLUMN order_tca_20210329.order_start_nbbo_ask_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_start_nbbo_ask_qty IS 'NBBO arrives from market_data.trade.ask_quantity';


--
-- Name: COLUMN order_tca_20210329.aggression_level; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.aggression_level IS 'aggression level. Arrives from client_order.aggression_level';


--
-- Name: COLUMN order_tca_20210329.twap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.twap IS 'Simple avarage of market_data.trade.price during order life time';


--
-- Name: COLUMN order_tca_20210329.order_qty; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_qty IS 'Parent order qty';


--
-- Name: COLUMN order_tca_20210329.sub_strategy; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.sub_strategy IS 'Base of flat_trade.sub_strategy which is based on parent order sub_strategy value';


--
-- Name: COLUMN order_tca_20210329.limit_adj_vwap; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.limit_adj_vwap IS 'Like a normal vwap calculation except it filters out trades above the limit price on a buy order, and filters out trades below the limit price on a sell order.';


--
-- Name: COLUMN order_tca_20210329.instrument_type_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.instrument_type_id IS 'E/O ... Equity , Option etc..';


--
-- Name: COLUMN order_tca_20210329.order_price; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.order_price IS 'Base on Parent order price from lcient_order table';


--
-- Name: COLUMN order_tca_20210329.pt_basket_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.pt_basket_id IS 'based on client_order.pt_basket_id of the parent level';


--
-- Name: COLUMN order_tca_20210329.avg_fill_size; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.avg_fill_size IS 'Simple avg(flat_trade_record.last_px)';


--
-- Name: COLUMN order_tca_20210329.trade_count; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.trade_count IS 'Number of trades on the order. Simple count(flat_trade_record.trade_record_id) ';


--
-- Name: COLUMN order_tca_20210329.fix_message_id; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.fix_message_id IS 'fix_message_id of the parent order';


--
-- Name: COLUMN order_tca_20210329.interval_number_of_blocks; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.interval_number_of_blocks IS 'Number big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210329.interval_block_volume; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.interval_block_volume IS 'sum of quantity filed of big trades on the market during order life times';


--
-- Name: COLUMN order_tca_20210329.end_px_diff_bps; Type: COMMENT; Schema: partitions; Owner: dwh
--

COMMENT ON COLUMN partitions.order_tca_20210329.end_px_diff_bps IS 'Performance vs Last at order End (bps)';

